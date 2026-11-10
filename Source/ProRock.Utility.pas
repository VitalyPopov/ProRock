unit ProRock.Utility;

interface

uses System.Classes, System.SysUtils, System.Generics.Collections, System.Generics.Defaults, System.Math, System.TypInfo;

const
  cIntegerMaxDiv: array [boolean] of integer = (integer.MaxValue div 10, integer.MaxValue div 16);
  cIntegerMaxMod: array [boolean] of integer = (integer.MaxValue mod 10, integer.MaxValue mod 16);

  cBasiteWriterDefaultIndent = 2;

type
  // camelCase, PascalCase, snake_case, CAPS_CASE, Title_Case, kebab-case, COBOL-CASE, Train-Case, flatcase, UPPERCASE
  TNaming = (nAsIs, nCamelCase, nPascalCase, nSnakeCase, nCapsCase, nTitleCase, nKebabCase, nCobolCase, nTrainCase, nFlatCase, nUpperCase);

  TCustomAttributeClass = class of TCustomAttribute;

  TNamingAttribute = class(TCustomAttribute)
  private
    fNaming: TNaming;
  public
    constructor Create(aNaming: TNaming);
    property Naming: TNaming read fNaming;
  end;

  // Internal ProRock hash set (RTL-backed on D12+, fallback otherwise)
{$IF CompilerVersion >= 36.0} // Delphi 12
  THashSet<T> = class(System.Generics.Collections.THashSet<T>);
{$ELSE}
  THashSet<T> = class
  private
    fDictionary: TDictionary<T, Byte>;
  public
    constructor Create; overload;
    constructor Create(const AItems: array of T; const AComparer: IEqualityComparer<T>); overload;
    destructor Destroy; override;

    function GetEnumerator: TDictionary<T, Byte>.TKeyEnumerator;

    procedure Clear;
    function Add(const Value: T): Boolean;
    function Contains(const Value: T): Boolean;
  end;
{$ENDIF}

  THashedObjectList<T: class> = class
  private
    fDictionary: TObjectDictionary<T, integer>;
    fList: TObjectList<T>;
    function GetCount: integer;

    function GetValue(const aIndex: integer): T;
    function GetValues: TEnumerable<T>;
  public
    constructor Create(aOwnsObjects: boolean = True);
    destructor Destroy; override;

    property Count: integer read GetCount;
    property Values: TEnumerable<T> read GetValues;
    property Value[const aIndex: integer]: T read GetValue; default;

    procedure Add(const aValue: T);
    procedure Remove(const aValue: T);
    function Contains(const aValue: T): boolean;
  end;

  TDictObjectList<K; V: class> = class
  private
    fDictionary: TObjectDictionary<K, V>;
    fKeys: TList<k>;
    fValues: TObjectList<V>;

    function GetCount: integer;
    function GetValue(const aKey: K): V;
  public
    constructor Create(aOwnsValues: boolean = True); overload;
    constructor Create(aComparer: IComparer<K>; aEqualityComparer: IEqualityComparer<K>; aOwnsValues: boolean = True); overload;
    destructor Destroy; override;

    property Count: integer read GetCount;
    property Keys: TList<K> read fKeys;
    property Values: TObjectList<V> read fValues;
    property Value[const aKey: K]: V read GetValue; default;

    procedure Add(const aKey: K; const aValue: V);
    // a value under a key that may be there: Keys and Values get it after the others, the key keeps giving the first
    procedure AddAnother(const aKey: K; const aValue: V);
    procedure Remove(const aKey: K); overload;
    procedure Remove(const aIndex: integer); overload;
    procedure Clear;
  end;

  TDualDictionary<TKey, TValue> = class
  private
    fKeyValue: TDictionary<TKey, TValue>;
    fValueKey: TDictionary<TValue, TKey>;

    function GetCount: NativeInt;
  public
    constructor Create;
    destructor Destroy; override;

    property Count: NativeInt read GetCount;

    procedure Add(const aKey: TKey; const aValue: TValue);
    function TryGetValueByKey(const aKey: TKey; out aValue: TValue): boolean;
    function TryGetKeyByValue(const aValue: TValue; out aKey: TKey): boolean;
  end;

  TSummaryDictionary<T: class> = class
  private
    fDictionary: TDictionary<T, cardinal>;
    function GetCount: integer;
  public
    constructor Create; overload;
    constructor Create(aFirstItem: T); overload;
    destructor Destroy; override;

    property Count: integer read GetCount;

    function Increase(const aItem: T): cardinal;
    function Decrease(const aItem: T): boolean;
  end;

  TWriterBase = class(TStreamWriter)
  private
    fLevel: cardinal;
    fIndent: cardinal;
    fWidth: cardinal;
    function GetText: string;

  public
    constructor Create(aStream: TStream; aIndent: cardinal = cBasiteWriterDefaultIndent; aWidth: cardinal = 0; aLevel: cardinal = 0);
      reintroduce; overload;
    constructor Create(aIndent: cardinal = cBasiteWriterDefaultIndent; aWidth: cardinal = 0; aLevel: cardinal = 0); overload;

    property Indent: cardinal read fIndent write fIndent;
    property Level: cardinal read fLevel;
    property Width: cardinal read fWidth; // 0: no limit
    property Text: string read GetText; // not empty only if BaseStream is TStringStream

    procedure IncLevel; inline;
    procedure DecLevel; inline;
    procedure AddIndent; inline;
    procedure AddLine(const aLine: string); overload; inline;
    procedure AddLine(const aFormat: string; aArgs: array of const); overload;
    procedure FinishLine(const aEndingText: string = ''); inline;
  end;

  TReaderBase = class abstract
  public
    class function MoveToChar(var aCursor: PChar; aChar: Char): boolean; static; inline;
    class function MoveToChars(var aCursor: PChar; const aChars: TSysCharSet): boolean; static; inline;
    class function MoveToVisualChar(var aCursor: PChar): boolean; static; inline;

    class function PassQuotes(var aCursor: PChar; aQuoteChar: Char = '"'): boolean; static; inline;

    class function ReadInteger(var aCursor: PChar; aHex: boolean = False): integer; static; inline;
  end;

  TUtility = class abstract
  public const
    cNameStartChars = ['A' .. 'Z', 'a' .. 'z'];
    cNameChars = cNameStartChars + ['0' .. '9', '-', '_'];
  public
    class function IsDebugging: boolean; static; inline;
    class function ExePath: string; static; inline;

    class function GuessNaming(const aName: string): TNaming; static; inline;
    class function Prefix(const aName: string; aSeparator: Char = ':'): string; static; inline;
    class function NameAndPrefix(const aFullName: string; out aPrefix, aName: string; aSeparator: Char = ':'): boolean; static; inline;
    class function NameWithoutPrefix(const aName: string; aSeparator: Char = ':'): string; static; inline;
    class function Acronym(const aName: string; aAcronyms: THashSet<string> = nil): string; static; inline;
    class function ToPascalCase(const aName: string): string; static; inline;
    class function FromPascalCase(const aName: string; aNaming: TNaming): string; inline;
    // FromPascalCase that also converts a name without lower-case letters (B -> b). Separate: in older generated units B means <B>
    class function FromPascalCaseExact(const aName: string; aNaming: TNaming): string; static;
    // GuessNaming that is sure: the style that gives the name back exactly, else nAsIs (FamilyHistoryStatus-list has no style)
    class function NamingOf(const aName: string): TNaming; static;

    // TryStrToFloat, invariant, that knows XML Schema's NaN, INF and -INF on every Delphi: 10.3 - 11 read them as not numbers
    class function TryFloatFromText(const aText: string; out aValue: Single): boolean; overload; static;
    class function TryFloatFromText(const aText: string; out aValue: Double): boolean; overload; static;
    class function TryFloatFromText(const aText: string; out aValue: Extended): boolean; overload; static;
    // assigned to a Comp otherwise it silently becomes another number
    class function FloatFitsComp(aValue: Extended): boolean; static;
  end;

