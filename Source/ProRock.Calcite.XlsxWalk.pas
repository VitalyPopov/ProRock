unit ProRock.Calcite.XlsxWalk;

// the xlsx backend's insert and delete: rows, columns, sheets, and what names them moved as Excel does (internal)

interface

uses System.SysUtils, System.Classes, System.Generics.Collections, ProRock.Xmlite, ProRock.Office.Ooxml,
  ProRock.Xmlite.Schema.Ooxml.Sml, ProRock.Calcite.Utility, ProRock.Calcite.Aspects, ProRock.Calcite.Xlsx,
  ProRock.Calcite.XlsxSheet;

type
  TXlsxWalk = class;

  // a worksheet as the walk sees it: its name, its storage, what a move plans on it
  TXlsxWalkSheet = class
  private type
    // a formula's cell through rows or columns inserted or deleted: where it is then, its text before and after (stored)
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
    // a drawing's object (xdr:twoCellAnchor or xdr:oneCellAnchor) and where it started and ended on the shifted axis
    TAnchorMove = record
      Part: string;
      Anchor: TXmlite;
      From, &To: Int64;
    end;
    // a chart's reference to cells through rows or columns inserted or deleted: its c:f (Index -1), or an extension's
    // element kept as read (Index in XmlUnknown); the text before and after
    TChartMove = record
      Part: string;
      Reference: TXmlite;
      Index: integer;
      Before, After: string;
    end;
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
    fWalk: TXlsxWalk;
    fBook: TXlsxBook;
    fName: string;
    fStore: TXlsxSheet;
    // while rows or columns are inserted or deleted: the tables (Sales) and table columns (Sales[Q1]) going, each table's
    // area and data rows (pairs)
    fGone: TArray<string>;
    fBodies: TArray<TArea>;
    function ShiftBlocker(const aMap: TReferenceMap): string;
    function TablesBlocker(const aMap: TReferenceMap): string;
    function PivotsBlocker(const aMap: TReferenceMap): string;
    procedure KeepTableRows(var aMap: TReferenceMap; aCleared: TList<TArea>);
    procedure PlanTables(const aMap: TReferenceMap);
    procedure ShiftTables(const aMap: TReferenceMap);
    procedure ShiftPivots(const aMap: TReferenceMap);
    function PlanDrawings(const aMap: TReferenceMap; out aWhy: string): TList<TAnchorMove>;
    procedure ShiftDrawings(aMoves: TList<TAnchorMove>; const aMap: TReferenceMap);
    procedure ShiftCharts(aMoves: TList<TChartMove>; const aMap: TReferenceMap);
    procedure NotesParts(out aComments, aDrawing: string);
    function NotesBlocker(const aMap: TReferenceMap): string;
    procedure ShiftNotes(const aMap: TReferenceMap);
    function CopiedRow(aSource: TRowCT; aNumber: integer): TRowCT;
    procedure ShowRows(aTop, aBottom: integer);
    procedure ShiftColumnEntries(const aMap: TReferenceMap);
    procedure ShiftCells(const aMap: TReferenceMap);
    function LiftSpills(const aMap: TReferenceMap): TArray<TSpill>;
    procedure PlaceSpills(const aSpills: TArray<TSpill>; const aMap: TReferenceMap);
    procedure FitAgain(const aMap: TReferenceMap);
    procedure ShiftLists(const aMap: TReferenceMap);
    procedure ApplyFormulas(aMoves: TList<TFormulaMove>; aRefs: TDictionary<cardinal, string>; aShifted: boolean;
      const aMap: TReferenceMap);
    procedure FoldSpills(aMoves: TList<TFormulaMove>);
  public
    constructor Create(aWalk: TXlsxWalk; const aName: string; aStore: TXlsxSheet);
    // Excel's Insert and Delete of aMap's rows or columns: EInvalidOpException with why when refused, nothing changed
    procedure Shift(aMap: TReferenceMap);
    // the sheet out of the workbook as Excel deletes it: EInvalidOpException with why when refused, nothing changed
    procedure DeleteSheet;
  end;

  // the workbook's worksheets in order, for one insert or delete
  TXlsxWalk = class
  private
    fBook: TXlsxBook;
    fSheets: TObjectList<TXlsxWalkSheet>;
  public
    constructor Create(aBook: TXlsxBook);
    destructor Destroy; override;
    // the next worksheet: its name and its storage (borrowed)
    function Add(const aName: string; aStore: TXlsxSheet): TXlsxWalkSheet;
  end;

implementation

uses System.Math, System.TypInfo, System.RegularExpressions, ProRock.Calcite.Formulas,
  ProRock.Xmlite.Schema.Ooxml.DmlSheet, ProRock.Xmlite.Schema.Ooxml.DmlChart,
  ProRock.Xmlite.Schema.Ooxml.Vml, ProRock.Xmlite.Schema.Ooxml.VmlExcel;

type
  {$REGION 'ProRock.Xmlite.Schema.Ooxml types aliases'}
  // DrawingML and its charts have ones of these names too
  TMarkerCT = ProRock.Xmlite.Schema.Ooxml.DmlSheet.TMarkerCT;
  TExtensionCT = ProRock.Xmlite.Schema.Ooxml.DmlChart.TExtensionCT;
  {$ENDREGION}

constructor TXlsxWalk.Create(aBook: TXlsxBook);
begin
  inherited Create;
  fBook := aBook;
  fSheets := TObjectList<TXlsxWalkSheet>.Create;
end;

destructor TXlsxWalk.Destroy;
begin
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
  fWalk := aWalk;
  fBook := aWalk.fBook;
  fName := aName;
  fStore := aStore;
end;

// why Excel or Calcite does not insert or delete aMap's rows or columns, '' when nothing stands in the way
function TXlsxWalkSheet.ShiftBlocker(const aMap: TReferenceMap): string;
const
  cLater = ', which Calcite does not move yet';
  cNotYet = ', which Calcite does not do yet';
  cPushedOff = 'Microsoft Excel can''t insert new cells because it would push non-empty cells off the end of the ' +
    'worksheet. These non-empty cells might appear empty but have blank values, some formatting, or a formula. Delete ' +
    'enough rows or columns to make room for what you want to insert and then try again.';
  cElements: array[0 .. 7] of string = ('OleObjects', 'Controls', 'ExtLst', 'Scenarios',
    'DataConsolidate', 'CustomSheetViews', 'CellWatches', 'SmartTags');
  cWhat: array[0 .. 7] of string = ('embedded objects', 'controls',
    'Excel 2010''s extensions (conditional formats, validation, sparklines)', 'scenarios', 'a data consolidation',
    'custom views', 'watched cells', 'smart tags');

  function IsSpill(const aArea: TArea): boolean;
  begin
    for var spill: TArea in fStore.Areas(akSpill) do
      if (spill.Top = aArea.Top) and (spill.Left = aArea.Left) then
        Exit(True);
    Result := False;
  end;

begin
  var sheet: TWorksheetE := fStore.Objects(False);
  var last: integer := aMap.First - aMap.Delta - 1;
  var limit: integer := aMap.Limit;
  for var area: TArea in fStore.Areas(akArray) do
  begin
    var low: integer := IfThen(aMap.ByRows, area.Top, area.Left);
    var high: integer := IfThen(aMap.ByRows, area.Bottom, area.Right);
    if IsSpill(area) then
    begin // Excel moves the formula's cell and spills it again from there; with that cell it goes whole
      var moved: integer := aMap.MovedIndex(low);
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
            var along: integer := IfThen(aMap.ByRows, integer(row.R), TUtility.ColumnOf(cell.R));
            var across: integer := IfThen(aMap.ByRows, TUtility.ColumnOf(cell.R), integer(row.R));
            var place: integer := aMap.MovedIndex(along);
            if (place >= moved) and (place <= moved + high - low) and (across >= IfThen(aMap.ByRows, area.Left, area.Top)) and
              (across <= IfThen(aMap.ByRows, area.Right, area.Bottom)) then
              Exit(Format('cells moved into the spill of the dynamic array at %s (Excel shows #SPILL!)', [anchor]) +
                cNotYet);
          end;
      Continue;
    end;
    if (aMap.Delta > 0) and (aMap.First > low) and (aMap.First <= high) or
      (aMap.Delta < 0) and (aMap.First <= high) and (last >= low) and ((aMap.First > low) or (last < high)) then
      Exit('You can''t change part of an array.');
  end;
  if Length(fStore.Areas(akDataTable)) > 0 then
    Exit('a data table' + cLater);
  if aMap.Delta > 0 then // a cell with only a format there is dropped, as Excel drops it
    for var row: TRowCT in sheet.SheetData.Row do
      for var cell: TCellCT in row.C do
        if HasValue(cell) and (aMap.ByRows and (integer(row.R) > limit - aMap.Delta) or
          not aMap.ByRows and (TUtility.ColumnOf(cell.R) > limit - aMap.Delta)) then
          Exit(cPushedOff);
  Result := PivotsBlocker(aMap);
  if Result = '' then
    Result := TablesBlocker(aMap);
  if Result <> '' then
    Exit;
  for var i := 0 to High(cElements) do
    if sheet.IsPresent(cElements[i]) then
      Exit(cWhat[i] + cLater);
  Result := NotesBlocker(aMap);
