unit ProRock.Calcite.Formats;

// Excel's number formats: a code checked, a number shown as it shows it (internal)

interface

type
  // what a section of a number format has, outside quotes and escapes
  TFormatSection = record
    Digits, Dates, Text, General: boolean;
    Error: string;
  end;

// a number format's sections, split at ; outside quotes, brackets and escapes; why Excel would not open it, '' - it would
function FormatSections(const aCode: string; out aSections: TArray<string>): string;

// a section of a number format that FormatSections took: digit placeholders, date and time codes, @, General
function ScanSection(const aSection: string): TFormatSection;

// why Excel would not open a file with this number format, '' - it would (each rule found by opening files in Excel)
function NumberFormatError(const aCode: string): string;

// '' or why a code looks typed in another language's Excel (TT.MM.JJJJ, aaaa-mm-dd, #.##0,00): a file keeps English codes,
// and Excel takes most of these as written - aaaa a weekday, J a letter shown as it is, 0,00 thousands
function LocalNotation(const aCode: string): string;

// a code as Excel's NumberFormat shows it: no \ before what is shown as itself anyway ($ - + / ( ) : ! ^ & ' ~ { } < > = and
// a space, a . in a date's section) - Excel writes dd\.mm\.yyyy for dd.mm.yyyy
function ShownFormat(const aCode: string): string;

// a number as a number format would show it, close enough for its width: Delphi's FormatFloat and FormatDateTime take
// most of Excel's codes
function ShownNumber(aNumber: Double; const aCode: string): string;

implementation

uses System.SysUtils, System.Math, System.TypInfo, ProRock.Calcite.Utility;

function FormatSections(const aCode: string; out aSections: TArray<string>): string;
begin
  aSections := [];
  var start: integer := 1;
  var i: integer := 1;
  while i <= aCode.Length do
  begin
    case aCode[i] of
      '"':
        begin
          i := Pos('"', aCode, i + 1);
          if i = 0 then
            Exit('a quote not closed');
        end;
      '[':
        begin
          i := Pos(']', aCode, i + 1);
          if i = 0 then
            Exit('a [ not closed');
        end;
      '\', '_', '*':
        begin
          if i = aCode.Length then
            Exit(aCode[i] + ' at the end, with nothing after it');
          Inc(i);
        end;
      ';':
        begin
          aSections := aSections + [Copy(aCode, start, i - start)];
          start := i + 1;
        end;
    end;
    Inc(i);
  end;
  aSections := aSections + [Copy(aCode, start, MaxInt)];
  Result := '';
end;

function ScanSection(const aSection: string): TFormatSection;
const
  cColors: array[0 .. 7] of string = ('black', 'blue', 'cyan', 'green', 'magenta', 'red', 'white', 'yellow');
begin
  Result := Default(TFormatSection);
  var colors: integer := 0;
  var conditions: integer := 0;
  var seconds: boolean := False; // the last date code: decimals of seconds may follow
  var n: integer := aSection.Length;
  var i: integer := 1;
  while i <= n do
  begin
    var c: char := aSection[i];
    case c of
      '"':
        i := Pos('"', aSection, i + 1);
      '\', '_', '*':
        Inc(i);
      '[':
        begin
          var close: integer := Pos(']', aSection, i + 1);
          var inside: string := LowerCase(Copy(aSection, i + 1, close - i - 1));
          var number: Double;
          var color: integer;
          var named: boolean := False;
          for var name: string in cColors do
            named := named or (inside = name);
          if named or (inside.StartsWith('color') and TryStrToInt(inside.Substring(5), color) and (color >= 1) and
            (color <= 56)) then
          begin
            Inc(colors);
            if colors > 1 then
              Result.Error := 'two colors in one section';
          end
          else if (inside <> '') and CharInSet(inside[1], ['<', '>', '=']) then
          begin
            var operatorLength: integer := 1;
            if (inside.Length > 1) and CharInSet(inside[2], ['>', '=']) and (inside[1] <> '=') then
              operatorLength := 2;
            Inc(conditions);
            if not TryStrToFloat(inside.Substring(operatorLength).Trim, number, TFormatSettings.Invariant) then
              Result.Error := 'a condition without a number: [' + inside + ']'
            else if conditions > 1 then
              Result.Error := 'two conditions in one section';
          end
          else if inside.StartsWith('$') then
            // a currency or a locale
          else if (inside <> '') and CharInSet(inside[1], ['h', 'm', 's']) and (inside.Trim([inside[1]]) = '') then
          begin // elapsed time
            Result.Dates := True;
            seconds := inside[1] = 's';
          end
          else if inside.StartsWith('dbnum') and TryStrToInt(inside.Substring(5), color) then
            // East Asian numerals
          else
            Result.Error := 'Excel has no [' + inside + ']';
          i := close;
        end;
      '0', '#', '?':
        begin
          Result.Digits := True;
          seconds := False;
        end;
      '.':
        if seconds then
        begin
          var zeros: integer := 0;
          while (i < n) and (aSection[i + 1] = '0') do
          begin
            Inc(zeros);
            Inc(i);
          end;
          if zeros > 3 then
            Result.Error := 'more than three decimals of seconds';
        end;
      'E':
        begin
          if (i = n) or not CharInSet(aSection[i + 1], ['+', '-']) then
            Result.Error := 'E without + or - after it'
          else if (i + 1 = n) or not CharInSet(aSection[i + 2], ['0', '#', '?']) then
            Result.Error := 'E+ without a digit placeholder after it';
          Result.Digits := True;
          Inc(i);
        end;
      '@':
        Result.Text := True;
      'G', 'g':
        if SameText(Copy(aSection, i, 7), 'General') then
        begin
          Result.General := True;
          Inc(i, 6);
        end
        else
          Result.Dates := True; // an era
      'A', 'a':
        if SameText(Copy(aSection, i, 5), 'AM/PM') then
        begin
          Result.Dates := True;
          Inc(i, 4);
        end
        else if SameText(Copy(aSection, i, 3), 'A/P') then
        begin
          Result.Dates := True;
          Inc(i, 2);
        end;
      'B':
        if (i < n) and CharInSet(aSection[i + 1], ['1', '2']) then
          Inc(i) // a calendar
        else
          Result.Error := 'B without 1 or 2 after it';
      'n', 'N':
        Result.Error := 'n (minutes are m)';
      'b', 'd', 'D', 'e', 'h', 'H', 'm', 'M', 'y', 'Y':
        begin
          Result.Dates := True;
          seconds := False;
        end;
      's', 'S':
        begin
          Result.Dates := True;
          seconds := True;
        end;
    end;
    if Result.Error <> '' then
      Exit;
    Inc(i);
  end;
