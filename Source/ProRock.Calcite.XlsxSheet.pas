unit ProRock.Calcite.XlsxSheet;

// the xlsx backend of a worksheet: its part's cells, rows, columns, values and areas (internal)

interface

uses System.SysUtils, System.Generics.Collections, ProRock.Xmlite, ProRock.Office.Ooxml, ProRock.Xmlite.Schema.Ooxml.Sml,
  ProRock.Calcite.Utility, ProRock.Calcite.Aspects, ProRock.Calcite.Xlsx;

type
  // the areas Excel writes only by their own rules: array formulas (spills: the dynamic ones), data tables, tables (table
  // rows: their header and totals rows), pivot tables (with their page fields above), merged areas
  TAreaKind = (akArray, akSpill, akDataTable, akTable, akTableRow, akPivot, akMerge);

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
    // found on the first need (fFound), until a write here changes them or Forget: the areas by kind, shared formulas'
    // first cells by si
    fAreas: array[TAreaKind] of TArray<TArea>;
    fFound: set of TAreaKind;
    fShared: TDictionary<cardinal, TCellCT>;

    procedure Find(aKind: TAreaKind);
    procedure FindFormulas;
    procedure FindFixedAreas;
    procedure FindMerges;
    procedure ForgetFormulas;
    function CellForValue(aRow, aColumn: integer): TCellCT;
  public
    constructor Create(aBook: TXlsxBook; const aPart: string);
    destructor Destroy; override;

    // every cache dropped: the objects handed out, or changed outside the backend
    procedure Forget;

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

    function Areas(aKind: TAreaKind): TArray<TArea>;
    function AreaAt(aKind: TAreaKind; aRow, aColumn: integer; out aArea: TArea): boolean;
    function ValueAt(aRow, aColumn: integer; out aValue: Variant): TCellValueType;
    function ValueOf(aCell: TCellCT; out aValue: Variant): TCellValueType;
    // the formula without its =: a shared one's cells the first one's text moved to them, an array formula's and a data
    // table's cells their first one's
    function FormulaText(aRow, aColumn: integer; out aText: string): boolean;
    // a shared formula's cells as plain ones, each its own text (the values Excel calculated stay); False: its text unreadable
    function Unshare(aIndex: cardinal): boolean;
    // the value replacing the cell's, the cell created where Excel expects it; what the front let through
    procedure PutNumber(aRow, aColumn: integer; aValue: Double);
    // False: no shared strings to add it to, nothing changed (aInline: an inline string then)
    function PutText(aRow, aColumn: integer; const aValue: string; aInline: boolean = False): boolean;
    procedure PutBoolean(aRow, aColumn: integer; aValue: boolean);
    // a date's serial number, aStyle its date format's
    procedure PutSerial(aRow, aColumn: integer; aSerial: Double; aStyle: cardinal);
    procedure PutFormula(aRow, aColumn: integer; const aText: string);
    // the area's array formula, held by its first cell
    procedure PutArray(const aArea: TArea; const aText: string);
    // the cell's value as stored (a shared string's count stays), aFrom's gone
    procedure MoveValue(aFrom: TCellCT; aRow, aColumn: integer);
    // the first cell with a value, row by row; nil when there is none
    function FirstValue(const aArea: TArea): TCellCT;
    // the values of the area gone where aClearable lets them; cells and rows with nothing left of their own go too
    procedure ClearValues(const aArea: TArea; const aClearable: TFunc<integer, integer, boolean>);
    procedure RemoveValue(aCell: TCellCT);
    // the merged areas overlapping aArea gone
    procedure RemoveMerges(const aArea: TArea);
    procedure AddMerge(const aArea: TArea);
    procedure SetTabSelected(aValue: boolean);
    // the cell below and right of a frozen pane, '' when there is none
    function FrozenAt: string;
    // why Freeze would not do, '' when nothing stands in the way; aKeepOwn: the sheet's own panes stay
    function PanesBlocker(aKeepOwn: boolean): string;
    // Excel's frozen pane and its selections, as Excel writes them for one view; 1, 1: none
    procedure Freeze(aRow, aColumn: integer);

    property Part: string read fPart;
  end;

