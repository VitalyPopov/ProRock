unit ProRock.Calcite.Utility;

// Excel's language, format-neutral: limits, A1 addresses and references, serial dates, text widths, colors (internal)

interface

{$SCOPEDENUMS ON}

uses System.SysUtils, System.Math, System.Variants,
  ProRock.Xmlite.Utility;

type
  {$REGION 'ProRock.Xmlite.Utility: its types, so a unit names only this Utility'}
  TNaming = ProRock.Xmlite.Utility.TNaming;
  TCustomAttributeClass = ProRock.Xmlite.Utility.TCustomAttributeClass;
  TNamingAttribute = ProRock.Xmlite.Utility.TNamingAttribute;
  TWriterBase = ProRock.Xmlite.Utility.TWriterBase;
  TReaderBase = ProRock.Xmlite.Utility.TReaderBase;
  TIssueSeverity = ProRock.Xmlite.Utility.TIssueSeverity;
  TIssue = ProRock.Xmlite.Utility.TIssue;
  TIssueEvent = ProRock.Xmlite.Utility.TIssueEvent;
  TIssues = ProRock.Xmlite.Utility.TIssues;
  PIssues = ProRock.Xmlite.Utility.PIssues;
  TXmliteComponentType = ProRock.Xmlite.Utility.TXmliteComponentType;
  TTagType = ProRock.Xmlite.Utility.TTagType;
  TUriedName = ProRock.Xmlite.Utility.TUriedName;
  TXmlns = ProRock.Xmlite.Utility.TXmlns;
  TXmlnsScope = ProRock.Xmlite.Utility.TXmlnsScope;
  // generics have no aliases: empty subclasses; a parent's object does not go into a child-typed variable (E2008)
  THashSet<T> = class(ProRock.Xmlite.Utility.THashSet<T>);
  THashedObjectList<T: class> = class(ProRock.Xmlite.Utility.THashedObjectList<T>);
  TDictObjectList<K; V: class> = class(ProRock.Xmlite.Utility.TDictObjectList<K, V>);
  TDualDictionary<TKey, TValue> = class(ProRock.Xmlite.Utility.TDualDictionary<TKey, TValue>);
  TSummaryDictionary<T: class> = class(ProRock.Xmlite.Utility.TSummaryDictionary<T>);
  {$ENDREGION}

  TReferenceKind = (rkNone, rkCell, rkColumn, rkRow);
  TReferenceChange = (rcFill, rcInsert, rcDelete, rcSheetDelete);
  // what a sheet deleted does to a prefix: nothing, gone with it (#REF!), a 3-D one's end moved inward
  TPrefixChange = (pcSame, pcGone, pcMoved);

  // a reference as a formula writes it (TUtility.ReadReference): a cell, a column or a row, alone or a range's two ends
  TReference = record
    Kind: TReferenceKind;
    Row, Column, Row2, Column2: integer;
    RowFixed, ColumnFixed, RowFixed2, ColumnFixed2, Range: boolean;
  end;

  // a rectangle of cells, from 1: a range's, a merged area's, a table's, a ref's
  TArea = record
    Top, Left, Bottom, Right: integer;
    class function Make(aTop, aLeft, aBottom, aRight: integer): TArea; static; inline;
    // B5, $B$5, A1:C10, 5:7, B:D
    class function TryParse(const aAddress: string; out aArea: TArea): boolean; static;
    function Holds(aRow, aColumn: integer): boolean; inline;
    function Contains(const aInner: TArea): boolean; inline;
    function Overlaps(const aOther: TArea): boolean; inline;
    // as Excel shows it: 5:7 for whole rows (the whole sheet too), B:D for whole columns, else A1:C10
    function Address: string;
    // A1:C10 for any area, whole columns too: what the file's dimension and refs hold
    function CellsAddress: string;
  end;

  // a table's rows (with its header and totals) and columns, its data rows among them
  TTableBody = record
    Left, Right, Top, DataTop, DataBottom, Bottom: integer;
  end;

  // a text's pieces copied into a builder made at the first change: Done gives the text itself when nothing changed
  TTextCopy = record
    Text: string;
    Builder: TStringBuilder; // the caller frees it
    Copied: integer; // Text before it is in Builder
    procedure Start(const aText: string);
    // Text[aStart .. aFinish - 1] written as aWith
    procedure Replace(aStart, aFinish: integer; const aWith: string);
    function Done: string;
  end;

  // a span reaching the sheet's last row or column through a delete, as Excel ends it: a list by address (conditional
  // formats, validation, hyperlinks, protected ranges) keeps reaching it; a table moves in with its cells; a merged area
  // moves in when wholly after the delete, keeps reaching it when the delete cuts it
  TSheetEnd = (sePinned, seMoves, seMerged);

  // how a formula's references change, as Excel changes them. A fill moves the relative parts of every reference. An insert
  // or delete of rows or columns on one sheet moves each reference into it at or past the cut, the absolute parts too (in a
  // defined name the relative parts stay, as Excel keeps them); a range grows or shrinks, one wholly deleted or pushed off
  // the sheet is #REF!, one reaching the last row or column keeps reaching it. 3-D references (Sheet1:Sheet3!A1) and other
  // workbooks' stay, as in Excel. A sheet deleted: what names it is #REF!, a name through it the workbook's ([0]!Total), a
  // 3-D range's end on it moves inward to the next worksheet
  TReferenceMap = record
    Change: TReferenceChange;
    Rows, Columns: integer; // a fill's offset
    Sheet: string; // the sheet with rows or columns inserted or deleted, or the sheet deleted
    Sheets: TArray<string>; // a sheet deleted: the worksheets in order, it among them (chart sheets end no 3-D range)
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
    class function SheetDeleted(const aSheet: string; const aSheets: TArray<string>): TReferenceMap; static;
    // whether the references after a prefix change: aPrefix as written before its ! (Data, 'My Sheet', [1]Data,
    // Data:Three), '' for none
    function Changes(const aPrefix: string): boolean;
    // a sheet deleted: what becomes of a prefix (as Changes takes it), aText the moved one (Data:Mid, 'A b:Last')
    function PrefixChange(const aPrefix: string; out aText: string): TPrefixChange;
    // a reference: False for #REF!, aText '' when it stays as written
    function Map(aReference: TReference; out aText: string): boolean;
    // whether Table[...] (aBrackets with its [ and ]) names a table or column gone: Excel writes #REF! for it
    function TableGone(const aTable, aBrackets: string): boolean;
    // rows or columns added (> 0) or taken (< 0); 0 for a fill or a sheet deleted
    function Delta: integer;
    // the last row or column along ByRows
    function Limit: integer;
    // a delete: the last row or column deleted
    function Last: integer;
    // a span of rows or columns as Excel moves it: one inserted inside grows (aGrowAfter: right after it too, as a format
    // carries on), a delete shrinks it, the whole sheet's stays, one reaching the last row or column ends by aEnd; False
    // when nothing is left
    function MovedSpan(var aLow, aHigh: integer; aGrowAfter: boolean; aEnd: TSheetEnd = TSheetEnd.seMerged): boolean;
    // a row or column number the same way: 0 when deleted or pushed off the sheet
    function MovedIndex(aIndex: integer): integer;
    function MovedArea(var aArea: TArea; aGrowAfter: boolean = False; aEnd: TSheetEnd = TSheetEnd.seMerged): boolean;
    // a list of areas (A1:B5 D7) the same way, those gone dropped: '' when none is left
    function MovedSqref(const aSqref: string; aGrowAfter: boolean = False; aEnd: TSheetEnd = TSheetEnd.seMerged): string;
  private
    function MapFill(const aReference: TReference; out aText: string): boolean;
    function MovedEnd(var aValue: integer; aFixed: boolean): boolean;
    function MovedEnds(const aReference: TReference; var aLow, aHigh: integer; aLowFixed, aHighFixed: boolean): boolean;
    function GrowsWithTable(const aReference: TReference; aLow, aHigh: integer): boolean;
  end;

  TUtility = class abstract(ProRock.Xmlite.Utility.TUtility)
  public const
    cMaxSheetName = 31; // UTF-16 units, as Excel counts
    cMaxRow = 1048576;
    cMaxColumn = 16384;
    cMaxText = 32767;
    cMaxFormula = 8192;
    // the default font's digit (Calibri or Aptos Narrow 11) in pixels: the unit of Excel's column widths
    cDigitPixels = 7;
  public
    class function ColumnName(aColumn: integer): string; static;
    class function CellName(aRow, aColumn: integer): string; static;
    // the letters from aIndex on (up to aFinish) as a column number (0: none, or beyond XFD); aIndex moves past them
    class function ReadColumn(const aText: string; var aIndex: integer; aFinish: integer = MaxInt): integer; static;
    class function ReadRow(const aText: string; var aIndex: integer; aFinish: integer = MaxInt): integer; static;
    // a cell's r (B5) -> its column; 0 when it has none
    class function ColumnOf(const aReference: string): integer; static;
    // A1, $A$1, A, $A, 5, $5 (a column and a row count only as one end of A:C or 5:7)
    class function ReadReference(const aWord: string; out aRow, aColumn: integer; out aRowFixed, aColumnFixed: boolean): TReferenceKind;
      overload; static;
    // the same of aText[aStart .. aFinish - 1]
    class function ReadReference(const aText: string; aStart, aFinish: integer; out aRow, aColumn: integer;
      out aRowFixed, aColumnFixed: boolean): TReferenceKind; overload; static;
    // a reference's relative parts moved; False off the sheet
    class function MoveReference(aKind: TReferenceKind; aRow, aColumn: integer; aRowFixed, aColumnFixed: boolean;
      aRows, aColumns: integer; out aText: string): boolean; static;

    // a sheet's name as a formula writes it before its !: quoted ('My Sheet', 'A1', 'It''s') when Excel quotes it
    class function QuotedSheet(const aName: string): string; static;
    // whether a formula's text may name the sheet: its name as a prefix (before !, : or the closing quote), plain or quoted
    // ('Bob''s'), in any case; a formula that does not read naming it is refused, not kept
    class function MayNameSheet(const aText, aSheet: string): boolean; static;
    // the columns a structured reference's brackets name ([Sales], [[#This Row],[Sales]], [[Q1]:[Q3]], [@Sales]), their '
    // escapes undone; # specifiers left out
    class function TableColumns(const aBrackets: string): TArray<string>; static;

    // Excel's serial numbers: days from 1899-12-30 as TDateTime, but in the 1900 system the serials before 1900-03-01 count a
    // 1900-02-29 that never was (60 reads as 1900-02-28); a serial below 1 is a time of day
    class function SerialToDate(aSerial: Double; a1904: boolean): TDateTime; static;
    // False before the system's first day (1900-01-01, 1904-01-01); a TDateTime below 1 is a time of day
    class function DateToSerial(aDate: TDateTime; a1904: boolean; out aSerial: Double): boolean; static;

    // a text's width in pixels at size 11, the widest line: ASCII as Excel's AutoFit measures Aptos Narrow (aFont) or Calibri
    // (any other font), the rest estimated
    class function TextPixels(const aText, aFont: string; aBold: boolean): Double; static;
    // Excel's ColumnWidth (characters) in pixels on the screen: whole pixels, 5 of them padding
    class function WidthPixels(aCharacters: Double): integer; static;

    // colors as Excel's Color (BGR, TColor's order)
    // a tint or shade (-1 darkest, 1 lightest) as Excel applies it: its integer HLS (240 steps), each product truncated
    class function TintedColor(aColor: integer; aTint: Double): integer; static;
    // an indexed color in Excel's default palette: 0-63, 64 the system's text (black), 65 its window (white); others black
    class function PaletteColor(aIndex: integer): integer; static;

    // an item of an array for a range, from 0: two dimensions, or one (a row)
    class function ArrayItem(const aArray: Variant; aRow, aColumn: integer): Variant; static;
    // empty, null or '': what clears a cell's formula
    class function IsNoFormula(const aValue: Variant): boolean; static;
  end;

