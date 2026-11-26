unit ProRock.Calcite.XlsxObjects;

// the xlsx backend's walk over what sits on the cells - tables, pivot tables, drawings, charts, notes - and its run (internal)

interface

uses ProRock.Calcite.Utility, ProRock.Calcite.XlsxWalk;

type
  // a worksheet's element (its property's name) or a relationship's type (its last segment) as the walk knows it: Handler
  // moves the references in it through an insert or delete; nil - none there, or refused with Why
  TKnownKind = record
    Name: string;
    Handler: TXlsxHandlerClass;
    Why: string;
  end;

  // the walk with its handlers: the orders they plan and apply in
  TXlsxRun = class(TXlsxWalk)
  private
    function Handler<T: TXlsxHandler>: T;
    function Shift: string;
    function DeleteSheet: string;
  public
    // Excel's Insert and Delete of aMap's rows or columns on aSheet, or its Delete of aSheet (TReferenceMap.SheetDeleted;
    // a very hidden or the last visible sheet is the caller's to refuse): why when refused, nothing changed then
    function Run(aSheet: TXlsxWalkSheet; const aMap: TReferenceMap): string;
    // what the walk knows, for the coverage test: an insert's or delete's handlers in plan order, every element of
    // CT_Worksheet, the relationship types
    class function ShiftOrder: TArray<TXlsxHandlerClass>;
    class function Elements: TArray<TKnownKind>;
    class function Parts: TArray<TKnownKind>;
  end;

implementation

uses System.SysUtils, System.Classes, System.Generics.Collections, System.StrUtils, System.Math, System.TypInfo,
  System.Generics.Defaults, ProRock.Xmlite, ProRock.Office.Ooxml, ProRock.Xmlite.Schema.Ooxml.Sml,
  ProRock.Calcite.Aspects, ProRock.Calcite.Xlsx, ProRock.Calcite.XlsxSheet, ProRock.Calcite.Formulas,
  ProRock.Xmlite.Schema.Ooxml.DmlSheet, ProRock.Xmlite.Schema.Ooxml.DmlChart, ProRock.Xmlite.Schema.Ooxml.Vml,
  ProRock.Xmlite.Schema.Ooxml.VmlExcel;

type
  {$REGION 'ProRock.Xmlite.Schema.Ooxml types aliases'}
  // DrawingML and its charts have ones of these names too
  TMarkerCT = ProRock.Xmlite.Schema.Ooxml.DmlSheet.TMarkerCT;
  TExtensionCT = ProRock.Xmlite.Schema.Ooxml.DmlChart.TExtensionCT;
  {$ENDREGION}

  // the sheet's rows or columns as drawings place objects on them, in EMUs (12700 a point, 9525 a pixel): where one
  // starts (from 0, as markers count), which one a distance falls in
  TAxis = class
  private
    fDefault: Int64;
    fSizes: TList<TPair<integer, Int64>>; // the rows or columns (from 1) of another size, in order
  public
    constructor Create(aSheet: TXlsxWalkSheet; aByRows: boolean);
    destructor Destroy; override;
    function Start(aIndex: integer): Int64;
    procedure Find(aPosition: Int64; out aIndex: integer; out aOffset: Int64);
  end;

  // the sheet's tables: they fill the walk's map first (the data row a delete keeps, the tables and columns gone, their
  // bodies); a sheet deleted, the other sheets' tables' formulas naming it
  TTablesHandler = class(TXlsxHandler)
  private type
    // a formula of a table on another sheet, changed
    TKeptFormula = record
      Part: string;
      Formula: TTableFormulaCT;
      Text: string;
    end;
  private
    fCleared: TList<TArea>; // the data rows kept, emptied after the move
    fKept: TList<TKeptFormula>;
    procedure ShiftTables;
    function PlanOthers: string;
    function PlanFormula(const aPart: string; aFormula: TTableFormulaCT): string;
  public
    constructor Create(aWalk: TXlsxWalk); override;
    destructor Destroy; override;
    procedure Complete(var aMap: TReferenceMap);
    function Plan: string; override;
    procedure Apply; override;
    procedure Written(aTo: TStringBuilder); override;
  end;

  // the sheet's pivot tables and the caches' sources on it; a sheet deleted, the caches only its pivot tables used
  TPivotsHandler = class(TXlsxHandler)
  private
    fCaches: TList<string>;
    procedure PlanCaches;
    procedure DropCaches;
  public
    constructor Create(aWalk: TXlsxWalk); override;
    destructor Destroy; override;
    function Plan: string; override;
    procedure Apply; override;
  end;

  TNotesHandler = class(TXlsxHandler)
  private
    procedure NotesParts(out aComments, aDrawing: string);
  public
    function Plan: string; override;
    procedure Apply; override;
  end;

  TDrawingsHandler = class(TXlsxHandler)
  private type
    // a drawing's object (xdr:twoCellAnchor or xdr:oneCellAnchor) and where it started and ended on the shifted axis
    TAnchorMove = record
      Part: string;
      Anchor: TXmlite;
      From, &To: Int64;
    end;
  private
    fMoves: TList<TAnchorMove>;
  public
    constructor Create(aWalk: TXlsxWalk); override;
    destructor Destroy; override;
    function Plan: string; override;
    procedure Apply; override;
  end;

  // every chart's references to cells, on every sheet's and chart sheet's drawings (but a deleted sheet's)
  TChartsHandler = class(TXlsxHandler)
  private type
    // a chart's reference to cells through the change: its c:f (Index -1), or an extension's element kept as read (Index
    // in XmlUnknown); the text before and after
    TChartMove = record
      Part: string;
      Reference: TXmlite;
      Index: integer;
      Before, After: string;
    end;
  private
    fMoves: TList<TChartMove>;
    function ChartParts(aCharts: TList<string>): string;
    function PlanChart(const aPart: string; aFound: TList<TXmlite>; aSeen: TDictionary<TBasite, boolean>): string;
  public
    constructor Create(aWalk: TXlsxWalk); override;
    destructor Destroy; override;
    function Plan: string; override;
    procedure Apply; override;
    procedure Written(aTo: TStringBuilder); override;
  end;

  // the sheet's elements the walk refuses (cElements): a sheet with one is refused whole
  TRefusedElementsHandler = class(TXlsxHandler)
  public
    function Plan: string; override;
  end;

  // the parts the workbook reaches, by their relationships' types (cParts): one the walk does not know or refuses
  // refuses the run - an unknown part may name the cells that move
  TPartsHandler = class(TXlsxHandler)
  public
    function Plan: string; override;
  end;

