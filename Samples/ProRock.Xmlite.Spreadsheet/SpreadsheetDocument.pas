unit SpreadsheetDocument;

// An Excel workbook (.xlsx) read into the classes ProRocket generates from the SpreadsheetML schemas (ECMA-376): the
// workbook, its sheets, shared strings, styles and tables - found as Office finds them, through the package's
// relationships. Cells are shown and edited; Save writes every part it read back from its objects, with what Excel put in
// it that the schema does not describe (its extensions), and copies every other part as it is

interface

uses System.SysUtils, System.Classes, System.Generics.Collections,
  ProRock.Xmlite, ProRock.Xmlite.Schema.Ooxml.Sml;

type
  ESpreadsheetDocument = class(Exception);

  TSheet = class
  private
    fName, fPartName: string;
    fWorksheet: TWorksheetE; // owned by the document's parts
  public
    property Name: string read fName;
    property PartName: string read fPartName;
    property Worksheet: TWorksheetE read fWorksheet;
  end;

  TSpreadsheetDocument = class
  private
    fFileName: string;
    fParts: TObjectDictionary<string, TXmlite>; // part name in the zip -> its object, written back on Save
    fWorkbook: TWorkbookE;
    fSharedStrings: TSstE; // nil when the workbook has none yet
    fStyles: TStyleSheetE;
    fSheets: TObjectList<TSheet>;
    fTables: TList<TTableE>;
    fEdited: boolean;

    function SharedString(aIndex: integer): string;
    function IsDateStyle(aStyle: cardinal): boolean;
  public
    constructor Create;
    destructor Destroy; override;

    // raises ESpreadsheetDocument: not a zip, not a workbook, a part that cannot be read
    procedure Load(const aFileName: string);
    procedure Save(const aFileName: string);

    // the cell at a reference (B2), nil when there is none
    function Cell(aSheet: TSheet; const aRef: string): TCTCellCT;
    // the text a cell shows: a shared string resolved, a date as a date, a number or a formula's last value as written
    function CellText(aCell: TCTCellCT): string;
    // a new value for a cell, created when missing: a number, a date (yyyy-mm-dd) or text (a shared string)
    procedure SetCellText(aSheet: TSheet; const aRef, aText: string);

    property FileName: string read fFileName;
    property Workbook: TWorkbookE read fWorkbook;
    property Sheets: TObjectList<TSheet> read fSheets;
    property Tables: TList<TTableE> read fTables;
  end;

// A1-style references: column 0 is A, row 0 is 1
function CellRef(aCol, aRow: integer): string;
function ParseRef(const aRef: string; out aCol, aRow: integer): boolean;

implementation

uses System.IOUtils, System.Zip, System.DateUtils, System.StrUtils,
  ProRock.Basite, ProRock.Xmlite.Schema.Relationships;

const
  // relationship types end in these names - Transitional and Strict differ only before them
  cOfficeDocument = '/officeDocument';
  cWorksheet = '/worksheet';
  cSharedStrings = '/sharedStrings';
  cStyles = '/styles';
  cTable = '/table';

function CellRef(aCol, aRow: integer): string;
begin
  Result := '';
  var col: integer := aCol + 1;
  while col > 0 do
  begin
    Result := Char(Ord('A') + (col - 1) mod 26) + Result;
    col := (col - 1) div 26;
  end;
  Result := Result + IntToStr(aRow + 1);
end;

function ParseRef(const aRef: string; out aCol, aRow: integer): boolean;
begin
  aCol := 0;
  var i: integer := 1;
  while (i <= aRef.Length) and CharInSet(aRef[i], ['A' .. 'Z']) do
  begin
    aCol := aCol * 26 + Ord(aRef[i]) - Ord('A') + 1;
    Inc(i);
  end;
  Result := (aCol > 0) and TryStrToInt(Copy(aRef, i, MaxInt), aRow) and (aRow > 0);
  Dec(aCol);
  Dec(aRow);
end;

// XML parts are UTF-8 (a BOM or not) or UTF-16 with a BOM
function PartText(const aBytes: TBytes): string;
begin
  var encoding: TEncoding := nil;
  var bomLength: integer := TEncoding.GetBufferEncoding(aBytes, encoding, TEncoding.UTF8);
  Result := encoding.GetString(aBytes, bomLength, Length(aBytes) - bomLength);
