unit ProRock.Calcite.XlsxSheet;

// the xlsx backend of a worksheet: its part's cells, rows and columns (internal)

interface

uses System.SysUtils, System.Generics.Collections, ProRock.Office.Ooxml, ProRock.Xmlite.Schema.Ooxml.Sml,
  ProRock.Calcite.Utility, ProRock.Calcite.Aspects, ProRock.Calcite.Xlsx;

type
  TXlsxSheet = class
  private
    fBook: TXlsxBook;
    fPart: string;
    fPrepared: boolean;
    // the part's objects as Objects last gave them, valid while the package and its Version are the same (Exchange swaps
    // packages between workbooks)
    fObjects: TWorksheetE;
    fObjectsPackage: TPackageOoxml;
    fObjectsVersion: cardinal;
    fObjectsEdited: boolean;
  public
    constructor Create(aBook: TXlsxBook; const aPart: string);

    // the part's objects, a missing r filled on the first call
    function Objects(aEdit: boolean): TWorksheetE;
    // binary search: aSheet's row aRow, or where it goes
    function FindRow(aSheet: TWorksheetE; aRow: integer; out aIndex: integer): boolean;
    function FindCell(aRow, aColumn: integer): TCellCT;
    function EffectiveStyle(aRow, aColumn: integer): cardinal;
    function CellForStyle(aRow, aColumn: integer): TCellCT;
    // the rows' and columns' entries as Excel reads and writes them
    function AxisDefault(aByRows: boolean): TAxisFormat;
    function AxisOf(aByRows: boolean; aIndex: integer): TAxisFormat;
    function AxisEntries(aByRows: boolean): TArray<TPair<integer, TAxisFormat>>;
    procedure ApplyAxis(aByRows: boolean; aFirst, aLast: integer; const aChange: TAxisChange);
    // each cell of the area given aNewStyle of its style; a whole column's or row's own style too (Excel's: the cells it
    // will have take it). aExisting: only the cells there already
    procedure SetStyles(const aArea: TArea; const aNewStyle: TFunc<cardinal, cardinal>; aExisting: boolean);
    function ColumnEntry(aColumn: integer): TColCT;
    function ColumnStyle(aColumn: integer): cardinal;
    function SortedColumns: TColCTList;
    function ColumnEntries(aLeft, aRight: integer): TArray<TColCT>;
    function RowEntries(aTop, aBottom: integer): TArray<TRowCT>;
    // from the first cell to the last one; A1 when there are none
    function UsedRange: TArea;

    property Part: string read fPart;
  end;

// binary search: the cells of a row by column
function FindInRow(aRow: TRowCT; aColumn: integer; out aIndex: integer): boolean;
// the <col> entry across aAt split there: ...aAt-1 and aAt...
procedure SplitColumns(aColumns: TColCTList; aAt: cardinal);

implementation

uses System.Math, System.Generics.Defaults;

const
  // in points: a sheet's rows without a height of their own and no default in the file
  cDefaultRowHeight = 15;

function WidthToFile(aCharacters: Double): Double;
begin
  Result := Trunc(TUtility.WidthPixels(aCharacters) / TUtility.cDigitPixels * 256) / 256;
end;

function FileToWidth(aWidth: Double): Double;
begin
  var pixels: integer := Trunc(aWidth * TUtility.cDigitPixels + 0.5) - 5;
  if pixels <= 0 then
    Exit(0);
  Result := Trunc(pixels / TUtility.cDigitPixels * 100 + 0.5) / 100;
end;

function RowAxis(aRow: TRowCT; const aDefault: TAxisFormat): TAxisFormat;
begin
  Result.Hidden := aRow.Hidden;
  if aRow.Present[@aRow.Ht] then
    Result.Size := aRow.Ht
  else
    Result.Size := aDefault.Size;
end;

