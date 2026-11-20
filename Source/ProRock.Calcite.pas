unit ProRock.Calcite;

// Excel workbooks (.xlsx): open, change and save with nothing lost

interface

uses System.SysUtils, System.Classes, System.Generics.Collections,
  ProRock.Xmlite, ProRock.Office.Ooxml, ProRock.Xmlite.Schema.Ooxml.Sml, ProRock.Xmlite.Schema.CoreProperties;

const
  {$REGION 'ProRock.Xmlite constants aliases'}
  isHint = ProRock.Xmlite.isHint;
  isWarning = ProRock.Xmlite.isWarning;
  isError = ProRock.Xmlite.isError;
  {$ENDREGION}

type
  {$REGION 'ProRock.Xmlite types aliases'}
  TIssueSeverity = ProRock.Xmlite.TIssueSeverity;
  TIssue = ProRock.Xmlite.TIssue;
  TIssueEvent = ProRock.Xmlite.TIssueEvent;
  TIssues = ProRock.Xmlite.TIssues;
  {$ENDREGION}

  TWorkbook = class;
  TWorksheet = class;

  // a date is a number in a date format, as in Excel
  TCellValueType = (cvEmpty, cvNumber, cvDate, cvText, cvBoolean, cvError);

  // Excel's Range.Font: read from the first cell, written to every cell
  TRangeFont = record
  private
    fSheet: TWorksheet;
    fTop, fLeft, fBottom, fRight: integer;

    function GetBold: boolean;
    procedure SetBold(aValue: boolean);
  public
    property Bold: boolean read GetBold write SetBold;
  end;

  // Excel's Range.Columns: the range's columns
  TRangeColumns = record
  private
    fSheet: TWorksheet;
    fTop, fLeft, fBottom, fRight: integer;
  public
    // Excel's AutoFit, estimated: each column as wide as its longest shown value in the range's rows, numbers and dates a digit
    // wider (too narrow, Excel shows ####). Calcite measures no fonts: Latin letters, digits and signs exact in Calibri and
    // Aptos Narrow, other fonts as Calibri, other scripts close. A column with nothing in those rows keeps its width
    procedure AutoFit;
  end;

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
    function GetNumberFormat: string;
    procedure SetNumberFormat(const aValue: string);
    function GetFont: TRangeFont;
    function GetColumns: TRangeColumns;
    function GetColumnWidth: Double;
    procedure SetColumnWidth(aValue: Double);
  public
    // the values gone, as Excel's ClearContents: a cell with a format stays
    procedure ClearContents;

    property Sheet: TWorksheet read fSheet;
    property Row: integer read fTop;
    property Column: integer read fLeft;
    property RowCount: integer read GetRowCount;
    property ColumnCount: integer read GetColumnCount;
    // the bottom row and the right column: B2:D5 has LastRow 5, LastColumn 4
    property LastRow: integer read fBottom;
    property LastColumn: integer read fRight;
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

    // Excel's NumberFormat, the first cell's: 'General', '0.00', '#,##0.00', 'dd.mm.yyyy', '@' (text). Written to every cell,
    // a whole column or row as Excel does; '' is General. m/d/yyyy and m/d/yyyy h:mm are Excel's built-in dates, shown in each
    // reader's own order (Excel names them by the regional settings); dd.mm.yyyy is shown as written everywhere. A format
    // Excel would not open ([Foo]0, an open quote, digits and dates in one section) is refused
    property NumberFormat: string read GetNumberFormat write SetNumberFormat;
    property Font: TRangeFont read GetFont;
    property Columns: TRangeColumns read GetColumns;
    // Excel's ColumnWidth in characters of the default font's digits (8.43 by default), the first column's; written to every
    // column of the range, 0 hides them; EArgumentOutOfRangeException beyond 0..255
    property ColumnWidth: Double read GetColumnWidth write SetColumnWidth;
  end;

  // the sheet's xlsx objects: Sheet.Xlsx
  TWorksheetXlsx = class
  private
    fSheet: TWorksheet;
    function GetWorksheet: TWorksheetE;
  public
    // the generated objects; once taken, the sheet is saved from them
    property Worksheet: TWorksheetE read GetWorksheet;
  end;

  TWorksheet = class
  private
    fWorkbook: TWorkbook;
    fXlsx: TWorksheetXlsx;
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

    function GetXlsx: TWorksheetXlsx;
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
    function CellForStyle(aRow, aColumn: integer): TCellCT;
    procedure Restyle(const aRange: TRange; const aChange: TProc<TXfCT>);
    function DefaultWidth: Double;
    function ColumnEntries(aLeft, aRight: integer): TArray<TColCT>;
    function ColumnEntry(aColumn: integer): TColCT;
    procedure AutoFit(const aRange: TRange);
    function GetFreezePanes: string;
    procedure SetFreezePanes(const aValue: string);
  public
    destructor Destroy; override;

    // the xlsx file's own objects, for what Calcite does not cover
    property Xlsx: TWorksheetXlsx read GetXlsx;

    property Workbook: TWorkbook read fWorkbook;
    // renamed only while nothing can name it: a sheet made here (a new workbook's or added), before formulas are written
    property Name: string read fName write SetName;
    // 'B5', 'A1:C10', '5:5', 'B:D' ($ allowed); EArgumentException for anything else
    property Range[const aAddress: string]: TRange read GetRange;
    // Excel's order, from 1: Cells[5, 2] or Cells[5, 'B'] is B5; Sheet[5, 'B'] too
    property Cells[aRow, aColumn: integer]: TRange read GetCells; default;
    property Cells[aRow: integer; const aColumn: string]: TRange read GetCellsByLetters; default;
    // Sheet['B5'] or Sheet['A1:C10'], as Range
    property Cells[const aAddress: string]: TRange read GetRange; default;
    // from the first cell to the last one the sheet has (a formatted one too, as in Excel); A1 when there are none
    property UsedRange: TRange read GetUsedRange;
    // Excel's Freeze Panes at a cell: the rows above it and the columns left of it stay put ('A2' - the first row, 'B1' - the
    // first column); '' or 'A1' unfreezes. A sheet with several views, or an opened sheet's panes, is not changed (an issue)
    property FreezePanes: string read GetFreezePanes write SetFreezePanes;
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

  // the workbook's xlsx objects: Workbook.Xlsx. Each nil when the file has no such part; once taken, the part is saved from
  // them
  TWorkbookXlsx = class
  private
    fWorkbook: TWorkbook;
    function GetWorkbook: TWorkbookE;
    function GetSharedStrings: TSstE;
    function GetStyles: TStyleSheetE;
    function GetCoreProperties: TCorePropertiesE;
  public
    property Workbook: TWorkbookE read GetWorkbook;
    property SharedStrings: TSstE read GetSharedStrings;
    property Styles: TStyleSheetE read GetStyles;
    // docProps/core.xml's, made when the file has none
    property CoreProperties: TCorePropertiesE read GetCoreProperties;
  end;

  // Excel's File > Info as plain values: '' and 0 - none, and setting them so removes the property; dates in UTC
  TWorkbookProperties = class
  private
    fWorkbook: TWorkbook;
    function GetText(aIndex: integer): string;
    procedure SetText(aIndex: integer; const aValue: string);
    function GetDate(aIndex: integer): TDateTime;
    procedure SetDate(aIndex: integer; aValue: TDateTime);
  public
    property Title: string index 0 read GetText write SetText;
    property Subject: string index 1 read GetText write SetText;
    property Creator: string index 2 read GetText write SetText;
    property Keywords: string index 3 read GetText write SetText;
    property Description: string index 4 read GetText write SetText;
    property Category: string index 5 read GetText write SetText;
    property ContentStatus: string index 6 read GetText write SetText;
    property LastModifiedBy: string index 7 read GetText write SetText;
    property Revision: string index 8 read GetText write SetText;
    property Created: TDateTime index 0 read GetDate write SetDate;
    // Save sets it when anything changed, as Excel does
    property Modified: TDateTime index 1 read GetDate write SetDate;
  end;

  TWorkbook = class
  private
    fError: string;
    fXlsx: TWorkbookXlsx;
    fProperties: TWorkbookProperties;
    fPackage: TPackageOoxml;
    fWorkbookPart, fSharedStringsPart, fStylesPart, fCalcChainPart: string;
    fSheets: TWorksheets;
    fStrings: TDictionary<string, integer>; // shared strings by text, built on the first write
    fStyleKeys: TDictionary<string, integer>; // cellXfs by content, built on the first need
    fFontKeys: TDictionary<string, integer>; // fonts by content, the same
    fDateStyleIds: TDictionary<UInt64, integer>; // DateStyle's answers: a style and a format, the style with it
    fDateStyles: TDictionary<cardinal, boolean>;
    fValuesChanged: boolean;
    fFormulasWritten: boolean;
    fIssues: TIssues;

    // nothing open: Open's own workbook
    constructor CreateClosed;
    class procedure Swap<T>(var aLeft, aRight: T); static; inline;
    procedure NewPackage;
    procedure ForwardIssues;
    function Opened(const aFileName: string; aStream: TStream): boolean;
    function Load: boolean;
    function Fail(const aCode, aError: string): boolean;
    procedure Exchange(aOther: TWorkbook);
    procedure FixedAreas(const aSheetPart: string; aTables, aTableRows, aPivots: TList<TRange>);
    function SheetNameError(const aName: string; aExcept: TWorksheet): string;
    function AddSheet(const aName: string): TWorksheet;

    function IsLockedStyle(aStyle: cardinal): boolean;
    procedure ValueChanged;
    procedure FormulaChanged;
    function Date1904: boolean;
    function SharedString(aIndex: integer): string;
    function SharedStringIndex(const aText: string): integer;
    procedure SharedStringReleased;
    function IsDateStyle(aStyle: cardinal): boolean;
    function ChangedStyle(aStyle: cardinal; const aChange: TProc<TXfCT>): integer;
    function DateStyle(aStyle: cardinal; aFormat: integer): integer;
    function FormatCode(aStyle: cardinal): string;
    function FormatId(const aCode: string): integer;
    function FontWith(aFont: cardinal; aBold: boolean): integer;
    function StyleFont(aStyle: cardinal): TFontCT;

    function GetXml: TWorkbookE;
    function GetXmlSharedStrings: TSstE;
    function GetXmlStyles: TStyleSheetE;
    function GetFileName: string;
    function ExtensionError(const aFileName: string): string;
  public
    // a new workbook, as Excel's: Sheet1 and nothing in it; Open replaces it
    constructor Create;
    destructor Destroy; override;

    // the xlsx file's own objects, for what Calcite does not cover
    property Xlsx: TWorkbookXlsx read fXlsx;

    // the format from the content, not the name's extension. False: Error says why, and the workbook open before stays
    // open
    function Open(const aFileName: string): boolean; overload;
    function Open(aStream: TStream): boolean; overload;
    // Save: to the file opened (a new workbook has none: SaveAs). SaveAs: the extension as Excel needs it - .xlsx, .xlsm with
    // macros, .xltx and .xltm for templates (another name is written as it is). False: Error says why, and the file stays
    // as it was
    function Save: boolean;
    function SaveAs(const aFileName: string): boolean; overload;
    function SaveAs(aStream: TStream): boolean; overload;

    property FileName: string read GetFileName;
    // why the last Open or Save returned False
    property Error: string read fError;
    // since the last Open: writes refused (the cell keeps its value), what Open and Save could not do, values and parts read
    // not quite right. Save refuses only to keep the file valid with nothing lost: Issues.HasErrors tells the rest
    property Issues: TIssues read fIssues;
    // each issue as it comes
    property OnIssue: TIssueEvent read fIssues.OnIssue write fIssues.OnIssue;
    property Sheets: TWorksheets read fSheets;
    // Excel's File > Info: title, author, dates (Save sets Modified when anything changed); the open file's, after an Open too
    property Properties: TWorkbookProperties read fProperties;
  end;