end;

function NumberFormatError(const aCode: string): string;
begin
  var sections: TArray<string>;
  Result := FormatSections(aCode, sections);
  if Result <> '' then
    Exit;
  if Length(sections) > 4 then
    Exit('more than four sections');
  for var i := 0 to High(sections) do
  begin
    var section: TFormatSection := ScanSection(sections[i]);
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
    if section.Text and (i < High(sections)) then
      Exit('@ in a section before the last one');
  end;
end;

function LocalNotation(const aCode: string): string;
const
  cPlaces = ['#', '0', '?'];
  cLetters: array[0 .. 5] of string = ('JJ', 'TT', 'RR', #$0414#$0414, #$041C#$041C, #$0413#$0413); // gg: an era in English
  cHint = 'it looks like another language''s notation: Excel''s codes are English (yyyy, mm, dd, hh, #,##0.00), each reader '
    + 'sees them in their own';
begin
  Result := '';
  var sections: TArray<string>;
  if FormatSections(aCode, sections) <> '' then
    Exit;
  for var section: string in sections do
  begin
    // the codes alone, without quotes, brackets and escaped characters
    var codes: string := '';
    var i: integer := 1;
    while i <= section.Length do
    begin
      case section[i] of
        '"':
          i := Pos('"', section, i + 1);
        '[':
          i := Pos(']', section, i + 1);
        '\', '_', '*':
          Inc(i);
      else
        codes := codes + section[i];
      end;
      Inc(i);
    end;

    // German, Dutch, French, Polish and Russian date letters; Spanish or Italian aaaa beside a day and a month, with no y
    var upper: string := codes.ToUpper;
    for var letters: string in cLetters do
      if upper.Contains(letters) then
        Exit(cHint);
    if upper.Contains('AA') and not upper.Contains('Y') and upper.Contains('M')
      and (upper.Contains('D') or upper.Contains('G')) then
      Exit(cHint);

    // a decimal comma: #.##0,00, or 0,00 with no point
    var n: integer := codes.Length;
    for var p := 1 to n do
      if (codes[p] = '.') and (p + 4 <= n) and CharInSet(codes[p + 1], cPlaces) and CharInSet(codes[p + 2], cPlaces)
        and CharInSet(codes[p + 3], cPlaces) and (codes[p + 4] = ',') then
        Exit(cHint)
      else if (codes[p] = ',') and not codes.Contains('.') and (p > 1) and CharInSet(codes[p - 1], cPlaces) then
      begin
        var places: integer := 0;
        while (p + places + 1 <= n) and CharInSet(codes[p + places + 1], cPlaces) do
          Inc(places);
        if (places in [1, 2]) and ((p + places = n) or (codes[p + places + 1] <> ',')) then
          Exit(cHint);
      end;
  end;
end;

function ShownFormat(const aCode: string): string;
begin
  var sections: TArray<string>;
  if FormatSections(aCode, sections) <> '' then
    Exit(aCode);
  var builder: TStringBuilder := TStringBuilder.Create;
  try
    for var index := 0 to High(sections) do
    begin
      if index > 0 then
        builder.Append(';');
      var section: string := sections[index];
      var dates: boolean := ScanSection(section).Dates;
      var i: integer := 1;
      while i <= section.Length do
      begin
        var c: char := section[i];
        if c = '"' then
        begin
          var close: integer := Pos('"', section, i + 1);
          builder.Append(Copy(section, i, close - i + 1));
          i := close;
        end
        else if c = '[' then
        begin
          var close: integer := Pos(']', section, i + 1);
          builder.Append(Copy(section, i, close - i + 1));
          i := close;
        end
        else if CharInSet(c, ['\', '_', '*']) and (i < section.Length) then
        begin
          Inc(i);
          if (c <> '\') or not (CharInSet(section[i], ['$', '-', '+', '/', '(', ')', ':', '!', '^', '&', '''', '~', '{', '}',
            '<', '>', '=', ' ']) or (dates and (section[i] = '.'))) then
            builder.Append(c);
          builder.Append(section[i]);
        end
        else
          builder.Append(c);
        Inc(i);
      end;
    end;
    Result := builder.ToString;
  finally
    builder.Free;
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

function ShownNumber(aNumber: Double; const aCode: string): string;
begin
  var sections: TArray<string>;
  if FormatSections(aCode, sections) <> '' then
    Exit(GeneralText(aNumber));
  var section: string := sections[0];
  if (aNumber < 0) and (Length(sections) >= 2) then
  begin
    section := sections[1];
    aNumber := -aNumber;
  end
  else if (aNumber = 0) and (Length(sections) >= 3) then
    section := sections[2];
  var info: TFormatSection := ScanSection(section);
  if info.Text then
    Exit(GeneralText(aNumber));
  // Excel's code -> Delphi's: literals quoted, padding and fills as a space or nothing, brackets as what they show
  var code: string := '';
  var scale: Double := 1;
  var i: integer := 1;
  while i <= section.Length do
  begin
    var c: char := section[i];
    case c of
      '"':
        begin
          var close: integer := Pos('"', section, i + 1);
          code := code + Copy(section, i, close - i + 1);
          i := close;
        end;
      '\':
        begin
          Inc(i);
          code := code + '"' + section[i] + '"';
        end;
      '_':
        begin
          Inc(i);
          code := code + ' ';
        end;
      '*':
        Inc(i);
      '[':
        begin
          var close: integer := Pos(']', section, i + 1);
          var inside: string := Copy(section, i + 1, close - i - 1);
          var unitPerDay: Double := 0;
          case LowerCase(inside + ' ')[1] of
            '$':
              code := code + '"' + Copy(inside, 2, Pos('-', inside + '-') - 2) + '"';
            'h':
              unitPerDay := 24;
            'm':
              unitPerDay := 1440;
            's':
              unitPerDay := 86400;
          end;
          if unitPerDay > 0 then
            code := code + '"' + IntToStr(Trunc(aNumber * unitPerDay)) + '"';
          i := close;
        end;
      '%':
        begin
          scale := scale * 100;
          code := code + '"%"';
        end;
      '?':
        code := code + '0';
      'G', 'g':
        if SameText(Copy(section, i, 7), 'General') then
        begin
          code := code + '"' + GeneralText(aNumber) + '"';
          Inc(i, 6);
        end
        else
          code := code + c;
      'e', 'b', 'B':
        if info.Dates then
          code := code + 'yyyy'
        else
          code := code + c;
      's', 'S':
        begin
          code := code + c;
          if (i < section.Length) and (section[i + 1] = '.') then
          begin // decimals of seconds: Delphi's z
            code := code + '.';
            Inc(i);
            while (i < section.Length) and (section[i + 1] = '0') do
            begin
              code := code + 'z';
              Inc(i);
            end;
          end;
        end;
      'm', 'M':
        begin // minutes before seconds (Delphi's n); after hours Delphi takes m as minutes itself
          var j: integer := i;
          while (j < section.Length) and CharInSet(section[j + 1], ['m', 'M']) do
            Inc(j);
          var k: integer := j + 1;
          while (k <= section.Length) and not CharInSet(section[k], ['a' .. 'z', 'A' .. 'Z', '0']) do
            Inc(k);
          var letter: char := 'm';
          if (k <= section.Length) and CharInSet(section[k], ['s', 'S']) then
            letter := 'n';
          code := code + StringOfChar(letter, j - i + 1);
          i := j;
        end;
    else
      code := code + c;
    end;
    Inc(i);
  end;
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
