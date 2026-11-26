unit ProRock.Calcite.Formats;

// Excel's number formats: a code checked, a number shown as it shows it (internal)

interface

type
  // what a section of a number format has, outside quotes and escapes
  TFormatSection = record
    Digits, Dates, Text, General: boolean;
    Error: string;
  end;

// a number format's section (from 0): digit placeholders, date and time codes, @, General; Error - why Excel would not open
// it, or the code's own (a quote not closed) when the section reads; all False past the last section
function FormatSection(const aCode: string; aIndex: integer): TFormatSection;

// why Excel would not open a file with this number format, '' - it would (each rule found by opening files in Excel)
function NumberFormatError(const aCode: string): string;

// whether a cell with this number format holds a date or a time: its first section has a date or time code (an era's g and
// the Buddhist year's b, e too: Excel shows them as dates)
function IsDateCode(const aCode: string): boolean;

// '' or why a code looks typed in another language's Excel (TT.MM.JJJJ, aaaa-mm-dd, #.##0,00): a file keeps English codes,
// and Excel takes most of these as written - aaaa a weekday, J a letter shown as it is, 0,00 thousands
function LocalNotation(const aCode: string): string;

// a code as Excel's NumberFormat shows it: no \ before what is shown as itself anyway ($ - + / ( ) : ! ^ & ' ~ { } < > = and
// a space, a . in a date's section) - Excel writes dd\.mm\.yyyy for dd.mm.yyyy; the code itself when nothing goes
function ShownFormat(const aCode: string): string;

// a number as a number format would show it, close enough for its width: Delphi's FormatFloat and FormatDateTime take
// most of Excel's codes
function ShownNumber(aNumber: Double; const aCode: string): string;

implementation

uses System.SysUtils, System.StrUtils, System.Math, System.TypInfo, ProRock.Calcite.Utility;

type
  TFormatTokenKind = (tkLiteral, tkQuoted, tkEscaped, tkPadding, tkFill, tkBracket, tkSection, tkDigit, tkPoint, tkComma,
    tkPercent, tkExponent, tkText, tkGeneral, tkDate, tkCalendar);

  // a code's piece at Start .. Finish - 1 in its section (Section, from 0; a ; ends the one before it): "..." with its quotes,
  // \x, _x, *x, [...], E with its + or -, B with its 1 or 2, AM/PM and A/P whole; one character otherwise
  TFormatToken = record
    Kind: TFormatTokenKind;
    Start, Finish, Section: integer;
  end;

  TFormatFailure = (ffNone, ffQuote, ffBracket, ffEnd);

  // a code's pieces in turn, each told by its characters, never by the section's meaning. Nothing managed (a record with a
  // string is set up and cleared on every call): the caller keeps the code alive while it reads
  TFormatScanner = record
  private
    fText: PChar; // the code's first character
    fLength, fIndex, fSection: integer;
    fFailure: TFormatFailure;
    fFailed: Char; // the \, _ or * at the end
    function At(aIndex: integer): Char; inline;
    function Fail(aFailure: TFormatFailure): boolean;
    function Passed(const aWord: string): boolean;
    function Closing(aClose: Char): integer;
  public
    constructor Create(const aCode: string);
    // False at the end or when the code reads no further (Error)
    function Next(out aToken: TFormatToken): boolean;
    function Error: string; // why reading stopped; '' at the code's end
  end;

constructor TFormatScanner.Create(const aCode: string);
begin
  fText := PChar(aCode);
  fLength := aCode.Length;
  fIndex := 1;
  fSection := 0;
  fFailure := ffNone;
  fFailed := #0;
end;

function TFormatScanner.At(aIndex: integer): Char;
begin
  Result := fText[aIndex - 1];
end;

function TFormatScanner.Fail(aFailure: TFormatFailure): boolean;
begin
  fFailure := aFailure;
  fIndex := fLength + 1;
  Result := False;
end;