// a <col> without a width: Excel's 0
function ColumnAxis(aColumn: TColCT): TAxisFormat;
begin
  Result.Hidden := aColumn.Hidden;
  Result.Size := FileToWidth(aColumn.Width);
end;

function FindInRow(aRow: TRowCT; aColumn: integer; out aIndex: integer): boolean;
begin
  var cells: TCellCTList := aRow.C;
  var low: integer := 0;
  var high: integer := cells.Count - 1;
  while low <= high do
  begin
    var middle: integer := (low + high) shr 1;
    var column: integer := TUtility.ColumnOf(cells[middle].R);
    if column = aColumn then
    begin
      aIndex := middle;
      Exit(True);
    end;
    if column < aColumn then
      low := middle + 1
    else
      high := middle - 1;
  end;
  aIndex := low;
  Result := False;
end;

procedure SplitColumns(aColumns: TColCTList; aAt: cardinal);
begin
  for var i := 0 to aColumns.Count - 1 do
    if (aColumns[i].Min < aAt) and (aColumns[i].Max >= aAt) then
    begin
      var copy: TColCT := aColumns[i].Clone<TColCT>;
      copy.Min := aAt;
      aColumns[i].Max := aAt - 1;
      aColumns.Insert(i + 1, copy);
      Exit;
    end;
end;

{ TXlsxSheet }

constructor TXlsxSheet.Create(aBook: TXlsxBook; const aPart: string);
begin
  inherited Create;
  fBook := aBook;
  fPart := aPart;
end;

function TXlsxSheet.Objects(aEdit: boolean): TWorksheetE;
begin
  var package: TPackageOoxml := fBook.Package;
  if (fObjects <> nil) and (fObjectsPackage = package) and (fObjectsVersion = package.Version) and
    (fObjectsEdited or not aEdit) then
    Exit(fObjects); // asked for several times a cell: no lookup in the package
  if aEdit then
    Result := package.EditPart<TWorksheetE>(fPart)
  else
    Result := package.Part<TWorksheetE>(fPart);
  fObjects := Result;
  fObjectsPackage := package;
  fObjectsVersion := package.Version;
  fObjectsEdited := aEdit;
  if fPrepared then
    Exit;
  fPrepared := True;
  // r is optional (other writers leave it out): the next row, the next column - the part stays unchanged
  var rowNumber: cardinal := 0;
  for var row: TRowCT in Result.SheetData.Row do
  begin
    if row.R = 0 then
      row.R := rowNumber + 1;
    rowNumber := row.R;
    var column: integer := 0;
    for var cell: TCellCT in row.C do
    begin
      var cellColumn: integer := TUtility.ColumnOf(cell.R);
      if cellColumn = 0 then
      begin
        cellColumn := column + 1;
        cell.R := TUtility.CellName(rowNumber, cellColumn);
      end;
      column := cellColumn;
    end;
  end;
end;

function TXlsxSheet.FindRow(aSheet: TWorksheetE; aRow: integer; out aIndex: integer): boolean;
begin
  var rows: TRowCTList := aSheet.SheetData.Row;
  var low: integer := 0;
  var high: integer := rows.Count - 1;
  while low <= high do
  begin
    var middle: integer := (low + high) shr 1;
    var number: cardinal := rows[middle].R;
    if number = cardinal(aRow) then
    begin
      aIndex := middle;
      Exit(True);
    end;
    if number < cardinal(aRow) then
      low := middle + 1
    else
      high := middle - 1;
  end;
  aIndex := low;
  Result := False;
end;

function TXlsxSheet.FindCell(aRow, aColumn: integer): TCellCT;
begin
  Result := nil;
  var sheet: TWorksheetE := Objects(False);
  var rowIndex, cellIndex: integer;
  if FindRow(sheet, aRow, rowIndex) and FindInRow(sheet.SheetData.Row[rowIndex], aColumn, cellIndex) then
    Result := sheet.SheetData.Row[rowIndex].C[cellIndex];
end;