// binary search: the cells of a row by column
function FindInRow(aRow: TRowCT; aColumn: integer; out aIndex: integer): boolean;
// the <col> entry across aAt split there: ...aAt-1 and aAt...
procedure SplitColumns(aColumns: TColCTList; aAt: cardinal);
function HasValue(aCell: TCellCT): boolean;
// nothing left but its address: Excel keeps a cell with a format, a row with its own settings
function IsBare(aObject: TXmlite; const aProperties: array of string): boolean;

implementation

uses System.Math, System.Variants, System.TypInfo, System.Generics.Defaults, ProRock.Calcite.Formulas;

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

function HasValue(aCell: TCellCT): boolean;
begin
  Result := aCell.Present[@aCell.V] or aCell.IsPresent('F') or aCell.IsPresent('Is');
end;

function IsBare(aObject: TXmlite; const aProperties: array of string): boolean;
begin
  if (aObject.XmlAttributes <> nil) and (aObject.XmlAttributes.Count > 0) then
    Exit(False);
  for var name: string in aProperties do
    if aObject.IsPresent(name) then
      Exit(False);
  Result := True;
end;

// the value of a data table's cells, as Excel's Formula shows it: TABLE(row input, column input)
function TableFormula(aFormula: TCellFormulaCT): string;
begin
  if aFormula.Dt2D then
    Result := Format('TABLE(%s,%s)', [aFormula.R1, aFormula.R2])
  else if aFormula.Dtr then
    Result := Format('TABLE(%s,)', [aFormula.R1])
  else
    Result := Format('TABLE(,%s)', [aFormula.R1]);
end;

{ TXlsxSheet }

constructor TXlsxSheet.Create(aBook: TXlsxBook; const aPart: string);
begin
  inherited Create;
  fBook := aBook;
  fPart := aPart;
end;

destructor TXlsxSheet.Destroy;
begin
  fShared.Free;
  inherited;
end;

procedure TXlsxSheet.Forget;
begin
  fObjects := nil;
  fFound := [];
  FreeAndNil(fShared);
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

// aChange written to the rows or columns aFirst..aLast, their entries made where missing (a row's own height dropped and a
// row shown again only where it has an entry: Sheet.Rows makes none) - but rows shown on a sheet hiding the ones without an
// entry (zeroHeight) get entries; AutoFit there shows only rows with one
procedure TXlsxSheet.ApplyAxis(aByRows: boolean; aFirst, aLast: integer; const aChange: TAxisChange);
begin
  var aspects: TAxisAspects := aChange.Aspects;
  var entries: boolean := (axSize in aspects) or ((axHidden in aspects) and aChange.Value.Hidden)
    or ((aspects = [axHidden]) and aByRows and AxisDefault(True).Hidden);
  if aByRows and not entries then
  begin
    var sheet: TWorksheetE := Objects(False);
    var rows: TRowCTList := sheet.SheetData.Row;
    var rowIndex: integer;
    FindRow(sheet, aFirst, rowIndex);
    while (rowIndex < rows.Count) and (rows[rowIndex].R <= cardinal(aLast)) do
    begin
      var row: TRowCT := rows[rowIndex];
      if (axDefaultSize in aspects) and (row.Present[@row.Ht] or row.CustomHeight) then
      begin
        Objects(True);
        row.Clear(@row.Ht);
        row.Clear(@row.CustomHeight);
      end;
      if (axHidden in aspects) and row.Hidden then
      begin
        Objects(True);
        row.Clear(@row.Hidden);
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

{$REGION 'the areas by kind'}

procedure TXlsxSheet.Find(aKind: TAreaKind);
begin
  if aKind in fFound then
    Exit;
  case aKind of
    akArray, akSpill, akDataTable:
      FindFormulas;
    akTable, akTableRow, akPivot:
      FindFixedAreas;
    akMerge:
      FindMerges;
  end;
end;

