unit ProRock.Calcite.XlsxWalk;

// the xlsx backend's insert and delete: rows, columns, sheets, and what names them moved as Excel does (internal)

interface

uses System.SysUtils, System.Generics.Collections, ProRock.Xmlite, ProRock.Office.Ooxml,
  ProRock.Xmlite.Schema.Ooxml.Sml, ProRock.Calcite.Utility, ProRock.Calcite.Aspects, ProRock.Calcite.Xlsx,
  ProRock.Calcite.XlsxSheet;

type
  TXlsxWalk = class;

  // a worksheet as the walk sees it: its name, its storage
  TXlsxWalkSheet = class
  private
    fBook: TXlsxBook;
    fName: string;
    fStore: TXlsxSheet;
  public
    constructor Create(aWalk: TXlsxWalk; const aName: string; aStore: TXlsxSheet);
    property Store: TXlsxSheet read fStore;
  end;

  // one kind of what an insert, a delete or a sheet delete moves: Plan finds what stands in the way ('' when nothing does)
  // and keeps its moves, Apply makes them and never refuses
  TXlsxHandler = class
  protected
    fWalk: TXlsxWalk;
    fMap: TReferenceMap; // the walk's, the tables' part filled in
    // the sheet whose rows or columns move, or which is deleted: its book, storage and name
    fSheet: TXlsxWalkSheet;
    fBook: TXlsxBook;
    fStore: TXlsxSheet;
    fName: string;
    procedure ShowRows(aTop, aBottom: integer);
  public
    constructor Create(aWalk: TXlsxWalk); virtual;
    function Plan: string; virtual;
    procedure Apply; virtual;
    // the formulas' texts Apply writes, a line each: a name local to a deleted sheet that one names stays
    procedure Written(aTo: TStringBuilder); virtual;
  end;

  TXlsxHandlerClass = class of TXlsxHandler;

  // the workbook's worksheets in order, for one insert, delete or sheet delete
  TXlsxWalk = class
  protected
    fBook: TXlsxBook;
    fSheets: TObjectList<TXlsxWalkSheet>;
    fSheet: TXlsxWalkSheet; // the one whose rows or columns move, or which is deleted
    fMap: TReferenceMap;
    fHandlers: TObjectList<TXlsxHandler>; // the run's, in the order they plan
    fDropped: TList<string>; // the parts a sheet delete removes with the sheet's (pivot caches)
    fUnknownExtensions: TUnknownExtensions;
    fNotes: TList<string>;
    function Planned: string;
    // the map, the tables' part filled in, to every handler
    procedure Mapped;
  public
    constructor Create(aBook: TXlsxBook);
    destructor Destroy; override;
    // the next worksheet: its name and its storage (borrowed)
    function Add(const aName: string; aStore: TXlsxSheet): TXlsxWalkSheet;
    property Sheets: TObjectList<TXlsxWalkSheet> read fSheets;
    property Dropped: TList<string> read fDropped;
    // what the run does with an extension it does not know on the sheet it changes
    property UnknownExtensions: TUnknownExtensions read fUnknownExtensions write fUnknownExtensions;
    // what the run did that its caller warns of (an extension kept or dropped), once it applied
    property Notes: TList<string> read fNotes;
  end;

  // arrays, spills and data tables in the way, cells pushed off the sheet; then the cells, the rows' and columns' entries,
  // the spills placed again
  TCellsHandler = class(TXlsxHandler)
  private type
    // a dynamic array's spilled value, lifted while rows or columns move: its place from the formula's cell
    TSpillValue = record
      Row, Column: integer;
      Typed: boolean;
      T: TCellTypeST;
      V: string;
    end;
    // a dynamic array through rows or columns moved: its area before, its spilled values
    TSpill = record
      Area: TArea;
      Values: TArray<TSpillValue>;
    end;
  private
    function CopiedRow(aSource: TRowCT; aNumber: integer): TRowCT;
    procedure ShiftColumnEntries;
    procedure ShiftCells;
    function LiftSpills: TArray<TSpill>;
    procedure PlaceSpills(const aSpills: TArray<TSpill>);
    procedure FitAgain;
  public
    function Plan: string; override;
    procedure Apply; override;
  end;

  // every sheet's formulas (a deleted sheet's not): the cells', shared formulas' areas, conditional formats' and
  // validation's (the rules')
  TFormulasHandler = class(TXlsxHandler)
  private type
    // a formula's cell through the change: where it is then, its text before and after (stored)
    TFormulaMove = record
      Cell: TCellCT;
      Row, Column: integer;
      Before, After: string;
    end;
    // a conditional format's formula (Rule, its Index) or data validation's (Validation, 1 or 2) changed the same way
    TTextMove = record
      Sheet: TXlsxWalkSheet;
      Rule: TCfRuleCT;
      Validation: TDataValidationCT;
      Index: integer;
      Text: string;
    end;
  private
    fMoves: TObjectList<TList<TFormulaMove>>; // each sheet's, in the walk's order
    fRefs: TObjectList<TDictionary<cardinal, string>>;
    fRules: TList<TTextMove>;
    function Changed(aSheet: TXlsxWalkSheet; const aMap: TReferenceMap; const aText, aWhere: string;
      out aResult, aWhy: string): boolean;
    function PlanSheet(aSheet: TXlsxWalkSheet; aMoves: TList<TFormulaMove>; aRefs: TDictionary<cardinal, string>): string;
    function PlanRules(aSheet: TXlsxWalkSheet; const aMap: TReferenceMap): string;
    procedure ApplyOne(aSheet: TXlsxWalkSheet; const aMove: TFormulaMove; aShifted: boolean);
    procedure ApplyShared(aSheet: TXlsxWalkSheet; aMoves: TList<TFormulaMove>; aSi: cardinal; aMembers: TList<integer>;
      aRefs: TDictionary<cardinal, string>; aShifted: boolean);
    procedure ApplySheet(aSheet: TXlsxWalkSheet; aMoves: TList<TFormulaMove>; aRefs: TDictionary<cardinal, string>;
      aShifted: boolean);
    procedure FoldSpills(aSheet: TXlsxWalkSheet; aMoves: TList<TFormulaMove>);
  public
    constructor Create(aWalk: TXlsxWalk); override;
    destructor Destroy; override;
    function Plan: string; override;
    // the rules' formulas: before the lists drop the rules gone with their areas
    procedure ApplyRules;
    procedure Apply; override;
    procedure Written(aTo: TStringBuilder); override;
  end;

  // the defined names, print areas and titles too
  TNamesHandler = class(TXlsxHandler)
  private
    fMapped: boolean;
    fChanged: TArray<string>;
  public
    function Plan: string; override;
    procedure Apply; override;
    procedure Written(aTo: TStringBuilder); override;
  end;

  // the sheet's lists by address, one handler each
  TMergesHandler = class(TXlsxHandler)
  public
    procedure Apply; override;
  end;

  TConditionalAreasHandler = class(TXlsxHandler)
  public
    procedure Apply; override;
  end;

  TValidationAreasHandler = class(TXlsxHandler)
  public
    procedure Apply; override;
  end;

  THyperlinksHandler = class(TXlsxHandler)
  public
    procedure Apply; override;
  end;

  TAutoFilterHandler = class(TXlsxHandler)
  public
    procedure Apply; override;
  end;

  TSortHandler = class(TXlsxHandler)
  public
    procedure Apply; override;
  end;

  TIgnoredErrorsHandler = class(TXlsxHandler)
  public
    procedure Apply; override;
  end;

  TProtectedRangesHandler = class(TXlsxHandler)
  public
    procedure Apply; override;
  end;

  TPageBreaksHandler = class(TXlsxHandler)
  public
    procedure Apply; override;
  end;

  TPanesHandler = class(TXlsxHandler)
  public
    procedure Apply; override;
  end;

  TDimensionHandler = class(TXlsxHandler)
  public
    procedure Apply; override;
  end;

  // the extensions (extLst): rows or columns moved, the sheet's - those naming cells refuse, those it does not know are kept
  // or dropped (UnknownExtensions); the other sheets' kept as read (x14 conditional formats, validation, sparklines), their
  // formulas naming the sheet
  TExtensionsHandler = class(TXlsxHandler)
  private type
    // an extension's element kept as read (Index in XmlUnknown), changed
    TKeptMove = record
      Sheet: TXlsxWalkSheet;
      Extension: TXmlite;
      Index: integer;
      Text: string;
    end;
  private
    fMoves: TList<TKeptMove>;
    fUnknown: TList<integer>; // the sheet's extensions it does not know, by index in ExtLst.Ext
    function PlanSheet: string;
    procedure ApplySheet;
  public
    constructor Create(aWalk: TXlsxWalk); override;
    destructor Destroy; override;
    function Plan: string; override;
    procedure Apply; override;
    procedure Written(aTo: TStringBuilder); override;
  end;

  // a sheet deleted, the names local to it: gone, but those another formula names (Data!Total, now [0]!Total), which
  // Excel keeps as the workbook's; those of the sheets after it count one less. It plans last: it reads every handler's
  // Written
  TLocalNamesHandler = class(TXlsxHandler)
  private
    fIndex: integer; // the sheet's in the workbook
    fLifted: TList<integer>;
  public
    constructor Create(aWalk: TXlsxWalk); override;
    destructor Destroy; override;
    function Plan: string; override;
    procedure Apply; override;
  end;

  // a sheet deleted, the sheet itself: slicers and timelines refused; the active tab and the views, its shared strings,
  // its parts (and the walk's dropped ones), its entry
  TSheetHandler = class(TXlsxHandler)
  private
    fIndex: integer; // the sheet's in the workbook
    procedure ShowAnother;
    procedure RemoveParts;
  public
    function Plan: string; override;
    procedure Apply; override;
  end;