// the style a new cell takes, as in Excel: a formatted row's, else its column's
function TXlsxSheet.EffectiveStyle(aRow, aColumn: integer): cardinal;
begin
  var sheet: TWorksheetE := Objects(False);
  var rowIndex: integer;
  if FindRow(sheet, aRow, rowIndex) then
  begin
    var row: TRowCT := sheet.SheetData.Row[rowIndex];
    var cellIndex: integer;
    if FindInRow(row, aColumn, cellIndex) then
      Exit(row.C[cellIndex].S);
    if row.CustomFormat then
      Exit(row.S);
  end;
  for var columns: TColsCT in sheet.Cols do
    for var column: TColCT in columns.Col do
      if (cardinal(aColumn) >= column.Min) and (cardinal(aColumn) <= column.Max) then
        Exit(column.Style);
  Result := 0;
end;

// the cell as it is, created where Excel expects it (rows in order, cells by column) with the style it shows
function TXlsxSheet.CellForStyle(aRow, aColumn: integer): TCellCT;
begin
  var style: cardinal := EffectiveStyle(aRow, aColumn);
  var sheet: TWorksheetE := Objects(True);
  var rows: TRowCTList := sheet.SheetData.Row;
  var rowIndex: integer;
  if not FindRow(sheet, aRow, rowIndex) then
  begin
    var newRow: TRowCT := TRowCT.Create;
    newRow.R := aRow;
    rows.Insert(rowIndex, newRow);
  end;
  var row: TRowCT := rows[rowIndex];
  var cellIndex: integer;
  if FindInRow(row, aColumn, cellIndex) then
    Result := row.C[cellIndex]
  else
  begin
    Result := TCellCT.Create;
    Result.R := TUtility.CellName(aRow, aColumn);
    Result.S := style;
    row.C.Insert(cellIndex, Result);
    // spans (optional, a hint for readers) and the sheet's dimension cover the new cell
    if row.Spans <> '' then
    begin
      var first: integer := MaxInt;
      var last: integer := 0;
      for var span: string in string(row.Spans).Split([' ']) do
      begin
        var ends: TArray<string> := span.Split([':']);
        if Length(ends) = 2 then
        begin
          first := Min(first, StrToIntDef(ends[0], first));
          last := Max(last, StrToIntDef(ends[1], last));
        end;
      end;
      if (aColumn < first) or (aColumn > last) then
        row.Spans := Format('%d:%d', [Min(first, aColumn), Max(last, aColumn)]);
    end;
    if sheet.IsPresent('Dimension') then
    begin
      var dimension: TArea;
      if TArea.TryParse(sheet.Dimension.Ref, dimension) and not dimension.Holds(aRow, aColumn) then
        sheet.Dimension.Ref := TArea.Make(Min(dimension.Top, aRow), Min(dimension.Left, aColumn), Max(dimension.Bottom, aRow),
          Max(dimension.Right, aColumn)).CellsAddress;
    end;
  end;
end;

{$REGION 'the axis table: rows and columns as Excel reads and writes them'}

// rows or columns without an entry of their own: Excel's 15 points or 8.43 characters unless the sheet says; the rows
// hidden when the sheet hides those it does not list
function TXlsxSheet.AxisDefault(aByRows: boolean): TAxisFormat;
begin
  Result := Default(TAxisFormat);
  var sheet: TWorksheetE := Objects(False);
  var format: TSheetFormatPrCT := nil;
  if sheet.IsPresent('SheetFormatPr') then
    format := sheet.SheetFormatPr;
  if aByRows then
  begin
    Result.Size := cDefaultRowHeight;
    if format <> nil then
    begin
      Result.Hidden := format.ZeroHeight;
      if format.Present[@format.DefaultRowHeight] then
        Result.Size := format.DefaultRowHeight;
    end;
  end
  else if (format <> nil) and format.Present[@format.DefaultColWidth] then
    Result.Size := FileToWidth(format.DefaultColWidth)
  else
  begin
    var base: integer := 8;
    if (format <> nil) and format.Present[@format.BaseColWidth] then
      base := format.BaseColWidth;
    // base characters and the padding, in whole multiples of 8 pixels
    var pixels: integer := (base * TUtility.cDigitPixels + 5 + 7) div 8 * 8;
    Result.Size := Trunc((pixels - 5) / TUtility.cDigitPixels * 100 + 0.5) / 100;
  end;