function TFormatScanner.Error: string;
begin
  case fFailure of
    ffQuote:
      Result := 'a quote not closed';
    ffBracket:
      Result := 'a [ not closed';
    ffEnd:
      Result := fFailed + ' at the end, with nothing after it';
  else
    Result := '';
  end;
end;

// whether the code goes on with aWord, in any case: passed when it does
function TFormatScanner.Passed(const aWord: string): boolean;
begin
  Result := fIndex + aWord.Length - 1 <= fLength;
  for var i := 1 to aWord.Length do
    Result := Result and (UpCase(At(fIndex + i - 1)) = UpCase(aWord[i]));
  if Result then
    Inc(fIndex, aWord.Length);
end;

// the index of aClose from fIndex on, 0 when there is none
function TFormatScanner.Closing(aClose: Char): integer;
begin
  for var i := fIndex to fLength do
    if At(i) = aClose then
      Exit(i);
  Result := 0;
end;

// the kind of a piece of one character
function CharKind(aChar: Char): TFormatTokenKind;
begin
  case aChar of
    '0', '#', '?':
      Result := tkDigit;
    '.':
      Result := tkPoint;
    ',':
      Result := tkComma;
    '%':
      Result := tkPercent;
    '@':
      Result := tkText;
    'b', 'd', 'D', 'e', 'g', 'G', 'h', 'H', 'm', 'M', 'y', 'Y', 's', 'S': // g: an era
      Result := tkDate;
  else
    Result := tkLiteral;
  end;
end;

function TFormatScanner.Next(out aToken: TFormatToken): boolean;
begin
  if fIndex > fLength then
    Exit(False);
  aToken.Start := fIndex;
  aToken.Section := fSection;
  var c: Char := At(fIndex);
  aToken.Kind := CharKind(c);
  if CharInSet(c, ['G', 'g']) and Passed('General') then
    aToken.Kind := tkGeneral
  else if CharInSet(c, ['A', 'a']) and (Passed('AM/PM') or Passed('A/P')) then
    aToken.Kind := tkDate
  else
  begin
    Inc(fIndex);
    var after: Char := #0;
    if fIndex <= fLength then
      after := At(fIndex);
    case c of
      '"':
        begin
          aToken.Kind := tkQuoted;
          fIndex := Closing('"') + 1;
          if fIndex = 1 then
            Exit(Fail(ffQuote));
        end;
      '[':
        begin
          aToken.Kind := tkBracket;
          fIndex := Closing(']') + 1;
          if fIndex = 1 then
            Exit(Fail(ffBracket));
        end;
      '\', '_', '*':
        begin
          if after = #0 then
          begin
            fFailed := c;
            Exit(Fail(ffEnd));
          end;
          if c = '\' then
            aToken.Kind := tkEscaped
          else if c = '_' then
            aToken.Kind := tkPadding
          else
            aToken.Kind := tkFill;
          Inc(fIndex);
        end;
      ';':
        begin
          aToken.Kind := tkSection;
          Inc(fSection);
        end;
      'E':
        begin
          aToken.Kind := tkExponent;
          if CharInSet(after, ['+', '-']) then
            Inc(fIndex);
        end;
      'B':
        begin
          aToken.Kind := tkCalendar;
          if CharInSet(after, ['1', '2']) then
            Inc(fIndex);
        end;
    end;
  end;
  aToken.Finish := fIndex;
  Result := True;
end;

type
  TFormatBracket = (fbUnknown, fbColor, fbCondition, fbLocale, fbElapsed, fbNumerals);

// what a [...] holds (aInside in lower case, without its brackets)
function BracketKind(const aInside: string): TFormatBracket;
const
  cColors: array[0 .. 7] of string = ('black', 'blue', 'cyan', 'green', 'magenta', 'red', 'white', 'yellow');
