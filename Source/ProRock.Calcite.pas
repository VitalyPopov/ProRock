unit ProRock.Calcite;

// Excel workbooks (.xlsx): open, change and save with nothing lost

interface

uses System.SysUtils, System.Classes, System.Generics.Collections, System.Zip,
  ProRock.Xmlite, ProRock.Xmlite.Schema.Ooxml.Sml;

const
  isHint = ProRock.Xmlite.isHint;
  isWarning = ProRock.Xmlite.isWarning;
  isError = ProRock.Xmlite.isError;

type
  TIssueSeverity = ProRock.Xmlite.TIssueSeverity;
  TIssue = ProRock.Xmlite.TIssue;
  TIssueEvent = ProRock.Xmlite.TIssueEvent;
  TIssues = ProRock.Xmlite.TIssues;

  TWorkbook = class;
  TWorksheet = class;

  // a date is a number in a date format, as in Excel
  TCellValueType = (cvEmpty, cvNumber, cvDate, cvText, cvBoolean, cvError);

  // An address on a sheet, not the cells themselves: no Free. Reading creates nothing, writing creates the cells it needs
  TRange = record
  private
    fSheet: TWorksheet;
    fTop, fLeft, fBottom, fRight: integer;

    function GetRowCount: integer; inline;
    function GetColumnCount: integer; inline;
    function GetAddress: string;
    function GetValue: Variant;
    procedure SetValue(const aValue: Variant);
    function GetValueType: TCellValueType;
    function GetAsString: string;
    procedure SetAsString(const aValue: string);
    function GetAsFloat: Double;
    procedure SetAsFloat(aValue: Double);
    function GetAsInteger: Int64;
    procedure SetAsInteger(aValue: Int64);
    function GetAsDateTime: TDateTime;
    procedure SetAsDateTime(aValue: TDateTime);
    function GetAsBoolean: boolean;
    procedure SetAsBoolean(aValue: boolean);
    procedure CheckShape(const aArray: Variant);
    function GetFormula: Variant;
    procedure SetFormula(const aValue: Variant);
    function GetHasFormula: boolean;
    function GetHasArray: boolean;
    function GetCurrentArray: TRange;
    function GetFormulaArray: string;
    procedure SetFormulaArray(const aValue: string);
  public
    // the values gone, as Excel's ClearContents: a cell with a format stays
    procedure ClearContents;

    property Sheet: TWorksheet read fSheet;
    property Row: integer read fTop;
    property Column: integer read fLeft;
    property RowCount: integer read GetRowCount;
    property ColumnCount: integer read GetColumnCount;
    // B5, A1:C10
    property Address: string read GetAddress;

    // Excel's Value: Empty, a Double, a TDateTime (a number in a date format), a string, a Boolean, an error as its text (#N/A).
    // Several cells: a Variant array [1..RowCount, 1..ColumnCount], and one value is written to each.
    // Text is stored as text: '=A1' is not a formula (Formula writes one), '00123' not a number. Empty or '' clears the cell.
    // A formula's value is the one Excel calculated last: none for a formula written here until Excel opens and saves the file
    property Value: Variant read GetValue write SetValue;

    // the first cell's
    property ValueType: TCellValueType read GetValueType;
    // As*: the first cell's value, written to every cell. AsString: a number as the shortest invariant text (1250.5), a date as
    // ISO 8601, a Boolean as TRUE or FALSE; AsFloat: a date as its serial number (Excel's Value2)
    property AsString: string read GetAsString write SetAsString;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsInteger: Int64 read GetAsInteger write SetAsInteger;
    // a date written into a cell without a date format gets Excel's short date (with the time when there is one)
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsBoolean: boolean read GetAsBoolean write SetAsBoolean;

    // Excel's Formula: '=' and the formula in Excel's own form (=SUM(A1:A3;B1) is the locale's, =SUM(A1:A3,B1) Excel's), '' for
    // a cell without one; several cells: a Variant array as Value's. Written: the = optional, '' clears; one text written to
    // several cells moves its relative references to each, as Excel fills (=B1 in A1:A3: =B1, =B2, =B3); an array gives each
    // cell its own. Function names in English only (SUM, not SUMME), Excel's prefixes (_xlfn.) not needed. A formula Excel
    // would refuse (brackets, ROUND(1), ROW(1)) is refused, an unknown function warned of; what Excel cannot calculate shows
    // its error
    property Formula: Variant read GetFormula write SetFormula;
    // every cell has a formula (each cell of an array formula's area has)
    property HasFormula: boolean read GetHasFormula;
    // the first cell is in an array formula's area
    property HasArray: boolean read GetHasArray;
    // that area; EInvalidOpException when there is none
    property CurrentArray: TRange read GetCurrentArray;
    // the first cell's array formula ('' when there is none). Written: the range becomes one array formula; an array formula
    // changes only as a whole, as in Excel. Excel 365's dynamic arrays read as array formulas
    property FormulaArray: string read GetFormulaArray write SetFormulaArray;
  end;

  TWorksheet = class
  private
    fWorkbook: TWorkbook;
    fName: string;
    fPartName: string;
    fPrepared: boolean;
    // found on the first need: the areas of array formulas and data tables, shared formulas' first cells by si
    fArrays, fDataTables: TList<TRange>;
    fShared: TDictionary<cardinal, TCellCT>;
    // found on the first write: the areas of tables, their header and totals rows, pivot tables
    fTables, fTableRows, fPivots: TList<TRange>;
    fLockedWritten: boolean; // reported once a sheet
    fFresh: boolean; // made here, a new workbook's or added: nothing outside Calcite can name it yet

    function GetXml: TWorksheetE;
    function Objects(aEdit: boolean): TWorksheetE;
    function FindRow(aSheet: TWorksheetE; aRow: integer; out aIndex: integer): boolean;
    function FindCell(aRow, aColumn: integer): TCellCT;
    function EffectiveStyle(aRow, aColumn: integer): cardinal;
    function CellValue(aCell: TCellCT; out aValue: Variant): TCellValueType;
    procedure FindFormulas;
    procedure ForgetFormulas;
    procedure FindFixedAreas;
    function FormulaText(aRow, aColumn: integer; out aText: string): boolean;
    function CheckFormula(aRow, aColumn: integer; const aFormula: Variant; out aText: string): boolean;
    function Unshare(aIndex: cardinal): boolean;
    function Blocker(aRow, aColumn: integer; const aTarget: TRange; out aCode, aWhy: string): boolean;
    function CanWrite(aRow, aColumn: integer; const aTarget: TRange): boolean;
    function CellForWriting(aRow, aColumn: integer): TCellCT;
    procedure RemoveValue(aCell: TCellCT);
    procedure Refuse(aRow, aColumn: integer; const aCode, aWhy: string);
    function IsLocked(aRow, aColumn: integer): boolean;
    procedure WriteNumber(aRow, aColumn: integer; aValue: Double; const aTarget: TRange);
    procedure WriteDate(aRow, aColumn: integer; aValue: TDateTime; const aTarget: TRange);
    procedure WriteText(aRow, aColumn: integer; const aValue: string; const aTarget: TRange);
    procedure WriteBoolean(aRow, aColumn: integer; aValue: boolean; const aTarget: TRange);
    procedure WriteValue(aRow, aColumn: integer; const aValue: Variant; const aTarget: TRange);
    procedure WriteFormula(aRow, aColumn: integer; const aText: string; const aTarget: TRange);
    procedure WriteArray(const aRange: TRange; const aFormula: string);
    procedure ClearContents(const aRange: TRange);
    function MakeRange(aTop, aLeft, aBottom, aRight: integer): TRange;
    function GetRange(const aAddress: string): TRange;
    function GetCells(aRow, aColumn: integer): TRange;
    function GetCellsByLetters(aRow: integer; const aColumn: string): TRange;
    function GetUsedRange: TRange;
    procedure SetName(const aValue: string);
  public
    destructor Destroy; override;

    // the generated objects; once taken, the sheet is saved from them
    property Xml: TWorksheetE read GetXml;

    property Workbook: TWorkbook read fWorkbook;
    // renamed only while nothing can name it: a sheet made here (a new workbook's or added), before formulas are written
    property Name: string read fName write SetName;
    // 'B5', 'A1:C10', '5:5', 'B:D' ($ allowed); EArgumentException for anything else
    property Range[const aAddress: string]: TRange read GetRange;
    // Excel's order, from 1: Cells[5, 2] or Cells[5, 'B'] is B5; Sheet[5, 'B'] too
    property Cells[aRow, aColumn: integer]: TRange read GetCells; default;
    property Cells[aRow: integer; const aColumn: string]: TRange read GetCellsByLetters; default;
    // from the first cell to the last one the sheet has (a formatted one too, as in Excel); A1 when there are none
    property UsedRange: TRange read GetUsedRange;
  end;

  // in the workbook's order, numbered from 1 as in Excel; chart sheets are not listed
  TWorksheets = class
  private
    fWorkbook: TWorkbook;
    fList: TObjectList<TWorksheet>;

    function GetCount: integer;
    function GetItem(aIndex: integer): TWorksheet;
    function GetItemByName(const aName: string): TWorksheet;
  public
    constructor Create;
    destructor Destroy; override;

    function GetEnumerator: TList<TWorksheet>.TEnumerator;
    // nil when there is none; case is ignored, as in Excel
    function Find(const aName: string): TWorksheet;
    // at the end; no name: Excel's next SheetN. A name Excel would refuse (more than 31 characters, [ ] : * ? / \, ' at
    // either end, taken) is an issue, and the sheet gets the next SheetN
    function Add(const aName: string = ''): TWorksheet;

    property Count: integer read GetCount;
    // raise when there is none (Find does not)
    property Items[aIndex: integer]: TWorksheet read GetItem; default;
    property Items[const aName: string]: TWorksheet read GetItemByName; default;
  end;

  TWorkbook = class
  private type
    TPart = class
    private
      fClass: TXmliteClass;
      fXml: TXmlite; // nil until first used
      fExact: boolean; // read without a loss: may be written back
      fChanged: boolean;
      fNew: boolean; // not in the package yet
    public
      destructor Destroy; override;
    end;
  private
    fFileName: string;
    fError: string;
    fSource: TBytesStream;
    fZip: TZipFile; // over fSource
    fParts: TObjectDictionary<string, TPart>; // only the parts Calcite has classes for
    fRelationshipTypes: string; // what the package's relationship types start with: Transitional and Strict differ
    fWorkbookPart, fWorkbookRelationshipsPart, fContentTypesPart, fSharedStringsPart, fStylesPart, fCalcChainPart: string;
    fDropped: TList<string>; // parts left out on save
    fSheets: TWorksheets;
    fStrings: TDictionary<string, integer>; // shared strings by text, built on the first write
    fStyleKeys: TDictionary<string, integer>; // cellXfs by content, built on the first need
    fDateStyles: TDictionary<cardinal, boolean>;
    fValuesChanged: boolean;
    fFormulasWritten: boolean;
    fIssues: TIssues;

    // nothing open: Open's own workbook
    constructor CreateClosed;
    class procedure Swap<T>(var aLeft, aRight: T); static; inline;
    procedure NewPackage;
    procedure Close;
    function Load: boolean;
    function Fail(const aCode, aError: string): boolean;
    function ReadXml(aXml: TXmlite; const aPart: string; const aBytes: TBytes): boolean;
    function CanWrite: boolean;
    function Write(aStream: TStream): boolean;
    procedure Exchange(aOther: TWorkbook);
    function PartIndex(const aName: string): integer;
    procedure FixedAreas(const aSheetPart: string; aTables, aTableRows, aPivots: TList<TRange>);
    function AddPart(const aName: string; aClass: TXmliteClass): string;
    function NewPart(const aRelationship, aTarget, aContentType: string; aXml: TXmlite; out aId: string): string;
    function SheetNameError(const aName: string; aExcept: TWorksheet): string;
    function AddSheet(const aName: string): TWorksheet;
    // ReadPart leaves the part as its bytes, EditPart saves it from its objects
    function ReadPart(const aName: string): TXmlite;
    function EditPart(const aName: string): TXmlite;

    function IsLockedStyle(aStyle: cardinal): boolean;
    procedure ValueChanged;
    procedure FormulaChanged;
    function Date1904: boolean;
    function SharedString(aIndex: integer): string;
    function SharedStringIndex(const aText: string): integer;
    procedure SharedStringReleased;
    function IsDateStyle(aStyle: cardinal): boolean;
    function DateStyle(aStyle: cardinal; aFormat: integer): integer;

    function GetXml: TWorkbookE;
    function GetXmlSharedStrings: TSstE;
    function GetXmlStyles: TStyleSheetE;
  public
    // a new workbook, as Excel's: Sheet1 and nothing in it; Open replaces it
    constructor Create;
    destructor Destroy; override;

    // the generated objects (nil when there are none); once taken, the part is saved from them
    property Xml: TWorkbookE read GetXml;
    property XmlSharedStrings: TSstE read GetXmlSharedStrings;
    property XmlStyles: TStyleSheetE read GetXmlStyles;

    // False: Error says why, and the workbook open before stays open
    function Open(const aFileName: string): boolean; overload;
    function Open(aStream: TStream): boolean; overload;
    // Save: to the file opened (a new workbook has none: SaveAs). False: Error says why, and the file stays as it was
    function Save: boolean;
    function SaveAs(const aFileName: string): boolean; overload;
    function SaveAs(aStream: TStream): boolean; overload;

    property FileName: string read fFileName;
    // why the last Open or Save returned False
    property Error: string read fError;
    // since the last Open: writes refused (the cell keeps its value), what Open and Save could not do, values and parts read
    // not quite right. Save refuses only to keep the file valid with nothing lost: Issues.HasErrors tells the rest
    property Issues: TIssues read fIssues;
    // each issue as it comes
    property OnIssue: TIssueEvent read fIssues.OnIssue write fIssues.OnIssue;
    property Sheets: TWorksheets read fSheets;
  end;

implementation

uses System.IOUtils, System.Math, System.Variants, System.DateUtils, System.TypInfo, System.Character,
  ProRock.Utility, ProRock.Xmlite.Schema.Relationships, ProRock.Xmlite.Schema.ContentTypes;

const
  // relationship types end in these names - Transitional and Strict differ only before them
  cOfficeDocument = '/officeDocument';
  cWorksheet = '/worksheet';
  cSharedStrings = '/sharedStrings';
  cStyles = '/styles';
  cCalcChain = '/calcChain';
  cTable = '/table';
  cPivotTable = '/pivotTable';
  cContentTypes = '[Content_Types].xml';
  cSharedStringsType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml';
  cWorksheetType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml';
  cMaxSheetName = 31; // UTF-16 units, as Excel counts

  cMaxRow = 1048576;
  cMaxColumn = 16384;
  cMaxText = 32767;
  cMaxFormula = 8192;

  // Excel's number formats a date gets: m/d/yyyy, m/d/yyyy h:mm, h:mm:ss (shown in the user's locale)
  cDateFormat = 14;
  cDateTimeFormat = 22;
  cTimeFormat = 21;

// relative to the folder of the part that has the relationship, or absolute (/xl/...)
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

function RelationshipsPart(const aPart: string): string;
begin
  var slash: integer := aPart.LastIndexOf('/');
  Result := aPart.Substring(0, slash + 1) + '_rels/' + aPart.Substring(slash + 1) + '.rels';
end;

{ addresses }

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

// the letters from aIndex on as a column number (0: none, or beyond XFD); aIndex moves past them
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

// a cell's r (B5) -> its column; 0 when it has none
function ColumnOf(const aReference: string): integer;
begin
  var index: integer := 1;
  Result := ReadColumn(aReference, index);
end;

// B5, $B$5, A1:C10, 5:7, B:D
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

{ formulas }

type
  TReferenceKind = (rkNone, rkCell, rkColumn, rkRow);

// A1, $A$1, A, $A, 5, $5 (a column and a row count only as one end of A:C or 5:7)
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
  aRowFixed := (index <= aWord.Length) and (aWord[index] = '$');
  if aRowFixed then
    Inc(index);
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

// a reference's relative parts moved; False off the sheet
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