function GetEnumerationName(aEnumTypeInfo: PTypeInfo; aValue: cardinal): string; overload;
function GetEnumerationName(aEnumTypeInfo: PTypeInfo; aValue: cardinal; aNaming: TNaming): string; overload;

function SimplifiedGenericName(const aName: string): string; inline;

// the shortest text that reads back to the same value: 0.1 stays 0.1, 0.79998168889431442 keeps its 17 digits
// (FloatToStr stops at 15 - a different Double); aPlain: no exponent, 1E-5 -> 0.00001
function FloatText(aValue: Extended; aFloatType: TFloatType; aPlain: boolean = False): string;

implementation

uses System.RegularExpressions, System.StrUtils;

// the point moved to where the exponent puts it: 1.5E17 -> 150000000000000000
function WithoutExponent(const aText: string): string;
begin
  var digitsStart: PChar := PChar(aText);
  var negative: boolean := digitsStart^ = '-';
  if negative then
    Inc(digitsStart);

  var exponentAt: PChar := digitsStart;
  var digitCount: integer := 0;
  var wholeDigits: integer := -1;
  while (exponentAt^ <> 'E') and (exponentAt^ <> #0) do
  begin
    if exponentAt^ = '.' then
      wholeDigits := digitCount
    else
      Inc(digitCount);
    Inc(exponentAt);
  end;
  if exponentAt^ = #0 then // no exponent; NAN and INF have none to move either
    Exit(aText);
  if wholeDigits < 0 then
    wholeDigits := digitCount;

  var cursor: PChar := exponentAt + 1;
  var negativeExponent: boolean := cursor^ = '-';
  if CharInSet(cursor^, ['-', '+']) then
    Inc(cursor);
  var exponent: integer := 0;
  while cursor^ <> #0 do
  begin
    exponent := exponent * 10 + Ord(cursor^) - Ord('0');
    Inc(cursor);
  end;
  if negativeExponent then
    exponent := -exponent;
  Inc(wholeDigits, exponent);

  var size: integer := Ord(negative);
  if wholeDigits <= 0 then
    Inc(size, 2 - wholeDigits + digitCount)
  else if wholeDigits >= digitCount then
    Inc(size, wholeDigits)
  else
    Inc(size, digitCount + 1);
  SetLength(Result, size);

  var output: PChar := PChar(Result);
  if negative then
  begin
    output^ := '-';
    Inc(output);
  end;
  if wholeDigits <= 0 then
  begin
    output^ := '0';
    output[1] := '.';
    Inc(output, 2);
    for var i := 1 to -wholeDigits do
    begin
      output^ := '0';
      Inc(output);
    end;
  end;

  var written: integer := 0;
  cursor := digitsStart;
  while cursor < exponentAt do
  begin
    if cursor^ <> '.' then
    begin
      if (written = wholeDigits) and (written > 0) then
      begin
        output^ := '.';
        Inc(output);
      end;
      output^ := cursor^;
      Inc(output);
      Inc(written);
    end;
    Inc(cursor);
  end;
  for var i := written + 1 to wholeDigits do
  begin
    output^ := '0';
    Inc(output);
  end;
end;

function ShortestFloatText(aValue: Extended; aFloatType: TFloatType): string;
begin
  if IsNan(aValue) then
    Exit('NaN'); // XML Schema's spelling; the RTL's is NAN

  var precision, maxPrecision: integer;
  case aFloatType of
    ftSingle:
      begin
        precision := 7;
        maxPrecision := 9;
      end;
    ftDouble:
      begin
        precision := 15;
        maxPrecision := 17;
      end;
  else
    Exit(FloatToStr(aValue, FormatSettings.Invariant));
  end;
  if IsInfinite(aValue) then
    Exit(FloatToStr(aValue, FormatSettings.Invariant));

  while True do
  begin
    Result := FloatToStrF(aValue, ffGeneral, precision, 0, FormatSettings.Invariant);
    if precision >= maxPrecision then
      Exit;
    var readBack: Extended := StrToFloat(Result, FormatSettings.Invariant);
    if ((aFloatType = ftSingle) and (Single(readBack) = Single(aValue))) or
      ((aFloatType = ftDouble) and (Double(readBack) = Double(aValue))) then
      Exit;
    Inc(precision);
  end;
end;

function FloatText(aValue: Extended; aFloatType: TFloatType; aPlain: boolean): string;
begin
  Result := ShortestFloatText(aValue, aFloatType);
  if aPlain then
    Result := WithoutExponent(Result);
end;

function EnumerationNameWithoutPrefix(aEnumTypeInfo: PTypeInfo; aValue: cardinal): string;
begin
  Result := GetEnumName(aEnumTypeInfo, aValue);

  var resultStartsAt: PChar := PChar(Result);
  while CharInSet(resultStartsAt^, ['a' .. 'z']) do
    Inc(resultStartsAt);

  Result := resultStartsAt;
end;

function GetEnumerationName(aEnumTypeInfo: PTypeInfo; aValue: cardinal): string;
begin
  Result := TUtility.FromPascalCase(EnumerationNameWithoutPrefix(aEnumTypeInfo, aValue), nCamelCase);
end;

function GetEnumerationName(aEnumTypeInfo: PTypeInfo; aValue: cardinal; aNaming: TNaming): string;
begin
  Result := TUtility.FromPascalCaseExact(EnumerationNameWithoutPrefix(aEnumTypeInfo, aValue), aNaming);
end;

function SimplifiedGenericName(const aName: string): string;
begin
  SetString(Result, PChar(aName), Length(aName));

  var openBracket: integer := Result.IndexOf('<');
  if openBracket < 0 then
    Exit;
  var destination: PChar := PChar(Result) + openBracket + 1;

  var source: PChar := PChar(Result) + High(Result);
  while source^ <> '.' do
  begin
    if source = destination then
      Exit;
    Dec(source);
  end;
  Inc(source);

  repeat
    destination^ := source^;
    Inc(source);
    Inc(destination);
  until source^ = #0;
  SetLength(Result, destination - PChar(Result));
end;

{ TNamingAttribute }

constructor TNamingAttribute.Create(aNaming: TNaming);
begin
  fNaming := aNaming;
end;

{ THashedObjectList<T> }

procedure THashedObjectList<T>.Add(const aValue: T);
begin
  if fDictionary.ContainsKey(aValue) then
    Exit;

  fDictionary.Add(aValue, fList.Add(aValue));
end;

function THashedObjectList<T>.Contains(const aValue: T): boolean;
begin
  Result := fDictionary.ContainsKey(aValue);
end;

constructor THashedObjectList<T>.Create(aOwnsObjects: boolean);
begin
  fList := TObjectList<T>.Create(aOwnsObjects);
  fDictionary := TObjectDictionary<T, integer>.Create;
end;

destructor THashedObjectList<T>.Destroy;
begin
  fDictionary.Free;
  fList.Free;
  inherited;
end;

function THashedObjectList<T>.GetCount: integer;
begin
  Result := fList.Count;
end;

function THashedObjectList<T>.GetValue(const aIndex: integer): T;
begin
  Result := fList[aIndex];
end;

function THashedObjectList<T>.GetValues: TEnumerable<T>;
begin
  Result := fList;
end;

procedure THashedObjectList<T>.Remove(const aValue: T);
begin
  if fDictionary.ContainsKey(aValue) then
  begin
    fDictionary.Remove(aValue);
    fList.Delete(fDictionary[aValue]);
  end;
end;

{ TDictObjectList<K, V> }

procedure TDictObjectList<K, V>.Add(const aKey: K; const aValue: V);
begin
  if fDictionary.ContainsKey(aKey) then
  begin
    var listIndex: integer := fKeys.IndexOf(aKey);
    fKeys.Delete(listIndex);
    fValues.Delete(listIndex);
  end;

  fKeys.Add(aKey);
  fValues.Add(aValue);
  fDictionary.AddOrSetValue(aKey, aValue);
end;

procedure TDictObjectList<K, V>.AddAnother(const aKey: K; const aValue: V);
begin
  fKeys.Add(aKey);
  fValues.Add(aValue);
  fDictionary.TryAdd(aKey, aValue);
end;

procedure TDictObjectList<K, V>.Clear;
begin
  fDictionary.Clear;
  fKeys.Clear;
  fValues.Clear;
end;

constructor TDictObjectList<K, V>.Create(aComparer: IComparer<K>; aEqualityComparer: IEqualityComparer<K>; aOwnsValues: boolean);
begin
  fKeys := TList<K>.Create(aComparer);
  fValues := TObjectList<V>.Create(aOwnsValues);
  fDictionary := TObjectDictionary<K, V>.Create([], aEqualityComparer);
end;

constructor TDictObjectList<K, V>.Create(aOwnsValues: boolean);
begin
  fKeys := TList<K>.Create;
  fValues := TObjectList<V>.Create(aOwnsValues);
  fDictionary := TObjectDictionary<K, V>.Create([]);
end;

destructor TDictObjectList<K, V>.Destroy;
begin
  fDictionary.Free;
  fValues.Free;
  fKeys.Free;
  inherited;
end;

function TDictObjectList<K, V>.GetCount: integer;
begin
  Result := fKeys.Count;
end;

function TDictObjectList<K, V>.GetValue(const aKey: K): V;
begin
  if not fDictionary.TryGetValue(aKey, Result) then
    Result := nil;
end;

procedure TDictObjectList<K, V>.Remove(const aIndex: integer);
begin
  if not InRange(aIndex, 0, fKeys.Count - 1) then
    Exit;

  fDictionary.Remove(fKeys[aIndex]);
  fKeys.Delete(aIndex);
  fValues.Delete(aIndex);
end;

procedure TDictObjectList<K, V>.Remove(const aKey: K);
begin
  Remove(fKeys.IndexOf(aKey));
end;

{ TDualDictionary<TKey, TValue> }

procedure TDualDictionary<TKey, TValue>.Add(const aKey: TKey; const aValue: TValue);
begin
  if fKeyValue.ContainsKey(aKey) then
  begin
    fValueKey.Remove(fKeyValue[aKey]);
    fKeyValue.Remove(aKey);
  end;
  if fValueKey.ContainsKey(aValue) then
  begin
    fKeyValue.Remove(fValueKey[aValue]);
    fValueKey.Remove(aValue);
  end;

  fKeyValue.Add(aKey, aValue);
  fValueKey.Add(aValue, aKey);
end;

constructor TDualDictionary<TKey, TValue>.Create;
begin
  fKeyValue := TDictionary<TKey, TValue>.Create;
  fValueKey := TDictionary<TValue, TKey>.Create;
end;

destructor TDualDictionary<TKey, TValue>.Destroy;
begin
  fKeyValue.Free;
  fValueKey.Free;
  inherited;
end;

function TDualDictionary<TKey, TValue>.GetCount: NativeInt;
begin
  Result := fKeyValue.Count;
end;

function TDualDictionary<TKey, TValue>.TryGetKeyByValue(const aValue: TValue; out aKey: TKey): boolean;
begin
  Result := fValueKey.TryGetValue(aValue, aKey);
end;

function TDualDictionary<TKey, TValue>.TryGetValueByKey(const aKey: TKey; out aValue: TValue): boolean;
begin
  Result := fKeyValue.TryGetValue(aKey, aValue);
end;

{ TWriterBase }

procedure TWriterBase.AddIndent;
begin
  if (fLevel = 0) or (fIndent = 0) then
    Exit;

  for var i := 0 to fLevel * fIndent - 1 do
    Write(' ');
end;

procedure TWriterBase.AddLine(const aLine: string);
begin
  var start: PChar := PChar(aLine);
  var increasedLevel: boolean := False; // for multiline wrap

  AddIndent;

  if fWidth > 0 then
  begin
    var stringLength: integer := Length(start);

    while cardinal(stringLength) + fIndent > fWidth do
    begin
      var cursor: PChar := start + fWidth - fIndent;

        // find space prior
      while (cursor <> start) and (cursor^ <> #32) do
        Dec(cursor);

      if cursor = start then
      begin // find space after
        cursor := start + fWidth - fIndent;

        while (cursor <> start + stringLength) and (cursor^ <> #32) do
          Inc(cursor);
      end;

      if cursor^ <> #32 then // no space left in string -> write it as is
        Break;

      cursor^ := #0;
      Write(start);
      cursor^ := #32;

      start := cursor + 1;
      stringLength := Length(start);

      if not increasedLevel then
      begin // increase indent for further lines
        IncLevel;
        increasedLevel := True;
      end;

      FinishLine;
      AddIndent;
    end;
  end;

  Write(start);
  FinishLine;

  if increasedLevel then
    DecLevel;
end;

procedure TWriterBase.AddLine(const aFormat: string; aArgs: array of const);
begin
  AddLine(Format(aFormat, aArgs));
end;

constructor TWriterBase.Create(aIndent, aWidth, aLevel: cardinal);
begin
  Create(nil, aIndent, aWidth, aLevel);
end;

constructor TWriterBase.Create(aStream: TStream; aIndent, aWidth, aLevel: cardinal);
begin
  if aStream = nil then
  begin
    // UTF-8, as TStreamWriter writes (TStringStream's default is the ANSI code page); the shared instance is not owned
    inherited Create(TStringStream.Create('', TEncoding.UTF8, False));
    OwnStream;
  end
  else
    inherited Create(aStream);

  fIndent := aIndent;
  fWidth := aWidth;
  fLevel := aLevel;
end;

procedure TWriterBase.FinishLine(const aEndingText: string);
begin
  Write(aEndingText);
  Write([#13, #10]);
end;

function TWriterBase.GetText: string;
begin
  if not BaseStream.ClassType.InheritsFrom(TStringStream) then
    Exit;

  Result := TStringStream(BaseStream).DataString;
end;

procedure TWriterBase.DecLevel;
begin
  Dec(fLevel);
end;

procedure TWriterBase.IncLevel;
begin
  Inc(fLevel);
end;

{ TReaderBase }

class function TReaderBase.ReadInteger(var aCursor: PChar; aHex: boolean): integer;
begin
  Result := 0;
  if aCursor = nil then
    Exit;

  while (aHex and CharInSet(aCursor^, ['0' .. '9', 'a' .. 'f', 'A' .. 'F'])) or (not aHex and CharInSet(aCursor^, ['0' .. '9'])) do
  begin
    var digit: Integer;
    if CharInSet(aCursor^, ['0' .. '9']) then
      digit := Ord(aCursor^) - Ord('0')
    else
      digit := Ord(UpCase(aCursor^)) - Ord('A') + 10;
    Inc(aCursor);

    if (Result > cIntegerMaxDiv[aHex]) or ((Result = cIntegerMaxDiv[aHex]) and (digit > cIntegerMaxMod[aHex])) then
      Exit(0); // overflow
    Result := Result * IfThen(aHex, 16, 10) + digit;
  end;
end;

class function TReaderBase.MoveToChar(var aCursor: PChar; aChar: Char): boolean;
begin
  if aCursor = nil then
    Exit(False);

  while aCursor^ <> aChar do
  begin
    if aCursor^ = #0 then
      Exit(False); // end of string
    Inc(aCursor);
  end;

  Result := True;
end;

// This function will not work as expected if 'aChars' contains non-ASCII characters.
class function TReaderBase.MoveToChars(var aCursor: PChar; const aChars: TSysCharSet): boolean;
begin
  Result := False;
  if (aCursor = nil) or (aChars = []) then
    Exit;

  while aCursor^ <> #0 do
  begin
    if CharInSet(aCursor^, aChars) then
      Exit(True);
    Inc(aCursor);
  end;
end;

class function TReaderBase.MoveToVisualChar(var aCursor: PChar): boolean;
begin
  if aCursor = nil then
    Exit(False);

  // Skip over control characters and non-printable ASCII characters. Printable ASCII characters start at #33 and above.
  while aCursor^ <= #32 do
  begin
    if aCursor^ = #0 then
      Exit(False); // end of string
    Inc(aCursor);
  end;

  Result := True;
end;

class function TReaderBase.PassQuotes(var aCursor: PChar; aQuoteChar: Char): boolean;
begin
  Result := False;

  if not MoveToChar(aCursor, aQuoteChar) then
    Exit;
  Inc(aCursor);

  if not MoveToChar(aCursor, aQuoteChar) then
    Exit;
  Inc(aCursor);

  Result := True;
end;

{ TUtility }

class function TUtility.Acronym(const aName: string; aAcronyms: THashSet<string>): string;
const cAlphabet = 'abcdefghijklmnopqrstuvwxyz';
begin
  Result := ToPascalCase(aName);
  if Result.IsEmpty then // PChar('') is a constant: the #0 below would be written into it
    Exit;
  var cursor: PChar := PChar(Result);
  var acronymCursor: PChar := cursor;
  while cursor^ <> #0 do
  begin
    if CharInSet(cursor^, ['A' .. 'Z']) then
    begin
      acronymCursor^ := cursor^;
      Inc(acronymCursor^, 32);
      Inc(acronymCursor);
    end;
    Inc(cursor);
  end;
  acronymCursor^ := #0;
  Result := PChar(Result);

  // taken: the acronym, then + a..z, + aa..zz and so on (one letter only gave the 27th taker its 26th's name)
  if aAcronyms <> nil then
  begin
    var acronym: string := Result;
    var index: integer := 0;
    while aAcronyms.Contains(Result) do
    begin
      Inc(index);
      var suffix: string := '';
      var rest: integer := index;
      while rest > 0 do
      begin
        Dec(rest);
        suffix := cAlphabet[rest mod Length(cAlphabet) + 1] + suffix;
        rest := rest div Length(cAlphabet);
      end;
      Result := acronym + suffix;
    end;
    aAcronyms.Add(Result);
  end;
end;

class function TUtility.ExePath: string;
begin
  Result := ExtractFilePath(ParamStr(0));
end;

class function TUtility.FloatFitsComp(aValue: Extended): boolean;
begin
  Result := not IsNan(aValue) and (Abs(aValue) < 9223372036854775808.0); // 2^63; infinity is above it
end;

class function TUtility.FromPascalCase(const aName: string; aNaming: TNaming): string;

  function SplitPascalCase(const aName: string): TArray<string>; inline;
  begin
    Result := [];
    var cursor: PChar := PChar(aName);
    var wordStart: PChar := cursor;
    var currentWord: string;
    while cursor^ <> #0 do
    begin
      if CharInSet(cursor^, ['A' .. 'Z']) and (cursor > wordStart) then
      begin
        SetString(currentWord, wordStart, cursor - wordStart);
        Result := Result + [currentWord];
        wordStart := cursor;
      end;
      Inc(cursor);
    end;

    if wordStart <> cursor then
    begin
      SetString(currentWord, wordStart, cursor - wordStart);
      Result := Result + [currentWord];
    end;
  end;

begin
  SetString(Result, PChar(aName), Length(aName));
  if (aNaming = nPascalCase) or Result.IsEmpty then
    Exit;

  var inputNaming: TNaming := GuessNaming(Result);
  if (inputNaming <> nPascalCase) or (inputNaming = nAsIs) then
    Exit;

  case aNaming of
    nSnakeCase, nCapsCase, nTitleCase, nKebabCase, nCobolCase, nTrainCase:
      begin
        var words: TArray<string> := SplitPascalCase(Result);

        for var i := 0 to High(words) do
        begin
          if aNaming in [nCobolCase, nCapsCase] then
            words[i] := words[i].ToUpper;
          if (aNaming in [nSnakeCase, nKebabCase]) and not words[i].IsEmpty then
            Inc(words[i][1], 32);
        end;

        case aNaming of
          nSnakeCase, nCapsCase, nTitleCase:
            Result := string.Join('_', words);
          nKebabCase, nCobolCase, nTrainCase:
            Result := string.Join('-', words);
        end;
      end;
    nCamelCase:
      Inc(Result[1], 32);
    nFlatCase:
      Result := Result.ToLower;
    nUpperCase:
      Result := Result.ToUpper;
  end;
end;

class function TUtility.FromPascalCaseExact(const aName: string; aNaming: TNaming): string;
begin
  if (GuessNaming(aName) = nUpperCase) and (aNaming in [nCamelCase, nSnakeCase, nKebabCase, nFlatCase]) then
    Result := aName.ToLower
  else
    Result := TUtility.FromPascalCase(aName, aNaming);
end;

class function TUtility.NamingOf(const aName: string): TNaming;
begin
  Result := GuessNaming(aName);
  if (Result <> nAsIs) and (TUtility.FromPascalCase(ToPascalCase(aName), Result) <> aName) then
    Result := nAsIs;
end;

class function TUtility.GuessNaming(const aName: string): TNaming;
begin
  Result := nAsIs;

  if aName.IsEmpty then
    Exit;

  var cursor: PChar := PChar(aName);
  if not CharInSet(cursor^, cNameStartChars) then
    Exit; // Invalid starting character

  var hasUnderscore: boolean := False;
  var hasHyphen: boolean := False;
  var hasLower: boolean := False;
  var hasUpper: boolean := False;
  var firstCharUpper: boolean := False;

  if CharInSet(cursor^, ['A' .. 'Z']) then
    firstCharUpper := True;

  while cursor^ <> #0 do
  begin
    if not CharInSet(cursor^, cNameChars) then
      Exit;

    case cursor^ of
      '_':
        hasUnderscore := True;
      '-':
        hasHyphen := True;
      'a' .. 'z':
        hasLower := True;
      'A' .. 'Z':
        hasUpper := True;
    end;

    Inc(cursor);
  end;

  if hasUnderscore then
    if hasUpper and not hasLower then
      Result := nCapsCase // CAPS_CASE
    else if firstCharUpper then
      Result := nTitleCase // Title_Case
    else
      Result := nSnakeCase // snake_case
  else if hasHyphen then
    if hasUpper and not hasLower then
      Result := nCobolCase // COBOL-CASE
    else if firstCharUpper then
      Result := nTrainCase // Train-Case
    else
      Result := nKebabCase // kebab-case
  else if hasUpper and hasLower then
    if firstCharUpper then
      Result := nPascalCase // PascalCase
    else
      Result := nCamelCase // camelCase
  else if hasUpper and not hasLower then
    Result := nUpperCase // UPPERCASE
  else if hasLower and not hasUpper then
    Result := nFlatCase; // flatcase
end;

class function TUtility.IsDebugging: boolean;
begin
  {$WARN SYMBOL_PLATFORM OFF}
  Result := DebugHook <> 0;
  {$WARN SYMBOL_PLATFORM ON}
end;

class function TUtility.NameAndPrefix(const aFullName: string; out aPrefix, aName: string; aSeparator: Char): boolean;
begin
  Result := True;
  if aFullName.IsEmpty then
    Exit(False);

  aPrefix := Prefix(aFullName, aSeparator);
  if aPrefix.IsEmpty then
    aName := aFullName
  else
    aName := PChar(aFullName) + Length(aPrefix) + 1 {separator};
end;

class function TUtility.NameWithoutPrefix(const aName: string; aSeparator: Char): string;
begin
  var cursor: PChar := PChar(aName);
  while cursor^ <> #0 do
  begin
    if cursor^ = aSeparator then
      Exit(cursor + 1);

    Inc(cursor);
  end;

  Result := aName;
end;

class function TUtility.Prefix(const aName: string; aSeparator: Char): string;
begin
  var cursor: PChar := PChar(aName);
  while cursor^ <> #0 do
  begin
    if cursor^ = aSeparator then
    begin
      cursor^ := #0;
      Result := PChar(aName);
      cursor^ := aSeparator;
      Exit;
    end;

    Inc(cursor);
  end;

  Result := '';
end;

class function TUtility.ToPascalCase(const aName: string): string;
begin
  SetString(Result, PChar(aName), Length(aName)); // for AsIs or PascalCase
  if Result.IsEmpty then
    Exit;

  // a dot separates words (XHTML a.content, FHIR Account.Coverage) - never part of a Delphi name; each word in its own style
  if Result.IndexOf('.') >= 0 then
  begin
    var dotWords: TArray<string> := Result.Split(['.']);
    Result := '';
    for var dotWord: string in dotWords do
      Result := Result + ToPascalCase(dotWord);
    Exit;
  end;

  var originalNaming: TNaming := GuessNaming(Result);;
  case originalNaming of
    nSnakeCase, nCapsCase, nTitleCase, nKebabCase, nCobolCase, nTrainCase:
      begin
        var words: TArray<string>;;
        case originalNaming of
          nSnakeCase, nCapsCase, nTitleCase:
            words := Result.Split(['_']);
          nKebabCase, nCobolCase, nTrainCase:
            words := Result.Split(['-']);
        end;

        for var i := 0 to High(words) do
        begin
          if originalNaming in [nCobolCase, nCapsCase] then
            words[i] := words[i].ToLower;
          if not words[i].IsEmpty then
            words[i][1] := UpCase(words[i][1]);
        end;

        Result := string.Join('', words);
      end;
    nCamelCase, nFlatCase:
      Result[1] := UpCase(Result[1]);
    nUpperCase:
      begin
        Result := Result.ToLower;
        Result[1] := UpCase(Result[1]);
      end;
  end;
end;

class function TUtility.TryFloatFromText(const aText: string; out aValue: Single): boolean;
begin
  Result := True;
  if aText = 'NaN' then
    aValue := NaN
  else if aText = 'INF' then
    aValue := Infinity
  else if aText = '-INF' then
    aValue := NegInfinity
  else
    Result := TryStrToFloat(aText, aValue, FormatSettings.Invariant);
end;

class function TUtility.TryFloatFromText(const aText: string; out aValue: Double): boolean;
begin
  Result := True;
  if aText = 'NaN' then
    aValue := NaN
  else if aText = 'INF' then
    aValue := Infinity
  else if aText = '-INF' then
    aValue := NegInfinity
  else
    Result := TryStrToFloat(aText, aValue, FormatSettings.Invariant);
end;

class function TUtility.TryFloatFromText(const aText: string; out aValue: Extended): boolean;
begin
  Result := True;
  if aText = 'NaN' then
    aValue := NaN
  else if aText = 'INF' then
    aValue := Infinity
  else if aText = '-INF' then
    aValue := NegInfinity
  else
    Result := TryStrToFloat(aText, aValue, FormatSettings.Invariant);
end;

{ TSummaryDictionary }

constructor TSummaryDictionary<T>.Create(aFirstItem: T);
begin
  Create;
  if aFirstItem <> nil then
    Increase(aFirstItem);
end;

constructor TSummaryDictionary<T>.Create;
begin
  fDictionary := TDictionary<T, cardinal>.Create;
end;

function TSummaryDictionary<T>.Decrease(const aItem: T): boolean;
begin
  var summary: cardinal := 0;
  Result := fDictionary.TryGetValue(aItem, summary);

  if Result then
  begin
    Dec(summary);

    if summary = 0 then
      fDictionary.Remove(aItem)
    else
      fDictionary[aItem] := summary;
  end;
end;

destructor TSummaryDictionary<T>.Destroy;
begin
  fDictionary.Free;
  inherited;
end;

function TSummaryDictionary<T>.GetCount: integer;
begin
  Result := fDictionary.Count;
end;

function TSummaryDictionary<T>.Increase(const aItem: T): cardinal;
begin
  if fDictionary.TryGetValue(aItem, Result) then
    Inc(Result)
  else
    Result := 1;

  fDictionary.AddOrSetValue(aItem, Result);
end;

{$IF CompilerVersion < 36.0} // Delphi < 12

{ THashSet<T> }

constructor THashSet<T>.Create;
begin
  fDictionary := TDictionary<T, Byte>.Create;
end;

constructor THashSet<T>.Create(const AItems: array of T; const AComparer: IEqualityComparer<T>);
begin
  fDictionary := TDictionary<T, Byte>.Create(AComparer);
  for var item: T in AItems do
    fDictionary.TryAdd(item, 0);
end;

destructor THashSet<T>.Destroy;
begin
  fDictionary.Free;
  inherited;
end;

function THashSet<T>.GetEnumerator: TDictionary<T, Byte>.TKeyEnumerator;
begin
  Result := fDictionary.Keys.GetEnumerator;
end;

procedure THashSet<T>.Clear;
begin
  fDictionary.Clear;
end;

function THashSet<T>.Add(const Value: T): Boolean;
begin
  Result := fDictionary.TryAdd(Value, 0);
end;

function THashSet<T>.Contains(const Value: T): Boolean;
begin
  Result := fDictionary.ContainsKey(Value);
end;

{$ENDIF}

end.
