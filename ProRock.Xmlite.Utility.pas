unit ProRock.Xmlite.Utility;

interface

uses System.Classes, System.SysUtils, System.StrUtils, System.Generics.Collections, System.Generics.Defaults,
  ProRock.Utility;

type
  TTagType = (xttNone, xttOpenClose, xttEmpty, xttText);

  { todo: inverstigate if it is a proper approach. Some info:
    https://stackoverflow.com/questions/27820171/delphi-using-records-as-key-in-tdictionary
    https://en.delphipraxis.net/topic/11770-records-as-tdictionary-keys/ }
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

    { todo: refinement and tests for all functions below }

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
  Inc(aCursor); // Skip the initial '<'

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

class function TReaderXmlite.PassNode(var aCursor: PChar; const aNodeName: string): boolean;
begin
  Result := False;

  while MoveToChars(aCursor, ['"', '<', '/', '>']) do
    case aCursor^ of
      '"': // attribute value
        PassQuotes(aCursor);
      '<': // next tag
        if (aCursor[1] = '!') then // DTD or comments
        begin
          if not TReaderXmlite.PassDtd(aCursor) then
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

  aFullName := nameStart; // define Full Name, including Prefix if it is there
  if separatorPosition <> nil then
  begin
    var prefixStart: PChar := nameStart;
    nameStart := separatorPosition + 1;
    separatorPosition^ := #0;
    aPrefix := prefixStart; // define Prefix
    separatorPosition^ := ':';

    if nameStart = #0 then
    begin
      aCursor^ := ending;
      Exit; // goal Name turned out to be empty - inform invoker about that through False Result (Prefix/FullName remain defined)
    end;
  end;
  aName := nameStart; // define Name without Prefix (equal to Full Name in no-prefix case)

  aCursor^ := ending;

  Result := True;
end;

class function TReaderXmlite.ReadQuotedValueInPlace(var aCursor: PChar): string;
begin
  Result := '';

  if not TReaderXmlite.MoveToChar(aCursor, '"') then
    Exit; // no opening quote found
  Inc(aCursor);
  var valueStart: PChar := aCursor;

  if not TReaderXmlite.MoveToChar(aCursor, '"') then
    Exit; // no closing quote found

  aCursor^ := #0; // temporarily terminate the string
  Result := ReadUnescapeInPlace(valueStart); // process the value
  aCursor^ := '"'; // restore the closing quote

  Inc(aCursor); // move past the closing quote
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

  // it is likely the contents of openning tag were already read and passed, but the start position of Text still needs to be defined
  if not TReaderXmlite.MoveToChar(aCursor, '>') then
    Exit;
  Inc(aCursor);

  Result := ReadUnescapeInPlace(aCursor, '<');
end;

class function TReaderXmlite.ReadUnescapeInPlace(var aCursor: PChar; aStringEndsAt: Char): string;
begin
  var resultStart: PChar := aCursor;
  var resultCursor: PChar := aCursor;

  while aCursor^ <> aStringEndsAt do
  begin
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