end;

// a relationship's target as a part name: relative to the folder of the part that has the relationship, or absolute (/xl/...)
function ResolveTarget(const aSourcePart, aTarget: string): string;
begin
  if aTarget.StartsWith('/') then
    Exit(aTarget.Substring(1));
  var path: TStringList := TStringList.Create;
  try
    path.Delimiter := '/';
    path.StrictDelimiter := True;
    path.DelimitedText := aSourcePart;
    if path.Count > 0 then
      path.Delete(path.Count - 1); // the part's own name ('' - the package itself)
    for var segment: string in aTarget.Split(['/']) do
      if segment = '..' then
      begin
        if path.Count > 0 then
          path.Delete(path.Count - 1);
      end
      else if (segment <> '.') and (segment <> '') then
        path.Add(segment);
    Result := path.DelimitedText;
  finally
    path.Free;
  end;
end;

// xl/workbook.xml -> xl/_rels/workbook.xml.rels
function RelationshipsPart(const aPart: string): string;
begin
  var slash: integer := aPart.LastIndexOf('/');
  Result := aPart.Substring(0, slash + 1) + '_rels/' + aPart.Substring(slash + 1) + '.rels';
end;

{ TSpreadsheetDocument }

constructor TSpreadsheetDocument.Create;
begin
  inherited;
  fParts := TObjectDictionary<string, TXmlite>.Create([doOwnsValues]);
  fSheets := TObjectList<TSheet>.Create;
  fTables := TList<TTableE>.Create;
end;

destructor TSpreadsheetDocument.Destroy;
begin
  fTables.Free;
  fSheets.Free;
  fParts.Free;
  inherited;
end;

procedure TSpreadsheetDocument.Load(const aFileName: string);
var
  zip: TZipFile;

  function Read(const aPart: string; aObject: TXmlite): boolean;
  begin
    var index: integer := zip.IndexOf(aPart);
    if index < 0 then
      Exit(False);
    var bytes: TBytes;
    zip.Read(index, bytes);
    var xml: string := PartText(bytes);
    // read without a copy of the text: it is not needed afterwards
    if not aObject.FromXmlInPlace(xml) then
      raise ESpreadsheetDocument.CreateFmt('%s cannot be read', [aPart]);
    Result := True;
  end;

  // the relationships of a part (nil when it has none) - read, not written back: they are saved as they were
  function Relationships(const aPart: string): TRelationshipsE;
  begin
    Result := TRelationshipsE.Create;
    if not Read(RelationshipsPart(aPart), Result) then
      FreeAndNil(Result);
  end;

  // a part kept for Save, read into its object
  function Keep(const aPart: string; aObject: TXmlite): TXmlite;
  begin
    try
      if not Read(aPart, aObject) then
        raise ESpreadsheetDocument.CreateFmt('The part %s is missing', [aPart]);
    except
      aObject.Free;
      raise;
    end;
    fParts.Add(aPart, aObject);
    Result := aObject;
  end;