type
  // one of Excel's functions: the argument counts it takes (those over Paired come in pairs: SUMIFS 3, 5, 7...; none when
  // Min is over Max: CALL), the prefix a file stores it with (cFunctionPrefixes), the arguments that must be references
  // (r; v - a value too; past its end the last one repeats, or the last two when paired), whether it may give one
  TExcelFunction = record
    Name: string;
    Min, Max, Paired, Prefix: byte;
    References: string;
    ReferenceResult: boolean;
  end;

const
  cFunctionPrefixes: array [0 .. 2] of string = ('', '_xlfn.', '_xlfn._xlws.');
  // Excel's functions, made from Excel itself (each count tried, a saved file read): not edited by hand
  cFunctionCount = 518;
  cLetFunction = 277;
  cLambdaFunction = 270;
  cFunctions: array [0 .. cFunctionCount - 1] of TExcelFunction = (
  (Name: 'ABS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ACCRINT'; Min: 6; Max: 8; Paired: 8; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ACCRINTM'; Min: 4; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ACOS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ACOSH'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ACOT'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'ACOTH'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'ADDRESS'; Min: 2; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'AGGREGATE'; Min: 3; Max: 254; Paired: 254; Prefix: 1; References: 'vvvvrrr'; ReferenceResult: False),
  (Name: 'AMORDEGRC'; Min: 6; Max: 7; Paired: 7; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'AMORLINC'; Min: 6; Max: 7; Paired: 7; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'AND'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ARABIC'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'AREAS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: 'r'; ReferenceResult: False),
  (Name: 'ARRAYTOTEXT'; Min: 1; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'ASC'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ASIN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ASINH'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ATAN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ATAN2'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ATANH'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'AVEDEV'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'AVERAGE'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'AVERAGEA'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'AVERAGEIF'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: 'rvr'; ReferenceResult: False),
  (Name: 'AVERAGEIFS'; Min: 3; Max: 255; Paired: 3; Prefix: 0; References: 'rrvrvrv'; ReferenceResult: False),
  (Name: 'BAHTTEXT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BASE'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BESSELI'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BESSELJ'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BESSELK'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BESSELY'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BETA.DIST'; Min: 4; Max: 6; Paired: 6; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BETADIST'; Min: 3; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BETAINV'; Min: 3; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BIN2DEC'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BIN2HEX'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BIN2OCT'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BINOM.DIST'; Min: 4; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BINOM.DIST.RANGE'; Min: 3; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BINOM.INV'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BINOMDIST'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BITAND'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BITLSHIFT'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BITOR'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BITRSHIFT'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BITXOR'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BYCOL'; Min: 1; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BYROW'; Min: 1; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CALL'; Min: 1; Max: 0; Paired: 0; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CEILING'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CEILING.MATH'; Min: 1; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CEILING.PRECISE'; Min: 1; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CELL'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: 'vr'; ReferenceResult: False),
  (Name: 'CHAR'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CHIDIST'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CHIINV'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CHISQ.DIST'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CHISQ.DIST.RT'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CHISQ.INV'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CHISQ.INV.RT'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CHISQ.TEST'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CHITEST'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CHOOSE'; Min: 2; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: True),
  (Name: 'CHOOSECOLS'; Min: 2; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CHOOSEROWS'; Min: 2; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CLEAN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CODE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COLUMN'; Min: 0; Max: 1; Paired: 1; Prefix: 0; References: 'r'; ReferenceResult: False),
  (Name: 'COLUMNS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COMBIN'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COMBINA'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'COMPLEX'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CONCAT'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CONCATENATE'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CONFIDENCE'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CONFIDENCE.NORM'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CONFIDENCE.T'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CONVERT'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CORREL'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COSH'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COT'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'COTH'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'COUNT'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COUNTA'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COUNTBLANK'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: 'r'; ReferenceResult: False),
  (Name: 'COUNTIF'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: 'rv'; ReferenceResult: False),
  (Name: 'COUNTIFS'; Min: 2; Max: 254; Paired: 2; Prefix: 0; References: 'rvrvrv'; ReferenceResult: False),
  (Name: 'COUPDAYBS'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COUPDAYS'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COUPDAYSNC'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COUPNCD'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COUPNUM'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COUPPCD'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COVAR'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COVARIANCE.P'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'COVARIANCE.S'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CRITBINOM'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CSC'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CSCH'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CUBEKPIMEMBER'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CUBEMEMBER'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CUBEMEMBERPROPERTY'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CUBERANKEDMEMBER'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CUBESET'; Min: 2; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CUBESETCOUNT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CUBEVALUE'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CUMIPMT'; Min: 6; Max: 6; Paired: 6; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CUMPRINC'; Min: 6; Max: 6; Paired: 6; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DATE'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DATEDIF'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DATEVALUE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DAVERAGE'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DAY'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DAYS'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'DAYS360'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DB'; Min: 4; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DBCS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DCOUNT'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DCOUNTA'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DDB'; Min: 4; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DEC2BIN'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DEC2HEX'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DEC2OCT'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DECIMAL'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'DEGREES'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DELTA'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DETECTLANGUAGE'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'DEVSQ'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DGET'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DISC'; Min: 4; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DMAX'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DMIN'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DOLLAR'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DOLLARDE'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DOLLARFR'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DPRODUCT'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DROP'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: True),
  (Name: 'DSTDEV'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DSTDEVP'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DSUM'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DURATION'; Min: 5; Max: 6; Paired: 6; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DVAR'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DVARP'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'EDATE'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'EFFECT'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ENCODEURL'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'EOMONTH'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ERF'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ERF.PRECISE'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'ERFC'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ERFC.PRECISE'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'ERROR.TYPE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'EUROCONVERT'; Min: 0; Max: 254; Paired: 254; Prefix: 0; References: ''; ReferenceResult: True),
  (Name: 'EVEN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'EXACT'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'EXP'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'EXPAND'; Min: 2; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'EXPON.DIST'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'EXPONDIST'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'F.DIST'; Min: 4; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'F.DIST.RT'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'F.INV'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'F.INV.RT'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'F.TEST'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'FACT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FACTDOUBLE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FALSE'; Min: 0; Max: 0; Paired: 0; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FDIST'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FILTER'; Min: 2; Max: 3; Paired: 3; Prefix: 2; References: ''; ReferenceResult: False),
  (Name: 'FILTERXML'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'FINV'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FISHER'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FISHERINV'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FIXED'; Min: 1; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FLOOR'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FLOOR.MATH'; Min: 1; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'FLOOR.PRECISE'; Min: 1; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'FORECAST'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FORECAST.ETS'; Min: 3; Max: 6; Paired: 6; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'FORECAST.ETS.CONFINT'; Min: 3; Max: 7; Paired: 7; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'FORECAST.ETS.SEASONALITY'; Min: 2; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'FORECAST.ETS.STAT'; Min: 3; Max: 6; Paired: 6; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'FORECAST.LINEAR'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'FORMULATEXT'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: 'r'; ReferenceResult: False),
  (Name: 'FREQUENCY'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FTEST'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FV'; Min: 3; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FVSCHEDULE'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'GAMMA'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'GAMMA.DIST'; Min: 4; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'GAMMA.INV'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'GAMMADIST'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'GAMMAINV'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'GAMMALN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'GAMMALN.PRECISE'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'GAUSS'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'GCD'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'GEOMEAN'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'GESTEP'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'GETPIVOTDATA'; Min: 2; Max: 254; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'GROUPBY'; Min: 3; Max: 8; Paired: 8; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'GROWTH'; Min: 1; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'HARMEAN'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'HEX2BIN'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'HEX2DEC'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'HEX2OCT'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'HLOOKUP'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'HOUR'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'HSTACK'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'HYPERLINK'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'HYPGEOM.DIST'; Min: 5; Max: 5; Paired: 5; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'HYPGEOMDIST'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IF'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: True),
  (Name: 'IFERROR'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IFNA'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'IFS'; Min: 2; Max: 254; Paired: 2; Prefix: 1; References: ''; ReferenceResult: True),
  (Name: 'IMABS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMAGE'; Min: 1; Max: 5; Paired: 5; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'IMAGINARY'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMARGUMENT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMCONJUGATE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMCOS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMCOSH'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'IMCOT'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'IMCSC'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'IMCSCH'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'IMDIV'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMEXP'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMLN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMLOG10'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMLOG2'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMPOWER'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMPRODUCT'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMREAL'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMSEC'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'IMSECH'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'IMSIN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMSINH'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'IMSQRT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMSUB'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMSUM'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMTAN'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'INDEX'; Min: 2; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: True),
  (Name: 'INDIRECT'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: True),
  (Name: 'INFO'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'INT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'INTERCEPT'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'INTRATE'; Min: 4; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IPMT'; Min: 4; Max: 6; Paired: 6; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IRR'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISBLANK'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISERR'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISERROR'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISEVEN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISFORMULA'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: 'r'; ReferenceResult: False),
  (Name: 'ISLOGICAL'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISNA'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISNONTEXT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISNUMBER'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISO.CEILING'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISODD'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISOMITTED'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'ISOWEEKNUM'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'ISPMT'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISREF'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISTEXT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'JIS'; Min: 0; Max: 254; Paired: 254; Prefix: 0; References: ''; ReferenceResult: True),
  (Name: 'KURT'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LAMBDA'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: True),
  (Name: 'LARGE'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LCM'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LEFT'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LEFTB'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LEN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LENB'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LET'; Min: 3; Max: 253; Paired: 3; Prefix: 1; References: ''; ReferenceResult: True),
  (Name: 'LINEST'; Min: 1; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LOG'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LOG10'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LOGEST'; Min: 1; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LOGINV'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LOGNORM.DIST'; Min: 4; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'LOGNORM.INV'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'LOGNORMDIST'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LOOKUP'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LOWER'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MAKEARRAY'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'MAP'; Min: 2; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'MATCH'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MAX'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MAXA'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MAXIFS'; Min: 3; Max: 253; Paired: 3; Prefix: 1; References: 'rrvrvrv'; ReferenceResult: False),
  (Name: 'MDETERM'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MDURATION'; Min: 5; Max: 6; Paired: 6; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MEDIAN'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MID'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MIDB'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MIN'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MINA'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MINIFS'; Min: 3; Max: 253; Paired: 3; Prefix: 1; References: 'rrvrvrv'; ReferenceResult: False),
  (Name: 'MINUTE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MINVERSE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MIRR'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MMULT'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MOD'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MODE'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MODE.MULT'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'MODE.SNGL'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'MONTH'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MROUND'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MULTINOMIAL'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MUNIT'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'N'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NA'; Min: 0; Max: 0; Paired: 0; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NEGBINOM.DIST'; Min: 4; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'NEGBINOMDIST'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NETWORKDAYS'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NETWORKDAYS.INTL'; Min: 2; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NOMINAL'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NORM.DIST'; Min: 4; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'NORM.INV'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'NORM.S.DIST'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'NORM.S.INV'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'NORMDIST'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NORMINV'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NORMSDIST'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NORMSINV'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NOT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NOW'; Min: 0; Max: 0; Paired: 0; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NPER'; Min: 3; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NPV'; Min: 2; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NUMBERVALUE'; Min: 1; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'OCT2BIN'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'OCT2DEC'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'OCT2HEX'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ODD'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ODDFPRICE'; Min: 8; Max: 9; Paired: 9; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ODDFYIELD'; Min: 8; Max: 9; Paired: 9; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ODDLPRICE'; Min: 7; Max: 8; Paired: 8; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ODDLYIELD'; Min: 7; Max: 8; Paired: 8; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'OFFSET'; Min: 3; Max: 5; Paired: 5; Prefix: 0; References: 'rvvvv'; ReferenceResult: True),
  (Name: 'OR'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PDURATION'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'PEARSON'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PERCENTILE'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PERCENTILE.EXC'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'PERCENTILE.INC'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'PERCENTOF'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'PERCENTRANK'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PERCENTRANK.EXC'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'PERCENTRANK.INC'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'PERMUT'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PERMUTATIONA'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'PHI'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'PHONETIC'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: 'r'; ReferenceResult: False),
  (Name: 'PI'; Min: 0; Max: 0; Paired: 0; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PIVOTBY'; Min: 4; Max: 11; Paired: 11; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'PMT'; Min: 3; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'POISSON'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'POISSON.DIST'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'POWER'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PPMT'; Min: 4; Max: 6; Paired: 6; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PRICE'; Min: 6; Max: 7; Paired: 7; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PRICEDISC'; Min: 4; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PRICEMAT'; Min: 5; Max: 6; Paired: 6; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PROB'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PRODUCT'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PROPER'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PV'; Min: 3; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'QUARTILE'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'QUARTILE.EXC'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'QUARTILE.INC'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'QUOTIENT'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'RADIANS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'RAND'; Min: 0; Max: 0; Paired: 0; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'RANDARRAY'; Min: 0; Max: 5; Paired: 5; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'RANDBETWEEN'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'RANK'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: 'vrv'; ReferenceResult: False),
  (Name: 'RANK.AVG'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: 'vrv'; ReferenceResult: False),
  (Name: 'RANK.EQ'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: 'vrv'; ReferenceResult: False),
  (Name: 'RATE'; Min: 3; Max: 6; Paired: 6; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'RECEIVED'; Min: 4; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'REDUCE'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: True),
  (Name: 'REGEXEXTRACT'; Min: 2; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'REGEXREPLACE'; Min: 3; Max: 5; Paired: 5; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'REGEXTEST'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'REGISTER.ID'; Min: 1; Max: 0; Paired: 0; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'REPLACE'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'REPLACEB'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'REPT'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'RIGHT'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'RIGHTB'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ROMAN'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ROUND'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ROUNDDOWN'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ROUNDUP'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ROW'; Min: 0; Max: 1; Paired: 1; Prefix: 0; References: 'r'; ReferenceResult: False),
  (Name: 'ROWS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'RRI'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'RSQ'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'RTD'; Min: 3; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SCAN'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'SEARCH'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SEARCHB'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SEC'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'SECH'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'SECOND'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SEQUENCE'; Min: 1; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'SERIESSUM'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SHEET'; Min: 0; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'SHEETS'; Min: 0; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'SIGN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SIN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SINH'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SKEW'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SKEW.P'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'SLN'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SLOPE'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SMALL'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SORT'; Min: 1; Max: 4; Paired: 4; Prefix: 2; References: ''; ReferenceResult: False),
  (Name: 'SORTBY'; Min: 2; Max: 253; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'SQRT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SQRTPI'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'STANDARDIZE'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'STDEV'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'STDEV.P'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'STDEV.S'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'STDEVA'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'STDEVP'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'STDEVPA'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'STEYX'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'STOCKHISTORY'; Min: 2; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'SUBSTITUTE'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SUBTOTAL'; Min: 2; Max: 255; Paired: 255; Prefix: 0; References: 'vrrrrr'; ReferenceResult: False),
  (Name: 'SUM'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SUMIF'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: 'rvr'; ReferenceResult: False),
  (Name: 'SUMIFS'; Min: 3; Max: 255; Paired: 3; Prefix: 0; References: 'rrvrvrv'; ReferenceResult: False),
  (Name: 'SUMPRODUCT'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SUMSQ'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SUMX2MY2'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SUMX2PY2'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SUMXMY2'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SWITCH'; Min: 3; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: True),
  (Name: 'SYD'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'T'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'T.DIST'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'T.DIST.2T'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'T.DIST.RT'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'T.INV'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'T.INV.2T'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'T.TEST'; Min: 4; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'TAKE'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: True),
  (Name: 'TAN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TANH'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TBILLEQ'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TBILLPRICE'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TBILLYIELD'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TDIST'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TEXT'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TEXTAFTER'; Min: 2; Max: 6; Paired: 6; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'TEXTBEFORE'; Min: 2; Max: 6; Paired: 6; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'TEXTJOIN'; Min: 3; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'TEXTSPLIT'; Min: 2; Max: 6; Paired: 6; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'TIME'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TIMEVALUE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TINV'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TOCOL'; Min: 1; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'TODAY'; Min: 0; Max: 0; Paired: 0; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TOROW'; Min: 1; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'TRANSLATE'; Min: 1; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'TRANSPOSE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TREND'; Min: 1; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TRIM'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TRIMMEAN'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TRIMRANGE'; Min: 1; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: True),
  (Name: 'TRUE'; Min: 0; Max: 0; Paired: 0; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TRUNC'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TTEST'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TYPE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'UNICHAR'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'UNICODE'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'UNIQUE'; Min: 1; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'UPPER'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'VALUE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'VALUETOTEXT'; Min: 1; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'VAR'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'VAR.P'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'VAR.S'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'VARA'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'VARP'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'VARPA'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'VDB'; Min: 5; Max: 7; Paired: 7; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'VLOOKUP'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'VSTACK'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'WEBSERVICE'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'WEEKDAY'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'WEEKNUM'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'WEIBULL'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'WEIBULL.DIST'; Min: 4; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'WORKDAY'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'WORKDAY.INTL'; Min: 2; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'WRAPCOLS'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'WRAPROWS'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'XIRR'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'XLOOKUP'; Min: 3; Max: 6; Paired: 6; Prefix: 1; References: ''; ReferenceResult: True),
  (Name: 'XMATCH'; Min: 2; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'XNPV'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'XOR'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'YEAR'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'YEARFRAC'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'YIELD'; Min: 6; Max: 7; Paired: 7; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'YIELDDISC'; Min: 4; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'YIELDMAT'; Min: 5; Max: 6; Paired: 6; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'Z.TEST'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'ZTEST'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False)
  );

// Excel's function by its name without a prefix, in any case; -1 when it is none of them
function FindFunction(const aName: string): integer;
begin
  var low: integer := 0;
  var high: integer := cFunctionCount - 1;
  while low <= high do
  begin
    Result := (low + high) div 2;
    var order: integer := CompareText(cFunctions[Result].Name, aName); // ASCII only: no SUMME, no СУММ
    if order = 0 then
      Exit
    else if order < 0 then
      low := Result + 1
    else
      high := Result - 1;
  end;
  Result := -1;
end;

type
  // a formula's text as a file stores it (_xlfn.XLOOKUP, LET's _xlpm.x) or as Excel's Formula shows it (XLOOKUP, x)
  TFormulaForm = (ffStored, ffShown);

// Excel's A1 formula text (without the =) in aForm: its references moved by aRows and aColumns, as Excel fills - the relative
// parts only, one off the sheet becomes #REF!. False with aWhy when Excel would not read it: a broken formula makes Excel
// refuse the whole file, even repaired. Checked: the grammar (values and operators in turn, brackets, arguments, array
// constants), the number of arguments Excel's own functions take (ROUND(1), SUM()) and a reference where one must stand
// (ROW(1)); an unknown function or name is Excel's #NAME?, the first unknown function aUnknown (a VBA or add-in one is
// unknown too). Without its prefix a file Excel refuses (FILTER) or shows #NAME? (XLOOKUP, LET's x): the stored form adds the
// prefixes, the shown form drops them
function ShiftFormula(const aFormula: string; aRows, aColumns: integer; aForm: TFormulaForm; out aResult, aWhy,
  aUnknown: string): boolean;
const
  cErrors: array [0 .. 9] of string = ('#NULL!', '#DIV/0!', '#VALUE!', '#REF!', '#NAME?', '#NUM!', '#N/A', '#GETTING_DATA',
    '#SPILL!', '#CALC!');
  cSpaces = [' ', #9, #10, #13];
  cOperators = ['+', '-', '*', '/', '^', '&', '=', '<', '>', ':'];
  cMaxArguments = 255;
  cUnknown = -1;
  cResult = -2;
  cParameterPrefix = '_xlpm.';
var
  builder: TStringBuilder;
  i, last: integer; // last: the formula's length
  // what comes next: a value (at the start, after an operator, an opening bracket, a comma) or an operator
  expectValue: boolean;
  // the value before was a constant (a number, a text, TRUE, an error, an array): no range or intersection with it
  constant: boolean;
  spaced: boolean; // spaces after a value: an intersection when another value follows
  ranged: boolean; // after a : the next value is a reference too
  arguments: boolean; // just after a function's ( or a comma between its arguments: an argument may be left out
  prefixed: boolean; // after Sheet1! or [1]: a reference follows
  continued: boolean; // after a table's name: its [...] is the same value
  called: boolean; // after a function's name: its ( follows
  calledFunction: integer; // that function: cFunctions' index, cUnknown, cResult (a LAMBDA's result or parameter called)
  callable: boolean; // just after a LAMBDA's ) or a call's: a ( calls its result, LAMBDA(x,x+1)(5)
  brackets: string; // what is open: f - a function's (, g - a group's (, { - an array constant
  commas: TArray<integer>; // a function's commas so far, for each bracket open
  functions: TArray<integer>; // a function's calledFunction, for each bracket open
  parameters: TList<string>; // LET's and LAMBDA's parameters in scope (Excel stores them _xlpm.x)
  scopes: TArray<integer>; // parameters' count at a function's (, for each bracket open: those after it end at its )
  // a function's argument so far may be a reference (A1, a name, (A1), A1:INDEX(...)), for each bracket open: a constant,
  // another operator or a call of a function giving a value spoils it, and Excel refuses a file with it where one must stand
  referenceLike: TArray<boolean>;

  function Fail(const aText: string): boolean;
  begin
    aWhy := aText;
    Result := False;
  end;

  function IsWordStart(aChar: Char): boolean;
  begin
    Result := aChar.IsLetterOrDigit or CharInSet(aChar, ['_', '\', '$', '.']);
  end;

  function ReadWord(aFrom: integer): integer; // the index after it
  begin
    Result := aFrom;
    while (Result <= last) and (aFormula[Result].IsLetterOrDigit or CharInSet(aFormula[Result], ['_', '\', '$', '.', '?'])) do
      Inc(Result);
  end;

  function Inside: Char;
  begin
    if brackets = '' then
      Result := #0
    else
      Result := brackets[brackets.Length];
  end;

  // the first character after aFrom's spaces, #0 at the end
  function NextChar(aFrom: integer): Char;
  begin
    while (aFrom <= last) and CharInSet(aFormula[aFrom], cSpaces) do
      Inc(aFrom);
    if aFrom > last then
      Result := #0
    else
      Result := aFormula[aFrom];
  end;

  // a word ending before aEnd declares a parameter: LET's name (each other argument, not its last), LAMBDA's (all but its last)
  function Declares(aEnd: integer): boolean;
  begin
    Result := (Inside = 'f') and arguments and (NextChar(aEnd) = ',') and
      ((functions[brackets.Length - 1] = cLambdaFunction) or
      ((functions[brackets.Length - 1] = cLetFunction) and not Odd(commas[brackets.Length - 1])));
  end;

  // a parameter in scope as declared (Excel shows LAMBDA(Total,TOTAL*2) as LAMBDA(Total,Total*2)), '' when there is none
  function Declared(const aName: string): string;
  begin
    for var index := parameters.Count - 1 downto 0 do
      if SameText(parameters[index], aName) then
        Exit(parameters[index]);
    Result := '';
  end;

  // the innermost function's argument is no reference: a group's ( ) inside it is part of it, an array constant is not
  procedure NotAReference;
  begin
    for var index := brackets.Length downto 1 do
      case brackets[index] of
        'f':
          begin
            referenceLike[index - 1] := False;
            Exit;
          end;
        '{':
          Exit;
      end;
  end;

  // the argument ending here (aPosition, from 0) where Excel's function needs a reference: one or Excel refuses the file
  function CheckReference(aPosition: integer): boolean;
  begin
    var top: integer := brackets.Length - 1;
    Result := True;
    if functions[top] < 0 then
      Exit;
    var known: TExcelFunction := cFunctions[functions[top]];
    var pattern: string := known.References;
    if pattern = '' then
      Exit;
    var position: integer := aPosition;
    if position >= pattern.Length then
    begin // past its end the last one repeats, or the last two when paired
      var period: integer := 1;
      if known.Paired < known.Max then
        period := 2;
      position := pattern.Length - period + (position - pattern.Length) mod period;
    end;
    if (pattern[position + 1] = 'r') and (arguments or not referenceLike[top]) then
      Result := Fail(Format('%s''s argument %d must be a reference (A1, a name, INDEX(...)), not a value or left out',
        [known.Name, aPosition + 1]));
    referenceLike[top] := True;
  end;

  procedure OpenFunction(aFunction: integer);
  begin
    brackets := brackets + 'f';
    functions[brackets.Length - 1] := aFunction;
    scopes[brackets.Length - 1] := parameters.Count;
    referenceLike[brackets.Length - 1] := True;
    called := False;
    expectValue := True;
    arguments := True;
  end;

  // a function's ): Excel refuses a file where its own one has another number of arguments
  function CloseFunction: boolean;
  begin
    var top: integer := brackets.Length - 1;
    var count: integer := commas[top] + 1;
    if (commas[top] = 0) and expectValue then
      count := 0;
    parameters.DeleteRange(scopes[top], parameters.Count - scopes[top]);
    callable := (functions[top] = cLambdaFunction) or (functions[top] = cResult);
    if functions[top] < 0 then
      Exit(True);
    var known: TExcelFunction := cFunctions[functions[top]];
    if known.Min > known.Max then
      Exit(Fail(Format('Excel takes %s in no cell''s formula', [known.Name])));
    if (count >= known.Min) and (count <= known.Max) and ((count <= known.Paired) or not Odd(count - known.Paired)) then
      Exit((count = 0) or CheckReference(commas[top]));
    var counts: string := IntToStr(known.Min);
    if known.Max > known.Min then
      counts := counts + ' to ' + IntToStr(known.Max);
    if (known.Min = 1) and (known.Max = 1) then
      counts := counts + ' argument'
    else
      counts := counts + ' arguments';
    if known.Paired < known.Max then
      counts := Format('%s, those after %d in pairs', [counts, known.Paired]);
    Result := Fail(Format('%s takes %s, not %d', [known.Name, counts, count]));
  end;

  // a quoted text or sheet name: the index of its closing quote (a doubled one is inside), 0 when there is none
  function ClosingQuote(aQuote: Char): integer;
  begin
    Result := i + 1;
    while Result <= last do
    begin
      if aFormula[Result] = aQuote then
      begin
        if (Result < last) and (aFormula[Result + 1] = aQuote) then
          Inc(Result)
        else
          Exit;
      end;
      Inc(Result);
    end;
    Result := 0;
  end;

  // a value where one may stand: next to another only through spaces, both references (an intersection)
  function Value(aConstant: boolean): boolean;
  begin
    Result := False;
    if not expectValue and not (spaced and not constant and not aConstant and (Inside <> '{')) then
      Exit(Fail('two values without an operator between them'));
    if (Inside = '{') and not aConstant then
      Exit(Fail('an array constant holds constants only'));
    if (ranged or prefixed) and aConstant then
      Exit(Fail('a reference missing'));
    if aConstant then
      NotAReference;
    expectValue := False;
    constant := aConstant;
    spaced := False;
    ranged := False;
    arguments := False;
    prefixed := False;
    Result := True;
  end;

  // anything but a value: not right after Sheet1!, a table's name or a :
  function NotAValue: boolean;
  begin
    Result := not prefixed and not continued and not ranged;
    if not Result then
      Fail('a reference missing');
    spaced := False;
  end;

  // a word: a reference alone or as one end of a range (moved, or #REF!), a number, TRUE, a name
  function Word(aEnd: integer): boolean;
  begin
    var word: string := Copy(aFormula, i, aEnd - i);
    var row, column: integer;
    var rowFixed, columnFixed: boolean;
    var kind: TReferenceKind := ReadReference(word, row, column, rowFixed, columnFixed);
    var secondEnd: integer := 0;
    var row2, column2: integer;
    var rowFixed2, columnFixed2: boolean;
    if (kind <> rkNone) and (aEnd < last) and (aFormula[aEnd] = ':') and IsWordStart(aFormula[aEnd + 1]) then
    begin
      secondEnd := ReadWord(aEnd + 1);
      if ReadReference(Copy(aFormula, aEnd + 1, secondEnd - aEnd - 1), row2, column2, rowFixed2, columnFixed2) <> kind then
        secondEnd := 0;
    end;
    if (kind = rkNone) or ((kind <> rkCell) and (secondEnd = 0)) then
    begin // a number, TRUE, a name
      var isNumber: boolean := CharInSet(word[1], ['0' .. '9', '.']);
      if isNumber then
      begin // the exponent's sign was not part of the word: 1.5E+3
        if CharInSet(word[word.Length], ['E', 'e']) and (aEnd < last) and CharInSet(aFormula[aEnd], ['+', '-']) and
          CharInSet(aFormula[aEnd + 1], ['0' .. '9']) then
        begin
          aEnd := ReadWord(aEnd + 1);
          word := Copy(aFormula, i, aEnd - i);
        end;
        var number: Double;
        if not TUtility.TryFloatFromText(word, number) then
          Exit(Fail('not a number: ' + word));
      end;
      if not Value(isNumber or SameText(word, 'TRUE') or SameText(word, 'FALSE')) then
        Exit(False);
      builder.Append(word);
      i := aEnd;
      Exit(True);
    end;
    if not Value(False) then
      Exit(False);
    if secondEnd = 0 then
      secondEnd := aEnd
    else
      word := Copy(aFormula, i, secondEnd - i);
    var moved, moved2: string;
    if (aRows = 0) and (aColumns = 0) then
      builder.Append(word)
    else if not MoveReference(kind, row, column, rowFixed, columnFixed, aRows, aColumns, moved) or
      ((secondEnd > aEnd) and not MoveReference(kind, row2, column2, rowFixed2, columnFixed2, aRows, aColumns, moved2)) then
      builder.Append('#REF!')
    else if secondEnd > aEnd then
      builder.Append(moved).Append(':').Append(moved2)
    else
      builder.Append(moved);
    i := secondEnd;
    Result := True;
  end;

  function HasPrefix(const aWord, aPrefix: string): boolean;
  begin
    Result := SameText(Copy(aWord, 1, aPrefix.Length), aPrefix);
  end;

  function Unprefixed(const aWord: string): string;
  begin
    Result := aWord;
    if HasPrefix(Result, cParameterPrefix) then
      Result := Result.Substring(cParameterPrefix.Length);
  end;

  // LET's or LAMBDA's parameter ending before aEnd, declared or used; called when a ( follows (LET(f,LAMBDA(x,x+1),f(5)))
  function Parameter(aEnd: integer): boolean;
  begin
    var name: string := Unprefixed(Copy(aFormula, i, aEnd - i));
    var declaring: boolean := Declares(aEnd);
    if not Value(False) then
      Exit(False);
    if declaring then
      parameters.Add(name)
    else
      name := Declared(name);
    if aForm = ffStored then
      builder.Append(cParameterPrefix);
    builder.Append(name);
    i := aEnd;
    if (i <= last) and (aFormula[i] = '(') then
    begin
      called := True;
      calledFunction := cResult;
    end;
    Result := True;
  end;

  // a function's name ending before aEnd, its ( next: one of Excel's in aForm, upper case; another as it is
  function FunctionName(aEnd: integer): boolean;
  begin
    if not Value(False) then
      Exit(False);
    var word: string := Copy(aFormula, i, aEnd - i);
    var name: string := word;
    while HasPrefix(name, '_xlfn.') or HasPrefix(name, '_xlws.') do
      name := name.Substring(6);
    calledFunction := FindFunction(name);
    if calledFunction >= 0 then
    begin
      if not cFunctions[calledFunction].ReferenceResult then
        NotAReference;
      if aForm = ffStored then
        builder.Append(cFunctionPrefixes[cFunctions[calledFunction].Prefix]);
      builder.Append(cFunctions[calledFunction].Name);
    end
    else
    begin
      calledFunction := cUnknown;
      if (aUnknown = '') and not HasPrefix(word, '_xl') then // _xludf.: a user's function the file names so
        aUnknown := word;
      builder.Append(word);
    end;
    called := True;
    i := aEnd;
    Result := True;
  end;

  function Token: boolean;
  begin
    Result := False;
    var letter: Char := aFormula[i];
    var start: integer := i;
    var wasCallable: boolean := callable;
    callable := False;
    if CharInSet(letter, cSpaces) then
    begin
      if not expectValue then
        spaced := True;
      builder.Append(letter);
      Inc(i);
      Exit(True);
    end;
    case letter of
      '"':
        begin
          var close: integer := ClosingQuote(letter);
          if close = 0 then
            Exit(Fail('a text without its closing quote'));
          if not Value(True) then
            Exit;
          i := close + 1;
        end;
      '''':
        begin // a sheet name, its ! with it
          var close: integer := ClosingQuote(letter);
          if close = 0 then
            Exit(Fail('a sheet name without its closing quote'));
          if (close = last) or (aFormula[close + 1] <> '!') then
            Exit(Fail('a quoted sheet name without ! after it'));
          if not expectValue and not spaced then
            Exit(Fail('two values without an operator between them'));
          prefixed := True;
          i := close + 2;
        end;
      '[':
        begin // a table's columns (Table1[[#This Row],[Sum]], ' escapes) or another workbook ([1]Sheet1!A1)
          var close: integer := i;
          var depth: integer := 0;
          while close <= last do
          begin
            case aFormula[close] of
              '''':
                Inc(close);
              '[':
                Inc(depth);
              ']':
                begin
                  Dec(depth);
                  if depth = 0 then
                    Break;
                end;
            end;
            Inc(close);
          end;
          if close > last then
            Exit(Fail('a [ without its ]'));
          i := close + 1;
          if continued then
            continued := False
          else if (i <= last) and (IsWordStart(aFormula[i]) or (aFormula[i] = '''')) then
            // a workbook: its sheet's name follows
          else if (i <= last) and (aFormula[i] = '!') then
          begin // a workbook's name: [1]!Total
            prefixed := True;
            Inc(i);
          end
          else if not Value(False) then
            Exit;
        end;
      '#':
        begin
          var error: string := '';
          for var index := Low(cErrors) to High(cErrors) do
            if SameText(Copy(aFormula, i, cErrors[index].Length), cErrors[index]) then
              error := cErrors[index];
          if error.IsEmpty then
            Exit(Fail('an error value Excel does not have'));
          if not Value(error <> '#REF!') then // Sheet1!#REF! stands for a reference
            Exit;
          builder.Append(error);
          Inc(i, error.Length);
          Exit(True);
        end;
      '(':
        begin
          if not NotAValue then
            Exit;
          SetLength(commas, brackets.Length + 1);
          SetLength(functions, brackets.Length + 1);
          SetLength(scopes, brackets.Length + 1);
          SetLength(referenceLike, brackets.Length + 1);
          commas[brackets.Length] := 0;
          if called then
            OpenFunction(calledFunction)
          else if wasCallable and not expectValue then
            OpenFunction(cResult)
          else if expectValue and (Inside <> '{') then
          begin
            brackets := brackets + 'g';
            arguments := False;
          end
          else
            Exit(Fail('a ( where an operator should be'));
          Inc(i);
        end;
      ')':
        begin
          if not NotAValue then
            Exit;
          case Inside of
            'f':
              if expectValue and not arguments then
                Exit(Fail('an operator without the value after it'))
              else if not CloseFunction then
                Exit;
            'g':
              if expectValue then
                Exit(Fail('a ( ) without a value inside'));
          else
            Exit(Fail('a ) without its opening one'));
          end;
          brackets := Copy(brackets, 1, brackets.Length - 1);
          expectValue := False;
          constant := False;
          arguments := False;
          Inc(i);
        end;
      '{':
        begin
          if not NotAValue then
            Exit;
          if not expectValue or (Inside = '{') then
            Exit(Fail('a { where it cannot stand'));
          brackets := brackets + '{';
          arguments := False;
          Inc(i);
        end;
      '}':
        begin
          if not NotAValue then
            Exit;
          if Inside <> '{' then
            Exit(Fail('a } without its opening one'));
          if expectValue then
            Exit(Fail('an array constant with a value missing'));
          brackets := Copy(brackets, 1, brackets.Length - 1);
          expectValue := True; // the array is the value
          if not Value(True) then
            Exit;
          Inc(i);
        end;
      ',':
        begin
          if not NotAValue then
            Exit;
          case Inside of
            'f':
              begin
                if not CheckReference(commas[brackets.Length - 1]) then
                  Exit;
                arguments := True; // an argument may be left out: IF(A1,,2)
                Inc(commas[brackets.Length - 1]);
                if commas[brackets.Length - 1] >= cMaxArguments then
                  Exit(Fail(Format('more than %d arguments to a function', [cMaxArguments])));
              end;
            'g', '{':
              if expectValue then
                Exit(Fail('a comma without a value before it'));
          else
            Exit(Fail('a comma outside a function''s brackets'));
          end;
          expectValue := True;
          Inc(i);
        end;
      ';':
        begin
          if not NotAValue then
            Exit;
          if (Inside <> '{') or expectValue then
            Exit(Fail('a ; outside an array constant''s rows'));
          expectValue := True;
          Inc(i);
        end;
      '%':
        begin
          if not NotAValue then
            Exit;
          if expectValue or (Inside = '{') then
            Exit(Fail('a % without a value before it'));
          NotAReference;
          Inc(i);
        end;
    else
      if IsWordStart(letter) then
      begin
        var after: integer := ReadWord(i);
        var next: Char := #0;
        if after <= last then
          next := aFormula[after];
        // a 3-D reference's sheets: Sheet1:Sheet3!A1
        var sheetsEnd: integer := 0;
        if (next = ':') and (after < last) and IsWordStart(aFormula[after + 1]) then
        begin
          sheetsEnd := ReadWord(after + 1);
          if (sheetsEnd > last) or (aFormula[sheetsEnd] <> '!') then
            sheetsEnd := 0;
        end;
        if (sheetsEnd > 0) or (next = '!') then
        begin // a sheet's name
          if prefixed or (not expectValue and not spaced) then
            Exit(Fail('two values without an operator between them'));
          prefixed := True;
          if sheetsEnd > 0 then
            i := sheetsEnd + 1
          else
            i := after + 1;
        end
        else if Declares(after) or (Declared(Unprefixed(Copy(aFormula, i, after - i))) <> '') then
          Exit(Parameter(after))
        else if next = '(' then
          Exit(FunctionName(after))
        else if next = '[' then
        begin // a table: its [...] follows
          if not Value(False) then
            Exit;
          continued := True;
          i := after;
        end
        else
          Exit(Word(after));
      end
      else if CharInSet(letter, cOperators) then
      begin
        if not NotAValue then
          Exit;
        if CharInSet(letter, ['+', '-']) and expectValue then
        begin // a sign
          arguments := False;
          NotAReference;
          Inc(i);
        end
        else if expectValue or (Inside = '{') then
          Exit(Fail('an operator without the value before it'))
        else
        begin
          if (letter = ':') and constant then
            Exit(Fail('a range of a constant'));
          ranged := letter = ':';
          if not ranged then
            NotAReference;
          Inc(i);
          if ((letter = '<') and (i <= last) and CharInSet(aFormula[i], ['>', '='])) or
            ((letter = '>') and (i <= last) and (aFormula[i] = '=')) then
            Inc(i);
          expectValue := True;
        end;
      end
      else
        Exit(Fail('a character no formula has: ' + letter));
    end;
    builder.Append(aFormula, start - 1, i - start);
    Result := True;
  end;

begin
  aResult := '';
  aWhy := '';
  aUnknown := '';
  last := aFormula.Length;
  expectValue := True;
  constant := False;
  spaced := False;
  ranged := False;
  arguments := False;
  prefixed := False;
  continued := False;
  called := False;
  calledFunction := cUnknown;
  callable := False;
  brackets := '';
  parameters := nil;
  builder := TStringBuilder.Create(last + 16);
  try
    parameters := TList<string>.Create;
    i := 1;
    while i <= last do
      if not Token then
        Exit(False);
    if Inside = '{' then
      Exit(Fail('a { without its closing one'));
    if brackets <> '' then
      Exit(Fail('a ( without its closing one'));
    if prefixed or continued or ranged then
      Exit(Fail('a reference missing'));
    if expectValue then
      if aFormula.Trim = '' then
        Exit(Fail('an empty formula'))
      else
        Exit(Fail('an operator without the value after it'));
    aResult := builder.ToString;
    Result := True;
  finally
    parameters.Free;
    builder.Free;
  end;
end;

// a stored formula as Excel's Formula shows it (prefixes dropped); as it is when it does not read
function ShownFormula(const aStored: string): string;
begin
  var why, unknown: string;
  if not ShiftFormula(aStored, 0, 0, ffShown, Result, why, unknown) then
    Result := aStored;
end;

{ values }

// ST_Xstring: a character XML cannot hold is written as _xHHHH_, and so is an underscore that would read as one
function DecodeText(const aText: string): string;
begin
  if Pos('_x', aText) = 0 then
    Exit(aText);
  var builder: TStringBuilder := TStringBuilder.Create(aText.Length);
  try
    var i: integer := 1;
    while i <= aText.Length do
    begin
      var code: integer;
      if (aText[i] = '_') and (i + 6 <= aText.Length) and (aText[i + 1] = 'x') and (aText[i + 6] = '_') and
        TryStrToInt('$' + Copy(aText, i + 2, 4), code) then
      begin
        builder.Append(Char(code));
        Inc(i, 7);
      end
      else
      begin
        builder.Append(aText[i]);
        Inc(i);
      end;
    end;
    Result := builder.ToString;
  finally
    builder.Free;
  end;
end;

function EncodeText(const aText: string): string;
begin
  Result := aText;
  for var i := aText.Length downto 1 do
  begin
    var code: integer := Ord(aText[i]);
    if ((code < 32) and not (code in [9, 10, 13])) or (code = $FFFE) or (code = $FFFF) then
      Result := Copy(Result, 1, i - 1) + Format('_x%.4X_', [code]) + Copy(Result, i + 1, MaxInt)
    else if (code = Ord('_')) and (i + 6 <= aText.Length) and (aText[i + 1] = 'x') and (aText[i + 6] = '_') then
    begin
      var hex: integer;
      if TryStrToInt('$' + Copy(aText, i + 2, 4), hex) then
        Result := Copy(Result, 1, i - 1) + '_x005F_' + Copy(Result, i + 1, MaxInt);
    end;
  end;
end;

// a shared string or an inline one: plain text, or rich text in runs
function RichText(aItem: TRstCT): string;
begin
  Result := aItem.T;
  for var run: TREltCT in aItem.R do
    Result := Result + string(run.T);
  Result := DecodeText(Result);
end;

// Excel's serial numbers: days from 1899-12-30 as TDateTime, but in the 1900 system the serials before 1900-03-01 count a
// 1900-02-29 that never was (60 reads as 1900-02-28); a serial below 1 is a time of day
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

// False before the system's first day (1900-01-01, 1904-01-01); a TDateTime below 1 is a time of day
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

// Excel's built-in date and time formats, and a format code with day, month, year, hour or second outside quotes
function IsDateFormat(aId: cardinal; aStyles: TStyleSheetE): boolean;

  function IsDateCode(const aCode: string): boolean;
  begin
    if aCode.StartsWith('General', True) then
      Exit(False);
    var i: integer := 1;
    while i <= aCode.Length do
    begin
      case aCode[i] of
        ';':
          Exit(False); // the first section decides
        '"':
          begin
            Inc(i);
            while (i <= aCode.Length) and (aCode[i] <> '"') do
              Inc(i);
          end;
        '\', '_', '*':
          Inc(i);
        '[':
          begin
            var close: integer := Pos(']', aCode, i);
            if close = 0 then
              Exit(False);
            // elapsed time ([h]:mm) is a time; colors, conditions and locales ([Red], [>0], [$-409]) are not
            var inside: string := LowerCase(Copy(aCode, i + 1, close - i - 1));
            if (inside <> '') and ((inside.Trim(['h']) = '') or (inside.Trim(['m']) = '') or (inside.Trim(['s']) = '')) then
              Exit(True);
            i := close;
          end;
        'y', 'Y', 'm', 'M', 'd', 'D', 'h', 'H', 's', 'S':
          Exit(True);
      end;
      Inc(i);
    end;
    Result := False;
  end;

begin
  if aStyles.IsPresent('NumFmts') then
    for var numberFormat: TNumFmtCT in aStyles.NumFmts.NumFmt do
      if numberFormat.NumFmtId = aId then
        Exit(IsDateCode(DecodeText(numberFormat.FormatCode)));
  // 27-36 and 50-58: the East Asian ones
  Result := (aId <= 58) and (Byte(aId) in [14 .. 22, 27 .. 36, 45 .. 47, 50 .. 58]);
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

function Contains(const aOuter, aInner: TRange): boolean;
begin
  Result := (aInner.fTop >= aOuter.fTop) and (aInner.fBottom <= aOuter.fBottom) and (aInner.fLeft >= aOuter.fLeft) and
    (aInner.fRight <= aOuter.fRight);
end;

function Overlaps(const aLeft, aRight: TRange): boolean;
begin
  Result := (aLeft.fTop <= aRight.fBottom) and (aRight.fTop <= aLeft.fBottom) and (aLeft.fLeft <= aRight.fRight) and
    (aRight.fLeft <= aLeft.fRight);
end;

function AreaAt(aAreas: TList<TRange>; aRow, aColumn: integer; out aArea: TRange): boolean;
begin
  for var area: TRange in aAreas do
    if (aRow >= area.fTop) and (aRow <= area.fBottom) and (aColumn >= area.fLeft) and (aColumn <= area.fRight) then
    begin
      aArea := area;
      Exit(True);
    end;
  Result := False;
end;

// an item of an array for a range, from 0: two dimensions, or one (a row)
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

{ TRange }

function TRange.GetRowCount: integer;
begin
  Result := fBottom - fTop + 1;
end;

function TRange.GetColumnCount: integer;
begin
  Result := fRight - fLeft + 1;
end;

function TRange.GetAddress: string;
begin
  Result := CellName(fTop, fLeft);
  if (fBottom <> fTop) or (fRight <> fLeft) then
    Result := Result + ':' + CellName(fBottom, fRight);
end;

function TRange.GetValue: Variant;
begin
  if (fBottom = fTop) and (fRight = fLeft) then
  begin
    fSheet.CellValue(fSheet.FindCell(fTop, fLeft), Result);
    Exit;
  end;
  Result := VarArrayCreate([1, RowCount, 1, ColumnCount], varVariant);
  for var row := fTop to fBottom do
    for var column := fLeft to fRight do
    begin
      var value: Variant;
      fSheet.CellValue(fSheet.FindCell(row, column), value);
      Result[row - fTop + 1, column - fLeft + 1] := value;
    end;
end;

// an array as Excel takes it: its shape the range's (one dimension: a row)
procedure TRange.CheckShape(const aArray: Variant);
begin
  var rows, columns: integer;
  if VarArrayDimCount(aArray) = 2 then
  begin
    rows := VarArrayHighBound(aArray, 1) - VarArrayLowBound(aArray, 1) + 1;
    columns := VarArrayHighBound(aArray, 2) - VarArrayLowBound(aArray, 2) + 1;
  end
  else if VarArrayDimCount(aArray) = 1 then
  begin
    rows := 1;
    columns := VarArrayHighBound(aArray, 1) - VarArrayLowBound(aArray, 1) + 1;
  end
  else
    raise EArgumentException.Create('An array for a range has one or two dimensions');
  if (rows <> RowCount) or (columns <> ColumnCount) then
    raise EArgumentException.CreateFmt('An array of %d x %d for %s (%d x %d)', [rows, columns, Address, RowCount, ColumnCount]);
end;

procedure TRange.SetValue(const aValue: Variant);
begin
  var isArray: boolean := VarIsArray(aValue);
  if isArray then
    CheckShape(aValue);
  for var row := fTop to fBottom do
    for var column := fLeft to fRight do
      if isArray then
        fSheet.WriteValue(row, column, ArrayItem(aValue, row - fTop, column - fLeft), Self)
      else
        fSheet.WriteValue(row, column, aValue, Self);
end;

function TRange.GetValueType: TCellValueType;
begin
  var value: Variant;
  Result := fSheet.CellValue(fSheet.FindCell(fTop, fLeft), value);
end;

function TRange.GetAsString: string;
begin
  var value: Variant;
  case fSheet.CellValue(fSheet.FindCell(fTop, fLeft), value) of
    cvEmpty:
      Result := '';
    cvNumber:
      Result := FloatText(Double(value), ftDouble);
    cvDate:
      begin
        var date: TDateTime := VarToDateTime(value);
        if Frac(date) = 0 then
          Result := FormatDateTime('yyyy"-"mm"-"dd', date)
        else if Trunc(date) = 0 then
          Result := FormatDateTime('hh":"nn":"ss', date)
        else
          Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', date);
        if MilliSecondOf(date) <> 0 then
          Result := Result + FormatDateTime('"."zzz', date);
      end;
    cvBoolean:
      if value then
        Result := 'TRUE'
      else
        Result := 'FALSE';
  else
    Result := value;
  end;
end;

procedure TRange.SetAsString(const aValue: string);
begin
  SetValue(aValue);
end;

function TRange.GetAsFloat: Double;
begin
  var value: Variant;
  case fSheet.CellValue(fSheet.FindCell(fTop, fLeft), value) of
    cvEmpty:
      Result := 0;
    cvNumber:
      Result := value;
    cvDate: // the number stored, as Excel's Value2
      TUtility.TryFloatFromText(string(fSheet.FindCell(fTop, fLeft).V).Trim, Result);
    cvBoolean:
      Result := Ord(boolean(value));
  else
    if not TUtility.TryFloatFromText(string(value).Trim, Result) then
      raise EConvertError.CreateFmt('%s holds "%s", not a number', [Address, string(value)]);
  end;
end;

procedure TRange.SetAsFloat(aValue: Double);
begin
  SetValue(aValue);
end;

function TRange.GetAsInteger: Int64;
begin
  var number: Double := GetAsFloat;
  if (number < -9.2233720368547758E18) or (number >= 9.2233720368547758E18) then
    raise EConvertError.CreateFmt('%s holds %s, beyond an Int64', [Address, FloatText(number, ftDouble)]);
  Result := Round(number);
end;

procedure TRange.SetAsInteger(aValue: Int64);
begin
  SetValue(aValue);
end;

function TRange.GetAsDateTime: TDateTime;
begin
  var value: Variant;
  case fSheet.CellValue(fSheet.FindCell(fTop, fLeft), value) of
    cvEmpty:
      Result := 0;
    cvNumber:
      Result := SerialToDate(value, fSheet.fWorkbook.Date1904);
    cvDate:
      Result := VarToDateTime(value);
  else
    if not TryISO8601ToDate(string(value), Result, False) then
      raise EConvertError.CreateFmt('%s holds "%s", not a date', [Address, string(value)]);
  end;
end;

procedure TRange.SetAsDateTime(aValue: TDateTime);
begin
  SetValue(VarFromDateTime(aValue));
end;

function TRange.GetAsBoolean: boolean;
begin
  var value: Variant;
  case fSheet.CellValue(fSheet.FindCell(fTop, fLeft), value) of
    cvEmpty:
      Result := False;
    cvBoolean:
      Result := value;
    cvNumber, cvDate:
      Result := Double(value) <> 0;
  else
    if SameText(value, 'TRUE') then
      Result := True
    else if SameText(value, 'FALSE') then
      Result := False
    else
      raise EConvertError.CreateFmt('%s holds "%s", not a Boolean', [Address, string(value)]);
  end;
end;

procedure TRange.SetAsBoolean(aValue: boolean);
begin
  SetValue(aValue);
end;

procedure TRange.ClearContents;
begin
  fSheet.ClearContents(Self);
end;

function TRange.GetFormula: Variant;

  function CellFormula(aRow, aColumn: integer): string;
  begin
    if fSheet.FormulaText(aRow, aColumn, Result) then
      Result := '=' + ShownFormula(Result);
  end;

begin
  if (fBottom = fTop) and (fRight = fLeft) then
    Exit(CellFormula(fTop, fLeft));
  Result := VarArrayCreate([1, RowCount, 1, ColumnCount], varVariant);
  for var row := fTop to fBottom do
    for var column := fLeft to fRight do
      Result[row - fTop + 1, column - fLeft + 1] := CellFormula(row, column);
end;

procedure TRange.SetFormula(const aValue: Variant);
begin
  var text: string;
  if VarIsArray(aValue) then
  begin
    CheckShape(aValue);
    for var row := fTop to fBottom do
      for var column := fLeft to fRight do
      begin
        var item: Variant := ArrayItem(aValue, row - fTop, column - fLeft);
        if IsNoFormula(item) then
          fSheet.ClearContents(fSheet.MakeRange(row, column, row, column))
        else if fSheet.CheckFormula(row, column, item, text) then
          fSheet.WriteFormula(row, column, text, Self);
      end;
  end
  else if IsNoFormula(aValue) then
    ClearContents
  else if fSheet.CheckFormula(fTop, fLeft, aValue, text) then // checked once, moved to each cell as Excel fills
    for var row := fTop to fBottom do
      for var column := fLeft to fRight do
      begin
        var moved, why, unknown: string;
        ShiftFormula(text, row - fTop, column - fLeft, ffStored, moved, why, unknown);
        fSheet.WriteFormula(row, column, moved, Self);
      end;
end;

function TRange.GetHasFormula: boolean;
begin
  for var row := fTop to fBottom do
    for var column := fLeft to fRight do
    begin
      var text: string;
      if not fSheet.FormulaText(row, column, text) then
        Exit(False);
    end;
  Result := True;
end;

function TRange.GetHasArray: boolean;
begin
  fSheet.FindFormulas;
  var area: TRange;
  Result := AreaAt(fSheet.fArrays, fTop, fLeft, area);
end;

function TRange.GetCurrentArray: TRange;
begin
  fSheet.FindFormulas;
  if not AreaAt(fSheet.fArrays, fTop, fLeft, Result) then
    raise EInvalidOpException.CreateFmt('%s!%s is not in an array formula', [fSheet.Name, CellName(fTop, fLeft)]);
end;

function TRange.GetFormulaArray: string;
begin
  Result := '';
  if HasArray and fSheet.FormulaText(fTop, fLeft, Result) then
    Result := '=' + ShownFormula(Result);
end;

procedure TRange.SetFormulaArray(const aValue: string);
begin
  if aValue = '' then
    ClearContents
  else
    fSheet.WriteArray(Self, aValue);
end;

{ TWorksheet }

destructor TWorksheet.Destroy;
begin
  ForgetFormulas;
  fPivots.Free;
  fTableRows.Free;
  fTables.Free;
  inherited;
end;

function TWorksheet.GetXml: TWorksheetE;
begin
  Result := Objects(True);
end;

function TWorksheet.Objects(aEdit: boolean): TWorksheetE;
begin
  if aEdit then
    Result := TWorksheetE(fWorkbook.EditPart(fPartName))
  else
    Result := TWorksheetE(fWorkbook.ReadPart(fPartName));
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
      var cellColumn: integer := ColumnOf(cell.R);
      if cellColumn = 0 then
      begin
        cellColumn := column + 1;
        cell.R := CellName(rowNumber, cellColumn);
      end;
      column := cellColumn;
    end;
  end;
end;

function TWorksheet.FindRow(aSheet: TWorksheetE; aRow: integer; out aIndex: integer): boolean;
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

// binary search: the cells of a row by column
function FindInRow(aRow: TRowCT; aColumn: integer; out aIndex: integer): boolean;
begin
  var cells: TCellCTList := aRow.C;
  var low: integer := 0;
  var high: integer := cells.Count - 1;
  while low <= high do
  begin
    var middle: integer := (low + high) shr 1;
    var column: integer := ColumnOf(cells[middle].R);
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

function TWorksheet.FindCell(aRow, aColumn: integer): TCellCT;
begin
  Result := nil;
  var sheet: TWorksheetE := Objects(False);
  var rowIndex, cellIndex: integer;
  if FindRow(sheet, aRow, rowIndex) and FindInRow(sheet.SheetData.Row[rowIndex], aColumn, cellIndex) then
    Result := sheet.SheetData.Row[rowIndex].C[cellIndex];
end;

// the style a new cell takes, as in Excel: a formatted row's, else its column's
function TWorksheet.EffectiveStyle(aRow, aColumn: integer): cardinal;
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

function TWorksheet.CellValue(aCell: TCellCT; out aValue: Variant): TCellValueType;
begin
  aValue := Unassigned;
  if aCell = nil then
    Exit(cvEmpty);
  var hasValue: boolean := aCell.Present[@aCell.V];
  if aCell.T = stctInlineStr then
  begin
    if not aCell.IsPresent('Is') then
      Exit(cvEmpty);
    aValue := RichText(aCell.&Is);
    Exit(cvText);
  end;
  if not hasValue then
    Exit(cvEmpty);
  case aCell.T of
    stctS:
      begin
        aValue := fWorkbook.SharedString(StrToIntDef(aCell.V, -1));
        Result := cvText;
      end;
    stctStr:
      begin
        aValue := DecodeText(aCell.V);
        Result := cvText;
      end;
    stctB:
      begin
        aValue := (aCell.V = '1') or SameText(aCell.V, 'true');
        Result := cvBoolean;
      end;
    stctE:
      begin
        aValue := string(aCell.V);
        Result := cvError;
      end;
  else
    var number: Double;
    if not TUtility.TryFloatFromText(string(aCell.V).Trim, number) then
    begin // not a number: shown as it is
      aValue := string(aCell.V);
      Exit(cvText);
    end;
    if fWorkbook.IsDateStyle(aCell.S) then
    begin
      aValue := VarFromDateTime(SerialToDate(number, fWorkbook.Date1904));
      Result := cvDate;
    end
    else
    begin
      aValue := number;
      Result := cvNumber;
    end;
  end;
end;

// Excel's refusal: the cell keeps its value, the rest is done
procedure TWorksheet.Refuse(aRow, aColumn: integer; const aCode, aWhy: string);
begin
  fWorkbook.fIssues.Add(isError, aCode, fName + '!' + CellName(aRow, aColumn), aWhy + ' - not written');
end;

// on a protected sheet, a cell its style does not unlock
function TWorksheet.IsLocked(aRow, aColumn: integer): boolean;
begin
  var sheet: TWorksheetE := Objects(False);
  Result := sheet.IsPresent('SheetProtection') and sheet.SheetProtection.Sheet and
    fWorkbook.IsLockedStyle(EffectiveStyle(aRow, aColumn));
end;

// the areas of array formulas and data tables, shared formulas' first cells: found once, again after one of them changes
procedure TWorksheet.FindFormulas;
begin
  if fArrays <> nil then
    Exit;
  fArrays := TList<TRange>.Create;
  fDataTables := TList<TRange>.Create;
  fShared := TDictionary<cardinal, TCellCT>.Create;
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
          var area: TRange := MakeRange(0, 0, 0, 0);
          if not ParseAddress(cell.F.Ref, area.fTop, area.fLeft, area.fBottom, area.fRight) then
            ParseAddress(cell.R, area.fTop, area.fLeft, area.fBottom, area.fRight);
          if cell.F.T = stcftArray then
            fArrays.Add(area)
          else
            fDataTables.Add(area);
        end;
end;

procedure TWorksheet.ForgetFormulas;
begin
  FreeAndNil(fArrays);
  FreeAndNil(fDataTables);
  FreeAndNil(fShared);
end;

// tables (their header and totals rows apart) and pivot tables, from their own parts: found on the first write
procedure TWorksheet.FindFixedAreas;
begin
  if fTables <> nil then
    Exit;
  fTables := TList<TRange>.Create;
  fTableRows := TList<TRange>.Create;
  fPivots := TList<TRange>.Create;
  fWorkbook.FixedAreas(fPartName, fTables, fTableRows, fPivots);
end;

// the formula without its =: a shared one's cells the first one's text moved to them, an array formula's and a data table's
// cells their first one's
function TWorksheet.FormulaText(aRow, aColumn: integer; out aText: string): boolean;
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
          FindFormulas;
          var first: TCellCT;
          var top, left, bottom, right: integer;
          if fShared.TryGetValue(cell.F.Si, first) and ParseAddress(first.R, top, left, bottom, right) then
          begin
            var why, unknown: string;
            ShiftFormula(DecodeText(first.F.XmlValue), aRow - top, aColumn - left, ffStored, aText, why, unknown);
          end;
        end;
      stcftDataTable:
        aText := TableFormula(cell.F);
    else
      aText := DecodeText(cell.F.XmlValue);
    end;
  if aText = '' then
  begin
    FindFormulas;
    var area: TRange;
    if (AreaAt(fArrays, aRow, aColumn, area) or AreaAt(fDataTables, aRow, aColumn, area)) and
      ((area.fTop <> aRow) or (area.fLeft <> aColumn)) then
      FormulaText(area.fTop, area.fLeft, aText);
  end;
  Result := aText <> '';
end;

// the text to store - without its =, checked, Excel's prefixes added; False: refused at the cell. A function Excel does not
// have is written with a warning: a local name (SUMME) is one, a VBA or add-in function too
function TWorksheet.CheckFormula(aRow, aColumn: integer; const aFormula: Variant; out aText: string): boolean;
begin
  Result := False;
  if not VarIsStr(aFormula) then
    raise EArgumentException.CreateFmt('A formula is a string, not a Variant of type %d', [VarType(aFormula)]);
  var text: string := aFormula;
  if text.StartsWith('=') then
    text := text.Substring(1);
  var why, unknown: string;
  if text.Length + 1 > cMaxFormula then
    Refuse(aRow, aColumn, 'Formula', Format('%d characters, Excel''s formulas hold up to %d', [text.Length + 1, cMaxFormula]))
  else if not ShiftFormula(text, 0, 0, ffStored, aText, why, unknown) then
    Refuse(aRow, aColumn, 'Formula', 'not a formula Excel reads: ' + why)
  else
  begin
    if unknown <> '' then
      fWorkbook.fIssues.Add(isWarning, 'Function', fName + '!' + CellName(aRow, aColumn),
        unknown + ' is not one of Excel''s functions (English)');
    Result := True;
  end;
end;

// a shared formula's cells as plain ones, each its own text (the values Excel calculated stay); False: its text unreadable
function TWorksheet.Unshare(aIndex: cardinal): boolean;
begin
  FindFormulas;
  var first: TCellCT;
  var area: TRange;
  if not fShared.TryGetValue(aIndex, first) then
    Exit(True); // no first cell: nothing the others could be read from
  var text: string := DecodeText(first.F.XmlValue);
  var checked, why, unknown: string;
  if not ParseAddress(first.F.Ref, area.fTop, area.fLeft, area.fBottom, area.fRight) or
    not ShiftFormula(text, 0, 0, ffStored, checked, why, unknown) then
    Exit(False);
  var top, left, bottom, right: integer;
  ParseAddress(first.R, top, left, bottom, right);
  var sheet: TWorksheetE := Objects(True);
  var rowIndex: integer;
  FindRow(sheet, area.fTop, rowIndex);
  var rows: TRowCTList := sheet.SheetData.Row;
  while (rowIndex < rows.Count) and (rows[rowIndex].R <= cardinal(area.fBottom)) do
  begin
    var row: TRowCT := rows[rowIndex];
    for var cell: TCellCT in row.C do
      if cell.IsPresent('F') and (cell.F.T = stcftShared) and (cell.F.Si = aIndex) then
      begin
        var moved: string;
        ShiftFormula(text, integer(row.R) - top, ColumnOf(cell.R) - left, ffStored, moved, why, unknown);
        cell.F.Clear('T');
        cell.F.Clear('Si');
        cell.F.Clear('Ref');
        cell.F.XmlValue := EncodeText(moved);
      end;
    Inc(rowIndex);
  end;
  ForgetFormulas;
  fWorkbook.FormulaChanged;
  Result := True;
end;

// why a cell cannot be written as part of aTarget: an array formula not wholly in it (Excel changes one only as a whole), a
// data table (Excel's what-if analysis fills it), a table's header or totals row (the table's own definition, a header its
// column's name in formulas), a pivot table (Excel builds it from its cache)
function TWorksheet.Blocker(aRow, aColumn: integer; const aTarget: TRange; out aCode, aWhy: string): boolean;
begin
  Result := True;
  FindFormulas;
  FindFixedAreas;
  var area: TRange;
  aCode := 'Formula';
  if AreaAt(fArrays, aRow, aColumn, area) and not Contains(aTarget, area) then
    aWhy := 'part of an array formula (' + area.Address + '), which Excel changes only as a whole'
  else if AreaAt(fDataTables, aRow, aColumn, area) then
    aWhy := 'part of a data table, which Excel''s what-if analysis fills'
  else if AreaAt(fTableRows, aRow, aColumn, area) then
  begin
    aCode := 'TableRow';
    aWhy := 'a table''s header or totals row (part of the table''s definition, which Calcite does not change yet)';
  end
  else if AreaAt(fPivots, aRow, aColumn, area) then
  begin
    aCode := 'PivotTable';
    aWhy := 'part of a pivot table, which Excel builds again';
  end
  else
    Result := False;
end;

// False: refused (Blocker), or a shared formula Calcite cannot read holds the cell; True: a shared one is made plain first
function TWorksheet.CanWrite(aRow, aColumn: integer; const aTarget: TRange): boolean;
begin
  var code, why: string;
  if Blocker(aRow, aColumn, aTarget, code, why) then
  begin
    Refuse(aRow, aColumn, code, why);
    Exit(False);
  end;
  var cell: TCellCT := FindCell(aRow, aColumn);
  if (cell <> nil) and cell.IsPresent('F') and (cell.F.T = stcftShared) and not Unshare(cell.F.Si) then
  begin
    Refuse(aRow, aColumn, 'Formula', 'part of a shared formula whose text Calcite cannot read');
    Exit(False);
  end;
  if not fLockedWritten and IsLocked(aRow, aColumn) then
  begin
    fLockedWritten := True;
    fWorkbook.fIssues.Add(isWarning, 'Locked', fName + '!' + CellName(aRow, aColumn),
      'a locked cell of a protected sheet, written: Excel lets its users change it only unprotected (reported once a sheet)');
  end;
  Result := True;
end;

// the cell, created where Excel expects it (rows in order, cells by column), with its value removed
function TWorksheet.CellForWriting(aRow, aColumn: integer): TCellCT;
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
  begin
    Result := row.C[cellIndex];
    RemoveValue(Result);
  end
  else
  begin
    Result := TCellCT.Create;
    Result.R := CellName(aRow, aColumn);
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
      var top, left, bottom, right: integer;
      if ParseAddress(sheet.Dimension.Ref, top, left, bottom, right) and
        ((aRow < top) or (aRow > bottom) or (aColumn < left) or (aColumn > right)) then
        sheet.Dimension.Ref := MakeRange(Min(top, aRow), Min(left, aColumn), Max(bottom, aRow), Max(right, aColumn)).Address;
    end;
  end;
  fWorkbook.ValueChanged;
end;

procedure TWorksheet.RemoveValue(aCell: TCellCT);
begin
  if (aCell.T = stctS) and aCell.Present[@aCell.V] then
    fWorkbook.SharedStringReleased;
  if aCell.IsPresent('F') then
  begin
    if aCell.F.T <> stcftNormal then
      ForgetFormulas;
    aCell.Clear('F');
    fWorkbook.FormulaChanged;
  end;
  aCell.Clear('Is');
  aCell.Clear(@aCell.V);
  aCell.Clear(@aCell.T);
  // cell and value metadata (dynamic arrays, rich values) belong to the value
  aCell.Clear(@aCell.Cm);
  aCell.Clear(@aCell.Vm);
end;

procedure TWorksheet.WriteNumber(aRow, aColumn: integer; aValue: Double; const aTarget: TRange);
begin
  if IsNan(aValue) or IsInfinite(aValue) then
    Refuse(aRow, aColumn, 'Value', 'Excel holds no NaN or infinity')
  else if CanWrite(aRow, aColumn, aTarget) then
    CellForWriting(aRow, aColumn).V := FloatText(aValue, ftDouble);
end;

procedure TWorksheet.WriteDate(aRow, aColumn: integer; aValue: TDateTime; const aTarget: TRange);
begin
  var serial: Double;
  if not DateToSerial(aValue, fWorkbook.Date1904, serial) then
  begin
    Refuse(aRow, aColumn, 'Value', 'a date before the first one Excel has (' + DateToISO8601(aValue) + ')');
    Exit;
  end;
  if not CanWrite(aRow, aColumn, aTarget) then
    Exit;
  var style: integer := EffectiveStyle(aRow, aColumn);
  if not fWorkbook.IsDateStyle(style) then
  begin
    var numberFormat: integer := cDateTimeFormat;
    if serial < 1 then
      numberFormat := cTimeFormat
    else if Frac(serial) = 0 then
      numberFormat := cDateFormat;
    style := fWorkbook.DateStyle(style, numberFormat);
    if style < 0 then
    begin
      Refuse(aRow, aColumn, 'NoStyles', 'a date needs a date format, and the workbook has no styles to add one to');
      Exit;
    end;
  end;
  var cell: TCellCT := CellForWriting(aRow, aColumn);
  cell.S := style;
  cell.V := FloatText(serial, ftDouble);
end;

procedure TWorksheet.WriteText(aRow, aColumn: integer; const aValue: string; const aTarget: TRange);
begin
  if aValue.Length > cMaxText then
    Refuse(aRow, aColumn, 'Value', Format('%d characters, Excel''s cells hold up to %d', [aValue.Length, cMaxText]))
  else if CanWrite(aRow, aColumn, aTarget) then
  begin
    var index: integer := fWorkbook.SharedStringIndex(aValue);
    if index < 0 then
      Refuse(aRow, aColumn, 'NoSharedStrings', 'the workbook has no shared strings and no content types to add them to')
    else
    begin
      var cell: TCellCT := CellForWriting(aRow, aColumn);
      cell.T := stctS;
      cell.V := IntToStr(index);
    end;
  end;
end;

procedure TWorksheet.WriteBoolean(aRow, aColumn: integer; aValue: boolean; const aTarget: TRange);
begin
  if CanWrite(aRow, aColumn, aTarget) then
  begin
    var cell: TCellCT := CellForWriting(aRow, aColumn);
    cell.T := stctB;
    cell.V := IntToStr(Ord(aValue));
  end;
end;

procedure TWorksheet.WriteValue(aRow, aColumn: integer; const aValue: Variant; const aTarget: TRange);
begin
  case VarType(aValue) of
    varEmpty, varNull:
      ClearContents(MakeRange(aRow, aColumn, aRow, aColumn));
    varSmallint, varInteger, varShortInt, varByte, varWord, varLongWord, varInt64, varUInt64, varSingle, varDouble, varCurrency:
      WriteNumber(aRow, aColumn, aValue, aTarget);
    varDate:
      WriteDate(aRow, aColumn, VarToDateTime(aValue), aTarget);
    varBoolean:
      WriteBoolean(aRow, aColumn, aValue, aTarget);
    varOleStr, varString, varUString:
      if string(aValue) = '' then // as in Excel
        ClearContents(MakeRange(aRow, aColumn, aRow, aColumn))
      else
        WriteText(aRow, aColumn, aValue, aTarget);
  else
    raise EArgumentException.CreateFmt('A cell takes a number, a date, a string or a Boolean, not a Variant of type %d',
      [VarType(aValue)]);
  end;
end;

procedure TWorksheet.WriteFormula(aRow, aColumn: integer; const aText: string; const aTarget: TRange);
begin
  if CanWrite(aRow, aColumn, aTarget) then
  begin
    CellForWriting(aRow, aColumn).F.XmlValue := EncodeText(aText);
    fWorkbook.FormulaChanged;
  end;
end;

// the range as one array formula, written whole or not at all: its first cell holds it, Excel fills the others when it
// calculates
procedure TWorksheet.WriteArray(const aRange: TRange; const aFormula: string);
begin
  var text: string;
  if not CheckFormula(aRange.fTop, aRange.fLeft, aFormula, text) then
    Exit;
  FindFormulas;
  FindFixedAreas;
  var why: string := '';
  for var area: TRange in fArrays do
    if Overlaps(area, aRange) and not Contains(aRange, area) then
      why := 'part of an array formula (' + area.Address + '), which Excel changes only as a whole';
  for var area: TRange in fDataTables do
    if Overlaps(area, aRange) then
      why := 'a data table, which Excel''s what-if analysis fills';
  for var area: TRange in fTableRows do
    if Overlaps(area, aRange) then
      why := 'a table''s header or totals row (part of the table''s definition, which Calcite does not change yet)';
  if (aRange.RowCount > 1) or (aRange.ColumnCount > 1) then
    for var area: TRange in fTables do
      if Overlaps(area, aRange) then
        why := 'a table, where Excel allows no array formula of several cells';
  for var area: TRange in fPivots do
    if Overlaps(area, aRange) then
      why := 'a pivot table, which Excel builds again';
  if why <> '' then
  begin
    Refuse(aRange.fTop, aRange.fLeft, 'Formula', 'an array formula over ' + why);
    Exit;
  end;
  ClearContents(aRange);
  if not CanWrite(aRange.fTop, aRange.fLeft, aRange) then
    Exit;
  var formula: TCellFormulaCT := CellForWriting(aRange.fTop, aRange.fLeft).F;
  formula.T := stcftArray;
  formula.Ref := aRange.Address;
  formula.XmlValue := EncodeText(text);
  ForgetFormulas;
  fWorkbook.FormulaChanged;
end;

procedure TWorksheet.ClearContents(const aRange: TRange);

  // nothing left but its address: Excel keeps a cell with a format, a row with its own settings
  function IsBare(aObject: TXmlite; const aProperties: array of string): boolean;
  begin
    if (aObject.XmlAttributes <> nil) and (aObject.XmlAttributes.Count > 0) then
      Exit(False);
    for var name: string in aProperties do
      if aObject.IsPresent(name) then
        Exit(False);
    Result := True;
  end;

begin
  var sheet: TWorksheetE := Objects(False);
  var rowIndex: integer;
  FindRow(sheet, aRange.fTop, rowIndex);
  var rows: TRowCTList := sheet.SheetData.Row;
  while (rowIndex < rows.Count) and (rows[rowIndex].R <= cardinal(aRange.fBottom)) do
  begin
    var row: TRowCT := rows[rowIndex];
    var cellIndex: integer;
    FindInRow(row, aRange.fLeft, cellIndex);
    while (cellIndex < row.C.Count) and (ColumnOf(row.C[cellIndex].R) <= aRange.fRight) do
    begin
      var cell: TCellCT := row.C[cellIndex];
      var column: integer := ColumnOf(cell.R);
      var hasValue: boolean := cell.Present[@cell.V] or cell.IsPresent('F') or cell.IsPresent('Is');
      if hasValue and not CanWrite(row.R, column, aRange) then
      begin
        Inc(cellIndex);
        Continue;
      end;
      if hasValue then
      begin
        Objects(True);
        RemoveValue(cell);
        fWorkbook.ValueChanged;
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

function TWorksheet.MakeRange(aTop, aLeft, aBottom, aRight: integer): TRange;
begin
  Result.fSheet := Self;
  Result.fTop := aTop;
  Result.fLeft := aLeft;
  Result.fBottom := aBottom;
  Result.fRight := aRight;
end;

function TWorksheet.GetRange(const aAddress: string): TRange;
begin
  var top, left, bottom, right: integer;
  if not ParseAddress(aAddress, top, left, bottom, right) then
    raise EArgumentException.CreateFmt('Not an address on a sheet: "%s"', [aAddress]);
  Result := MakeRange(top, left, bottom, right);
end;

function TWorksheet.GetCells(aRow, aColumn: integer): TRange;
begin
  if (aRow < 1) or (aRow > cMaxRow) then
    raise EArgumentOutOfRangeException.CreateFmt('There is no row %d (1 to %d)', [aRow, cMaxRow]);
  if (aColumn < 1) or (aColumn > cMaxColumn) then
    raise EArgumentOutOfRangeException.CreateFmt('There is no column %d (1 to %d)', [aColumn, cMaxColumn]);
  Result := MakeRange(aRow, aColumn, aRow, aColumn);
end;

function TWorksheet.GetCellsByLetters(aRow: integer; const aColumn: string): TRange;
begin
  var index: integer := 1;
  var column: integer := ReadColumn(aColumn, index);
  if (column = 0) or (index <= aColumn.Length) then
    raise EArgumentException.CreateFmt('Not a column: "%s" (A to XFD)', [aColumn]);
  Result := GetCells(aRow, column);
end;

function TWorksheet.GetUsedRange: TRange;
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
      left := Min(left, ColumnOf(row.C.First.R));
      right := Max(right, ColumnOf(row.C.Last.R));
    end;
  if bottom = 0 then
    Result := MakeRange(1, 1, 1, 1)
  else
    Result := MakeRange(top, left, bottom, right);
end;

procedure TWorksheet.SetName(const aValue: string);
begin
  if aValue = fName then
    Exit;
  var why: string;
  if not fFresh then
    why := 'only a sheet made here is renamed: in a workbook opened, formulas and other parts may name it'
  else if fWorkbook.fFormulasWritten then
    why := 'sheets are renamed before formulas are written: a formula may name the sheet'
  else
    why := fWorkbook.SheetNameError(aValue, Self);
  if not why.IsEmpty then
  begin
    fWorkbook.fIssues.Add(isError, 'Rename', fName, why + ' - not renamed');
    Exit;
  end;
  for var entry: TSheetCT in TWorkbookE(fWorkbook.EditPart(fWorkbook.fWorkbookPart)).Sheets.Sheet do
    if entry.Name = fName then
      entry.Name := aValue;
  fName := aValue;
end;

{ TWorksheets }

constructor TWorksheets.Create;
begin
  inherited;
  fList := TObjectList<TWorksheet>.Create;
end;

destructor TWorksheets.Destroy;
begin
  fList.Free;
  inherited;
end;

function TWorksheets.GetEnumerator: TList<TWorksheet>.TEnumerator;
begin
  Result := fList.GetEnumerator;
end;

function TWorksheets.Find(const aName: string): TWorksheet;
begin
  for var sheet: TWorksheet in fList do
    if AnsiSameText(sheet.Name, aName) then
      Exit(sheet);
  Result := nil;
end;

function TWorksheets.Add(const aName: string): TWorksheet;
begin
  Result := fWorkbook.AddSheet(aName);
end;

function TWorksheets.GetCount: integer;
begin
  Result := fList.Count;
end;

function TWorksheets.GetItem(aIndex: integer): TWorksheet;
begin
  if (aIndex < 1) or (aIndex > fList.Count) then
    raise EArgumentOutOfRangeException.CreateFmt('There is no sheet %d (the workbook has %d)', [aIndex, fList.Count]);
  Result := fList[aIndex - 1];
end;

function TWorksheets.GetItemByName(const aName: string): TWorksheet;
begin
  Result := Find(aName);
  if Result = nil then
    raise EArgumentException.CreateFmt('There is no sheet "%s"', [aName]);
end;

{ TWorkbook.TPart }

destructor TWorkbook.TPart.Destroy;
begin
  fXml.Free;
  inherited;
end;

{ TWorkbook }

constructor TWorkbook.CreateClosed;
begin
  inherited Create;
  fParts := TObjectDictionary<string, TPart>.Create([doOwnsValues]);
  fSheets := TWorksheets.Create;
  fSheets.fWorkbook := Self;
  fDropped := TList<string>.Create;
end;

constructor TWorkbook.Create;
begin
  CreateClosed;
  NewPackage;
end;

destructor TWorkbook.Destroy;
begin
  Close;
  fDropped.Free;
  fSheets.Free;
  fParts.Free;
  inherited;
end;

class procedure TWorkbook.Swap<T>(var aLeft, aRight: T);
begin
  var value: T := aLeft;
  aLeft := aRight;
  aRight := value;
end;

// Excel's new workbook, read as a file would be: Transitional, no theme; styles with fonts, fills and borders (without them
// Excel refuses the file)
procedure TWorkbook.NewPackage;
const
  cDeclaration = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'#13#10;
  cPackage = 'http://schemas.openxmlformats.org/package/2006/';
  cOffice = 'http://schemas.openxmlformats.org/officeDocument/2006/';
  cMain = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  cTypes = 'application/vnd.openxmlformats-';
begin
  var created: string := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"Z"', TTimeZone.Local.ToUniversalTime(Now));
  var parts: TArray<string> := [
    cContentTypes, '<Types xmlns="' + cPackage + 'content-types">' +
      '<Default Extension="rels" ContentType="' + cTypes + 'package.relationships+xml"/>' +
      '<Default Extension="xml" ContentType="application/xml"/>' +
      '<Override PartName="/xl/workbook.xml" ContentType="' + cTypes + 'officedocument.spreadsheetml.sheet.main+xml"/>' +
      '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="' + cWorksheetType + '"/>' +
      '<Override PartName="/xl/styles.xml" ContentType="' + cTypes + 'officedocument.spreadsheetml.styles+xml"/>' +
      '<Override PartName="/docProps/core.xml" ContentType="' + cTypes + 'package.core-properties+xml"/>' +
      '<Override PartName="/docProps/app.xml" ContentType="' + cTypes + 'officedocument.extended-properties+xml"/></Types>',
    '_rels/.rels', '<Relationships xmlns="' + cPackage + 'relationships">' +
      '<Relationship Id="rId1" Type="' + cOffice + 'relationships/officeDocument" Target="xl/workbook.xml"/>' +
      '<Relationship Id="rId2" Type="' + cPackage + 'relationships/metadata/core-properties" Target="docProps/core.xml"/>' +
      '<Relationship Id="rId3" Type="' + cOffice + 'relationships/extended-properties" Target="docProps/app.xml"/>' +
      '</Relationships>',
    'docProps/app.xml', '<Properties xmlns="' + cOffice + 'extended-properties"><Application>ProRock Calcite</Application>' +
      '</Properties>',
    'docProps/core.xml', '<cp:coreProperties xmlns:cp="' + cPackage + 'metadata/core-properties" ' +
      'xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" ' +
      'xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
      '<dcterms:created xsi:type="dcterms:W3CDTF">' + created + '</dcterms:created>' +
      '<dcterms:modified xsi:type="dcterms:W3CDTF">' + created + '</dcterms:modified></cp:coreProperties>',
    'xl/workbook.xml', '<workbook xmlns="' + cMain + '" xmlns:r="' + cOffice + 'relationships">' +
      '<sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>',
    'xl/_rels/workbook.xml.rels', '<Relationships xmlns="' + cPackage + 'relationships">' +
      '<Relationship Id="rId1" Type="' + cOffice + 'relationships/worksheet" Target="worksheets/sheet1.xml"/>' +
      '<Relationship Id="rId2" Type="' + cOffice + 'relationships/styles" Target="styles.xml"/></Relationships>',
    'xl/styles.xml', '<styleSheet xmlns="' + cMain + '">' +
      '<fonts count="1"><font><sz val="11"/><name val="Calibri"/><family val="2"/></font></fonts>' +
      '<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>' +
      '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>' +
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>' +
      '<cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/></cellXfs>' +
      '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>',
    'xl/worksheets/sheet1.xml', '<worksheet xmlns="' + cMain + '"><sheetData/></worksheet>'];
  fSource := TBytesStream.Create;
  var zip: TZipFile := TZipFile.Create;
  try
    zip.Open(fSource, zmWrite);
    for var i := 0 to High(parts) div 2 do
      zip.Add(TEncoding.UTF8.GetBytes(cDeclaration + parts[2 * i + 1]), parts[2 * i]);
    zip.Close;
  finally
    zip.Free;
  end;
  fSource.Position := 0;
  fZip := TZipFile.Create;
  fZip.Open(fSource, zmRead);
  Load;
  fSheets.fList[0].fFresh := True;
end;

procedure TWorkbook.Close;
begin
  fSheets.fList.Clear;
  fParts.Clear;
  fDropped.Clear;
  FreeAndNil(fZip);
  FreeAndNil(fSource);
  FreeAndNil(fStrings);
  FreeAndNil(fStyleKeys);
  FreeAndNil(fDateStyles);
  fFileName := '';
  fRelationshipTypes := '';
  fWorkbookPart := '';
  fWorkbookRelationshipsPart := '';
  fContentTypesPart := '';
  fSharedStringsPart := '';
  fStylesPart := '';
  fCalcChainPart := '';
  fValuesChanged := False;
  fFormulasWritten := False;
end;

// an answer for the caller (False and Error); everything else still raises: a bug
function IsFileError(aError: Exception): boolean;
begin
  // 10.3 - 10.4: EFileNotFoundException and its kin are no EInOutError yet
  Result := aError.InheritsFrom(EStreamError) or aError.InheritsFrom(EInOutError) or aError.InheritsFrom(EZipException) or
    aError.InheritsFrom(EEncodingError) or aError.InheritsFrom(EOSError) or aError.InheritsFrom(EFileNotFoundException) or
    aError.InheritsFrom(EDirectoryNotFoundException) or aError.InheritsFrom(EPathTooLongException);
end;

function TWorkbook.Fail(const aCode, aError: string): boolean;
begin
  fError := aError;
  fIssues.Add(isError, aCode, '', aError);
  Result := False;
end;

// what the read reports, the part named; content not in the schema is kept anyway (left out)
function TWorkbook.ReadXml(aXml: TXmlite; const aPart: string; const aBytes: TBytes): boolean;
begin
  var read: TIssues;
  Result := aXml.FromXmlBytes(aBytes, read);
  for var issue: TIssue in read do
    if issue.Severity <> isHint then
    begin
      var named: TIssue := issue;
      if named.Where.IsEmpty then
        named.Where := aPart
      else
        named.Where := aPart + ', ' + named.Where;
      fIssues.Add(named);
    end;
end;

function TWorkbook.Open(const aFileName: string): boolean;
begin
  var stream: TFileStream := nil;
  try
    // others may write it meanwhile: a workbook open in Excel can still be read
    stream := TFileStream.Create(aFileName, fmOpenRead or fmShareDenyNone);
  except
    on e: Exception do
    begin
      if not IsFileError(e) then
        raise;
      fIssues.Clear;
      Exit(Fail('File', e.Message));
    end;
  end;
  try
    Result := Open(stream);
  finally
    stream.Free;
  end;
  if Result then
    fFileName := aFileName;
end;

function TWorkbook.Open(aStream: TStream): boolean;
begin
  // into a workbook of its own first: a failed Open leaves this one as it was, with this Open's issues
  fIssues.Clear;
  var opened: TWorkbook := TWorkbook.CreateClosed;
  try
    opened.fIssues.OnIssue := fIssues.OnIssue;
    try
      // a copy in memory: the parts are read from it on first use, and the file itself may be saved over
      opened.fSource := TBytesStream.Create;
      opened.fSource.CopyFrom(aStream, aStream.Size - aStream.Position);
      opened.fSource.Position := 0;
      opened.fZip := TZipFile.Create;
      try
        opened.fZip.Open(opened.fSource, zmRead);
      except
        on EZipException do
          Exit(Fail('NotXlsx', 'Not an .xlsx file (not a zip package)'));
      end;
      if not opened.Load then
      begin
        fIssues := opened.fIssues; // Load's failure among them
        fError := opened.fError;
        Exit(False);
      end;
    except
      on e: Exception do
      begin
        if not IsFileError(e) then
          raise;
        fIssues := opened.fIssues;
        Exit(Fail('File', e.Message));
      end;
    end;
    Exchange(opened);
    fError := '';
    Result := True;
  finally
    opened.Free; // with what was open here before
  end;
end;

// everything but Error: what is open here goes to aOther
procedure TWorkbook.Exchange(aOther: TWorkbook);
begin
  Swap<string>(fFileName, aOther.fFileName);
  Swap<TBytesStream>(fSource, aOther.fSource);
  Swap<TZipFile>(fZip, aOther.fZip);
  Swap<TObjectDictionary<string, TPart>>(fParts, aOther.fParts);
  Swap<string>(fRelationshipTypes, aOther.fRelationshipTypes);
  Swap<string>(fWorkbookPart, aOther.fWorkbookPart);
  Swap<string>(fWorkbookRelationshipsPart, aOther.fWorkbookRelationshipsPart);
  Swap<string>(fContentTypesPart, aOther.fContentTypesPart);
  Swap<string>(fSharedStringsPart, aOther.fSharedStringsPart);
  Swap<string>(fStylesPart, aOther.fStylesPart);
  Swap<string>(fCalcChainPart, aOther.fCalcChainPart);
  Swap<TList<string>>(fDropped, aOther.fDropped);
  Swap<TWorksheets>(fSheets, aOther.fSheets);
  Swap<TDictionary<string, integer>>(fStrings, aOther.fStrings);
  Swap<TDictionary<string, integer>>(fStyleKeys, aOther.fStyleKeys);
  Swap<TDictionary<cardinal, boolean>>(fDateStyles, aOther.fDateStyles);
  Swap<boolean>(fValuesChanged, aOther.fValuesChanged);
  Swap<boolean>(fFormulasWritten, aOther.fFormulasWritten);
  Swap<TIssues>(fIssues, aOther.fIssues);
  fSheets.fWorkbook := Self;
  aOther.fSheets.fWorkbook := aOther;
  for var sheet: TWorksheet in fSheets do
    sheet.fWorkbook := Self;
  for var sheet: TWorksheet in aOther.fSheets do
    sheet.fWorkbook := aOther;
end;

// a part's relationships as they are in the package, nil when it has none
function ReadRelationships(aBook: TWorkbook; const aPart: string): TRelationshipsE;
begin
  Result := nil;
  var index: integer := aBook.PartIndex(RelationshipsPart(aPart));
  if index < 0 then
    Exit;
  var bytes: TBytes;
  aBook.fZip.Read(index, bytes);
  Result := TRelationshipsE.Create;
  aBook.ReadXml(Result, RelationshipsPart(aPart), bytes);
end;

// a sheet's cells that belong to its tables' and pivot tables' definitions: header and totals rows, pivot tables with their
// page fields above them
procedure TWorkbook.FixedAreas(const aSheetPart: string; aTables, aTableRows, aPivots: TList<TRange>);
begin
  var relationships: TRelationshipsE := ReadRelationships(Self, aSheetPart);
  if relationships = nil then
    Exit;
  try
    for var relationship: TRelationshipE in relationships.Relationship do
    begin
      var index: integer := PartIndex(ResolveTarget(aSheetPart, relationship.Target));
      if index < 0 then
        Continue;
      var bytes: TBytes;
      var area: TRange;
      if string(relationship.&Type).EndsWith(cTable) then
      begin
        fZip.Read(index, bytes);
        var table: TTableE := TTableE.Create;
        try
          ReadXml(table, ResolveTarget(aSheetPart, relationship.Target), bytes);
          if ParseAddress(table.Ref, area.fTop, area.fLeft, area.fBottom, area.fRight) then
          begin
            var whole: TRange := area;
            aTables.Add(whole);
            if table.HeaderRowCount > 0 then
            begin
              area.fBottom := whole.fTop + integer(table.HeaderRowCount) - 1;
              aTableRows.Add(area);
            end;
            if table.TotalsRowCount > 0 then
            begin
              area.fTop := whole.fBottom - integer(table.TotalsRowCount) + 1;
              area.fBottom := whole.fBottom;
              aTableRows.Add(area);
            end;
          end;
        finally
          table.Free;
        end;
      end
      else if string(relationship.&Type).EndsWith(cPivotTable) then
      begin
        fZip.Read(index, bytes);
        var pivot: TPivotTableDefinitionE := TPivotTableDefinitionE.Create;
        try
          ReadXml(pivot, ResolveTarget(aSheetPart, relationship.Target), bytes);
          if ParseAddress(pivot.Location.Ref, area.fTop, area.fLeft, area.fBottom, area.fRight) then
          begin
            if pivot.Location.RowPageCount > 0 then // the page fields and a blank row
              area.fTop := Max(1, area.fTop - integer(pivot.Location.RowPageCount) - 1);
            aPivots.Add(area);
          end;
        finally
          pivot.Free;
        end;
      end;
    end;
  finally
    relationships.Free;
  end;
end;

function TWorkbook.Load: boolean;
begin
  // the main part is found, not assumed (xl/workbook.xml in Excel's files)
  var packageRelationships: TRelationshipsE := ReadRelationships(Self, '');
  if packageRelationships <> nil then
    try
      for var relationship: TRelationshipE in packageRelationships.Relationship do
        if string(relationship.&Type).EndsWith(cOfficeDocument) then
        begin
          fWorkbookPart := AddPart(ResolveTarget('', relationship.Target), TWorkbookE);
          fRelationshipTypes := string(relationship.&Type).Substring(0, Length(relationship.&Type) - Length(cOfficeDocument));
        end;
    finally
      packageRelationships.Free;
    end;
  if fWorkbookPart.IsEmpty then
    Exit(Fail('NotWorkbook', 'Not an Office document: the package names no main part'));
  var workbook: TWorkbookE := TWorkbookE(ReadPart(fWorkbookPart));
  fContentTypesPart := AddPart(cContentTypes, TTypesE);

  var workbookRelationships: TRelationshipsE := ReadRelationships(Self, fWorkbookPart);
  if workbookRelationships = nil then
    Exit(Fail('NotWorkbook', Format('%s is not a workbook: it has no relationships', [fWorkbookPart])));
  fWorkbookRelationshipsPart := AddPart(RelationshipsPart(fWorkbookPart), TRelationshipsE);
  try
    for var relationship: TRelationshipE in workbookRelationships.Relationship do
      if string(relationship.&Type).EndsWith(cSharedStrings) then
        fSharedStringsPart := AddPart(ResolveTarget(fWorkbookPart, relationship.Target), TSstE)
      else if string(relationship.&Type).EndsWith(cStyles) then
        fStylesPart := AddPart(ResolveTarget(fWorkbookPart, relationship.Target), TStyleSheetE)
      else if string(relationship.&Type).EndsWith(cCalcChain) then
      begin
        var index: integer := PartIndex(ResolveTarget(fWorkbookPart, relationship.Target));
        if index >= 0 then
          fCalcChainPart := fZip.FileNames[index];
      end;

    for var sheetEntry: TSheetCT in workbook.Sheets.Sheet do
      for var relationship: TRelationshipE in workbookRelationships.Relationship do
        if (relationship.Id = sheetEntry.Id) and string(relationship.&Type).EndsWith(cWorksheet) then
        begin
          var partName: string := AddPart(ResolveTarget(fWorkbookPart, relationship.Target), TWorksheetE);
          if partName.IsEmpty then
            Exit(Fail('NoSheetPart', Format('The sheet "%s" has no part (%s)', [sheetEntry.Name, relationship.Target])));
          var sheet: TWorksheet := TWorksheet.Create;
          fSheets.fList.Add(sheet);
          sheet.fWorkbook := Self;
          sheet.fName := sheetEntry.Name;
          sheet.fPartName := partName;
        end;
  finally
    workbookRelationships.Free;
  end;
  Result := True;
end;

// part names ignore case (OPC); Excel's own match exactly
function TWorkbook.PartIndex(const aName: string): integer;
begin
  Result := fZip.IndexOf(aName);
  if Result < 0 then
    for var i := 0 to fZip.FileCount - 1 do
      if SameText(fZip.FileNames[i], aName) then
        Exit(i);
end;

// the name as in the package ('' when missing)
function TWorkbook.AddPart(const aName: string; aClass: TXmliteClass): string;
begin
  var index: integer := PartIndex(aName);
  if index < 0 then
    Exit('');
  Result := fZip.FileNames[index];
  if not fParts.ContainsKey(Result) then
  begin
    var part: TPart := TPart.Create;
    part.fClass := aClass;
    fParts.Add(Result, part);
  end;
end;

// a part of the workbook's, with its relationship (aId) and content type; '' (aXml freed) when the package has no content types
function TWorkbook.NewPart(const aRelationship, aTarget, aContentType: string; aXml: TXmlite; out aId: string): string;
begin
  aId := '';
  if fContentTypesPart.IsEmpty then
  begin
    aXml.Free;
    Exit('');
  end;
  Result := ResolveTarget(fWorkbookPart, aTarget);
  var part: TPart := TPart.Create;
  part.fClass := TXmliteClass(aXml.ClassType);
  part.fXml := aXml;
  part.fExact := True;
  part.fChanged := True;
  part.fNew := True;
  fParts.Add(Result, part);

  var relationships: TRelationshipsE := TRelationshipsE(EditPart(fWorkbookRelationshipsPart));
  var number: integer := 1;
  for var existing: TRelationshipE in relationships.Relationship do
    if string(existing.Id).StartsWith('rId') then
      number := Max(number, StrToIntDef(string(existing.Id).Substring(3), 0) + 1);
  var relationship: TRelationshipE := relationships.Add<TRelationshipE>;
  relationship.Id := 'rId' + IntToStr(number);
  relationship.&Type := fRelationshipTypes + aRelationship;
  relationship.Target := aTarget;
  aId := relationship.Id;

  var contentType: TOverrideE := TTypesE(EditPart(fContentTypesPart)).Add<TOverrideE>;
  contentType.PartName := '/' + Result;
  contentType.ContentType := aContentType;
end;

// Excel's rules as it opens a file: a sheet named against them makes it refuse the whole file, even repaired. '' - a good name
function TWorkbook.SheetNameError(const aName: string; aExcept: TWorksheet): string;
begin
  if aName.IsEmpty then
    Exit('a sheet''s name cannot be empty');
  if Length(aName) > cMaxSheetName then
    Exit(Format('a sheet''s name has at most %d characters', [cMaxSheetName]));
  for var c: char in aName do
    if CharInSet(c, ['[', ']', ':', '*', '?', '/', '\']) or (c < ' ') then
      Exit('a sheet''s name cannot have [ ] : * ? / \ or control characters');
  if aName.StartsWith('''') or aName.EndsWith('''') then
    Exit('a sheet''s name cannot start or end with ''');
  if AnsiSameText(aName, 'History') then
    Exit('History is reserved by Excel');
  // chart sheets too
  for var entry: TSheetCT in TWorkbookE(ReadPart(fWorkbookPart)).Sheets.Sheet do
    if AnsiSameText(entry.Name, aName) and ((aExcept = nil) or (entry.Name <> aExcept.fName)) then
      Exit(Format('the workbook has a sheet "%s" already', [string(entry.Name)]));
  Result := '';
end;

function TWorkbook.AddSheet(const aName: string): TWorksheet;
begin
  var name: string := aName;
  var why: string := '';
  if not name.IsEmpty then
    why := SheetNameError(name, nil);
  var workbook: TWorkbookE := TWorkbookE(ReadPart(fWorkbookPart));
  if name.IsEmpty or not why.IsEmpty then
  begin
    var number: integer := workbook.Sheets.Sheet.Count;
    repeat
      Inc(number);
      name := 'Sheet' + IntToStr(number);
    until SheetNameError(name, nil).IsEmpty;
  end;
  if not why.IsEmpty then
    fIssues.Add(isError, 'SheetName', aName, why + ' - the sheet is added as ' + name);

  var number: integer := 0;
  var target, partName: string;
  repeat
    Inc(number);
    target := 'worksheets/sheet' + IntToStr(number) + '.xml';
    partName := ResolveTarget(fWorkbookPart, target);
  until (PartIndex(partName) < 0) and not fParts.ContainsKey(partName);
  var id: string;
  partName := NewPart(cWorksheet, target, cWorksheetType, TWorksheetE.Create, id);
  if partName.IsEmpty then
  begin
    fIssues.Add(isError, 'NoContentTypes', '', 'The package has no content types: a sheet cannot be added');
    Exit(nil);
  end;

  workbook := TWorkbookE(EditPart(fWorkbookPart));
  var sheetId: cardinal := 0;
  for var entry: TSheetCT in workbook.Sheets.Sheet do
    if entry.SheetId > sheetId then
      sheetId := entry.SheetId;
  var added: TSheetCT := workbook.Sheets.Add<TSheetCT>;
  added.Name := name;
  added.SheetId := sheetId + 1;
  added.Id := id;

  Result := TWorksheet.Create;
  fSheets.fList.Add(Result);
  Result.fWorkbook := Self;
  Result.fName := name;
  Result.fPartName := partName;
  Result.fFresh := True;
end;

function TWorkbook.ReadPart(const aName: string): TXmlite;
begin
  var part: TPart := fParts[aName];
  if part.fXml = nil then
  begin
    var bytes: TBytes;
    fZip.Read(PartIndex(aName), bytes);
    part.fXml := part.fClass.Create;
    // False: read as far as it goes, but it would not be written back as it was
    part.fExact := ReadXml(part.fXml, aName, bytes);
  end;
  Result := part.fXml;
end;

// a part that did not read back exactly too: Save refuses it
function TWorkbook.EditPart(const aName: string): TXmlite;
begin
  Result := ReadPart(aName);
  fParts[aName].fChanged := True;
end;

// Excel's default: a cell is locked unless its style unlocks it
function TWorkbook.IsLockedStyle(aStyle: cardinal): boolean;
begin
  Result := True;
  if fStylesPart.IsEmpty then
    Exit;
  var styles: TStyleSheetE := TStyleSheetE(ReadPart(fStylesPart));
  if styles.IsPresent('CellXfs') and (aStyle < cardinal(styles.CellXfs.Xf.Count)) then
  begin
    var style: TXfCT := styles.CellXfs.Xf[aStyle];
    if style.IsPresent('Protection') then
      Result := style.Protection.Locked;
  end;
end;

// formulas' cached results are stale: Excel recalculates when it opens the file
procedure TWorkbook.ValueChanged;
begin
  if fValuesChanged then
    Exit;
  fValuesChanged := True;
  TWorkbookE(EditPart(fWorkbookPart)).CalcPr.FullCalcOnLoad := True;
end;

// the calculation chain is Excel's cache: a stale entry is its repair prompt, a missing one is not calculated, so it goes with
// any change of a formula and Excel builds a new one
procedure TWorkbook.FormulaChanged;
begin
  fFormulasWritten := True;
  if fCalcChainPart.IsEmpty then
    Exit;
  var relationships: TRelationshipsE := TRelationshipsE(EditPart(fWorkbookRelationshipsPart));
  for var i := relationships.Relationship.Count - 1 downto 0 do
    if string(relationships.Relationship[i].&Type).EndsWith(cCalcChain) then
      relationships.Remove(relationships.Relationship[i]);
  if not fContentTypesPart.IsEmpty then
  begin
    var types: TTypesE := TTypesE(EditPart(fContentTypesPart));
    for var i := types.Override.Count - 1 downto 0 do
      if SameText(types.Override[i].PartName, '/' + fCalcChainPart) then
        types.Remove(types.Override[i]);
  end;
  fDropped.Add(fCalcChainPart);
  fCalcChainPart := '';
end;

function TWorkbook.Date1904: boolean;
begin
  var workbook: TWorkbookE := TWorkbookE(ReadPart(fWorkbookPart));
  Result := workbook.IsPresent('WorkbookPr') and workbook.WorkbookPr.Date1904;
end;

function TWorkbook.SharedString(aIndex: integer): string;
begin
  Result := '';
  if fSharedStringsPart.IsEmpty then
    Exit;
  var strings: TSstE := TSstE(ReadPart(fSharedStringsPart));
  if (aIndex >= 0) and (aIndex < strings.Si.Count) then
    Result := RichText(strings.Si[aIndex]);
end;

// found or added, one more use counted; -1 when there are no shared strings and they cannot be added
function TWorkbook.SharedStringIndex(const aText: string): integer;
begin
  if fSharedStringsPart.IsEmpty then
  begin
    var added: TSstE := TSstE.Create;
    var id: string;
    fSharedStringsPart := NewPart(cSharedStrings, 'sharedStrings.xml', cSharedStringsType, added, id);
    if fSharedStringsPart.IsEmpty then
      Exit(-1);
    added.Count := 0;
    added.UniqueCount := 0;
    added.SetPresent(@added.Count);
    added.SetPresent(@added.UniqueCount);
  end;
  var strings: TSstE := TSstE(EditPart(fSharedStringsPart));
  if fStrings = nil then
  begin
    fStrings := TDictionary<string, integer>.Create;
    for var i := 0 to strings.Si.Count - 1 do
      if strings.Si[i].R.Count = 0 then // plain text only: rich text stays its own
        fStrings.TryAdd(DecodeText(strings.Si[i].T), i);
  end;
  if not fStrings.TryGetValue(aText, Result) then
  begin
    var item: TRstCT := TRstCT.Create;
    item.T := EncodeText(aText);
    strings.Si.Add(item);
    Result := strings.Si.Count - 1;
    fStrings.Add(aText, Result);
    if strings.Present[@strings.UniqueCount] then
      strings.UniqueCount := strings.Si.Count;
  end;
  if strings.Present[@strings.Count] then
  begin
    strings.Count := strings.Count + 1;
    strings.SetPresent(@strings.Count);
  end;
end;

procedure TWorkbook.SharedStringReleased;
begin
  if fSharedStringsPart.IsEmpty then
    Exit;
  var strings: TSstE := TSstE(EditPart(fSharedStringsPart));
  if strings.Present[@strings.Count] and (strings.Count > 0) then
  begin
    strings.Count := strings.Count - 1;
    strings.SetPresent(@strings.Count);
  end;
end;

function TWorkbook.IsDateStyle(aStyle: cardinal): boolean;
begin
  if fStylesPart.IsEmpty then
    Exit(False);
  if fDateStyles = nil then
    fDateStyles := TDictionary<cardinal, boolean>.Create;
  if fDateStyles.TryGetValue(aStyle, Result) then
    Exit;
  var styles: TStyleSheetE := TStyleSheetE(ReadPart(fStylesPart));
  Result := styles.IsPresent('CellXfs') and (aStyle < cardinal(styles.CellXfs.Xf.Count)) and
    IsDateFormat(styles.CellXfs.Xf[aStyle].NumFmtId, styles);
  fDateStyles.Add(aStyle, Result);
end;

// aStyle with the number format aFormat, found in cellXfs by content or added; -1 when there are no styles
function TWorkbook.DateStyle(aStyle: cardinal; aFormat: integer): integer;
begin
  if fStylesPart.IsEmpty then
    Exit(-1);
  var styles: TStyleSheetE := TStyleSheetE(ReadPart(fStylesPart));
  if not styles.IsPresent('CellXfs') or (aStyle >= cardinal(styles.CellXfs.Xf.Count)) then
    Exit(-1);
  var formats: TXfCTList := styles.CellXfs.Xf;
  if fStyleKeys = nil then
  begin
    fStyleKeys := TDictionary<string, integer>.Create;
    for var i := 0 to formats.Count - 1 do
      fStyleKeys.TryAdd(TXmlite.ObjectToXml(formats[i]), i);
  end;
  // a copy through its XML: everything it has (alignment, protection, extensions) kept
  var wanted: TXfCT := TXfCT.Create;
  try
    TXmlite.XmlToObject(TXmlite.ObjectToXml(formats[aStyle]), wanted);
    wanted.NumFmtId := aFormat;
    wanted.ApplyNumberFormat := True;
    var key: string := TXmlite.ObjectToXml(wanted);
    if fStyleKeys.TryGetValue(key, Result) then
      Exit;
    styles := TStyleSheetE(EditPart(fStylesPart));
    formats.Add(wanted);
    Result := formats.Count - 1;
    wanted := nil;
    fStyleKeys.Add(key, Result);
    if styles.CellXfs.Present[@styles.CellXfs.Count] then
      styles.CellXfs.Count := formats.Count;
  finally
    wanted.Free;
  end;
end;

function TWorkbook.GetXml: TWorkbookE;
begin
  Result := nil;
  if not fWorkbookPart.IsEmpty then
    Result := TWorkbookE(EditPart(fWorkbookPart));
end;

function TWorkbook.GetXmlSharedStrings: TSstE;
begin
  Result := nil;
  if not fSharedStringsPart.IsEmpty then
  begin
    Result := TSstE(EditPart(fSharedStringsPart));
    FreeAndNil(fStrings); // the user's changes: found again on the next write
  end;
end;

function TWorkbook.GetXmlStyles: TStyleSheetE;
begin
  Result := nil;
  if not fStylesPart.IsEmpty then
  begin
    Result := TStyleSheetE(EditPart(fStylesPart));
    FreeAndNil(fStyleKeys);
    FreeAndNil(fDateStyles);
  end;
end;

function TWorkbook.Save: boolean;
begin
  if fZip = nil then
    Exit(Fail('NotOpen', 'No workbook is open'));
  if fFileName.IsEmpty then
    Exit(Fail('NoFileName', 'The workbook has no file to save to (a new one, or opened from a stream): use SaveAs'));
  Result := SaveAs(fFileName);
end;

function TWorkbook.SaveAs(const aFileName: string): boolean;
begin
  if not CanWrite then // a refusal touches no file
    Exit(False);
  // the old file stays intact until the new one is complete
  var temporary: string := aFileName + '.saving';
  try
    try
      var stream: TFileStream := TFileStream.Create(temporary, fmCreate);
      try
        Result := Write(stream);
      finally
        stream.Free;
      end;
      if Result then
      begin
        if FileExists(aFileName) then
          TFile.Delete(aFileName);
        TFile.Move(temporary, aFileName);
      end;
    except
      on e: Exception do
      begin
        if not IsFileError(e) then
          raise;
        Result := Fail('File', e.Message);
      end;
    end;
  finally
    if FileExists(temporary) then
      DeleteFile(temporary);
  end;
  if Result then
  begin
    fFileName := aFileName;
    fError := '';
  end;
end;

function TWorkbook.SaveAs(aStream: TStream): boolean;
begin
  try
    Result := Write(aStream);
  except
    on e: Exception do
    begin
      if not IsFileError(e) then
        raise;
      Result := Fail('File', e.Message);
    end;
  end;
  if Result then
    fError := '';
end;

function TWorkbook.CanWrite: boolean;
begin
  if fZip = nil then
    Exit(Fail('NotOpen', 'No workbook is open'));
  // refused rather than written broken
  for var pair: TPair<string, TPart> in fParts do
    if pair.Value.fChanged and not pair.Value.fExact then
      Exit(Fail('NotExact', Format('%s cannot be saved changed: it did not read back exactly, writing it could lose something',
        [pair.Key])));
  Result := True;
end;

function TWorkbook.Write(aStream: TStream): boolean;

  procedure AddXml(aTarget: TZipFile; aPart: TPart; const aName: string; aCompression: TZipCompression);
  begin
    var xml: TBytesStream := TBytesStream.Create;
    try
      // as Excel writes: compact whatever TBasite.Pretty says, booleans as 1 and 0
      aPart.fXml.ToXml(xml, [woBooleanDigits]);
      xml.Position := 0;
      aTarget.Add(xml, aName, aCompression);
    finally
      xml.Free;
    end;
  end;

begin
  if not CanWrite then
    Exit(False);
  var target: TZipFile := TZipFile.Create;
  try
    target.Open(aStream, zmWrite);
    // the same order and compression as the original
    for var i := 0 to fZip.FileCount - 1 do
    begin
      var name: string := fZip.FileNames[i];
      if fDropped.Contains(name) then
        Continue;
      var compression: TZipCompression := TZipCompression(fZip.FileInfo[i].CompressionMethod);
      var part: TPart;
      if fParts.TryGetValue(name, part) and part.fChanged then
        AddXml(target, part, name, compression)
      else
      begin
        var bytes: TBytes;
        fZip.Read(i, bytes);
        target.Add(bytes, name, compression);
      end;
    end;
    for var pair: TPair<string, TPart> in fParts do
      if pair.Value.fNew then
        AddXml(target, pair.Value, pair.Key, zcDeflate);
    target.Close;
  finally
    target.Free;
  end;
  Result := True;
end;

end.