procedure TXlsxSheet.FindFormulas;
begin
  FreeAndNil(fShared);
  fShared := TDictionary<cardinal, TCellCT>.Create;
  var arrays: TList<TArea> := TList<TArea>.Create;
  var spills: TList<TArea> := TList<TArea>.Create;
  var dataTables: TList<TArea> := TList<TArea>.Create;
  try
    for var row: TRowCT in Objects(False).SheetData.Row do
      for var cell: TCellCT in row.C do
        if cell.IsPresent('F') and (cell.F.T <> stcftNormal) then
          if cell.F.T = stcftShared then
          begin
            if cell.F.Ref <> '' then // the first cell: its text, the group's area
              fShared.AddOrSetValue(cell.F.Si, cell);
          end
          else
          begin
            var area: TArea;
            if not TArea.TryParse(cell.F.Ref, area) then
              TArea.TryParse(cell.R, area);
            if cell.F.T = stcftArray then
            begin
              arrays.Add(area);
              if (cell.Cm > 0) and fBook.IsDynamicArray(cell.Cm) then
                spills.Add(area);
            end
            else
              dataTables.Add(area);
          end;
    fAreas[akArray] := arrays.ToArray;
    fAreas[akSpill] := spills.ToArray;
    fAreas[akDataTable] := dataTables.ToArray;
  finally
    dataTables.Free;
    spills.Free;
    arrays.Free;
  end;
  fFound := fFound + [akArray, akSpill, akDataTable];
end;

// from the tables' and pivot tables' own parts
procedure TXlsxSheet.FindFixedAreas;
begin
  fAreas[akTable] := nil;
  fAreas[akTableRow] := nil;
  fAreas[akPivot] := nil;
  for var relationship: TRelationshipOoxml in fBook.Package.Relationships(fPart) do
  begin
    var area: TArea;
    if relationship.&Type.EndsWith(cTable) then
    begin
      var table: TTableE := fBook.Package.Part<TTableE>(relationship.Part);
      if (table <> nil) and TArea.TryParse(table.Ref, area) then
      begin
        var whole: TArea := area;
        fAreas[akTable] := fAreas[akTable] + [whole];
        if table.HeaderRowCount > 0 then
        begin
          area.Bottom := whole.Top + integer(table.HeaderRowCount) - 1;
          fAreas[akTableRow] := fAreas[akTableRow] + [area];
        end;
        if table.TotalsRowCount > 0 then
        begin
          area.Top := whole.Bottom - integer(table.TotalsRowCount) + 1;
          area.Bottom := whole.Bottom;
          fAreas[akTableRow] := fAreas[akTableRow] + [area];
        end;
      end;
    end
    else if relationship.&Type.EndsWith(cPivotTable) then
    begin
      var pivot: TPivotTableDefinitionE := fBook.Package.Part<TPivotTableDefinitionE>(relationship.Part);
      if (pivot <> nil) and TArea.TryParse(pivot.Location.Ref, area) then
      begin
        if pivot.Location.RowPageCount > 0 then // the page fields and a blank row
          area.Top := Max(1, area.Top - integer(pivot.Location.RowPageCount) - 1);
        fAreas[akPivot] := fAreas[akPivot] + [area];
      end;
    end;
  end;
  fFound := fFound + [akTable, akTableRow, akPivot];
end;

procedure TXlsxSheet.FindMerges;
begin
  var merges: TList<TArea> := TList<TArea>.Create;
  try
    var sheet: TWorksheetE := Objects(False);
    if sheet.IsPresent('MergeCells') then
      for var merged: TMergeCellCT in sheet.MergeCells.MergeCell do
      begin
        var area: TArea;
        if TArea.TryParse(merged.Ref, area) then
          merges.Add(area);
      end;
    fAreas[akMerge] := merges.ToArray;
  finally
    merges.Free;
  end;
  Include(fFound, akMerge);
end;

procedure TXlsxSheet.ForgetFormulas;
begin
  fFound := fFound - [akArray, akSpill, akDataTable];
  FreeAndNil(fShared);
end;

function TXlsxSheet.Areas(aKind: TAreaKind): TArray<TArea>;
begin
  Find(aKind);
  Result := fAreas[aKind];
end;

