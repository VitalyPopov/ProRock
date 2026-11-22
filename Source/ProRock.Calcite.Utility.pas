unit ProRock.Calcite.Utility;

// Excel's language, format-neutral: limits, A1 addresses and references, serial dates, text widths, colors (internal)

interface

uses System.SysUtils, System.Math, System.Variants;

const
  cMaxSheetName = 31; // UTF-16 units, as Excel counts
  cMaxRow = 1048576;
  cMaxColumn = 16384;
  cMaxText = 32767;
  cMaxFormula = 8192;

type
  TReferenceKind = (rkNone, rkCell, rkColumn, rkRow);

function ColumnName(aColumn: integer): string;
function CellName(aRow, aColumn: integer): string;
// the letters from aIndex on as a column number (0: none, or beyond XFD); aIndex moves past them
function ReadColumn(const aText: string; var aIndex: integer): integer;
function ReadRow(const aText: string; var aIndex: integer): integer;
// a cell's r (B5) -> its column; 0 when it has none
function ColumnOf(const aReference: string): integer;
// B5, $B$5, A1:C10, 5:7, B:D
function ParseAddress(const aAddress: string; out aTop, aLeft, aBottom, aRight: integer): boolean;
// A1, $A$1, A, $A, 5, $5 (a column and a row count only as one end of A:C or 5:7)
function ReadReference(const aWord: string; out aRow, aColumn: integer; out aRowFixed, aColumnFixed: boolean): TReferenceKind;
// a reference's relative parts moved; False off the sheet
function MoveReference(aKind: TReferenceKind; aRow, aColumn: integer; aRowFixed, aColumnFixed: boolean;
  aRows, aColumns: integer; out aText: string): boolean;

type
  TReferenceChange = (rcFill, rcInsert, rcDelete);

  // a table's rows (with its header and totals) and columns, its data rows among them
  TTableBody = record
    Left, Right, Top, DataTop, DataBottom, Bottom: integer;
  end;

  // how a formula's references change, as Excel changes them. A fill moves the relative parts of every reference. An insert
  // or delete of rows or columns on one sheet moves each reference into it at or past the cut, the absolute parts too (in a
  // defined name the relative parts stay, as Excel keeps them); a range grows or shrinks, one wholly deleted or pushed off
  // the sheet is #REF!, one reaching the last row or column keeps reaching it. 3-D references (Sheet1:Sheet3!A1) and other
  // workbooks' stay, as in Excel
  TReferenceMap = record
    Change: TReferenceChange;
    Rows, Columns: integer; // a fill's offset
    Sheet: string; // the sheet with rows or columns inserted or deleted
    ByRows: boolean;
    First, Count: integer; // from row or column First, Count of them
    OnSheet: boolean; // a reference without a sheet's name is on Sheet: the formula is there
    InName: boolean; // the formula is a defined name's
    // tables deleted with the rows or columns (Sales) and table columns (Sales[Q1]): Excel writes #REF! for what names them
    GoneTables: TArray<string>;
    // the sheet's tables: a range in one's columns over all its data rows grows with rows inserted at its first data row or
    // its totals row, as the table does
    Bodies: TArray<TTableBody>;
    class function Fill(aRows, aColumns: integer): TReferenceMap; static;
    class function Inserted(const aSheet: string; aByRows: boolean; aFirst, aCount: integer): TReferenceMap; static;
    class function Deleted(const aSheet: string; aByRows: boolean; aFirst, aCount: integer): TReferenceMap; static;
    // whether the references after a prefix change: aPrefix as written before its ! (Data, 'My Sheet', [1]Data,
    // Data:Three), '' for none
    function Changes(const aPrefix: string): boolean;
    // a reference read by ReadReference, alone or a range's first end with its second (aRange): False for #REF!, aText ''
    // when it stays as written
    function Map(aKind: TReferenceKind; aRow, aColumn: integer; aRowFixed, aColumnFixed, aRange: boolean; aRow2, aColumn2: integer;
      aRowFixed2, aColumnFixed2: boolean; out aText: string): boolean;
    // whether Table[...] (aBrackets with its [ and ]) names a table or column gone: Excel writes #REF! for it
    function TableGone(const aTable, aBrackets: string): boolean;
  end;