end;

// aMap (rows or columns of aSheet) with aSheet's tables, for its own formulas (aOnSheet) or a name's: those deleted and
// their columns (structured references to them become #REF!), the ranges growing with them (PlanTables found them)
function SheetMap(aSheet: TXlsxWalkSheet; const aMap: TReferenceMap; aOnSheet: boolean = False): TReferenceMap;
begin
  Result := aMap;
  Result.OnSheet := aOnSheet;
  Result.InName := not aOnSheet;
  Result.GoneTables := aSheet.fGone;
  SetLength(Result.Bodies, Length(aSheet.fBodies) div 2);
  for var i := 0 to High(Result.Bodies) do
  begin
    Result.Bodies[i].Left := aSheet.fBodies[2 * i].Left;
    Result.Bodies[i].Right := aSheet.fBodies[2 * i].Right;
    Result.Bodies[i].Top := aSheet.fBodies[2 * i].Top;
    Result.Bodies[i].Bottom := aSheet.fBodies[2 * i].Bottom;
    Result.Bodies[i].DataTop := aSheet.fBodies[2 * i + 1].Top;
    Result.Bodies[i].DataBottom := aSheet.fBodies[2 * i + 1].Bottom;
  end;
end;

// aSheet's formulas through aMap (rows or columns of aShifted inserted or deleted, or a sheet deleted): each cell's that
// stays, its place and text then; shared formulas' areas by si; conditional formats' and validation's formulas that change.
// False with aWhy when one that may name aMap's sheet does not read
function PlanFormulas(aSheet: TXlsxWalkSheet; const aMap: TReferenceMap; aShifted: TXlsxWalkSheet;
  aMoves: TList<TXlsxWalkSheet.TFormulaMove>; aTexts: TList<TXlsxWalkSheet.TTextMove>; aRefs: TDictionary<cardinal, string>;
  out aWhy: string): boolean;
var
  map: TReferenceMap;

  function Changed(const aText, aWhere: string; out aResult: string): boolean;
  begin
    Result := True;
    var why: string;
    if ShiftFormula(aText, map, aResult, why) then
      Exit;
    aResult := aText;
    if (aShifted = aSheet) or aText.ToUpper.Contains(aMap.Sheet.ToUpper) then
    begin
      aWhy := Format('the formula of %s!%s does not read: %s', [aSheet.fName, aWhere, why]);
      Result := False;
    end;
  end;

  procedure AddText(aRule: TCfRuleCT; aValidation: TDataValidationCT; aIndex: integer; const aText, aWhere: string);
  begin
    var move: TXlsxWalkSheet.TTextMove := Default(TXlsxWalkSheet.TTextMove);
    if not Changed(DecodeText(aText), aWhere, move.Text) then
      Exit;
    if move.Text = DecodeText(aText) then
      Exit;
    move.Sheet := aSheet;
    move.Rule := aRule;
    move.Validation := aValidation;
    move.Index := aIndex;
    aTexts.Add(move);
  end;

begin
  Result := False;
  aWhy := '';
  map := aMap;
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
      var move: TXlsxWalkSheet.TFormulaMove;
      move.Cell := cell;
      move.Row := row.R;
      move.Column := TUtility.ColumnOf(cell.R);
      if not aSheet.fStore.FormulaText(move.Row, move.Column, move.Before) then
        Continue;
      if aShifted = aSheet then
        if aMap.ByRows then
          move.Row := aMap.MovedIndex(move.Row)
        else
          move.Column := aMap.MovedIndex(move.Column);
      if (move.Row = 0) or (move.Column = 0) then
        Continue;
      if not Changed(move.Before, cell.R, move.After) then
        Exit;
      aMoves.Add(move);
    end;
  for var formatting: TConditionalFormattingCT in sheet.ConditionalFormatting do
    for var rule: TCfRuleCT in formatting.CfRule do
      for var index := 0 to rule.Formula.Count - 1 do
      begin
        AddText(rule, nil, index, rule.Formula[index], formatting.Sqref);
        if aWhy <> '' then
          Exit;
      end;
  if sheet.IsPresent('DataValidations') then
    for var validation: TDataValidationCT in sheet.DataValidations.DataValidation do
    begin
      if validation.Formula1 <> '' then
        AddText(nil, validation, 1, validation.Formula1, validation.Sqref);
      if (aWhy = '') and (validation.Formula2 <> '') then
        AddText(nil, validation, 2, validation.Formula2, validation.Sqref);
      if aWhy <> '' then
        Exit;
    end;
  Result := True;
end;

// the conditional formats' and validation's formulas PlanFormulas changed written
procedure WriteTexts(aTexts: TList<TXlsxWalkSheet.TTextMove>);
begin
  for var move: TXlsxWalkSheet.TTextMove in aTexts do
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

procedure TXlsxWalkSheet.ShowRows(aTop, aBottom: integer);
begin
  for var row: TRowCT in fStore.RowEntries(aTop, aBottom) do
    row.Clear(@row.Hidden);
end;

// a row inserted as Excel does: the format and height of the row above (not hidden), its cells' styles where they differ
// from what the new row shows anyway; nil when there is nothing to copy
function TXlsxWalkSheet.CopiedRow(aSource: TRowCT; aNumber: integer): TRowCT;
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
procedure TXlsxWalkSheet.ShiftColumnEntries(const aMap: TReferenceMap);
begin
  var sheet: TWorksheetE := fStore.Objects(True);
  if sheet.Cols.Count = 0 then
    Exit;
  var columns: TColCTList := fStore.SortedColumns;
  var last: integer := aMap.First - aMap.Delta - 1;
  SplitColumns(columns, aMap.First);
  if aMap.Delta < 0 then
  begin
    if last < TUtility.cMaxColumn then
      SplitColumns(columns, last + 1);
    for var i := columns.Count - 1 downto 0 do
      if (integer(columns[i].Min) >= aMap.First) and (integer(columns[i].Max) <= last) then
        columns.Delete(i)
      else if integer(columns[i].Min) > last then
      begin
        columns[i].Min := integer(columns[i].Min) + aMap.Delta;
        columns[i].Max := integer(columns[i].Max) + aMap.Delta;
      end;
  end
  else
  begin
    var source: integer := -1;
    for var i := columns.Count - 1 downto 0 do
      if integer(columns[i].Min) >= aMap.First then
      begin
        if integer(columns[i].Min) + aMap.Delta > TUtility.cMaxColumn then
          columns.Delete(i)
        else
        begin
          columns[i].Min := integer(columns[i].Min) + aMap.Delta;
          columns[i].Max := Min(integer(columns[i].Max) + aMap.Delta, TUtility.cMaxColumn);
        end;
      end
      else if integer(columns[i].Max) = aMap.First - 1 then
        source := i;
    if source >= 0 then
      if not columns[source].Hidden and (columns[source].Width > 0) then
        columns[source].Max := integer(columns[source].Max) + aMap.Delta
      else
      begin
        var copy: TColCT := columns[source].Clone<TColCT>;
        copy.Min := aMap.First;
        copy.Max := aMap.First + aMap.Delta - 1;
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
procedure TXlsxWalkSheet.ShiftCells(const aMap: TReferenceMap);
begin
  var sheet: TWorksheetE := fStore.Objects(True);
  var rows: TRowCTList := sheet.SheetData.Row;
  var last: integer := aMap.First - aMap.Delta - 1;
  if aMap.ByRows then
  begin
    var index: integer;
    fStore.FindRow(sheet, aMap.First, index);
    if aMap.Delta < 0 then
      while (index < rows.Count) and (integer(rows[index].R) <= last) do
      begin
        for var cell: TCellCT in rows[index].C do
          fStore.RemoveValue(cell);
        rows.Delete(index);
      end
    else
      for var i := rows.Count - 1 downto index do
        if integer(rows[i].R) + aMap.Delta > TUtility.cMaxRow then // only formats there (ShiftBlocker)
          rows.Delete(i);
    for var i := index to rows.Count - 1 do
    begin
      var row: TRowCT := rows[i];
      row.R := integer(row.R) + aMap.Delta;
      for var cell: TCellCT in row.C do
        cell.R := TUtility.CellName(row.R, TUtility.ColumnOf(cell.R));
    end;
    var above: integer;
    if (aMap.Delta > 0) and (aMap.First > 1) and fStore.FindRow(sheet, aMap.First - 1, above) then
      for var number := aMap.First + aMap.Delta - 1 downto aMap.First do
      begin
        var added: TRowCT := CopiedRow(rows[above], number);
        if added <> nil then
          rows.Insert(above + 1, added);
      end;
    Exit;
  end;
  ShiftColumnEntries(aMap);
  for var row: TRowCT in rows do
  begin
    var cells: TCellCTList := row.C;
    var index: integer;
    FindInRow(row, aMap.First, index);
    if aMap.Delta < 0 then
      while (index < cells.Count) and (TUtility.ColumnOf(cells[index].R) <= last) do
      begin
        fStore.RemoveValue(cells[index]);
        cells.Delete(index);
      end
    else
      for var i := cells.Count - 1 downto index do
        if TUtility.ColumnOf(cells[i].R) + aMap.Delta > TUtility.cMaxColumn then
          cells.Delete(i);
    for var i := index to cells.Count - 1 do
      cells[i].R := TUtility.CellName(row.R, TUtility.ColumnOf(cells[i].R) + aMap.Delta);
    if (aMap.Delta > 0) and (index > 0) and (TUtility.ColumnOf(cells[index - 1].R) = aMap.First - 1) then
    begin
      var source: TCellCT := cells[index - 1];
      var shown: cardinal := fStore.ColumnStyle(aMap.First);
      if row.CustomFormat then
        shown := row.S;
      if source.S <> shown then
        for var column := aMap.First + aMap.Delta - 1 downto aMap.First do
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