implementation

uses System.Character, System.RegularExpressions;

class function TUtility.ColumnName(aColumn: integer): string;
begin
  Result := '';
  while aColumn > 0 do
  begin
    Result := Char(Ord('A') + (aColumn - 1) mod 26) + Result;
    aColumn := (aColumn - 1) div 26;
  end;
end;

class function TUtility.CellName(aRow, aColumn: integer): string;
begin
  Result := ColumnName(aColumn) + IntToStr(aRow);
end;

class function TUtility.ReadColumn(const aText: string; var aIndex: integer; aFinish: integer): integer;
begin
  Result := 0;
  var last: integer := Min(aFinish - 1, aText.Length);
  while aIndex <= last do
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

class function TUtility.ReadRow(const aText: string; var aIndex: integer; aFinish: integer): integer;
begin
  Result := 0;
  var last: integer := Min(aFinish - 1, aText.Length);
  while (aIndex <= last) and CharInSet(aText[aIndex], ['0' .. '9']) do
  begin
    Result := Result * 10 + Ord(aText[aIndex]) - Ord('0');
    if Result > cMaxRow then
      Exit(0);
    Inc(aIndex);
  end;
end;

class function TUtility.ColumnOf(const aReference: string): integer;
begin
  var index: integer := 1;
  Result := ReadColumn(aReference, index);