function TXlsxSheet.AreaAt(aKind: TAreaKind; aRow, aColumn: integer; out aArea: TArea): boolean;
begin
  for var area: TArea in Areas(aKind) do
    if area.Holds(aRow, aColumn) then
    begin
      aArea := area;
      Exit(True);
    end;
  Result := False;
end;

procedure TXlsxSheet.RemoveMerges(const aArea: TArea);
begin
  var sheet: TWorksheetE := Objects(False);
  if not sheet.IsPresent('MergeCells') then
    Exit;
  var list: TMergeCellCTList := sheet.MergeCells.MergeCell;
  for var i := list.Count - 1 downto 0 do
  begin
    var area: TArea;
    if TArea.TryParse(list[i].Ref, area) and area.Overlaps(aArea) then
    begin
      Objects(True);
      list.Delete(i);
    end;
  end;
  if list.Count = 0 then // the schema wants one at least
    sheet.Clear('MergeCells')
  else if sheet.MergeCells.Present[@sheet.MergeCells.Count] then
    sheet.MergeCells.Count := list.Count;
  Exclude(fFound, akMerge);
end;

procedure TXlsxSheet.AddMerge(const aArea: TArea);
begin
  var sheet: TWorksheetE := Objects(True);
  var added: TMergeCellCT := TMergeCellCT.Create;
  added.Ref := aArea.CellsAddress;
  sheet.MergeCells.MergeCell.Add(added);
  sheet.MergeCells.Count := sheet.MergeCells.MergeCell.Count;
  sheet.MergeCells.SetPresent(@sheet.MergeCells.Count);
  Exclude(fFound, akMerge);
end;

{$ENDREGION}

{$REGION 'the views: the tab, frozen panes'}

procedure TXlsxSheet.SetTabSelected(aValue: boolean);
begin
  var sheet: TWorksheetE := Objects(False);
  if sheet.IsPresent('SheetViews') then
    for var view: TSheetViewCT in sheet.SheetViews.SheetView do
      if view.TabSelected <> aValue then
      begin
        Objects(True);
        if aValue then
          view.TabSelected := True
        else
          view.Clear(@view.TabSelected);
      end;
end;

function TXlsxSheet.FrozenAt: string;
begin
  Result := '';
  var sheet: TWorksheetE := Objects(False);
  if not sheet.IsPresent('SheetViews') or (sheet.SheetViews.SheetView.Count = 0) or
    not sheet.SheetViews.SheetView[0].IsPresent('Pane') then
    Exit;
  var pane: TPaneCT := sheet.SheetViews.SheetView[0].Pane;
  if not (pane.State in [stpsFrozen, stpsFrozenSplit]) then
    Exit;
  var at: TArea;
  if (pane.TopLeftCell <> '') and TArea.TryParse(pane.TopLeftCell, at) and (at.Top = at.Bottom) and (at.Left = at.Right) then
    Result := TUtility.CellName(at.Top, at.Left)
  else
    Result := TUtility.CellName(Trunc(pane.YSplit) + 1, Trunc(pane.XSplit) + 1);
end;

function TXlsxSheet.PanesBlocker(aKeepOwn: boolean): string;
begin
  Result := '';
  var sheet: TWorksheetE := Objects(False);
  if sheet.IsPresent('SheetViews') and (sheet.SheetViews.SheetView.Count > 1) then
    Result := 'the sheet has several views; Calcite freezes panes only with one'
  else if aKeepOwn and sheet.IsPresent('SheetViews') and (sheet.SheetViews.SheetView.Count = 1) and
    sheet.SheetViews.SheetView[0].IsPresent('Pane') then
    Result := 'the sheet has panes of its own, which Calcite does not change yet';
end;

