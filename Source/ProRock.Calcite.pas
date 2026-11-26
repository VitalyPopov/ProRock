unit ProRock.Calcite;

// Excel workbooks (.xlsx): open, change and save with nothing lost

interface

uses System.SysUtils, System.Classes, System.Generics.Collections, System.UITypes,
  ProRock.Xmlite, ProRock.Office.Ooxml, ProRock.Xmlite.Schema.Ooxml.Sml, ProRock.Xmlite.Schema.CoreProperties,
  ProRock.Calcite.Utility, ProRock.Calcite.Aspects, ProRock.Calcite.Xlsx, ProRock.Calcite.XlsxSheet;

const
  // Excel's built-in dates: each reader sees them as their own short date, 31.12.2026 or 12/31/2026
  nfShortDate = 'm/d/yyyy';
  nfShortDateTime = 'm/d/yyyy h:mm';

  // the VCL's, for programs without it: Interior.Color := clNone removes a fill, a font or border color clDefault is
  // Excel's automatic
  clNone = TColors.SysNone;
  clDefault = TColors.SysDefault;
  fsBold = TFontStyle.fsBold;
  fsItalic = TFontStyle.fsItalic;
  fsUnderline = TFontStyle.fsUnderline;
  fsStrikeOut = TFontStyle.fsStrikeOut;

  {$REGION 'ProRock.Calcite.Aspects values aliases'}
  ulNone = ProRock.Calcite.Aspects.ulNone;
  ulSingle = ProRock.Calcite.Aspects.ulSingle;
  ulDouble = ProRock.Calcite.Aspects.ulDouble;
  ulSingleAccounting = ProRock.Calcite.Aspects.ulSingleAccounting;
  ulDoubleAccounting = ProRock.Calcite.Aspects.ulDoubleAccounting;
  haGeneral = ProRock.Calcite.Aspects.haGeneral;
  haLeft = ProRock.Calcite.Aspects.haLeft;
  haCenter = ProRock.Calcite.Aspects.haCenter;
  haRight = ProRock.Calcite.Aspects.haRight;
  haFill = ProRock.Calcite.Aspects.haFill;
  haJustify = ProRock.Calcite.Aspects.haJustify;
  haCenterAcrossSelection = ProRock.Calcite.Aspects.haCenterAcrossSelection;
  haDistributed = ProRock.Calcite.Aspects.haDistributed;
  vaTop = ProRock.Calcite.Aspects.vaTop;
  vaCenter = ProRock.Calcite.Aspects.vaCenter;
  vaBottom = ProRock.Calcite.Aspects.vaBottom;
  vaJustify = ProRock.Calcite.Aspects.vaJustify;
  vaDistributed = ProRock.Calcite.Aspects.vaDistributed;
  beLeft = ProRock.Calcite.Aspects.beLeft;
  beTop = ProRock.Calcite.Aspects.beTop;
  beBottom = ProRock.Calcite.Aspects.beBottom;
  beRight = ProRock.Calcite.Aspects.beRight;
  beInsideVertical = ProRock.Calcite.Aspects.beInsideVertical;
  beInsideHorizontal = ProRock.Calcite.Aspects.beInsideHorizontal;
  lsNone = ProRock.Calcite.Aspects.lsNone;
  lsContinuous = ProRock.Calcite.Aspects.lsContinuous;
  lsDash = ProRock.Calcite.Aspects.lsDash;
  lsDot = ProRock.Calcite.Aspects.lsDot;
  lsDashDot = ProRock.Calcite.Aspects.lsDashDot;
  lsDashDotDot = ProRock.Calcite.Aspects.lsDashDotDot;
  lsDouble = ProRock.Calcite.Aspects.lsDouble;
  lsSlantDashDot = ProRock.Calcite.Aspects.lsSlantDashDot;
  bwHairline = ProRock.Calcite.Aspects.bwHairline;
  bwThin = ProRock.Calcite.Aspects.bwThin;
  bwMedium = ProRock.Calcite.Aspects.bwMedium;
  bwThick = ProRock.Calcite.Aspects.bwThick;
  cvEmpty = ProRock.Calcite.Aspects.cvEmpty;
  cvNumber = ProRock.Calcite.Aspects.cvNumber;
  cvDate = ProRock.Calcite.Aspects.cvDate;
  cvText = ProRock.Calcite.Aspects.cvText;
  cvBoolean = ProRock.Calcite.Aspects.cvBoolean;
  cvError = ProRock.Calcite.Aspects.cvError;
  svVisible = ProRock.Calcite.Aspects.svVisible;
  svHidden = ProRock.Calcite.Aspects.svHidden;
  svVeryHidden = ProRock.Calcite.Aspects.svVeryHidden;
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

  {$REGION 'ProRock.Calcite.Aspects types aliases'}
  // a date is a number in a date format, as in Excel
  TCellValueType = ProRock.Calcite.Aspects.TCellValueType;
  // Excel's XlSheetVisibility: svVeryHidden is shown again only from code
  TSheetVisibility = ProRock.Calcite.Aspects.TSheetVisibility;
  // Excel's names: XlUnderlineStyle, XlHAlign, XlVAlign, XlBordersIndex, XlLineStyle, XlBorderWeight
  TUnderline = ProRock.Calcite.Aspects.TUnderline;
  THAlign = ProRock.Calcite.Aspects.THAlign;
  TVAlign = ProRock.Calcite.Aspects.TVAlign;
  TBorderEdge = ProRock.Calcite.Aspects.TBorderEdge;
  TBorderEdges = ProRock.Calcite.Aspects.TBorderEdges;
  TLineStyle = ProRock.Calcite.Aspects.TLineStyle;
  TBorderWeight = ProRock.Calcite.Aspects.TBorderWeight;
  {$ENDREGION}

  // Excel's Range.Font: read from the first cell, written to every cell
  TRangeFont = record
  private
    fSheet: TWorksheet;
    fTop, fLeft, fBottom, fRight: integer;

    procedure Apply(const aChange: TFormatChange);
    function GetFlag(aIndex: integer): boolean;
    procedure SetFlag(aIndex: integer; aValue: boolean);
    function GetName: string;
    procedure SetName(const aValue: string);
    function GetSize: Double;
    procedure SetSize(aValue: Double);
    function GetColor: TColor;
    procedure SetColor(aValue: TColor);
    function GetUnderline: TUnderline;
    procedure SetUnderline(aValue: TUnderline);
    function GetStyle: TFontStyles;
    procedure SetStyle(aValue: TFontStyles);
  public
    // a name of the theme's fonts (Aptos Narrow, Calibri) set by name stays that font when the theme changes
    property Name: string read GetName write SetName;
    // in points, 1 to 409
    property Size: Double read GetSize write SetSize;
    // TColor's BGR, as Excel's Color; theme colors read as Excel shows them; clDefault: automatic (reads 0, black)
    property Color: TColor read GetColor write SetColor;
    property Bold: boolean index 0 read GetFlag write SetFlag;
    property Italic: boolean index 1 read GetFlag write SetFlag;
    property Strikethrough: boolean index 2 read GetFlag write SetFlag;
    property Underline: TUnderline read GetUnderline write SetUnderline;
    // the four at once (System.UITypes' fsBold...): fsUnderline is any underline, and written as a single one
    property Style: TFontStyles read GetStyle write SetStyle;
  end;

  // Excel's Range.Interior: a solid fill, the first cell's read, every cell's written
  TRangeInterior = record
  private
    fSheet: TWorksheet;
    fTop, fLeft, fBottom, fRight: integer;

    function GetColor: TColor;
    procedure SetColor(aValue: TColor);
  public
    // clNone: no fill (Excel reads 16777215, white). Patterns read as their background color
    property Color: TColor read GetColor write SetColor;
  end;

  // Excel's Border: one edge of a range, or all of them (Range.Borders)
  TRangeBorder = record
  private
    fSheet: TWorksheet;
    fTop, fLeft, fBottom, fRight: integer;
    fEdges: TBorderEdges;

    function GetLineStyle: TLineStyle;
    procedure SetLineStyle(aValue: TLineStyle);
    function GetWeight: TBorderWeight;
    procedure SetWeight(aValue: TBorderWeight);
    function GetColor: TColor;
    procedure SetColor(aValue: TColor);
  public
    // Excel's pairs: lsContinuous any weight; lsDash, lsDashDot, lsDashDotDot thin or medium; lsDot thin; lsDouble thick;
    // lsSlantDashDot medium. A style takes its own weight where the pair is missing, a weight makes the line continuous.
    // A cell's edge is shared with its neighbour: setting one clears the neighbour's, reading one sees it
    property LineStyle: TLineStyle read GetLineStyle write SetLineStyle;
    property Weight: TBorderWeight read GetWeight write SetWeight;
    // clDefault: automatic (reads 0, black)
    property Color: TColor read GetColor write SetColor;
  end;

  // Excel's Range.Borders: Borders[beLeft] an edge, the inside ones between the range's cells; Borders.LineStyle all six
  TRangeBorders = record
  private
    fSheet: TWorksheet;
    fTop, fLeft, fBottom, fRight: integer;

    function GetItem(aEdge: TBorderEdge): TRangeBorder;
    function GetAll: TRangeBorder;
    function GetLineStyle: TLineStyle;
    procedure SetLineStyle(aValue: TLineStyle);
    function GetWeight: TBorderWeight;
    procedure SetWeight(aValue: TBorderWeight);
    function GetColor: TColor;
    procedure SetColor(aValue: TColor);
  public
    property Items[aEdge: TBorderEdge]: TRangeBorder read GetItem; default;
    // read: the left edge's
    property LineStyle: TLineStyle read GetLineStyle write SetLineStyle;
    property Weight: TBorderWeight read GetWeight write SetWeight;
    property Color: TColor read GetColor write SetColor;
  end;

  // An address on a sheet, not the cells themselves: no Free. Reading creates nothing, writing creates the cells it needs
  TRange = record
  public type
    // Excel's Range.Columns: the range's columns (Sheet.Columns: the sheet's)
    TColumns = record
    private
      fSheet: TWorksheet;
      fTop, fLeft, fBottom, fRight: integer;

      function GetCount: integer;
      function GetItem(aIndex: integer): TRange;
      function GetItemByLetters(const aColumns: string): TRange;
    public
      // Excel's AutoFit, estimated: each column as wide as its longest shown value in the range's rows, numbers and dates a
      // digit wider (too narrow, Excel shows ####). Calcite measures no fonts: Latin letters, digits and signs exact in
      // Calibri and Aptos Narrow, other fonts as Calibri, other scripts close. A column with nothing in those rows keeps its
      // width
      procedure AutoFit;

      property Count: integer read GetCount;
      // Excel's Columns(2), Columns("B"), Columns("B:D"), counted from the range's first column as in Excel:
      // Range['C1:E5'].Columns[2] is D1:D5, Sheet.Columns['B'] the whole column B
      property Items[aIndex: integer]: TRange read GetItem; default;
      property Items[const aColumns: string]: TRange read GetItemByLetters; default;
    end;

    // Excel's Range.Rows: the range's rows (Sheet.Rows: the sheet's)
    TRows = record
    private
      fSheet: TWorksheet;
      fTop, fLeft, fBottom, fRight: integer;

      function GetCount: integer;
      function GetItem(aIndex: integer): TRange;
      function GetItemByNumbers(const aRows: string): TRange;
    public
      // Excel's AutoFit: the rows' own heights dropped, Excel fits them to what they show when it opens the file (RowHeight
      // reads the default until then)
      procedure AutoFit;

      property Count: integer read GetCount;
      // Excel's Rows(2), Rows("5:7"), counted from the range's first row: Range['C3:E5'].Rows[2] is C4:E4, Sheet.Rows[200]
      // the whole row 200
      property Items[aIndex: integer]: TRange read GetItem; default;
      property Items[const aRows: string]: TRange read GetItemByNumbers; default;
    end;
  private
    fSheet: TWorksheet;
    fTop, fLeft, fBottom, fRight: integer;

    function Area: TArea; inline;
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
    function GetInterior: TRangeInterior;
    function GetBorders: TRangeBorders;
    function GetHorizontalAlignment: THAlign;
    procedure SetHorizontalAlignment(aValue: THAlign);
    function GetVerticalAlignment: TVAlign;
    procedure SetVerticalAlignment(aValue: TVAlign);
    function GetWrapText: boolean;
    procedure SetWrapText(aValue: boolean);
    function GetColumns: TColumns;
    function GetRows: TRows;
    function GetEntireRow: TRange;
    function GetEntireColumn: TRange;
    function GetColumnWidth: Double;
    procedure SetColumnWidth(aValue: Double);
    function GetRowHeight: Double;
    procedure SetRowHeight(aValue: Double);
    function GetHidden: boolean;
    procedure SetHidden(aValue: boolean);
    procedure HiddenAxis(out aByRows: boolean; out aFirst, aLast: integer);
    function GetMergeCells: boolean;
    procedure SetMergeCells(aValue: boolean);
    function GetMergeArea: TRange;
  public
    // the values gone, as Excel's ClearContents: a cell with a format stays. A merged area touched is cleared whole
    procedure ClearContents;
    // Excel's Insert and Delete of whole rows or columns (Sheet.Rows['5:7'].Insert, Range['B5'].EntireColumn.Delete): cells,
    // merged areas, conditional formats, validation, hyperlinks, the autofilter and frozen panes move, formulas and names on
    // every sheet change as in Excel; new rows and columns take the format of the one above or left. EInvalidOpException
    // with nothing changed where Excel refuses (part of an array formula, cells pushed off the sheet) or for what Calcite
    // does not move yet (tables, pivot tables, charts, drawings, notes); cells shifted within rows or columns: later
    procedure Insert;
    procedure Delete;

    property Sheet: TWorksheet read fSheet;
    property Row: integer read fTop;
    property Column: integer read fLeft;
    property RowCount: integer read GetRowCount;
    property ColumnCount: integer read GetColumnCount;
    // the bottom row and the right column: B2:D5 has LastRow 5, LastColumn 4
    property LastRow: integer read fBottom;
    property LastColumn: integer read fRight;
    // B5, A1:C10; whole columns B:D and rows 5:7, as Excel's
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
    property Interior: TRangeInterior read GetInterior;
    property Borders: TRangeBorders read GetBorders;
    // Excel's BorderAround: the outline only, the inside edges kept
    procedure BorderAround(aLineStyle: TLineStyle = lsContinuous; aWeight: TBorderWeight = bwThin;
      aColor: TColor = clDefault);
    // Excel's alignment, the first cell's; written to every cell
    property HorizontalAlignment: THAlign read GetHorizontalAlignment write SetHorizontalAlignment;
    property VerticalAlignment: TVAlign read GetVerticalAlignment write SetVerticalAlignment;
    property WrapText: boolean read GetWrapText write SetWrapText;

    property Columns: TColumns read GetColumns;
    property Rows: TRows read GetRows;
    // the whole rows and columns the range is in: Range['C5:D6'].EntireRow is 5:6
    property EntireRow: TRange read GetEntireRow;
    property EntireColumn: TRange read GetEntireColumn;
    // Excel's ColumnWidth in characters of the default font's digits (8.43 by default), the first column's; written to every
    // column of the range, 0 hides them; EArgumentOutOfRangeException beyond 0..255
    property ColumnWidth: Double read GetColumnWidth write SetColumnWidth;
    // Excel's RowHeight in points, the first row's as the file stores it (Excel shows it rounded to its screen), 0 when
    // hidden; written to every row of the range, 0 hides them; EArgumentOutOfRangeException beyond 0..409.5
    property RowHeight: Double read GetRowHeight write SetRowHeight;
    // whole rows or columns only, as in Excel (Range['B5'].EntireRow.Hidden; EInvalidOpException otherwise): the first
    // one's read, every one written; a row's height and a column's width come back when shown again
    property Hidden: boolean read GetHidden write SetHidden;

    // Excel's Merge: one cell over the range (aAcross: one for each row). It keeps the first value, read row by row, in the
    // top-left cell and clears the others; every cell takes the top-left cell's format; merged areas it meets become part
    // of it. Refused (an issue) over an array formula, a data table, a table or a pivot table
    procedure Merge(aAcross: boolean = False);
    // every merged area the range touches, whole; the cells keep their formats
    procedure UnMerge;
    // every cell is merged; written: Merge or UnMerge
    property MergeCells: boolean read GetMergeCells write SetMergeCells;
    // the merged area of the first cell, the cell itself when it is not merged. A value written to a merged area's cell
    // other than its top-left one is not written (a warning), as Excel shows only that one. Formats go to the cells named,
    // as in Excel: MergeArea.BorderAround outlines the whole area
    property MergeArea: TRange read GetMergeArea;
  end;

  TRangeColumns = TRange.TColumns;
  TRangeRows = TRange.TRows;

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
    fStore: TXlsxSheet;
    fXlsx: TWorksheetXlsx;
    fName: string;
    fLockedWritten: boolean; // reported once a sheet
    fFresh: boolean; // made here, a new workbook's or added: nothing outside Calcite can name it yet

    function GetXlsx: TWorksheetXlsx;
    function FormatAt(aRow, aColumn: integer): TCellFormat;
    function CheckFormula(aRow, aColumn: integer; const aFormula: Variant; out aText: string): boolean;
    function Blocker(aRow, aColumn: integer; const aTarget: TRange; out aCode, aWhy: string): boolean;
    function CanWrite(aRow, aColumn: integer; const aTarget: TRange): boolean;
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
    function MakeRange(aTop, aLeft, aBottom, aRight: integer): TRange; overload;
    function MakeRange(const aArea: TArea): TRange; overload;
    function GetRange(const aAddress: string): TRange;
    function GetCells(aRow, aColumn: integer): TRange;
    function GetCellsByLetters(aRow: integer; const aColumn: string): TRange;
    function GetUsedRange: TRange;
    function GetColumns: TRangeColumns;
    function GetRows: TRangeRows;
    procedure SetName(const aValue: string);
    procedure ApplyStyle(const aRange: TRange; const aChange: TFormatChange; aExisting: boolean = False);
    function MergedAt(aRow, aColumn: integer; out aArea: TArea): boolean;
    function IsCovered(aRow, aColumn: integer): boolean;
    function Uncovered(aRow, aColumn: integer): boolean;
    function WithMerges(const aRange: TRange): TArea;
    procedure Merge(const aRange: TRange);
    procedure UnMerge(const aRange: TRange);
    function GetVisible: TSheetVisibility;
    procedure SetVisible(aValue: TSheetVisibility);
    procedure ApplyBorders(const aRange: TRange; aEdges: TBorderEdges; const aChange: TFormatChange);
    function BorderSide(aRow, aColumn: integer; aEdge: TCellSide): TBorderLine;
    procedure AutoFit(const aRange: TRange);
    function GetFreezePanes: string;
    procedure SetFreezePanes(const aValue: string);
    procedure Shift(const aMap: TReferenceMap);
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
    // Excel's Worksheet.Columns and Rows: Sheet.Columns[2], Sheet.Columns['B:D'], Sheet.Rows[200], Sheet.Rows['5:7'] -
    // whole columns and rows to format before they hold anything
    property Columns: TRangeColumns read GetColumns;
    property Rows: TRangeRows read GetRows;
    // Excel's Freeze Panes at a cell: the rows above it and the columns left of it stay put ('A2' - the first row, 'B1' - the
    // first column); '' or 'A1' unfreezes. A sheet with several views, or an opened sheet's panes, is not changed (an issue)
    property FreezePanes: string read GetFreezePanes write SetFreezePanes;
    // Excel's Visible: hiding the last visible sheet raises EInvalidOpException, as in Excel; hiding the active one makes
    // the next visible sheet active
    property Visible: TSheetVisibility read GetVisible write SetVisible;

    // Excel's Delete: what names the sheet elsewhere becomes #REF! (a 3-D range's end on it moves to the next worksheet),
    // its names, parts and pivot caches only it used go, and the object is freed - with its ranges. EInvalidOpException
    // with nothing changed for the last visible sheet and a very hidden one (as Excel), and what Calcite cannot do yet
    procedure Delete;
  end;

  // in the workbook's order, numbered from 1 as in Excel; chart sheets are not listed
  TWorksheets = class
  public type
    // for var sheet in Workbook.Worksheets: in the workbook's order
    TEnumerator = record
    private
      fList: TList<TWorksheet>;
      fIndex: integer;

      function GetCurrent: TWorksheet; inline;
    public
      function MoveNext: boolean; inline;

      property Current: TWorksheet read GetCurrent;
    end;
  private
    fWorkbook: TWorkbook;
    fList: TObjectList<TWorksheet>;

    constructor Create;
    function GetCount: integer;
    function GetItem(aIndex: integer): TWorksheet;
    function GetItemByName(const aName: string): TWorksheet;
  public
    destructor Destroy; override;

    function GetEnumerator: TEnumerator;
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
    fDateFormats: array[0 .. 1] of string; // DateFormat, DateTimeFormat
    fBook: TXlsxBook;
    fSheets: TWorksheets;
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
    function SheetNameError(const aName: string; aExcept: TWorksheet): string;
    function AddSheet(const aName: string): TWorksheet;

    function GetFileName: string;
    function ExtensionError(const aFileName: string): string;
    function GetDateFormat(aIndex: integer): string;
    procedure SetDateFormat(aIndex: integer; const aValue: string);
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
    property Worksheets: TWorksheets read fSheets;
    // Excel's File > Info: title, author, dates (Save sets Modified when anything changed); the open file's, after an Open too
    property Properties: TWorkbookProperties read fProperties;
    // what a date written into an unformatted cell gets (a date with a time: DateTimeFormat); 'dd.mm.yyyy' shows so to
    // every reader. EArgumentException for a code that is no date or one Excel would not open. Kept over Open
    property DateFormat: string index 0 read GetDateFormat write SetDateFormat;
    property DateTimeFormat: string index 1 read GetDateFormat write SetDateFormat;
  end;