implementation

uses System.Math, System.Variants, System.DateUtils, System.TypInfo, System.Character, System.Generics.Defaults,
  System.Zip, ProRock.Utility, ProRock.Calcite.Utility;

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

  // Excel's number formats a date gets: m/d/yyyy, m/d/yyyy h:mm, h:mm:ss (shown in the user's locale)
  cDateFormat = 14;
  cDateTimeFormat = 22;
  cTimeFormat = 21;

{$REGION 'Excel language: formulas'}

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
  {$REGION 'Excel functions'}
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
  {$ENDREGION}

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

{$ENDREGION}

{$REGION 'Excel language: number formats'}

// a number format's sections, split at ; outside quotes, brackets and escapes; why Excel would not open it, '' - it would
function FormatSections(const aCode: string; out aSections: TArray<string>): string;
begin
  aSections := [];
  var start: integer := 1;
  var i: integer := 1;
  while i <= aCode.Length do
  begin
    case aCode[i] of
      '"':
        begin
          i := Pos('"', aCode, i + 1);
          if i = 0 then
            Exit('a quote not closed');
        end;
      '[':
        begin
          i := Pos(']', aCode, i + 1);
          if i = 0 then
            Exit('a [ not closed');
        end;
      '\', '_', '*':
        begin
          if i = aCode.Length then
            Exit(aCode[i] + ' at the end, with nothing after it');
          Inc(i);
        end;
      ';':
        begin
          aSections := aSections + [Copy(aCode, start, i - start)];
          start := i + 1;
        end;
    end;
    Inc(i);
  end;
  aSections := aSections + [Copy(aCode, start, MaxInt)];
  Result := '';
end;

type
  // what a section of a number format has, outside quotes and escapes
  TFormatSection = record
    Digits, Dates, Text, General: boolean;
    Error: string;
  end;

// a section of a number format that FormatSections took: digit placeholders, date and time codes, @, General
function ScanSection(const aSection: string): TFormatSection;
const
  cColors: array[0 .. 7] of string = ('black', 'blue', 'cyan', 'green', 'magenta', 'red', 'white', 'yellow');
begin
  Result := Default(TFormatSection);
  var colors: integer := 0;
  var conditions: integer := 0;
  var seconds: boolean := False; // the last date code: decimals of seconds may follow
  var n: integer := aSection.Length;
  var i: integer := 1;
  while i <= n do
  begin
    var c: char := aSection[i];
    case c of
      '"':
        i := Pos('"', aSection, i + 1);
      '\', '_', '*':
        Inc(i);
      '[':
        begin
          var close: integer := Pos(']', aSection, i + 1);
          var inside: string := LowerCase(Copy(aSection, i + 1, close - i - 1));
          var number: Double;
          var color: integer;
          var named: boolean := False;
          for var name: string in cColors do
            named := named or (inside = name);
          if named or (inside.StartsWith('color') and TryStrToInt(inside.Substring(5), color) and (color >= 1) and
            (color <= 56)) then
          begin
            Inc(colors);
            if colors > 1 then
              Result.Error := 'two colors in one section';
          end
          else if (inside <> '') and CharInSet(inside[1], ['<', '>', '=']) then
          begin
            var operatorLength: integer := 1;
            if (inside.Length > 1) and CharInSet(inside[2], ['>', '=']) and (inside[1] <> '=') then
              operatorLength := 2;
            Inc(conditions);
            if not TryStrToFloat(inside.Substring(operatorLength).Trim, number, TFormatSettings.Invariant) then
              Result.Error := 'a condition without a number: [' + inside + ']'
            else if conditions > 1 then
              Result.Error := 'two conditions in one section';
          end
          else if inside.StartsWith('$') then
            // a currency or a locale
          else if (inside <> '') and CharInSet(inside[1], ['h', 'm', 's']) and (inside.Trim([inside[1]]) = '') then
          begin // elapsed time
            Result.Dates := True;
            seconds := inside[1] = 's';
          end
          else if inside.StartsWith('dbnum') and TryStrToInt(inside.Substring(5), color) then
            // East Asian numerals
          else
            Result.Error := 'Excel has no [' + inside + ']';
          i := close;
        end;
      '0', '#', '?':
        begin
          Result.Digits := True;
          seconds := False;
        end;
      '.':
        if seconds then
        begin
          var zeros: integer := 0;
          while (i < n) and (aSection[i + 1] = '0') do
          begin
            Inc(zeros);
            Inc(i);
          end;
          if zeros > 3 then
            Result.Error := 'more than three decimals of seconds';
        end;
      'E':
        begin
          if (i = n) or not CharInSet(aSection[i + 1], ['+', '-']) then
            Result.Error := 'E without + or - after it'
          else if (i + 1 = n) or not CharInSet(aSection[i + 2], ['0', '#', '?']) then
            Result.Error := 'E+ without a digit placeholder after it';
          Result.Digits := True;
          Inc(i);
        end;
      '@':
        Result.Text := True;
      'G', 'g':
        if SameText(Copy(aSection, i, 7), 'General') then
        begin
          Result.General := True;
          Inc(i, 6);
        end
        else
          Result.Dates := True; // an era
      'A', 'a':
        if SameText(Copy(aSection, i, 5), 'AM/PM') then
        begin
          Result.Dates := True;
          Inc(i, 4);
        end
        else if SameText(Copy(aSection, i, 3), 'A/P') then
        begin
          Result.Dates := True;
          Inc(i, 2);
        end;
      'B':
        if (i < n) and CharInSet(aSection[i + 1], ['1', '2']) then
          Inc(i) // a calendar
        else
          Result.Error := 'B without 1 or 2 after it';
      'n', 'N':
        Result.Error := 'n (minutes are m)';
      'b', 'd', 'D', 'e', 'h', 'H', 'm', 'M', 'y', 'Y':
        begin
          Result.Dates := True;
          seconds := False;
        end;
      's', 'S':
        begin
          Result.Dates := True;
          seconds := True;
        end;
    end;
    if Result.Error <> '' then
      Exit;
    Inc(i);
  end;