procedure TXlsxSheet.Freeze(aRow, aColumn: integer);
begin
  var sheet: TWorksheetE := Objects(False);
  if (aRow = 1) and (aColumn = 1) and not sheet.IsPresent('SheetViews') then
    Exit;
  sheet := Objects(True);
  if sheet.SheetViews.SheetView.Count = 0 then
  begin
    var added: TSheetViewCT := TSheetViewCT.Create;
    added.SetPresent(@added.WorkbookViewId);
    sheet.SheetViews.SheetView.Add(added);
  end;
  var view: TSheetViewCT := sheet.SheetViews.SheetView[0];
  view.Clear('Pane');
  view.Selection.Clear;
  if (aRow = 1) and (aColumn = 1) then
    Exit;
  var pane: TPaneCT := view.Pane;
  pane.XSplit := aColumn - 1;
  pane.YSplit := aRow - 1;
  pane.TopLeftCell := TUtility.CellName(aRow, aColumn);
  pane.State := stpsFrozen;
  pane.SetPresent(@pane.State);
  // a selection in each pane that scrolls, its first cell: Excel's own
  var panes: TArray<TPaneST>;
  var cells: TArray<string>;
  if aRow = 1 then
  begin
    panes := [stpTopRight];
    cells := [TUtility.CellName(1, aColumn)];
  end
  else if aColumn = 1 then
  begin
    panes := [stpBottomLeft];
    cells := [TUtility.CellName(aRow, 1)];
  end
  else
  begin
    panes := [stpTopRight, stpBottomLeft, stpBottomRight];
    cells := [TUtility.CellName(1, aColumn), TUtility.CellName(aRow, 1), TUtility.CellName(aRow, aColumn)];
  end;
  pane.ActivePane := panes[High(panes)];
  pane.SetPresent(@pane.ActivePane);
  for var i := 0 to High(panes) do
  begin
    var selection: TSelectionCT := TSelectionCT.Create;
    selection.Pane := panes[i];
    selection.SetPresent(@selection.Pane);
    selection.ActiveCell := cells[i];
    selection.Sqref := cells[i];
    view.Selection.Add(selection);
  end;
end;

{$ENDREGION}

{$REGION 'values and formulas'}

function TXlsxSheet.ValueAt(aRow, aColumn: integer; out aValue: Variant): TCellValueType;
begin
  Result := ValueOf(FindCell(aRow, aColumn), aValue);
end;

function TXlsxSheet.ValueOf(aCell: TCellCT; out aValue: Variant): TCellValueType;
begin
  aValue := Unassigned;
  var cell: TCellCT := aCell;
  if cell = nil then
    Exit(cvEmpty);
  var hasValue: boolean := cell.Present[@cell.V];
  if cell.T = stctInlineStr then
  begin
    if not cell.IsPresent('Is') then
      Exit(cvEmpty);
    aValue := RichText(cell.&Is);
    Exit(cvText);
  end;
  if not hasValue then
    Exit(cvEmpty);
  case cell.T of
    stctS:
      begin
        aValue := fBook.SharedString(StrToIntDef(cell.V, -1));
        Result := cvText;
      end;
    stctStr:
      begin
        aValue := DecodeText(cell.V);
        Result := cvText;
      end;
    stctB:
      begin
        aValue := (cell.V = '1') or SameText(cell.V, 'true');
        Result := cvBoolean;
      end;
    stctE:
      begin
        aValue := string(cell.V);
        Result := cvError;
      end;
  else
    var number: Double;
    if not TUtility.TryFloatFromText(string(cell.V).Trim, number) then
    begin // not a number: shown as it is
      aValue := string(cell.V);
      Exit(cvText);
    end;
    if fBook.IsDateStyle(cell.S) then
    begin
      aValue := VarFromDateTime(TUtility.SerialToDate(number, fBook.Date1904));
      Result := cvDate;
    end
    else
    begin
      aValue := number;
      Result := cvNumber;
    end;
  end;
end;