implementation

uses System.Math, System.Variants, System.DateUtils, System.TypInfo, System.Character, System.Generics.Defaults, System.Zip,
  ProRock.Calcite.Formulas, ProRock.Calcite.Formats, ProRock.Calcite.XlsxWalk;

const

  // Excel's number format a time of day gets: h:mm:ss
  cTimeFormat = 21;

{$REGION 'Excel''s largest sizes'}

const
  // Excel's largest width (characters) and row height (points)
  cMaxColumnWidth = 255;
  cMaxRowHeight = 409.5;

{$ENDREGION}

{$REGION 'formats: colors, changes, the borders shown'}

procedure CheckColor(aValue: TColor; aDefault, aNone: boolean);
begin
  if (aValue >= 0) and (aValue <= $FFFFFF) or aDefault and (aValue = clDefault) or aNone and (aValue = clNone) then
    Exit;
  raise EArgumentException.CreateFmt('Not a color Excel stores: $%.8X (RGB values, $000000 to $FFFFFF)', [aValue]);
end;

// a change of aAspects; their values set after
function FormatChange(aAspects: TAspects): TFormatChange;
begin
  Result := Default(TFormatChange);
  Result.Aspects := aAspects;
end;

function AxisChange(aAspects: TAxisAspects; aSize: Double = 0; aHidden: boolean = False): TAxisChange;
begin
  Result.Aspects := aAspects;
  Result.Value.Size := aSize;
  Result.Value.Hidden := aHidden;