end;

class function TUtility.ReadReference(const aWord: string; out aRow, aColumn: integer;
  out aRowFixed, aColumnFixed: boolean): TReferenceKind;
begin
  Result := ReadReference(aWord, 1, aWord.Length + 1, aRow, aColumn, aRowFixed, aColumnFixed);
end;

class function TUtility.ReadReference(const aText: string; aStart, aFinish: integer; out aRow, aColumn: integer;
  out aRowFixed, aColumnFixed: boolean): TReferenceKind;
begin
  Result := TReferenceKind.rkNone;
  var index: integer := aStart;
  aColumnFixed := (index < aFinish) and (aText[index] = '$');
  if aColumnFixed then
    Inc(index);
  var start: integer := index;
  aColumn := ReadColumn(aText, index, aFinish);
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
    aRowFixed := (index < aFinish) and (aText[index] = '$');
    if aRowFixed then
      Inc(index);
  end;
  start := index;
  aRow := ReadRow(aText, index, aFinish);
  var digits: boolean := index > start;
  if (index < aFinish) or (digits and (aRow = 0)) then
    Exit;
  if letters and digits then
    Result := TReferenceKind.rkCell
  else if letters and not aRowFixed then
    Result := TReferenceKind.rkColumn
  else if digits and not aColumnFixed then
    Result := TReferenceKind.rkRow;