function TXlsxSheet.FormulaText(aRow, aColumn: integer; out aText: string): boolean;
begin
  aText := '';
  var cell: TCellCT := FindCell(aRow, aColumn);
  if (cell <> nil) and cell.IsPresent('F') then
    case cell.F.T of
      stcftShared:
        if cell.F.XmlValue <> '' then
          aText := DecodeText(cell.F.XmlValue)
        else
        begin
          Find(akArray);
          var first: TCellCT;
          var at: TArea;
          if fShared.TryGetValue(cell.F.Si, first) and TArea.TryParse(first.R, at) then
          begin
            var why: string;
            if not ShiftFormula(DecodeText(first.F.XmlValue), TReferenceMap.Fill(aRow - at.Top, aColumn - at.Left), aText, why) then
              aText := '';
          end;
        end;
      stcftDataTable:
        aText := TableFormula(cell.F);
    else
      aText := DecodeText(cell.F.XmlValue);
    end;
  if aText = '' then
  begin
    var area: TArea;
    if (AreaAt(akArray, aRow, aColumn, area) or AreaAt(akDataTable, aRow, aColumn, area)) and
      ((area.Top <> aRow) or (area.Left <> aColumn)) then
      FormulaText(area.Top, area.Left, aText);
  end;
  Result := aText <> '';
end;

function TXlsxSheet.Unshare(aIndex: cardinal): boolean;
begin
  Find(akArray);
  var first: TCellCT;
  var area: TArea;
  if not fShared.TryGetValue(aIndex, first) then
    Exit(True); // no first cell: nothing the others could be read from
  var text: string := DecodeText(first.F.XmlValue);
  var checked, why, unknown: string;
  if not TArea.TryParse(first.F.Ref, area) or
    not StoredFormula(text, checked, why, unknown) then
    Exit(False);
  var at: TArea;
  TArea.TryParse(first.R, at);
  var sheet: TWorksheetE := Objects(True);
  var rowIndex: integer;
  FindRow(sheet, area.Top, rowIndex);
  var rows: TRowCTList := sheet.SheetData.Row;
  while (rowIndex < rows.Count) and (rows[rowIndex].R <= cardinal(area.Bottom)) do
  begin
    var row: TRowCT := rows[rowIndex];
    for var cell: TCellCT in row.C do
      if cell.IsPresent('F') and (cell.F.T = stcftShared) and (cell.F.Si = aIndex) then
      begin
        var moved: string;
        ShiftFormula(text, TReferenceMap.Fill(integer(row.R) - at.Top, TUtility.ColumnOf(cell.R) - at.Left), moved, why);
        cell.F.Clear('T');
        cell.F.Clear('Si');
        cell.F.Clear('Ref');
        cell.F.XmlValue := EncodeText(moved);
      end;
    Inc(rowIndex);
  end;
  ForgetFormulas;
  fBook.FormulaChanged;
  Result := True;
end;

procedure TXlsxSheet.RemoveValue(aCell: TCellCT);
begin
  if (aCell.T = stctS) and aCell.Present[@aCell.V] then
    fBook.SharedStringReleased;
  if aCell.IsPresent('F') then
  begin
    if aCell.F.T <> stcftNormal then
      ForgetFormulas;
    aCell.Clear('F');
    fBook.FormulaChanged;
  end;
  aCell.Clear('Is');
  aCell.Clear(@aCell.V);
  aCell.Clear(@aCell.T);
  // cell and value metadata (dynamic arrays, rich values) belong to the value
  aCell.Clear(@aCell.Cm);
  aCell.Clear(@aCell.Vm);
end;

function TXlsxSheet.CellForValue(aRow, aColumn: integer): TCellCT;
begin
  Result := CellForStyle(aRow, aColumn);
  RemoveValue(Result);
  fBook.ValueChanged;
end;

procedure TXlsxSheet.PutNumber(aRow, aColumn: integer; aValue: Double);
begin
  CellForValue(aRow, aColumn).V := TUtility.FloatText(aValue, ftDouble);
end;

function TXlsxSheet.PutText(aRow, aColumn: integer; const aValue: string; aInline: boolean): boolean;
begin
  var index: integer := fBook.SharedStringIndex(aValue);
  Result := index >= 0;
  if not Result and not aInline then
    Exit;
  var cell: TCellCT := CellForValue(aRow, aColumn);
  if Result then
  begin
    cell.T := stctS;
    cell.V := IntToStr(index);
  end
  else
  begin
    cell.T := stctInlineStr;
    cell.&Is.T := EncodeText(aValue);
  end;
end;