// an autofilter's columns through columns inserted or deleted (its first one was aOldLeft, is aLeft): True when the last
// filter went with them - Excel then shows the rows it hid
function ShiftFilterColumns(aFilter: TAutoFilterCT; aOldLeft, aLeft: integer; const aMap: TReferenceMap): boolean;
// an element kept as read with its f and sqref texts (formulas, any prefix) through aMap; False with aWhy when one naming
// aSheet does not read
function MappedKeptXml(const aXml, aSheet: string; const aMap: TReferenceMap; out aResult, aWhy: string): boolean;

implementation

uses System.StrUtils, System.Math, System.RegularExpressions, System.Generics.Defaults, ProRock.Calcite.Formulas,
  ProRock.Xmlite.Schema.Ooxml.DmlChart;

type
  {$REGION 'ProRock.Xmlite.Schema.Ooxml types aliases'}
  // DrawingML's charts have one of this name too
  TExtensionCT = ProRock.Xmlite.Schema.Ooxml.DmlChart.TExtensionCT;
  {$ENDREGION}

constructor TXlsxWalk.Create(aBook: TXlsxBook);
begin
  inherited Create;
  fBook := aBook;
  fSheets := TObjectList<TXlsxWalkSheet>.Create;
  fDropped := TList<string>.Create;
  fNotes := TList<string>.Create;
end;

destructor TXlsxWalk.Destroy;
begin
  fNotes.Free;
  fDropped.Free;
  fSheets.Free;
  inherited;
end;

function TXlsxWalk.Add(const aName: string; aStore: TXlsxSheet): TXlsxWalkSheet;
begin
  Result := TXlsxWalkSheet.Create(Self, aName, aStore);
  fSheets.Add(Result);
end;

constructor TXlsxWalkSheet.Create(aWalk: TXlsxWalk; const aName: string; aStore: TXlsxSheet);
begin
  inherited Create;
  fBook := aWalk.fBook;
  fName := aName;
  fStore := aStore;
end;

constructor TXlsxHandler.Create(aWalk: TXlsxWalk);
begin
  inherited Create;
  fWalk := aWalk;
  fSheet := aWalk.fSheet;
  fBook := fSheet.fBook;
  fStore := fSheet.fStore;
  fName := fSheet.fName;
end;

function TXlsxHandler.Plan: string;
begin
  Result := '';
end;

procedure TXlsxHandler.Apply;
begin
end;

procedure TXlsxHandler.Written(aTo: TStringBuilder);
begin
end;

procedure TXlsxHandler.ShowRows(aTop, aBottom: integer);
begin
  for var row: TRowCT in fStore.RowEntries(aTop, aBottom) do
    row.Clear(@row.Hidden);
end;

// why Excel or Calcite does not move the cells so: arrays, spills, data tables, cells pushed off; '' when nothing does
function TCellsHandler.Plan: string;
const
  cLater = ', which Calcite does not move yet';
  cNotYet = ', which Calcite does not do yet';
  cPushedOff = 'Microsoft Excel can''t insert new cells because it would push non-empty cells off the end of the ' +
    'worksheet. These non-empty cells might appear empty but have blank values, some formatting, or a formula. Delete ' +
    'enough rows or columns to make room for what you want to insert and then try again.';

  function IsSpill(const aArea: TArea): boolean;
  begin
    for var spill: TArea in fStore.Areas(akSpill) do
      if (spill.Top = aArea.Top) and (spill.Left = aArea.Left) then
        Exit(True);
    Result := False;
  end;

begin
  var sheet: TWorksheetE := fStore.Objects(False);
  var last: integer := fMap.First - fMap.Delta - 1;
  var limit: integer := fMap.Limit;
  for var area: TArea in fStore.Areas(akArray) do
  begin
    var low: integer := IfThen(fMap.ByRows, area.Top, area.Left);
    var high: integer := IfThen(fMap.ByRows, area.Bottom, area.Right);
    if IsSpill(area) then
    begin // Excel moves the formula's cell and spills it again from there; with that cell it goes whole
      var moved: integer := fMap.MovedIndex(low);
      if moved = 0 then
        Continue;
      var anchor: string := TUtility.CellName(area.Top, area.Left);
      if moved + high - low > limit then
        Exit(Format('the dynamic array at %s spilled past the end of the worksheet (Excel shows #SPILL!)', [anchor]) +
          cNotYet);
      for var row: TRowCT in sheet.SheetData.Row do
        for var cell: TCellCT in row.C do
          if HasValue(cell) and not area.Holds(integer(row.R), TUtility.ColumnOf(cell.R)) then
          begin
            var along: integer := IfThen(fMap.ByRows, integer(row.R), TUtility.ColumnOf(cell.R));
            var across: integer := IfThen(fMap.ByRows, TUtility.ColumnOf(cell.R), integer(row.R));
            var place: integer := fMap.MovedIndex(along);
            if (place >= moved) and (place <= moved + high - low) and (across >= IfThen(fMap.ByRows, area.Left, area.Top)) and
              (across <= IfThen(fMap.ByRows, area.Right, area.Bottom)) then
              Exit(Format('cells moved into the spill of the dynamic array at %s (Excel shows #SPILL!)', [anchor]) +
                cNotYet);
          end;
      Continue;
    end;
    if (fMap.Delta > 0) and (fMap.First > low) and (fMap.First <= high) or
      (fMap.Delta < 0) and (fMap.First <= high) and (last >= low) and ((fMap.First > low) or (last < high)) then
      Exit('You can''t change part of an array.');
  end;
  if Length(fStore.Areas(akDataTable)) > 0 then
    Exit('a data table' + cLater);
  if fMap.Delta > 0 then // a cell with only a format there is dropped, as Excel drops it
    for var row: TRowCT in sheet.SheetData.Row do
      for var cell: TCellCT in row.C do
        if HasValue(cell) and (fMap.ByRows and (integer(row.R) > limit - fMap.Delta) or
          not fMap.ByRows and (TUtility.ColumnOf(cell.R) > limit - fMap.Delta)) then
          Exit(cPushedOff);
  Result := '';
end;