end;

class function TUtility.MoveReference(aKind: TReferenceKind; aRow, aColumn: integer; aRowFixed, aColumnFixed: boolean;
  aRows, aColumns: integer; out aText: string): boolean;
begin
  if not aRowFixed and (aKind in [TReferenceKind.rkCell, TReferenceKind.rkRow]) then
    Inc(aRow, aRows);
  if not aColumnFixed and (aKind in [TReferenceKind.rkCell, TReferenceKind.rkColumn]) then
    Inc(aColumn, aColumns);
  Result := ((aKind = TReferenceKind.rkColumn) or ((aRow >= 1) and (aRow <= cMaxRow))) and
    ((aKind = TReferenceKind.rkRow) or ((aColumn >= 1) and (aColumn <= cMaxColumn)));
  aText := '';
  if aKind in [TReferenceKind.rkCell, TReferenceKind.rkColumn] then
  begin
    if aColumnFixed then
      aText := '$';
    aText := aText + ColumnName(aColumn);
  end;
  if aKind in [TReferenceKind.rkCell, TReferenceKind.rkRow] then
  begin
    if aRowFixed then
      aText := aText + '$';
    aText := aText + IntToStr(aRow);
  end;
end;

class function TUtility.TableColumns(const aBrackets: string): TArray<string>;
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