// the dynamic arrays' spilled values taken out before rows or columns move (ShiftBlocker let them): Excel spills each again
// from its formula's cell, the formats stay with the cells
function TXlsxWalkSheet.LiftSpills(const aMap: TReferenceMap): TArray<TSpill>;
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
procedure TXlsxWalkSheet.PlaceSpills(const aSpills: TArray<TSpill>; const aMap: TReferenceMap);
begin
  for var spill: TSpill in aSpills do
  begin
    var moved: integer;
    if aMap.ByRows then
      moved := aMap.MovedIndex(spill.Area.Top)
    else
      moved := aMap.MovedIndex(spill.Area.Left);
    var top: integer := IfThen(aMap.ByRows, moved, spill.Area.Top);
    var left: integer := IfThen(aMap.ByRows, spill.Area.Left, moved);
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
procedure TXlsxWalkSheet.FitAgain(const aMap: TReferenceMap);
begin
  if aMap.ByRows then
    Exit;
  var rows: TRowCTList := fStore.Objects(False).SheetData.Row;
  var moved: boolean := False;
  for var row: TRowCT in rows do
    if (row.C.Count > 0) and (TUtility.ColumnOf(row.C[row.C.Count - 1].R) >= aMap.First) then
      moved := True;
  if not moved and (aMap.Delta > 0) then
    for var area: TArea in fStore.Areas(akMerge) do
      if (area.Left < aMap.First) and (area.Right >= aMap.First) then
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

// an autofilter's columns through columns inserted or deleted (its first one was aOldLeft, is aLeft): True when the last
// filter went with them - Excel then shows the rows it hid
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
procedure TXlsxWalkSheet.ShiftLists(const aMap: TReferenceMap);
var
  sheet: TWorksheetE;
  last: integer;

  function Sqref(const aText: string; aGrowAfter: boolean = False): string;
  begin
    Result := aMap.MovedSqref(aText, aGrowAfter);
  end;

  function SortKept(aSort: TSortStateCT): boolean;
  begin
    var ref: string := Sqref(aSort.Ref);
    if ref = '' then
      Exit(False);
    aSort.Ref := ref;
    for var i := aSort.SortCondition.Count - 1 downto 0 do
    begin
      ref := Sqref(aSort.SortCondition[i].Ref);
      if ref = '' then
        aSort.SortCondition.Delete(i)
      else
        aSort.SortCondition[i].Ref := ref;
    end;
    Result := aSort.SortCondition.Count > 0;
  end;

  procedure ShiftBreaks(aBreaks: TPageBreakCT; const aName: string);
  begin
    for var i := aBreaks.Brk.Count - 1 downto 0 do
    begin
      var id: integer := aMap.MovedIndex(aBreaks.Brk[i].Id);
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
  last := aMap.First - aMap.Delta - 1;
  if sheet.IsPresent('MergeCells') then
  begin
    var merged: TMergeCellCTList := sheet.MergeCells.MergeCell;
    for var i := merged.Count - 1 downto 0 do
    begin
      var area: TArea;
      if TArea.TryParse(merged[i].Ref, area) then
        if aMap.MovedArea(area) and ((area.Top <> area.Bottom) or (area.Left <> area.Right)) then
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
  for var i := sheet.ConditionalFormatting.Count - 1 downto 0 do
  begin
    var ref: string := Sqref(sheet.ConditionalFormatting[i].Sqref, True);
    if ref = '' then
      sheet.ConditionalFormatting.Delete(i)
    else
      sheet.ConditionalFormatting[i].Sqref := ref;
  end;
  if sheet.IsPresent('DataValidations') then
  begin
    var validations: TDataValidationCTList := sheet.DataValidations.DataValidation;
    for var i := validations.Count - 1 downto 0 do
    begin
      var ref: string := Sqref(validations[i].Sqref, True);
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
  if sheet.IsPresent('Hyperlinks') then
  begin
    var links: THyperlinkCTList := sheet.Hyperlinks.Hyperlink;
    for var i := links.Count - 1 downto 0 do
    begin
      var ref: string := Sqref(links[i].Ref);
      if ref = '' then
        links.Delete(i)
      else
        links[i].Ref := ref;
    end;
    if links.Count = 0 then
      sheet.Clear('Hyperlinks');
  end;
  var filterGone: boolean := False;
  if sheet.IsPresent('AutoFilter') then
  begin
    var filter: TAutoFilterCT := sheet.AutoFilter;
    var area: TArea;
    if TArea.TryParse(filter.Ref, area) then
    begin
      var oldLeft: integer := area.Left;
      if aMap.ByRows and (aMap.Delta < 0) and (aMap.First <= area.Top) and (last >= area.Top) or
        not aMap.MovedArea(area) then
      begin
        sheet.Clear('AutoFilter');
        filterGone := True;
      end
      else
      begin
        filter.Ref := area.CellsAddress;
        if not aMap.ByRows and ShiftFilterColumns(filter, oldLeft, area.Left, aMap) then
          ShowRows(area.Top + 1, area.Bottom);
        if filter.IsPresent('SortState') and not SortKept(filter.SortState) then
          filter.Clear('SortState');
      end;
    end;
  end;
  if sheet.IsPresent('SortState') and not SortKept(sheet.SortState) then
    sheet.Clear('SortState');
  if sheet.IsPresent('IgnoredErrors') then
  begin
    var errors: TIgnoredErrorCTList := sheet.IgnoredErrors.IgnoredError;
    for var i := errors.Count - 1 downto 0 do
    begin
      var ref: string := Sqref(errors[i].Sqref);
      if ref = '' then
        errors.Delete(i)
      else
        errors[i].Sqref := ref;
    end;
    if errors.Count = 0 then
      sheet.Clear('IgnoredErrors');
  end;
  if sheet.IsPresent('ProtectedRanges') then
  begin
    var ranges: TProtectedRangeCTList := sheet.ProtectedRanges.ProtectedRange;
    for var i := ranges.Count - 1 downto 0 do
    begin
      var ref: string := Sqref(ranges[i].Sqref);
      if ref = '' then
        ranges.Delete(i)
      else
        ranges[i].Sqref := ref;
    end;
    if ranges.Count = 0 then
      sheet.Clear('ProtectedRanges');
  end;
  if aMap.ByRows and sheet.IsPresent('RowBreaks') then
    ShiftBreaks(sheet.RowBreaks, 'RowBreaks');
  if not aMap.ByRows and sheet.IsPresent('ColBreaks') then
    ShiftBreaks(sheet.ColBreaks, 'ColBreaks');
  if sheet.IsPresent('SheetViews') then
    for var view: TSheetViewCT in sheet.SheetViews.SheetView do
      if view.IsPresent('Pane') and (view.Pane.State in [stpsFrozen, stpsFrozenSplit]) then
      begin
        var pane: TPaneCT := view.Pane;
        var split: integer := Trunc(pane.XSplit);
        if aMap.ByRows then
          split := Trunc(pane.YSplit);
        if (split = 0) or (aMap.First > split) then
          Continue;
        var moved: integer := split + aMap.Delta;
        if aMap.Delta < 0 then
          moved := Max(1, split - (Min(last, split) - aMap.First + 1));
        var at: TArea;
        if aMap.ByRows then
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
  if sheet.IsPresent('Dimension') then
  begin
    var area: TArea;
    if TArea.TryParse(sheet.Dimension.Ref, area) then
      if aMap.MovedArea(area) then
        sheet.Dimension.Ref := area.CellsAddress
      else
        sheet.Dimension.Ref := 'A1';
  end;
  if filterGone then // and its hidden name with it
  begin
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
end;

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

{ TXlsxWalkSheet.TAxis }

constructor TXlsxWalkSheet.TAxis.Create(aSheet: TXlsxWalkSheet; aByRows: boolean);
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
  fDefault := Emus(aSheet.fStore.AxisDefault(aByRows));
  for var entry: TPair<integer, TAxisFormat> in aSheet.fStore.AxisEntries(aByRows) do
    fSizes.Add(TPair<integer, Int64>.Create(entry.Key, Emus(entry.Value)));