end;

// the side Excel reads for a range's edge: the first cell's, the last column's right, the last row's bottom, the inside
// ones the first cell's right and bottom
function ShownSide(aSheet: TWorksheet; aTop, aLeft, aBottom, aRight: integer; aEdges: TBorderEdges): TBorderLine;
begin
  var edge: TBorderEdge := beLeft;
  for var each: TBorderEdge in aEdges do
  begin
    edge := each;
    Break;
  end;
  case edge of
    beBottom: Result := aSheet.BorderSide(aBottom, aLeft, beBottom);
    beRight: Result := aSheet.BorderSide(aTop, aRight, beRight);
    beInsideVertical:
      if aLeft = aRight then
        Result := cNoLine
      else
        Result := aSheet.BorderSide(aTop, aLeft, beRight);
    beInsideHorizontal:
      if aTop = aBottom then
        Result := cNoLine
      else
        Result := aSheet.BorderSide(aTop, aLeft, beBottom);
  else
    Result := aSheet.BorderSide(aTop, aLeft, edge);
  end;
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

function TRange.Area: TArea;
begin
  Result := TArea.Make(fTop, fLeft, fBottom, fRight);
end;

function TRange.GetAddress: string;
begin
  Result := Area.Address;
end;

function TRange.GetValue: Variant;
begin
  if (fBottom = fTop) and (fRight = fLeft) then
  begin
    fSheet.fStore.ValueAt(fTop, fLeft, Result);
    Exit;
  end;
  Result := VarArrayCreate([1, RowCount, 1, ColumnCount], varVariant);
  for var row := fTop to fBottom do
    for var column := fLeft to fRight do
    begin
      var value: Variant;
      fSheet.fStore.ValueAt(row, column, value);
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
        fSheet.WriteValue(row, column, TUtility.ArrayItem(aValue, row - fTop, column - fLeft), Self)
      else
        fSheet.WriteValue(row, column, aValue, Self);
end;

function TRange.GetValueType: TCellValueType;
begin
  var value: Variant;
  Result := fSheet.fStore.ValueAt(fTop, fLeft, value);
end;

function TRange.GetAsString: string;
begin
  var value: Variant;
  case fSheet.fStore.ValueAt(fTop, fLeft, value) of
    cvEmpty:
      Result := '';
    cvNumber:
      Result := TUtility.FloatText(Double(value), ftDouble);
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
  case fSheet.fStore.ValueAt(fTop, fLeft, value) of
    cvEmpty:
      Result := 0;
    cvNumber:
      Result := value;
    cvDate: // the number stored, as Excel's Value2
      TUtility.TryFloatFromText(string(fSheet.fStore.FindCell(fTop, fLeft).V).Trim, Result);
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
    raise EConvertError.CreateFmt('%s holds %s, beyond an Int64', [Address, TUtility.FloatText(number, ftDouble)]);
  Result := Round(number);
end;

procedure TRange.SetAsInteger(aValue: Int64);
begin
  SetValue(aValue);
end;

function TRange.GetAsDateTime: TDateTime;
begin
  var value: Variant;
  case fSheet.fStore.ValueAt(fTop, fLeft, value) of
    cvEmpty:
      Result := 0;
    cvNumber:
      Result := TUtility.SerialToDate(value, fSheet.fWorkbook.fBook.Date1904);
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
  case fSheet.fStore.ValueAt(fTop, fLeft, value) of
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
  fSheet.ClearContents(fSheet.MakeRange(fSheet.WithMerges(Self)));
end;

function TRange.GetFormula: Variant;

  function CellFormula(aRow, aColumn: integer): string;
  begin
    if fSheet.fStore.FormulaText(aRow, aColumn, Result) then
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
        var item: Variant := TUtility.ArrayItem(aValue, row - fTop, column - fLeft);
        if TUtility.IsNoFormula(item) then
          fSheet.ClearContents(fSheet.MakeRange(row, column, row, column))
        else if fSheet.CheckFormula(row, column, item, text) then
          fSheet.WriteFormula(row, column, text, Self);
      end;
  end
  else if TUtility.IsNoFormula(aValue) then
    ClearContents
  else if fSheet.CheckFormula(fTop, fLeft, aValue, text) then // checked once, moved to each cell as Excel fills
    for var row := fTop to fBottom do
      for var column := fLeft to fRight do
      begin
        var moved, why: string;
        ShiftFormula(text, TReferenceMap.Fill(row - fTop, column - fLeft), moved, why);
        fSheet.WriteFormula(row, column, moved, Self);
      end;
end;

function TRange.GetHasFormula: boolean;
begin
  for var row := fTop to fBottom do
    for var column := fLeft to fRight do
    begin
      var text: string;
      if not fSheet.fStore.FormulaText(row, column, text) then
        Exit(False);
    end;
  Result := True;
end;

function TRange.GetHasArray: boolean;
begin
  var area: TArea;
  Result := fSheet.fStore.AreaAt(akArray, fTop, fLeft, area);
end;

function TRange.GetCurrentArray: TRange;
begin
  var area: TArea;
  if not fSheet.fStore.AreaAt(akArray, fTop, fLeft, area) then
    raise EInvalidOpException.CreateFmt('%s!%s is not in an array formula', [fSheet.Name, TUtility.CellName(fTop, fLeft)]);
  Result := fSheet.MakeRange(area);
end;

function TRange.GetFormulaArray: string;
begin
  Result := '';
  if HasArray and fSheet.fStore.FormulaText(fTop, fLeft, Result) then
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
  Result := fSheet.FormatAt(fTop, fLeft).NumberFormat;
end;

procedure TRange.SetNumberFormat(const aValue: string);
var
  change: TFormatChange;
begin
  var why: string := NumberFormatError(aValue);
  var local: string := LocalNotation(aValue);
  if why <> '' then
  begin
    why := 'a number format Excel would not open (' + why + ')';
    if local <> '' then
      why := why + '; ' + local;
  end
  else if fSheet.fWorkbook.fBook.FormatId(aValue) < 0 then // cached: the style's write finds it there
    why := 'the workbook has no styles to add a number format to';
  if why <> '' then
  begin
    fSheet.fWorkbook.fIssues.Add(TIssueSeverity.isError, 'NumberFormat', fSheet.fName + '!' + Address, why + ' - not written');
    Exit;
  end;
  if local <> '' then
    fSheet.fWorkbook.fIssues.Add(TIssueSeverity.isWarning, 'NumberFormat', fSheet.fName + '!' + Address, '"' + aValue + '": ' + local
      + ' - written as it is');
  change := FormatChange([asNumberFormat]);
  change.Value.NumberFormat := aValue;
  fSheet.ApplyStyle(Self, change);
end;

function TRange.GetFont: TRangeFont;
begin
  Result.fSheet := fSheet;
  Result.fTop := fTop;
  Result.fLeft := fLeft;
  Result.fBottom := fBottom;
  Result.fRight := fRight;
end;

function TRange.GetInterior: TRangeInterior;
begin
  Result.fSheet := fSheet;
  Result.fTop := fTop;
  Result.fLeft := fLeft;
  Result.fBottom := fBottom;
  Result.fRight := fRight;
end;

function TRange.GetBorders: TRangeBorders;
begin
  Result.fSheet := fSheet;
  Result.fTop := fTop;
  Result.fLeft := fLeft;
  Result.fBottom := fBottom;
  Result.fRight := fRight;
end;

procedure TRange.BorderAround(aLineStyle: TLineStyle; aWeight: TBorderWeight; aColor: TColor);
var
  change: TFormatChange;
begin
  CheckColor(aColor, True, False);
  change := FormatChange(cBorderAspects);
  change.Line.LineStyle := aLineStyle;
  change.Line.Weight := aWeight;
  change.Line.Color := aColor;
  fSheet.ApplyBorders(Self, [beLeft, beTop, beBottom, beRight], change);
end;

function TRange.GetHorizontalAlignment: THAlign;
begin
  Result := fSheet.FormatAt(fTop, fLeft).HorizontalAlignment;
end;

procedure TRange.SetHorizontalAlignment(aValue: THAlign);
var
  change: TFormatChange;
begin
  change := FormatChange([asHorizontalAlignment]);
  change.Value.HorizontalAlignment := aValue;
  fSheet.ApplyStyle(Self, change);
end;