end;

function TXlsxSheet.AxisOf(aByRows: boolean; aIndex: integer): TAxisFormat;
begin
  if aByRows then
  begin
    var sheet: TWorksheetE := Objects(False);
    var rowIndex: integer;
    if not FindRow(sheet, aIndex, rowIndex) then
      Result := AxisDefault(True)
    else
      Result := RowAxis(sheet.SheetData.Row[rowIndex], AxisDefault(True));
  end
  else
  begin
    var column: TColCT := ColumnEntry(aIndex);
    if column = nil then
      Result := AxisDefault(False)
    else
      Result := ColumnAxis(column);
  end;
end;

// the rows or columns with an entry of their own, in order
function TXlsxSheet.AxisEntries(aByRows: boolean): TArray<TPair<integer, TAxisFormat>>;
var
  default: TAxisFormat;
begin
  var sheet: TWorksheetE := Objects(False);
  var entries: TList<TPair<integer, TAxisFormat>> := TList<TPair<integer, TAxisFormat>>.Create;
  try
    if aByRows then
    begin
      default := AxisDefault(True);
      for var row: TRowCT in sheet.SheetData.Row do
        entries.Add(TPair<integer, TAxisFormat>.Create(row.R, RowAxis(row, default)));
    end
    else
    begin
      for var columns: TColsCT in sheet.Cols do // not SortedColumns: it would add an empty <cols>, which Excel refuses
        for var column: TColCT in columns.Col do
          for var index := column.Min to Min(column.Max, TUtility.cMaxColumn) do
            entries.Add(TPair<integer, TAxisFormat>.Create(index, ColumnAxis(column)));
      entries.Sort(TComparer<TPair<integer, TAxisFormat>>.Construct(
        function(const aLeft, aRight: TPair<integer, TAxisFormat>): integer
        begin
          Result := CompareValue(aLeft.Key, aRight.Key);
        end));
    end;
    Result := entries.ToArray;
  finally
    entries.Free;
  end;
end;

// aChange written to the rows or columns aFirst..aLast, their entries made where missing (a row's own height dropped
// only where it has one)
procedure TXlsxSheet.ApplyAxis(aByRows: boolean; aFirst, aLast: integer; const aChange: TAxisChange);
begin
  var aspects: TAxisAspects := aChange.Aspects;
  if aByRows and (aspects * [axSize, axHidden] = []) then
  begin
    var sheet: TWorksheetE := Objects(False);
    var rows: TRowCTList := sheet.SheetData.Row;
    var rowIndex: integer;
    FindRow(sheet, aFirst, rowIndex);
    while (rowIndex < rows.Count) and (rows[rowIndex].R <= cardinal(aLast)) do
    begin
      var row: TRowCT := rows[rowIndex];
      if row.Present[@row.Ht] or row.CustomHeight then
      begin
        Objects(True);
        row.Clear(@row.Ht);
        row.Clear(@row.CustomHeight);
      end;
      Inc(rowIndex);
    end;
  end
  else if aByRows then
    for var row: TRowCT in RowEntries(aFirst, aLast) do
    begin
      if axSize in aspects then
      begin
        row.Ht := aChange.Value.Size;
        row.SetPresent(@row.Ht);
        row.CustomHeight := True;
      end
      else if axDefaultSize in aspects then
      begin
        row.Clear(@row.Ht);
        row.Clear(@row.CustomHeight);
      end;
      if axHidden in aspects then
        if aChange.Value.Hidden then
          row.Hidden := True
        else
          row.Clear(@row.Hidden);
    end
  else
  begin
    var width: Double := 0;
    if axSize in aspects then
      width := WidthToFile(aChange.Value.Size)
    else if axDefaultSize in aspects then
      width := WidthToFile(AxisDefault(False).Size);
    for var column: TColCT in ColumnEntries(aFirst, aLast) do
    begin
      if aspects * [axSize, axDefaultSize] <> [] then
      begin
        column.Width := width;
        column.SetPresent(@column.Width);
        if axSize in aspects then
          column.CustomWidth := True
        else
          column.Clear(@column.CustomWidth);
        if axFitted in aspects then
          column.BestFit := True
        else
          column.Clear(@column.BestFit);
      end;
      if axHidden in aspects then
        if aChange.Value.Hidden then
          column.Hidden := True
        else
          column.Clear(@column.Hidden);
    end;
  end;