end;

// why Excel would not open a file with this number format, '' - it would (each rule found by opening files in Excel)
function NumberFormatError(const aCode: string): string;
begin
  var sections: TArray<string>;
  Result := FormatSections(aCode, sections);
  if Result <> '' then
    Exit;
  if Length(sections) > 4 then
    Exit('more than four sections');
  for var i := 0 to High(sections) do
  begin
    var section: TFormatSection := ScanSection(sections[i]);
    if section.Error <> '' then
      Exit(section.Error);
    if section.General and section.Digits then
      Exit('General and digit placeholders in one section');
    if section.Text and (section.Digits or section.Dates) then
      Exit('@ and digits or dates in one section');
    if section.Digits and section.Dates then
      Exit('digits and dates in one section');
    if (i = 3) and (section.Digits or section.Dates) then
      Exit('digits or dates in the fourth section, which is for text');
    if section.Text and (i < High(sections)) then
      Exit('@ in a section before the last one');
  end;
end;

// a code as Excel's NumberFormat shows it: no \ before what is shown as itself anyway ($ - + / ( ) : ! ^ & ' ~ { } < > = and
// a space, a . in a date's section) - Excel writes dd\.mm\.yyyy for dd.mm.yyyy
function ShownFormat(const aCode: string): string;
begin
  var sections: TArray<string>;
  if FormatSections(aCode, sections) <> '' then
    Exit(aCode);
  var builder: TStringBuilder := TStringBuilder.Create;
  try
    for var index := 0 to High(sections) do
    begin
      if index > 0 then
        builder.Append(';');
      var section: string := sections[index];
      var dates: boolean := ScanSection(section).Dates;
      var i: integer := 1;
      while i <= section.Length do
      begin
        var c: char := section[i];
        if c = '"' then
        begin
          var close: integer := Pos('"', section, i + 1);
          builder.Append(Copy(section, i, close - i + 1));
          i := close;
        end
        else if c = '[' then
        begin
          var close: integer := Pos(']', section, i + 1);
          builder.Append(Copy(section, i, close - i + 1));
          i := close;
        end
        else if CharInSet(c, ['\', '_', '*']) and (i < section.Length) then
        begin
          Inc(i);
          if (c <> '\') or not (CharInSet(section[i], ['$', '-', '+', '/', '(', ')', ':', '!', '^', '&', '''', '~', '{', '}',
            '<', '>', '=', ' ']) or (dates and (section[i] = '.'))) then
            builder.Append(c);
          builder.Append(section[i]);
        end
        else
          builder.Append(c);
        Inc(i);
      end;
    end;
    Result := builder.ToString;
  finally
    builder.Free;
  end;
end;

// a number as Excel's General shows it in a cell: up to 11 characters
function GeneralText(aNumber: Double): string;
begin
  Result := FloatText(aNumber, ftDouble);
  if Result.Length <= 11 then
    Exit;
  var size: Double := Abs(aNumber);
  if (size >= 1E11) or (size < 1E-4) then
    Exit(FormatFloat('0.#####E+00', aNumber, TFormatSettings.Invariant));
  var decimals: integer := 11 - Length(IntToStr(Trunc(size))) - 1 - Ord(aNumber < 0);
  Result := FormatFloat('0.' + StringOfChar('#', Max(decimals, 0)), aNumber, TFormatSettings.Invariant);
end;

// a number as a number format would show it, close enough for its width: Delphi's FormatFloat and FormatDateTime take
// most of Excel's codes
function ShownNumber(aNumber: Double; const aCode: string): string;
begin
  var sections: TArray<string>;
  if FormatSections(aCode, sections) <> '' then
    Exit(GeneralText(aNumber));
  var section: string := sections[0];
  if (aNumber < 0) and (Length(sections) >= 2) then
  begin
    section := sections[1];
    aNumber := -aNumber;
  end
  else if (aNumber = 0) and (Length(sections) >= 3) then
    section := sections[2];
  var info: TFormatSection := ScanSection(section);
  if info.Text then
    Exit(GeneralText(aNumber));
  // Excel's code -> Delphi's: literals quoted, padding and fills as a space or nothing, brackets as what they show
  var code: string := '';
  var scale: Double := 1;
  var i: integer := 1;
  while i <= section.Length do
  begin
    var c: char := section[i];
    case c of
      '"':
        begin
          var close: integer := Pos('"', section, i + 1);
          code := code + Copy(section, i, close - i + 1);
          i := close;
        end;
      '\':
        begin
          Inc(i);
          code := code + '"' + section[i] + '"';
        end;
      '_':
        begin
          Inc(i);
          code := code + ' ';
        end;
      '*':
        Inc(i);
      '[':
        begin
          var close: integer := Pos(']', section, i + 1);
          var inside: string := Copy(section, i + 1, close - i - 1);
          var unitPerDay: Double := 0;
          case LowerCase(inside + ' ')[1] of
            '$':
              code := code + '"' + Copy(inside, 2, Pos('-', inside + '-') - 2) + '"';
            'h':
              unitPerDay := 24;
            'm':
              unitPerDay := 1440;
            's':
              unitPerDay := 86400;
          end;
          if unitPerDay > 0 then
            code := code + '"' + IntToStr(Trunc(aNumber * unitPerDay)) + '"';
          i := close;
        end;
      '%':
        begin
          scale := scale * 100;
          code := code + '"%"';
        end;
      '?':
        code := code + '0';
      'G', 'g':
        if SameText(Copy(section, i, 7), 'General') then
        begin
          code := code + '"' + GeneralText(aNumber) + '"';
          Inc(i, 6);
        end
        else
          code := code + c;
      'e', 'b', 'B':
        if info.Dates then
          code := code + 'yyyy'
        else
          code := code + c;
      's', 'S':
        begin
          code := code + c;
          if (i < section.Length) and (section[i + 1] = '.') then
          begin // decimals of seconds: Delphi's z
            code := code + '.';
            Inc(i);
            while (i < section.Length) and (section[i + 1] = '0') do
            begin
              code := code + 'z';
              Inc(i);
            end;
          end;
        end;
      'm', 'M':
        begin // minutes before seconds (Delphi's n); after hours Delphi takes m as minutes itself
          var j: integer := i;
          while (j < section.Length) and CharInSet(section[j + 1], ['m', 'M']) do
            Inc(j);
          var k: integer := j + 1;
          while (k <= section.Length) and not CharInSet(section[k], ['a' .. 'z', 'A' .. 'Z', '0']) do
            Inc(k);
          var letter: char := 'm';
          if (k <= section.Length) and CharInSet(section[k], ['s', 'S']) then
            letter := 'n';
          code := code + StringOfChar(letter, j - i + 1);
          i := j;
        end;
    else
      code := code + c;
    end;
    Inc(i);
  end;
  try
    if info.Dates then
      Result := FormatDateTime(code, SerialToDate(aNumber, False), TFormatSettings.Invariant)
    else if info.Digits then
      Result := FormatFloat(code, aNumber * scale, TFormatSettings.Invariant)
    else if code = '' then
      Result := GeneralText(aNumber)
    else
      Result := StringReplace(code, '"', '', [rfReplaceAll]);
  except
    Result := GeneralText(aNumber);
  end;
end;

{$ENDREGION}

{$REGION 'xlsx storage: text, built-in formats, date styles, widths, data tables'}

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

const
  // Excel's built-in number formats as its NumberFormat names them in English; 14-17 and 22 follow the regional settings
  // in Excel (these are en-US's), 5-8 the currency's; '' - none
  cBuiltInFormats: array[0 .. 49] of string = ('General', '0', '0.00', '#,##0', '#,##0.00', '$#,##0_);($#,##0)',
    '$#,##0_);[Red]($#,##0)', '$#,##0.00_);($#,##0.00)', '$#,##0.00_);[Red]($#,##0.00)', '0%', '0.00%', '0.00E+00', '# ?/?',
    '# ??/??', 'm/d/yyyy', 'd-mmm-yy', 'd-mmm', 'mmm-yy', 'h:mm AM/PM', 'h:mm:ss AM/PM', 'h:mm', 'h:mm:ss', 'm/d/yyyy h:mm',
    '', '', '', '', '', '', '', '', '', '', '', '', '', '', '#,##0_);(#,##0)', '#,##0_);[Red](#,##0)',
    '#,##0.00_);(#,##0.00)', '#,##0.00_);[Red](#,##0.00)', '_(* #,##0_);_(* (#,##0);_(* "-"_);_(@_)',
    '_($* #,##0_);_($* (#,##0);_($* "-"_);_(@_)', '_(* #,##0.00_);_(* (#,##0.00);_(* "-"??_);_(@_)',
    '_($* #,##0.00_);_($* (#,##0.00);_($* "-"??_);_(@_)', 'mm:ss', '[h]:mm:ss', 'mm:ss.0', '##0.0E+0', '@');

function BuiltInFormat(aId: cardinal): string;
begin
  if (aId <= High(cBuiltInFormats)) and (cBuiltInFormats[aId] <> '') then
    Result := cBuiltInFormats[aId]
  else if (aId <= 58) and (Byte(aId) in [32 .. 35]) then // the East Asian times and dates: the locale's
    Result := 'h:mm:ss'
  else if (aId <= 58) and (Byte(aId) in [27 .. 31, 36, 50 .. 58]) then
    Result := 'm/d/yyyy'
  else
    Result := 'General';
end;

// a code written: the built-in id it names, -1 for none (5-8 are the locale's currency, never chosen)
function BuiltInFormatId(const aShown: string): integer;
begin
  if (aShown = '') or SameText(aShown, 'General') then
    Exit(0);
  for var id := 1 to High(cBuiltInFormats) do
    if not (id in [5 .. 8]) and (cBuiltInFormats[id] = aShown) then
      Exit(id);
  Result := -1;
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

const
  // the default font's digit (Calibri or Aptos Narrow 11) in pixels: the unit of Excel's column widths
  cDigitPixels = 7;
  cMaxColumnWidth = 255;

// Excel's ColumnWidth (characters) as a file stores it, and back: whole pixels, 5 of them padding
function WidthToFile(aCharacters: Double): Double;
begin
  if aCharacters <= 0 then
    Exit(0);
  Result := Trunc((Trunc(aCharacters * cDigitPixels + 0.5) + 5) / cDigitPixels * 256) / 256;
end;

function FileToWidth(aWidth: Double): Double;
begin
  var pixels: integer := Trunc(aWidth * cDigitPixels + 0.5) - 5;
  if pixels <= 0 then
    Exit(0);
  Result := Trunc(pixels / cDigitPixels * 100 + 0.5) / 100;
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

{$ENDREGION}

{$REGION 'Ranges'}

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

{$ENDREGION}

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

function TRange.GetNumberFormat: string;
begin
  Result := fSheet.fWorkbook.FormatCode(fSheet.EffectiveStyle(fTop, fLeft));
end;

procedure TRange.SetNumberFormat(const aValue: string);
begin
  var why: string := NumberFormatError(aValue);
  var id: integer := -1;
  if why <> '' then
    why := 'a number format Excel would not open (' + why + ')'
  else
  begin
    id := fSheet.fWorkbook.FormatId(aValue);
    if id < 0 then
      why := 'the workbook has no styles to add a number format to';
  end;
  if why <> '' then
  begin
    fSheet.fWorkbook.fIssues.Add(isError, 'NumberFormat', fSheet.fName + '!' + Address, why + ' - not written');
    Exit;
  end;
  fSheet.Restyle(Self,
    procedure(aXf: TXfCT)
    begin
      aXf.NumFmtId := id;
      aXf.ApplyNumberFormat := True;
    end);
end;

function TRange.GetFont: TRangeFont;
begin
  Result.fSheet := fSheet;
  Result.fTop := fTop;
  Result.fLeft := fLeft;
  Result.fBottom := fBottom;
  Result.fRight := fRight;
end;

function TRange.GetColumns: TRangeColumns;
begin
  Result.fSheet := fSheet;
  Result.fTop := fTop;
  Result.fLeft := fLeft;
  Result.fBottom := fBottom;
  Result.fRight := fRight;
end;

function TRange.GetColumnWidth: Double;
begin
  var column: TColCT := fSheet.ColumnEntry(fLeft);
  if column = nil then
    Result := fSheet.DefaultWidth
  else if column.Hidden then
    Result := 0
  else // no width: Excel's 0
    Result := FileToWidth(column.Width);
end;

procedure TRange.SetColumnWidth(aValue: Double);
begin
  if IsNan(aValue) or (aValue < 0) or (aValue > cMaxColumnWidth) then
    raise EArgumentOutOfRangeException.CreateFmt('A column width of %s: Excel''s are 0 to %d characters',
      [FloatText(aValue, ftDouble), cMaxColumnWidth]);
  for var column: TColCT in fSheet.ColumnEntries(fLeft, fRight) do
  begin
    column.Width := WidthToFile(aValue);
    column.SetPresent(@column.Width);
    column.CustomWidth := True;
    column.Clear(@column.BestFit);
    if aValue = 0 then
      column.Hidden := True
    else
      column.Clear(@column.Hidden);
  end;
end;

{ TRangeFont }

function TRangeFont.GetBold: boolean;
begin
  var font: TFontCT := fSheet.fWorkbook.StyleFont(fSheet.EffectiveStyle(fTop, fLeft));
  Result := (font <> nil) and (font.B.Count > 0) and font.B[0].Val;
end;

procedure TRangeFont.SetBold(aValue: boolean);
begin
  var workbook: TWorkbook := fSheet.fWorkbook;
  fSheet.Restyle(fSheet.MakeRange(fTop, fLeft, fBottom, fRight),
    procedure(aXf: TXfCT)
    begin
      var font: integer := workbook.FontWith(aXf.FontId, aValue);
      if font >= 0 then
      begin
        aXf.FontId := font;
        aXf.ApplyFont := True;
      end;
    end);
end;

{ TRangeColumns }

procedure TRangeColumns.AutoFit;
begin
  fSheet.AutoFit(fSheet.MakeRange(fTop, fLeft, fBottom, fRight));
end;

{ TWorksheetXlsx }

function TWorksheetXlsx.GetWorksheet: TWorksheetE;
begin
  Result := fSheet.Objects(True);
end;

{ TWorksheet }

destructor TWorksheet.Destroy;
begin
  fXlsx.Free;
  ForgetFormulas;
  fPivots.Free;
  fTableRows.Free;
  fTables.Free;
  inherited;
end;

function TWorksheet.GetXlsx: TWorksheetXlsx;
begin
  if fXlsx = nil then
  begin
    fXlsx := TWorksheetXlsx.Create;
    fXlsx.fSheet := Self;
  end;
  Result := fXlsx;
end;

function TWorksheet.Objects(aEdit: boolean): TWorksheetE;
begin
  if aEdit then
    Result := fWorkbook.fPackage.EditPart<TWorksheetE>(fPartName)
  else
    Result := fWorkbook.fPackage.Part<TWorksheetE>(fPartName);
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

// the cell, created where Excel expects it, with its value removed
function TWorksheet.CellForWriting(aRow, aColumn: integer): TCellCT;
begin
  Result := CellForStyle(aRow, aColumn);
  RemoveValue(Result);
  fWorkbook.ValueChanged;
end;

// the cell as it is, created where Excel expects it (rows in order, cells by column) with the style it shows
function TWorksheet.CellForStyle(aRow, aColumn: integer): TCellCT;
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
end;

// each cell of the range given its style changed (one new style for each old one); a whole column's or row's own style
// too, as Excel formats them: the cells it will have take it
procedure TWorksheet.Restyle(const aRange: TRange; const aChange: TProc<TXfCT>);
begin
  var changed: TDictionary<cardinal, integer> := TDictionary<cardinal, integer>.Create;
  try
    var failed: boolean := False;
    var newStyle: TFunc<cardinal, cardinal> :=
      function(aStyle: cardinal): cardinal
      var
        style: integer;
      begin
        if not changed.TryGetValue(aStyle, style) then
        begin
          style := fWorkbook.ChangedStyle(aStyle, aChange);
          changed.Add(aStyle, style);
        end;
        failed := failed or (style < 0);
        if style < 0 then
          Result := aStyle
        else
          Result := style;
      end;
    var sheet: TWorksheetE := Objects(True);
    var wholeColumns: boolean := (aRange.fTop = 1) and (aRange.fBottom = cMaxRow);
    var wholeRows: boolean := (aRange.fLeft = 1) and (aRange.fRight = cMaxColumn);
    if wholeColumns or wholeRows then
    begin
      if wholeColumns then
        for var column: TColCT in ColumnEntries(aRange.fLeft, aRange.fRight) do
        begin
          column.Style := newStyle(column.Style);
          column.SetPresent(@column.Style);
        end
      else
        for var number := aRange.fTop to aRange.fBottom do
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
            row.S := newStyle(row.S)
          else
            row.S := newStyle(0);
          row.CustomFormat := True;
        end;
      // the cells there already
      var rowIndex: integer;
      FindRow(sheet, aRange.fTop, rowIndex);
      var rows: TRowCTList := sheet.SheetData.Row;
      while (rowIndex < rows.Count) and (rows[rowIndex].R <= cardinal(aRange.fBottom)) do
      begin
        var row: TRowCT := rows[rowIndex];
        if wholeColumns and wholeRows and row.CustomFormat then
          row.S := newStyle(row.S); // the whole sheet: a formatted row's empty cells too
        var cellIndex: integer;
        FindInRow(row, aRange.fLeft, cellIndex);
        while (cellIndex < row.C.Count) and (ColumnOf(row.C[cellIndex].R) <= aRange.fRight) do
        begin
          row.C[cellIndex].S := newStyle(row.C[cellIndex].S);
          Inc(cellIndex);
        end;
        Inc(rowIndex);
      end;
    end
    else
      for var row := aRange.fTop to aRange.fBottom do
        for var column := aRange.fLeft to aRange.fRight do
        begin
          var cell: TCellCT := CellForStyle(row, column);
          cell.S := newStyle(cell.S);
        end;
    if failed then
      fWorkbook.fIssues.Add(isError, 'NoStyles', fName + '!' + aRange.Address,
        'the workbook has no styles to change - not written');
  finally
    changed.Free;
  end;
end;

// the width of a column without its own, in characters: Excel's 8.43 unless the sheet says
function TWorksheet.DefaultWidth: Double;
begin
  var sheet: TWorksheetE := Objects(False);
  var base: cardinal := 8;
  if sheet.IsPresent('SheetFormatPr') then
  begin
    if sheet.SheetFormatPr.Present[@sheet.SheetFormatPr.DefaultColWidth] then
      Exit(FileToWidth(sheet.SheetFormatPr.DefaultColWidth));
    if sheet.SheetFormatPr.Present[@sheet.SheetFormatPr.BaseColWidth] then
      base := sheet.SheetFormatPr.BaseColWidth;
  end;
  // base characters and the padding, in whole multiples of 8 pixels
  var pixels: integer := (integer(base) * cDigitPixels + 5 + 7) div 8 * 8;
  Result := Trunc((pixels - 5) / cDigitPixels * 100 + 0.5) / 100;
end;

// the column's <col>, nil when it has none
function TWorksheet.ColumnEntry(aColumn: integer): TColCT;
begin
  for var columns: TColsCT in Objects(False).Cols do
    for var column: TColCT in columns.Col do
      if (cardinal(aColumn) >= column.Min) and (cardinal(aColumn) <= column.Max) then
        Exit(column);
  Result := nil;
end;

// the <col> entries covering aLeft..aRight exactly, in order: those there split at the ends, the gaps filled with the
// default width (a <col> without one is hidden)
function TWorksheet.ColumnEntries(aLeft, aRight: integer): TArray<TColCT>;

  // the entry across aAt split there: ...aAt-1 and aAt...
  procedure Split(aColumns: TColCTList; aAt: cardinal);
  begin
    for var i := 0 to aColumns.Count - 1 do
      if (aColumns[i].Min < aAt) and (aColumns[i].Max >= aAt) then
      begin
        var copy: TColCT := TColCT.Create;
        TXmlite.XmlToObject(TXmlite.ObjectToXml(aColumns[i]), copy);
        copy.Min := aAt;
        aColumns[i].Max := aAt - 1;
        aColumns.Insert(i + 1, copy);
        Exit;
      end;
  end;

begin
  var sheet: TWorksheetE := Objects(True);
  if sheet.Cols.Count = 0 then
    sheet.Cols.Add(TColsCT.Create);
  var columns: TColCTList := sheet.Cols[0].Col;
  while sheet.Cols.Count > 1 do // one <cols>, as Excel writes
  begin
    var other: TColCTList := sheet.Cols[1].Col;
    while other.Count > 0 do
      columns.Add(other.Extract(other[0]));
    sheet.Cols.Delete(1);
  end;
  columns.Sort(TComparer<TColCT>.Construct(
    function(const aLeftColumn, aRightColumn: TColCT): integer
    begin
      Result := CompareValue(int64(aLeftColumn.Min), int64(aRightColumn.Min));
    end));
  Split(columns, aLeft);
  if aRight < cMaxColumn then
    Split(columns, aRight + 1);
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
      added.Width := WidthToFile(DefaultWidth);
      columns.Insert(i, added);
      Inc(i);
      Result := Result + [added];
      next := last + 1;
    end;
end;

// Excel's AutoFit estimated: the widest shown value of each column in the range's rows, with Excel's 2 pixels of margin
// (numbers and dates a digit more)
procedure TWorksheet.AutoFit(const aRange: TRange);
begin
  var sheet: TWorksheetE := Objects(False);
  var widths: TArray<Double>;
  SetLength(widths, aRange.fRight - aRange.fLeft + 1);
  var fonts: TDictionary<cardinal, TFontCT> := TDictionary<cardinal, TFontCT>.Create; // each style's, nil: none
  try
    var rows: TRowCTList := sheet.SheetData.Row;
    var rowIndex: integer;
    FindRow(sheet, aRange.fTop, rowIndex);
    while (rowIndex < rows.Count) and (rows[rowIndex].R <= cardinal(aRange.fBottom)) do
    begin
      var row: TRowCT := rows[rowIndex];
      var cellIndex: integer;
      FindInRow(row, aRange.fLeft, cellIndex);
      while (cellIndex < row.C.Count) and (ColumnOf(row.C[cellIndex].R) <= aRange.fRight) do
      begin
        var cell: TCellCT := row.C[cellIndex];
        var value: Variant;
        var text: string := '';
        var margin: integer := 0;
        case CellValue(cell, value) of
          cvText, cvError:
            text := value;
          cvBoolean:
            if value then
              text := 'TRUE'
            else
              text := 'FALSE';
          cvNumber, cvDate:
            begin
              var number: Double;
              if TUtility.TryFloatFromText(string(cell.V).Trim, number) then
              begin
                var code: string := fWorkbook.FormatCode(cell.S);
                // the built-in dates show in the reader's own order: measured at their widest, two digits each
                if (code = 'm/d/yyyy') or (code = 'm/d/yyyy h:mm') then
                  code := StringReplace(StringReplace(code, 'm/d', 'mm/dd', []), ' h:', ' hh:', []);
                text := ShownNumber(number, code);
              end;
              margin := cDigitPixels; // too narrow, a number shows ####, where text only runs over
            end;
        end;
        if text <> '' then
        begin
          var font: TFontCT;
          if not fonts.TryGetValue(cell.S, font) then
          begin
            font := fWorkbook.StyleFont(cell.S);
            fonts.Add(cell.S, font);
          end;
          var scale: Double := 1;
          var bold: boolean := False;
          var name: string := '';
          if font <> nil then
          begin
            if (font.Sz.Count > 0) and (font.Sz[0].Val > 0) then
              scale := font.Sz[0].Val / 11;
            bold := (font.B.Count > 0) and font.B[0].Val;
            if font.Name.Count > 0 then
              name := font.Name[0].Val;
          end;
          var index: integer := ColumnOf(cell.R) - aRange.fLeft;
          widths[index] := Max(widths[index], TextPixels(text, name, bold) * scale + margin);
        end;
        Inc(cellIndex);
      end;
      Inc(rowIndex);
    end;
  finally
    fonts.Free;
  end;
  for var i := 0 to High(widths) do
    if widths[i] > 0 then
    begin
      var pixels: integer := Trunc(widths[i] + 0.5) + 2 + 5;
      var width: Double := Min(Trunc(pixels / cDigitPixels * 256) / 256, WidthToFile(cMaxColumnWidth));
      var column: TColCT := ColumnEntries(aRange.fLeft + i, aRange.fLeft + i)[0];
      column.Width := width;
      column.BestFit := True;
      column.CustomWidth := True;
      column.Clear(@column.Hidden);
    end;
end;

// the cell below and right of a frozen pane, '' when there is none
function TWorksheet.GetFreezePanes: string;
begin
  Result := '';
  var sheet: TWorksheetE := Objects(False);
  if not sheet.IsPresent('SheetViews') or (sheet.SheetViews.SheetView.Count = 0) or
    not sheet.SheetViews.SheetView[0].IsPresent('Pane') then
    Exit;
  var pane: TPaneCT := sheet.SheetViews.SheetView[0].Pane;
  if not (pane.State in [stpsFrozen, stpsFrozenSplit]) then
    Exit;
  var top, left, bottom, right: integer;
  if (pane.TopLeftCell <> '') and ParseAddress(pane.TopLeftCell, top, left, bottom, right) and (top = bottom) and
    (left = right) then
    Result := CellName(top, left)
  else
    Result := CellName(Trunc(pane.YSplit) + 1, Trunc(pane.XSplit) + 1);
end;

// Excel's frozen pane and its selections, as Excel writes them for one view
procedure TWorksheet.SetFreezePanes(const aValue: string);
begin
  var row: integer := 1;
  var column: integer := 1;
  if aValue <> '' then
  begin
    var bottom, right: integer;
    if not ParseAddress(aValue, row, column, bottom, right) or (row <> bottom) or (column <> right) then
      raise EArgumentException.CreateFmt('FreezePanes takes a cell: "%s"', [aValue]);
  end;
  var sheet: TWorksheetE := Objects(False);
  var why: string := '';
  if sheet.IsPresent('SheetViews') and (sheet.SheetViews.SheetView.Count > 1) then
    why := 'the sheet has several views; Calcite freezes panes only with one'
  else if sheet.IsPresent('SheetViews') and (sheet.SheetViews.SheetView.Count = 1) and
    sheet.SheetViews.SheetView[0].IsPresent('Pane') and not fFresh then
    why := 'the sheet has panes of its own, which Calcite does not change yet';
  if why <> '' then
  begin
    fWorkbook.fIssues.Add(isError, 'FreezePanes', fName, why + ' - not changed');
    Exit;
  end;
  if (row = 1) and (column = 1) and not sheet.IsPresent('SheetViews') then
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
  if (row = 1) and (column = 1) then
    Exit;
  var pane: TPaneCT := view.Pane;
  pane.XSplit := column - 1;
  pane.YSplit := row - 1;
  pane.TopLeftCell := CellName(row, column);
  pane.State := stpsFrozen;
  pane.SetPresent(@pane.State);
  // a selection in each pane that scrolls, its first cell: Excel's own
  var panes: TArray<TPaneST>;
  var cells: TArray<string>;
  if row = 1 then
  begin
    panes := [stpTopRight];
    cells := [CellName(1, column)];
  end
  else if column = 1 then
  begin
    panes := [stpBottomLeft];
    cells := [CellName(row, 1)];
  end
  else
  begin
    panes := [stpTopRight, stpBottomLeft, stpBottomRight];
    cells := [CellName(1, column), CellName(row, 1), CellName(row, column)];
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
  for var entry: TSheetCT in fWorkbook.fPackage.EditPart<TWorkbookE>(fWorkbook.fWorkbookPart).Sheets.Sheet do
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

{ TWorkbookXlsx }

function TWorkbookXlsx.GetWorkbook: TWorkbookE;
begin
  Result := fWorkbook.GetXml;
end;

function TWorkbookXlsx.GetSharedStrings: TSstE;
begin
  Result := fWorkbook.GetXmlSharedStrings;
end;

function TWorkbookXlsx.GetStyles: TStyleSheetE;
begin
  Result := fWorkbook.GetXmlStyles;
end;

function TWorkbookXlsx.GetCoreProperties: TCorePropertiesE;
begin
  Result := fWorkbook.fPackage.Properties.Xml;
end;

{ TWorkbookProperties }

function TWorkbookProperties.GetText(aIndex: integer): string;
begin
  var core: TCoreProperties := fWorkbook.fPackage.Properties;
  case aIndex of
    0: Result := core.Title;
    1: Result := core.Subject;
    2: Result := core.Creator;
    3: Result := core.Keywords;
    4: Result := core.Description;
    5: Result := core.Category;
    6: Result := core.ContentStatus;
    7: Result := core.LastModifiedBy;
  else
    Result := core.Revision;
  end;
end;

procedure TWorkbookProperties.SetText(aIndex: integer; const aValue: string);
begin
  var core: TCoreProperties := fWorkbook.fPackage.Properties;
  case aIndex of
    0: core.Title := aValue;
    1: core.Subject := aValue;
    2: core.Creator := aValue;
    3: core.Keywords := aValue;
    4: core.Description := aValue;
    5: core.Category := aValue;
    6: core.ContentStatus := aValue;
    7: core.LastModifiedBy := aValue;
  else
    core.Revision := aValue;
  end;
end;

function TWorkbookProperties.GetDate(aIndex: integer): TDateTime;
begin
  if aIndex = 0 then
    Result := fWorkbook.fPackage.Properties.Created
  else
    Result := fWorkbook.fPackage.Properties.Modified;
end;

procedure TWorkbookProperties.SetDate(aIndex: integer; aValue: TDateTime);
begin
  if aIndex = 0 then
    fWorkbook.fPackage.Properties.Created := aValue
  else
    fWorkbook.fPackage.Properties.Modified := aValue;
end;

{ TWorkbook }

constructor TWorkbook.CreateClosed;
begin
  inherited Create;
  fPackage := TPackageOoxml.Create;
  ForwardIssues;
  fSheets := TWorksheets.Create;
  fSheets.fWorkbook := Self;
  fXlsx := TWorkbookXlsx.Create;
  fXlsx.fWorkbook := Self;
  fProperties := TWorkbookProperties.Create;
  fProperties.fWorkbook := Self;
end;

constructor TWorkbook.Create;
begin
  CreateClosed;
  NewPackage;
end;

destructor TWorkbook.Destroy;
begin
  fProperties.Free;
  fXlsx.Free;
  fSheets.Free;
  fPackage.Free;
  fStrings.Free;
  fStyleKeys.Free;
  fFontKeys.Free;
  fDateStyleIds.Free;
  fDateStyles.Free;
  inherited;
end;

class procedure TWorkbook.Swap<T>(var aLeft, aRight: T);
begin
  var value: T := aLeft;
  aLeft := aRight;
  aRight := value;
end;

// the closure holds Self: set again when the package moves to another workbook
procedure TWorkbook.ForwardIssues;
begin
  fPackage.OnIssue :=
    procedure(const aIssue: TIssue)
    begin
      fIssues.Add(aIssue);
    end;
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
  var built: TBytesStream := TBytesStream.Create;
  try
    var zip: TZipFile := TZipFile.Create;
    try
      zip.Open(built, zmWrite);
      for var i := 0 to High(parts) div 2 do
        zip.Add(TEncoding.UTF8.GetBytes(cDeclaration + parts[2 * i + 1]), parts[2 * i]);
      zip.Close;
    finally
      zip.Free;
    end;
    built.Position := 0;
    fPackage.Open(built);
  finally
    built.Free;
  end;
  Load;
  fSheets.fList[0].fFresh := True;
end;

function TWorkbook.Fail(const aCode, aError: string): boolean;
begin
  fError := aError;
  fIssues.Add(isError, aCode, '', aError);
  Result := False;
end;

function TWorkbook.Open(const aFileName: string): boolean;
begin
  Result := Opened(aFileName, nil);
end;

function TWorkbook.Open(aStream: TStream): boolean;
begin
  Result := Opened('', aStream);
end;

// aStream, or the file when it is nil
function TWorkbook.Opened(const aFileName: string; aStream: TStream): boolean;
begin
  // into a workbook of its own first: a failed Open leaves this one as it was, with this Open's issues
  fIssues.Clear;
  var opened: TWorkbook := TWorkbook.CreateClosed;
  try
    opened.fIssues.OnIssue := fIssues.OnIssue;
    var done: boolean;
    if aStream = nil then
      done := opened.fPackage.Open(aFileName)
    else
      done := opened.fPackage.Open(aStream);
    if not done then
    begin
      fIssues := opened.fIssues; // the package's failure among them
      fError := opened.fPackage.Error;
      Exit(False);
    end;
    try
      if not opened.Load then
      begin
        fIssues := opened.fIssues; // Load's failure among them
        fError := opened.fError;
        Exit(False);
      end;
    except
      on e: Exception do
      begin
        if not TUtility.IsFileError(e) then
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
  Swap<TPackageOoxml>(fPackage, aOther.fPackage);
  Swap<string>(fWorkbookPart, aOther.fWorkbookPart);
  Swap<string>(fSharedStringsPart, aOther.fSharedStringsPart);
  Swap<string>(fStylesPart, aOther.fStylesPart);
  Swap<string>(fCalcChainPart, aOther.fCalcChainPart);
  Swap<TWorksheets>(fSheets, aOther.fSheets);
  Swap<TDictionary<string, integer>>(fStrings, aOther.fStrings);
  Swap<TDictionary<string, integer>>(fStyleKeys, aOther.fStyleKeys);
  Swap<TDictionary<string, integer>>(fFontKeys, aOther.fFontKeys);
  Swap<TDictionary<UInt64, integer>>(fDateStyleIds, aOther.fDateStyleIds);
  Swap<TDictionary<cardinal, boolean>>(fDateStyles, aOther.fDateStyles);
  Swap<boolean>(fValuesChanged, aOther.fValuesChanged);
  Swap<boolean>(fFormulasWritten, aOther.fFormulasWritten);
  Swap<TIssues>(fIssues, aOther.fIssues);
  ForwardIssues;
  aOther.ForwardIssues;
  fSheets.fWorkbook := Self;
  aOther.fSheets.fWorkbook := aOther;
  for var sheet: TWorksheet in fSheets do
    sheet.fWorkbook := Self;
  for var sheet: TWorksheet in aOther.fSheets do
    sheet.fWorkbook := aOther;
end;

// a sheet's cells that belong to its tables' and pivot tables' definitions: header and totals rows, pivot tables with their
// page fields above them
procedure TWorkbook.FixedAreas(const aSheetPart: string; aTables, aTableRows, aPivots: TList<TRange>);
begin
  for var relationship: TRelationshipOoxml in fPackage.Relationships(aSheetPart) do
  begin
    var area: TRange;
    if relationship.&Type.EndsWith(cTable) then
    begin
      var table: TTableE := fPackage.Part<TTableE>(relationship.Part);
      if (table <> nil) and ParseAddress(table.Ref, area.fTop, area.fLeft, area.fBottom, area.fRight) then
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
    end
    else if relationship.&Type.EndsWith(cPivotTable) then
    begin
      var pivot: TPivotTableDefinitionE := fPackage.Part<TPivotTableDefinitionE>(relationship.Part);
      if (pivot <> nil) and ParseAddress(pivot.Location.Ref, area.fTop, area.fLeft, area.fBottom, area.fRight) then
      begin
        if pivot.Location.RowPageCount > 0 then // the page fields and a blank row
          area.fTop := Max(1, area.fTop - integer(pivot.Location.RowPageCount) - 1);
        aPivots.Add(area);
      end;
    end;
  end;
end;

function TWorkbook.Load: boolean;
begin
  // the main part is found, not assumed (xl/workbook.xml in Excel's files)
  for var relationship: TRelationshipOoxml in fPackage.Relationships('', cOfficeDocument) do
    fWorkbookPart := relationship.Part;
  if fWorkbookPart.IsEmpty then
    Exit(Fail('NotWorkbook', 'Not an Office document: the package names no main part'));
  var workbook: TWorkbookE := fPackage.Part<TWorkbookE>(fWorkbookPart);
  var relationships: TArray<TRelationshipOoxml> := fPackage.Relationships(fWorkbookPart);
  if Length(relationships) = 0 then
    Exit(Fail('NotWorkbook', Format('%s is not a workbook: it has no relationships', [fWorkbookPart])));
  for var relationship: TRelationshipOoxml in relationships do
    if relationship.&Type.EndsWith(cSharedStrings) then
      fSharedStringsPart := relationship.Part
    else if relationship.&Type.EndsWith(cStyles) then
      fStylesPart := relationship.Part
    else if relationship.&Type.EndsWith(cCalcChain) then
      fCalcChainPart := relationship.Part;

  for var sheetEntry: TSheetCT in workbook.Sheets.Sheet do
    for var relationship: TRelationshipOoxml in relationships do
      if (relationship.Id = sheetEntry.Id) and relationship.&Type.EndsWith(cWorksheet) then
      begin
        if relationship.Part.IsEmpty then
          Exit(Fail('NoSheetPart', Format('The sheet "%s" has no part (%s)', [sheetEntry.Name, relationship.Target])));
        var sheet: TWorksheet := TWorksheet.Create;
        fSheets.fList.Add(sheet);
        sheet.fWorkbook := Self;
        sheet.fName := sheetEntry.Name;
        sheet.fPartName := relationship.Part;
      end;
  Result := True;
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
  for var entry: TSheetCT in fPackage.Part<TWorkbookE>(fWorkbookPart).Sheets.Sheet do
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
  var workbook: TWorkbookE := fPackage.Part<TWorkbookE>(fWorkbookPart);
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

  if not fPackage.HasPart(cContentTypes) then
  begin
    fIssues.Add(isError, 'NoContentTypes', '', 'The package has no content types: a sheet cannot be added');
    Exit(nil);
  end;
  var folder: string := fWorkbookPart.Substring(0, fWorkbookPart.LastIndexOf('/') + 1);
  var number: integer := 0;
  var target: string;
  repeat
    Inc(number);
    target := 'worksheets/sheet' + IntToStr(number) + '.xml';
  until not fPackage.HasPart(folder + target);
  var id: string;
  var partName: string := fPackage.AddPart(fWorkbookPart, cWorksheet, target, cWorksheetType, TWorksheetE.Create, id);
  if partName.IsEmpty then
    Exit(nil);

  workbook := fPackage.EditPart<TWorkbookE>(fWorkbookPart);
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

// Excel's default: a cell is locked unless its style unlocks it
function TWorkbook.IsLockedStyle(aStyle: cardinal): boolean;
begin
  Result := True;
  if fStylesPart.IsEmpty then
    Exit;
  var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
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
  fPackage.EditPart<TWorkbookE>(fWorkbookPart).CalcPr.FullCalcOnLoad := True;
end;

// the calculation chain is Excel's cache: a stale entry is its repair prompt, a missing one is not calculated, so it goes with
// any change of a formula and Excel builds a new one
procedure TWorkbook.FormulaChanged;
begin
  fFormulasWritten := True;
  if fCalcChainPart.IsEmpty then
    Exit;
  fPackage.RemovePart(fWorkbookPart, fCalcChainPart);
  fCalcChainPart := '';
end;

function TWorkbook.Date1904: boolean;
begin
  var workbook: TWorkbookE := fPackage.Part<TWorkbookE>(fWorkbookPart);
  Result := workbook.IsPresent('WorkbookPr') and workbook.WorkbookPr.Date1904;
end;

function TWorkbook.SharedString(aIndex: integer): string;
begin
  Result := '';
  if fSharedStringsPart.IsEmpty then
    Exit;
  var strings: TSstE := fPackage.Part<TSstE>(fSharedStringsPart);
  if (aIndex >= 0) and (aIndex < strings.Si.Count) then
    Result := RichText(strings.Si[aIndex]);
end;

// found or added, one more use counted; -1 when there are no shared strings and they cannot be added
function TWorkbook.SharedStringIndex(const aText: string): integer;
begin
  if fSharedStringsPart.IsEmpty then
  begin
    if not fPackage.HasPart(cContentTypes) then // the caller says why
      Exit(-1);
    var added: TSstE := TSstE.Create;
    var id: string;
    fSharedStringsPart := fPackage.AddPart(fWorkbookPart, cSharedStrings, 'sharedStrings.xml', cSharedStringsType, added, id);
    if fSharedStringsPart.IsEmpty then
      Exit(-1);
    added.Count := 0;
    added.UniqueCount := 0;
    added.SetPresent(@added.Count);
    added.SetPresent(@added.UniqueCount);
  end;
  var strings: TSstE := fPackage.EditPart<TSstE>(fSharedStringsPart);
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
  var strings: TSstE := fPackage.EditPart<TSstE>(fSharedStringsPart);
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
  var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
  Result := styles.IsPresent('CellXfs') and (aStyle < cardinal(styles.CellXfs.Xf.Count)) and
    IsDateFormat(styles.CellXfs.Xf[aStyle].NumFmtId, styles);
  fDateStyles.Add(aStyle, Result);
end;

// aStyle changed by aChange, found in cellXfs by content or added; -1 when there are no styles
function TWorkbook.ChangedStyle(aStyle: cardinal; const aChange: TProc<TXfCT>): integer;
begin
  if fStylesPart.IsEmpty then
    Exit(-1);
  var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
  if not styles.IsPresent('CellXfs') or (styles.CellXfs.Xf.Count = 0) then
    Exit(-1);
  var formats: TXfCTList := styles.CellXfs.Xf;
  if aStyle >= cardinal(formats.Count) then
    aStyle := 0; // as Excel shows such a cell
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
    aChange(wanted);
    var key: string := TXmlite.ObjectToXml(wanted);
    if fStyleKeys.TryGetValue(key, Result) then
      Exit;
    styles := fPackage.EditPart<TStyleSheetE>(fStylesPart);
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

// aStyle with the number format aFormat; -1 when there are no styles. Asked for each date written: kept
function TWorkbook.DateStyle(aStyle: cardinal; aFormat: integer): integer;
begin
  var key: UInt64 := UInt64(aStyle) shl 32 or cardinal(aFormat);
  if fDateStyleIds = nil then
    fDateStyleIds := TDictionary<UInt64, integer>.Create;
  if fDateStyleIds.TryGetValue(key, Result) then
    Exit;
  Result := ChangedStyle(aStyle,
    procedure(aXf: TXfCT)
    begin
      aXf.NumFmtId := aFormat;
      aXf.ApplyNumberFormat := True;
    end);
  fDateStyleIds.Add(key, Result);
end;

// the style's number format as Excel's NumberFormat names it
function TWorkbook.FormatCode(aStyle: cardinal): string;
begin
  Result := 'General';
  if fStylesPart.IsEmpty then
    Exit;
  var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
  if not styles.IsPresent('CellXfs') or (aStyle >= cardinal(styles.CellXfs.Xf.Count)) then
    Exit;
  var id: cardinal := styles.CellXfs.Xf[aStyle].NumFmtId;
  if styles.IsPresent('NumFmts') then
    for var numberFormat: TNumFmtCT in styles.NumFmts.NumFmt do
      if numberFormat.NumFmtId = id then
        Exit(ShownFormat(DecodeText(numberFormat.FormatCode)));
  Result := BuiltInFormat(id);
end;

// the id of a number format, built-in or in numFmts, added when there is none; -1 when there are no styles
function TWorkbook.FormatId(const aCode: string): integer;
begin
  if fStylesPart.IsEmpty then
    Exit(-1);
  var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
  var shown: string := ShownFormat(aCode);
  var builtIn: integer := BuiltInFormatId(shown);
  var last: integer := 163; // custom formats start at 164
  if styles.IsPresent('NumFmts') then
    for var numberFormat: TNumFmtCT in styles.NumFmts.NumFmt do
    begin
      if integer(numberFormat.NumFmtId) = builtIn then
        builtIn := -1; // a built-in id given a code of its own
      if ShownFormat(DecodeText(numberFormat.FormatCode)) = shown then
        Exit(numberFormat.NumFmtId);
      last := Max(last, integer(numberFormat.NumFmtId));
    end;
  if builtIn >= 0 then
    Exit(builtIn);
  styles := fPackage.EditPart<TStyleSheetE>(fStylesPart);
  var added: TNumFmtCT := TNumFmtCT.Create;
  added.NumFmtId := last + 1;
  added.FormatCode := EncodeText(aCode);
  styles.NumFmts.NumFmt.Add(added);
  styles.NumFmts.Count := styles.NumFmts.NumFmt.Count;
  Result := added.NumFmtId;
end;

// the font aFont with bold set or not, found in fonts by content or added; -1 when there are no fonts
function TWorkbook.FontWith(aFont: cardinal; aBold: boolean): integer;
begin
  if fStylesPart.IsEmpty then
    Exit(-1);
  var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
  if not styles.IsPresent('Fonts') or (styles.Fonts.Font.Count = 0) then
    Exit(-1);
  var fonts: TFontCTList := styles.Fonts.Font;
  if aFont >= cardinal(fonts.Count) then
    aFont := 0;
  if fFontKeys = nil then
  begin
    fFontKeys := TDictionary<string, integer>.Create;
    for var i := 0 to fonts.Count - 1 do
      fFontKeys.TryAdd(TXmlite.ObjectToXml(fonts[i]), i);
  end;
  var wanted: TFontCT := TFontCT.Create;
  try
    TXmlite.XmlToObject(TXmlite.ObjectToXml(fonts[aFont]), wanted);
    wanted.B.Clear;
    if aBold then
    begin
      var bold: TBooleanPropertyCT := TBooleanPropertyCT.Create;
      bold.Val := True;
      wanted.B.Add(bold);
    end;
    var key: string := TXmlite.ObjectToXml(wanted);
    if fFontKeys.TryGetValue(key, Result) then
      Exit;
    styles := fPackage.EditPart<TStyleSheetE>(fStylesPart);
    fonts.Add(wanted);
    Result := fonts.Count - 1;
    wanted := nil;
    fFontKeys.Add(key, Result);
    if styles.Fonts.Present[@styles.Fonts.Count] then
      styles.Fonts.Count := fonts.Count;
  finally
    wanted.Free;
  end;
end;

// the font a style shows; nil when there is none
function TWorkbook.StyleFont(aStyle: cardinal): TFontCT;
begin
  Result := nil;
  if fStylesPart.IsEmpty then
    Exit;
  var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
  if not styles.IsPresent('Fonts') or (styles.Fonts.Font.Count = 0) then
    Exit;
  var font: cardinal := 0;
  if styles.IsPresent('CellXfs') and (aStyle < cardinal(styles.CellXfs.Xf.Count)) then
    font := styles.CellXfs.Xf[aStyle].FontId;
  if font >= cardinal(styles.Fonts.Font.Count) then
    font := 0;
  Result := styles.Fonts.Font[font];
end;

function TWorkbook.GetXml: TWorkbookE;
begin
  Result := nil;
  if not fWorkbookPart.IsEmpty then
    Result := fPackage.EditPart<TWorkbookE>(fWorkbookPart);
end;

function TWorkbook.GetXmlSharedStrings: TSstE;
begin
  Result := nil;
  if not fSharedStringsPart.IsEmpty then
  begin
    Result := fPackage.EditPart<TSstE>(fSharedStringsPart);
    FreeAndNil(fStrings); // the user's changes: found again on the next write
  end;
end;

function TWorkbook.GetXmlStyles: TStyleSheetE;
begin
  Result := nil;
  if not fStylesPart.IsEmpty then
  begin
    Result := fPackage.EditPart<TStyleSheetE>(fStylesPart);
    FreeAndNil(fStyleKeys);
    FreeAndNil(fFontKeys);
    FreeAndNil(fDateStyleIds);
    FreeAndNil(fDateStyles);
  end;
end;

function TWorkbook.GetFileName: string;
begin
  Result := fPackage.FileName;
end;

// Excel opens a workbook only under the extension of its kind, and other formats' names would mislead
function TWorkbook.ExtensionError(const aFileName: string): string;
const
  cTypes = 'application/vnd.openxmlformats-';
begin
  Result := '';
  var extension: string := ExtractFileExt(aFileName).ToLower;
  var contentType: string := fPackage.ContentType(fWorkbookPart);
  var kind: string := '';
  if contentType = cTypes + 'officedocument.spreadsheetml.sheet.main+xml' then
    kind := '.xlsx'
  else if contentType = 'application/vnd.ms-excel.sheet.macroEnabled.main+xml' then
    kind := '.xlsm'
  else if contentType = cTypes + 'officedocument.spreadsheetml.template.main+xml' then
    kind := '.xltx'
  else if contentType = 'application/vnd.ms-excel.template.macroEnabled.main+xml' then
    kind := '.xltm';
  if (extension = '.xlsx') or (extension = '.xlsm') or (extension = '.xltx') or (extension = '.xltm') then
  begin
    if not kind.IsEmpty and (extension <> kind) then
      Result := Format('The workbook is %s: Excel refuses it named %s', [kind, extension]);
  end
  else if (extension = '.xls') or (extension = '.xlsb') or (extension = '.ods') or (extension = '.csv') then
    Result := Format('Calcite writes %s, not %s', [kind, extension]);
end;

function TWorkbook.Save: boolean;
begin
  Result := fPackage.Save;
  fError := fPackage.Error;
end;

function TWorkbook.SaveAs(const aFileName: string): boolean;
begin
  var error: string := ExtensionError(aFileName);
  if not error.IsEmpty then
    Exit(Fail('Extension', error));
  Result := fPackage.SaveAs(aFileName);
  fError := fPackage.Error;
end;

function TWorkbook.SaveAs(aStream: TStream): boolean;
begin
  Result := fPackage.SaveAs(aStream);
  fError := fPackage.Error;
end;

end.