begin
  var number: integer;
  if MatchStr(aInside, cColors) or (aInside.StartsWith('color') and TryStrToInt(aInside.Substring(5), number) and
    (number >= 1) and (number <= 56)) then
    Result := fbColor
  else if (aInside <> '') and CharInSet(aInside[1], ['<', '>', '=']) then
    Result := fbCondition
  else if aInside.StartsWith('$') then
    Result := fbLocale // a currency or a locale
  else if (aInside <> '') and CharInSet(aInside[1], ['h', 'm', 's']) and (aInside.Trim([aInside[1]]) = '') then
    Result := fbElapsed
  else if aInside.StartsWith('dbnum') and TryStrToInt(aInside.Substring(5), number) then
    Result := fbNumerals // East Asian numerals
  else
    Result := fbUnknown;
end;

type
  // a section's tokens summed up in turn: what it has, the first reason Excel would not open it
  TFormatSummary = record
    Section: TFormatSection;
    Colors, Conditions: integer;
    Seconds: boolean; // the last date code: decimals of seconds may follow
    Decimals: boolean; // just after a seconds' point: its zeros follow
    Zeros: integer;
    procedure Bracket(const aInside: string);
    procedure Take(const aCode: string; const aToken: TFormatToken);
  end;

procedure TFormatSummary.Bracket(const aInside: string);
begin
  case BracketKind(aInside) of
    fbColor:
      begin
        Inc(Colors);
        if Colors > 1 then
          Section.Error := 'two colors in one section';
      end;
    fbCondition:
      begin
        var operatorLength: integer := 1;
        if (aInside.Length > 1) and CharInSet(aInside[2], ['>', '=']) and (aInside[1] <> '=') then
          operatorLength := 2;
        Inc(Conditions);
        var number: Double;
        if not TryStrToFloat(aInside.Substring(operatorLength).Trim, number, TFormatSettings.Invariant) then
          Section.Error := 'a condition without a number: [' + aInside + ']'
        else if Conditions > 1 then
          Section.Error := 'two conditions in one section';
      end;
    fbElapsed:
      begin
        Section.Dates := True;
        Seconds := aInside[1] = 's';
      end;
    fbUnknown:
      Section.Error := 'Excel has no [' + aInside + ']';
  end;
end;

procedure TFormatSummary.Take(const aCode: string; const aToken: TFormatToken);
begin
  if Section.Error <> '' then
    Exit;
  var c: Char := aCode[aToken.Start];
  if Decimals and (aToken.Kind = tkDigit) and (c = '0') then
  begin
    Inc(Zeros);
    if Zeros > 3 then
      Section.Error := 'more than three decimals of seconds';
    Exit;
  end;
  Decimals := False;
  case aToken.Kind of
    tkBracket:
      Bracket(LowerCase(Copy(aCode, aToken.Start + 1, aToken.Finish - aToken.Start - 2)));
    tkDigit:
      begin
        Section.Digits := True;
        Seconds := False;
      end;
    tkPoint:
      if Seconds then
      begin
        Decimals := True;
        Zeros := 0;
      end;
    tkExponent:
      begin
        if aToken.Finish - aToken.Start = 1 then
          Section.Error := 'E without + or - after it'
        else if (aToken.Finish > aCode.Length) or not CharInSet(aCode[aToken.Finish], ['0', '#', '?']) then
          Section.Error := 'E+ without a digit placeholder after it';
        Section.Digits := True;
      end;
    tkText:
      Section.Text := True;
    tkGeneral:
      Section.General := True;
    tkCalendar:
      if aToken.Finish - aToken.Start = 1 then
        Section.Error := 'B without 1 or 2 after it';
    tkDate:
      begin
        Section.Dates := True;
        case c of
          's', 'S':
            Seconds := True;
          'b', 'd', 'D', 'e', 'h', 'H', 'm', 'M', 'y', 'Y':
            Seconds := False;
        end;
      end;
    tkLiteral:
      if CharInSet(c, ['n', 'N']) then
        Section.Error := 'n (minutes are m)';
  end;
end;

function FormatSection(const aCode: string; aIndex: integer): TFormatSection;
var
  scanner: TFormatScanner;
  token: TFormatToken;
  summary: TFormatSummary;