// a row inserted as Excel does: the format and height of the row above (not hidden), its cells' styles where they differ
// from what the new row shows anyway; nil when there is nothing to copy
function TCellsHandler.CopiedRow(aSource: TRowCT; aNumber: integer): TRowCT;
begin
  Result := TRowCT.Create;
  Result.R := aNumber;
  if aSource.CustomFormat then
  begin
    Result.S := aSource.S;
    Result.CustomFormat := True;
  end;
  if aSource.CustomHeight then
  begin
    Result.Ht := aSource.Ht;
    Result.CustomHeight := True;
  end;
  if aSource.Present[@aSource.Spans] then
    Result.Spans := aSource.Spans;
  for var cell: TCellCT in aSource.C do
  begin
    var column: integer := TUtility.ColumnOf(cell.R);
    var shown: cardinal := fStore.ColumnStyle(column);
    if Result.CustomFormat then
      shown := Result.S;
    if cell.S <> shown then
    begin
      var added: TCellCT := TCellCT.Create;
      added.R := TUtility.CellName(aNumber, column);
      added.S := cell.S;
      Result.C.Add(added);
    end;
  end;
  if (Result.C.Count = 0) and not Result.CustomFormat and not Result.CustomHeight then
    FreeAndNil(Result);
end;

// the <col> entries moved; a column inserted takes the width and style of the one left of it (not hidden, not a width of 0)
procedure TCellsHandler.ShiftColumnEntries;
begin
  var sheet: TWorksheetE := fStore.Objects(True);
  if sheet.Cols.Count = 0 then
    Exit;
  var columns: TColCTList := fStore.SortedColumns;
  var last: integer := fMap.First - fMap.Delta - 1;
  SplitColumns(columns, fMap.First);
  if fMap.Delta < 0 then
  begin
    if last < TUtility.cMaxColumn then
      SplitColumns(columns, last + 1);
    for var i := columns.Count - 1 downto 0 do
      if (integer(columns[i].Min) >= fMap.First) and (integer(columns[i].Max) <= last) then
        columns.Delete(i)
      else if integer(columns[i].Min) > last then
      begin
        columns[i].Min := integer(columns[i].Min) + fMap.Delta;
        columns[i].Max := integer(columns[i].Max) + fMap.Delta;
      end;
  end
  else
  begin
    var source: integer := -1;
    for var i := columns.Count - 1 downto 0 do
      if integer(columns[i].Min) >= fMap.First then
      begin
        if integer(columns[i].Min) + fMap.Delta > TUtility.cMaxColumn then
          columns.Delete(i)
        else
        begin
          columns[i].Min := integer(columns[i].Min) + fMap.Delta;
          columns[i].Max := Min(integer(columns[i].Max) + fMap.Delta, TUtility.cMaxColumn);
        end;
      end
      else if integer(columns[i].Max) = fMap.First - 1 then
        source := i;
    if source >= 0 then
      if not columns[source].Hidden and (columns[source].Width > 0) then
        columns[source].Max := integer(columns[source].Max) + fMap.Delta
      else
      begin
        var copy: TColCT := columns[source].Clone<TColCT>;
        copy.Min := fMap.First;
        copy.Max := fMap.First + fMap.Delta - 1;
        copy.Clear(@copy.Hidden);
        copy.Clear(@copy.Collapsed);
        if copy.Width = 0 then
        begin
          copy.Clear(@copy.Width);
          copy.Clear(@copy.CustomWidth);
        end;
        if copy.Present[@copy.Width] or (copy.Style <> 0) then
          columns.Insert(source + 1, copy)
        else
          copy.Free;
      end;
  end;
  if columns.Count = 0 then
    sheet.Cols.Clear;
end;

// the rows or columns moved, those deleted gone (their values released), new ones as the row above or the column left
procedure TCellsHandler.ShiftCells;
begin
  var sheet: TWorksheetE := fStore.Objects(True);
  var rows: TRowCTList := sheet.SheetData.Row;
  var last: integer := fMap.First - fMap.Delta - 1;
  if fMap.ByRows then
  begin
    var index: integer;
    fStore.FindRow(sheet, fMap.First, index);
    if fMap.Delta < 0 then
      while (index < rows.Count) and (integer(rows[index].R) <= last) do
      begin
        for var cell: TCellCT in rows[index].C do
          fStore.RemoveValue(cell);
        rows.Delete(index);
      end
    else
      for var i := rows.Count - 1 downto index do
        if integer(rows[i].R) + fMap.Delta > TUtility.cMaxRow then // only formats there (Plan)
          rows.Delete(i);
    for var i := index to rows.Count - 1 do
    begin
      var row: TRowCT := rows[i];
      row.R := integer(row.R) + fMap.Delta;
      for var cell: TCellCT in row.C do
        cell.R := TUtility.CellName(row.R, TUtility.ColumnOf(cell.R));
    end;
    var above: integer;
    if (fMap.Delta > 0) and (fMap.First > 1) and fStore.FindRow(sheet, fMap.First - 1, above) then
      for var number := fMap.First + fMap.Delta - 1 downto fMap.First do
      begin
        var added: TRowCT := CopiedRow(rows[above], number);
        if added <> nil then
          rows.Insert(above + 1, added);
      end;
    Exit;
  end;
  ShiftColumnEntries;
  for var row: TRowCT in rows do
  begin
    var cells: TCellCTList := row.C;
    var index: integer;
    FindInRow(row, fMap.First, index);
    if fMap.Delta < 0 then
      while (index < cells.Count) and (TUtility.ColumnOf(cells[index].R) <= last) do
      begin
        fStore.RemoveValue(cells[index]);
        cells.Delete(index);
      end
    else
      for var i := cells.Count - 1 downto index do
        if TUtility.ColumnOf(cells[i].R) + fMap.Delta > TUtility.cMaxColumn then
          cells.Delete(i);
    for var i := index to cells.Count - 1 do
      cells[i].R := TUtility.CellName(row.R, TUtility.ColumnOf(cells[i].R) + fMap.Delta);
    if (fMap.Delta > 0) and (index > 0) and (TUtility.ColumnOf(cells[index - 1].R) = fMap.First - 1) then
    begin
      var source: TCellCT := cells[index - 1];
      var shown: cardinal := fStore.ColumnStyle(fMap.First);
      if row.CustomFormat then
        shown := row.S;
      if source.S <> shown then
        for var column := fMap.First + fMap.Delta - 1 downto fMap.First do
        begin
          var added: TCellCT := TCellCT.Create;
          added.R := TUtility.CellName(row.R, column);
          added.S := source.S;
          cells.Insert(index, added);
        end;
    end;
    if row.Present[@row.Spans] then
      if cells.Count = 0 then
        row.Clear(@row.Spans)
      else
        row.Spans := Format('%d:%d', [TUtility.ColumnOf(cells[0].R), TUtility.ColumnOf(cells[cells.Count - 1].R)]);
  end;
end;

// the dynamic arrays' spilled values taken out before rows or columns move (Plan let them): Excel spills each again
// from its formula's cell, the formats stay with the cells
function TCellsHandler.LiftSpills: TArray<TSpill>;
begin
  Result := nil;
  var rows: TRowCTList := fStore.Objects(False).SheetData.Row;
  for var area: TArea in fStore.Areas(akSpill) do
  begin
    var spill: TSpill;
    spill.Area := area;
    spill.Values := nil;
    var index: integer;
    fStore.FindRow(fStore.Objects(False), area.Top, index);
    while (index < rows.Count) and (integer(rows[index].R) <= area.Bottom) do
    begin
      var row: TRowCT := rows[index];
      for var i := row.C.Count - 1 downto 0 do
      begin
        var cell: TCellCT := row.C[i];
        var column: integer := TUtility.ColumnOf(cell.R);
        if (column < area.Left) or (column > area.Right) or (integer(row.R) = area.Top) and (column = area.Left) or
          not cell.Present[@cell.V] or cell.IsPresent('F') or cell.IsPresent('Is') then
          Continue;
        fStore.Objects(True);
        var value: TSpillValue;
        value.Row := integer(row.R) - area.Top;
        value.Column := column - area.Left;
        value.Typed := cell.Present[@cell.T];
        value.T := cell.T;
        value.V := cell.V;
        spill.Values := spill.Values + [value];
        cell.Clear(@cell.V);
        cell.Clear(@cell.T);
        if not cell.Present[@cell.S] and not cell.Present[@cell.Cm] and not cell.Present[@cell.Vm] and
          ((cell.XmlAttributes = nil) or (cell.XmlAttributes.Count = 0)) then
          row.C.Delete(i);
      end;
      Inc(index);
    end;
    Result := Result + [spill];
  end;
