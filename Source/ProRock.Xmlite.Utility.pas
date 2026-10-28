unit ProRock.Xmlite.Utility;

interface

uses System.Classes, System.SysUtils, System.StrUtils, System.Generics.Collections, System.Generics.Defaults,
  ProRock.Utility;

const
  // the "xml" prefix is bound to it by definition - documents never declare it (xml:lang, xml:space)
  cXmlPrefix = 'xml';
  cXmlPrefixUri = 'http://www.w3.org/XML/1998/namespace';
  // xsi:type, xsi:nil - the prefix is usual, not fixed: it is declared like any other
  cXsiPrefix = 'xsi';
  cXsiUri = 'http://www.w3.org/2001/XMLSchema-instance';

type
  TXmliteComponentType = (xctUndefined, xctSimpleType, xctComplexType, xctAttribute, xctAttributeGroup, xctElement, xctElementGroup);
  TTagType = (xttNone, xttOpenClose, xttEmpty, xttText);

  // a dictionary key with its own comparers: the RTL's default ones compare a record's memory - string pointers, not text
  TUriedName = record
    Uri, Name: string;
  public
    constructor Create(const aUri, aName: string); overload;
    constructor Create(const aName: string); overload;
    class operator Equal(const aRecordA, aRecordB: TUriedName): boolean;

  public type
    TComparer = class(TInterfacedObject, IComparer<TUriedName>)
    public
      function Compare(const aLeft, aRight: TUriedName): integer;
    end;

    TEqualityComparer = class(TInterfacedObject, IEqualityComparer<TUriedName>)
    public
      function Equals(const aLeft, aRight: TUriedName): boolean; reintroduce;
      function GetHashCode(const aValue: TUriedName): integer; reintroduce;
    end;
  end;

  TXmlns = class(TDictionary<string, string>) // prefix-URI
  private
    fDefaultUri: string;
    function GetUri(const aPrefix: string): string;
  public
    constructor Create; reintroduce; overload;
    constructor Create(const aParentXmlns: TXmlns); overload;

    property DefaultUri: string read fDefaultUri;
    property Uri[const aPrefix: string]: string read GetUri; default;

    procedure Clear; reintroduce;
  end;

  TReaderXmlite = class abstract(TReaderBase)
  public const
    cXmlNameStartChars = ['a' .. 'z', 'A' .. 'Z', '_', ':']; // valid starting characters for XML names
    cXmlNameChars = cXmlNameStartChars + ['0' .. '9', '-', '.']; // valid subsequent characters for XML names
  public
    class procedure DecodeNumericEscapeEntity(var aCursor, aResultCursor: PChar); static; inline;
    class procedure DecodeNamedEscapeEntity(var aCursor, aResultCursor: PChar); static; inline;
    class function ReadUnescapeInPlace(var aCursor: PChar; aStringEndsAt: Char = #0): string; static; inline;
    class function ReadQuotedValueInPlace(var aCursor: PChar): string; static; inline;
    class function PassDtd(var aCursor: PChar): boolean; static; inline;
    // markup that is not an element - a comment, CDATA, a processing instruction, a DOCTYPE - passed to its own end
    // (CDATA and comments may hold < and >, which bracket counting would take for tags)
    class function PassMarkup(var aCursor: PChar): boolean; static;
    // an element as its exact text, the cursor on its < - the buffer is not changed. Well-formed only: tags nested and
    // closed, attribute values, comments, CDATA and processing instructions closed, every prefix declared (in it or in
    // aXmlns); else False. aNamespaces gets the prefixes it takes from outside ('' - the default namespace) with their URIs
    class function ReadFragment(var aCursor: PChar; aXmlns: TXmlns; out aXml: string;
      aNamespaces: TDictionary<string, string>): boolean; static;

    class function PassNode(var aCursor: PChar; const aNodeName: string): boolean; static; inline;

    class function ReadName(var aCursor: PChar; out aPrefix, aName, aFullName: string; const aCustomEndChars: TSysCharSet = []): boolean;
     static; inline;
    class function ReadTagName(var aCursor: PChar; var aIsEndTag: boolean; out aPrefix, aName, aFullName: string): boolean; overload;
      static; inline;
    class function ReadTagName(var aCursor: PChar; var aIsEndTag: boolean; out aFullName: string): boolean; overload; static; inline;
    class function ReadAttributeName(var aCursor: PChar; out aPrefix, aName, aFullName: string): boolean; static; inline;

    class function ReadTextNodeContents(var aCursor: PChar): string; static; inline;
    class function ReadXmlns(aCursor: PChar; aXmlns: TXmlns): boolean; static; inline;
  end;

implementation

uses System.Hash;

{ TUriedName }

constructor TUriedName.Create(const aUri, aName: string);
begin
  Uri := aUri;
  Name := aName;
end;

constructor TUriedName.Create(const aName: string);
begin
  Uri := '';
  Name := aName;
end;

class operator TUriedName.Equal(const aRecordA, aRecordB: TUriedName): boolean;
begin
  Result := (aRecordA.Uri = aRecordB.Uri) and (aRecordA.Name = aRecordB.Name);
end;

{ TUriedName.TComparer }

function TUriedName.TComparer.Compare(const aLeft, aRight: TUriedName): integer;
begin
  Result := CompareStr(aLeft.Uri, aRight.Uri);
  if Result = 0 then
    Result := CompareStr(aLeft.Name, aRight.Name);
end;

{ TUriedName.TEqualityComparer }

function TUriedName.TEqualityComparer.Equals(const aLeft, aRight: TUriedName): boolean;
begin
  Result := aLeft = aRight;
end;

function TUriedName.TEqualityComparer.GetHashCode(const aValue: TUriedName): integer;
begin
{$IF CompilerVersion >= 35.0} // Delphi 11+
  Result := THashFNV1a32.GetHashValue(aValue.Uri) xor THashFNV1a32.GetHashValue(aValue.Name);
{$ELSE}
  Result := THashBobJenkins.GetHashValue(aValue.Uri) xor THashBobJenkins.GetHashValue(aValue.Name);
{$ENDIF}
end;

{ TXmlns }

procedure TXmlns.Clear;
begin
  inherited Clear;
  fDefaultUri := '';
end;

constructor TXmlns.Create(const aParentXmlns: TXmlns);
begin
  inherited Create(aParentXmlns);
  fDefaultUri := aParentXmlns.DefaultUri;
end;

function TXmlns.GetUri(const aPrefix: string): string;
begin
  if aPrefix.IsEmpty or not TryGetValue(aPrefix, Result) then
    if aPrefix = cXmlPrefix then
      Result := cXmlPrefixUri
    else
      Result := fDefaultUri;
end;

constructor TXmlns.Create;
begin
  inherited Create;
end;

{ TReaderXmlite }

class procedure TReaderXmlite.DecodeNamedEscapeEntity(var aCursor, aResultCursor: PChar);
begin
  if (aCursor = nil) or (aResultCursor = nil) then
    Exit;

  if (aCursor[1] = 'l') and (aCursor[2] = 't') and (aCursor[3] = ';') then
  begin // &lt;
    aResultCursor^ := '<';
    Inc(aCursor, 3);
  end
  else if (aCursor[1] = 'g') and (aCursor[2] = 't') and (aCursor[3] = ';') then
  begin // &gt;
    aResultCursor^ := '>';
    Inc(aCursor, 3);
  end
  else if (aCursor[1] = 'a') and (aCursor[2] = 'm') and (aCursor[3] = 'p') and (aCursor[4] = ';') then
  begin // &amp;
    aResultCursor^ := '&';
    Inc(aCursor, 4);
  end
  else if (aCursor[1] = 'q') and (aCursor[2] = 'u') and (aCursor[3] = 'o') and (aCursor[4] = 't') and (aCursor[5] = ';') then
  begin // &quot;
    aResultCursor^ := '"';
    Inc(aCursor, 5);
  end
  else if (aCursor[1] = 'a') and (aCursor[2] = 'p') and (aCursor[3] = 'o') and (aCursor[4] = 's') and (aCursor[5] = ';') then
  begin // &apos;
    aResultCursor^ := '''';
    Inc(aCursor, 5);
  end
  else // something else
    aResultCursor^ := aCursor^;
end;

class procedure TReaderXmlite.DecodeNumericEscapeEntity(var aCursor, aResultCursor: PChar);
begin
  if (aCursor = nil) or (aResultCursor = nil) then
    Exit;

  var cursor: PChar := aCursor + 2;
  var code: integer;;

  if cursor^ = 'x' then
  begin // hexadecimal
    Inc(cursor);
    code := TReaderXmlite.ReadInteger(cursor, True);
  end
  else // decimal
    code := TReaderXmlite.ReadInteger(cursor);

  if (code > 0) and (code <= $10FFFF) then
  begin
    if code <= $FFFF then // BMP character: directly assign
      aResultCursor^ := Char(code)
    else // code point above BMP: convert to surrogate pair
    begin
      code := code - $10000;
      aResultCursor^ := Char($D800 or (code shr 10)); // high surrogate
      Inc(aResultCursor);
      aResultCursor^ := Char($DC00 or (code and $3FF)); // low surrogate
    end;

    aCursor := cursor;
  end
  else
    aResultCursor^ := aCursor^; // seems, it's not a numeric entity
end;

class function TReaderXmlite.PassDtd(var aCursor: PChar): boolean;
begin
  Result := False;

  if not MoveToVisualChar(aCursor) or (aCursor^ <> '<') then
    Exit;
  Inc(aCursor);

  var bracketsCount: cardinal := 1;
  while bracketsCount > 0 do
  begin
    if not TReaderXmlite.MoveToChars(aCursor, ['<', '>']) then
      Exit;

    if aCursor^ = '<' then
      Inc(bracketsCount)
    else
      Dec(bracketsCount);

    Inc(aCursor);
  end;

  Result := True;
end;

class function TReaderXmlite.PassMarkup(var aCursor: PChar): boolean;

  function PassTo(const aEnd: string): boolean;
  begin
    var found: PChar := StrPos(aCursor, PChar(aEnd));
    Result := found <> nil;
    if Result then
      aCursor := found + Length(aEnd);
  end;

begin
  if StrLComp(aCursor, '<!--', 4) = 0 then
    Result := PassTo('-->')
  else if StrLComp(aCursor, '<![CDATA[', 9) = 0 then
    Result := PassTo(']]>')
  else if aCursor[1] = '?' then
    Result := PassTo('?>')
  else
    Result := PassDtd(aCursor);
end;

class function TReaderXmlite.ReadFragment(var aCursor: PChar; aXmlns: TXmlns; out aXml: string;
  aNamespaces: TDictionary<string, string>): boolean;
type
  TDeclaration = record
    Depth: integer;
    Prefix: string;
  end;
var
  names: TList<string>; // the open elements
  declarations: TList<TDeclaration>; // the prefixes they declare

  procedure PassSpaces;
  begin
    while CharInSet(aCursor^, [#32, #9, #$A, #$D]) do
      Inc(aCursor);
  end;

  function ReadName(out aName: string): boolean;
  begin
    var start: PChar := aCursor;
    while not CharInSet(aCursor^, [#0, #32, #9, #$A, #$D, '/', '>', '=', '<', '"', '''']) do
      Inc(aCursor);
    SetString(aName, start, aCursor - start);
    Result := not aName.IsEmpty;
  end;

  procedure CloseElement;
  begin
    for var i := declarations.Count - 1 downto 0 do
      if declarations[i].Depth = names.Count then
        declarations.Delete(i);
    names.Delete(names.Count - 1);
  end;

  // the prefix of a name: declared in the fragment, or outside - then recorded; an undeclared one is not well-formed
  function Resolve(const aName: string; aElement: boolean): boolean;
  begin
    Result := True;
    var prefix: string := '';
    if aName.IndexOf(':') > 0 then
      prefix := aName.Substring(0, aName.IndexOf(':'))
    else if not aElement then
      Exit; // an unprefixed attribute is in no namespace
    if (prefix = cXmlPrefix) or (prefix = 'xmlns') then
      Exit;
    for var declaration: TDeclaration in declarations do
      if declaration.Prefix = prefix then
        Exit;
    if prefix.IsEmpty then
      aNamespaces.AddOrSetValue('', aXmlns.DefaultUri)
    else
    begin
      var uri: string;
      Result := aXmlns.TryGetValue(prefix, uri);
      if Result then
        aNamespaces.AddOrSetValue(prefix, uri);
    end;
  end;

begin
  Result := False;
  var start: PChar := aCursor;
  names := TList<string>.Create;
  declarations := TList<TDeclaration>.Create;
  try
    repeat
      if aCursor^ = #0 then
        Exit;
      if aCursor^ <> '<' then // text
      begin
        Inc(aCursor);
        Continue;
      end;

      if (aCursor[1] = '!') or (aCursor[1] = '?') then
      begin // a comment, CDATA, a processing instruction - a DOCTYPE has no place in an element
        if (StrLComp(aCursor, '<!--', 4) <> 0) and (StrLComp(aCursor, '<![CDATA[', 9) <> 0) and (aCursor[1] <> '?') then
          Exit;
        if not PassMarkup(aCursor) then
          Exit;
        Continue;
      end;

      if aCursor[1] = '/' then
      begin // an end tag closes the element opened last
        Inc(aCursor, 2);
        var name: string;
        if not ReadName(name) or (names.Count = 0) or (names.Last <> name) then
          Exit;
        PassSpaces;
        if aCursor^ <> '>' then
          Exit;
        Inc(aCursor);
        CloseElement;
        Continue;
      end;

      // a start tag: its declarations count for its own names
      Inc(aCursor);
      var name: string;
      if not ReadName(name) then
        Exit;
      names.Add(name);
      var attributes: TArray<string> := [];
      var empty: boolean := False;
      while True do
      begin
        PassSpaces;
        if aCursor^ = '>' then
        begin
          Inc(aCursor);
          Break;
        end;
        if (aCursor^ = '/') and (aCursor[1] = '>') then
        begin
          Inc(aCursor, 2);
          empty := True;
          Break;
        end;

        var attribute: string;
        if not ReadName(attribute) then
          Exit;
        PassSpaces;
        if aCursor^ <> '=' then
          Exit;
        Inc(aCursor);
        PassSpaces;
        if not CharInSet(aCursor^, ['"', '''']) then
          Exit;
        var quote: Char := aCursor^;
        Inc(aCursor);
        while aCursor^ <> quote do
        begin
          if (aCursor^ = #0) or (aCursor^ = '<') then // < is not allowed in an attribute value
            Exit;
          Inc(aCursor);
        end;
        Inc(aCursor);

        var declaration: TDeclaration;
        declaration.Depth := names.Count;
        if attribute = 'xmlns' then
        begin
          declaration.Prefix := '';
          declarations.Add(declaration);
        end
        else if attribute.StartsWith('xmlns:') then
        begin
          declaration.Prefix := attribute.Substring(6);
          declarations.Add(declaration);
        end
        else
          attributes := attributes + [attribute];
      end;

      if not Resolve(name, True) then
        Exit;
      for var attribute: string in attributes do
        if not Resolve(attribute, False) then
          Exit;
      if empty then
        CloseElement;
    until names.Count = 0;

    SetString(aXml, start, aCursor - start);
    Result := True;
  finally
    declarations.Free;
    names.Free;
  end;
end;

class function TReaderXmlite.PassNode(var aCursor: PChar; const aNodeName: string): boolean;
begin
  Result := False;

  while MoveToChars(aCursor, ['"', '''', '<', '/', '>']) do
    case aCursor^ of
      '"', '''': // attribute value
        PassQuotes(aCursor, aCursor^);
      '<': // next tag
        if (aCursor[1] = '!') or (aCursor[1] = '?') then // a comment, CDATA, a processing instruction, a DOCTYPE
        begin
          if not TReaderXmlite.PassMarkup(aCursor) then
            Exit;
        end
        else // regular node or end tag
        begin
          var nestedNodeName: string;
          var isEndTag: boolean;
          if not ReadTagName(aCursor, isEndTag, nestedNodeName) then
            Exit;

          if isEndTag and (nestedNodeName = aNodeName) then
            Exit(True)
          else if not PassNode(aCursor, nestedNodeName) then
            Exit;
        end;
      '/': // empty tag
        begin
          Inc(aCursor);
          if not MoveToVisualChar(aCursor) then
            Exit;
          if aCursor^ = '>' then
          begin
            Inc(aCursor);
            Exit(True);
          end
          else
            Exit; // something is wrong
        end;
      '>': // possibly text-node contents go next
        begin
          var localCursor: PChar := aCursor; // for checking further contents without changing aCursor value
          Inc(localCursor);
          if not MoveToVisualChar(localCursor) then
            Exit;
          if localCursor^ <> '<' then
            ReadTextNodeContents(aCursor)
          else
            Inc(aCursor);
        end;
    end;
end;

class function TReaderXmlite.ReadAttributeName(var aCursor: PChar; out aPrefix, aName, aFullName: string): boolean;
begin
  Result := TReaderXmlite.ReadName(aCursor, aPrefix, aName, aFullName, ['=']) and TReaderXmlite.MoveToChar(aCursor, '=');
end;

class function TReaderXmlite.ReadName(var aCursor: PChar; out aPrefix, aName, aFullName: string;
  const aCustomEndChars: TSysCharSet): boolean;
begin
  aPrefix := '';
  aName := '';
  aFullName := '';
  Result := False; // should mean no valid name found or invalid format

  if not MoveToVisualChar(aCursor) then // pass any meaningless characters (spaces for instance), check for a nil input
    Exit;
  if CharInSet(aCursor^, aCustomEndChars) then
    Exit; // custom ending character appeared at the beginning

  if not CharInSet(aCursor^, cXmlNameStartChars) then
    Exit; // invalid start character for an XML name

  var nameStart: PChar := aCursor;
  var separatorPosition: PChar := nil;

  while (aCursor^ > #32) and not CharInSet(aCursor^, aCustomEndChars) do
  begin
    if aCursor^ = ':' then
      if separatorPosition = nil then
        separatorPosition := aCursor
      else
        Exit // having several colons is not allowed - something is wrong
    else if not CharInSet(aCursor^, cXmlNameChars) then
      Exit; // invalid character in XML name

    Inc(aCursor);
  end;

  var ending: Char := aCursor^;
  aCursor^ := #0;

  aFullName := nameStart;
  if separatorPosition <> nil then
  begin
    var prefixStart: PChar := nameStart;
    nameStart := separatorPosition + 1;
    separatorPosition^ := #0;
    aPrefix := prefixStart;
    separatorPosition^ := ':';

    if nameStart = #0 then
    begin
      aCursor^ := ending;
      Exit; // goal Name turned out to be empty - inform invoker about that through False Result (Prefix/FullName remain defined)
    end;
  end;
  aName := nameStart;

  aCursor^ := ending;

  Result := True;
end;

class function TReaderXmlite.ReadQuotedValueInPlace(var aCursor: PChar): string;
begin
  Result := '';

  if not TReaderXmlite.MoveToChars(aCursor, ['"', '''']) then
    Exit; // no opening quote found
  var quoteChar: Char := aCursor^;

  Inc(aCursor);
  var valueStart: PChar := aCursor;

  if not TReaderXmlite.MoveToChar(aCursor, quoteChar) then
    Exit; // no closing quote found

  // a start tag is read more than once (its xmlns declarations first, then its attributes): a value with entities is
  // decoded from a copy - decoding in place would leave the shortened value padded with spaces for the next read ("&lt;"
  // read as "<   " the second time)
  SetString(Result, valueStart, aCursor - valueStart);
  if Result.IndexOf('&') >= 0 then
  begin
    var copyCursor: PChar := PChar(Result);
    Result := ReadUnescapeInPlace(copyCursor);
  end;

  Inc(aCursor);
end;

class function TReaderXmlite.ReadTagName(var aCursor: PChar; var aIsEndTag: boolean; out aPrefix, aName, aFullName: string): boolean;
begin
  Result := False;
  aIsEndTag := False;

  if not TReaderXmlite.MoveToVisualChar(aCursor) or (aCursor^ <> '<') then
    Exit;
  Inc(aCursor);

  aIsEndTag := aCursor^ = '/';
  if aIsEndTag then
    Inc(aCursor);

  if not TReaderXmlite.ReadName(aCursor, aPrefix, aName, aFullName, ['>', '/']) then
    Exit;

  if aIsEndTag then
  begin
    if not TReaderXmlite.MoveToChar(aCursor, '>') then
      Exit;
    Inc(aCursor);
  end;

  Result := True;
end;

class function TReaderXmlite.ReadTagName(var aCursor: PChar; var aIsEndTag: boolean; out aFullName: string): boolean;
begin
  var prefix, name: string;
  Result := ReadTagName(aCursor, aIsEndTag, prefix, name, aFullName);
end;

class function TReaderXmlite.ReadTextNodeContents(var aCursor: PChar): string;
begin
  Result := '';

  // it is likely the contents of opening tag were already read and passed, but the start position of Text still needs to be defined
  if not TReaderXmlite.MoveToChar(aCursor, '>') then
    Exit;
  Inc(aCursor);

  Result := ReadUnescapeInPlace(aCursor, '<');
end;

class function TReaderXmlite.ReadUnescapeInPlace(var aCursor: PChar; aStringEndsAt: Char): string;
begin
  var resultStart: PChar := aCursor;
  var resultCursor: PChar := aCursor;

  while True do
  begin
    if aCursor^ = aStringEndsAt then
    begin
      // element text: CDATA is text as it is (no entities: < and & are plain characters), a comment or a processing
      // instruction is skipped; any other < ends the text
      if aStringEndsAt <> '<' then
        Break;
      if StrLComp(aCursor, '<![CDATA[', 9) = 0 then
      begin
        Inc(aCursor, 9);
        while StrLComp(aCursor, ']]>', 3) <> 0 do
        begin
          if aCursor^ = #0 then
            Exit(''); // invalid input
          resultCursor^ := aCursor^;
          Inc(resultCursor);
          Inc(aCursor);
        end;
        Inc(aCursor, 3);
        Continue;
      end;
      if (StrLComp(aCursor, '<!--', 4) <> 0) and (aCursor[1] <> '?') then
        Break;
      if not PassMarkup(aCursor) then
        Exit(''); // invalid input
      Continue;
    end;

    if aCursor^ = #0 then
      Exit(''); // invalid input

    if aCursor^ = '&' then
      if (aCursor[1] = '#') then
        DecodeNumericEscapeEntity(aCursor, resultCursor)
      else
        DecodeNamedEscapeEntity(aCursor, resultCursor)
    else
      resultCursor^ := aCursor^;

    Inc(resultCursor);
    Inc(aCursor);
  end;

  // cut-off string with null-terminate and save result
  resultCursor^ := #0;
  Result := resultStart;

  // overwrite all left characters with spaces
  while resultCursor < aCursor do
  begin
    resultCursor^ := #32;
    Inc(resultCursor);
  end;

  // Reset cursor to termination character
  aCursor^ := aStringEndsAt;
end;

class function TReaderXmlite.ReadXmlns(aCursor: PChar; aXmlns: TXmlns): boolean;
begin
  Result := False;

  if (aCursor = nil) or (aXmlns = nil) then
    Exit; // invalid input

  if not MoveToVisualChar(aCursor) or (aCursor^ <> '<') then
    Exit; // not a tag provided

  Inc(aCursor);
  if not MoveToVisualChar(aCursor) or not CharInSet(aCursor^, cXmlNameStartChars) then
    Exit; // invalid beginning of a tag name

  if not MoveToChars(aCursor, [#32, '>', '/']) then
    Exit; // expected to find space (beginning of xmlns/attribute) or at least ending of the tag

  while aCursor^ <= #32 do
  begin
    if not TReaderXmlite.MoveToVisualChar(aCursor) then
      Exit;

    if CharInSet(aCursor^, ['/', '>']) then
      Exit(True); // tag end reached

    var prefix, name, fullName: string;
    if not TReaderXmlite.ReadAttributeName(aCursor, prefix, name, fullName) then
      Exit;

    var value: string := TReaderXmlite.ReadQuotedValueInPlace(aCursor);

    if prefix = 'xmlns' then
      aXmlns.AddOrSetValue(name, value)
    else if prefix.IsEmpty and (name = 'xmlns') then
      aXmlns.fDefaultUri := value;
  end;

  Result := True;
end;

end.