begin
  scanner := TFormatScanner.Create(aCode);
  summary := Default(TFormatSummary);
  while scanner.Next(token) do
    if (token.Section = aIndex) and (token.Kind <> tkSection) then
      summary.Take(aCode, token);
  Result := summary.Section;
  if Result.Error = '' then
    Result.Error := scanner.Error;
end;

function NumberFormatError(const aCode: string): string;
var
  scanner: TFormatScanner;
  token: TFormatToken;
  summaries: array[0 .. 3] of TFormatSummary;
begin
  scanner := TFormatScanner.Create(aCode);
  for var i := Low(summaries) to High(summaries) do
    summaries[i] := Default(TFormatSummary);
  var count: integer := 1;
  while scanner.Next(token) do
    if token.Kind = tkSection then
      Inc(count)
    else if count <= Length(summaries) then
      summaries[count - 1].Take(aCode, token);
  if scanner.Error <> '' then
    Exit(scanner.Error);
  if count > Length(summaries) then
    Exit('more than four sections');
  for var i := 0 to count - 1 do
  begin
    var section: TFormatSection := summaries[i].Section;
    if section.Error <> '' then
      Exit(section.Error);
    if section.General and section.Digits then
      Exit('General and digit placeholders in one section');
    if section.Text and (section.Digits or section.Dates) then
      Exit('@ and digits or dates in one section');
    if section.Digits and section.Dates then
      Exit('digits and dates in one section');
    if (i = 3) and (section.Digits or section.Dates) then
      Exit('digits or dates in the fourth section, which is for text');
    if section.Text and (i < count - 1) then
      Exit('@ in a section before the last one');
  end;
  Result := '';
end;

function IsDateCode(const aCode: string): boolean;
begin
  Result := FormatSection(aCode, 0).Dates;
end;