end;

{$ENDREGION}

procedure TXlsxSheet.SetStyles(const aArea: TArea; const aNewStyle: TFunc<cardinal, cardinal>; aExisting: boolean);
begin
  var sheet: TWorksheetE := Objects(True);
  var wholeColumns: boolean := (aArea.Top = 1) and (aArea.Bottom = TUtility.cMaxRow);
  var wholeRows: boolean := (aArea.Left = 1) and (aArea.Right = TUtility.cMaxColumn);
  if wholeColumns or wholeRows or aExisting then
  begin
    if aExisting then
      // the cells there already, below
    else if wholeColumns then
      for var column: TColCT in ColumnEntries(aArea.Left, aArea.Right) do
      begin
        column.Style := aNewStyle(column.Style);
        column.SetPresent(@column.Style);
      end
    else
      for var number := aArea.Top to aArea.Bottom do
      begin
        var rowIndex: integer;
        if not FindRow(sheet, number, rowIndex) then
        begin
          var added: TRowCT := TRowCT.Create;
          added.R := number;
          sheet.SheetData.Row.Insert(rowIndex, added);
        end;
        var row: TRowCT := sheet.SheetData.Row[rowIndex];
        if row.CustomFormat then
          row.S := aNewStyle(row.S)
        else
          row.S := aNewStyle(0);
        row.CustomFormat := True;
      end;
    // the cells there already
    var rowIndex: integer;
    FindRow(sheet, aArea.Top, rowIndex);
    var rows: TRowCTList := sheet.SheetData.Row;
    while (rowIndex < rows.Count) and (rows[rowIndex].R <= cardinal(aArea.Bottom)) do
    begin
      var row: TRowCT := rows[rowIndex];
      if wholeColumns and wholeRows and row.CustomFormat and not aExisting then
        row.S := aNewStyle(row.S); // the whole sheet: a formatted row's empty cells too
      var cellIndex: integer;
      FindInRow(row, aArea.Left, cellIndex);
      while (cellIndex < row.C.Count) and (TUtility.ColumnOf(row.C[cellIndex].R) <= aArea.Right) do
      begin
        row.C[cellIndex].S := aNewStyle(row.C[cellIndex].S);
        Inc(cellIndex);
      end;
      Inc(rowIndex);
    end;
  end
  else
    for var row := aArea.Top to aArea.Bottom do
      for var column := aArea.Left to aArea.Right do
      begin
        var cell: TCellCT := CellForStyle(row, column);
        cell.S := aNewStyle(cell.S);
      end;
end;

// the column's <col>, nil when it has none
function TXlsxSheet.ColumnEntry(aColumn: integer): TColCT;
begin
  for var columns: TColsCT in Objects(False).Cols do
    for var column: TColCT in columns.Col do
      if (cardinal(aColumn) >= column.Min) and (cardinal(aColumn) <= column.Max) then
        Exit(column);
  Result := nil;