function TRange.GetVerticalAlignment: TVAlign;
begin
  Result := fSheet.FormatAt(fTop, fLeft).VerticalAlignment;
end;

procedure TRange.SetVerticalAlignment(aValue: TVAlign);
var
  change: TFormatChange;
begin
  change := FormatChange([asVerticalAlignment]);
  change.Value.VerticalAlignment := aValue;
  fSheet.ApplyStyle(Self, change);
end;

function TRange.GetWrapText: boolean;
begin
  Result := fSheet.FormatAt(fTop, fLeft).WrapText;
end;

procedure TRange.SetWrapText(aValue: boolean);
var
  change: TFormatChange;
begin
  change := FormatChange([asWrapText]);
  change.Value.WrapText := aValue;
  fSheet.ApplyStyle(Self, change);
end;

function TRange.GetColumns: TColumns;
begin
  Result.fSheet := fSheet;
  Result.fTop := fTop;
  Result.fLeft := fLeft;
  Result.fBottom := fBottom;
  Result.fRight := fRight;
end;

function TRange.GetRows: TRows;
begin
  Result.fSheet := fSheet;
  Result.fTop := fTop;
  Result.fLeft := fLeft;
  Result.fBottom := fBottom;
  Result.fRight := fRight;
end;

function TRange.GetEntireRow: TRange;
begin
  Result := fSheet.MakeRange(fTop, 1, fBottom, TUtility.cMaxColumn);
end;

function TRange.GetEntireColumn: TRange;
begin
  Result := fSheet.MakeRange(1, fLeft, TUtility.cMaxRow, fRight);
end;

function TRange.GetColumnWidth: Double;
var
  axis: TAxisFormat;
begin
  axis := fSheet.fStore.AxisOf(False, fLeft);
  if axis.Hidden then
    Result := 0
  else
    Result := axis.Size;
end;

procedure TRange.SetColumnWidth(aValue: Double);
begin
  if IsNan(aValue) or (aValue < 0) or (aValue > cMaxColumnWidth) then
    raise EArgumentOutOfRangeException.CreateFmt('A column width of %s: Excel''s are 0 to %d characters',
      [TUtility.FloatText(aValue, ftDouble), cMaxColumnWidth]);
  // Excel writes a width of 0 (shown again, the default), where a row keeps its height
  fSheet.fStore.ApplyAxis(False, fLeft, fRight, AxisChange([axSize, axHidden], aValue, aValue = 0));
end;

function TRange.GetRowHeight: Double;
var
  axis: TAxisFormat;
begin
  axis := fSheet.fStore.AxisOf(True, fTop);
  if axis.Hidden then
    Result := 0
  else
    Result := axis.Size;
end;

procedure TRange.SetRowHeight(aValue: Double);
begin
  if IsNan(aValue) or (aValue < 0) or (aValue > cMaxRowHeight) then
    raise EArgumentOutOfRangeException.CreateFmt('A row height of %s: Excel''s are 0 to %s points',
      [TUtility.FloatText(aValue, ftDouble), TUtility.FloatText(cMaxRowHeight, ftDouble)]);
  if aValue = 0 then // the height kept for when they are shown again
    fSheet.fStore.ApplyAxis(True, fTop, fBottom, AxisChange([axHidden], 0, True))
  else
    fSheet.fStore.ApplyAxis(True, fTop, fBottom, AxisChange([axSize, axHidden], aValue, False));
end;

// what Hidden reads and writes: the range's rows when it spans whole rows, else its whole columns
procedure TRange.HiddenAxis(out aByRows: boolean; out aFirst, aLast: integer);
begin
  aByRows := (fLeft = 1) and (fRight = TUtility.cMaxColumn);
  if aByRows then
  begin
    aFirst := fTop;
    aLast := fBottom;
  end
  else if (fTop = 1) and (fBottom = TUtility.cMaxRow) then
  begin
    aFirst := fLeft;
    aLast := fRight;
  end
  else
    raise EInvalidOpException.CreateFmt('Hidden is for whole rows or columns, not %s: Range[''%s''].EntireRow.Hidden',
      [Address, Address]);
end;

function TRange.GetHidden: boolean;
var
  axis: TAxisFormat;
begin
  var byRows: boolean;
  var first, last: integer;
  HiddenAxis(byRows, first, last);
  axis := fSheet.fStore.AxisOf(byRows, first);
  Result := axis.Hidden or (axis.Size = 0);
end;

procedure TRange.SetHidden(aValue: boolean);
begin
  var byRows: boolean;
  var first, last: integer;
  HiddenAxis(byRows, first, last);
  fSheet.fStore.ApplyAxis(byRows, first, last, AxisChange([axHidden], 0, aValue));
  if not aValue then
    for var index := first to last do
      if fSheet.fStore.AxisOf(byRows, index).Size = 0 then // hidden by a size of 0: shown at the default one
        fSheet.fStore.ApplyAxis(byRows, index, index, AxisChange([axDefaultSize]));
end;

procedure TRange.Merge(aAcross: boolean);
begin
  if aAcross then
    for var row := fTop to fBottom do
      fSheet.Merge(fSheet.MakeRange(row, fLeft, row, fRight))
  else
    fSheet.Merge(Self);
end;

procedure TRange.UnMerge;
begin
  fSheet.UnMerge(Self);
end;

function TRange.GetMergeCells: boolean;
begin
  var area: TArea;
  for var row := fTop to fBottom do
  begin
    var column: integer := fLeft;
    while column <= fRight do
    begin
      if not fSheet.MergedAt(row, column, area) then
        Exit(False);
      column := area.Right + 1;
    end;
  end;
  Result := True;
end;

procedure TRange.SetMergeCells(aValue: boolean);
begin
  if aValue then
    Merge
  else
    UnMerge;
end;

function TRange.GetMergeArea: TRange;
begin
  var area: TArea;
  if fSheet.MergedAt(fTop, fLeft, area) then
    Result := fSheet.MakeRange(area)
  else
    Result := fSheet.MakeRange(fTop, fLeft, fTop, fLeft);
end;

procedure TRange.Insert;
begin
  if (fLeft = 1) and (fRight = TUtility.cMaxColumn) then
    fSheet.Shift(ShiftMap('', fSheet.fName, True, fTop, RowCount))
  else if (fTop = 1) and (fBottom = TUtility.cMaxRow) then
    fSheet.Shift(ShiftMap('', fSheet.fName, False, fLeft, ColumnCount))
  else
    raise EInvalidOpException.CreateFmt('Insert takes whole rows or columns, not %s: Range[''%s''].EntireRow.Insert',
      [Address, Address]);
end;

procedure TRange.Delete;
begin
  if (fLeft = 1) and (fRight = TUtility.cMaxColumn) then
    fSheet.Shift(ShiftMap('', fSheet.fName, True, fTop, -RowCount))
  else if (fTop = 1) and (fBottom = TUtility.cMaxRow) then
    fSheet.Shift(ShiftMap('', fSheet.fName, False, fLeft, -ColumnCount))
  else
    raise EInvalidOpException.CreateFmt('Delete takes whole rows or columns, not %s: Range[''%s''].EntireRow.Delete',
      [Address, Address]);
end;

{ TRangeFont }

procedure TRangeFont.Apply(const aChange: TFormatChange);
begin
  fSheet.ApplyStyle(fSheet.MakeRange(fTop, fLeft, fBottom, fRight), aChange);
end;

function TRangeFont.GetFlag(aIndex: integer): boolean;
begin
  var format: TCellFormat := fSheet.FormatAt(fTop, fLeft);
  case aIndex of
    0: Result := format.Bold;
    1: Result := format.Italic;
  else
    Result := format.Strikethrough;
  end;
end;

procedure TRangeFont.SetFlag(aIndex: integer; aValue: boolean);
const
  cFlags: array[0 .. 2] of TAspect = (asBold, asItalic, asStrikethrough);
var
  change: TFormatChange;
begin
  change := FormatChange([cFlags[aIndex]]);
  change.Value.Bold := aValue;
  change.Value.Italic := aValue;
  change.Value.Strikethrough := aValue;
  Apply(change);
end;

function TRangeFont.GetName: string;
begin
  Result := fSheet.FormatAt(fTop, fLeft).FontName;
end;

procedure TRangeFont.SetName(const aValue: string);
var
  change: TFormatChange;
begin
  change := FormatChange([asFontName]);
  change.Value.FontName := aValue.Trim;
  if change.Value.FontName = '' then
    raise EArgumentException.Create('A font needs a name');
  Apply(change);
end;

function TRangeFont.GetSize: Double;
begin
  Result := fSheet.FormatAt(fTop, fLeft).FontSize;
end;

procedure TRangeFont.SetSize(aValue: Double);
var
  change: TFormatChange;
begin
  if IsNan(aValue) or (aValue < 1) or (aValue > 409) then
    raise EArgumentOutOfRangeException.CreateFmt('A font size of %s: Excel''s are 1 to 409 points',
      [TUtility.FloatText(aValue, ftDouble)]);
  change := FormatChange([asFontSize]);
  change.Value.FontSize := aValue;
  Apply(change);
end;

function TRangeFont.GetColor: TColor;
begin
  Result := fSheet.FormatAt(fTop, fLeft).FontColor;
end;

procedure TRangeFont.SetColor(aValue: TColor);
var
  change: TFormatChange;
begin
  CheckColor(aValue, True, False);
  change := FormatChange([asFontColor]);
  change.Value.FontColor := aValue;
  Apply(change);
end;

function TRangeFont.GetUnderline: TUnderline;
begin
  Result := fSheet.FormatAt(fTop, fLeft).Underline;
end;

procedure TRangeFont.SetUnderline(aValue: TUnderline);
var
  change: TFormatChange;
begin
  change := FormatChange([asUnderline]);
  change.Value.Underline := aValue;
  Apply(change);
end;

function TRangeFont.GetStyle: TFontStyles;
begin
  Result := [];
  var format: TCellFormat := fSheet.FormatAt(fTop, fLeft);
  if format.Bold then
    Include(Result, fsBold);
  if format.Italic then
    Include(Result, fsItalic);
  if format.Underline <> ulNone then
    Include(Result, fsUnderline);
  if format.Strikethrough then
    Include(Result, fsStrikeOut);
end;

procedure TRangeFont.SetStyle(aValue: TFontStyles);
var
  change: TFormatChange;
begin
  change := FormatChange([asBold, asItalic, asStrikethrough, asUnderline]);
  change.Value.Bold := fsBold in aValue;
  change.Value.Italic := fsItalic in aValue;
  change.Value.Strikethrough := fsStrikeOut in aValue;
  if fsUnderline in aValue then
    change.Value.Underline := ulSingle;
  Apply(change);