end;

// the spilled values back, from where the formula's cell went; gone with it
procedure TCellsHandler.PlaceSpills(const aSpills: TArray<TSpill>);
begin
  for var spill: TSpill in aSpills do
  begin
    var moved: integer;
    if fMap.ByRows then
      moved := fMap.MovedIndex(spill.Area.Top)
    else
      moved := fMap.MovedIndex(spill.Area.Left);
    var top: integer := IfThen(fMap.ByRows, moved, spill.Area.Top);
    var left: integer := IfThen(fMap.ByRows, spill.Area.Left, moved);
    for var value: TSpillValue in spill.Values do
      if moved = 0 then
      begin
        if value.Typed and (value.T = stctS) then
          fBook.SharedStringReleased;
      end
      else
      begin
        var cell: TCellCT := fStore.CellForStyle(top + value.Row, left + value.Column);
        cell.V := value.V;
        cell.SetPresent(@cell.V);
        if value.Typed then
        begin
          cell.T := value.T;
          cell.SetPresent(@cell.T);
        end;
      end;
  end;
end;

// Excel fits the rows' automatic heights (ht without customHeight) again when columns move cells or grow a merged area;
// Calcite drops them, Excel fits them when it opens the file
procedure TCellsHandler.FitAgain;
begin
  if fMap.ByRows then
    Exit;
  var rows: TRowCTList := fStore.Objects(False).SheetData.Row;
  var moved: boolean := False;
  for var row: TRowCT in rows do
    if (row.C.Count > 0) and (TUtility.ColumnOf(row.C[row.C.Count - 1].R) >= fMap.First) then
      moved := True;
  if not moved and (fMap.Delta > 0) then
    for var area: TArea in fStore.Areas(akMerge) do
      if (area.Left < fMap.First) and (area.Right >= fMap.First) then
        moved := True;
  if not moved then
    Exit;
  for var row: TRowCT in rows do
    if row.Present[@row.Ht] and not row.CustomHeight then
    begin
      fStore.Objects(True);
      row.Clear(@row.Ht);
    end;
end;

procedure TCellsHandler.Apply;
begin
  FitAgain;
  var spills: TArray<TSpill> := LiftSpills;
  ShiftCells;
  PlaceSpills(spills);
end;

function ShiftFilterColumns(aFilter: TAutoFilterCT; aOldLeft, aLeft: integer; const aMap: TReferenceMap): boolean;
begin
  var filtered: boolean := aFilter.FilterColumn.Count > 0;
  for var i := aFilter.FilterColumn.Count - 1 downto 0 do
  begin
    var column: integer := aMap.MovedIndex(aOldLeft + integer(aFilter.FilterColumn[i].ColId));
    if column = 0 then
      aFilter.FilterColumn.Delete(i)
    else
    begin
      aFilter.FilterColumn[i].ColId := column - aLeft;
      aFilter.FilterColumn[i].SetPresent(@aFilter.FilterColumn[i].ColId);
    end;
  end;
  Result := filtered and (aFilter.FilterColumn.Count = 0);
end;

// what the sheet lists by address, as Excel moves it: merged areas (one left with a cell unmerged), conditional formats and
// validation (grown by a row or column inserted right after them), hyperlinks, the autofilter (gone with its header row)
// and its sort, ignored errors, protected ranges, page breaks, frozen panes (never fewer than one row or column), the
// dimension

// a sort's areas and conditions moved: False when nothing is left
function SortKept(aSort: TSortStateCT; const aMap: TReferenceMap): boolean;
begin
  var ref: string := aMap.MovedSqref(aSort.Ref);
  if ref = '' then
    Exit(False);
  aSort.Ref := ref;
  for var i := aSort.SortCondition.Count - 1 downto 0 do
  begin
    ref := aMap.MovedSqref(aSort.SortCondition[i].Ref);
    if ref = '' then
      aSort.SortCondition.Delete(i)
    else
      aSort.SortCondition[i].Ref := ref;
  end;
  Result := aSort.SortCondition.Count > 0;
end;

// one left with a cell unmerged
procedure TMergesHandler.Apply;
begin
  var sheet: TWorksheetE := fStore.Objects(True);
  if sheet.IsPresent('MergeCells') then
  begin
    var merged: TMergeCellCTList := sheet.MergeCells.MergeCell;
    for var i := merged.Count - 1 downto 0 do
    begin
      var area: TArea;
      if TArea.TryParse(merged[i].Ref, area) then
        if fMap.MovedArea(area) and ((area.Top <> area.Bottom) or (area.Left <> area.Right)) then
          merged[i].Ref := area.CellsAddress
        else
          merged.Delete(i);
    end;
    if merged.Count = 0 then
      sheet.Clear('MergeCells')
    else if sheet.MergeCells.Present[@sheet.MergeCells.Count] then
      sheet.MergeCells.Count := merged.Count;
  end;
  fStore.Forget; // the merges edited as objects
end;

// grown by a row or column inserted right after them
procedure TConditionalAreasHandler.Apply;
begin
  var sheet: TWorksheetE := fStore.Objects(True);
  for var i := sheet.ConditionalFormatting.Count - 1 downto 0 do
  begin
    var ref: string := fMap.MovedSqref(sheet.ConditionalFormatting[i].Sqref, True);
    if ref = '' then
      sheet.ConditionalFormatting.Delete(i)
    else
      sheet.ConditionalFormatting[i].Sqref := ref;
  end;
end;

// grown by a row or column inserted right after them
procedure TValidationAreasHandler.Apply;
begin
  var sheet: TWorksheetE := fStore.Objects(True);
  if not sheet.IsPresent('DataValidations') then
    Exit;
  var validations: TDataValidationCTList := sheet.DataValidations.DataValidation;
  for var i := validations.Count - 1 downto 0 do
  begin
    var ref: string := fMap.MovedSqref(validations[i].Sqref, True);
    if ref = '' then
      validations.Delete(i)
    else
      validations[i].Sqref := ref;
  end;
  if validations.Count = 0 then
    sheet.Clear('DataValidations')
  else if sheet.DataValidations.Present[@sheet.DataValidations.Count] then
    sheet.DataValidations.Count := validations.Count;
end;

procedure THyperlinksHandler.Apply;
begin
  var sheet: TWorksheetE := fStore.Objects(True);
  if not sheet.IsPresent('Hyperlinks') then
    Exit;
  var links: THyperlinkCTList := sheet.Hyperlinks.Hyperlink;
  for var i := links.Count - 1 downto 0 do
  begin
    var ref: string := fMap.MovedSqref(links[i].Ref);
    if ref = '' then
      links.Delete(i)
    else
      links[i].Ref := ref;
  end;
  if links.Count = 0 then
    sheet.Clear('Hyperlinks');
end;

// gone with its header row, and its hidden name with it; its columns and sort follow
procedure TAutoFilterHandler.Apply;
begin
  var sheet: TWorksheetE := fStore.Objects(True);
  var last: integer := fMap.First - fMap.Delta - 1;
  var filterGone: boolean := False;
  if sheet.IsPresent('AutoFilter') then
  begin
    var filter: TAutoFilterCT := sheet.AutoFilter;
    var area: TArea;
    if TArea.TryParse(filter.Ref, area) then
    begin
      var oldLeft: integer := area.Left;
      if fMap.ByRows and (fMap.Delta < 0) and (fMap.First <= area.Top) and (last >= area.Top) or
        not fMap.MovedArea(area) then
      begin
        sheet.Clear('AutoFilter');
        filterGone := True;
      end
      else
      begin
        filter.Ref := area.CellsAddress;
        if not fMap.ByRows and ShiftFilterColumns(filter, oldLeft, area.Left, fMap) then
          ShowRows(area.Top + 1, area.Bottom);
        if filter.IsPresent('SortState') and not SortKept(filter.SortState, fMap) then
          filter.Clear('SortState');
      end;
    end;
  end;
  if not filterGone then
    Exit;
  var workbook: TWorkbookE := fBook.Package.EditPart<TWorkbookE>(fBook.WorkbookPart);
  var tab: integer := workbook.Sheets.Sheet.IndexOf(fBook.SheetEntry(fName));
  if workbook.IsPresent('DefinedNames') then
  begin
    var names: TDefinedNameCTList := workbook.DefinedNames.DefinedName;
    for var i := names.Count - 1 downto 0 do
      if (names[i].Name = '_xlnm._FilterDatabase') and names[i].Present[@names[i].LocalSheetId] and
        (integer(names[i].LocalSheetId) = tab) then
        names.Delete(i);
    if names.Count = 0 then
      workbook.Clear('DefinedNames');
  end;