begin
  if not TZipFile.IsValid(aFileName) then
    raise ESpreadsheetDocument.CreateFmt('%s is not an .xlsx file (not a zip package)', [ExtractFileName(aFileName)]);

  fParts.Clear;
  fSheets.Clear;
  fTables.Clear;
  fWorkbook := nil;
  fSharedStrings := nil;
  fStyles := nil;
  fEdited := False;

  zip := TZipFile.Create;
  try
    zip.Open(aFileName, zmRead);

    // OPC: the package's relationships name the main part - xl/workbook.xml in every Excel file, but found, not assumed
    // (_rels/.rels: the relationships of the package itself, the part with no name)
    var workbookPart: string := '';
    var packageRelationships: TRelationshipsE := Relationships('');
    if packageRelationships <> nil then
      try
        for var relationship: TRelationshipE in packageRelationships.Relationship do
          if string(relationship.&Type).EndsWith(cOfficeDocument) then
            workbookPart := ResolveTarget('', relationship.Target);
      finally
        packageRelationships.Free;
      end;
    if workbookPart.IsEmpty then
      raise ESpreadsheetDocument.CreateFmt('%s is not an Office document', [ExtractFileName(aFileName)]);

    fWorkbook := TWorkbookE(Keep(workbookPart, TWorkbookE.Create));

    var workbookRelationships: TRelationshipsE := Relationships(workbookPart);
    if workbookRelationships = nil then
      raise ESpreadsheetDocument.CreateFmt('%s is not a workbook', [workbookPart]);
    try
      for var relationship: TRelationshipE in workbookRelationships.Relationship do
        if string(relationship.&Type).EndsWith(cSharedStrings) then
          fSharedStrings := TSstE(Keep(ResolveTarget(workbookPart, relationship.Target), TSstE.Create))
        else if string(relationship.&Type).EndsWith(cStyles) then
          fStyles := TStyleSheetE(Keep(ResolveTarget(workbookPart, relationship.Target), TStyleSheetE.Create));

      // the sheets in the workbook's order, each found by its relationship id (r:id)
      for var sheetEntry: TCTSheetCT in fWorkbook.Sheets.Sheet do
        for var relationship: TRelationshipE in workbookRelationships.Relationship do
          if (relationship.Id = sheetEntry.Id) and string(relationship.&Type).EndsWith(cWorksheet) then
          begin
            var sheet: TSheet := TSheet.Create;
            fSheets.Add(sheet);
            sheet.fName := sheetEntry.Name;
            sheet.fPartName := ResolveTarget(workbookPart, relationship.Target);
            sheet.fWorksheet := TWorksheetE(Keep(sheet.fPartName, TWorksheetE.Create));

            // the sheet's tables, through its own relationships
            var sheetRelationships: TRelationshipsE := Relationships(sheet.fPartName);
            if sheetRelationships <> nil then
              try
                for var sheetRelationship: TRelationshipE in sheetRelationships.Relationship do
                  if string(sheetRelationship.&Type).EndsWith(cTable) then
                    fTables.Add(TTableE(Keep(ResolveTarget(sheet.fPartName, sheetRelationship.Target), TTableE.Create)));
              finally
                sheetRelationships.Free;
              end;
          end;
    finally
      workbookRelationships.Free;
    end;

    fFileName := aFileName;
  finally
    zip.Free;
  end;
end;

procedure TSpreadsheetDocument.Save(const aFileName: string);
begin
  if fFileName.IsEmpty then
    raise ESpreadsheetDocument.Create('Nothing loaded to save');

  // values changed here: formulas (an Amount, a total) are recalculated by Excel when it opens the file
  if fEdited then
    fWorkbook.CalcPr.FullCalcOnLoad := True;

  // a new package next to the target, then moved over it - the loaded file stays intact until the new one is complete
  var temporary: string := aFileName + '.saving';
  var source: TZipFile := TZipFile.Create;
  var target: TZipFile := TZipFile.Create;
  try
    try
      source.Open(fFileName, zmRead);
      target.Open(temporary, zmWrite);
      for var i := 0 to source.FileCount - 1 do
      begin
        var part: TXmlite;
        if fParts.TryGetValue(source.FileNames[i], part) then
          // written from its objects - with the content the schema does not describe (Excel's extensions) where it was
          target.Add(TEncoding.UTF8.GetBytes(part.ToXml), source.FileNames[i])
        else
        begin // as it was: the same bytes, the same compression, in the same order
          var bytes: TBytes;
          source.Read(i, bytes);
          target.Add(bytes, source.FileNames[i], TZipCompression(source.FileInfo[i].CompressionMethod));
        end;
      end;
    finally
      target.Free;
      source.Free;
    end;

    if FileExists(aFileName) then
      TFile.Delete(aFileName);
    TFile.Move(temporary, aFileName);
  except
    if FileExists(temporary) then
      TFile.Delete(temporary);
    raise;
  end;

  fFileName := aFileName;
end;

function TSpreadsheetDocument.SharedString(aIndex: integer): string;
begin
  Result := '';
  if (fSharedStrings = nil) or (aIndex < 0) or (aIndex >= fSharedStrings.Si.Count) then
    Exit;
  // plain text, or rich text: runs, each with its own formatting
  var item: TCTRstCT := fSharedStrings.Si[aIndex];
  Result := item.T;
  for var run: TCTREltCT in item.R do
    Result := Result + string(run.T);
end;