end;

{ TRangeInterior }

function TRangeInterior.GetColor: TColor;
begin
  Result := fSheet.FormatAt(fTop, fLeft).FillColor;
end;

procedure TRangeInterior.SetColor(aValue: TColor);
var
  change: TFormatChange;
begin
  CheckColor(aValue, False, True);
  change := FormatChange([asFillColor]);
  change.Value.FillColor := aValue;
  fSheet.ApplyStyle(fSheet.MakeRange(fTop, fLeft, fBottom, fRight), change);
end;

{ TRangeBorder }

function TRangeBorder.GetLineStyle: TLineStyle;
begin
  Result := ShownSide(fSheet, fTop, fLeft, fBottom, fRight, fEdges).LineStyle;
end;

procedure TRangeBorder.SetLineStyle(aValue: TLineStyle);
var
  change: TFormatChange;
begin
  change := FormatChange([asLineStyle]);
  change.Line.LineStyle := aValue;
  fSheet.ApplyBorders(fSheet.MakeRange(fTop, fLeft, fBottom, fRight), fEdges, change);
end;

function TRangeBorder.GetWeight: TBorderWeight;
begin
  Result := ShownSide(fSheet, fTop, fLeft, fBottom, fRight, fEdges).Weight;
end;

procedure TRangeBorder.SetWeight(aValue: TBorderWeight);
var
  change: TFormatChange;
begin
  change := FormatChange([asWeight]);
  change.Line.Weight := aValue;
  fSheet.ApplyBorders(fSheet.MakeRange(fTop, fLeft, fBottom, fRight), fEdges, change);
end;

function TRangeBorder.GetColor: TColor;
begin
  Result := ShownSide(fSheet, fTop, fLeft, fBottom, fRight, fEdges).Color;
end;

procedure TRangeBorder.SetColor(aValue: TColor);
var
  change: TFormatChange;
begin
  CheckColor(aValue, True, False);
  change := FormatChange([asBorderColor]);
  change.Line.Color := aValue;
  fSheet.ApplyBorders(fSheet.MakeRange(fTop, fLeft, fBottom, fRight), fEdges, change);
end;

{ TRangeBorders }

function TRangeBorders.GetItem(aEdge: TBorderEdge): TRangeBorder;
begin
  Result := GetAll;
  Result.fEdges := [aEdge];
end;

function TRangeBorders.GetAll: TRangeBorder;
begin
  Result.fSheet := fSheet;
  Result.fTop := fTop;
  Result.fLeft := fLeft;
  Result.fBottom := fBottom;
  Result.fRight := fRight;
  Result.fEdges := [Low(TBorderEdge) .. High(TBorderEdge)];
end;

function TRangeBorders.GetLineStyle: TLineStyle;
begin
  Result := GetItem(beLeft).LineStyle;
end;

procedure TRangeBorders.SetLineStyle(aValue: TLineStyle);
begin
  var all: TRangeBorder := GetAll;
  all.LineStyle := aValue;
end;

function TRangeBorders.GetWeight: TBorderWeight;
begin
  Result := GetItem(beLeft).Weight;
end;

procedure TRangeBorders.SetWeight(aValue: TBorderWeight);
begin
  var all: TRangeBorder := GetAll;
  all.Weight := aValue;
end;

function TRangeBorders.GetColor: TColor;
begin
  Result := GetItem(beLeft).Color;
end;

procedure TRangeBorders.SetColor(aValue: TColor);
begin
  var all: TRangeBorder := GetAll;
  all.Color := aValue;
end;

{ TRange.TColumns }

procedure TRange.TColumns.AutoFit;
begin
  fSheet.AutoFit(fSheet.MakeRange(fTop, fLeft, fBottom, fRight));
end;

function TRange.TColumns.GetCount: integer;
begin
  Result := fRight - fLeft + 1;
end;

function TRange.TColumns.GetItem(aIndex: integer): TRange;
begin
  var column: integer := fLeft + aIndex - 1;
  if (column < 1) or (column > TUtility.cMaxColumn) then
    raise EArgumentOutOfRangeException.CreateFmt('Column %d from %s is off the sheet', [aIndex, TUtility.ColumnName(fLeft)]);
  Result := fSheet.MakeRange(fTop, column, fBottom, column);
end;

function TRange.TColumns.GetItemByLetters(const aColumns: string): TRange;
begin
  var text: string := aColumns.Trim;
  var index: integer := 1;
  var first: integer := TUtility.ReadColumn(text, index);
  var last: integer := first;
  if (index <= text.Length) and (text[index] = ':') then
  begin
    Inc(index);
    last := TUtility.ReadColumn(text, index);
  end;
  if (first = 0) or (last = 0) or (index <= text.Length) then
    raise EArgumentException.CreateFmt('Not columns: "%s" (B or B:D)', [aColumns]);
  Result := GetItem(Min(first, last));
  Result.fRight := GetItem(Max(first, last)).fRight;
end;

{ TRange.TRows }

function TRange.TRows.GetCount: integer;
begin
  Result := fBottom - fTop + 1;
end;

function TRange.TRows.GetItem(aIndex: integer): TRange;
begin
  var row: integer := fTop + aIndex - 1;
  if (row < 1) or (row > TUtility.cMaxRow) then
    raise EArgumentOutOfRangeException.CreateFmt('Row %d from %d is off the sheet', [aIndex, fTop]);
  Result := fSheet.MakeRange(row, fLeft, row, fRight);
end;

function TRange.TRows.GetItemByNumbers(const aRows: string): TRange;
begin
  var text: string := aRows.Trim;
  var index: integer := 1;
  var first: integer := TUtility.ReadRow(text, index);
  var last: integer := first;
  if (index <= text.Length) and (text[index] = ':') then
  begin
    Inc(index);
    last := TUtility.ReadRow(text, index);
  end;
  if (first = 0) or (last = 0) or (index <= text.Length) then
    raise EArgumentException.CreateFmt('Not rows: "%s" (5 or 5:7)', [aRows]);
  Result := GetItem(Min(first, last));
  Result.fBottom := GetItem(Max(first, last)).fBottom;
end;

procedure TRange.TRows.AutoFit;
begin
  fSheet.fStore.ApplyAxis(True, fTop, fBottom, AxisChange([axDefaultSize]));
end;

{ TWorksheetXlsx }

function TWorksheetXlsx.GetWorksheet: TWorksheetE;
begin
  fSheet.fStore.Forget;
  Result := fSheet.fStore.Objects(True);
end;

{ TWorksheet }

destructor TWorksheet.Destroy;
begin
  fXlsx.Free;
  fStore.Free;
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

function TWorksheet.FormatAt(aRow, aColumn: integer): TCellFormat;
begin
  Result := fWorkbook.fBook.FormatOf(fStore.EffectiveStyle(aRow, aColumn));
end;

// Excel's refusal: the cell keeps its value, the rest is done
procedure TWorksheet.Refuse(aRow, aColumn: integer; const aCode, aWhy: string);
begin
  fWorkbook.fIssues.Add(TIssueSeverity.isError, aCode, fName + '!' + TUtility.CellName(aRow, aColumn), aWhy + ' - not written');
end;

// on a protected sheet, a cell its style does not unlock
function TWorksheet.IsLocked(aRow, aColumn: integer): boolean;
begin
  var sheet: TWorksheetE := fStore.Objects(False);
  Result := sheet.IsPresent('SheetProtection') and sheet.SheetProtection.Sheet and
    fWorkbook.fBook.IsLockedStyle(fStore.EffectiveStyle(aRow, aColumn));
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
  if text.Length + 1 > TUtility.cMaxFormula then
    Refuse(aRow, aColumn, 'Formula', Format('%d characters, Excel''s formulas hold up to %d', [text.Length + 1, TUtility.cMaxFormula]))
  else if not StoredFormula(text, aText, why, unknown) then
    Refuse(aRow, aColumn, 'Formula', 'not a formula Excel reads: ' + why)
  else
  begin
    if unknown <> '' then
      fWorkbook.fIssues.Add(TIssueSeverity.isWarning, 'Function', fName + '!' + TUtility.CellName(aRow, aColumn),
        unknown + ' is not one of Excel''s functions (English)');
    Result := True;
  end;
end;

// why a cell cannot be written as part of aTarget: an array formula not wholly in it (Excel changes one only as a whole), a
// data table (Excel's what-if analysis fills it), a table's header or totals row (the table's own definition, a header its
// column's name in formulas), a pivot table (Excel builds it from its cache)
function TWorksheet.Blocker(aRow, aColumn: integer; const aTarget: TRange; out aCode, aWhy: string): boolean;
begin
  Result := True;
  var area: TArea;
  aCode := 'Formula';
  if fStore.AreaAt(akArray, aRow, aColumn, area) and not aTarget.Area.Contains(area) then
    aWhy := 'part of an array formula (' + area.Address + '), which Excel changes only as a whole'
  else if fStore.AreaAt(akDataTable, aRow, aColumn, area) then
    aWhy := 'part of a data table, which Excel''s what-if analysis fills'
  else if fStore.AreaAt(akTableRow, aRow, aColumn, area) then
  begin
    aCode := 'TableRow';
    aWhy := 'a table''s header or totals row (part of the table''s definition, which Calcite does not change yet)';
  end
  else if fStore.AreaAt(akPivot, aRow, aColumn, area) then
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
  var cell: TCellCT := fStore.FindCell(aRow, aColumn);
  if (cell <> nil) and cell.IsPresent('F') and (cell.F.T = stcftShared) and not fStore.Unshare(cell.F.Si) then
  begin
    Refuse(aRow, aColumn, 'Formula', 'part of a shared formula whose text Calcite cannot read');
    Exit(False);
  end;
  if not fLockedWritten and IsLocked(aRow, aColumn) then
  begin
    fLockedWritten := True;
    fWorkbook.fIssues.Add(TIssueSeverity.isWarning, 'Locked', fName + '!' + TUtility.CellName(aRow, aColumn),
      'a locked cell of a protected sheet, written: Excel lets its users change it only unprotected (reported once a sheet)');
  end;
  Result := True;
end;