const
  cNotYet = ', which Calcite does not move yet';

  {$REGION 'what the walk knows: the elements, the relationship types'}
  // CT_Worksheet's elements in the schema's order; the coverage test holds the list to the schema
  cElements: array[0 .. 38] of TKnownKind = (
    (Name: 'SheetPr'; Handler: nil; Why: ''),
    (Name: 'Dimension'; Handler: TDimensionHandler; Why: ''),
    (Name: 'SheetViews'; Handler: TPanesHandler; Why: ''),
    (Name: 'SheetFormatPr'; Handler: nil; Why: ''),
    (Name: 'Cols'; Handler: TCellsHandler; Why: ''),
    (Name: 'SheetData'; Handler: TCellsHandler; Why: ''),
    (Name: 'SheetCalcPr'; Handler: nil; Why: ''),
    (Name: 'SheetProtection'; Handler: nil; Why: ''),
    (Name: 'ProtectedRanges'; Handler: TProtectedRangesHandler; Why: ''),
    (Name: 'Scenarios'; Handler: nil; Why: 'scenarios'),
    (Name: 'AutoFilter'; Handler: TAutoFilterHandler; Why: ''),
    (Name: 'SortState'; Handler: TSortHandler; Why: ''),
    (Name: 'DataConsolidate'; Handler: nil; Why: 'a data consolidation'),
    (Name: 'CustomSheetViews'; Handler: nil; Why: 'custom views'),
    (Name: 'MergeCells'; Handler: TMergesHandler; Why: ''),
    (Name: 'PhoneticPr'; Handler: nil; Why: ''),
    (Name: 'ConditionalFormatting'; Handler: TConditionalAreasHandler; Why: ''),
    (Name: 'DataValidations'; Handler: TValidationAreasHandler; Why: ''),
    (Name: 'Hyperlinks'; Handler: THyperlinksHandler; Why: ''),
    (Name: 'PrintOptions'; Handler: nil; Why: ''),
    (Name: 'PageMargins'; Handler: nil; Why: ''),
    (Name: 'PageSetup'; Handler: nil; Why: ''),
    (Name: 'HeaderFooter'; Handler: nil; Why: ''),
    (Name: 'RowBreaks'; Handler: TPageBreaksHandler; Why: ''),
    (Name: 'ColBreaks'; Handler: TPageBreaksHandler; Why: ''),
    (Name: 'CustomProperties'; Handler: nil; Why: ''),
    (Name: 'CellWatches'; Handler: nil; Why: 'watched cells'),
    (Name: 'IgnoredErrors'; Handler: TIgnoredErrorsHandler; Why: ''),
    (Name: 'SmartTags'; Handler: nil; Why: 'smart tags'),
    (Name: 'Drawing'; Handler: TDrawingsHandler; Why: ''),
    (Name: 'LegacyDrawing'; Handler: TNotesHandler; Why: ''),
    (Name: 'LegacyDrawingHF'; Handler: nil; Why: ''),
    (Name: 'DrawingHF'; Handler: nil; Why: ''),
    (Name: 'Picture'; Handler: nil; Why: ''),
    (Name: 'OleObjects'; Handler: nil; Why: 'embedded objects'),
    (Name: 'Controls'; Handler: nil; Why: 'controls'),
    (Name: 'WebPublishItems'; Handler: nil; Why: 'items published to the web'),
    (Name: 'TableParts'; Handler: TTablesHandler; Why: ''),
    (Name: 'ExtLst'; Handler: nil; Why: 'Excel 2010''s extensions (conditional formats, validation, sparklines)'));

  // the relationship types from the workbook down; a type not here refuses. A handler refuses what it cannot move yet
  // (threaded comments, chartEx); the elements refuse embedded objects and controls before their parts matter
  cParts: array[0 .. 63] of TKnownKind = (
    (Name: 'worksheet'; Handler: TCellsHandler; Why: ''),
    (Name: 'chartsheet'; Handler: TChartsHandler; Why: ''),
    (Name: 'sharedStrings'; Handler: nil; Why: ''),
    (Name: 'styles'; Handler: nil; Why: ''),
    (Name: 'theme'; Handler: nil; Why: ''),
    (Name: 'themeOverride'; Handler: nil; Why: ''),
    (Name: 'calcChain'; Handler: nil; Why: ''), // the book drops it with any formula changed
    (Name: 'sheetMetadata'; Handler: nil; Why: ''),
    (Name: 'connections'; Handler: nil; Why: ''),
    (Name: 'queryTable'; Handler: TTablesHandler; Why: ''),
    (Name: 'customXml'; Handler: nil; Why: ''),
    (Name: 'customXmlProps'; Handler: nil; Why: ''),
    (Name: 'xmlMaps'; Handler: nil; Why: ''),
    (Name: 'tableSingleCells'; Handler: nil; Why: 'cells mapped to XML'),
    (Name: 'externalLink'; Handler: nil; Why: ''),
    (Name: 'externalLinkPath'; Handler: nil; Why: ''),
    (Name: 'xlPathMissing'; Handler: nil; Why: ''),
    (Name: 'volatileDependencies'; Handler: nil; Why: 'real-time data (volatile dependencies)'),
    (Name: 'revisionHeaders'; Handler: nil; Why: 'a shared workbook''s revisions'),
    (Name: 'usernames'; Handler: nil; Why: ''),
    (Name: 'person'; Handler: nil; Why: ''),
    (Name: 'vbaProject'; Handler: nil; Why: ''),
    (Name: 'attachedToolbars'; Handler: nil; Why: ''),
    (Name: 'customProperty'; Handler: nil; Why: ''),
    (Name: 'printerSettings'; Handler: nil; Why: ''),
    (Name: 'hyperlink'; Handler: nil; Why: ''),
    (Name: 'image'; Handler: nil; Why: ''),
    (Name: 'media'; Handler: nil; Why: ''),
    (Name: 'audio'; Handler: nil; Why: ''),
    (Name: 'video'; Handler: nil; Why: ''),
    (Name: 'oleObject'; Handler: nil; Why: ''),
    (Name: 'package'; Handler: nil; Why: ''),
    (Name: 'control'; Handler: nil; Why: ''),
    (Name: 'ctrlProp'; Handler: nil; Why: ''),
    (Name: 'activeXControlBinary'; Handler: nil; Why: ''),
    (Name: 'table'; Handler: TTablesHandler; Why: ''),
    (Name: 'pivotTable'; Handler: TPivotsHandler; Why: ''),
    (Name: 'pivotCacheDefinition'; Handler: TPivotsHandler; Why: ''),
    (Name: 'pivotCacheRecords'; Handler: nil; Why: ''),
    (Name: 'slicer'; Handler: nil; Why: ''),
    (Name: 'slicerCache'; Handler: nil; Why: ''),
    (Name: 'timeline'; Handler: nil; Why: ''),
    (Name: 'timelineCache'; Handler: nil; Why: ''),
    (Name: 'comments'; Handler: TNotesHandler; Why: ''),
    (Name: 'vmlDrawing'; Handler: TNotesHandler; Why: ''),
    (Name: 'threadedComment'; Handler: TNotesHandler; Why: ''),
    (Name: 'namedSheetView'; Handler: nil; Why: 'named sheet views'),
    (Name: 'drawing'; Handler: TDrawingsHandler; Why: ''),
    (Name: 'chart'; Handler: TChartsHandler; Why: ''),
    (Name: 'chartEx'; Handler: TChartsHandler; Why: ''),
    (Name: 'chartUserShapes'; Handler: nil; Why: ''),
    (Name: 'chartStyle'; Handler: nil; Why: ''),
    (Name: 'chartColorStyle'; Handler: nil; Why: ''),
    (Name: 'diagramData'; Handler: nil; Why: ''),
    (Name: 'diagramLayout'; Handler: nil; Why: ''),
    (Name: 'diagramQuickStyle'; Handler: nil; Why: ''),
    (Name: 'diagramColors'; Handler: nil; Why: ''),
    (Name: 'diagramDrawing'; Handler: nil; Why: ''),
    (Name: 'webextension'; Handler: nil; Why: ''),
    (Name: 'rdRichValue'; Handler: nil; Why: ''),
    (Name: 'rdRichValueStructure'; Handler: nil; Why: ''),
    (Name: 'rdRichValueTypes'; Handler: nil; Why: ''),
    (Name: 'richStyles'; Handler: nil; Why: ''),
    (Name: 'rdRichValueWebImage'; Handler: nil; Why: ''));

  {$ENDREGION}

  // the plan orders: the first why is the refusal; an insert's or delete's lists by address last, they apply in this order
  cShift: array[0 .. 9] of TXlsxHandlerClass = (TCellsHandler, TPivotsHandler, TTablesHandler, TRefusedElementsHandler,
    TPartsHandler, TNotesHandler, TDrawingsHandler, TChartsHandler, TFormulasHandler, TNamesHandler);
  cLists: array[0 .. 10] of TXlsxHandlerClass = (TMergesHandler, TConditionalAreasHandler, TValidationAreasHandler,
    THyperlinksHandler, TAutoFilterHandler, TSortHandler, TIgnoredErrorsHandler, TProtectedRangesHandler,
    TPageBreaksHandler, TPanesHandler, TDimensionHandler);
  // the local names last: they read what the others write
  cDeleteSheet: array[0 .. 8] of TXlsxHandlerClass = (TSheetHandler, TPartsHandler, TFormulasHandler, TChartsHandler,
    TNamesHandler, TExtensionsHandler, TTablesHandler, TPivotsHandler, TLocalNamesHandler);

// a DrawingML coordinate (ST_Coordinate) in EMUs: a number of them, or a measure with its unit (2.5cm, 1in, 12pt)
function CoordinateEmus(const aText: string; out aEmus: Int64): boolean;
const
  cUnits: array[0 .. 5] of string = ('mm', 'cm', 'in', 'pt', 'pc', 'pi');
  cEmus: array[0 .. 5] of integer = (36000, 360000, 914400, 12700, 152400, 152400);
begin
  if TryStrToInt64(aText, aEmus) then
    Exit(True);
  for var i := 0 to High(cUnits) do
    if aText.EndsWith(cUnits[i]) then
    begin
      var number: Double;
      Result := TUtility.TryFloatFromText(aText.Substring(0, aText.Length - 2), number);
      if Result then
        aEmus := Round(number * cEmus[i]);
      Exit;
    end;
  Result := False;
end;

// a marker's row (aByRows) or column, from 0, and its offset in EMUs; False when the offset does not read
function MarkerPlace(aMarker: TMarkerCT; aByRows: boolean; out aIndex: integer; out aOffset: Int64): boolean;
begin
  if aByRows then
  begin
    aIndex := aMarker.Row;
    Result := CoordinateEmus(aMarker.RowOff, aOffset);
  end
  else
  begin
    aIndex := aMarker.Col;
    Result := CoordinateEmus(aMarker.ColOff, aOffset);
  end;
end;

procedure PlaceMarker(aMarker: TMarkerCT; aByRows: boolean; aIndex: integer; aOffset: Int64);
begin
  if aByRows then
  begin
    aMarker.Row := aIndex;
    aMarker.RowOff := IntToStr(aOffset);
  end
  else
  begin
    aMarker.Col := aIndex;
    aMarker.ColOff := IntToStr(aOffset);
  end;
end;

{ TAxis }

constructor TAxis.Create(aSheet: TXlsxWalkSheet; aByRows: boolean);
const
  cPoint = 12700;
  cPixel = 9525;

  function Emus(const aAxis: TAxisFormat): Int64;
  begin
    if aAxis.Hidden then
      Result := 0
    else if aByRows then
      Result := Round(aAxis.Size * cPoint)
    else // pixels as Excel shows the widths in Calibri's or Aptos Narrow's digits (cDigitPixels), as ColumnWidth reads them
      Result := TUtility.WidthPixels(aAxis.Size) * cPixel;
  end;

begin
  fSizes := TList<TPair<integer, Int64>>.Create;
  fDefault := Emus(aSheet.Store.AxisDefault(aByRows));
  for var entry: TPair<integer, TAxisFormat> in aSheet.Store.AxisEntries(aByRows) do
    fSizes.Add(TPair<integer, Int64>.Create(entry.Key, Emus(entry.Value)));
end;

destructor TAxis.Destroy;
begin
  fSizes.Free;
  inherited;
end;

function TAxis.Start(aIndex: integer): Int64;
begin
  Result := fDefault * aIndex;
  for var size: TPair<integer, Int64> in fSizes do
    if size.Key <= aIndex then
      Inc(Result, size.Value - fDefault)
    else
      Break;