end;

destructor TXlsxWalkSheet.TAxis.Destroy;
begin
  fSizes.Free;
  inherited;
end;

function TXlsxWalkSheet.TAxis.Start(aIndex: integer): Int64;
begin
  Result := fDefault * aIndex;
  for var size: TPair<integer, Int64> in fSizes do
    if size.Key <= aIndex then
      Inc(Result, size.Value - fDefault)
    else
      Break;
end;

procedure TXlsxWalkSheet.TAxis.Find(aPosition: Int64; out aIndex: integer; out aOffset: Int64);
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
function TXlsxWalkSheet.TablesBlocker(const aMap: TReferenceMap): string;
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
      if (aLeft + integer(column.ColId) >= aMap.First) and (aLeft + integer(column.ColId) <= last) then
        Inc(deleted);
    Result := not aMap.ByRows and (aMap.Delta < 0) and (deleted > 0) and (deleted < aFilter.FilterColumn.Count);
  end;

  // rows passing through it: an insert below its first row, a delete taking any
  function Through(const aArea: TArea): boolean;
  begin
    Result := aMap.ByRows and ((aMap.Delta > 0) and (aMap.First > aArea.Top) and (aMap.First <= aArea.Bottom) or
      (aMap.Delta < 0) and (aMap.First <= aArea.Bottom) and (last >= aArea.Top));
  end;

begin
  last := aMap.First - aMap.Delta - 1;
  var package: TPackageOoxml := fBook.Package;
  for var relationship: TRelationshipOoxml in package.Relationships(fStore.Part) do
    if relationship.&Type.EndsWith(cTable) then
    begin
      var table: TTableE := package.Part<TTableE>(relationship.Part);
      var area: TArea;
      if (table = nil) or not TArea.TryParse(table.Ref, area) then
        Exit(Format('a table that does not read (%s)', [relationship.Part]));
      if IfThen(aMap.ByRows, area.Bottom, area.Right) < aMap.First then
        Continue;
      if table.TableType <> stttWorksheet then
        Exit(Format('a table from a query or an XML map (%s, %s), which Calcite does not move yet', [table.Name,
          area.CellsAddress]));
      if aMap.ByRows and (aMap.Delta < 0) and (table.HeaderRowCount > 0) and (aMap.First < area.Top + integer(table.HeaderRowCount)) and
        (last >= area.Top) and ((aMap.First > area.Top) or (last < area.Bottom)) then
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

// Excel's refusal of a pivot table cut (its page fields above it count), '' when none is
function TXlsxWalkSheet.PivotsBlocker(const aMap: TReferenceMap): string;
begin
  var last: integer := aMap.First - aMap.Delta - 1;
  for var area: TArea in fStore.Areas(akPivot) do
  begin
    var low: integer := IfThen(aMap.ByRows, area.Top, area.Left);
    var high: integer := IfThen(aMap.ByRows, area.Bottom, area.Right);
    if (aMap.Delta > 0) and (aMap.First > low) and (aMap.First <= high) or
      (aMap.Delta < 0) and (aMap.First <= high) and (last >= low) and ((aMap.First > low) or (last < high)) then
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

// a delete taking all the data rows of a table whose header stays: Excel keeps the first of them, emptied (aCleared), and
// deletes the rest
procedure TXlsxWalkSheet.KeepTableRows(var aMap: TReferenceMap; aCleared: TList<TArea>);
begin
  var last: integer := aMap.First - aMap.Delta - 1;
  var package: TPackageOoxml := fBook.Package;
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
        aCleared.Add(area);
      end;
    end;
  if aCleared.Count > 0 then
  begin
    Inc(aMap.First);
    Dec(aMap.Count);
  end;
end;

// the tables and table columns the change deletes (fGone), for the formulas naming them
procedure TXlsxWalkSheet.PlanTables(const aMap: TReferenceMap);
begin
  fGone := nil;
  fBodies := nil;
  var last: integer := aMap.First - aMap.Delta - 1;
  var package: TPackageOoxml := fBook.Package;
  for var relationship: TRelationshipOoxml in package.Relationships(fStore.Part) do
    if relationship.&Type.EndsWith(cTable) then
    begin
      var table: TTableE := package.Part<TTableE>(relationship.Part);
      var area: TArea;
      if not TArea.TryParse(table.Ref, area) then
        Continue;
      var data: TArea := area;
      data.Top := area.Top + integer(table.HeaderRowCount);
      data.Bottom := area.Bottom - integer(table.TotalsRowCount);
      fBodies := fBodies + [area, data];
      if aMap.Delta > 0 then
        Continue;
      if not aMap.MovedArea(area) then
        fGone := fGone + [string(table.Name)]
      else if not aMap.ByRows then
      begin
        TArea.TryParse(table.Ref, area);
        for var index := 0 to table.TableColumns.TableColumn.Count - 1 do
          if (area.Left + index >= aMap.First) and (area.Left + index <= last) then
            fGone := fGone + [table.Name + '[' + table.TableColumns.TableColumn[index].Name + ']'];
      end;
    end;
end;

// the sheet's tables as Excel moves them: grown by rows or columns inserted inside (new columns named Column1...; new rows
// take the calculated columns' formulas), shrunk, gone with all their rows or columns; the totals row deleted, the table
// keeps none; the autofilter, its columns and sort follow
procedure TXlsxWalkSheet.ShiftTables(const aMap: TReferenceMap);
var
  sheet: TWorksheetE;
  last: integer;

  function Changed(const aText: string): string;
  begin
    var why: string;
    if not ShiftFormula(aText, SheetMap(Self, aMap, True), Result, why) then
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
  last := aMap.First - aMap.Delta - 1;
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
    if not aMap.MovedArea(area) then
    begin
      Remove(relationship);
      Continue;
    end;
    var columns: TTableColumnCTList := table.TableColumns.TableColumn;
    var added: TArray<integer> := nil; // the new columns' numbers on the sheet
    if not aMap.ByRows and (aMap.Delta < 0) then
    begin
      for var index := columns.Count - 1 downto 0 do
        if (old.Left + index >= aMap.First) and (old.Left + index <= last) then
          columns.Delete(index);
    end
    else if not aMap.ByRows and (aMap.First > old.Left) and (aMap.First <= old.Right) then
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
        for var index := 0 to aMap.Delta - 1 do
        begin
          while names.IndexOf('Column' + IntToStr(number)) >= 0 do
            Inc(number);
          var column: TTableColumnCT := TTableColumnCT.Create;
          Inc(id);
          column.Id := id;
          column.Name := 'Column' + IntToStr(number);
          names.Add(column.Name);
          columns.Insert(aMap.First - old.Left + index, column);
          added := added + [aMap.First + index];
        end;
      finally
        names.Free;
      end;
    end;
    table.TableColumns.Count := columns.Count;
    if aMap.ByRows and (aMap.Delta < 0) and (table.TotalsRowCount > 0) and (old.Bottom >= aMap.First) and (old.Bottom <= last) then
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
    if aMap.ByRows and (aMap.Delta > 0) and (aMap.First > old.Top) and (aMap.First <= old.Bottom) then
      for var index := 0 to columns.Count - 1 do
        if columns[index].IsPresent('CalculatedColumnFormula') and not columns[index].CalculatedColumnFormula.&Array then
        begin
          var text: string := DecodeText(columns[index].CalculatedColumnFormula.XmlValue);
          for var row := Max(aMap.First, dataTop) to Min(aMap.First + aMap.Delta - 1, dataBottom) do
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
      if not aMap.ByRows and ShiftFilterColumns(filter, old.Left, area.Left, aMap) then
        ShowRows(dataTop, dataBottom);
    end;
    if table.IsPresent('SortState') then
    begin
      var sort: TSortStateCT := table.SortState;
      var ref: string := aMap.MovedSqref(sort.Ref);
      if ref <> '' then
      begin
        sort.Ref := ref;
        for var i := sort.SortCondition.Count - 1 downto 0 do
        begin
          var condition: string := aMap.MovedSqref(sort.SortCondition[i].Ref);
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

// pivot tables on the sheet moved (gone when deleted whole) and the caches' sources on it grown or shrunk, as Excel does;
// a source deleted whole keeps its ref, as in Excel
procedure TXlsxWalkSheet.ShiftPivots(const aMap: TReferenceMap);
begin
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
      if not aMap.MovedArea(whole) then
      begin
        var folder: integer := relationship.Part.LastIndexOf('/') + 1;
        package.RemovePart(relationship.Part, relationship.Part.Substring(0, folder) + '_rels/' +
          relationship.Part.Substring(folder) + '.rels');
        package.RemovePart(fStore.Part, relationship.Part);
      end
      else if aMap.MovedArea(area) then
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
      var ref: string := aMap.MovedSqref(source.Ref);
      if (ref <> '') and (ref <> source.Ref) then
        package.EditPart<TPivotCacheDefinitionE>(relationship.Part).CacheSource.WorksheetSource.Ref := ref;
    end;