procedure TXlsxSheet.PutBoolean(aRow, aColumn: integer; aValue: boolean);
begin
  var cell: TCellCT := CellForValue(aRow, aColumn);
  cell.T := stctB;
  cell.V := IntToStr(Ord(aValue));
end;

procedure TXlsxSheet.PutSerial(aRow, aColumn: integer; aSerial: Double; aStyle: cardinal);
begin
  var cell: TCellCT := CellForValue(aRow, aColumn);
  cell.S := aStyle;
  cell.V := TUtility.FloatText(aSerial, ftDouble);
end;

procedure TXlsxSheet.PutFormula(aRow, aColumn: integer; const aText: string);
begin
  CellForValue(aRow, aColumn).F.XmlValue := EncodeText(aText);
  fBook.FormulaChanged;
end;

procedure TXlsxSheet.PutArray(const aArea: TArea; const aText: string);
begin
  var formula: TCellFormulaCT := CellForValue(aArea.Top, aArea.Left).F;
  formula.T := stcftArray;
  formula.Ref := aArea.CellsAddress;
  formula.XmlValue := EncodeText(aText);
  ForgetFormulas;
  fBook.FormulaChanged;
end;

procedure TXlsxSheet.MoveValue(aFrom: TCellCT; aRow, aColumn: integer);
begin
  var target: TCellCT := CellForValue(aRow, aColumn);
  target.T := aFrom.T;
  target.V := aFrom.V;
  aFrom.Clear(@aFrom.V);
  aFrom.Clear(@aFrom.T);
end;

function TXlsxSheet.FirstValue(const aArea: TArea): TCellCT;
begin
  var sheet: TWorksheetE := Objects(False);
  var rowIndex: integer;
  FindRow(sheet, aArea.Top, rowIndex);
  var rows: TRowCTList := sheet.SheetData.Row;
  while (rowIndex < rows.Count) and (rows[rowIndex].R <= cardinal(aArea.Bottom)) do
  begin
    var cellIndex: integer;
    FindInRow(rows[rowIndex], aArea.Left, cellIndex);
    var cells: TCellCTList := rows[rowIndex].C;
    while (cellIndex < cells.Count) and (TUtility.ColumnOf(cells[cellIndex].R) <= aArea.Right) do
    begin
      if HasValue(cells[cellIndex]) then
        Exit(cells[cellIndex]);
      Inc(cellIndex);
    end;
    Inc(rowIndex);
  end;
  Result := nil;
end;

procedure TXlsxSheet.ClearValues(const aArea: TArea; const aClearable: TFunc<integer, integer, boolean>);
begin
  var sheet: TWorksheetE := Objects(False);
  var rowIndex: integer;
  FindRow(sheet, aArea.Top, rowIndex);
  var rows: TRowCTList := sheet.SheetData.Row;
  while (rowIndex < rows.Count) and (rows[rowIndex].R <= cardinal(aArea.Bottom)) do
  begin
    var row: TRowCT := rows[rowIndex];
    var cellIndex: integer;
    FindInRow(row, aArea.Left, cellIndex);
    while (cellIndex < row.C.Count) and (TUtility.ColumnOf(row.C[cellIndex].R) <= aArea.Right) do
    begin
      var cell: TCellCT := row.C[cellIndex];
      if HasValue(cell) then
      begin
        if not aClearable(row.R, TUtility.ColumnOf(cell.R)) then
        begin
          Inc(cellIndex);
          Continue;
        end;
        Objects(True);
        RemoveValue(cell);
        fBook.ValueChanged;
      end;
      if IsBare(cell, ['S', 'Ph', 'ExtLst']) then
      begin
        Objects(True);
        row.Remove(cell);
      end
      else
        Inc(cellIndex);
    end;
    if (row.C.Count = 0) and IsBare(row, ['S', 'CustomFormat', 'Ht', 'Hidden', 'CustomHeight', 'OutlineLevel', 'Collapsed',
      'ThickTop', 'ThickBot', 'Ph', 'ExtLst']) then
    begin
      Objects(True);
      sheet.SheetData.Remove(row);
    end
    else
      Inc(rowIndex);
  end;
end;

{$ENDREGION}

end.