end;

procedure TSortHandler.Apply;
begin
  var sheet: TWorksheetE := fStore.Objects(True);
  if sheet.IsPresent('SortState') and not SortKept(sheet.SortState, fMap) then
    sheet.Clear('SortState');
end;

procedure TIgnoredErrorsHandler.Apply;
begin
  var sheet: TWorksheetE := fStore.Objects(True);
  if not sheet.IsPresent('IgnoredErrors') then
    Exit;
  var errors: TIgnoredErrorCTList := sheet.IgnoredErrors.IgnoredError;
  for var i := errors.Count - 1 downto 0 do
  begin
    var ref: string := fMap.MovedSqref(errors[i].Sqref);
    if ref = '' then
      errors.Delete(i)
    else
      errors[i].Sqref := ref;
  end;
  if errors.Count = 0 then
    sheet.Clear('IgnoredErrors');
end;

procedure TProtectedRangesHandler.Apply;
begin
  var sheet: TWorksheetE := fStore.Objects(True);
  if not sheet.IsPresent('ProtectedRanges') then
    Exit;
  var ranges: TProtectedRangeCTList := sheet.ProtectedRanges.ProtectedRange;
  for var i := ranges.Count - 1 downto 0 do
  begin
    var ref: string := fMap.MovedSqref(ranges[i].Sqref);
    if ref = '' then
      ranges.Delete(i)
    else
      ranges[i].Sqref := ref;
  end;
  if ranges.Count = 0 then
    sheet.Clear('ProtectedRanges');
end;

procedure TPageBreaksHandler.Apply;
var
  sheet: TWorksheetE;

  procedure ShiftBreaks(aBreaks: TPageBreakCT; const aName: string);
  begin
    for var i := aBreaks.Brk.Count - 1 downto 0 do
    begin
      var id: integer := fMap.MovedIndex(aBreaks.Brk[i].Id);
      if id = 0 then
        aBreaks.Brk.Delete(i)
      else
        aBreaks.Brk[i].Id := id;
    end;
    if aBreaks.Brk.Count = 0 then
      sheet.Clear(aName)
    else
    begin
      if aBreaks.Present[@aBreaks.Count] then
        aBreaks.Count := aBreaks.Brk.Count;
      if aBreaks.Present[@aBreaks.ManualBreakCount] then
      begin
        var manual: integer := 0;
        for var item: TBreakCT in aBreaks.Brk do
          if item.Man then
            Inc(manual);
        aBreaks.ManualBreakCount := manual;
      end;
    end;
  end;

begin
  sheet := fStore.Objects(True);
  if fMap.ByRows and sheet.IsPresent('RowBreaks') then
    ShiftBreaks(sheet.RowBreaks, 'RowBreaks');
  if not fMap.ByRows and sheet.IsPresent('ColBreaks') then
    ShiftBreaks(sheet.ColBreaks, 'ColBreaks');
end;

// never fewer than one row or column frozen
procedure TPanesHandler.Apply;
begin
  var sheet: TWorksheetE := fStore.Objects(True);
  if not sheet.IsPresent('SheetViews') then
    Exit;
  var last: integer := fMap.First - fMap.Delta - 1;
  for var view: TSheetViewCT in sheet.SheetViews.SheetView do
    if view.IsPresent('Pane') and (view.Pane.State in [stpsFrozen, stpsFrozenSplit]) then
    begin
      var pane: TPaneCT := view.Pane;
      var split: integer := Trunc(pane.XSplit);
      if fMap.ByRows then
        split := Trunc(pane.YSplit);
      if (split = 0) or (fMap.First > split) then
        Continue;
      var moved: integer := split + fMap.Delta;
      if fMap.Delta < 0 then
        moved := Max(1, split - (Min(last, split) - fMap.First + 1));
      var at: TArea;
      if fMap.ByRows then
      begin
        pane.YSplit := moved;
        if TArea.TryParse(pane.TopLeftCell, at) then
          pane.TopLeftCell := TUtility.CellName(Max(1, at.Top + moved - split), at.Left);
      end
      else
      begin
        pane.XSplit := moved;
        if TArea.TryParse(pane.TopLeftCell, at) then
          pane.TopLeftCell := TUtility.CellName(at.Top, Max(1, at.Left + moved - split));
      end;
    end;
end;

procedure TDimensionHandler.Apply;
begin
  var sheet: TWorksheetE := fStore.Objects(True);
  if sheet.IsPresent('Dimension') then
  begin
    var area: TArea;
    if TArea.TryParse(sheet.Dimension.Ref, area) then
      if fMap.MovedArea(area) then
        sheet.Dimension.Ref := area.CellsAddress
      else
        sheet.Dimension.Ref := 'A1';
  end;
end;