end;

// the drawings' objects and where they start and end along the shifted axis before the change; aWhy for a drawing that
// does not read
function TXlsxWalkSheet.PlanDrawings(const aMap: TReferenceMap; out aWhy: string): TList<TAnchorMove>;
begin
  Result := TList<TAnchorMove>.Create;
  aWhy := '';
  var package: TPackageOoxml := fBook.Package;
  var axis: TAxis := nil;
  try
    for var relationship: TRelationshipOoxml in package.Relationships(fStore.Part) do
      if relationship.&Type.EndsWith(cDrawing) then
      begin
        var drawing: TWsDrE := package.Part<TWsDrE>(relationship.Part);
        if drawing = nil then
        begin
          aWhy := Format('a drawing that does not read (%s)', [relationship.Part]);
          Exit;
        end;
        if axis = nil then
          axis := TAxis.Create(Self, aMap.ByRows);
        for var anchor: TTwoCellAnchorCT in drawing.TwoCellAnchor do
        begin
          var move: TAnchorMove := Default(TAnchorMove);
          move.Part := relationship.Part;
          move.Anchor := anchor;
          var fromIndex, toIndex: integer;
          var fromOffset, toOffset: Int64;
          if not MarkerPlace(anchor.From, aMap.ByRows, fromIndex, fromOffset) or
            not MarkerPlace(anchor.&To, aMap.ByRows, toIndex, toOffset) then
          begin
            aWhy := Format('a drawing''s object whose place does not read (%s)', [relationship.Part]);
            Exit;
          end;
          move.From := axis.Start(fromIndex) + fromOffset;
          move.&To := axis.Start(toIndex) + toOffset;
          Result.Add(move);
        end;
        for var anchor: TOneCellAnchorCT in drawing.OneCellAnchor do
        begin
          var move: TAnchorMove := Default(TAnchorMove);
          move.Part := relationship.Part;
          move.Anchor := anchor;
          var index: integer;
          var offset: Int64;
          if not MarkerPlace(anchor.From, aMap.ByRows, index, offset) then
          begin
            aWhy := Format('a drawing''s object whose place does not read (%s)', [relationship.Part]);
            Exit;
          end;
          Result.Add(move);
        end;
      end;
  finally
    axis.Free;
  end;
end;

// the drawings' objects as Excel moves them: move and size with cells (twoCell) - each end with its cell, gone when its
// rows or columns are deleted whole; move only (oneCell) - its start with its cell, its size kept; free (absolute) -
// where it was; xdr:oneCellAnchor's start with its cell
procedure TXlsxWalkSheet.ShiftDrawings(aMoves: TList<TAnchorMove>; const aMap: TReferenceMap);
var
  last, limit: integer;
  axis: TAxis;

  // a marker with its cell: one deleted goes to the start of what follows (its offset as written otherwise)
  procedure MoveMarker(aMarker: TMarkerCT);
  begin
    var index: integer;
    var offset: Int64;
    MarkerPlace(aMarker, aMap.ByRows, index, offset);
    var moved: integer := aMap.MovedIndex(index + 1);
    if (moved = 0) and (aMap.Delta < 0) then
      PlaceMarker(aMarker, aMap.ByRows, aMap.First - 1, 0)
    else if aMap.ByRows then
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
    PlaceMarker(aMarker, aMap.ByRows, index, offset);
  end;

  // the marker's row or column among the deleted ones (an end: at the start of the one after them too)
  function Deleted(aMarker: TMarkerCT; aEnd: boolean): boolean;
  begin
    var index: integer;
    var offset: Int64;
    MarkerPlace(aMarker, aMap.ByRows, index, offset);
    Inc(index);
    Result := (aMap.Delta < 0) and ((index >= aMap.First) and (index <= last) or aEnd and (index = last + 1) and (offset = 0));
  end;

begin
  if aMoves.Count = 0 then
    Exit;
  last := aMap.First - aMap.Delta - 1;
  limit := aMap.Limit;
  var package: TPackageOoxml := fBook.Package;
  axis := TAxis.Create(Self, aMap.ByRows);
  try
    for var move: TAnchorMove in aMoves do
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
            MarkerPlace(anchor.From, aMap.ByRows, index, offset);
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
    Result := Format('%s!%d,%d', [AnsiUpperCase(aCell.Sheet), aCell.Row, aCell.Column]);
  end;

begin
  aIndexes := nil;
  aTotal := 0;
  var before, after: TArray<TChartCell>;
  Result := ChartCells(aBefore, before) and ChartCells(aAfter, after);
  if not Result then
    Exit;
  var places: TDictionary<string, integer> := TDictionary<string, integer>.Create;
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