end;

procedure TAxis.Find(aPosition: Int64; out aIndex: integer; out aOffset: Int64);
begin
  var start: Int64 := 0;
  var next: integer := 1; // the first row or column not passed yet, from 1
  for var size: TPair<integer, Int64> in fSizes do
  begin
    var block: Int64 := fDefault * (size.Key - next);
    if aPosition < start + block then
      Break;
    Inc(start, block);
    if aPosition < start + size.Value then
    begin
      aIndex := size.Key - 1;
      aOffset := aPosition - start;
      Exit;
    end;
    Inc(start, size.Value);
    next := size.Key + 1;
  end;
  if fDefault = 0 then
  begin
    aIndex := next - 1;
    aOffset := 0;
    Exit;
  end;
  aIndex := next - 1 + integer((aPosition - start) div fDefault);
  aOffset := (aPosition - start) mod fDefault;
end;

// why Excel or Calcite does not move the sheet's tables (and the sheet's autofilter) so, '' when nothing stands in the way
function TTablesHandler.Plan: string;
const
  cFiltered = 'a filtered %s (%s): Excel inserts and deletes rows through a filter only partly, which Calcite does not ' +
    'copy - clear the filter first';
  cFilterDeleted = 'a filtered column of a %s (%s) deleted while other filters stay: Excel shows the rows only that filter ' +
    'hid, which Calcite does not work out - clear the filter first';
var
  last: integer;

  // columns deleted with some of the filtered ones, not all
  function SomeFilters(aFilter: TAutoFilterCT; aLeft: integer): boolean;
  begin
    var deleted: integer := 0;
    for var column: TFilterColumnCT in aFilter.FilterColumn do
      if (aLeft + integer(column.ColId) >= fMap.First) and (aLeft + integer(column.ColId) <= last) then
        Inc(deleted);
    Result := not fMap.ByRows and (fMap.Delta < 0) and (deleted > 0) and (deleted < aFilter.FilterColumn.Count);
  end;

  // rows passing through it: an insert below its first row, a delete taking any
  function Through(const aArea: TArea): boolean;
  begin
    Result := fMap.ByRows and ((fMap.Delta > 0) and (fMap.First > aArea.Top) and (fMap.First <= aArea.Bottom) or
      (fMap.Delta < 0) and (fMap.First <= aArea.Bottom) and (last >= aArea.Top));
  end;

begin
  if fMap.Change = TReferenceChange.rcSheetDelete then
    Exit(PlanOthers);
  last := fMap.First - fMap.Delta - 1;
  var package: TPackageOoxml := fBook.Package;
  for var relationship: TRelationshipOoxml in package.Relationships(fStore.Part) do
    if relationship.&Type.EndsWith(cTable) then
    begin
      var table: TTableE := package.Part<TTableE>(relationship.Part);
      var area: TArea;
      if (table = nil) or not TArea.TryParse(table.Ref, area) then
        Exit(Format('a table that does not read (%s)', [relationship.Part]));
      if IfThen(fMap.ByRows, area.Bottom, area.Right) < fMap.First then
        Continue;
      if table.TableType <> stttWorksheet then
        Exit(Format('a table from a query or an XML map (%s, %s), which Calcite does not move yet', [table.Name,
          area.CellsAddress]));
      if fMap.ByRows and (fMap.Delta < 0) and (table.HeaderRowCount > 0) and (fMap.First < area.Top + integer(table.HeaderRowCount)) and
        (last >= area.Top) and ((fMap.First > area.Top) or (last < area.Bottom)) then
        Exit(Format('the header row of a table (%s, %s): Excel deletes it only with the whole table', [table.Name,
          area.CellsAddress]));
      if table.IsPresent('AutoFilter') and (table.AutoFilter.FilterColumn.Count > 0) and Through(area) then
        Exit(Format(cFiltered, ['table', table.Name]));
      if table.IsPresent('AutoFilter') and SomeFilters(table.AutoFilter, area.Left) then
        Exit(Format(cFilterDeleted, ['table', table.Name]));
    end;
  var sheet: TWorksheetE := fStore.Objects(False);
  if sheet.IsPresent('AutoFilter') and (sheet.AutoFilter.FilterColumn.Count > 0) then
  begin
    var area: TArea;
    if TArea.TryParse(sheet.AutoFilter.Ref, area) and Through(area) then
      Exit(Format(cFiltered, ['list', area.CellsAddress]));
    if SomeFilters(sheet.AutoFilter, area.Left) then
      Exit(Format(cFilterDeleted, ['list', area.CellsAddress]));
  end;
  Result := '';
end;

// Excel's refusal of a pivot table cut (its page fields above it count), '' when none is; a sheet deleted, its caches
function TPivotsHandler.Plan: string;
begin
  if fMap.Change = TReferenceChange.rcSheetDelete then
  begin
    PlanCaches;
    Exit('');
  end;
  var last: integer := fMap.First - fMap.Delta - 1;
  for var area: TArea in fStore.Areas(akPivot) do
  begin
    var low: integer := IfThen(fMap.ByRows, area.Top, area.Left);
    var high: integer := IfThen(fMap.ByRows, area.Bottom, area.Right);
    if (fMap.Delta > 0) and (fMap.First > low) and (fMap.First <= high) or
      (fMap.Delta < 0) and (fMap.First <= high) and (last >= low) and ((fMap.First > low) or (last < high)) then
      Exit('We can''t make this change for the selected cells because it will affect a PivotTable. Use the field list to ' +
        'change the report. If you are trying to insert or delete cells, move the PivotTable and try again.');
  end;
  // a consolidation names its ranges by sheet
  var package: TPackageOoxml := fBook.Package;
  for var relationship: TRelationshipOoxml in package.Relationships(fBook.WorkbookPart) do
    if relationship.&Type.EndsWith(cPivotCacheDefinition) then
    begin
      var cache: TPivotCacheDefinitionE := package.Part<TPivotCacheDefinitionE>(relationship.Part);
      if cache = nil then
        Exit(Format('a pivot cache that does not read (%s)', [relationship.Part]));
      if cache.CacheSource.IsPresent('Consolidation') then
        Exit('a pivot table consolidating ranges, which Calcite does not move yet');
    end;
  Result := '';
end;

constructor TPivotsHandler.Create(aWalk: TXlsxWalk);
begin
  inherited;
  fCaches := TList<string>.Create;
end;

destructor TPivotsHandler.Destroy;
begin
  fCaches.Free;
  inherited;
end;

// a sheet deleted: the caches only its pivot tables used, in fCaches
procedure TPivotsHandler.PlanCaches;
begin
  var package: TPackageOoxml := fBook.Package;
  var used: TList<string> := TList<string>.Create(TIStringComparer.Ordinal);
  try
    for var sheet: TXlsxWalkSheet in fWalk.Sheets do
      if sheet <> fSheet then
        for var pivot: TRelationshipOoxml in package.Relationships(sheet.Store.Part, cPivotTable) do
          for var cache: TRelationshipOoxml in package.Relationships(pivot.Part, cPivotCacheDefinition) do
            used.Add(cache.Part);
    for var pivot: TRelationshipOoxml in package.Relationships(fStore.Part, cPivotTable) do
      for var cache: TRelationshipOoxml in package.Relationships(pivot.Part, cPivotCacheDefinition) do
        if not used.Contains(cache.Part) and not fCaches.Contains(cache.Part) then
          fCaches.Add(cache.Part);
  finally
    used.Free;
  end;
end;

// a sheet deleted: its caches out of the workbook's list, their parts to the walk's dropped ones
procedure TPivotsHandler.DropCaches;
begin
  var package: TPackageOoxml := fBook.Package;
  var workbook: TWorkbookE := package.EditPart<TWorkbookE>(fBook.WorkbookPart);
  if workbook.IsPresent('PivotCaches') then
  begin
    for var relationship: TRelationshipOoxml in package.Relationships(fBook.WorkbookPart, cPivotCacheDefinition) do
      if fCaches.Contains(relationship.Part) then
        for var i := workbook.PivotCaches.PivotCache.Count - 1 downto 0 do
          if workbook.PivotCaches.PivotCache[i].Id = relationship.Id then
            workbook.PivotCaches.PivotCache.Delete(i);
    if workbook.PivotCaches.PivotCache.Count = 0 then
      workbook.Clear('PivotCaches');
  end;
  fWalk.Dropped.AddRange(fCaches);
end;

constructor TTablesHandler.Create(aWalk: TXlsxWalk);
begin
  inherited;
  fCleared := TList<TArea>.Create;
  fKept := TList<TKeptFormula>.Create;
end;

destructor TTablesHandler.Destroy;
begin
  fKept.Free;
  fCleared.Free;
  inherited;
end;

// a sheet deleted: the other sheets' tables' formulas naming it, in fKept; why one does not read, '' when all do
function TTablesHandler.PlanOthers: string;
begin
  var package: TPackageOoxml := fBook.Package;
  for var sheet: TXlsxWalkSheet in fWalk.Sheets do
    if sheet <> fSheet then
      for var relationship: TRelationshipOoxml in package.Relationships(sheet.Store.Part, cTable) do
      begin
        var table: TTableE := package.Part<TTableE>(relationship.Part);
        if table <> nil then
          for var column: TTableColumnCT in table.TableColumns.TableColumn do
          begin
            Result := '';
            if column.IsPresent('CalculatedColumnFormula') then
              Result := PlanFormula(relationship.Part, column.CalculatedColumnFormula);
            if (Result = '') and column.IsPresent('TotalsRowFormula') then
              Result := PlanFormula(relationship.Part, column.TotalsRowFormula);
            if Result <> '' then
              Exit;
          end;
      end;
  Result := '';
