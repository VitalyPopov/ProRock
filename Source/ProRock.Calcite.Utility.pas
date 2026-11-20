unit ProRock.Calcite.Utility;

// Excel's language, format-neutral: limits, A1 addresses and references, serial dates, text widths (internal)

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

// Excel's serial numbers: days from 1899-12-30 as TDateTime, but in the 1900 system the serials before 1900-03-01 count a
// 1900-02-29 that never was (60 reads as 1900-02-28); a serial below 1 is a time of day
function SerialToDate(aSerial: Double; a1904: boolean): TDateTime;
// False before the system's first day (1900-01-01, 1904-01-01); a TDateTime below 1 is a time of day
function DateToSerial(aDate: TDateTime; a1904: boolean; out aSerial: Double): boolean;

// a text's width in pixels at size 11, the widest line: ASCII as Excel's AutoFit measures Aptos Narrow (aFont) or Calibri
// (any other font), the rest estimated
function TextPixels(const aText, aFont: string; aBold: boolean): Double;

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