// the columns a structured reference's brackets name ([Sales], [[#This Row],[Sales]], [[Q1]:[Q3]], [@Sales]), their '
// escapes undone; # specifiers left out
function TableColumns(const aBrackets: string): TArray<string>;

// Excel's serial numbers: days from 1899-12-30 as TDateTime, but in the 1900 system the serials before 1900-03-01 count a
// 1900-02-29 that never was (60 reads as 1900-02-28); a serial below 1 is a time of day
function SerialToDate(aSerial: Double; a1904: boolean): TDateTime;
// False before the system's first day (1900-01-01, 1904-01-01); a TDateTime below 1 is a time of day
function DateToSerial(aDate: TDateTime; a1904: boolean; out aSerial: Double): boolean;

// a text's width in pixels at size 11, the widest line: ASCII as Excel's AutoFit measures Aptos Narrow (aFont) or Calibri
// (any other font), the rest estimated
function TextPixels(const aText, aFont: string; aBold: boolean): Double;

// colors as Excel's Color (BGR, TColor's order)
// a tint or shade (-1 darkest, 1 lightest) as Excel applies it: its integer HLS (240 steps), each product truncated
function TintedColor(aColor: integer; aTint: Double): integer;
// an indexed color in Excel's default palette: 0-63, 64 the system's text (black), 65 its window (white); others black
function PaletteColor(aIndex: integer): integer;

// an item of an array for a range, from 0: two dimensions, or one (a row)
function ArrayItem(const aArray: Variant; aRow, aColumn: integer): Variant;
// empty, null or '': what clears a cell's formula
function IsNoFormula(const aValue: Variant): boolean;

implementation

function ColumnName(aColumn: integer): string;
begin
  Result := '';
  while aColumn > 0 do
  begin
    Result := Char(Ord('A') + (aColumn - 1) mod 26) + Result;
    aColumn := (aColumn - 1) div 26;
  end;
end;

function CellName(aRow, aColumn: integer): string;
begin
  Result := ColumnName(aColumn) + IntToStr(aRow);
end;

function ReadColumn(const aText: string; var aIndex: integer): integer;
begin
  Result := 0;
  while aIndex <= aText.Length do
  begin
    var letter: Char := aText[aIndex];
    if CharInSet(letter, ['a' .. 'z']) then
      letter := Char(Ord(letter) - 32)
    else if not CharInSet(letter, ['A' .. 'Z']) then
      Break;
    Result := Result * 26 + Ord(letter) - Ord('A') + 1;
    if Result > cMaxColumn then
      Exit(0);
    Inc(aIndex);
  end;
end;

function ReadRow(const aText: string; var aIndex: integer): integer;
begin
  Result := 0;
  while (aIndex <= aText.Length) and CharInSet(aText[aIndex], ['0' .. '9']) do
  begin
    Result := Result * 10 + Ord(aText[aIndex]) - Ord('0');
    if Result > cMaxRow then
      Exit(0);
    Inc(aIndex);
  end;
end;

function ColumnOf(const aReference: string): integer;
begin
  var index: integer := 1;
  Result := ReadColumn(aReference, index);
end;

function ParseAddress(const aAddress: string; out aTop, aLeft, aBottom, aRight: integer): boolean;

  // one end: a cell, a row or a column (0 for the part missing)
  function ReadEnd(const aText: string; out aRow, aColumn: integer): boolean;
  begin
    var index: integer := 1;
    if (index <= aText.Length) and (aText[index] = '$') then
      Inc(index);
    var start: integer := index;
    aColumn := ReadColumn(aText, index);
    if (aColumn = 0) and (index > start) then
      Exit(False); // beyond XFD
    if (index <= aText.Length) and (aText[index] = '$') then
      Inc(index);
    start := index;
    aRow := ReadRow(aText, index);
    if (aRow = 0) and (index > start) then
      Exit(False); // 0 or beyond the last row
    Result := (index > aText.Length) and ((aRow > 0) or (aColumn > 0));
  end;