function XmlTextDecoded(const aText: string): string;
begin
  Result := aText.Replace('&lt;', '<').Replace('&gt;', '>').Replace('&quot;', '"').Replace('&apos;', '''').
    Replace('&amp;', '&');
end;

function XmlTextEncoded(const aText: string): string;
begin
  Result := aText.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;');
end;

function MappedKeptXml(const aXml, aSheet: string; const aMap: TReferenceMap; out aResult, aWhy: string): boolean;
begin
  aResult := '';
  aWhy := '';
  var done: integer := 0; // the characters copied
  for var match: TMatch in TRegEx.Matches(aXml, '<((?:[\w.-]+:)?)(f|sqref)(\s[^>]*)?>([^<]*)</\1\2\s*>') do
  begin
    var text: string := XmlTextDecoded(match.Groups[4].Value);
    var changed, why: string;
    if not ShiftFormula(text, aMap, changed, why) then
    begin
      if ContainsText(text, aSheet) then
      begin
        aWhy := Format('%s (%s)', [why, text]);
        Exit(False);
      end;
      Continue;
    end;
    if changed = text then
      Continue;
    aResult := aResult + aXml.Substring(done, match.Index - 1 - done) + Format('<%s%s%s>%s</%0:s%1:s>',
      [match.Groups[1].Value, match.Groups[2].Value, match.Groups[3].Value, XmlTextEncoded(changed)]);
    done := match.Index - 1 + match.Length;
  end;
  aResult := aResult + aXml.Substring(done);
  Result := True;
end;

constructor TFormulasHandler.Create(aWalk: TXlsxWalk);
begin
  inherited;
  fMoves := TObjectList<TList<TFormulaMove>>.Create;
  fRefs := TObjectList<TDictionary<cardinal, string>>.Create;
  fRules := TList<TTextMove>.Create;
end;

destructor TFormulasHandler.Destroy;
begin
  fRules.Free;
  fRefs.Free;
  fMoves.Free;
  inherited;
end;

// a formula of aSheet through aMap (the sheet's copy of the walk's), in aResult: False with aWhy when one that may name the
// changed sheet does not read
function TFormulasHandler.Changed(aSheet: TXlsxWalkSheet; const aMap: TReferenceMap; const aText, aWhere: string;
  out aResult, aWhy: string): boolean;
begin
  Result := True;
  aWhy := '';
  var why: string;
  if ShiftFormula(aText, aMap, aResult, why) then
    Exit;
  aResult := aText;
  if (aSheet = fSheet) or ContainsText(aText, fMap.Sheet) then
  begin
    aWhy := Format('the formula of %s!%s does not read: %s', [aSheet.fName, aWhere, why]);
    Result := False;
  end;
end;

// aSheet's formulas through the walk's map: each cell's that stays, its place and text then; shared formulas' areas by si;
// then its rules'. Why one that may name the changed sheet does not read, '' when all do
function TFormulasHandler.PlanSheet(aSheet: TXlsxWalkSheet; aMoves: TList<TFormulaMove>; aRefs: TDictionary<cardinal, string>): string;
begin
  Result := '';
  var map: TReferenceMap := fMap;
  map.OnSheet := (map.Change <> TReferenceChange.rcSheetDelete) and AnsiSameText(aSheet.fName, map.Sheet);
  map.InName := False;
  var sheet: TWorksheetE := aSheet.fStore.Objects(False);
  for var row: TRowCT in sheet.SheetData.Row do
    for var cell: TCellCT in row.C do
    begin
      if not cell.IsPresent('F') or (cell.F.T = stcftDataTable) then
        Continue;
      if (cell.F.T = stcftShared) and (cell.F.Ref <> '') then
        aRefs.AddOrSetValue(cell.F.Si, cell.F.Ref);
      var move: TFormulaMove;
      move.Cell := cell;
      move.Row := row.R;
      move.Column := TUtility.ColumnOf(cell.R);
      if not aSheet.fStore.FormulaText(move.Row, move.Column, move.Before) then
        Continue;
      if aSheet = fSheet then
        if fMap.ByRows then
          move.Row := fMap.MovedIndex(move.Row)
        else
          move.Column := fMap.MovedIndex(move.Column);
      if (move.Row = 0) or (move.Column = 0) then
        Continue;
      if not Changed(aSheet, map, move.Before, cell.R, move.After, Result) then
        Exit;
      aMoves.Add(move);
    end;
  Result := PlanRules(aSheet, map);
end;

// aSheet's conditional formats' and validation's formulas that change, in fRules: why one does not read, '' when all do
function TFormulasHandler.PlanRules(aSheet: TXlsxWalkSheet; const aMap: TReferenceMap): string;

  function Add(aRule: TCfRuleCT; aValidation: TDataValidationCT; aIndex: integer; const aText, aWhere: string): string;
  begin
    var move: TTextMove := Default(TTextMove);
    if Changed(aSheet, aMap, DecodeText(aText), aWhere, move.Text, Result) and (move.Text <> DecodeText(aText)) then
    begin
      move.Sheet := aSheet;
      move.Rule := aRule;
      move.Validation := aValidation;
      move.Index := aIndex;
      fRules.Add(move);
    end;
  end;

begin
  Result := '';
  var sheet: TWorksheetE := aSheet.fStore.Objects(False);
  for var formatting: TConditionalFormattingCT in sheet.ConditionalFormatting do
    for var rule: TCfRuleCT in formatting.CfRule do
      for var index := 0 to rule.Formula.Count - 1 do
      begin
        Result := Add(rule, nil, index, rule.Formula[index], formatting.Sqref);
        if Result <> '' then
          Exit;
      end;
  if sheet.IsPresent('DataValidations') then
    for var validation: TDataValidationCT in sheet.DataValidations.DataValidation do
    begin
      if validation.Formula1 <> '' then
        Result := Add(nil, validation, 1, validation.Formula1, validation.Sqref);
      if (Result = '') and (validation.Formula2 <> '') then
        Result := Add(nil, validation, 2, validation.Formula2, validation.Sqref);
      if Result <> '' then
        Exit;
    end;
end;

function TFormulasHandler.Plan: string;
begin
  Result := '';
  for var sheet: TXlsxWalkSheet in fWalk.fSheets do
  begin
    fMoves.Add(TList<TFormulaMove>.Create);
    fRefs.Add(TDictionary<cardinal, string>.Create);
    if (sheet <> fSheet) or (fMap.Change <> TReferenceChange.rcSheetDelete) then
      Result := PlanSheet(sheet, fMoves.Last, fRefs.Last);
    if Result <> '' then
      Exit;
  end;
end;

procedure TFormulasHandler.ApplyRules;
begin
  for var move: TTextMove in fRules do
  begin
    move.Sheet.fStore.Objects(True);
    if move.Rule <> nil then
      move.Rule.Formula[move.Index] := EncodeText(move.Text)
    else if move.Index = 1 then
      move.Validation.Formula1 := EncodeText(move.Text)
    else
      move.Validation.Formula2 := EncodeText(move.Text);
  end;
end;

// a formula of its own written; aShifted (its sheet's rows or columns moved), an array's area too: a dynamic array spilled
// again from its cell, as large as before
procedure TFormulasHandler.ApplyOne(aSheet: TXlsxWalkSheet; const aMove: TFormulaMove; aShifted: boolean);
begin
  var formula: TCellFormulaCT := aMove.Cell.F;
  if aMove.After <> aMove.Before then
  begin
    aSheet.fStore.Objects(True);
    formula.XmlValue := EncodeText(aMove.After);
  end;
  var area: TArea;
  if aShifted and (formula.T = stcftArray) and TArea.TryParse(formula.Ref, area) then
    if (aMove.Cell.Cm > 0) and fBook.IsDynamicArray(aMove.Cell.Cm) then
    begin
      var moved: TArea := area;
      moved.Top := aMove.Row;
      moved.Left := aMove.Column;
      moved.Bottom := aMove.Row + area.Bottom - area.Top;
      moved.Right := aMove.Column + area.Right - area.Left;
      formula.Ref := moved.CellsAddress;
    end
    else if fMap.MovedArea(area) then
      formula.Ref := area.CellsAddress;
end;

// a shared formula's cells (aMembers, indexes in aMoves) written: it stays one while they still fill from its first cell's
// text (that cell gone, the next one is first) and it names no #REF! (Excel makes those plain), else each cell gets its own
procedure TFormulasHandler.ApplyShared(aSheet: TXlsxWalkSheet; aMoves: TList<TFormulaMove>; aSi: cardinal;
  aMembers: TList<integer>; aRefs: TDictionary<cardinal, string>; aShifted: boolean);
begin
  var changed: boolean := aShifted;
  for var index: integer in aMembers do
    changed := changed or (aMoves[index].After <> aMoves[index].Before);
  if not changed then
    Exit;
  aSheet.fStore.Objects(True);
  var first: TFormulaMove := aMoves[aMembers[0]];
  var area: TArea;
  var ref: string;
  var shared: boolean := not first.After.Contains('#REF!') and aRefs.TryGetValue(aSi, ref) and TArea.TryParse(ref, area) and
    (not aShifted or fMap.MovedArea(area));
  for var index: integer in aMembers do
  begin
    var move: TFormulaMove := aMoves[index];
    var filled, why: string;
    shared := shared and ShiftFormula(first.After, TReferenceMap.Fill(move.Row - first.Row, move.Column - first.Column),
      filled, why) and (filled = move.After);
  end;
  for var index: integer in aMembers do
  begin
    var formula: TCellFormulaCT := aMoves[index].Cell.F;
    if not shared then
    begin
      formula.Clear('T');
      formula.Clear('Si');
      formula.Clear('Ref');
      formula.XmlValue := EncodeText(aMoves[index].After);
    end
    else if index = aMembers[0] then
    begin
      formula.Ref := area.CellsAddress;
      formula.XmlValue := EncodeText(first.After);
    end
    else
    begin
      formula.Clear('Ref');
      formula.XmlValue := '';
    end;
  end;
end;

// aSheet's planned formulas written; aShifted: its rows or columns moved
procedure TFormulasHandler.ApplySheet(aSheet: TXlsxWalkSheet; aMoves: TList<TFormulaMove>; aRefs: TDictionary<cardinal, string>;
  aShifted: boolean);
begin
  var groups: TObjectDictionary<cardinal, TList<integer>> := TObjectDictionary<cardinal, TList<integer>>.Create([doOwnsValues]);
  try
    for var index := 0 to aMoves.Count - 1 do
      if aMoves[index].Cell.F.T <> stcftShared then
        ApplyOne(aSheet, aMoves[index], aShifted)
      else
      begin
        var members: TList<integer>;
        if not groups.TryGetValue(aMoves[index].Cell.F.Si, members) then
        begin
          members := TList<integer>.Create;
          groups.Add(aMoves[index].Cell.F.Si, members);
        end;
        members.Add(index);
      end;
    for var group: TPair<cardinal, TList<integer>> in groups do
      ApplyShared(aSheet, aMoves, group.Key, group.Value, aRefs, aShifted);
  finally
    groups.Free;
  end;
end;

// a dynamic array whose formula now names #REF!: its spill folded into its cell, as Excel calculates it; #REF! its value
// when the formula is #REF! alone (Data!#REF!), else the value as read - Excel calculates it on open (IFERROR(...,"x"))
procedure TFormulasHandler.FoldSpills(aSheet: TXlsxWalkSheet; aMoves: TList<TFormulaMove>);
begin
  for var move: TFormulaMove in aMoves do
  begin
    var cell: TCellCT := move.Cell;
    var area: TArea;
    if (move.After = move.Before) or not move.After.Contains('#REF!') or (cell.F.T <> stcftArray) or (cell.Cm = 0) or
      not fBook.IsDynamicArray(cell.Cm) or not TArea.TryParse(cell.F.Ref, area) then
      Continue;
    aSheet.fStore.Objects(True);
    for var row: TRowCT in aSheet.fStore.RowEntries(area.Top, area.Bottom) do
      for var i := row.C.Count - 1 downto 0 do
      begin
        var spilled: TCellCT := row.C[i];
        var column: integer := TUtility.ColumnOf(spilled.R);
        if (spilled = cell) or (column < area.Left) or (column > area.Right) then
          Continue;
        aSheet.fStore.RemoveValue(spilled);
        if IsBare(spilled, ['S', 'Ph', 'ExtLst']) then
          row.Remove(spilled);
      end;
    cell.F.Ref := cell.R;
    if TRegEx.IsMatch(move.After, '^(?:(?:''(?:[^'']|'''')*''|[^''!]+)!)?#REF!$') then
    begin
      cell.T := stctE;
      cell.V := '#REF!';
    end;
  end;