class function TUtility.MayNameSheet(const aText, aSheet: string): boolean;
begin
  Result := (aSheet <> '') and (TRegEx.IsMatch(aText, '(?<![\w.])' + TRegEx.Escape(aSheet) + '(?=[!:''])', [roIgnoreCase]) or
    TRegEx.IsMatch(aText, '(?<![\w.])' + TRegEx.Escape(aSheet.Replace('''', '''''')) + '(?=[!:''])', [roIgnoreCase]));
end;

class function TUtility.QuotedSheet(const aName: string): string;
begin
  var plain: boolean := (aName <> '') and (aName[1].IsLetter or (aName[1] = '_'));
  for var letter: Char in aName do
    plain := plain and (letter.IsLetterOrDigit or CharInSet(letter, ['_', '.']));
  var row, column: integer;
  var rowFixed, columnFixed: boolean;
  // like a cell (A1, XFD5) or R1C1's R, C2, R1C1
  if plain and ((ReadReference(aName, row, column, rowFixed, columnFixed) = TReferenceKind.rkCell) or
    TRegEx.IsMatch(aName, '^([Rr]\d*)?([Cc]\d*)?$')) then
    plain := False;
  if plain then
    Result := aName
  else
    Result := '''' + aName.Replace('''', '''''') + '''';
end;

class function TReferenceMap.Fill(aRows, aColumns: integer): TReferenceMap;
begin
  Result := Default(TReferenceMap);
  Result.Change := TReferenceChange.rcFill;
  Result.Rows := aRows;
  Result.Columns := aColumns;
end;

class function TReferenceMap.Inserted(const aSheet: string; aByRows: boolean; aFirst, aCount: integer): TReferenceMap;
begin
  Result := Default(TReferenceMap);
  Result.Change := TReferenceChange.rcInsert;
  Result.Sheet := aSheet;
  Result.ByRows := aByRows;
  Result.First := aFirst;
  Result.Count := aCount;
end;

class function TReferenceMap.Deleted(const aSheet: string; aByRows: boolean; aFirst, aCount: integer): TReferenceMap;
begin
  Result := Inserted(aSheet, aByRows, aFirst, aCount);
  Result.Change := TReferenceChange.rcDelete;
end;

class function TReferenceMap.SheetDeleted(const aSheet: string; const aSheets: TArray<string>): TReferenceMap;
begin
  Result := Default(TReferenceMap);
  Result.Change := TReferenceChange.rcSheetDelete;
  Result.Sheet := aSheet;
  Result.Sheets := aSheets;
end;

function TReferenceMap.Delta: integer;
begin
  case Change of
    TReferenceChange.rcInsert:
      Result := Count;
    TReferenceChange.rcDelete:
      Result := -Count;
  else
    Result := 0;
  end;
end;

function TReferenceMap.Limit: integer;
begin
  if ByRows then
    Result := TUtility.cMaxRow
  else
    Result := TUtility.cMaxColumn;
end;

function TReferenceMap.Last: integer;
begin
  Result := First + Count - 1;
end;

function TReferenceMap.MovedSpan(var aLow, aHigh: integer; aGrowAfter: boolean; aEnd: TSheetEnd): boolean;
begin
  var count: integer := Delta;
  var bound: integer := Limit; // not `limit`: Delphi 10.3 reads the call as the variable
  if count > 0 then
  begin
    if (aLow = 1) and (aHigh = bound) then
      Exit(True);
    if First <= aLow then
    begin
      Inc(aLow, count);
      Inc(aHigh, count);
    end
    else if (First <= aHigh) or aGrowAfter and (First = aHigh + 1) then
      Inc(aHigh, count);
    aHigh := Min(aHigh, bound);
    Exit(aLow <= bound);
  end;
  var last: integer := First - count - 1;
  var toEnd: boolean := aHigh = bound;
  if last < aLow then
  begin
    Inc(aLow, count);
    if not toEnd or (aEnd <> TSheetEnd.sePinned) then
      Inc(aHigh, count);
  end
  else if First <= aHigh then
  begin
    var left: integer := aHigh - aLow + 1 - (Min(last, aHigh) - Max(First, aLow) + 1);
    if left = 0 then
      Exit(False);
    aLow := Min(aLow, First);
    aHigh := aLow + left - 1;
    if toEnd and (aEnd <> TSheetEnd.seMoves) then
      aHigh := bound;
  end;
  Result := True;
end;

function TReferenceMap.MovedIndex(aIndex: integer): integer;
begin
  Result := aIndex;
  if aIndex < First then
    Exit;
  var count: integer := Delta;
  if count < 0 then
  begin
    if aIndex < First - count then
      Exit(0);
  end
  else if aIndex + count > Limit then
    Exit(0);
  Result := aIndex + count;
end;

function TReferenceMap.MovedArea(var aArea: TArea; aGrowAfter: boolean; aEnd: TSheetEnd): boolean;
begin
  if ByRows then
    Result := MovedSpan(aArea.Top, aArea.Bottom, aGrowAfter, aEnd)
  else
    Result := MovedSpan(aArea.Left, aArea.Right, aGrowAfter, aEnd);
end;

function TReferenceMap.MovedSqref(const aSqref: string; aGrowAfter: boolean; aEnd: TSheetEnd): string;
begin
  Result := '';
  for var item: string in aSqref.Split([' '], TStringSplitOptions.ExcludeEmpty) do
  begin
    var area: TArea;
    var text: string := item;
    if TArea.TryParse(item, area) then
      if MovedArea(area, aGrowAfter, aEnd) then
        text := area.CellsAddress
      else
        text := '';
    if text <> '' then
      if Result = '' then
        Result := text
      else
        Result := Result + ' ' + text;
  end;
end;

// a prefix's sheet names, its quotes undone
function UnquotedPrefix(const aPrefix: string): string;
begin
  Result := aPrefix;
  if (Result.Length >= 2) and (Result[1] = '''') and (Result[Result.Length] = '''') then
    Result := Copy(Result, 2, Result.Length - 2).Replace('''''', '''');
end;

function TReferenceMap.Changes(const aPrefix: string): boolean;
begin
  if Change = TReferenceChange.rcFill then
    Exit((Rows <> 0) or (Columns <> 0));
  if Change = TReferenceChange.rcSheetDelete then
    Exit(False); // the prefix changes: PrefixChange
  if aPrefix = '' then
    Exit(OnSheet);
  var name: string := UnquotedPrefix(aPrefix);
  // another workbook's or 3-D: a sheet's name has neither [ nor :
  Result := not name.StartsWith('[') and not name.Contains(':') and AnsiSameText(name, Sheet);
end;

function TReferenceMap.PrefixChange(const aPrefix: string; out aText: string): TPrefixChange;

  function IndexOf(const aName: string): integer;
  begin
    for var i := 0 to High(Sheets) do
      if AnsiSameText(Sheets[i], aName) then
        Exit(i);
    Result := -1;
  end;

begin
  aText := '';
  Result := TPrefixChange.pcSame;
  if (Change <> TReferenceChange.rcSheetDelete) or (aPrefix = '') then
    Exit;
  var name: string := UnquotedPrefix(aPrefix);
  if name.StartsWith('[') then // another workbook's
    Exit;
  var colon: integer := name.IndexOf(':');
  if colon < 0 then
  begin
    if AnsiSameText(name, Sheet) then
      Result := TPrefixChange.pcGone;
    Exit;
  end;
  var first: integer := IndexOf(name.Substring(0, colon));
  var last: integer := IndexOf(name.Substring(colon + 1));
  var gone: integer := IndexOf(Sheet);
  if (first < 0) or (last < 0) or (gone < 0) or ((first <> gone) and (last <> gone)) then
    Exit;
  if first = last then
    Exit(TPrefixChange.pcGone);
  var step: integer := Sign(last - first);
  if first = gone then
    Inc(first, step)
  else
    Dec(last, step);
  Result := TPrefixChange.pcMoved;
  if first = last then
    aText := TUtility.QuotedSheet(Sheets[first])
  else if (TUtility.QuotedSheet(Sheets[first]) = Sheets[first]) and (TUtility.QuotedSheet(Sheets[last]) = Sheets[last]) then
    aText := Sheets[first] + ':' + Sheets[last]
  else
    aText := '''' + (Sheets[first] + ':' + Sheets[last]).Replace('''', '''''') + '''';
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
        columns := TUtility.TableColumns(aBrackets);
      for var column: string in columns do
        if AnsiSameText(column, gone.Substring(bracket + 1, gone.Length - bracket - 2)) then
          Exit(True);
    end;
  end;
  Result := False;
end;

// one end of a reference as written, with its kind's parts
function EndText(aKind: TReferenceKind; aRow, aColumn: integer; aRowFixed, aColumnFixed: boolean): string;
begin
  TUtility.MoveReference(aKind, aRow, aColumn, aRowFixed, aColumnFixed, 0, 0, Result);
end;

// a reference as Excel writes it: a range over every column as rows (5:7), over every row as columns (B:D)
function ReferenceText(const aReference: TReference): string;
begin
  if not aReference.Range then
    Result := EndText(aReference.Kind, aReference.Row, aReference.Column, aReference.RowFixed, aReference.ColumnFixed)
  else if (aReference.Kind = TReferenceKind.rkCell) and (Min(aReference.Column, aReference.Column2) = 1) and
    (Max(aReference.Column, aReference.Column2) = TUtility.cMaxColumn) then
    Result := EndText(TReferenceKind.rkRow, aReference.Row, 0, aReference.RowFixed, False) + ':' +
      EndText(TReferenceKind.rkRow, aReference.Row2, 0, aReference.RowFixed2, False)
  else if (aReference.Kind = TReferenceKind.rkCell) and (Min(aReference.Row, aReference.Row2) = 1) and
    (Max(aReference.Row, aReference.Row2) = TUtility.cMaxRow) then
    Result := EndText(TReferenceKind.rkColumn, 0, aReference.Column, False, aReference.ColumnFixed) + ':' +
      EndText(TReferenceKind.rkColumn, 0, aReference.Column2, False, aReference.ColumnFixed2)
  else
    Result := EndText(aReference.Kind, aReference.Row, aReference.Column, aReference.RowFixed, aReference.ColumnFixed) +
      ':' + EndText(aReference.Kind, aReference.Row2, aReference.Column2, aReference.RowFixed2, aReference.ColumnFixed2);
end;

function TReferenceMap.Map(aReference: TReference; out aText: string): boolean;
begin
  aText := '';
  if Change = TReferenceChange.rcFill then
    Exit(MapFill(aReference, aText));
  Result := True;
  if (ByRows and (aReference.Kind = TReferenceKind.rkColumn)) or (not ByRows and (aReference.Kind = TReferenceKind.rkRow)) then
    Exit;
  if not aReference.Range then
  begin
    aReference.Row2 := aReference.Row;
    aReference.Column2 := aReference.Column;
    aReference.RowFixed2 := aReference.RowFixed;
    aReference.ColumnFixed2 := aReference.ColumnFixed;
  end;
  // a range written backwards (A5:A1) as low and high
  var swapped, lowFixed, highFixed: boolean;
  var low, high: integer;
  if ByRows then
  begin
    swapped := aReference.Row > aReference.Row2;
    low := Min(aReference.Row, aReference.Row2);
    high := Max(aReference.Row, aReference.Row2);
    lowFixed := (aReference.RowFixed and not swapped) or (aReference.RowFixed2 and swapped);
    highFixed := (aReference.RowFixed2 and not swapped) or (aReference.RowFixed and swapped);
  end
  else
  begin
    swapped := aReference.Column > aReference.Column2;
    low := Min(aReference.Column, aReference.Column2);
    high := Max(aReference.Column, aReference.Column2);
    lowFixed := (aReference.ColumnFixed and not swapped) or (aReference.ColumnFixed2 and swapped);
    highFixed := (aReference.ColumnFixed2 and not swapped) or (aReference.ColumnFixed and swapped);
  end;
  var oldLow: integer := low;
  var oldHigh: integer := high;
  if aReference.Range then
    Result := MovedEnds(aReference, low, high, lowFixed, highFixed)
  else
    Result := MovedEnd(low, lowFixed);
  if not Result or ((low = oldLow) and (high = oldHigh)) then
    Exit;
  if not aReference.Range then
    high := low;
  if swapped then
  begin
    var value: integer := low;
    low := high;
    high := value;
  end;
  if ByRows then
  begin
    aReference.Row := low;
    aReference.Row2 := high;
  end
  else
  begin
    aReference.Column := low;
    aReference.Column2 := high;
  end;
  aText := ReferenceText(aReference);
end;

function TReferenceMap.MapFill(const aReference: TReference; out aText: string): boolean;
begin
  var moved2: string;
  Result := TUtility.MoveReference(aReference.Kind, aReference.Row, aReference.Column, aReference.RowFixed,
    aReference.ColumnFixed, Rows, Columns, aText) and (not aReference.Range or TUtility.MoveReference(aReference.Kind,
    aReference.Row2, aReference.Column2, aReference.RowFixed2, aReference.ColumnFixed2, Rows, Columns, moved2));
  if aReference.Range then
    aText := aText + ':' + moved2;
end;

// one end alone: False when it is deleted or pushed off the sheet
function TReferenceMap.MovedEnd(var aValue: integer; aFixed: boolean): boolean;
begin
  Result := True;
  if InName and not aFixed then
    Exit;
  if Change = TReferenceChange.rcInsert then
  begin
    if aValue >= First then
      Inc(aValue, Count);
    Result := aValue <= Limit;
  end
  else if aValue >= First + Count then
    Dec(aValue, Count)
  else if aValue >= First then
    Result := False;
end;

// a range's ends, aLow <= aHigh: False when it is wholly deleted or pushed off the sheet
function TReferenceMap.MovedEnds(const aReference: TReference; var aLow, aHigh: integer; aLowFixed, aHighFixed: boolean): boolean;
begin
  if InName and (not aLowFixed or not aHighFixed) then
    Exit(MovedEnd(aLow, aLowFixed) and MovedEnd(aHigh, aHighFixed));
  var bound: integer := Limit; // not `limit`: Delphi 10.3 reads the call as the variable
  if Change = TReferenceChange.rcInsert then
  begin
    if (aLow = 1) and (aHigh = bound) then // every row or column stays so
      Exit(True);
    if GrowsWithTable(aReference, aLow, aHigh) then
    begin
      aHigh := Min(aHigh + Count, bound);
      Exit(True);
    end;
    if aLow >= First then
      Inc(aLow, Count);
    if aHigh >= First then
      aHigh := Min(aHigh + Count, bound);
    Exit(aLow <= bound);
  end;
  if (aLow >= First) and (aHigh <= Last) then
    Exit(False);
  if aLow > Last then
    Dec(aLow, Count)
  else if aLow >= First then
    aLow := First;
  if aHigh = bound then
    // reaching the last row or column, it keeps reaching it
  else if aHigh > Last then
    Dec(aHigh, Count)
  else if aHigh >= First then
    aHigh := First - 1;
  Result := True;
end;

// a cell range in one of Bodies' columns over all its data rows, rows inserted at its first data row or its totals row
function TReferenceMap.GrowsWithTable(const aReference: TReference; aLow, aHigh: integer): boolean;
begin
  Result := False;
  if not ByRows or (aReference.Kind <> TReferenceKind.rkCell) then
    Exit;
  for var body: TTableBody in Bodies do
    if (Min(aReference.Column, aReference.Column2) >= body.Left) and (Max(aReference.Column, aReference.Column2) <= body.Right) and
      (aLow >= body.Top) and (aLow <= body.DataTop) and (aHigh >= body.DataBottom) and (aHigh <= body.Bottom) and
      ((First = body.DataTop) or (First = body.DataBottom + 1) and (First <= body.Bottom)) then
      Exit(True);
end;

class function TUtility.SerialToDate(aSerial: Double; a1904: boolean): TDateTime;
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

class function TUtility.DateToSerial(aDate: TDateTime; a1904: boolean; out aSerial: Double): boolean;
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

class function TUtility.WidthPixels(aCharacters: Double): integer;
begin
  if aCharacters <= 0 then
    Exit(0);
  Result := Trunc(aCharacters * cDigitPixels + 0.5) + 5;
end;

class function TUtility.TextPixels(const aText, aFont: string; aBold: boolean): Double;
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
    var width: Double := 7.5; // other letters
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
    end;
    if aBold then
      width := width * 1.04;
    line := line + width;
  end;
  Result := Max(Result, line);
end;

class function TUtility.TintedColor(aColor: integer; aTint: Double): integer;
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

class function TUtility.PaletteColor(aIndex: integer): integer;
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

class function TUtility.ArrayItem(const aArray: Variant; aRow, aColumn: integer): Variant;
begin
  if VarArrayDimCount(aArray) = 2 then
    Result := aArray[VarArrayLowBound(aArray, 1) + aRow, VarArrayLowBound(aArray, 2) + aColumn]
  else
    Result := aArray[VarArrayLowBound(aArray, 1) + aColumn];
end;

class function TUtility.IsNoFormula(const aValue: Variant): boolean;
begin
  Result := VarIsEmpty(aValue) or VarIsNull(aValue) or (VarIsStr(aValue) and (string(aValue) = ''));
end;

procedure TTextCopy.Start(const aText: string);
begin
  Text := aText;
  Builder := nil;
  Copied := 1;
end;

procedure TTextCopy.Replace(aStart, aFinish: integer; const aWith: string);
begin
  if Builder = nil then
    Builder := TStringBuilder.Create(Text.Length + 16);
  Builder.Append(Text, Copied - 1, aStart - Copied).Append(aWith);
  Copied := aFinish;
end;

function TTextCopy.Done: string;
begin
  if Builder = nil then
    Exit(Text);
  Builder.Append(Text, Copied - 1, Text.Length + 1 - Copied);
  Result := Builder.ToString;
end;

{ TArea }

class function TArea.Make(aTop, aLeft, aBottom, aRight: integer): TArea;
begin
  Result.Top := aTop;
  Result.Left := aLeft;
  Result.Bottom := aBottom;
  Result.Right := aRight;
end;

class function TArea.TryParse(const aAddress: string; out aArea: TArea): boolean;

  // one end: a cell, a row or a column (0 for the part missing)
  function ReadEnd(const aText: string; out aRow, aColumn: integer): boolean;
  begin
    var index: integer := 1;
    if (index <= aText.Length) and (aText[index] = '$') then
      Inc(index);
    var start: integer := index;
    aColumn := TUtility.ReadColumn(aText, index);
    if (aColumn = 0) and (index > start) then
      Exit(False); // beyond XFD
    if (index <= aText.Length) and (aText[index] = '$') then
      Inc(index);
    start := index;
    aRow := TUtility.ReadRow(aText, index);
    if (aRow = 0) and (index > start) then
      Exit(False); // 0 or beyond the last row
    Result := (index > aText.Length) and ((aRow > 0) or (aColumn > 0));
  end;

begin
  Result := False;
  aArea := Default(TArea); // a failed parse gives an empty area, never what the variable held
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
    row2 := TUtility.cMaxRow;
  end;
  if column1 = 0 then
  begin // whole rows
    column1 := 1;
    column2 := TUtility.cMaxColumn;
  end;
  aArea := Make(Min(row1, row2), Min(column1, column2), Max(row1, row2), Max(column1, column2));
  Result := True;
end;

function TArea.Holds(aRow, aColumn: integer): boolean;
begin
  Result := (aRow >= Top) and (aRow <= Bottom) and (aColumn >= Left) and (aColumn <= Right);
end;

function TArea.Contains(const aInner: TArea): boolean;
begin
  Result := (aInner.Top >= Top) and (aInner.Bottom <= Bottom) and (aInner.Left >= Left) and (aInner.Right <= Right);
end;

function TArea.Overlaps(const aOther: TArea): boolean;
begin
  Result := (Top <= aOther.Bottom) and (aOther.Top <= Bottom) and (Left <= aOther.Right) and (aOther.Left <= Right);
end;

function TArea.Address: string;
begin
  if (Left = 1) and (Right = TUtility.cMaxColumn) then
    Result := IntToStr(Top) + ':' + IntToStr(Bottom)
  else if (Top = 1) and (Bottom = TUtility.cMaxRow) then
    Result := TUtility.ColumnName(Left) + ':' + TUtility.ColumnName(Right)
  else
    Result := CellsAddress;
end;

function TArea.CellsAddress: string;
begin
  Result := TUtility.CellName(Top, Left);
  if (Bottom <> Top) or (Right <> Left) then
    Result := Result + ':' + TUtility.CellName(Bottom, Right);
end;

end.