begin
  Result := False;
  var ends: TArray<string> := aAddress.Trim.Split([':']);
  if not (Length(ends) in [1, 2]) then
    Exit;
  var row1, column1, row2, column2: integer;
  if not ReadEnd(ends[0], row1, column1) then
    Exit;
  if Length(ends) = 1 then
  begin
    if (row1 = 0) or (column1 = 0) then
      Exit; // a lone 5 or B
    row2 := row1;
    column2 := column1;
  end
  else if not ReadEnd(ends[1], row2, column2) or ((row1 = 0) <> (row2 = 0)) or ((column1 = 0) <> (column2 = 0)) then
    Exit;
  if row1 = 0 then
  begin // whole columns
    row1 := 1;
    row2 := cMaxRow;
  end;
  if column1 = 0 then
  begin // whole rows
    column1 := 1;
    column2 := cMaxColumn;
  end;
  aTop := Min(row1, row2);
  aBottom := Max(row1, row2);
  aLeft := Min(column1, column2);
  aRight := Max(column1, column2);
  Result := True;
end;

function ReadReference(const aWord: string; out aRow, aColumn: integer; out aRowFixed, aColumnFixed: boolean): TReferenceKind;
begin
  Result := rkNone;
  var index: integer := 1;
  aColumnFixed := (index <= aWord.Length) and (aWord[index] = '$');
  if aColumnFixed then
    Inc(index);
  var start: integer := index;
  aColumn := ReadColumn(aWord, index);
  var letters: boolean := index > start;
  if letters and (aColumn = 0) then
    Exit;
  if aColumnFixed and not letters then
  begin // $5: the $ was the row's
    aColumnFixed := False;
    aRowFixed := True;
  end
  else
  begin
    aRowFixed := (index <= aWord.Length) and (aWord[index] = '$');
    if aRowFixed then
      Inc(index);
  end;
  start := index;
  aRow := ReadRow(aWord, index);
  var digits: boolean := index > start;
  if (index <= aWord.Length) or (digits and (aRow = 0)) then
    Exit;
  if letters and digits then
    Result := rkCell
  else if letters and not aRowFixed then
    Result := rkColumn
  else if digits and not aColumnFixed then
    Result := rkRow;
end;

function MoveReference(aKind: TReferenceKind; aRow, aColumn: integer; aRowFixed, aColumnFixed: boolean;
  aRows, aColumns: integer; out aText: string): boolean;
begin
  if not aRowFixed and (aKind in [rkCell, rkRow]) then
    Inc(aRow, aRows);
  if not aColumnFixed and (aKind in [rkCell, rkColumn]) then
    Inc(aColumn, aColumns);
  Result := ((aKind = rkColumn) or ((aRow >= 1) and (aRow <= cMaxRow))) and
    ((aKind = rkRow) or ((aColumn >= 1) and (aColumn <= cMaxColumn)));
  aText := '';
  if aKind in [rkCell, rkColumn] then
  begin
    if aColumnFixed then
      aText := '$';
    aText := aText + ColumnName(aColumn);
  end;
  if aKind in [rkCell, rkRow] then
  begin
    if aRowFixed then
      aText := aText + '$';
    aText := aText + IntToStr(aRow);
  end;
end;