end;

procedure TFormulasHandler.Apply;
begin
  for var index := 0 to fWalk.fSheets.Count - 1 do
  begin
    var sheet: TXlsxWalkSheet := fWalk.fSheets[index];
    ApplySheet(sheet, fMoves[index], fRefs[index], sheet = fSheet);
    FoldSpills(sheet, fMoves[index]);
  end;
end;

procedure TFormulasHandler.Written(aTo: TStringBuilder);
begin
  for var list: TList<TFormulaMove> in fMoves do
    for var move: TFormulaMove in list do
      aTo.Append(move.After).Append(#10);
  for var move: TTextMove in fRules do
    aTo.Append(move.Text).Append(#10);
end;

// why one naming the sheet does not read, '' when all do
function TNamesHandler.Plan: string;
begin
  fMapped := fBook.MappedNames(fMap, fChanged, Result);
end;

procedure TNamesHandler.Apply;
begin
  if fMapped then
    fBook.WriteNames(fChanged);
end;

procedure TNamesHandler.Written(aTo: TStringBuilder);
begin
  for var text: string in fChanged do
    aTo.Append(text).Append(#10);
end;

// every handler's Plan in order: the first why, '' when none refuses
function TXlsxWalk.Planned: string;
begin
  for var handler: TXlsxHandler in fHandlers do
  begin
    Result := handler.Plan;
    if Result <> '' then
      Exit;
  end;
  Result := '';
end;

procedure TXlsxWalk.Mapped;
begin
  for var handler: TXlsxHandler in fHandlers do
    handler.fMap := fMap;
end;

constructor TExtensionsHandler.Create(aWalk: TXlsxWalk);
begin
  inherited;
  fMoves := TList<TKeptMove>.Create;
  fUnknown := TList<integer>.Create;
end;

destructor TExtensionsHandler.Destroy;
begin
  fUnknown.Free;
  fMoves.Free;
  inherited;
end;

type
  // an extension's URI as the walk knows it: Why - refused, '' - it names no cells
  TKnownExtension = record
    Uri, Why: string;
  end;

const
  cExtensions: array[0 .. 5] of TKnownExtension = (
    (Uri: '{78C0D931-6437-407d-A8EE-F0AAD7539E65}'; Why: 'Excel 2010''s conditional formats (data bars, icon sets)'),
    (Uri: '{CCE6A557-97BC-4b89-ADB6-D9C93CAAB3DF}'; Why: 'Excel 2010''s data validation (lists from other sheets)'),
    (Uri: '{05C60535-1F16-4fd2-B633-F4F36F0B64E0}'; Why: 'sparklines'),
    (Uri: '{A8765BA9-456A-4dab-B4F3-ACF838C121DE}'; Why: ''), // slicers
    (Uri: '{3A4CF648-6AED-40f4-86FF-DC5316D8AED3}'; Why: ''), // tables' slicers
    (Uri: '{7E03D99C-DC04-49d9-9315-930204A7B6E9}'; Why: '')); // timelines

// rows or columns moved: why one of the sheet's extensions naming cells refuses; those it does not know into fUnknown
function TExtensionsHandler.PlanSheet: string;
begin
  Result := '';
  var objects: TWorksheetE := fStore.Objects(False);
  if not objects.IsPresent('ExtLst') then
    Exit;
  var extensions: ProRock.Xmlite.Schema.Ooxml.Sml.TExtensionCTList := objects.ExtLst.Ext;
  for var index := 0 to extensions.Count - 1 do
  begin
    var known: integer := High(cExtensions);
    while (known >= 0) and not SameText(cExtensions[known].Uri, extensions[index].Uri) do
      Dec(known);
    if known < 0 then
      fUnknown.Add(index)
    else if cExtensions[known].Why <> '' then
      Exit(cExtensions[known].Why + ', which Calcite does not move yet');
  end;
end;

// the extensions it does not know kept or dropped, the walk's notes telling which
procedure TExtensionsHandler.ApplySheet;
begin
  if fUnknown.Count = 0 then
    Exit;
  var objects: TWorksheetE := fStore.Objects(fWalk.fUnknownExtensions = ueDrop);
  var extensions: ProRock.Xmlite.Schema.Ooxml.Sml.TExtensionCTList := objects.ExtLst.Ext;
  for var i := fUnknown.Count - 1 downto 0 do
    if fWalk.fUnknownExtensions = ueDrop then
    begin
      fWalk.fNotes.Add(Format('an extension Calcite does not know (%s) dropped', [extensions[fUnknown[i]].Uri]));
      extensions.Delete(fUnknown[i]);
    end
    else
      fWalk.fNotes.Add(Format('an extension Calcite does not know (%s) kept as it was: its references may not have moved',
        [extensions[fUnknown[i]].Uri]));
  fWalk.fNotes.Reverse;
  if extensions.Count = 0 then
    objects.Clear('ExtLst');
end;

// rows or columns moved, the sheet's own extensions first; then why another sheet's formula naming it does not read, ''
// when all do
function TExtensionsHandler.Plan: string;
begin
  if fMap.Change <> TReferenceChange.rcSheetDelete then
  begin
    Result := PlanSheet;
    if Result <> '' then
      Exit;
  end;
  var map: TReferenceMap := fMap; // a reference without a sheet's name is the other sheet's own
  map.OnSheet := False;
  map.InName := False;
  for var sheet: TXlsxWalkSheet in fWalk.fSheets do
  begin
    if sheet = fSheet then
      Continue;
    var objects: TWorksheetE := sheet.fStore.Objects(False);
    if not objects.IsPresent('ExtLst') then
      Continue;
    for var extension: ProRock.Xmlite.Schema.Ooxml.Sml.TExtensionCT in objects.ExtLst.Ext do
      for var index := 0 to extension.XmlUnknown.Count - 1 do
      begin
        var move: TKeptMove := Default(TKeptMove);
        var why: string := '';
        if not MappedKeptXml(extension.XmlUnknown[index].Xml, fName, map, move.Text, why) then
          Exit(Format('a formula of %s''s extensions does not read: %s', [sheet.fName, why]));
        if move.Text = extension.XmlUnknown[index].Xml then
          Continue;
        move.Sheet := sheet;
        move.Extension := extension;
        move.Index := index;
        fMoves.Add(move);
      end;
  end;
  Result := '';
end;

procedure TExtensionsHandler.Apply;
begin
  ApplySheet;
  for var move: TKeptMove in fMoves do
  begin
    move.Sheet.fStore.Objects(True);
    var item: TXmliteUnknown := move.Extension.XmlUnknown[move.Index];
    item.Xml := move.Text;
    move.Extension.XmlUnknown[move.Index] := item;
  end;
end;

procedure TExtensionsHandler.Written(aTo: TStringBuilder);
begin
  for var move: TKeptMove in fMoves do
    aTo.Append(move.Text).Append(#10);
end;

constructor TLocalNamesHandler.Create(aWalk: TXlsxWalk);
begin
  inherited;
  fLifted := TList<integer>.Create;
end;

destructor TLocalNamesHandler.Destroy;
begin
  fLifted.Free;
  inherited;
end;

// why one a formula names cannot become the workbook's, '' else
function TLocalNamesHandler.Plan: string;
begin
  Result := '';
  fIndex := fBook.SheetIndex(fName);
  var xml: TWorkbookE := fBook.Package.Part<TWorkbookE>(fBook.WorkbookPart);
  if not xml.IsPresent('DefinedNames') then
    Exit;
  var workbookNames: TList<string> := TList<string>.Create(TIStringComparer.Ordinal);
  var written: TStringBuilder := TStringBuilder.Create;
  try
    for var handler: TXlsxHandler in fWalk.fHandlers do
      handler.Written(written);
    var text: string := written.ToString;
    var list: TDefinedNameCTList := xml.DefinedNames.DefinedName;
    for var name: TDefinedNameCT in list do
      if not name.Present[@name.LocalSheetId] then
        workbookNames.Add(name.Name);
    for var i := 0 to list.Count - 1 do
      if list[i].Present[@list[i].LocalSheetId] and (integer(list[i].LocalSheetId) = fIndex) and
        not string(list[i].Name).StartsWith('_xlnm.') and
        TRegEx.IsMatch(text, '\[0\]!' + TRegEx.Escape(list[i].Name) + '(?![\w.?\\])', [roIgnoreCase]) then
        if workbookNames.Contains(list[i].Name) then
          Exit(Format('its name %s, which a formula names, and the workbook''s of the same name: Calcite does not know ' +
            'which Excel keeps', [string(list[i].Name)]))
        else
          fLifted.Add(i);
  finally
    written.Free;
    workbookNames.Free;
  end;
end;

procedure TLocalNamesHandler.Apply;
begin
  var workbook: TWorkbookE := fBook.Package.EditPart<TWorkbookE>(fBook.WorkbookPart);
  if not workbook.IsPresent('DefinedNames') then
    Exit;
  var list: TDefinedNameCTList := workbook.DefinedNames.DefinedName;
  for var i := list.Count - 1 downto 0 do
    if fLifted.Contains(i) then
      list[i].Clear(@list[i].LocalSheetId)
    else if list[i].Present[@list[i].LocalSheetId] then
      if integer(list[i].LocalSheetId) = fIndex then
        list.Delete(i)
      else if integer(list[i].LocalSheetId) > fIndex then
        list[i].LocalSheetId := list[i].LocalSheetId - 1;
  if list.Count = 0 then
    workbook.Clear('DefinedNames');
end;

// a part's own relationships part
function RelationshipsOf(const aPart: string): string;
begin
  var slash: integer := aPart.LastIndexOf('/');
  Result := aPart.Substring(0, slash + 1) + '_rels/' + aPart.Substring(slash + 1) + '.rels';
end;

function TSheetHandler.Plan: string;
begin
  fIndex := fBook.SheetIndex(fName);
  for var relationship: TRelationshipOoxml in fBook.Package.Relationships(fStore.Part) do
    if relationship.&Type.EndsWith(cSlicer) or relationship.&Type.EndsWith(cTimeline) then
      Exit('slicers or timelines, which Calcite does not remove yet');
  Result := '';
end;

// the active sheet deleted: the next visible one (else the one before) active and selected, as Excel does; the views' tabs
// after it one less
procedure TSheetHandler.ShowAnother;
begin
  var workbook: TWorkbookE := fBook.Package.EditPart<TWorkbookE>(fBook.WorkbookPart);
  var entries: TSheetCTList := workbook.Sheets.Sheet;
  var active: integer := -1;
  for var i := fIndex + 1 to entries.Count - 1 do
    if (active < 0) and (entries[i].State = stssVisible) then
      active := i;
  for var i := fIndex - 1 downto 0 do
    if (active < 0) and (entries[i].State = stssVisible) then
      active := i;
  if fBook.MoveActiveSheet(fIndex, active) then
  begin
    for var sheet: TXlsxWalkSheet in fWalk.fSheets do
      if (sheet <> fSheet) and (fBook.SheetIndex(sheet.fName) = active) then
        sheet.fStore.SetTabSelected(True);
    fBook.SetChartTabSelected(active, True);
  end;
  if workbook.IsPresent('BookViews') then
    for var view: TBookViewCT in workbook.BookViews.WorkbookView do
    begin
      var tab: integer := view.ActiveTab;
      if tab > fIndex then
        Dec(tab);
      if tab <> integer(view.ActiveTab) then
      begin
        view.ActiveTab := tab;
        view.SetPresent(@view.ActiveTab);
      end;
      var first: integer := view.FirstSheet;
      if first > fIndex then
        Dec(first);
      first := Min(first, entries.Count - 2);
      if first <> integer(view.FirstSheet) then
      begin
        view.FirstSheet := first;
        view.SetPresent(@view.FirstSheet);
      end;
    end;
end;

// the parts only the sheet and the walk's dropped ones lead to: those no other part reaches from the package's root
procedure TSheetHandler.RemoveParts;
begin
  var package: TPackageOoxml := fBook.Package;
  var dropped: TList<string> := fWalk.fDropped;
  var names: TList<string> := TList<string>.Create;
  var parents: TList<string> := TList<string>.Create;
  var found: TDictionary<string, boolean> := TDictionary<string, boolean>.Create(TIStringComparer.Ordinal);
  var reached: TDictionary<string, boolean> := TDictionary<string, boolean>.Create(TIStringComparer.Ordinal);
  var queue: TList<string> := TList<string>.Create;
  try
    names.Add(fStore.Part);
    parents.Add(fBook.WorkbookPart);
    found.Add(fStore.Part, True);
    for var cache: string in dropped do
    begin
      names.Add(cache);
      parents.Add(fBook.WorkbookPart);
      found.AddOrSetValue(cache, True);
    end;
    var next: integer := 0;
    while next < names.Count do
    begin
      for var relationship: TRelationshipOoxml in package.Relationships(names[next]) do
        if (relationship.Part <> '') and not found.ContainsKey(relationship.Part) then
        begin
          found.Add(relationship.Part, True);
          names.Add(relationship.Part);
          parents.Add(names[next]);
        end;
      Inc(next);
    end;
    queue.Add('');
    next := 0;
    while next < queue.Count do
    begin
      for var relationship: TRelationshipOoxml in package.Relationships(queue[next]) do
        if (relationship.Part <> '') and not reached.ContainsKey(relationship.Part) and
          ((queue[next] <> fBook.WorkbookPart) or (relationship.Part <> fStore.Part) and not dropped.Contains(relationship.Part)) then
        begin
          reached.Add(relationship.Part, True);
          queue.Add(relationship.Part);
        end;
      Inc(next);
    end;
    for var index := 0 to names.Count - 1 do
      if not reached.ContainsKey(names[index]) then
      begin
        package.RemovePart(names[index], RelationshipsOf(names[index]));
        package.RemovePart(parents[index], names[index]);
      end;
  finally
    queue.Free;
    reached.Free;
    found.Free;
    parents.Free;
    names.Free;
  end;
end;

procedure TSheetHandler.Apply;
begin
  ShowAnother;
  for var row: TRowCT in fStore.Objects(False).SheetData.Row do
    for var cell: TCellCT in row.C do
      if (cell.T = stctS) and cell.Present[@cell.V] then
        fBook.SharedStringReleased;
  RemoveParts;
  fBook.Package.Part<TWorkbookE>(fBook.WorkbookPart).Sheets.Sheet.Delete(fIndex);
end;

end.