function TSpreadsheetDocument.IsDateStyle(aStyle: cardinal): boolean;
begin
  // the built-in date formats (ECMA-376 Part 1, 18.8.30); a custom one would need its format code read
  Result := (fStyles <> nil) and (aStyle < cardinal(fStyles.CellXfs.Xf.Count)) and
    (fStyles.CellXfs.Xf[aStyle].NumFmtId >= 14) and ((fStyles.CellXfs.Xf[aStyle].NumFmtId <= 22) or
    (fStyles.CellXfs.Xf[aStyle].NumFmtId >= 45) and (fStyles.CellXfs.Xf[aStyle].NumFmtId <= 47));
end;

function TSpreadsheetDocument.Cell(aSheet: TSheet; const aRef: string): TCTCellCT;
begin
  Result := nil;
  var col, row: integer;
  if not ParseRef(aRef, col, row) then
    Exit;
  for var sheetRow: TCTRowCT in aSheet.Worksheet.SheetData.Row do
    if sheetRow.R = cardinal(row + 1) then
      for var sheetCell: TCTCellCT in sheetRow.C do
        if sheetCell.R = aRef then
          Exit(sheetCell);
end;

function TSpreadsheetDocument.CellText(aCell: TCTCellCT): string;
begin
  Result := '';
  if aCell = nil then
    Exit;
  case aCell.T of
    stctS:
      Result := SharedString(StrToIntDef(aCell.V, -1));
    stctInlineStr:
      Result := aCell.&Is.T;
    stctN:
      begin
        Result := aCell.V;
        var serial: Double;
        if IsDateStyle(aCell.S) and TryStrToFloat(aCell.V, serial, TFormatSettings.Invariant) then
          // Excel's date serial counts days from 1899-12-30, as TDateTime does
          Result := FormatDateTime('yyyy-mm-dd', serial);
      end;
  else
    Result := aCell.V;
  end;
end;

procedure TSpreadsheetDocument.SetCellText(aSheet: TSheet; const aRef, aText: string);
begin
  var col, row: integer;
  if not ParseRef(aRef, col, row) then
    Exit;

  // the cell, created where Excel expects it: rows in order, cells in a row in column order
  var cell: TCTCellCT := Cell(aSheet, aRef);
  if cell = nil then
  begin
    var rows: TCTRowCTList := aSheet.Worksheet.SheetData.Row;
    var rowIndex: integer := 0;
    while (rowIndex < rows.Count) and (rows[rowIndex].R < cardinal(row + 1)) do
      Inc(rowIndex);
    if (rowIndex = rows.Count) or (rows[rowIndex].R <> cardinal(row + 1)) then
    begin
      var newRow: TCTRowCT := TCTRowCT.Create;
      newRow.R := row + 1;
      rows.Insert(rowIndex, newRow);
    end;
    var cells: TCTCellCTList := rows[rowIndex].C;
    var cellIndex: integer := 0;
    var cellCol, cellRow: integer;
    while (cellIndex < cells.Count) and ParseRef(cells[cellIndex].R, cellCol, cellRow) and (cellCol < col) do
      Inc(cellIndex);
    cell := TCTCellCT.Create;
    cell.R := aRef;
    cells.Insert(cellIndex, cell);
  end;

  // a number as a number (written invariant: 1250.5), a date as its serial, anything else as a shared string
  var number: Double;
  var date: TDateTime;
  if TryStrToFloat(aText, number) then
  begin
    cell.T := stctN;
    cell.V := FloatToStr(number, TFormatSettings.Invariant);
  end
  else if TryISO8601ToDate(aText, date) and IsDateStyle(cell.S) then
  begin
    cell.T := stctN;
    cell.V := FloatToStr(Trunc(date), TFormatSettings.Invariant);
  end
  else
  begin
    if fSharedStrings = nil then
      raise ESpreadsheetDocument.Create('The workbook has no shared strings: only numbers can be entered');
    var item: TCTRstCT := TCTRstCT.Create;
    item.T := aText;
    fSharedStrings.Si.Add(item);
    fSharedStrings.Count := fSharedStrings.Count + 1;
    fSharedStrings.UniqueCount := fSharedStrings.Si.Count;
    cell.T := stctS;
    cell.V := IntToStr(fSharedStrings.Si.Count - 1);
  end;
  fEdited := True;
end;

end.