end;

function TTablesHandler.PlanFormula(const aPart: string; aFormula: TTableFormulaCT): string;
begin
  Result := '';
  var text: string := DecodeText(aFormula.XmlValue);
  var kept: TKeptFormula := Default(TKeptFormula);
  var why: string;
  if not ShiftFormula(text, fMap, kept.Text, why) then
  begin
    if ContainsText(text, fName) then
      Result := Format('a formula of the table %s does not read: %s', [aPart, why]);
    Exit;
  end;
  if kept.Text = text then
    Exit;
  kept.Part := aPart;
  kept.Formula := aFormula;
  fKept.Add(kept);
end;

procedure TTablesHandler.Written(aTo: TStringBuilder);
begin
  for var kept: TKeptFormula in fKept do
    aTo.Append(kept.Text).Append(#10);
end;

// the walk's map without the data row a delete keeps (all the data rows of a table whose header stays deleted: Excel keeps
// the first of them, emptied, and deletes the rest), with the tables and table columns the change deletes and the tables'
// bodies, for the formulas naming them; a sheet deleted, all its tables
procedure TTablesHandler.Complete(var aMap: TReferenceMap);
begin
  var package: TPackageOoxml := fBook.Package;
  if aMap.Change = TReferenceChange.rcSheetDelete then
  begin
    for var relationship: TRelationshipOoxml in package.Relationships(fStore.Part, cTable) do
    begin
      var table: TTableE := package.Part<TTableE>(relationship.Part);
      if table <> nil then
        aMap.GoneTables := aMap.GoneTables + [string(table.Name)];
    end;
    Exit;
  end;
  if aMap.ByRows and (aMap.Change = TReferenceChange.rcDelete) then
  begin
    var last: integer := aMap.First - aMap.Delta - 1;
    for var relationship: TRelationshipOoxml in package.Relationships(fStore.Part) do
      if relationship.&Type.EndsWith(cTable) then
      begin
        var table: TTableE := package.Part<TTableE>(relationship.Part);
        var area: TArea;
        if (table = nil) or not TArea.TryParse(table.Ref, area) or
          (table.HeaderRowCount = 0) then
          Continue;
        var dataTop: integer := area.Top + integer(table.HeaderRowCount);
        var dataBottom: integer := area.Bottom - integer(table.TotalsRowCount);
        if (dataTop <= dataBottom) and (aMap.First = dataTop) and (last >= dataBottom) then
        begin
          area.Top := dataTop;
          area.Bottom := dataTop;
          fCleared.Add(area);
        end;
      end;
    if fCleared.Count > 0 then
    begin
      Inc(aMap.First);
      Dec(aMap.Count);
    end;
  end;
  var gone: TArray<string> := nil;
  var bodies: TArray<TTableBody> := nil;
  var last: integer := aMap.First - aMap.Delta - 1;
  for var relationship: TRelationshipOoxml in package.Relationships(fStore.Part) do
    if relationship.&Type.EndsWith(cTable) then
    begin
      var table: TTableE := package.Part<TTableE>(relationship.Part);
      var area: TArea;
      if not TArea.TryParse(table.Ref, area) then
        Continue;
      var body: TTableBody;
      body.Left := area.Left;
      body.Right := area.Right;
      body.Top := area.Top;
      body.Bottom := area.Bottom;
      body.DataTop := area.Top + integer(table.HeaderRowCount);
      body.DataBottom := area.Bottom - integer(table.TotalsRowCount);
      bodies := bodies + [body];
      if aMap.Delta > 0 then
        Continue;
      if not aMap.MovedArea(area) then
        gone := gone + [string(table.Name)]
      else if not aMap.ByRows then
      begin
        TArea.TryParse(table.Ref, area);
        for var index := 0 to table.TableColumns.TableColumn.Count - 1 do
          if (area.Left + index >= aMap.First) and (area.Left + index <= last) then
            gone := gone + [table.Name + '[' + table.TableColumns.TableColumn[index].Name + ']'];
      end;
    end;
  aMap.GoneTables := gone;
  aMap.Bodies := bodies;
end;

// the sheet's tables as Excel moves them: grown by rows or columns inserted inside (new columns named Column1...; new rows
// take the calculated columns' formulas), shrunk, gone with all their rows or columns; the totals row deleted, the table
// keeps none; the autofilter, its columns and sort follow
procedure TTablesHandler.ShiftTables;
var
  sheet: TWorksheetE;
  last: integer;

  function Changed(const aText: string): string;
  begin
    var why: string;
    var map: TReferenceMap := fMap;
    map.OnSheet := True;
    map.InName := False;
    if not ShiftFormula(aText, map, Result, why) then
      Result := aText;
  end;

  procedure ChangeFormula(aFormula: TTableFormulaCT);
  begin
    var text: string := DecodeText(aFormula.XmlValue);
    var newText: string := Changed(text); // not `changed`: Delphi 10.3 reads the call as the variable
    if newText <> text then
      aFormula.XmlValue := EncodeText(newText);
  end;

  procedure WriteName(aRow, aColumn: integer; const aName: string);
  begin
    fStore.PutText(aRow, aColumn, aName, True);
  end;

  procedure Remove(const aRelationship: TRelationshipOoxml);
  begin
    if sheet.IsPresent('TableParts') then
    begin
      var parts: TTablePartCTList := sheet.TableParts.TablePart;
      for var i := parts.Count - 1 downto 0 do
        if parts[i].Id = aRelationship.Id then
          parts.Delete(i);
      if parts.Count = 0 then
        sheet.Clear('TableParts')
      else
        sheet.TableParts.Count := parts.Count;
    end;
    fBook.Package.RemovePart(fStore.Part, aRelationship.Part);
  end;

begin
  sheet := fStore.Objects(True);
  last := fMap.First - fMap.Delta - 1;
  var package: TPackageOoxml := fBook.Package;
  for var relationship: TRelationshipOoxml in package.Relationships(fStore.Part) do
  begin
    if not relationship.&Type.EndsWith(cTable) then
      Continue;
    var table: TTableE := package.EditPart<TTableE>(relationship.Part);
    var old: TArea;
    if not TArea.TryParse(table.Ref, old) then
      Continue;
    var area: TArea := old;
    if not fMap.MovedArea(area) then
    begin
      Remove(relationship);
      Continue;
    end;
    var columns: TTableColumnCTList := table.TableColumns.TableColumn;
    var added: TArray<integer> := nil; // the new columns' numbers on the sheet
    if not fMap.ByRows and (fMap.Delta < 0) then
    begin
      for var index := columns.Count - 1 downto 0 do
        if (old.Left + index >= fMap.First) and (old.Left + index <= last) then
          columns.Delete(index);
    end
    else if not fMap.ByRows and (fMap.First > old.Left) and (fMap.First <= old.Right) then
    begin // Excel's names: the first ColumnN the table does not have
      var id: cardinal := 0;
      var names: TStringList := TStringList.Create;
      try
        names.CaseSensitive := False;
        for var column: TTableColumnCT in columns do
        begin
          id := Max(id, column.Id);
          names.Add(column.Name);
        end;
        var number: integer := 1;
        for var index := 0 to fMap.Delta - 1 do
        begin
          while names.IndexOf('Column' + IntToStr(number)) >= 0 do
            Inc(number);
          var column: TTableColumnCT := TTableColumnCT.Create;
          Inc(id);
          column.Id := id;
          column.Name := 'Column' + IntToStr(number);
          names.Add(column.Name);
          columns.Insert(fMap.First - old.Left + index, column);
          added := added + [fMap.First + index];
        end;
      finally
        names.Free;
      end;
    end;
    table.TableColumns.Count := columns.Count;
    if fMap.ByRows and (fMap.Delta < 0) and (table.TotalsRowCount > 0) and (old.Bottom >= fMap.First) and (old.Bottom <= last) then
    begin // the table keeps no totals row then
      table.Clear(@table.TotalsRowCount);
      table.TotalsRowShown := False;
      table.SetPresent(@table.TotalsRowShown);
      for var column: TTableColumnCT in columns do
      begin
        column.Clear(@column.TotalsRowFunction);
        column.Clear(@column.TotalsRowLabel);
        column.Clear('TotalsRowFormula');
      end;
    end;
    for var column: TTableColumnCT in columns do
    begin
      if column.IsPresent('CalculatedColumnFormula') then
        ChangeFormula(column.CalculatedColumnFormula);
      if column.IsPresent('TotalsRowFormula') then
        ChangeFormula(column.TotalsRowFormula);
    end;
    table.Ref := area.CellsAddress;
    var dataTop: integer := area.Top + integer(table.HeaderRowCount);
    var dataBottom: integer := area.Bottom - integer(table.TotalsRowCount);
    if table.HeaderRowCount > 0 then
      for var column: integer in added do
        WriteName(area.Top, column, columns[column - area.Left].Name);
    if fMap.ByRows and (fMap.Delta > 0) and (fMap.First > old.Top) and (fMap.First <= old.Bottom) then
      for var index := 0 to columns.Count - 1 do
        if columns[index].IsPresent('CalculatedColumnFormula') and not columns[index].CalculatedColumnFormula.&Array then
        begin
          var text: string := DecodeText(columns[index].CalculatedColumnFormula.XmlValue);
          for var row := Max(fMap.First, dataTop) to Min(fMap.First + fMap.Delta - 1, dataBottom) do
          begin
            var filled, why: string;
            if ShiftFormula(text, TReferenceMap.Fill(row - dataTop, 0), filled, why) then
              fStore.PutFormula(row, area.Left + index, filled);
          end;
        end;
    if table.IsPresent('AutoFilter') then
    begin
      var filter: TAutoFilterCT := table.AutoFilter;
      var shown: TArea := area;
      shown.Bottom := dataBottom;
      filter.Ref := shown.CellsAddress;
      if not fMap.ByRows and ShiftFilterColumns(filter, old.Left, area.Left, fMap) then
        ShowRows(dataTop, dataBottom);
    end;
    if table.IsPresent('SortState') then
    begin
      var sort: TSortStateCT := table.SortState;
      var ref: string := fMap.MovedSqref(sort.Ref);
      if ref <> '' then
      begin
        sort.Ref := ref;
        for var i := sort.SortCondition.Count - 1 downto 0 do
        begin
          var condition: string := fMap.MovedSqref(sort.SortCondition[i].Ref);
          if condition = '' then
            sort.SortCondition.Delete(i)
          else
            sort.SortCondition[i].Ref := condition;
        end;
      end;
      if (ref = '') or (sort.SortCondition.Count = 0) then
        table.Clear('SortState');
    end;
  end;
end;

// the tables moved, then the data rows a delete kept emptied
procedure TTablesHandler.Apply;
begin
  for var kept: TKeptFormula in fKept do
  begin
    fBook.Package.EditPart<TTableE>(kept.Part);
    kept.Formula.XmlValue := EncodeText(kept.Text);
  end;
  if fMap.Count <> 0 then
    ShiftTables;
  for var area: TArea in fCleared do
    for var row: TRowCT in fStore.RowEntries(area.Top, area.Bottom) do
      for var cell: TCellCT in row.C do
        if (TUtility.ColumnOf(cell.R) >= area.Left) and (TUtility.ColumnOf(cell.R) <= area.Right) then
          fStore.RemoveValue(cell);
end;

// pivot tables on the sheet moved (gone when deleted whole) and the caches' sources on it grown or shrunk, as Excel does;
// a source deleted whole keeps its ref, as in Excel
procedure TPivotsHandler.Apply;
begin
  if fMap.Change = TReferenceChange.rcSheetDelete then
  begin
    DropCaches;
    Exit;
  end;
  var package: TPackageOoxml := fBook.Package;
  for var relationship: TRelationshipOoxml in package.Relationships(fStore.Part) do
    if relationship.&Type.EndsWith(cPivotTable) then
    begin
      var pivot: TPivotTableDefinitionE := package.Part<TPivotTableDefinitionE>(relationship.Part);
      var area: TArea;
      if (pivot = nil) or not TArea.TryParse(pivot.Location.Ref, area) then
        Continue;
      var whole: TArea := area;
      if pivot.Location.RowPageCount > 0 then // the page fields and a blank row
        whole.Top := Max(1, area.Top - integer(pivot.Location.RowPageCount) - 1);
      if not fMap.MovedArea(whole) then
      begin
        var folder: integer := relationship.Part.LastIndexOf('/') + 1;
        package.RemovePart(relationship.Part, relationship.Part.Substring(0, folder) + '_rels/' +
          relationship.Part.Substring(folder) + '.rels');
        package.RemovePart(fStore.Part, relationship.Part);
      end
      else if fMap.MovedArea(area) then
        package.EditPart<TPivotTableDefinitionE>(relationship.Part).Location.Ref := area.CellsAddress;
    end;
  for var relationship: TRelationshipOoxml in package.Relationships(fBook.WorkbookPart) do
    if relationship.&Type.EndsWith(cPivotCacheDefinition) then
    begin
      var cache: TPivotCacheDefinitionE := package.Part<TPivotCacheDefinitionE>(relationship.Part);
      if not cache.CacheSource.IsPresent('WorksheetSource') then
        Continue;
      var source: TWorksheetSourceCT := cache.CacheSource.WorksheetSource;
      if (source.Name <> '') or (source.Ref = '') or not AnsiSameText(source.Sheet, fName) or source.Present[@source.Id] then
        Continue;
      var ref: string := fMap.MovedSqref(source.Ref);
      if (ref <> '') and (ref <> source.Ref) then
        package.EditPart<TPivotCacheDefinitionE>(relationship.Part).CacheSource.WorksheetSource.Ref := ref;
    end;
end;

constructor TDrawingsHandler.Create(aWalk: TXlsxWalk);
begin
  inherited;
  fMoves := TList<TAnchorMove>.Create;
end;

destructor TDrawingsHandler.Destroy;
begin
  fMoves.Free;
  inherited;
end;

// the drawings' objects and where they start and end along the shifted axis before the change (fMoves); why for a
// drawing that does not read
function TDrawingsHandler.Plan: string;
begin
  Result := '';
  var package: TPackageOoxml := fBook.Package;
  var axis: TAxis := nil;
  try
    for var relationship: TRelationshipOoxml in package.Relationships(fStore.Part) do
      if relationship.&Type.EndsWith(cDrawing) then
      begin
        var drawing: TWsDrE := package.Part<TWsDrE>(relationship.Part);
        if drawing = nil then
        begin
          Result := Format('a drawing that does not read (%s)', [relationship.Part]);
          Exit;
        end;
        if axis = nil then
          axis := TAxis.Create(fSheet, fMap.ByRows);
        for var anchor: TTwoCellAnchorCT in drawing.TwoCellAnchor do
        begin
          var move: TAnchorMove := Default(TAnchorMove);
          move.Part := relationship.Part;
          move.Anchor := anchor;
          var fromIndex, toIndex: integer;
          var fromOffset, toOffset: Int64;
          if not MarkerPlace(anchor.From, fMap.ByRows, fromIndex, fromOffset) or
            not MarkerPlace(anchor.&To, fMap.ByRows, toIndex, toOffset) then
          begin
            Result := Format('a drawing''s object whose place does not read (%s)', [relationship.Part]);
            Exit;
          end;
          move.From := axis.Start(fromIndex) + fromOffset;
          move.&To := axis.Start(toIndex) + toOffset;
          fMoves.Add(move);
        end;
        for var anchor: TOneCellAnchorCT in drawing.OneCellAnchor do
        begin
          var move: TAnchorMove := Default(TAnchorMove);
          move.Part := relationship.Part;
          move.Anchor := anchor;
          var index: integer;
          var offset: Int64;
          if not MarkerPlace(anchor.From, fMap.ByRows, index, offset) then
          begin
            Result := Format('a drawing''s object whose place does not read (%s)', [relationship.Part]);
            Exit;
          end;
          fMoves.Add(move);
        end;
      end;
  finally
    axis.Free;
  end;
end;

// the drawings' objects as Excel moves them: move and size with cells (twoCell) - each end with its cell, gone when its
// rows or columns are deleted whole; move only (oneCell) - its start with its cell, its size kept; free (absolute) -
// where it was; xdr:oneCellAnchor's start with its cell
procedure TDrawingsHandler.Apply;
var
  last, limit: integer;
  axis: TAxis;

  // a marker with its cell: one deleted goes to the start of what follows (its offset as written otherwise)
  procedure MoveMarker(aMarker: TMarkerCT);
  begin
    var index: integer;
    var offset: Int64;
    MarkerPlace(aMarker, fMap.ByRows, index, offset);
    var moved: integer := fMap.MovedIndex(index + 1);
    if (moved = 0) and (fMap.Delta < 0) then
      PlaceMarker(aMarker, fMap.ByRows, fMap.First - 1, 0)
    else if fMap.ByRows then
      aMarker.Row := IfThen(moved = 0, limit, moved) - 1
    else
      aMarker.Col := IfThen(moved = 0, limit, moved) - 1;
  end;

  // a marker at a distance from the sheet's top or left
  procedure Place(aMarker: TMarkerCT; aPosition: Int64);
  begin
    var index: integer;
    var offset: Int64;
    axis.Find(aPosition, index, offset);
    PlaceMarker(aMarker, fMap.ByRows, index, offset);
  end;

  // the marker's row or column among the deleted ones (an end: at the start of the one after them too)
  function Deleted(aMarker: TMarkerCT; aEnd: boolean): boolean;
  begin
    var index: integer;
    var offset: Int64;
    MarkerPlace(aMarker, fMap.ByRows, index, offset);
    Inc(index);
    Result := (fMap.Delta < 0) and ((index >= fMap.First) and (index <= last) or aEnd and (index = last + 1) and (offset = 0));
  end;

begin
  if fMoves.Count = 0 then
    Exit;
  last := fMap.First - fMap.Delta - 1;
  limit := fMap.Limit;
  var package: TPackageOoxml := fBook.Package;
  axis := TAxis.Create(fSheet, fMap.ByRows);
  try
    for var move: TAnchorMove in fMoves do
    begin
      var drawing: TWsDrE := package.EditPart<TWsDrE>(move.Part);
      if move.Anchor is TOneCellAnchorCT then
      begin
        MoveMarker(TOneCellAnchorCT(move.Anchor).From);
        Continue;
      end;
      var anchor: TTwoCellAnchorCT := TTwoCellAnchorCT(move.Anchor);
      case anchor.EditAs of
        steaTwoCell:
          if Deleted(anchor.From, False) and Deleted(anchor.&To, True) then
            drawing.TwoCellAnchor.Remove(anchor)
          else
          begin
            MoveMarker(anchor.From);
            MoveMarker(anchor.&To);
          end;
        steaOneCell:
          begin
            MoveMarker(anchor.From);
            var index: integer;
            var offset: Int64;
            MarkerPlace(anchor.From, fMap.ByRows, index, offset);
            Place(anchor.&To, axis.Start(index) + offset + move.&To - move.From);
          end;
        steaAbsolute:
          begin
            Place(anchor.From, move.From);
            Place(anchor.&To, move.&To);
          end;
      end;
    end;
  finally
    axis.Free;
  end;
end;

type
  // a cell a chart's reference names: its cached points are its cells in order
  TChartCell = record
    Sheet: string;
    Row, Column: integer;
  end;

// the cells of a chart's reference, a range or a bracketed list of them, in order: False for what is not single rows or
// columns of cells (a name, a 2-D area, #REF!, too many cells)
function ChartCells(const aText: string; out aCells: TArray<TChartCell>): boolean;
const
  cMostCells = 65536;
begin
  aCells := nil;
  var text: string := aText.Trim;
  if text.StartsWith('(') and text.EndsWith(')') then
    text := text.Substring(1, text.Length - 2);
  var parts: TArray<string> := [];
  var quoted: boolean := False;
  var start: integer := 0;
  for var i := 0 to text.Length - 1 do
    if text.Chars[i] = '''' then
      quoted := not quoted
    else if (text.Chars[i] = ',') and not quoted then
    begin
      parts := parts + [text.Substring(start, i - start)];
      start := i + 1;
    end;
  parts := parts + [text.Substring(start)];
  var cells: TList<TChartCell> := TList<TChartCell>.Create;
  try
    for var part: string in parts do
    begin
      var bang: integer := part.LastIndexOf('!');
      if bang < 0 then
        Exit(False);
      var cell: TChartCell := Default(TChartCell);
      cell.Sheet := part.Substring(0, bang).Trim;
      if (cell.Sheet.Length >= 2) and cell.Sheet.StartsWith('''') and cell.Sheet.EndsWith('''') then
        cell.Sheet := cell.Sheet.Substring(1, cell.Sheet.Length - 2).Replace('''''', '''');
      var at: TArea;
      if not TArea.TryParse(part.Substring(bang + 1), at) or (at.Top <> at.Bottom) and (at.Left <> at.Right) or
        (cells.Count + (at.Bottom - at.Top + 1) * (at.Right - at.Left + 1) > cMostCells) then
        Exit(False);
      for var row := at.Top to at.Bottom do
        for var column := at.Left to at.Right do
        begin
          cell.Row := row;
          cell.Column := column;
          cells.Add(cell);
        end;
    end;
    aCells := cells.ToArray;
    Result := True;
  finally
    cells.Free;
  end;
end;

// where each cached point of a chart's reference goes when its text changes from aBefore to aAfter through rows or columns
// of aSheet inserted or deleted: its index then (-1: its cell deleted), aTotal the new reference's cells - as Excel reads
// them again; False when either text does not list single rows or columns
function ChartPoints(const aBefore, aAfter, aSheet: string; const aMap: TReferenceMap;
  out aIndexes: TArray<integer>; out aTotal: integer): boolean;

  function Key(const aCell: TChartCell): string;
  begin
    Result := Format('%s!%d,%d', [aCell.Sheet, aCell.Row, aCell.Column]);
  end;

begin
  aIndexes := nil;
  aTotal := 0;
  var before, after: TArray<TChartCell>;
  Result := ChartCells(aBefore, before) and ChartCells(aAfter, after);
  if not Result then
    Exit;
  var places: TDictionary<string, integer> := TDictionary<string, integer>.Create(TIStringComparer.Ordinal);
  try
    for var i := 0 to High(after) do
      places.AddOrSetValue(Key(after[i]), i);
    SetLength(aIndexes, Length(before));
    for var i := 0 to High(before) do
    begin
      var cell: TChartCell := before[i];
      if AnsiSameText(cell.Sheet, aSheet) then
        if aMap.ByRows then
          cell.Row := aMap.MovedIndex(cell.Row)
        else
          cell.Column := aMap.MovedIndex(cell.Column);
      if (cell.Row = 0) or (cell.Column = 0) or not places.TryGetValue(Key(cell), aIndexes[i]) then
        aIndexes[i] := -1;
    end;
    aTotal := Length(after);
  finally
    places.Free;
  end;
end;

procedure MoveNumPoints(aData: TNumDataCT; const aIndexes: TArray<integer>; aTotal: integer);
begin
  for var i := aData.Pt.Count - 1 downto 0 do
  begin
    var point: TNumValCT := aData.Pt[i];
    if (point.Idx < cardinal(Length(aIndexes))) and (aIndexes[point.Idx] >= 0) then
      point.Idx := aIndexes[point.Idx]
    else
      aData.Pt.Remove(point);
  end;
  aData.PtCount.Val := aTotal;
end;

procedure MoveStrPoints(aData: TStrDataCT; const aIndexes: TArray<integer>; aTotal: integer);
begin
  for var i := aData.Pt.Count - 1 downto 0 do
  begin
    var point: TStrValCT := aData.Pt[i];
    if (point.Idx < cardinal(Length(aIndexes))) and (aIndexes[point.Idx] >= 0) then
      point.Idx := aIndexes[point.Idx]
    else
      aData.Pt.Remove(point);
  end;
  aData.PtCount.Val := aTotal;
end;

// a chart's objects that name cells: numRef, strRef and multiLvlStrRef (their c:f), and extensions, whose elements kept as
// read may name cells too (c15's data labels range, filtered series)
procedure ChartReferences(aObject: TBasite; aFound: TList<TXmlite>; aSeen: TDictionary<TBasite, boolean>);
begin
  if aSeen.ContainsKey(aObject) then
    Exit;
  aSeen.Add(aObject, True);
  if (aObject is TNumRefCT) or (aObject is TStrRefCT) or (aObject is TMultiLvlStrRefCT) or (aObject is TExtensionCT) then
    aFound.Add(TXmlite(aObject));
  for var element: TProperty in aObject.Meta.Xmlite.Elements.Values do
    case element.PropertyType of
      TPropertyType.ptBasite:
        begin
          var child: TBasite := TPropertyBasite(element).ObjectPointer(aObject)^;
          if child <> nil then
            ChartReferences(child, aFound, aSeen);
        end;
      TPropertyType.ptBasiteList:
        begin
          var list: TBasiteList := TPropertyBasiteList(element).ObjectPointer(aObject)^;
          if list <> nil then
            for var child: TBasite in list do
              ChartReferences(child, aFound, aSeen);
        end;
    end;
  if aObject.Meta.Xmlite.IsTXmlite then
    for var child: TBasite in TXmlite(aObject).XmlAny do
      ChartReferences(child, aFound, aSeen);
end;

function ChartFormula(aReference: TXmlite): string;
begin
  if aReference is TNumRefCT then
    Result := TNumRefCT(aReference).F
  else if aReference is TStrRefCT then
    Result := TStrRefCT(aReference).F
  else
    Result := TMultiLvlStrRefCT(aReference).F;
end;

// the charts of every sheet's and chart sheet's drawings (but a deleted sheet's), in aCharts: why one cannot move, '' else
function TChartsHandler.ChartParts(aCharts: TList<string>): string;
begin
  Result := '';
  var package: TPackageOoxml := fBook.Package;
  var owners: TList<string> := TList<string>.Create;
  var drawings: TList<string> := TList<string>.Create;
  try
    for var sheet: TXlsxWalkSheet in fWalk.Sheets do
      if (sheet <> fSheet) or (fMap.Change <> TReferenceChange.rcSheetDelete) then
        owners.Add(sheet.Store.Part);
    for var relationship: TRelationshipOoxml in package.Relationships(fBook.WorkbookPart) do
      if relationship.&Type.EndsWith(cChartsheet) and (relationship.Part <> '') then
        owners.Add(relationship.Part);
    for var owner: string in owners do
      for var relationship: TRelationshipOoxml in package.Relationships(owner) do
        if relationship.&Type.EndsWith(cDrawing) and (relationship.Part <> '') and not drawings.Contains(relationship.Part) then
          drawings.Add(relationship.Part);
    for var drawing: string in drawings do
      for var relationship: TRelationshipOoxml in package.Relationships(drawing) do
        if relationship.&Type.EndsWith(cChartEx) then
          Exit('charts of Excel 2016''s kinds (chartEx), which Calcite does not move yet')
        else if relationship.&Type.EndsWith(cChart) and (relationship.Part <> '') and not aCharts.Contains(relationship.Part) then
          aCharts.Add(relationship.Part);
  finally
    drawings.Free;
    owners.Free;
  end;
end;

// one chart's references through the map, those that change in fMoves: why it, or a reference naming the sheet, does not
// read; '' else
function TChartsHandler.PlanChart(const aPart: string; aFound: TList<TXmlite>; aSeen: TDictionary<TBasite, boolean>): string;
begin
  var chart: TChartSpaceE := fBook.Package.Part<TChartSpaceE>(aPart);
  if chart = nil then
    Exit(Format('a chart that does not read (%s)', [aPart]));
  aFound.Clear;
  aSeen.Clear;
  ChartReferences(chart, aFound, aSeen);
  for var reference: TXmlite in aFound do
  begin
    var move: TChartMove := Default(TChartMove);
    move.Part := aPart;
    move.Reference := reference;
    move.Index := -1;
    var why: string := '';
    if reference is TExtensionCT then
    begin
      for var index := 0 to reference.XmlUnknown.Count - 1 do
      begin
        move.Before := reference.XmlUnknown[index].Xml;
        move.Index := index;
        if not MappedKeptXml(move.Before, fName, fMap, move.After, why) then
          Exit(Format('a formula of the chart %s does not read: %s', [aPart, why]));
        if move.After <> move.Before then
          fMoves.Add(move);
      end;
      Continue;
    end;
    move.Before := ChartFormula(reference);
    if not ShiftFormula(move.Before, fMap, move.After, why) then
    begin
      if ContainsText(move.Before, fName) then
        Exit(Format('the formula %s of the chart %s does not read: %s', [move.Before, aPart, why]));
      Continue;
    end;
    if move.After <> move.Before then
      fMoves.Add(move);
  end;
  Result := '';
end;

function TChartsHandler.Plan: string;
begin
  var charts: TList<string> := TList<string>.Create;
  var found: TList<TXmlite> := TList<TXmlite>.Create;
  var seen: TDictionary<TBasite, boolean> := TDictionary<TBasite, boolean>.Create;
  try
    Result := ChartParts(charts);
    for var part: string in charts do
      if Result = '' then
        Result := PlanChart(part, found, seen);
  finally
    seen.Free;
    found.Free;
    charts.Free;
  end;
end;

// the planned chart references written; their cached points follow their cells
procedure TChartsHandler.Apply;
begin
  var package: TPackageOoxml := fBook.Package;
  for var move: TChartMove in fMoves do
  begin
    package.EditPart<TChartSpaceE>(move.Part);
    if move.Index >= 0 then
    begin
      var kept: TXmliteUnknown := move.Reference.XmlUnknown[move.Index];
      kept.Xml := move.After;
      move.Reference.XmlUnknown[move.Index] := kept;
      Continue;
    end;
    var indexes: TArray<integer>;
    var total: integer;
    var points: boolean := ChartPoints(move.Before, move.After, fName, fMap, indexes, total);
    if move.Reference is TNumRefCT then
    begin
      var reference: TNumRefCT := TNumRefCT(move.Reference);
      reference.F := move.After;
      if points and reference.IsPresent('NumCache') then
        MoveNumPoints(reference.NumCache, indexes, total);
    end
    else if move.Reference is TStrRefCT then
    begin
      var reference: TStrRefCT := TStrRefCT(move.Reference);
      reference.F := move.After;
      if points and reference.IsPresent('StrCache') then
        MoveStrPoints(reference.StrCache, indexes, total);
    end
    else // a multi-level cache's levels are its columns or rows: Excel reads it again
      TMultiLvlStrRefCT(move.Reference).F := move.After;
  end;
end;

procedure TChartsHandler.Written(aTo: TStringBuilder);
begin
  for var move: TChartMove in fMoves do
    aTo.Append(move.After).Append(#10);
end;

// the sheet's notes: its comments part and the VML drawing its legacyDrawing names ('' - none)
procedure TNotesHandler.NotesParts(out aComments, aDrawing: string);
begin
  aComments := '';
  aDrawing := '';
  var sheet: TWorksheetE := fStore.Objects(False);
  var id: string := '';
  if sheet.IsPresent('LegacyDrawing') then
    id := sheet.LegacyDrawing.Id;
  for var relationship: TRelationshipOoxml in fBook.Package.Relationships(fStore.Part) do
    if relationship.&Type.EndsWith(cComments) then
      aComments := relationship.Part
    else if (id <> '') and (relationship.Id = id) then
      aDrawing := relationship.Part;
end;

// a VML note's cell (from 1); False for a shape that is no note
function NoteCell(aItem: TBasite; out aRow, aColumn: integer): boolean;
begin
  Result := False;
  if not (aItem is TShapeE) or (TShapeE(aItem).ClientData.Count <> 1) then
    Exit;
  var data: TClientDataE := TShapeE(aItem).ClientData[0];
  if (data.ObjectType <> stotNote) or (data.Row.Count <> 1) or (data.Column.Count <> 1) or (data.Anchor.Count <> 1) then
    Exit;
  var anchor: string := data.Anchor[0];
  if Length(anchor.Split([','])) <> 8 then
    Exit;
  aRow := data.Row[0] + 1;
  aColumn := data.Column[0] + 1;
  Result := True;
end;

// why the sheet's notes do not move: threaded comments, a VML drawing with more than notes (Forms controls) or one that does
// not read, a note pushed off the sheet; '' when nothing stands in the way
function TNotesHandler.Plan: string;
const
  cPushedOff = 'Microsoft Excel can''t insert new cells because it would push non-empty cells off the end of the ' +
    'worksheet. These non-empty cells might appear empty but have blank values, some formatting, or a formula. Delete ' +
    'enough rows or columns to make room for what you want to insert and then try again.';
begin
  Result := '';
  var package: TPackageOoxml := fBook.Package;
  for var relationship: TRelationshipOoxml in package.Relationships(fStore.Part) do
    if relationship.&Type.EndsWith(cThreadedComment) then
      Exit('threaded comments, which Calcite does not move yet');
  var commentsPart, drawingPart: string;
  NotesParts(commentsPart, drawingPart);
  var limit: integer := fMap.Limit;
  if commentsPart <> '' then
  begin
    var comments: TCommentsE := package.Part<TCommentsE>(commentsPart);
    if comments = nil then
      Exit(Format('notes that do not read (%s)', [commentsPart]));
    if fMap.Delta > 0 then
      for var comment: TCommentCT in comments.CommentList.Comment do
      begin
        var at: TArea;
        if TArea.TryParse(comment.Ref, at) and (IfThen(fMap.ByRows, at.Top, at.Left) > limit - fMap.Delta) then
          Exit(cPushedOff);
      end;
  end;
  if drawingPart = '' then
    Exit;
  var drawing: TVmlDrawing := package.Part<TVmlDrawing>(drawingPart);
  if (drawing = nil) or (drawing.XmlUnknown.Count > 0) then
    Exit(Format('notes whose drawing does not read (%s)', [drawingPart]));
  for var item: TBasite in drawing.XmlAny do
  begin
    var row, column: integer;
    if not (item is TShapelayoutE) and not (item is TShapetypeE) and not NoteCell(item, row, column) then
      Exit('shapes other than notes in the sheet''s VML drawing (Forms controls), which Calcite does not move yet');
  end;
end;

// a CSS length as Excel writes a VML box's: whole inches in in, else points
function VmlLength(aEmus: Int64): string;
const
  cInch = 914400;
  cPoint = 12700;
begin
  if (aEmus <> 0) and (aEmus mod cInch = 0) then
    Result := IntToStr(aEmus div cInch) + 'in'
  else
    Result := TUtility.FloatText(aEmus / cPoint, ftDouble) + 'pt';
end;

// the notes as Excel moves them: each box by as many rows or columns as its cell moved (never above the first; its offsets
// kept, its place and size on the axis computed again), gone with its cell; the last one gone, its parts go too. A part is
// edited only when it changes: one that did not read back exactly still saves
procedure TNotesHandler.Apply;
const
  cPixel = 9525;
var
  anchor: array[0 .. 7] of integer; // not an inline var: Delphi 10.3 takes no structured type there
begin
  var commentsPart, drawingPart: string;
  NotesParts(commentsPart, drawingPart);
  if (commentsPart = '') and (drawingPart = '') then
    Exit;
  var package: TPackageOoxml := fBook.Package;
  var notesLeft: boolean := False;
  if commentsPart <> '' then
  begin
    var comments: TCommentsE := package.Part<TCommentsE>(commentsPart);
    var edited: boolean := False;
    for var i := comments.CommentList.Comment.Count - 1 downto 0 do
    begin
      var comment: TCommentCT := comments.CommentList.Comment[i];
      var at: TArea;
      if not TArea.TryParse(comment.Ref, at) then
        Continue;
      var index: integer := IfThen(fMap.ByRows, at.Top, at.Left);
      var moved: integer := fMap.MovedIndex(index);
      if moved = index then
        Continue;
      if not edited then
        package.EditPart<TCommentsE>(commentsPart);
      edited := True;
      if moved = 0 then
        comments.CommentList.Comment.Remove(comment)
      else if fMap.ByRows then
        comment.Ref := TUtility.CellName(moved, at.Left)
      else
        comment.Ref := TUtility.CellName(at.Top, moved);
    end;
    notesLeft := comments.CommentList.Comment.Count > 0;
  end;
  if drawingPart <> '' then
  begin
    var drawing: TVmlDrawing := package.Part<TVmlDrawing>(drawingPart);
    var axis: TAxis := TAxis.Create(fSheet, fMap.ByRows);
    try
      var edited, removed: boolean;
      edited := False;
      removed := False;
      var shapes: integer := 0;
      for var i := drawing.XmlAny.Count - 1 downto 0 do
      begin
        var row, column: integer;
        if not NoteCell(drawing.XmlAny[i], row, column) then
          Continue;
        var shape: TShapeE := TShapeE(drawing.XmlAny[i]);
        var data: TClientDataE := shape.ClientData[0];
        // LeftColumn, LeftOffset, TopRow, TopOffset, RightColumn, RightOffset, BottomRow, BottomOffset (pixels)
        var text: string := string(data.Anchor[0]);
        var numbers: TArray<string> := text.Split([',']);
        for var k := 0 to 7 do
          anchor[k] := StrToIntDef(numbers[k].Trim, 0);
        var first: integer := IfThen(fMap.ByRows, 2, 0); // the start's index; its offset next, the end's 4 on
        var index: integer := IfThen(fMap.ByRows, row, column);
        var moved: integer := fMap.MovedIndex(index);
        if moved <> 0 then
          Inc(shapes);
        if (moved = index) and (anchor[first + 4] < fMap.First - 1) then
          Continue; // all before the change: as it was
        if not edited then
          package.EditPart<TVmlDrawing>(drawingPart);
        edited := True;
        if moved = 0 then
        begin
          drawing.XmlAny.Remove(shape);
          removed := True;
          Continue;
        end;
        if fMap.ByRows then
          data.Row[0] := moved - 1
        else
          data.Column[0] := moved - 1;
        var by: integer := Max(moved - index, -anchor[first]); // never above the first row or column
        Inc(anchor[first], by);
        Inc(anchor[first + 4], by);
        var spaces: string := text.Substring(0, text.Length - text.TrimLeft.Length);
        text := spaces + IntToStr(anchor[0]);
        for var k := 1 to 7 do
          text := text + ', ' + IntToStr(anchor[k]);
        data.Anchor[0] := text;
        var boxStart: Int64 := axis.Start(anchor[first]) +
          Min(Int64(anchor[first + 1]) * cPixel, axis.Start(anchor[first] + 1) - axis.Start(anchor[first]));
        var boxEnd: Int64 := axis.Start(anchor[first + 4]) +
          Min(Int64(anchor[first + 5]) * cPixel, axis.Start(anchor[first + 4] + 1) - axis.Start(anchor[first + 4]));
        var place: string := 'margin-left';
        var size: string := 'width';
        if fMap.ByRows then
        begin
          place := 'margin-top';
          size := 'height';
        end;
        var style: string := shape.Style;
        var items: TArray<string> := style.Split([';']);
        for var k := 0 to High(items) do
        begin
          var name: string := items[k].Split([':'])[0].Trim;
          var lead: string := items[k].Substring(0, items[k].Length - items[k].TrimLeft.Length);
          if name = place then
            items[k] := lead + name + ':' + VmlLength(boxStart)
          else if name = size then
            items[k] := lead + name + ':' + VmlLength(Max(boxEnd - boxStart, 0));
        end;
        shape.Style := string.Join(';', items);
      end;
      if removed then // Excel numbers the boxes left from 1
      begin
        var z: integer := 0;
        for var item: TBasite in drawing.XmlAny do
          if item is TShapeE then
          begin
            Inc(z);
            var style: string := TShapeE(item).Style;
            var items: TArray<string> := style.Split([';']);
            for var k := 0 to High(items) do
              if items[k].Split([':'])[0].Trim = 'z-index' then
                items[k] := items[k].Substring(0, items[k].Length - items[k].TrimLeft.Length) + 'z-index:' + IntToStr(z);
            TShapeE(item).Style := string.Join(';', items);
          end;
      end;
      notesLeft := notesLeft or (shapes > 0);
    finally
      axis.Free;
    end;
  end;
  if notesLeft then
    Exit;
  if commentsPart <> '' then
    package.RemovePart(fStore.Part, commentsPart);
  if drawingPart <> '' then
  begin
    package.RemovePart(fStore.Part, drawingPart);
    fStore.Objects(True).Clear('LegacyDrawing');
  end;
end;

constructor TChartsHandler.Create(aWalk: TXlsxWalk);
begin
  inherited;
  fMoves := TList<TChartMove>.Create;
end;

destructor TChartsHandler.Destroy;
begin
  fMoves.Free;
  inherited;
end;

function TRefusedElementsHandler.Plan: string;
begin
  var sheet: TWorksheetE := fStore.Objects(False);
  for var known: TKnownKind in cElements do
    if (known.Why <> '') and sheet.IsPresent(known.Name) then
      Exit(known.Why + cNotYet);
  Result := '';
end;

function TPartsHandler.Plan: string;
begin
  Result := '';
  var package: TPackageOoxml := fBook.Package;
  var parts: TList<string> := TList<string>.Create;
  var seen: TDictionary<string, boolean> := TDictionary<string, boolean>.Create;
  try
    parts.Add(fBook.WorkbookPart);
    seen.Add(fBook.WorkbookPart, True);
    var next: integer := 0;
    while next < parts.Count do
    begin
      for var relationship: TRelationshipOoxml in package.Relationships(parts[next]) do
      begin
        var name: string := relationship.&Type.Substring(relationship.&Type.LastIndexOf('/') + 1);
        var known: integer := High(cParts);
        while (known >= 0) and (cParts[known].Name <> name) do
          Dec(known);
        if known < 0 then
          Exit(Format('a part of a kind Calcite does not know (%s)', [relationship.&Type]) + cNotYet);
        if cParts[known].Why <> '' then
          Exit(cParts[known].Why + cNotYet);
        if (relationship.Part <> '') and not seen.ContainsKey(relationship.Part) then
        begin
          seen.Add(relationship.Part, True);
          parts.Add(relationship.Part);
        end;
      end;
      Inc(next);
    end;
  finally
    seen.Free;
    parts.Free;
  end;
end;

function TXlsxRun.Handler<T>: T;
begin
  for var item: TXlsxHandler in fHandlers do
    if item is T then
      Exit(T(item));
  Result := nil;
end;

function TXlsxRun.Run(aSheet: TXlsxWalkSheet; const aMap: TReferenceMap): string;
begin
  fSheet := aSheet;
  fMap := aMap;
  fHandlers := TObjectList<TXlsxHandler>.Create;
  try
    if aMap.Change = TReferenceChange.rcSheetDelete then
      Result := DeleteSheet
    else
      Result := Shift;
  finally
    FreeAndNil(fHandlers);
  end;
end;

// the tables fill the map, every handler plans in the order of Excel's refusals, then they apply in an order of their own:
// the names, the rules' formulas, the cells, the lists, the cells' formulas, the objects
function TXlsxRun.Shift: string;
begin
  Result := '';
  for var kind: TXlsxHandlerClass in cShift do
    fHandlers.Add(kind.Create(Self));
  var firstList: integer := fHandlers.Count;
  for var kind: TXlsxHandlerClass in cLists do
    fHandlers.Add(kind.Create(Self));
  var cells: TCellsHandler := Handler<TCellsHandler>;
  var pivots: TPivotsHandler := Handler<TPivotsHandler>;
  var tables: TTablesHandler := Handler<TTablesHandler>;
  var notes: TNotesHandler := Handler<TNotesHandler>;
  var drawings: TDrawingsHandler := Handler<TDrawingsHandler>;
  var charts: TChartsHandler := Handler<TChartsHandler>;
  var formulas: TFormulasHandler := Handler<TFormulasHandler>;
  var names: TNamesHandler := Handler<TNamesHandler>;
  tables.Complete(fMap);
  Mapped;
  if fMap.Count <> 0 then
  begin
    Result := Planned;
    if Result <> '' then
      Exit;
    names.Apply;
    formulas.ApplyRules;
    cells.Apply;
    for var index := firstList to fHandlers.Count - 1 do
      fHandlers[index].Apply;
    formulas.Apply;
  end;
  tables.Apply;
  if fMap.Count <> 0 then
  begin
    pivots.Apply;
    drawings.Apply;
    charts.Apply;
    notes.Apply;
  end;
  for var sheet: TXlsxWalkSheet in fSheets do // edited as objects; other sheets' shared formulas may be plain now
    sheet.Store.Forget;
  fBook.ValueChanged;
  fBook.FormulaChanged;
end;

// the sheet's tables fill the map, every handler plans in the order of Excel's refusals (the local names last: they read
// what the others write), then they apply: the names, the formulas, the charts, the tables' and extensions' formulas, the
// caches, the sheet
function TXlsxRun.DeleteSheet: string;
begin
  for var kind: TXlsxHandlerClass in cDeleteSheet do
    fHandlers.Add(kind.Create(Self));
  var deleted: TSheetHandler := Handler<TSheetHandler>;
  var formulas: TFormulasHandler := Handler<TFormulasHandler>;
  var charts: TChartsHandler := Handler<TChartsHandler>;
  var names: TNamesHandler := Handler<TNamesHandler>;
  var extensions: TExtensionsHandler := Handler<TExtensionsHandler>;
  var tables: TTablesHandler := Handler<TTablesHandler>;
  var pivots: TPivotsHandler := Handler<TPivotsHandler>;
  var localNames: TLocalNamesHandler := Handler<TLocalNamesHandler>;
  tables.Complete(fMap);
  Mapped;
  Result := Planned;
  if Result <> '' then
    Exit;
  names.Apply;
  localNames.Apply;
  formulas.ApplyRules;
  formulas.Apply;
  charts.Apply;
  tables.Apply;
  extensions.Apply;
  pivots.Apply;
  deleted.Apply;
  fBook.ValueChanged;
  fBook.FormulaChanged;
  for var sheet: TXlsxWalkSheet in fSheets do
    if sheet <> fSheet then
      sheet.Store.Forget;
end;

function KnownKinds(const aKinds: array of TKnownKind): TArray<TKnownKind>;
begin
  SetLength(Result, Length(aKinds));
  for var i := 0 to High(aKinds) do
    Result[i] := aKinds[i];
end;

class function TXlsxRun.ShiftOrder: TArray<TXlsxHandlerClass>;
begin
  SetLength(Result, Length(cShift) + Length(cLists));
  for var i := 0 to High(cShift) do
    Result[i] := cShift[i];
  for var i := 0 to High(cLists) do
    Result[Length(cShift) + i] := cLists[i];
end;

class function TXlsxRun.Elements: TArray<TKnownKind>;
begin
  Result := KnownKinds(cElements);
end;

class function TXlsxRun.Parts: TArray<TKnownKind>;
begin
  Result := KnownKinds(cParts);
end;

end.