// aChange written to each cell of the range (one new style for each old one); a whole column's or row's own style too, as
// Excel formats them: the cells it will have take it. aExisting: only the cells there already
procedure TWorksheet.ApplyStyle(const aRange: TRange; const aChange: TFormatChange; aExisting: boolean);
begin
  var changed: TDictionary<cardinal, integer> := TDictionary<cardinal, integer>.Create;
  try
    var failed: boolean := False;
    var book: TXlsxBook := fWorkbook.fBook;
    var newStyle: TFunc<cardinal, cardinal> :=
      function(aStyle: cardinal): cardinal
      var
        style: integer;
      begin
        if not changed.TryGetValue(aStyle, style) then
        begin
          style := book.ChangedStyle(aStyle, aChange.Aspects, aChange.Sides, Applied(book.FormatOf(aStyle), aChange));
          changed.Add(aStyle, style);
        end;
        failed := failed or (style < 0);
        if style < 0 then
          Result := aStyle
        else
          Result := style;
      end;
    fStore.SetStyles(aRange.Area, newStyle, aExisting);
    if failed then
      fWorkbook.fIssues.Add(TIssueSeverity.isError, 'NoStyles', fName + '!' + aRange.Address,
        'the workbook has no styles to change - not written');
  finally
    changed.Free;
  end;
end;

// aChange for each side the edges give each cell (the inside ones both cells' sides, as Excel writes them), in at most
// nine areas; the neighbours' sides on the outer edges cleared, as Excel keeps an edge on one cell
procedure TWorksheet.ApplyBorders(const aRange: TRange; aEdges: TBorderEdges; const aChange: TFormatChange);
type
  TBand = record
    First, Last: integer;
    Low, High: boolean; // the band's top (or left) side, its bottom (or right) one
  end;

  // the rows (or columns) in bands with the same sides: the first gets aLow, the last aHigh, between them aInside
  function Bands(aFirst, aLast: integer; aLow, aHigh, aInside: boolean): TArray<TBand>;
  begin
    Result := nil;
    var starts: TArray<integer> := [aFirst, aFirst + 1, aLast];
    var ends: TArray<integer> := [aFirst, aLast - 1, aLast];
    for var i := 0 to 2 do
      if (ends[i] >= starts[i]) and ((i = 0) or (starts[i] > Result[High(Result)].Last)) then
      begin
        var band: TBand;
        band.First := starts[i];
        band.Last := ends[i];
        band.Low := (band.First = aFirst) and aLow or (band.First > aFirst) and aInside;
        band.High := (band.Last = aLast) and aHigh or (band.Last < aLast) and aInside;
        if (Length(Result) > 0) and (Result[High(Result)].Low = band.Low) and (Result[High(Result)].High = band.High) then
          Result[High(Result)].Last := band.Last
        else
          Result := Result + [band];
      end;
  end;

var
  change, clear: TFormatChange;
begin
  var rows: TArray<TBand> := Bands(aRange.fTop, aRange.fBottom, beTop in aEdges, beBottom in aEdges,
    beInsideHorizontal in aEdges);
  var columns: TArray<TBand> := Bands(aRange.fLeft, aRange.fRight, beLeft in aEdges, beRight in aEdges,
    beInsideVertical in aEdges);
  change := aChange;
  for var rowBand: TBand in rows do
    for var columnBand: TBand in columns do
    begin
      change.Sides := [];
      if rowBand.Low then
        Include(change.Sides, beTop);
      if rowBand.High then
        Include(change.Sides, beBottom);
      if columnBand.Low then
        Include(change.Sides, beLeft);
      if columnBand.High then
        Include(change.Sides, beRight);
      if change.Sides <> [] then
        ApplyStyle(MakeRange(rowBand.First, columnBand.First, rowBand.Last, columnBand.Last), change);
    end;
  clear := FormatChange([asLineStyle]); // lsNone
  if (beLeft in aEdges) and (aRange.fLeft > 1) then
  begin
    clear.Sides := [beRight];
    ApplyStyle(MakeRange(aRange.fTop, aRange.fLeft - 1, aRange.fBottom, aRange.fLeft - 1), clear, True);
  end;
  if (beRight in aEdges) and (aRange.fRight < TUtility.cMaxColumn) then
  begin
    clear.Sides := [beLeft];
    ApplyStyle(MakeRange(aRange.fTop, aRange.fRight + 1, aRange.fBottom, aRange.fRight + 1), clear, True);
  end;
  if (beTop in aEdges) and (aRange.fTop > 1) then
  begin
    clear.Sides := [beBottom];
    ApplyStyle(MakeRange(aRange.fTop - 1, aRange.fLeft, aRange.fTop - 1, aRange.fRight), clear, True);
  end;
  if (beBottom in aEdges) and (aRange.fBottom < TUtility.cMaxRow) then
  begin
    clear.Sides := [beTop];
    ApplyStyle(MakeRange(aRange.fBottom + 1, aRange.fLeft, aRange.fBottom + 1, aRange.fRight), clear, True);
  end;
end;

// a cell's side with a line, as Excel reads it: its own, else the neighbour's facing one; nil when neither has one
function TWorksheet.BorderSide(aRow, aColumn: integer; aEdge: TCellSide): TBorderLine;
begin
  Result := FormatAt(aRow, aColumn).Borders[aEdge];
  if Result.LineStyle <> lsNone then
    Exit;
  case aEdge of
    beLeft:
      if aColumn > 1 then
        Result := FormatAt(aRow, aColumn - 1).Borders[beRight];
    beRight:
      if aColumn < TUtility.cMaxColumn then
        Result := FormatAt(aRow, aColumn + 1).Borders[beLeft];
    beTop:
      if aRow > 1 then
        Result := FormatAt(aRow - 1, aColumn).Borders[beBottom];
    beBottom:
      if aRow < TUtility.cMaxRow then
        Result := FormatAt(aRow + 1, aColumn).Borders[beTop];
  end;
end;

function TWorksheet.GetColumns: TRangeColumns;
begin
  Result.fSheet := Self;
  Result.fTop := 1;
  Result.fLeft := 1;
  Result.fBottom := TUtility.cMaxRow;
  Result.fRight := TUtility.cMaxColumn;
end;

function TWorksheet.GetRows: TRangeRows;
begin
  Result.fSheet := Self;
  Result.fTop := 1;
  Result.fLeft := 1;
  Result.fBottom := TUtility.cMaxRow;
  Result.fRight := TUtility.cMaxColumn;
end;

// Excel's AutoFit estimated: the widest shown value of each column in the range's rows, with Excel's 2 pixels of margin
// (numbers and dates a digit more)
procedure TWorksheet.AutoFit(const aRange: TRange);
begin
  var sheet: TWorksheetE := fStore.Objects(False);
  var widths: TArray<Double>;
  SetLength(widths, aRange.fRight - aRange.fLeft + 1);
  var rows: TRowCTList := sheet.SheetData.Row;
  var rowIndex: integer;
  fStore.FindRow(sheet, aRange.fTop, rowIndex);
  while (rowIndex < rows.Count) and (rows[rowIndex].R <= cardinal(aRange.fBottom)) do
  begin
    var row: TRowCT := rows[rowIndex];
    var cellIndex: integer;
    FindInRow(row, aRange.fLeft, cellIndex);
    while (cellIndex < row.C.Count) and (TUtility.ColumnOf(row.C[cellIndex].R) <= aRange.fRight) do
    begin
      var cell: TCellCT := row.C[cellIndex];
      var value: Variant;
      var text: string := '';
      var margin: integer := 0;
      var format: TCellFormat := fWorkbook.fBook.FormatOf(cell.S);
      case fStore.ValueOf(cell, value) of
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
              var code: string := format.NumberFormat;
              // the built-in dates show in the reader's own order: measured at their widest, two digits each
              if (code = 'm/d/yyyy') or (code = 'm/d/yyyy h:mm') then
                code := StringReplace(StringReplace(code, 'm/d', 'mm/dd', []), ' h:', ' hh:', []);
              text := ShownNumber(number, code);
            end;
            margin := TUtility.cDigitPixels; // too narrow, a number shows ####, where text only runs over
          end;
      end;
      if text <> '' then
      begin
        var scale: Double := 1;
        if format.FontSize > 0 then
          scale := format.FontSize / 11;
        var index: integer := TUtility.ColumnOf(cell.R) - aRange.fLeft;
        widths[index] := Max(widths[index], TUtility.TextPixels(text, format.FontName, format.Bold) * scale + margin);
      end;
      Inc(cellIndex);
    end;
    Inc(rowIndex);
  end;
  for var i := 0 to High(widths) do
    if widths[i] > 0 then
    begin
      var characters: Double := Min((Trunc(widths[i] + 0.5) + 2) / TUtility.cDigitPixels, cMaxColumnWidth);
      fStore.ApplyAxis(False, aRange.fLeft + i, aRange.fLeft + i, AxisChange([axSize, axHidden, axFitted], characters, False));
    end;
end;

function TWorksheet.MergedAt(aRow, aColumn: integer; out aArea: TArea): boolean;
begin
  Result := fStore.AreaAt(akMerge, aRow, aColumn, aArea);
end;

// in a merged area, not its top-left cell: Excel shows nothing of it
function TWorksheet.IsCovered(aRow, aColumn: integer): boolean;
begin
  var area: TArea;
  Result := MergedAt(aRow, aColumn, area) and ((aRow <> area.Top) or (aColumn <> area.Left));
end;

// False: covered (IsCovered), a warning added
function TWorksheet.Uncovered(aRow, aColumn: integer): boolean;
begin
  var area: TArea;
  Result := not IsCovered(aRow, aColumn);
  if not Result then
  begin
    MergedAt(aRow, aColumn, area);
    fWorkbook.fIssues.Add(TIssueSeverity.isWarning, 'Merged', fName + '!' + TUtility.CellName(aRow, aColumn),
      'covered by the merged area ' + area.Address + ', which shows only ' + TUtility.CellName(area.Top, area.Left) +
      ' - not written');
  end;
end;

// the range grown over the merged areas it touches, as Excel's selection grows
function TWorksheet.WithMerges(const aRange: TRange): TArea;
begin
  Result := aRange.Area;
  var grown: boolean := True;
  while grown do
  begin
    grown := False;
    for var area: TArea in fStore.Areas(akMerge) do
      if area.Overlaps(Result) and not Result.Contains(area) then
      begin
        Result := TArea.Make(Min(Result.Top, area.Top), Min(Result.Left, area.Left), Max(Result.Bottom, area.Bottom),
          Max(Result.Right, area.Right));
        grown := True;
      end;
  end;
end;