function XmlTextDecoded(const aText: string): string;
begin
  Result := aText.Replace('&lt;', '<').Replace('&gt;', '>').Replace('&quot;', '"').Replace('&apos;', '''').
    Replace('&amp;', '&');
end;

function XmlTextEncoded(const aText: string): string;
begin
  Result := aText.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;');
end;

// an element kept as read with its f and sqref texts (formulas, any prefix) through aMap; False with aWhy when one naming
// aSheet does not read
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
      if text.ToUpper.Contains(aSheet.ToUpper) then
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

// every chart's references to cells (on every sheet and chart sheet; but aSheet's when it is deleted) through aMap, aSheet's
// rows or columns inserted or deleted as a defined name's (absolute ones), or aSheet deleted; False with aWhy for a chart that
// does not read, or a reference naming the sheet that does not
function PlanCharts(aSheet: TXlsxWalkSheet; const aMap: TReferenceMap; aMoves: TList<TXlsxWalkSheet.TChartMove>;
  out aWhy: string): boolean;
begin
  Result := False;
  aWhy := '';
  var package: TPackageOoxml := aSheet.fBook.Package;
  var drawings: TList<string> := TList<string>.Create;
  var charts: TList<string> := TList<string>.Create;
  var found: TList<TXmlite> := TList<TXmlite>.Create;
  var seen: TDictionary<TBasite, boolean> := TDictionary<TBasite, boolean>.Create;
  try
    var owners: TList<string> := TList<string>.Create;
    try
      for var sheet: TXlsxWalkSheet in aSheet.fWalk.fSheets do
        if (sheet <> aSheet) or (aMap.Change <> TReferenceChange.rcSheetDelete) then
          owners.Add(sheet.fStore.Part);
      for var relationship: TRelationshipOoxml in package.Relationships(aSheet.fBook.WorkbookPart) do
        if relationship.&Type.EndsWith(cChartsheet) and (relationship.Part <> '') then
          owners.Add(relationship.Part);
      for var owner: string in owners do
        for var relationship: TRelationshipOoxml in package.Relationships(owner) do
          if relationship.&Type.EndsWith(cDrawing) and (relationship.Part <> '') and not drawings.Contains(relationship.Part) then
            drawings.Add(relationship.Part);
    finally
      owners.Free;
    end;
    for var drawing: string in drawings do
      for var relationship: TRelationshipOoxml in package.Relationships(drawing) do
        if relationship.&Type.EndsWith(cChartEx) then
        begin
          aWhy := 'charts of Excel 2016''s kinds (chartEx), which Calcite does not move yet';
          Exit;
        end
        else if relationship.&Type.EndsWith(cChart) and (relationship.Part <> '') and not charts.Contains(relationship.Part) then
          charts.Add(relationship.Part);
    for var part: string in charts do
    begin
      var chart: TChartSpaceE := package.Part<TChartSpaceE>(part);
      if chart = nil then
      begin
        aWhy := Format('a chart that does not read (%s)', [part]);
        Exit;
      end;
      found.Clear;
      seen.Clear;
      ChartReferences(chart, found, seen);
      for var reference: TXmlite in found do
        if reference is TExtensionCT then
        begin
          for var index := 0 to reference.XmlUnknown.Count - 1 do
          begin
            var move: TXlsxWalkSheet.TChartMove := Default(TXlsxWalkSheet.TChartMove);
            move.Before := reference.XmlUnknown[index].Xml;
            var why: string;
            if not MappedKeptXml(move.Before, aSheet.fName, aMap, move.After, why) then
            begin
              aWhy := Format('a formula of the chart %s does not read: %s', [part, why]);
              Exit;
            end;
            if move.After = move.Before then
              Continue;
            move.Part := part;
            move.Reference := reference;
            move.Index := index;
            aMoves.Add(move);
          end;
        end
        else
        begin
          var move: TXlsxWalkSheet.TChartMove := Default(TXlsxWalkSheet.TChartMove);
          move.Before := ChartFormula(reference);
          var why: string;
          if not ShiftFormula(move.Before, aMap, move.After, why) then
          begin
            if move.Before.ToUpper.Contains(aSheet.fName.ToUpper) then
            begin
              aWhy := Format('the formula %s of the chart %s does not read: %s', [move.Before, part, why]);
              Exit;
            end;
            Continue;
          end;
          if move.After = move.Before then
            Continue;
          move.Part := part;
          move.Reference := reference;
          move.Index := -1;
          aMoves.Add(move);
        end;
    end;
    Result := True;
  finally
    seen.Free;
    found.Free;
    charts.Free;
    drawings.Free;
  end;
end;

// the planned chart references written; their cached points follow their cells
procedure TXlsxWalkSheet.ShiftCharts(aMoves: TList<TChartMove>; const aMap: TReferenceMap);
begin
  var package: TPackageOoxml := fBook.Package;
  for var move: TChartMove in aMoves do
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
    var points: boolean := ChartPoints(move.Before, move.After, fName, aMap, indexes, total);
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

// the sheet's notes: its comments part and the VML drawing its legacyDrawing names ('' - none)
procedure TXlsxWalkSheet.NotesParts(out aComments, aDrawing: string);
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
function TXlsxWalkSheet.NotesBlocker(const aMap: TReferenceMap): string;
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
  var limit: integer := aMap.Limit;
  if commentsPart <> '' then
  begin
    var comments: TCommentsE := package.Part<TCommentsE>(commentsPart);
    if comments = nil then
      Exit(Format('notes that do not read (%s)', [commentsPart]));
    if aMap.Delta > 0 then
      for var comment: TCommentCT in comments.CommentList.Comment do
      begin
        var at: TArea;
        if TArea.TryParse(comment.Ref, at) and (IfThen(aMap.ByRows, at.Top, at.Left) > limit - aMap.Delta) then
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
procedure TXlsxWalkSheet.ShiftNotes(const aMap: TReferenceMap);
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
      var index: integer := IfThen(aMap.ByRows, at.Top, at.Left);
      var moved: integer := aMap.MovedIndex(index);
      if moved = index then
        Continue;
      if not edited then
        package.EditPart<TCommentsE>(commentsPart);
      edited := True;
      if moved = 0 then
        comments.CommentList.Comment.Remove(comment)
      else if aMap.ByRows then
        comment.Ref := TUtility.CellName(moved, at.Left)
      else
        comment.Ref := TUtility.CellName(at.Top, moved);
    end;
    notesLeft := comments.CommentList.Comment.Count > 0;
  end;
  if drawingPart <> '' then
  begin
    var drawing: TVmlDrawing := package.Part<TVmlDrawing>(drawingPart);
    var axis: TAxis := TAxis.Create(Self, aMap.ByRows);
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
        var first: integer := IfThen(aMap.ByRows, 2, 0); // the start's index; its offset next, the end's 4 on
        var index: integer := IfThen(aMap.ByRows, row, column);
        var moved: integer := aMap.MovedIndex(index);
        if moved <> 0 then
          Inc(shapes);
        if (moved = index) and (anchor[first + 4] < aMap.First - 1) then
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
        if aMap.ByRows then
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
        if aMap.ByRows then
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

// the planned formulas written: a shared formula stays one while its cells still fill from its first cell's text (that cell
// gone, the next one is first) and it names no #REF! (Excel makes those plain), else each cell gets its own; aShifted: this
// sheet's rows or columns moved
procedure TXlsxWalkSheet.ApplyFormulas(aMoves: TList<TFormulaMove>; aRefs: TDictionary<cardinal, string>; aShifted: boolean;
  const aMap: TReferenceMap);
begin
  var groups: TObjectDictionary<cardinal, TList<integer>> := TObjectDictionary<cardinal, TList<integer>>.Create([doOwnsValues]);
  try
    for var index := 0 to aMoves.Count - 1 do
    begin
      var move: TFormulaMove := aMoves[index];
      var formula: TCellFormulaCT := move.Cell.F;
      if formula.T = stcftShared then
      begin
        var members: TList<integer>;
        if not groups.TryGetValue(formula.Si, members) then
        begin
          members := TList<integer>.Create;
          groups.Add(formula.Si, members);
        end;
        members.Add(index);
        Continue;
      end;
      if move.After <> move.Before then
      begin
        fStore.Objects(True);
        formula.XmlValue := EncodeText(move.After);
      end;
      var area: TArea;
      if aShifted and (formula.T = stcftArray) and TArea.TryParse(formula.Ref, area) then
        if (move.Cell.Cm > 0) and fBook.IsDynamicArray(move.Cell.Cm) then
        begin // spilled again from its cell, as large as before
          var moved: TArea := area;
          moved.Top := move.Row;
          moved.Left := move.Column;
          moved.Bottom := move.Row + area.Bottom - area.Top;
          moved.Right := move.Column + area.Right - area.Left;
          formula.Ref := moved.CellsAddress;
        end
        else if aMap.MovedArea(area) then
          formula.Ref := area.CellsAddress;
    end;
    for var group: TPair<cardinal, TList<integer>> in groups do
    begin
      var members: TList<integer> := group.Value;
      var changed: boolean := aShifted;
      for var index: integer in members do
        changed := changed or (aMoves[index].After <> aMoves[index].Before);
      if not changed then
        Continue;
      fStore.Objects(True);
      var first: TFormulaMove := aMoves[members[0]];
      var area: TArea;
      var ref: string;
      var shared: boolean := not first.After.Contains('#REF!') and aRefs.TryGetValue(group.Key, ref) and
        TArea.TryParse(ref, area) and
        (not aShifted or aMap.MovedArea(area));
      for var index: integer in members do
      begin
        var move: TFormulaMove := aMoves[index];
        var filled, why: string;
        shared := shared and ShiftFormula(first.After, TReferenceMap.Fill(move.Row - first.Row, move.Column - first.Column),
          filled, why) and (filled = move.After);
      end;
      for var index: integer in members do
      begin
        var formula: TCellFormulaCT := aMoves[index].Cell.F;
        if not shared then
        begin
          formula.Clear('T');
          formula.Clear('Si');
          formula.Clear('Ref');
          formula.XmlValue := EncodeText(aMoves[index].After);
        end
        else if index = members[0] then
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
  finally
    groups.Free;
  end;
end;

// every defined name, print areas and titles too, changed as Excel changes references for aMap's rows or columns inserted
// or deleted. False with aWhy and nothing changed when one naming aMap's sheet does not read
function ChangeNames(aWalk: TXlsxWalk; const aMap: TReferenceMap; out aWhy: string): boolean;
begin
  var map: TReferenceMap := aMap;
  for var sheet: TXlsxWalkSheet in aWalk.fSheets do
    if AnsiSameText(sheet.fName, aMap.Sheet) then
      map := SheetMap(sheet, aMap);
  var changed: TArray<string>;
  Result := aWalk.fBook.MappedNames(map, changed, aWhy);
  if Result then
    aWalk.fBook.WriteNames(changed);
end;

// Excel's Insert and Delete of aMap's rows or columns: all checked and planned first, so a refusal changes nothing
procedure TXlsxWalkSheet.Shift(aMap: TReferenceMap);
begin
  var last: integer := aMap.First + aMap.Count - 1;
  var what: string := Format('Columns %s:%s', [TUtility.ColumnName(aMap.First), TUtility.ColumnName(last)]);
  if aMap.ByRows then
    what := Format('Rows %d:%d', [aMap.First, last]);
  var cleared: TList<TArea> := TList<TArea>.Create;
  var anchors: TList<TAnchorMove> := nil;
  var moves: TObjectList<TList<TFormulaMove>> := TObjectList<TList<TFormulaMove>>.Create;
  var refs: TObjectList<TDictionary<cardinal, string>> := TObjectList<TDictionary<cardinal, string>>.Create;
  var texts: TList<TTextMove> := TList<TTextMove>.Create;
  var charts: TList<TChartMove> := TList<TChartMove>.Create;
  try
    if aMap.ByRows and (aMap.Change = TReferenceChange.rcDelete) then
      KeepTableRows(aMap, cleared);
    var why: string := '';
    if aMap.Count <> 0 then
      why := ShiftBlocker(aMap);
    if why = '' then
    begin
      PlanTables(aMap);
      anchors := PlanDrawings(aMap, why);
    end;
    if (why = '') and (aMap.Count <> 0) then
      PlanCharts(Self, SheetMap(Self, aMap), charts, why);
    if (why = '') and (aMap.Count <> 0) then
      for var sheet: TXlsxWalkSheet in fWalk.fSheets do
      begin
        moves.Add(TList<TFormulaMove>.Create);
        refs.Add(TDictionary<cardinal, string>.Create);
        if not PlanFormulas(sheet, SheetMap(Self, aMap), Self, moves.Last, texts, refs.Last, why) then
          Break;
      end;
    if (why = '') and (aMap.Count <> 0) then
      ChangeNames(fWalk, aMap, why);
    if why <> '' then
    begin
      var done: string := 'deleted';
      if aMap.Change = TReferenceChange.rcInsert then
        done := 'inserted';
      raise EInvalidOpException.CreateFmt('%s of %s not %s: %s', [what, fName, done, why]);
    end;
    WriteTexts(texts);
    if aMap.Count <> 0 then
    begin
      FitAgain(aMap);
      var spills: TArray<TSpill> := LiftSpills(aMap);
      ShiftCells(aMap);
      PlaceSpills(spills, aMap);
      ShiftLists(aMap);
      for var index := 0 to fWalk.fSheets.Count - 1 do
        fWalk.fSheets[index].ApplyFormulas(moves[index], refs[index], fWalk.fSheets[index] = Self,
          aMap);
      ShiftTables(aMap);
      ShiftPivots(aMap);
      ShiftDrawings(anchors, aMap);
      ShiftCharts(charts, aMap);
      ShiftNotes(aMap);
    end;
    for var area: TArea in cleared do
      for var row: TRowCT in fStore.RowEntries(area.Top, area.Bottom) do
        for var cell: TCellCT in row.C do
          if (TUtility.ColumnOf(cell.R) >= area.Left) and (TUtility.ColumnOf(cell.R) <= area.Right) then
            fStore.RemoveValue(cell);
  finally
    fGone := nil;
    fBodies := nil;
    charts.Free;
    texts.Free;
    refs.Free;
    moves.Free;
    anchors.Free;
    cleared.Free;
  end;
  for var sheet: TXlsxWalkSheet in fWalk.fSheets do // edited as objects; other sheets' shared formulas may be plain now
    sheet.fStore.Forget;
  fBook.ValueChanged;
  fBook.FormulaChanged;
end;

// a dynamic array whose formula now names #REF! gives #REF! alone, as Excel calculates it: its spill folded into its cell
procedure TXlsxWalkSheet.FoldSpills(aMoves: TList<TFormulaMove>);
begin
  for var move: TFormulaMove in aMoves do
  begin
    var cell: TCellCT := move.Cell;
    var area: TArea;
    if (move.After = move.Before) or not move.After.Contains('#REF!') or (cell.F.T <> stcftArray) or (cell.Cm = 0) or
      not fBook.IsDynamicArray(cell.Cm) or not TArea.TryParse(cell.F.Ref, area) then
      Continue;
    fStore.Objects(True);
    for var row: TRowCT in fStore.RowEntries(area.Top, area.Bottom) do
      for var i := row.C.Count - 1 downto 0 do
      begin
        var spilled: TCellCT := row.C[i];
        var column: integer := TUtility.ColumnOf(spilled.R);
        if (spilled = cell) or (column < area.Left) or (column > area.Right) then
          Continue;
        fStore.RemoveValue(spilled);
        if IsBare(spilled, ['S', 'Ph', 'ExtLst']) then
          row.Remove(spilled);
      end;
    cell.F.Ref := cell.R;
    cell.T := stctE;
    cell.V := '#REF!';
  end;
end;

// a part's own relationships part
function RelationshipsOf(const aPart: string): string;
begin
  var slash: integer := aPart.LastIndexOf('/');
  Result := aPart.Substring(0, slash + 1) + '_rels/' + aPart.Substring(slash + 1) + '.rels';
end;

// all checked and planned first, so a refusal changes nothing; then every other sheet's formulas, charts, names, tables'
// formulas and extensions, the names local to it, the views, its parts
procedure TXlsxWalkSheet.DeleteSheet;
const
  cLastVisible = 'A workbook must contain at least one visible worksheet. To hide, delete, or move the selected sheet(s), ' +
    'you must first insert a new sheet or unhide a sheet that is already hidden.';
type
  // a formula of a table on another sheet (Formula), or of an extension's element kept as read (Index in XmlUnknown), changed
  TKeptMove = record
    Part: string;
    Sheet: TXlsxWalkSheet;
    Formula: TTableFormulaCT;
    Extension: TXmlite;
    Index: integer;
    Text: string;
  end;
var
  package: TPackageOoxml;
  map, cellsMap: TReferenceMap;
  why: string;
  kept: TList<TKeptMove>;

  procedure PlanTableFormula(aSheet: TXlsxWalkSheet; const aPart: string; aFormula: TTableFormulaCT);
  begin
    if why <> '' then
      Exit;
    var text: string := DecodeText(aFormula.XmlValue);
    var move: TKeptMove := Default(TKeptMove);
    var reason: string;
    if not ShiftFormula(text, cellsMap, move.Text, reason) then
    begin
      if text.ToUpper.Contains(fName.ToUpper) then
        why := Format('a formula of the table %s does not read: %s', [aPart, reason]);
      Exit;
    end;
    if move.Text = text then
      Exit;
    move.Part := aPart;
    move.Sheet := aSheet;
    move.Formula := aFormula;
    kept.Add(move);
  end;

  procedure PlanExtensions(aSheet: TXlsxWalkSheet);
  begin
    var objects: TWorksheetE := aSheet.fStore.Objects(False);
    if (why <> '') or not objects.IsPresent('ExtLst') then
      Exit;
    for var extension: ProRock.Xmlite.Schema.Ooxml.Sml.TExtensionCT in objects.ExtLst.Ext do
      for var index := 0 to extension.XmlUnknown.Count - 1 do
      begin
        var move: TKeptMove := Default(TKeptMove);
        var reason: string;
        if not MappedKeptXml(extension.XmlUnknown[index].Xml, fName, cellsMap, move.Text, reason) then
        begin
          why := Format('a formula of %s''s extensions does not read: %s', [aSheet.fName, reason]);
          Exit;
        end;
        if move.Text = extension.XmlUnknown[index].Xml then
          Continue;
        move.Sheet := aSheet;
        move.Extension := extension;
        move.Index := index;
        kept.Add(move);
      end;
  end;

  // the parts only this sheet and the caches dropped lead to: those no other part reaches from the package's root
  procedure RemoveParts(const aCaches: TList<string>);
  begin
    var names: TList<string> := TList<string>.Create;
    var parents: TList<string> := TList<string>.Create;
    var found: TDictionary<string, boolean> := TDictionary<string, boolean>.Create;
    var reached: TDictionary<string, boolean> := TDictionary<string, boolean>.Create;
    try
      names.Add(fStore.Part);
      parents.Add(fBook.WorkbookPart);
      found.Add(fStore.Part.ToUpper, True);
      for var cache: string in aCaches do
      begin
        names.Add(cache);
        parents.Add(fBook.WorkbookPart);
        found.AddOrSetValue(cache.ToUpper, True);
      end;
      var next: integer := 0;
      while next < names.Count do
      begin
        for var relationship: TRelationshipOoxml in package.Relationships(names[next]) do
          if (relationship.Part <> '') and not found.ContainsKey(relationship.Part.ToUpper) then
          begin
            found.Add(relationship.Part.ToUpper, True);
            names.Add(relationship.Part);
            parents.Add(names[next]);
          end;
        Inc(next);
      end;
      var queue: TList<string> := TList<string>.Create;
      try
        queue.Add('');
        next := 0;
        while next < queue.Count do
        begin
          for var relationship: TRelationshipOoxml in package.Relationships(queue[next]) do
            if (relationship.Part <> '') and not reached.ContainsKey(relationship.Part.ToUpper) and
              ((queue[next] <> fBook.WorkbookPart) or (relationship.Part <> fStore.Part) and
              not aCaches.Contains(relationship.Part)) then
            begin
              reached.Add(relationship.Part.ToUpper, True);
              queue.Add(relationship.Part);
            end;
          Inc(next);
        end;
      finally
        queue.Free;
      end;
      for var index := 0 to names.Count - 1 do
        if not reached.ContainsKey(names[index].ToUpper) then
        begin
          package.RemovePart(names[index], RelationshipsOf(names[index]));
          package.RemovePart(parents[index], names[index]);
        end;
    finally
      reached.Free;
      found.Free;
      parents.Free;
      names.Free;
    end;
  end;

begin
  package := fBook.Package;
  var entries: TSheetCTList := package.Part<TWorkbookE>(fBook.WorkbookPart).Sheets.Sheet;
  var entry: TSheetCT := fBook.SheetEntry(fName);
  var index: integer := entries.IndexOf(entry);
  why := '';
  var visible: integer := 0;
  for var i := 0 to entries.Count - 1 do
    if (i <> index) and (entries[i].State = stssVisible) then
      Inc(visible);
  if fBook.SheetStates[index] = svVeryHidden then
    why := 'a very hidden sheet, which Excel does not delete'
  else if visible = 0 then
    why := cLastVisible;
  for var relationship: TRelationshipOoxml in package.Relationships(fStore.Part) do
    if (why = '') and (relationship.&Type.EndsWith(cSlicer) or relationship.&Type.EndsWith(cTimeline)) then
      why := 'slicers or timelines, which Calcite does not remove yet';
  var sheets: TArray<string> := nil;
  for var sheet: TXlsxWalkSheet in fWalk.fSheets do
    sheets := sheets + [sheet.fName];
  map := TReferenceMap.SheetDeleted(fName, sheets);
  map.InName := True;
  for var relationship: TRelationshipOoxml in package.Relationships(fStore.Part, cTable) do
  begin
    var table: TTableE := package.Part<TTableE>(relationship.Part);
    if table <> nil then
      map.GoneTables := map.GoneTables + [string(table.Name)];
  end;
  cellsMap := map;
  cellsMap.InName := False;

  var others: TList<TXlsxWalkSheet> := TList<TXlsxWalkSheet>.Create;
  var moves: TObjectList<TList<TFormulaMove>> := TObjectList<TList<TFormulaMove>>.Create;
  var refs: TObjectList<TDictionary<cardinal, string>> := TObjectList<TDictionary<cardinal, string>>.Create;
  var texts: TList<TTextMove> := TList<TTextMove>.Create;
  var charts: TList<TChartMove> := TList<TChartMove>.Create;
  var caches: TList<string> := TList<string>.Create;
  kept := TList<TKeptMove>.Create;
  try
    for var sheet: TXlsxWalkSheet in fWalk.fSheets do
      if sheet <> Self then
        others.Add(sheet);
    if why = '' then
      for var sheet: TXlsxWalkSheet in others do
      begin
        moves.Add(TList<TFormulaMove>.Create);
        refs.Add(TDictionary<cardinal, string>.Create);
        if not PlanFormulas(sheet, map, nil, moves.Last, texts, refs.Last, why) then
          Break;
      end;
    if why = '' then
      PlanCharts(Self, map, charts, why);
    var names: TArray<string>;
    if why = '' then
      fBook.MappedNames(map, names, why);
    for var sheet: TXlsxWalkSheet in others do
    begin
      PlanExtensions(sheet);
      for var relationship: TRelationshipOoxml in package.Relationships(sheet.fStore.Part, cTable) do
      begin
        var table: TTableE := package.Part<TTableE>(relationship.Part);
        if table <> nil then
          for var column: TTableColumnCT in table.TableColumns.TableColumn do
          begin
            if column.IsPresent('CalculatedColumnFormula') then
              PlanTableFormula(sheet, relationship.Part, column.CalculatedColumnFormula);
            if column.IsPresent('TotalsRowFormula') then
              PlanTableFormula(sheet, relationship.Part, column.TotalsRowFormula);
          end;
      end;
    end;
    // its names another formula names (Data!Total, now [0]!Total): Excel keeps them as the workbook's
    var workbookNames: TList<string> := TList<string>.Create;
    var lifted: TList<integer> := TList<integer>.Create;
    try
      var written: TStringBuilder := TStringBuilder.Create;
      try
        for var list: TList<TFormulaMove> in moves do
          for var move: TFormulaMove in list do
            written.Append(move.After).Append(#10);
        for var move: TTextMove in texts do
          written.Append(move.Text).Append(#10);
        for var move: TChartMove in charts do
          written.Append(move.After).Append(#10);
        for var move: TKeptMove in kept do
          written.Append(move.Text).Append(#10);
        for var text: string in names do
          written.Append(text).Append(#10);
        var xml: TWorkbookE := package.Part<TWorkbookE>(fBook.WorkbookPart);
        if (why = '') and xml.IsPresent('DefinedNames') then
        begin
          var list: TDefinedNameCTList := xml.DefinedNames.DefinedName;
          for var name: TDefinedNameCT in list do
            if not name.Present[@name.LocalSheetId] then
              workbookNames.Add(AnsiUpperCase(name.Name));
          for var i := 0 to list.Count - 1 do
            if list[i].Present[@list[i].LocalSheetId] and (integer(list[i].LocalSheetId) = index) and
              not string(list[i].Name).StartsWith('_xlnm.') and TRegEx.IsMatch(written.ToString,
              '\[0\]!' + TRegEx.Escape(list[i].Name) + '(?![\w.?\\])', [roIgnoreCase]) then
              if workbookNames.Contains(AnsiUpperCase(list[i].Name)) then
                why := Format('its name %s, which a formula names, and the workbook''s of the same name: Calcite does ' +
                  'not know which Excel keeps', [string(list[i].Name)])
              else
                lifted.Add(i);
        end;
      finally
        written.Free;
      end;
      if why <> '' then
        raise EInvalidOpException.CreateFmt('%s not deleted: %s', [fName, why]);

      fBook.WriteNames(names);
      var workbook: TWorkbookE := package.EditPart<TWorkbookE>(fBook.WorkbookPart);
      if workbook.IsPresent('DefinedNames') then
      begin // its own go (or the workbook's then), those of the sheets after it count one less
        var list: TDefinedNameCTList := workbook.DefinedNames.DefinedName;
        for var i := list.Count - 1 downto 0 do
          if lifted.Contains(i) then
            list[i].Clear(@list[i].LocalSheetId)
          else if list[i].Present[@list[i].LocalSheetId] then
            if integer(list[i].LocalSheetId) = index then
              list.Delete(i)
            else if integer(list[i].LocalSheetId) > index then
              list[i].LocalSheetId := list[i].LocalSheetId - 1;
        if list.Count = 0 then
          workbook.Clear('DefinedNames');
      end;
    finally
      lifted.Free;
      workbookNames.Free;
    end;

    WriteTexts(texts);
    for var i := 0 to others.Count - 1 do
    begin
      others[i].ApplyFormulas(moves[i], refs[i], False, map);
      others[i].FoldSpills(moves[i]);
    end;
    ShiftCharts(charts, map);
    for var move: TKeptMove in kept do
      if move.Formula <> nil then
      begin
        package.EditPart<TTableE>(move.Part);
        move.Formula.XmlValue := EncodeText(move.Text);
      end
      else
      begin
        move.Sheet.fStore.Objects(True);
        var item: TXmliteUnknown := move.Extension.XmlUnknown[move.Index];
        item.Xml := move.Text;
        move.Extension.XmlUnknown[move.Index] := item;
      end;

    var workbook: TWorkbookE := package.EditPart<TWorkbookE>(fBook.WorkbookPart);

    // the active sheet deleted: the next visible one (else the one before) active and selected, as Excel does
    var active: integer := -1;
    for var i := index + 1 to entries.Count - 1 do
      if (active < 0) and (entries[i].State = stssVisible) then
        active := i;
    for var i := index - 1 downto 0 do
      if (active < 0) and (entries[i].State = stssVisible) then
        active := i;
    if fBook.MoveActiveSheet(index, active) then
    begin
      for var sheet: TXlsxWalkSheet in others do
        if fBook.SheetIndex(sheet.fName) = active then
          sheet.fStore.SetTabSelected(True);
      fBook.SetChartTabSelected(active, True);
    end;
    if workbook.IsPresent('BookViews') then // the tabs after it one less
      for var view: TBookViewCT in workbook.BookViews.WorkbookView do
      begin
        var tab: integer := view.ActiveTab;
        if tab > index then
          Dec(tab);
        if tab <> integer(view.ActiveTab) then
        begin
          view.ActiveTab := tab;
          view.SetPresent(@view.ActiveTab);
        end;
        var first: integer := view.FirstSheet;
        if first > index then
          Dec(first);
        first := Min(first, entries.Count - 2);
        if first <> integer(view.FirstSheet) then
        begin
          view.FirstSheet := first;
          view.SetPresent(@view.FirstSheet);
        end;
      end;

    // the pivot caches only its pivot tables used
    var used: TList<string> := TList<string>.Create;
    try
      for var sheet: TXlsxWalkSheet in others do
        for var pivot: TRelationshipOoxml in package.Relationships(sheet.fStore.Part, cPivotTable) do
          for var cache: TRelationshipOoxml in package.Relationships(pivot.Part, cPivotCacheDefinition) do
            used.Add(cache.Part.ToUpper);
      for var pivot: TRelationshipOoxml in package.Relationships(fStore.Part, cPivotTable) do
        for var cache: TRelationshipOoxml in package.Relationships(pivot.Part, cPivotCacheDefinition) do
          if not used.Contains(cache.Part.ToUpper) and not caches.Contains(cache.Part) then
            caches.Add(cache.Part);
    finally
      used.Free;
    end;
    if workbook.IsPresent('PivotCaches') then
    begin
      for var relationship: TRelationshipOoxml in package.Relationships(fBook.WorkbookPart, cPivotCacheDefinition) do
        if caches.Contains(relationship.Part) then
          for var i := workbook.PivotCaches.PivotCache.Count - 1 downto 0 do
            if workbook.PivotCaches.PivotCache[i].Id = relationship.Id then
              workbook.PivotCaches.PivotCache.Delete(i);
      if workbook.PivotCaches.PivotCache.Count = 0 then
        workbook.Clear('PivotCaches');
    end;

    for var row: TRowCT in fStore.Objects(False).SheetData.Row do
      for var cell: TCellCT in row.C do
        if (cell.T = stctS) and cell.Present[@cell.V] then
          fBook.SharedStringReleased;
    RemoveParts(caches);
    entries.Delete(index);
    fBook.ValueChanged;
    fBook.FormulaChanged;
    for var sheet: TXlsxWalkSheet in others do
      sheet.fStore.Forget;
  finally
    kept.Free;
    caches.Free;
    charts.Free;
    texts.Free;
    refs.Free;
    moves.Free;
    others.Free;
  end;
end;

end.