function TableColumns(const aBrackets: string): TArray<string>;
var
  inner: string;
  i: integer;

  // one name up to the ] that closes it (or the end), from i on
  function Name: string;
  begin
    Result := '';
    while (i <= inner.Length) and (inner[i] <> ']') do
    begin
      if (inner[i] = '''') and (i < inner.Length) then
        Inc(i);
      Result := Result + inner[i];
      Inc(i);
    end;
  end;

  procedure Add(const aName: string);
  begin
    if (aName <> '') and (aName[1] <> '#') then
      Result := Result + [aName.Trim];
  end;

begin
  Result := nil;
  inner := Copy(aBrackets, 2, aBrackets.Length - 2);
  i := 1;
  if inner.StartsWith('@') then
    i := 2;
  if (i > inner.Length) or (inner[i] <> '[') then
  begin // [Sales], [@Sales], [#Totals], []
    Add(Name);
    Exit;
  end;
  while i <= inner.Length do
    if inner[i] = '[' then
    begin
      Inc(i);
      Add(Name);
      Inc(i);
    end
    else
      Inc(i); // , : @ and spaces between them
end;

class function TReferenceMap.Fill(aRows, aColumns: integer): TReferenceMap;
begin
  Result := Default(TReferenceMap);
  Result.Change := rcFill;
  Result.Rows := aRows;
  Result.Columns := aColumns;
end;

class function TReferenceMap.Inserted(const aSheet: string; aByRows: boolean; aFirst, aCount: integer): TReferenceMap;
begin
  Result := Default(TReferenceMap);
  Result.Change := rcInsert;
  Result.Sheet := aSheet;
  Result.ByRows := aByRows;
  Result.First := aFirst;
  Result.Count := aCount;
end;

class function TReferenceMap.Deleted(const aSheet: string; aByRows: boolean; aFirst, aCount: integer): TReferenceMap;
begin
  Result := Inserted(aSheet, aByRows, aFirst, aCount);
  Result.Change := rcDelete;
end;

function TReferenceMap.Changes(const aPrefix: string): boolean;
begin
  if Change = rcFill then
    Exit((Rows <> 0) or (Columns <> 0));
  if aPrefix = '' then
    Exit(OnSheet);
  var name: string := aPrefix;
  if (name.Length >= 2) and (name[1] = '''') and (name[name.Length] = '''') then
    name := Copy(name, 2, name.Length - 2).Replace('''''', '''');
  // another workbook's or 3-D: a sheet's name has neither [ nor :
  Result := not name.StartsWith('[') and not name.Contains(':') and AnsiSameText(name, Sheet);
end;

function TReferenceMap.TableGone(const aTable, aBrackets: string): boolean;
begin
  var columns: TArray<string> := nil;
  for var gone: string in GoneTables do
  begin
    var bracket: integer := gone.IndexOf('[');
    if bracket < 0 then
    begin
      if AnsiSameText(gone, aTable) then
        Exit(True);
    end
    else if AnsiSameText(gone.Substring(0, bracket), aTable) then
    begin
      if columns = nil then
        columns := TableColumns(aBrackets);
      for var column: string in columns do
        if AnsiSameText(column, gone.Substring(bracket + 1, gone.Length - bracket - 2)) then
          Exit(True);
    end;
  end;
  Result := False;
end;

function TReferenceMap.Map(aKind: TReferenceKind; aRow, aColumn: integer; aRowFixed, aColumnFixed, aRange: boolean;
  aRow2, aColumn2: integer; aRowFixed2, aColumnFixed2: boolean; out aText: string): boolean;
var
  low, high, limit: integer;
  lowFixed, highFixed: boolean;

  // one end alone: False when it is deleted or pushed off the sheet
  function MapOne(var aValue: integer; aFixed: boolean): boolean;
  begin
    Result := True;
    if InName and not aFixed then
      Exit;
    if Change = rcInsert then
    begin
      if aValue >= First then
        Inc(aValue, Count);
      Result := aValue <= limit;
    end
    else if aValue >= First + Count then
      Dec(aValue, Count)
    else if aValue >= First then
      Result := False;
  end;

  // a range's ends, low <= high
  function MapRange: boolean;
  begin
    if InName and (not lowFixed or not highFixed) then
      Exit(MapOne(low, lowFixed) and MapOne(high, highFixed));
    var last: integer := First + Count - 1;
    if Change = rcInsert then
    begin
      if (low = 1) and (high = limit) then // every row or column stays so
        Exit(True);
      if ByRows and (aKind = rkCell) then
        for var body: TTableBody in Bodies do
          if (Min(aColumn, aColumn2) >= body.Left) and (Max(aColumn, aColumn2) <= body.Right) and (low >= body.Top) and
            (low <= body.DataTop) and (high >= body.DataBottom) and (high <= body.Bottom) and
            ((First = body.DataTop) or (First = body.DataBottom + 1) and (First <= body.Bottom)) then
          begin
            high := Min(high + Count, limit);
            Exit(True);
          end;
      if low >= First then
        Inc(low, Count);
      if high >= First then
        high := Min(high + Count, limit);
      Exit(low <= limit);
    end;
    if (low >= First) and (high <= last) then
      Exit(False);
    if low > last then
      Dec(low, Count)
    else if low >= First then
      low := First;
    if high = limit then
      // reaching the last row or column, it keeps reaching it
    else if high > last then
      Dec(high, Count)
    else if high >= First then
      high := First - 1;
    Result := True;
  end;

  function Text(aKind: TReferenceKind; aRow, aColumn: integer; aRowFixed, aColumnFixed: boolean): string;
  begin
    MoveReference(aKind, aRow, aColumn, aRowFixed, aColumnFixed, 0, 0, Result);
  end;

begin
  aText := '';
  if Change = rcFill then
  begin
    var moved2: string;
    Result := MoveReference(aKind, aRow, aColumn, aRowFixed, aColumnFixed, Rows, Columns, aText) and
      (not aRange or MoveReference(aKind, aRow2, aColumn2, aRowFixed2, aColumnFixed2, Rows, Columns, moved2));
    if aRange then
      aText := aText + ':' + moved2;
    Exit;
  end;
  Result := True;
  if (ByRows and (aKind = rkColumn)) or (not ByRows and (aKind = rkRow)) then
    Exit;
  if not aRange then
  begin
    aRow2 := aRow;
    aColumn2 := aColumn;
    aRowFixed2 := aRowFixed;
    aColumnFixed2 := aColumnFixed;
  end;
  // a range written backwards (A5:A1) as low and high
  var swapped: boolean;
  if ByRows then
  begin
    limit := cMaxRow;
    swapped := aRow > aRow2;
    low := Min(aRow, aRow2);
    high := Max(aRow, aRow2);
    lowFixed := (aRowFixed and not swapped) or (aRowFixed2 and swapped);
    highFixed := (aRowFixed2 and not swapped) or (aRowFixed and swapped);
  end
  else
  begin
    limit := cMaxColumn;
    swapped := aColumn > aColumn2;
    low := Min(aColumn, aColumn2);
    high := Max(aColumn, aColumn2);
    lowFixed := (aColumnFixed and not swapped) or (aColumnFixed2 and swapped);
    highFixed := (aColumnFixed2 and not swapped) or (aColumnFixed and swapped);
  end;
  var oldLow: integer := low;
  var oldHigh: integer := high;
  if aRange then
    Result := MapRange
  else
    Result := MapOne(low, lowFixed);
  if not Result or ((low = oldLow) and (high = oldHigh)) then
    Exit;
  if not aRange then
    high := low;
  if swapped then
  begin
    var value: integer := low;
    low := high;
    high := value;
  end;
  if ByRows then
  begin
    aRow := low;
    aRow2 := high;
  end
  else
  begin
    aColumn := low;
    aColumn2 := high;
  end;
  if not aRange then
    aText := Text(aKind, aRow, aColumn, aRowFixed, aColumnFixed)
  else if (aKind = rkCell) and (Min(aColumn, aColumn2) = 1) and (Max(aColumn, aColumn2) = cMaxColumn) then
    // every column: Excel writes the rows, 5:7
    aText := Text(rkRow, aRow, 0, aRowFixed, False) + ':' + Text(rkRow, aRow2, 0, aRowFixed2, False)
  else if (aKind = rkCell) and (Min(aRow, aRow2) = 1) and (Max(aRow, aRow2) = cMaxRow) then
    aText := Text(rkColumn, 0, aColumn, False, aColumnFixed) + ':' + Text(rkColumn, 0, aColumn2, False, aColumnFixed2)
  else
    aText := Text(aKind, aRow, aColumn, aRowFixed, aColumnFixed) + ':' + Text(aKind, aRow2, aColumn2, aRowFixed2, aColumnFixed2);
end;

function SerialToDate(aSerial: Double; a1904: boolean): TDateTime;
begin
  if aSerial < 1 then
    Result := aSerial
  else if a1904 then
    Result := aSerial + 1462
  else if aSerial < 60 then
    Result := aSerial + 1
  else
    Result := aSerial;
end;

function DateToSerial(aDate: TDateTime; a1904: boolean; out aSerial: Double): boolean;
begin
  Result := True;
  if (aDate >= 0) and (aDate < 1) then
    aSerial := aDate
  else if a1904 then
  begin
    aSerial := aDate - 1462;
    Result := aSerial >= 0;
  end
  else if aDate < 61 then
  begin
    aSerial := aDate - 1;
    Result := aSerial >= 1;
  end
  else
    aSerial := aDate;
end;

function TextPixels(const aText, aFont: string; aBold: boolean): Double;
const
  // ' ' to '~', a pixel width each in hex (Excel 365 at 96 dpi, size 11); regular, bold
  cCalibri: array[boolean] of string = (
    '35677BA3557745467777777777447777D988977994586CAA8A87799D877565774786885784474C888856587B7765757',
    '35777BB4557745467777777777447777D988977A94586DAA8A877A9E887565775786885784474C888856587B7765757');
  cAptosNarrow: array[boolean] of string = (
    '35577B93557745457777777777447777C888977994586BAA8A87798C877454867887874784474C888857486A6664747',
    '35677B93557745457777777777447777B88AA87AA4587BAA8A98798D887555867787885784474C888857587A7765757');
begin
  Result := 0;
  var table: string := cCalibri[aBold];
  if SameText(aFont, 'Aptos Narrow') then
    table := cAptosNarrow[aBold];
  var line: Double := 0;
  for var i := 1 to aText.Length do
  begin
    var c: char := aText[i];
    var width: Double;
    case c of
      #10:
        begin
          Result := Max(Result, line);
          line := 0;
          Continue;
        end;
      ' ' .. '~':
        begin
          var digit: integer := Ord(table[Ord(c) - 31]) - Ord('0');
          if digit > 9 then
            Dec(digit, Ord('A') - Ord('9') - 1);
          line := line + digit;
          Continue;
        end;
      #$DC00 .. #$DFFF:
        Continue; // the second half of a pair: counted with the first
      #$1100 .. #$115F, #$2E80 .. #$A4CF, #$AC00 .. #$D7A3, #$D800 .. #$DBFF, #$F900 .. #$FAFF, #$FE30 .. #$FE4F,
      #$FF00 .. #$FF60, #$FFE0 .. #$FFE6:
        width := 16; // East Asian wide, and the pairs (emoji)
    else
      width := 7.5;
    end;
    if aBold then
      width := width * 1.04;
    line := line + width;
  end;
  Result := Max(Result, line);
end;

function TintedColor(aColor: integer; aTint: Double): integer;
const
  cMax = 240;

  function HueValue(aLow, aHigh, aHue: integer): integer;
  begin
    aHue := (aHue mod cMax + cMax) mod cMax;
    if aHue < cMax div 6 then
      Result := aLow + ((aHigh - aLow) * aHue + cMax div 12) div (cMax div 6)
    else if aHue < cMax div 2 then
      Result := aHigh
    else if aHue < cMax * 2 div 3 then
      Result := aLow + ((aHigh - aLow) * (cMax * 2 div 3 - aHue) + cMax div 12) div (cMax div 6)
    else
      Result := aLow;
  end;

begin
  if aTint = 0 then
    Exit(aColor);
  var r: integer := aColor and $FF;
  var g: integer := aColor shr 8 and $FF;
  var b: integer := aColor shr 16 and $FF;
  var high: integer := Max(r, Max(g, b));
  var low: integer := Min(r, Min(g, b));
  var lum: integer := ((high + low) * cMax + 255) div 510;
  var hue: integer := 0;
  var sat: integer := 0;
  if high <> low then
  begin
    if lum <= cMax div 2 then
      sat := ((high - low) * cMax + (high + low) div 2) div (high + low)
    else
      sat := ((high - low) * cMax + (510 - high - low) div 2) div (510 - high - low);
    var rd: integer := ((high - r) * (cMax div 6) + (high - low) div 2) div (high - low);
    var gd: integer := ((high - g) * (cMax div 6) + (high - low) div 2) div (high - low);
    var bd: integer := ((high - b) * (cMax div 6) + (high - low) div 2) div (high - low);
    if r = high then
      hue := bd - gd
    else if g = high then
      hue := cMax div 3 + rd - bd
    else
      hue := cMax * 2 div 3 + gd - rd;
    hue := (hue mod cMax + cMax) mod cMax;
  end;
  if aTint < 0 then
    lum := Trunc(lum * (1 + aTint))
  else
    lum := Trunc(lum * (1 - aTint)) + (cMax - Trunc(cMax * (1 - aTint)));
  lum := EnsureRange(lum, 0, cMax);
  if sat = 0 then
  begin
    r := Floor(lum * 255 / cMax + 0.5);
    Exit(r or r shl 8 or r shl 16);
  end;
  var m2: integer;
  if lum <= cMax div 2 then
    m2 := (lum * (cMax + sat) + cMax div 2) div cMax
  else
    m2 := lum + sat - (lum * sat + cMax div 2) div cMax;
  var m1: integer := 2 * lum - m2;
  r := (HueValue(m1, m2, hue + cMax div 3) * 255 + cMax div 2) div cMax;
  g := (HueValue(m1, m2, hue) * 255 + cMax div 2) div cMax;
  b := (HueValue(m1, m2, hue - cMax div 3) * 255 + cMax div 2) div cMax;
  Result := r or g shl 8 or b shl 16;
end;

function PaletteColor(aIndex: integer): integer;
const
  // Excel's Colors(1..56) = indexes 8-63; 0-7 repeat the first eight
  cPalette: array[0 .. 55] of integer = (
    $000000, $FFFFFF, $0000FF, $00FF00, $FF0000, $00FFFF, $FF00FF, $FFFF00, $000080, $008000, $800000, $008080,
    $800080, $808000, $C0C0C0, $808080, $FF9999, $663399, $CCFFFF, $FFFFCC, $660066, $8080FF, $CC6600, $FFCCCC,
    $800000, $FF00FF, $00FFFF, $FFFF00, $800080, $000080, $808000, $FF0000, $FFCC00, $FFFFCC, $CCFFCC, $99FFFF,
    $FFCC99, $CC99FF, $FF99CC, $99CCFF, $FF6633, $CCCC33, $00CC99, $00CCFF, $0099FF, $0066FF, $996666, $969696,
    $663300, $669933, $003300, $003333, $003399, $663399, $993333, $333333);
begin
  case aIndex of
    0 .. 7:
      Result := cPalette[aIndex];
    8 .. 63:
      Result := cPalette[aIndex - 8];
    65:
      Result := $FFFFFF;
  else
    Result := 0;
  end;
end;

function ArrayItem(const aArray: Variant; aRow, aColumn: integer): Variant;
begin
  if VarArrayDimCount(aArray) = 2 then
    Result := aArray[VarArrayLowBound(aArray, 1) + aRow, VarArrayLowBound(aArray, 2) + aColumn]
  else
    Result := aArray[VarArrayLowBound(aArray, 1) + aColumn];
end;

function IsNoFormula(const aValue: Variant): boolean;
begin
  Result := VarIsEmpty(aValue) or VarIsNull(aValue) or (VarIsStr(aValue) and (string(aValue) = ''));
end;

end.