procedure TWorksheet.Merge(const aRange: TRange);
begin
  if (aRange.fTop = aRange.fBottom) and (aRange.fLeft = aRange.fRight) then
    Exit;
  var area: TArea := WithMerges(aRange);
  var why: string := '';
  for var fixed: TArea in fStore.Areas(akArray) do
    if fixed.Overlaps(area) then
      why := 'an array formula (' + fixed.Address + '), which Excel changes only as a whole';
  for var fixed: TArea in fStore.Areas(akDataTable) do
    if fixed.Overlaps(area) then
      why := 'a data table, which Excel''s what-if analysis fills';
  for var fixed: TArea in fStore.Areas(akTable) do
    if fixed.Overlaps(area) then
      why := 'a table, where Excel merges no cells';
  for var fixed: TArea in fStore.Areas(akPivot) do
    if fixed.Overlaps(area) then
      why := 'a pivot table, which Excel builds again';
  if why <> '' then
  begin
    fWorkbook.fIssues.Add(TIssueSeverity.isError, 'Merge', fName + '!' + area.Address, 'over ' + why + ' - not merged');
    Exit;
  end;
  // the merged areas met become part of this one
  fStore.RemoveMerges(area);
  // the first value read row by row goes to the top-left cell, as Excel keeps it
  var first: TCellCT := fStore.FirstValue(area);
  if (first <> nil) and (string(first.R) <> TUtility.CellName(area.Top, area.Left)) then
  begin
    var at: TArea;
    TArea.TryParse(first.R, at);
    var text: string;
    var value: Variant;
    if first.IsPresent('F') then
    begin
      if fStore.FormulaText(at.Top, at.Left, text) then
        WriteFormula(area.Top, area.Left, text, MakeRange(area));
    end
    else if first.IsPresent('Is') then
    begin
      fStore.ValueAt(at.Top, at.Left, value);
      WriteText(area.Top, area.Left, VarToStr(value), MakeRange(area));
    end
    else if CanWrite(area.Top, area.Left, MakeRange(area)) then
      fStore.MoveValue(first, area.Top, area.Left);
  end;
  if area.Right > area.Left then
    ClearContents(MakeRange(area.Top, area.Left + 1, area.Top, area.Right));
  if area.Bottom > area.Top then
    ClearContents(MakeRange(area.Top + 1, area.Left, area.Bottom, area.Right));
  // every cell takes the top-left cell's format
  var style: cardinal := fStore.EffectiveStyle(area.Top, area.Left);
  fStore.SetStyles(area,
    function(aStyle: cardinal): cardinal
    begin
      Result := style;
    end, False);
  fStore.AddMerge(area);
end;

procedure TWorksheet.UnMerge(const aRange: TRange);
begin
  fStore.RemoveMerges(aRange.Area);
end;

function TWorksheet.GetVisible: TSheetVisibility;
begin
  var index: integer := fWorkbook.fBook.SheetIndex(fName);
  if index < 0 then
    Exit(svVisible);
  Result := fWorkbook.fBook.SheetStates[index];
end;

procedure TWorksheet.SetVisible(aValue: TSheetVisibility);
begin
  if aValue = GetVisible then
    Exit;
  var book: TXlsxBook := fWorkbook.fBook;
  var index: integer := book.SheetIndex(fName);
  if index < 0 then
    Exit;
  var states: TArray<TSheetVisibility> := book.SheetStates;
  var visible: integer := 0;
  for var i := 0 to High(states) do
    if (i <> index) and (states[i] = svVisible) then
      Inc(visible);
  if (aValue <> svVisible) and (visible = 0) then
    raise EInvalidOpException.CreateFmt('%s is the last visible sheet: Excel keeps one at least', [fName]);
  book.SetSheetState(fName, aValue);
  if aValue = svVisible then
    Exit;
  // the active sheet hidden: the next visible one (else the one before) active, as Excel does, its tab the one selected
  var active: integer := -1;
  for var i := index + 1 to High(states) do
    if (active < 0) and (states[i] = svVisible) then
      active := i;
  for var i := index - 1 downto 0 do
    if (active < 0) and (states[i] = svVisible) then
      active := i;
  if book.MoveActiveSheet(index, active) then
    for var sheet: TWorksheet in fWorkbook.fSheets do
    begin
      var tab: integer := book.SheetIndex(sheet.fName);
      if (tab = index) or (tab = active) then
        sheet.fStore.SetTabSelected(tab = active);
    end;
end;

function TWorksheet.GetFreezePanes: string;
begin
  Result := fStore.FrozenAt;
end;

procedure TWorksheet.SetFreezePanes(const aValue: string);
begin
  var row: integer := 1;
  var column: integer := 1;
  if aValue <> '' then
  begin
    var at: TArea;
    if not TArea.TryParse(aValue, at) or (at.Top <> at.Bottom) or (at.Left <> at.Right) then
      raise EArgumentException.CreateFmt('FreezePanes takes a cell: "%s"', [aValue]);
    row := at.Top;
    column := at.Left;
  end;
  var why: string := fStore.PanesBlocker(not fFresh);
  if why <> '' then
    fWorkbook.fIssues.Add(TIssueSeverity.isError, 'FreezePanes', fName, why + ' - not changed')
  else
    fStore.Freeze(row, column);
end;

// the workbook's worksheets for a walk, aMine aSheet's
function WalkOf(aSheet: TWorksheet; out aMine: TXlsxWalkSheet): TXlsxWalk;
begin
  Result := TXlsxWalk.Create(aSheet.fWorkbook.fBook);
  aMine := nil;
  for var sheet: TWorksheet in aSheet.fWorkbook.fSheets do
    if sheet = aSheet then
      aMine := Result.Add(sheet.fName, sheet.fStore)
    else
      Result.Add(sheet.fName, sheet.fStore);
end;

// Excel's Insert and Delete of aMap's rows or columns: the backend's walk
procedure TWorksheet.Shift(const aMap: TReferenceMap);
begin
  var mine: TXlsxWalkSheet;
  var walk: TXlsxWalk := WalkOf(Self, mine);
  try
    mine.Shift(aMap);
  finally
    walk.Free;
  end;
end;

procedure TWorksheet.WriteNumber(aRow, aColumn: integer; aValue: Double; const aTarget: TRange);
begin
  if IsNan(aValue) or IsInfinite(aValue) then
    Refuse(aRow, aColumn, 'Value', 'Excel holds no NaN or infinity')
  else if Uncovered(aRow, aColumn) and CanWrite(aRow, aColumn, aTarget) then
    fStore.PutNumber(aRow, aColumn, aValue);
end;

procedure TWorksheet.WriteDate(aRow, aColumn: integer; aValue: TDateTime; const aTarget: TRange);
begin
  var serial: Double;
  if not TUtility.DateToSerial(aValue, fWorkbook.fBook.Date1904, serial) then
  begin
    Refuse(aRow, aColumn, 'Value', 'a date before the first one Excel has (' + DateToISO8601(aValue) + ')');
    Exit;
  end;
  if not Uncovered(aRow, aColumn) or not CanWrite(aRow, aColumn, aTarget) then
    Exit;
  var style: integer := fStore.EffectiveStyle(aRow, aColumn);
  if not fWorkbook.fBook.IsDateStyle(style) then
  begin
    var numberFormat: integer := cTimeFormat;
    if serial >= 1 then
      numberFormat := fWorkbook.fBook.FormatId(fWorkbook.fDateFormats[Ord(Frac(serial) <> 0)]);
    if numberFormat >= 0 then
      style := fWorkbook.fBook.DateStyle(style, numberFormat)
    else
      style := -1;
    if style < 0 then
    begin
      Refuse(aRow, aColumn, 'NoStyles', 'a date needs a date format, and the workbook has no styles to add one to');
      Exit;
    end;
  end;
  fStore.PutSerial(aRow, aColumn, serial, style);
end;

procedure TWorksheet.WriteText(aRow, aColumn: integer; const aValue: string; const aTarget: TRange);
begin
  if aValue.Length > TUtility.cMaxText then
    Refuse(aRow, aColumn, 'Value', Format('%d characters, Excel''s cells hold up to %d', [aValue.Length, TUtility.cMaxText]))
  else if Uncovered(aRow, aColumn) and CanWrite(aRow, aColumn, aTarget) and not fStore.PutText(aRow, aColumn, aValue) then
    Refuse(aRow, aColumn, 'NoSharedStrings', 'the workbook has no shared strings and no content types to add them to');
end;

procedure TWorksheet.WriteBoolean(aRow, aColumn: integer; aValue: boolean; const aTarget: TRange);
begin
  if Uncovered(aRow, aColumn) and CanWrite(aRow, aColumn, aTarget) then
    fStore.PutBoolean(aRow, aColumn, aValue);
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
  if Uncovered(aRow, aColumn) and CanWrite(aRow, aColumn, aTarget) then
    fStore.PutFormula(aRow, aColumn, aText);
end;

// the range as one array formula, written whole or not at all: its first cell holds it, Excel fills the others when it
// calculates
procedure TWorksheet.WriteArray(const aRange: TRange; const aFormula: string);
begin
  var text: string;
  if not CheckFormula(aRange.fTop, aRange.fLeft, aFormula, text) then
    Exit;
  var why: string := '';
  for var area: TArea in fStore.Areas(akArray) do
    if area.Overlaps(aRange.Area) and not aRange.Area.Contains(area) then
      why := 'part of an array formula (' + area.Address + '), which Excel changes only as a whole';
  for var area: TArea in fStore.Areas(akDataTable) do
    if area.Overlaps(aRange.Area) then
      why := 'a data table, which Excel''s what-if analysis fills';
  for var area: TArea in fStore.Areas(akTableRow) do
    if area.Overlaps(aRange.Area) then
      why := 'a table''s header or totals row (part of the table''s definition, which Calcite does not change yet)';
  if (aRange.RowCount > 1) or (aRange.ColumnCount > 1) then
    for var area: TArea in fStore.Areas(akTable) do
      if area.Overlaps(aRange.Area) then
        why := 'a table, where Excel allows no array formula of several cells';
  for var area: TArea in fStore.Areas(akPivot) do
    if area.Overlaps(aRange.Area) then
      why := 'a pivot table, which Excel builds again';
  for var area: TArea in fStore.Areas(akMerge) do
    if area.Overlaps(aRange.Area) then
      why := 'merged cells (' + area.Address + '), where Excel allows no array formula';
  if why <> '' then
  begin
    Refuse(aRange.fTop, aRange.fLeft, 'Formula', 'an array formula over ' + why);
    Exit;
  end;
  ClearContents(aRange);
  if CanWrite(aRange.fTop, aRange.fLeft, aRange) then
    fStore.PutArray(aRange.Area, text);
end;

procedure TWorksheet.ClearContents(const aRange: TRange);
begin
  var target: TRange := aRange;
  // a covered cell whose merged area is not cleared whole keeps its value, as a write to it
  fStore.ClearValues(aRange.Area,
    function(aRow, aColumn: integer): boolean
    begin
      var area: TArea;
      Result := (not MergedAt(aRow, aColumn, area) or target.Area.Contains(area) or (aRow = area.Top) and (aColumn = area.Left))
        and CanWrite(aRow, aColumn, target);
    end);