// whether a section's codes (without quotes, brackets and escaped characters) look like another language's notation
function LocalSection(const aCodes: string): boolean;
const
  cPlaces = ['#', '0', '?'];
  cLetters: array[0 .. 5] of string = ('JJ', 'TT', 'RR', #$0414#$0414, #$041C#$041C, #$0413#$0413); // gg: an era in English
begin
  // German, Dutch, French, Polish and Russian date letters; Spanish or Italian aaaa beside a day and a month, with no y
  for var letters: string in cLetters do
    if ContainsText(aCodes, letters) then
      Exit(True);
  if ContainsText(aCodes, 'AA') and not ContainsText(aCodes, 'Y') and ContainsText(aCodes, 'M') and
    (ContainsText(aCodes, 'D') or ContainsText(aCodes, 'G')) then
    Exit(True);
  // a decimal comma: #.##0,00, or 0,00 with no point
  var n: integer := aCodes.Length;
  for var p := 1 to n do
    if (aCodes[p] = '.') and (p + 4 <= n) and CharInSet(aCodes[p + 1], cPlaces) and CharInSet(aCodes[p + 2], cPlaces) and
      CharInSet(aCodes[p + 3], cPlaces) and (aCodes[p + 4] = ',') then
      Exit(True)
    else if (aCodes[p] = ',') and not aCodes.Contains('.') and (p > 1) and CharInSet(aCodes[p - 1], cPlaces) then
    begin
      var places: integer := 0;
      while (p + places + 1 <= n) and CharInSet(aCodes[p + places + 1], cPlaces) do
        Inc(places);
      if (places in [1, 2]) and ((p + places = n) or (aCodes[p + places + 1] <> ',')) then
        Exit(True);
    end;
  Result := False;
end;

function LocalNotation(const aCode: string): string;
var
  scanner: TFormatScanner;
  token: TFormatToken;
begin
  var local: boolean := False;
  var codes: string := '';
  scanner := TFormatScanner.Create(aCode);
  while scanner.Next(token) do
    if token.Kind = tkSection then
    begin
      local := local or LocalSection(codes);
      codes := '';
    end
    else if not (token.Kind in [tkQuoted, tkEscaped, tkPadding, tkFill, tkBracket]) then
      codes := codes + Copy(aCode, token.Start, token.Finish - token.Start);
  local := local or LocalSection(codes);
  if local and (scanner.Error = '') then
    Result := 'it looks like another language''s notation: Excel''s codes are English (yyyy, mm, dd, hh, #,##0.00), each '
      + 'reader sees them in their own'
  else
    Result := '';
end;

function ShownFormat(const aCode: string): string;
var
  scanner: TFormatScanner;
  token: TFormatToken;
  summary: TFormatSummary;
  output: TTextCopy;
begin
  // each section's dates first: a \. stays outside them
  var dates: TArray<boolean> := [];
  scanner := TFormatScanner.Create(aCode);
  summary := Default(TFormatSummary);
  while scanner.Next(token) do
    if token.Kind = tkSection then
    begin
      dates := dates + [summary.Section.Dates];
      summary := Default(TFormatSummary);
    end
    else
      summary.Take(aCode, token);
  if scanner.Error <> '' then
    Exit(aCode);
  dates := dates + [summary.Section.Dates];
  scanner := TFormatScanner.Create(aCode);
  output.Start(aCode);
  try
    while scanner.Next(token) do
      if (token.Kind = tkEscaped) and (CharInSet(aCode[token.Start + 1], ['$', '-', '+', '/', '(', ')', ':', '!', '^', '&',
        '''', '~', '{', '}', '<', '>', '=', ' ']) or (dates[token.Section] and (aCode[token.Start + 1] = '.'))) then
        output.Replace(token.Start, token.Start + 1, '');
    Result := output.Done;
  finally
    output.Builder.Free;
  end;
end;

// a number as Excel's General shows it in a cell: up to 11 characters
function GeneralText(aNumber: Double): string;
begin
  Result := TUtility.FloatText(aNumber, ftDouble);
  if Result.Length <= 11 then
    Exit;
  var size: Double := Abs(aNumber);
  if (size >= 1E11) or (size < 1E-4) then
    Exit(FormatFloat('0.#####E+00', aNumber, TFormatSettings.Invariant));
  var decimals: integer := 11 - Length(IntToStr(Trunc(size))) - 1 - Ord(aNumber < 0);
  Result := FormatFloat('0.' + StringOfChar('#', Max(decimals, 0)), aNumber, TFormatSettings.Invariant);
end;

// a [...] (aBracket with its brackets) as what it shows: a currency's symbol, the elapsed hours, minutes or seconds
function BracketCode(const aBracket: string; aNumber: Double): string;
begin
  Result := '';
  var inside: string := LowerCase(Copy(aBracket, 2, aBracket.Length - 2));
  case BracketKind(inside) of
    fbLocale:
      Result := '"' + Copy(aBracket, 3, Pos('-', inside + '-') - 2) + '"';
    fbElapsed:
      case inside[1] of
        'h':
          Result := '"' + IntToStr(Trunc(aNumber * 24)) + '"';
        'm':
          Result := '"' + IntToStr(Trunc(aNumber * 1440)) + '"';
      else
        Result := '"' + IntToStr(Trunc(aNumber * 86400)) + '"';
      end;
  end;
end;

// the m's from aStart (their end aEnd) as months, or as minutes (Delphi's n) when seconds are the next code; after hours
// Delphi takes m as minutes itself. aScanner: past the first m
function MonthsCode(const aCode: string; aScanner: TFormatScanner; aStart: integer; out aEnd: integer): string;
var
  next: TFormatToken;
begin
  aEnd := aStart + 1;
  while (aEnd <= aCode.Length) and CharInSet(aCode[aEnd], ['m', 'M']) do
    Inc(aEnd);
  var letter: Char := 'm';
  while aScanner.Next(next) and (next.Kind <> tkSection) do
    if (next.Start >= aEnd) and CharInSet(aCode[next.Start], ['a' .. 'z', 'A' .. 'Z', '0']) then
    begin
      if CharInSet(aCode[next.Start], ['s', 'S']) then
        letter := 'n';
      Break;
    end;
  Result := StringOfChar(letter, aEnd - aStart);
end;

// a section's code (aIndex) as Delphi's FormatFloat or FormatDateTime takes it: literals quoted, padding and fills as a space
// or nothing, brackets as what they show; aScale - 100 for each %
function DelphiCode(const aCode: string; aIndex: integer; aNumber: Double; out aScale: Double): string;
var
  scanner: TFormatScanner;
  token: TFormatToken;
  count: integer; // Result's characters written: it is the buffer

  procedure Grow(aMore: integer);
  begin
    if count + aMore > Result.Length then
      SetLength(Result, 2 * (count + aMore));
  end;

  procedure Add(const aText: string);
  begin
    Grow(aText.Length);
    if aText <> '' then
      Move(aText[1], Result[count + 1], aText.Length * SizeOf(Char));
    Inc(count, aText.Length);
  end;

  procedure AddChar(aChar: Char);
  begin
    Grow(1);
    Inc(count);
    Result[count] := aChar;
  end;

begin
  aScale := 1;
  var seconds: boolean := False; // just after s: a point and zeros are its decimals (Delphi's z)
  var decimals: boolean := False;
  var written: integer := 0; // the m's before it are written already
  SetLength(Result, 2 * aCode.Length + 16);
  count := 0;
  scanner := TFormatScanner.Create(aCode);
  while scanner.Next(token) do
  begin
    if (token.Section <> aIndex) or (token.Kind = tkSection) then
      Continue;
    var c: Char := aCode[token.Start];
    if decimals and (token.Kind = tkDigit) and (c = '0') then
    begin
      AddChar('z');
      Continue;
    end;
    decimals := seconds and (token.Kind = tkPoint);
    seconds := (token.Kind = tkDate) and CharInSet(c, ['s', 'S']);
    case token.Kind of
      tkEscaped:
        Add('"' + aCode[token.Start + 1] + '"');
      tkPadding:
        AddChar(' ');
      tkFill, tkCalendar:
        ;
      tkBracket:
        Add(BracketCode(Copy(aCode, token.Start, token.Finish - token.Start), aNumber));
      tkPercent:
        begin
          aScale := aScale * 100;
          Add('"%"');
        end;
      tkGeneral:
        Add('"' + GeneralText(aNumber) + '"');
    else
      if (token.Kind = tkDigit) and (c = '?') then
        AddChar('0')
      else if (token.Kind = tkDate) and CharInSet(c, ['e', 'b']) then
        Add('yyyy') // the year: Delphi has no Buddhist one
      else if (token.Kind = tkDate) and CharInSet(c, ['m', 'M']) then
      begin
        if token.Start >= written then
          Add(MonthsCode(aCode, scanner, token.Start, written));
      end
      else
        for var i := token.Start to token.Finish - 1 do
          AddChar(aCode[i]);
    end;
  end;
  SetLength(Result, count);
end;

function ShownNumber(aNumber: Double; const aCode: string): string;
var
  scanner: TFormatScanner;
  token: TFormatToken;
begin
  var count: integer := 1;
  scanner := TFormatScanner.Create(aCode);
  while scanner.Next(token) do
    if token.Kind = tkSection then
      Inc(count);
  if scanner.Error <> '' then
    Exit(GeneralText(aNumber));
  var index: integer := 0;
  if (aNumber < 0) and (count >= 2) then
  begin
    index := 1;
    aNumber := -aNumber;
  end
  else if (aNumber = 0) and (count >= 3) then
    index := 2;
  var info: TFormatSection := FormatSection(aCode, index);
  if info.Text then
    Exit(GeneralText(aNumber));
  var scale: Double;
  var code: string := DelphiCode(aCode, index, aNumber, scale);
  try
    if info.Dates then
      Result := FormatDateTime(code, TUtility.SerialToDate(aNumber, False), TFormatSettings.Invariant)
    else if info.Digits then
      Result := FormatFloat(code, aNumber * scale, TFormatSettings.Invariant)
    else if code = '' then
      Result := GeneralText(aNumber)
    else
      Result := StringReplace(code, '"', '', [rfReplaceAll]);
  except
    Result := GeneralText(aNumber);
  end;
end;

end.