end;

function TXlsxSheet.ColumnStyle(aColumn: integer): cardinal;
begin
  var column: TColCT := ColumnEntry(aColumn);
  if column = nil then
    Result := 0
  else
    Result := column.Style;
end;

// the <col> entries in one <cols> sorted, as Excel writes them (a <cols> added when there is none)
function TXlsxSheet.SortedColumns: TColCTList;
begin
  var sheet: TWorksheetE := Objects(True);
  if sheet.Cols.Count = 0 then
    sheet.Cols.Add(TColsCT.Create);
  Result := sheet.Cols[0].Col;
  while sheet.Cols.Count > 1 do
  begin
    var other: TColCTList := sheet.Cols[1].Col;
    while other.Count > 0 do
      Result.Add(other.Extract(other[0]));
    sheet.Cols.Delete(1);
  end;
  Result.Sort(TComparer<TColCT>.Construct(
    function(const aLeftColumn, aRightColumn: TColCT): integer
    begin
      Result := CompareValue(int64(aLeftColumn.Min), int64(aRightColumn.Min));
    end));
end;

// the <col> entries covering aLeft..aRight exactly, in order: those there split at the ends, the gaps filled with the
// default width (a <col> without one reads 0)
function TXlsxSheet.ColumnEntries(aLeft, aRight: integer): TArray<TColCT>;
begin
  var columns: TColCTList := SortedColumns;
  SplitColumns(columns, aLeft);
  if aRight < TUtility.cMaxColumn then
    SplitColumns(columns, aRight + 1);
  Result := [];
  var i: integer := 0;
  while (i < columns.Count) and (columns[i].Max < cardinal(aLeft)) do
    Inc(i);
  var next: integer := aLeft;
  while next <= aRight do
    if (i < columns.Count) and (columns[i].Min = cardinal(next)) then
    begin
      Result := Result + [columns[i]];
      next := columns[i].Max + 1;
      Inc(i);
    end
    else
    begin
      var last: integer := aRight;
      if (i < columns.Count) and (columns[i].Min <= cardinal(aRight)) then
        last := columns[i].Min - 1;
      var added: TColCT := TColCT.Create;
      added.Min := next;
      added.Max := last;
      added.Width := WidthToFile(AxisDefault(False).Size);
      columns.Insert(i, added);
      Inc(i);
      Result := Result + [added];
      next := last + 1;
    end;
end;

// the <row> entries of aTop..aBottom, made where missing
function TXlsxSheet.RowEntries(aTop, aBottom: integer): TArray<TRowCT>;
begin
  var sheet: TWorksheetE := Objects(True);
  var rows: TRowCTList := sheet.SheetData.Row;
  SetLength(Result, aBottom - aTop + 1);
  var rowIndex: integer;
  FindRow(sheet, aTop, rowIndex);
  for var number := aTop to aBottom do
  begin
    if (rowIndex >= rows.Count) or (rows[rowIndex].R <> cardinal(number)) then
    begin
      var added: TRowCT := TRowCT.Create;
      added.R := number;
      rows.Insert(rowIndex, added);
    end;
    Result[number - aTop] := rows[rowIndex];
    Inc(rowIndex);
  end;
end;

function TXlsxSheet.UsedRange: TArea;
begin
  var top: integer := MaxInt;
  var left: integer := MaxInt;
  var bottom: integer := 0;
  var right: integer := 0;
  for var row: TRowCT in Objects(False).SheetData.Row do
    if row.C.Count > 0 then
    begin
      top := Min(top, row.R);
      bottom := Max(bottom, row.R);
      left := Min(left, TUtility.ColumnOf(row.C.First.R));
      right := Max(right, TUtility.ColumnOf(row.C.Last.R));
    end;
  if bottom = 0 then
    Result := TArea.Make(1, 1, 1, 1)
  else
    Result := TArea.Make(top, left, bottom, right);
end;

end.