end;

function TWorksheet.MakeRange(aTop, aLeft, aBottom, aRight: integer): TRange;
begin
  Result.fSheet := Self;
  Result.fTop := aTop;
  Result.fLeft := aLeft;
  Result.fBottom := aBottom;
  Result.fRight := aRight;
end;

function TWorksheet.MakeRange(const aArea: TArea): TRange;
begin
  Result := MakeRange(aArea.Top, aArea.Left, aArea.Bottom, aArea.Right);
end;

function TWorksheet.GetRange(const aAddress: string): TRange;
begin
  var area: TArea;
  if not TArea.TryParse(aAddress, area) then
    raise EArgumentException.CreateFmt('Not an address on a sheet: "%s"', [aAddress]);
  Result := MakeRange(area);
end;

function TWorksheet.GetCells(aRow, aColumn: integer): TRange;
begin
  if (aRow < 1) or (aRow > TUtility.cMaxRow) then
    raise EArgumentOutOfRangeException.CreateFmt('There is no row %d (1 to %d)', [aRow, TUtility.cMaxRow]);
  if (aColumn < 1) or (aColumn > TUtility.cMaxColumn) then
    raise EArgumentOutOfRangeException.CreateFmt('There is no column %d (1 to %d)', [aColumn, TUtility.cMaxColumn]);
  Result := MakeRange(aRow, aColumn, aRow, aColumn);
end;

function TWorksheet.GetCellsByLetters(aRow: integer; const aColumn: string): TRange;
begin
  var index: integer := 1;
  var column: integer := TUtility.ReadColumn(aColumn, index);
  if (column = 0) or (index <= aColumn.Length) then
    raise EArgumentException.CreateFmt('Not a column: "%s" (A to XFD)', [aColumn]);
  Result := GetCells(aRow, column);
end;

function TWorksheet.GetUsedRange: TRange;
begin
  Result := MakeRange(fStore.UsedRange);
end;

procedure TWorksheet.SetName(const aValue: string);
begin
  if aValue = fName then
    Exit;
  var why: string;
  if not fFresh then
    why := 'only a sheet made here is renamed: in a workbook opened, formulas and other parts may name it'
  else if fWorkbook.fBook.FormulasWritten then
    why := 'sheets are renamed before formulas are written: a formula may name the sheet'
  else
    why := fWorkbook.SheetNameError(aValue, Self);
  if not why.IsEmpty then
  begin
    fWorkbook.fIssues.Add(TIssueSeverity.isError, 'Rename', fName, why + ' - not renamed');
    Exit;
  end;
  fWorkbook.fBook.RenameSheet(fName, aValue);
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

function TWorksheets.GetEnumerator: TEnumerator;
begin
  Result.fList := fList;
  Result.fIndex := -1;
end;

{ TWorksheets.TEnumerator }

function TWorksheets.TEnumerator.GetCurrent: TWorksheet;
begin
  Result := fList[fIndex];
end;

function TWorksheets.TEnumerator.MoveNext: boolean;
begin
  Inc(fIndex);
  Result := fIndex < fList.Count;
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
  Result := fWorkbook.fBook.EditWorkbook;
end;

function TWorkbookXlsx.GetSharedStrings: TSstE;
begin
  Result := fWorkbook.fBook.EditSharedStrings;
end;

function TWorkbookXlsx.GetStyles: TStyleSheetE;
begin
  Result := fWorkbook.fBook.EditStyles;
end;

function TWorkbookXlsx.GetCoreProperties: TCorePropertiesE;
begin
  Result := fWorkbook.fBook.Package.Properties.Xml;
end;

{ TWorkbookProperties }

function TWorkbookProperties.GetText(aIndex: integer): string;
begin
  var core: TCoreProperties := fWorkbook.fBook.Package.Properties;
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
  var core: TCoreProperties := fWorkbook.fBook.Package.Properties;
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
    Result := fWorkbook.fBook.Package.Properties.Created
  else
    Result := fWorkbook.fBook.Package.Properties.Modified;
end;

procedure TWorkbookProperties.SetDate(aIndex: integer; aValue: TDateTime);
begin
  if aIndex = 0 then
    fWorkbook.fBook.Package.Properties.Created := aValue
  else
    fWorkbook.fBook.Package.Properties.Modified := aValue;
end;

{ TWorkbook }

constructor TWorkbook.CreateClosed;
begin
  inherited Create;
  fBook := TXlsxBook.Create;
  ForwardIssues;
  fSheets := TWorksheets.Create;
  fSheets.fWorkbook := Self;
  fXlsx := TWorkbookXlsx.Create;
  fXlsx.fWorkbook := Self;
  fProperties := TWorkbookProperties.Create;
  fProperties.fWorkbook := Self;
  fDateFormats[0] := nfShortDate;
  fDateFormats[1] := nfShortDateTime;
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
  fBook.Free;
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
  fBook.Package.OnIssue :=
    procedure(const aIssue: TIssue)
    begin
      fIssues.Add(aIssue);
    end;
end;

// Excel's new workbook: Sheet1 and nothing in it
procedure TWorkbook.NewPackage;
begin
  fBook.New;
  Load;
  fSheets.fList[0].fFresh := True;
end;

function TWorkbook.Fail(const aCode, aError: string): boolean;
begin
  fError := aError;
  fIssues.Add(TIssueSeverity.isError, aCode, '', aError);
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
    if not opened.fBook.Open(aFileName, aStream) then
    begin
      fIssues := opened.fIssues; // the package's failure among them
      fError := opened.fBook.Package.Error;
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
  Swap<TXlsxBook>(fBook, aOther.fBook);
  Swap<TWorksheets>(fSheets, aOther.fSheets);
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

function TWorkbook.Load: boolean;
var
  sheets: TArray<TXlsxSheetEntry>;
begin
  var code, error: string;
  if not fBook.Load(sheets, code, error) then
    Exit(Fail(code, error));
  for var i := 0 to High(sheets) do
  begin
    var sheet: TWorksheet := TWorksheet.Create;
    fSheets.fList.Add(sheet);
    sheet.fWorkbook := Self;
    sheet.fName := sheets[i].Name;
    sheet.fStore := TXlsxSheet.Create(fBook, sheets[i].Part);
  end;
  Result := True;
end;

// Excel's rules as it opens a file: a sheet named against them makes it refuse the whole file, even repaired. '' - a good name
function TWorkbook.SheetNameError(const aName: string; aExcept: TWorksheet): string;
begin
  if aName.IsEmpty then
    Exit('a sheet''s name cannot be empty');
  if Length(aName) > TUtility.cMaxSheetName then
    Exit(Format('a sheet''s name has at most %d characters', [TUtility.cMaxSheetName]));
  for var c: char in aName do
    if CharInSet(c, ['[', ']', ':', '*', '?', '/', '\']) or (c < ' ') then
      Exit('a sheet''s name cannot have [ ] : * ? / \ or control characters');
  if aName.StartsWith('''') or aName.EndsWith('''') then
    Exit('a sheet''s name cannot start or end with ''');
  if AnsiSameText(aName, 'History') then
    Exit('History is reserved by Excel');
  // chart sheets too
  var except_: string := '';
  if aExcept <> nil then
    except_ := aExcept.fName;
  var taken: string := fBook.SheetNamed(aName, except_);
  if not taken.IsEmpty then
    Exit(Format('the workbook has a sheet "%s" already', [taken]));
  Result := '';
end;

function TWorkbook.AddSheet(const aName: string): TWorksheet;
begin
  var name: string := aName;
  var why: string := '';
  if not name.IsEmpty then
    why := SheetNameError(name, nil);
  if name.IsEmpty or not why.IsEmpty then
  begin
    var number: integer := fBook.SheetCount;
    repeat
      Inc(number);
      name := 'Sheet' + IntToStr(number);
    until SheetNameError(name, nil).IsEmpty;
  end;
  if not why.IsEmpty then
    fIssues.Add(TIssueSeverity.isError, 'SheetName', aName, why + ' - the sheet is added as ' + name);

  if not fBook.CanAddParts then
  begin
    fIssues.Add(TIssueSeverity.isError, 'NoContentTypes', '', 'The package has no content types: a sheet cannot be added');
    Exit(nil);
  end;
  var partName: string := fBook.AddSheet(name);
  if partName.IsEmpty then
    Exit(nil);

  Result := TWorksheet.Create;
  fSheets.fList.Add(Result);
  Result.fWorkbook := Self;
  Result.fName := name;
  Result.fStore := TXlsxSheet.Create(fBook, partName);
  Result.fFresh := True;
end;

// Excel's Delete of the sheet: the backend's walk
procedure TWorksheet.Delete;
begin
  var mine: TXlsxWalkSheet;
  var walk: TXlsxWalk := WalkOf(Self, mine);
  try
    mine.DeleteSheet;
  finally
    walk.Free;
  end;
  fWorkbook.fSheets.fList.Remove(Self);
end;

function TWorkbook.GetFileName: string;
begin
  Result := fBook.Package.FileName;
end;

function TWorkbook.GetDateFormat(aIndex: integer): string;
begin
  Result := fDateFormats[aIndex];
end;

procedure TWorkbook.SetDateFormat(aIndex: integer; const aValue: string);
begin
  var why: string := NumberFormatError(aValue);
  if (why = '') and not IsDateCode(aValue) then
    why := 'no date in it';
  if why <> '' then
    raise EArgumentException.CreateFmt('Not a date format Excel would open: "%s" (%s)', [aValue, why]);
  var local: string := LocalNotation(aValue);
  if local <> '' then
    fIssues.Add(TIssueSeverity.isWarning, 'NumberFormat', '', '"' + aValue + '": ' + local + ' - taken as it is');
  fDateFormats[aIndex] := aValue;
end;

// Excel opens a workbook only under the extension of its kind, and other formats' names would mislead
function TWorkbook.ExtensionError(const aFileName: string): string;
begin
  Result := '';
  var extension: string := ExtractFileExt(aFileName).ToLower;
  var kind: string := fBook.Kind;
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
  Result := fBook.Package.Save;
  fError := fBook.Package.Error;
end;

function TWorkbook.SaveAs(const aFileName: string): boolean;
begin
  var error: string := ExtensionError(aFileName);
  if not error.IsEmpty then
    Exit(Fail('Extension', error));
  Result := fBook.Package.SaveAs(aFileName);
  fError := fBook.Package.Error;
end;

function TWorkbook.SaveAs(aStream: TStream): boolean;
begin
  Result := fBook.Package.SaveAs(aStream);
  fError := fBook.Package.Error;
end;

end.
