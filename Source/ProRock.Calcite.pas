unit ProRock.Calcite;

// Excel workbooks (.xlsx): open, change and save with nothing lost

interface

uses System.SysUtils, System.Classes, System.Generics.Collections, System.UITypes,
  ProRock.Xmlite, ProRock.Office.Ooxml, ProRock.Xmlite.Schema.Ooxml.Sml, ProRock.Xmlite.Schema.CoreProperties,
  ProRock.Calcite.Utility, ProRock.Calcite.Aspects, ProRock.Calcite.Xlsx;

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

  {$REGION 'ProRock.Calcite.Aspects types aliases'}
  // Excel's names: XlUnderlineStyle, XlHAlign, XlVAlign, XlBordersIndex, XlLineStyle, XlBorderWeight
  TUnderline = ProRock.Calcite.Aspects.TUnderline;
  THAlign = ProRock.Calcite.Aspects.THAlign;
  TVAlign = ProRock.Calcite.Aspects.TVAlign;
  TBorderEdge = ProRock.Calcite.Aspects.TBorderEdge;
  TBorderEdges = ProRock.Calcite.Aspects.TBorderEdges;
  TLineStyle = ProRock.Calcite.Aspects.TLineStyle;
  TBorderWeight = ProRock.Calcite.Aspects.TBorderWeight;
  {$ENDREGION}

  // Excel's XlSheetVisibility: svVeryHidden is shown again only from code
  TSheetVisibility = (svVisible, svHidden, svVeryHidden);

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
  private type
    // a formula's cell through rows or columns inserted or deleted: where it is then, its text before and after (stored)
    TFormulaMove = record
      Cell: TCellCT;
      Row, Column: integer;
      Before, After: string;
    end;
    // a conditional format's formula (Rule, its Index) or data validation's (Validation, 1 or 2) changed the same way
    TTextMove = record
      Sheet: TWorksheet;
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
      constructor Create(aSheet: TWorksheet; aByRows: boolean);
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
    fWorkbook: TWorkbook;
    fXlsx: TWorksheetXlsx;
    fName: string;
    fPartName: string;
    fPrepared: boolean;
    // the part's objects as Objects last gave them, valid while the package and its Version are the same (Exchange swaps
    // packages between workbooks)
    fObjects: TWorksheetE;
    fObjectsPackage: TPackageOoxml;
    fObjectsVersion: cardinal;
    fObjectsEdited: boolean;
    // found on the first need: the areas of array formulas and data tables, shared formulas' first cells by si
    fArrays, fDataTables: TList<TArea>;
    fSpills: TList<TArea>; // those of fArrays that are dynamic arrays (Excel 365's, spilled)
    fShared: TDictionary<cardinal, TCellCT>;
    // found on the first write: the areas of tables, their header and totals rows, pivot tables
    fTables, fTableRows, fPivots: TList<TArea>;
    fMerges: TList<TArea>; // the merged areas, found on the first need, again after a change
    fLockedWritten: boolean; // reported once a sheet
    fFresh: boolean; // made here, a new workbook's or added: nothing outside Calcite can name it yet
    // while rows or columns are inserted or deleted: the tables (Sales) and table columns (Sales[Q1]) going, each table's
    // area and data rows (pairs)
    fGone: TArray<string>;
    fBodies: TArray<TArea>;

    function GetXlsx: TWorksheetXlsx;
    function Objects(aEdit: boolean): TWorksheetE;
    function FindRow(aSheet: TWorksheetE; aRow: integer; out aIndex: integer): boolean;
    function FindCell(aRow, aColumn: integer): TCellCT;
    function EffectiveStyle(aRow, aColumn: integer): cardinal;
    function FormatAt(aRow, aColumn: integer): TCellFormat;
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
    function MakeRange(aTop, aLeft, aBottom, aRight: integer): TRange; overload;
    function MakeRange(const aArea: TArea): TRange; overload;
    function GetRange(const aAddress: string): TRange;
    function GetCells(aRow, aColumn: integer): TRange;
    function GetCellsByLetters(aRow: integer; const aColumn: string): TRange;
    function GetUsedRange: TRange;
    function GetColumns: TRangeColumns;
    function GetRows: TRangeRows;
    procedure SetName(const aValue: string);
    function CellForStyle(aRow, aColumn: integer): TCellCT;
    procedure ApplyStyle(const aRange: TRange; const aChange: TFormatChange; aExisting: boolean = False);
    procedure SetStyles(const aRange: TRange; const aNewStyle: TFunc<cardinal, cardinal>; aExisting: boolean);
    function FindMerges: TList<TArea>;
    function MergedAt(aRow, aColumn: integer; out aArea: TArea): boolean;
    function IsCovered(aRow, aColumn: integer): boolean;
    function Uncovered(aRow, aColumn: integer): boolean;
    function WithMerges(const aRange: TRange): TArea;
    procedure Merge(const aRange: TRange);
    procedure UnMerge(const aRange: TRange);
    function RowEntries(aTop, aBottom: integer): TArray<TRowCT>;
    function SheetEntry: TSheetCT;
    function GetVisible: TSheetVisibility;
    procedure SetVisible(aValue: TSheetVisibility);
    procedure ApplyBorders(const aRange: TRange; aEdges: TBorderEdges; const aChange: TFormatChange);
    function BorderSide(aRow, aColumn: integer; aEdge: TCellSide): TBorderLine;
    function AxisDefault(aByRows: boolean): TAxisFormat;
    function AxisOf(aByRows: boolean; aIndex: integer): TAxisFormat;
    function AxisEntries(aByRows: boolean): TArray<TPair<integer, TAxisFormat>>;
    procedure ApplyAxis(aByRows: boolean; aFirst, aLast: integer; const aChange: TAxisChange);
    function SortedColumns: TColCTList;
    function ColumnStyle(aColumn: integer): cardinal;
    function ColumnEntries(aLeft, aRight: integer): TArray<TColCT>;
    function ColumnEntry(aColumn: integer): TColCT;
    procedure AutoFit(const aRange: TRange);
    function GetFreezePanes: string;
    procedure SetFreezePanes(const aValue: string);
    function ShiftBlocker(aByRows: boolean; aFirst, aCount: integer): string;
    function TablesBlocker(aByRows: boolean; aFirst, aCount: integer): string;
    function PivotsBlocker(aByRows: boolean; aFirst, aCount: integer): string;
    procedure KeepTableRows(var aFirst, aCount: integer; aCleared: TList<TArea>);
    procedure PlanTables(aByRows: boolean; aFirst, aCount: integer);
    procedure ShiftTables(aByRows: boolean; aFirst, aCount: integer);
    procedure ShiftPivots(aByRows: boolean; aFirst, aCount: integer);
    function PlanDrawings(aByRows: boolean; out aWhy: string): TList<TAnchorMove>;
    procedure ShiftDrawings(aMoves: TList<TAnchorMove>; aByRows: boolean; aFirst, aCount: integer);
    procedure ShiftCharts(aMoves: TList<TChartMove>; aByRows: boolean; aFirst, aCount: integer);
    procedure NotesParts(out aComments, aDrawing: string);
    function NotesBlocker(aByRows: boolean; aFirst, aCount: integer): string;
    procedure ShiftNotes(aByRows: boolean; aFirst, aCount: integer);
    function CopiedRow(aSource: TRowCT; aNumber: integer): TRowCT;
    procedure ShowRows(aTop, aBottom: integer);
    procedure ShiftColumnEntries(aFirst, aCount: integer);
    procedure ShiftCells(aByRows: boolean; aFirst, aCount: integer);
    function LiftSpills(aByRows: boolean; aFirst, aCount: integer): TArray<TSpill>;
    procedure PlaceSpills(const aSpills: TArray<TSpill>; aByRows: boolean; aFirst, aCount: integer);
    procedure FitAgain(aByRows: boolean; aFirst, aCount: integer);
    procedure ShiftLists(aByRows: boolean; aFirst, aCount: integer);
    procedure ApplyFormulas(aMoves: TList<TFormulaMove>; aRefs: TDictionary<cardinal, string>; aShifted: boolean;
      aByRows: boolean; aFirst, aCount: integer);
    procedure FoldSpills(aMoves: TList<TFormulaMove>);
    procedure Shift(aByRows: boolean; aFirst, aCount: integer);
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
    procedure FixedAreas(const aSheetPart: string; aTables, aTableRows, aPivots: TList<TArea>);
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
  System.RegularExpressions, ProRock.Calcite.Formulas, ProRock.Calcite.Formats,
  ProRock.Xmlite.Schema.Ooxml.DmlMain, ProRock.Xmlite.Schema.Ooxml.DmlSheet, ProRock.Xmlite.Schema.Ooxml.DmlChart,
  ProRock.Xmlite.Schema.Ooxml.Vml, ProRock.Xmlite.Schema.Ooxml.VmlExcel;

type
  {$REGION 'ProRock.Xmlite.Schema.Ooxml types aliases'}
  // DrawingML, its charts and VML have ones of these names too
  TColorCT = ProRock.Xmlite.Schema.Ooxml.Sml.TColorCT;
  TFillCT = ProRock.Xmlite.Schema.Ooxml.Sml.TFillCT;
  TNumFmtCT = ProRock.Xmlite.Schema.Ooxml.Sml.TNumFmtCT;
  TMarkerCT = ProRock.Xmlite.Schema.Ooxml.DmlSheet.TMarkerCT;
  TExtensionCT = ProRock.Xmlite.Schema.Ooxml.DmlChart.TExtensionCT;
  {$ENDREGION}

const

  // Excel's number format a time of day gets: h:mm:ss
  cTimeFormat = 21;

{$REGION 'xlsx storage: text, built-in formats, date styles, widths, data tables'}

const
  // the default font's digit (Calibri or Aptos Narrow 11) in pixels: the unit of Excel's column widths
  cDigitPixels = 7;
  cMaxColumnWidth = 255;
  // in points: a sheet's rows without a height of their own and no default in the file, Excel's largest
  cDefaultRowHeight = 15;
  cMaxRowHeight = 409.5;

// Excel's ColumnWidth (characters) in pixels on the screen, and as a file stores it, and back: whole pixels, 5 of them
// padding
function WidthPixels(aCharacters: Double): integer;
begin
  if aCharacters <= 0 then
    Exit(0);
  Result := Trunc(aCharacters * cDigitPixels + 0.5) + 5;
end;

function WidthToFile(aCharacters: Double): Double;
begin
  Result := Trunc(WidthPixels(aCharacters) / cDigitPixels * 256) / 256;
end;

function FileToWidth(aWidth: Double): Double;
begin
  var pixels: integer := Trunc(aWidth * cDigitPixels + 0.5) - 5;
  if pixels <= 0 then
    Exit(0);
  Result := Trunc(pixels / cDigitPixels * 100 + 0.5) / 100;
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

function AreaAt(aAreas: TList<TArea>; aRow, aColumn: integer; out aArea: TArea): boolean;
begin
  for var area: TArea in aAreas do
    if area.Holds(aRow, aColumn) then
    begin
      aArea := area;
      Exit(True);
    end;
  Result := False;
end;

{$ENDREGION}

{$REGION 'xlsx storage: fonts, fills, borders, colors'}

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

{$REGION 'Ranges: rows and columns inserted and deleted'}

// rows or columns inserted (aCount > 0) at aFirst or deleted (aCount < 0) from it, as Excel moves a span of them: one
// inserted inside grows (aGrowAfter: right after it too, as a format carries on), a delete shrinks it, the whole sheet's
// stays and one reaching the last row or column keeps reaching it; False when nothing is left
function ShiftedSpan(var aLow, aHigh: integer; aFirst, aCount, aLimit: integer; aGrowAfter: boolean): boolean;
begin
  if aCount > 0 then
  begin
    if (aLow = 1) and (aHigh = aLimit) then
      Exit(True);
    if aFirst <= aLow then
    begin
      Inc(aLow, aCount);
      Inc(aHigh, aCount);
    end
    else if (aFirst <= aHigh) or aGrowAfter and (aFirst = aHigh + 1) then
      Inc(aHigh, aCount);
    aHigh := Min(aHigh, aLimit);
    Exit(aLow <= aLimit);
  end;
  var last: integer := aFirst - aCount - 1;
  if last < aLow then
  begin
    Inc(aLow, aCount);
    Inc(aHigh, aCount);
  end
  else if aFirst <= aHigh then
  begin
    var toEnd: boolean := aHigh = aLimit;
    var left: integer := aHigh - aLow + 1 - (Min(last, aHigh) - Max(aFirst, aLow) + 1);
    if left = 0 then
      Exit(False);
    aLow := Min(aLow, aFirst);
    aHigh := aLow + left - 1;
    if toEnd then
      aHigh := aLimit;
  end;
  Result := True;
end;

// a row or column number the same way: 0 when deleted or pushed off the sheet
function ShiftedIndex(aIndex, aFirst, aCount, aLimit: integer): integer;
begin
  Result := aIndex;
  if aIndex < aFirst then
    Exit;
  if aCount < 0 then
  begin
    if aIndex < aFirst - aCount then
      Exit(0);
  end
  else if aIndex + aCount > aLimit then
    Exit(0);
  Result := aIndex + aCount;
end;

function ShiftedArea(var aArea: TArea; aByRows: boolean; aFirst, aCount: integer; aGrowAfter: boolean): boolean;
begin
  if aByRows then
    Result := ShiftedSpan(aArea.Top, aArea.Bottom, aFirst, aCount, TUtility.cMaxRow, aGrowAfter)
  else
    Result := ShiftedSpan(aArea.Left, aArea.Right, aFirst, aCount, TUtility.cMaxColumn, aGrowAfter);
end;

// a list of areas (A1:B5 D7) the same way, those gone dropped: '' when none is left
function ShiftedSqref(const aSqref: string; aByRows: boolean; aFirst, aCount: integer; aGrowAfter: boolean): string;
begin
  Result := '';
  for var item: string in aSqref.Split([' '], TStringSplitOptions.ExcludeEmpty) do
  begin
    var area: TArea;
    var text: string := item;
    if TArea.TryParse(item, area) then
      if ShiftedArea(area, aByRows, aFirst, aCount, aGrowAfter) then
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

function HasValue(aCell: TCellCT): boolean;
begin
  Result := aCell.Present[@aCell.V] or aCell.IsPresent('F') or aCell.IsPresent('Is');
end;

// the <col> entry across aAt split there: ...aAt-1 and aAt...
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
        fSheet.WriteValue(row, column, TUtility.ArrayItem(aValue, row - fTop, column - fLeft), Self)
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
  case fSheet.CellValue(fSheet.FindCell(fTop, fLeft), value) of
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
  fSheet.ClearContents(fSheet.MakeRange(fSheet.WithMerges(Self)));
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
      if not fSheet.FormulaText(row, column, text) then
        Exit(False);
    end;
  Result := True;
end;

function TRange.GetHasArray: boolean;
begin
  fSheet.FindFormulas;
  var area: TArea;
  Result := AreaAt(fSheet.fArrays, fTop, fLeft, area);
end;

function TRange.GetCurrentArray: TRange;
begin
  fSheet.FindFormulas;
  var area: TArea;
  if not AreaAt(fSheet.fArrays, fTop, fLeft, area) then
    raise EInvalidOpException.CreateFmt('%s!%s is not in an array formula', [fSheet.Name, TUtility.CellName(fTop, fLeft)]);
  Result := fSheet.MakeRange(area);
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
  axis := fSheet.AxisOf(False, fLeft);
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
  fSheet.ApplyAxis(False, fLeft, fRight, AxisChange([axSize, axHidden], aValue, aValue = 0));
end;

function TRange.GetRowHeight: Double;
var
  axis: TAxisFormat;
begin
  axis := fSheet.AxisOf(True, fTop);
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
    fSheet.ApplyAxis(True, fTop, fBottom, AxisChange([axHidden], 0, True))
  else
    fSheet.ApplyAxis(True, fTop, fBottom, AxisChange([axSize, axHidden], aValue, False));
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
  axis := fSheet.AxisOf(byRows, first);
  Result := axis.Hidden or (axis.Size = 0);
end;

procedure TRange.SetHidden(aValue: boolean);
begin
  var byRows: boolean;
  var first, last: integer;
  HiddenAxis(byRows, first, last);
  fSheet.ApplyAxis(byRows, first, last, AxisChange([axHidden], 0, aValue));
  if not aValue then
    for var index := first to last do
      if fSheet.AxisOf(byRows, index).Size = 0 then // hidden by a size of 0: shown at the default one
        fSheet.ApplyAxis(byRows, index, index, AxisChange([axDefaultSize]));
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
    fSheet.Shift(True, fTop, RowCount)
  else if (fTop = 1) and (fBottom = TUtility.cMaxRow) then
    fSheet.Shift(False, fLeft, ColumnCount)
  else
    raise EInvalidOpException.CreateFmt('Insert takes whole rows or columns, not %s: Range[''%s''].EntireRow.Insert',
      [Address, Address]);
end;

procedure TRange.Delete;
begin
  if (fLeft = 1) and (fRight = TUtility.cMaxColumn) then
    fSheet.Shift(True, fTop, -RowCount)
  else if (fTop = 1) and (fBottom = TUtility.cMaxRow) then
    fSheet.Shift(False, fLeft, -ColumnCount)
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
  fSheet.ApplyAxis(True, fTop, fBottom, AxisChange([axDefaultSize]));
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
  fMerges.Free;
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
  var package: TPackageOoxml := fWorkbook.fBook.Package;
  if (fObjects <> nil) and (fObjectsPackage = package) and (fObjectsVersion = package.Version) and
    (fObjectsEdited or not aEdit) then
    Exit(fObjects); // asked for several times a cell: no lookup in the package
  if aEdit then
    Result := package.EditPart<TWorksheetE>(fPartName)
  else
    Result := package.Part<TWorksheetE>(fPartName);
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

function TWorksheet.FormatAt(aRow, aColumn: integer): TCellFormat;
begin
  Result := fWorkbook.fBook.FormatOf(EffectiveStyle(aRow, aColumn));
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
        aValue := fWorkbook.fBook.SharedString(StrToIntDef(aCell.V, -1));
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
    if fWorkbook.fBook.IsDateStyle(aCell.S) then
    begin
      aValue := VarFromDateTime(TUtility.SerialToDate(number, fWorkbook.fBook.Date1904));
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
  fWorkbook.fIssues.Add(TIssueSeverity.isError, aCode, fName + '!' + TUtility.CellName(aRow, aColumn), aWhy + ' - not written');
end;

// on a protected sheet, a cell its style does not unlock
function TWorksheet.IsLocked(aRow, aColumn: integer): boolean;
begin
  var sheet: TWorksheetE := Objects(False);
  Result := sheet.IsPresent('SheetProtection') and sheet.SheetProtection.Sheet and
    fWorkbook.fBook.IsLockedStyle(EffectiveStyle(aRow, aColumn));
end;

// the areas of array formulas and data tables, shared formulas' first cells: found once, again after one of them changes
procedure TWorksheet.FindFormulas;
begin
  if fArrays <> nil then
    Exit;
  fArrays := TList<TArea>.Create;
  fDataTables := TList<TArea>.Create;
  fSpills := TList<TArea>.Create;
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
          var area: TArea;
          if not TArea.TryParse(cell.F.Ref, area) then
            TArea.TryParse(cell.R, area);
          if cell.F.T = stcftArray then
          begin
            fArrays.Add(area);
            if (cell.Cm > 0) and fWorkbook.fBook.IsDynamicArray(cell.Cm) then
              fSpills.Add(area);
          end
          else
            fDataTables.Add(area);
        end;
end;

procedure TWorksheet.ForgetFormulas;
begin
  FreeAndNil(fArrays);
  FreeAndNil(fDataTables);
  FreeAndNil(fSpills);
  FreeAndNil(fShared);
end;

// tables (their header and totals rows apart) and pivot tables, from their own parts: found on the first write
procedure TWorksheet.FindFixedAreas;
begin
  if fTables <> nil then
    Exit;
  fTables := TList<TArea>.Create;
  fTableRows := TList<TArea>.Create;
  fPivots := TList<TArea>.Create;
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
    FindFormulas;
    var area: TArea;
    if (AreaAt(fArrays, aRow, aColumn, area) or AreaAt(fDataTables, aRow, aColumn, area)) and
      ((area.Top <> aRow) or (area.Left <> aColumn)) then
      FormulaText(area.Top, area.Left, aText);
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

// a shared formula's cells as plain ones, each its own text (the values Excel calculated stay); False: its text unreadable
function TWorksheet.Unshare(aIndex: cardinal): boolean;
begin
  FindFormulas;
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
  fWorkbook.fBook.FormulaChanged;
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
  var area: TArea;
  aCode := 'Formula';
  if AreaAt(fArrays, aRow, aColumn, area) and not aTarget.Area.Contains(area) then
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
    fWorkbook.fIssues.Add(TIssueSeverity.isWarning, 'Locked', fName + '!' + TUtility.CellName(aRow, aColumn),
      'a locked cell of a protected sheet, written: Excel lets its users change it only unprotected (reported once a sheet)');
  end;
  Result := True;
end;

// the cell, created where Excel expects it, with its value removed
function TWorksheet.CellForWriting(aRow, aColumn: integer): TCellCT;
begin
  Result := CellForStyle(aRow, aColumn);
  RemoveValue(Result);
  fWorkbook.fBook.ValueChanged;
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
    SetStyles(aRange, newStyle, aExisting);
    if failed then
      fWorkbook.fIssues.Add(TIssueSeverity.isError, 'NoStyles', fName + '!' + aRange.Address,
        'the workbook has no styles to change - not written');
  finally
    changed.Free;
  end;
end;

// each cell of the range given aNewStyle of its style; whole columns and rows as ApplyStyle says
procedure TWorksheet.SetStyles(const aRange: TRange; const aNewStyle: TFunc<cardinal, cardinal>; aExisting: boolean);
begin
  var sheet: TWorksheetE := Objects(True);
  var wholeColumns: boolean := (aRange.fTop = 1) and (aRange.fBottom = TUtility.cMaxRow);
  var wholeRows: boolean := (aRange.fLeft = 1) and (aRange.fRight = TUtility.cMaxColumn);
  if wholeColumns or wholeRows or aExisting then
  begin
    if aExisting then
      // the cells there already, below
    else if wholeColumns then
      for var column: TColCT in ColumnEntries(aRange.fLeft, aRange.fRight) do
      begin
        column.Style := aNewStyle(column.Style);
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
          row.S := aNewStyle(row.S)
        else
          row.S := aNewStyle(0);
        row.CustomFormat := True;
      end;
    // the cells there already
    var rowIndex: integer;
    FindRow(sheet, aRange.fTop, rowIndex);
    var rows: TRowCTList := sheet.SheetData.Row;
    while (rowIndex < rows.Count) and (rows[rowIndex].R <= cardinal(aRange.fBottom)) do
    begin
      var row: TRowCT := rows[rowIndex];
      if wholeColumns and wholeRows and row.CustomFormat and not aExisting then
        row.S := aNewStyle(row.S); // the whole sheet: a formatted row's empty cells too
      var cellIndex: integer;
      FindInRow(row, aRange.fLeft, cellIndex);
      while (cellIndex < row.C.Count) and (TUtility.ColumnOf(row.C[cellIndex].R) <= aRange.fRight) do
      begin
        row.C[cellIndex].S := aNewStyle(row.C[cellIndex].S);
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
        cell.S := aNewStyle(cell.S);
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

{$REGION 'the axis table: rows and columns as Excel reads and writes them'}

// rows or columns without an entry of their own: Excel's 15 points or 8.43 characters unless the sheet says; the rows
// hidden when the sheet hides those it does not list
function TWorksheet.AxisDefault(aByRows: boolean): TAxisFormat;
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
    var pixels: integer := (base * cDigitPixels + 5 + 7) div 8 * 8;
    Result.Size := Trunc((pixels - 5) / cDigitPixels * 100 + 0.5) / 100;
  end;
end;

function TWorksheet.AxisOf(aByRows: boolean; aIndex: integer): TAxisFormat;
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
function TWorksheet.AxisEntries(aByRows: boolean): TArray<TPair<integer, TAxisFormat>>;
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
procedure TWorksheet.ApplyAxis(aByRows: boolean; aFirst, aLast: integer; const aChange: TAxisChange);
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

// the column's <col>, nil when it has none
function TWorksheet.ColumnEntry(aColumn: integer): TColCT;
begin
  for var columns: TColsCT in Objects(False).Cols do
    for var column: TColCT in columns.Col do
      if (cardinal(aColumn) >= column.Min) and (cardinal(aColumn) <= column.Max) then
        Exit(column);
  Result := nil;
end;

function TWorksheet.ColumnStyle(aColumn: integer): cardinal;
begin
  var column: TColCT := ColumnEntry(aColumn);
  if column = nil then
    Result := 0
  else
    Result := column.Style;
end;

// the <col> entries in one <cols> sorted, as Excel writes them (a <cols> added when there is none)
function TWorksheet.SortedColumns: TColCTList;
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
function TWorksheet.ColumnEntries(aLeft, aRight: integer): TArray<TColCT>;
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

// Excel's AutoFit estimated: the widest shown value of each column in the range's rows, with Excel's 2 pixels of margin
// (numbers and dates a digit more)
procedure TWorksheet.AutoFit(const aRange: TRange);
begin
  var sheet: TWorksheetE := Objects(False);
  var widths: TArray<Double>;
  SetLength(widths, aRange.fRight - aRange.fLeft + 1);
  var rows: TRowCTList := sheet.SheetData.Row;
  var rowIndex: integer;
  FindRow(sheet, aRange.fTop, rowIndex);
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
              var code: string := format.NumberFormat;
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
      var characters: Double := Min((Trunc(widths[i] + 0.5) + 2) / cDigitPixels, cMaxColumnWidth);
      ApplyAxis(False, aRange.fLeft + i, aRange.fLeft + i, AxisChange([axSize, axHidden, axFitted], characters, False));
    end;
end;

// the <row> entries of aTop..aBottom, made where missing
function TWorksheet.RowEntries(aTop, aBottom: integer): TArray<TRowCT>;
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

function TWorksheet.FindMerges: TList<TArea>;
begin
  if fMerges = nil then
  begin
    fMerges := TList<TArea>.Create;
    var sheet: TWorksheetE := Objects(False);
    if sheet.IsPresent('MergeCells') then
      for var merged: TMergeCellCT in sheet.MergeCells.MergeCell do
      begin
        var area: TArea;
        if TArea.TryParse(merged.Ref, area) then
          fMerges.Add(area);
      end;
  end;
  Result := fMerges;
end;

function TWorksheet.MergedAt(aRow, aColumn: integer; out aArea: TArea): boolean;
begin
  Result := AreaAt(FindMerges, aRow, aColumn, aArea);
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
    for var area: TArea in FindMerges do
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
  FindFormulas;
  FindFixedAreas;
  var why: string := '';
  for var fixed: TArea in fArrays do
    if fixed.Overlaps(area) then
      why := 'an array formula (' + fixed.Address + '), which Excel changes only as a whole';
  for var fixed: TArea in fDataTables do
    if fixed.Overlaps(area) then
      why := 'a data table, which Excel''s what-if analysis fills';
  for var fixed: TArea in fTables do
    if fixed.Overlaps(area) then
      why := 'a table, where Excel merges no cells';
  for var fixed: TArea in fPivots do
    if fixed.Overlaps(area) then
      why := 'a pivot table, which Excel builds again';
  if why <> '' then
  begin
    fWorkbook.fIssues.Add(TIssueSeverity.isError, 'Merge', fName + '!' + area.Address, 'over ' + why + ' - not merged');
    Exit;
  end;
  var sheet: TWorksheetE := Objects(True);
  // the merged areas met become part of this one
  if sheet.IsPresent('MergeCells') then
    for var i := sheet.MergeCells.MergeCell.Count - 1 downto 0 do
    begin
      var old: TArea;
      if TArea.TryParse(sheet.MergeCells.MergeCell[i].Ref, old) and
        old.Overlaps(area) then
        sheet.MergeCells.MergeCell.Delete(i);
    end;
  FreeAndNil(fMerges);
  // the first value read row by row goes to the top-left cell, as Excel keeps it
  var first: TCellCT := nil;
  var rowIndex: integer;
  FindRow(sheet, area.Top, rowIndex);
  var rows: TRowCTList := sheet.SheetData.Row;
  while (first = nil) and (rowIndex < rows.Count) and (rows[rowIndex].R <= cardinal(area.Bottom)) do
  begin
    var cellIndex: integer;
    FindInRow(rows[rowIndex], area.Left, cellIndex);
    var cells: TCellCTList := rows[rowIndex].C;
    while (cellIndex < cells.Count) and (TUtility.ColumnOf(cells[cellIndex].R) <= area.Right) do
    begin
      if HasValue(cells[cellIndex]) then
      begin
        first := cells[cellIndex];
        Break;
      end;
      Inc(cellIndex);
    end;
    Inc(rowIndex);
  end;
  if (first <> nil) and (string(first.R) <> TUtility.CellName(area.Top, area.Left)) then
  begin
    var at: TArea;
    TArea.TryParse(first.R, at);
    var text: string;
    var value: Variant;
    if first.IsPresent('F') then
    begin
      if FormulaText(at.Top, at.Left, text) then
        WriteFormula(area.Top, area.Left, text, MakeRange(area));
    end
    else if first.IsPresent('Is') then
    begin
      CellValue(first, value);
      WriteText(area.Top, area.Left, VarToStr(value), MakeRange(area));
    end
    else if CanWrite(area.Top, area.Left, MakeRange(area)) then
    begin
      // moved as it is: a shared string's count stays
      var target: TCellCT := CellForWriting(area.Top, area.Left);
      target.T := first.T;
      target.V := first.V;
      first.Clear(@first.V);
      first.Clear(@first.T);
    end;
  end;
  if area.Right > area.Left then
    ClearContents(MakeRange(area.Top, area.Left + 1, area.Top, area.Right));
  if area.Bottom > area.Top then
    ClearContents(MakeRange(area.Top + 1, area.Left, area.Bottom, area.Right));
  // every cell takes the top-left cell's format
  var style: cardinal := EffectiveStyle(area.Top, area.Left);
  SetStyles(MakeRange(area),
    function(aStyle: cardinal): cardinal
    begin
      Result := style;
    end, False);
  var added: TMergeCellCT := TMergeCellCT.Create;
  added.Ref := area.CellsAddress;
  sheet.MergeCells.MergeCell.Add(added);
  sheet.MergeCells.Count := sheet.MergeCells.MergeCell.Count;
  sheet.MergeCells.SetPresent(@sheet.MergeCells.Count);
  FreeAndNil(fMerges);
end;

procedure TWorksheet.UnMerge(const aRange: TRange);
begin
  var sheet: TWorksheetE := Objects(False);
  if not sheet.IsPresent('MergeCells') then
    Exit;
  var list: TMergeCellCTList := sheet.MergeCells.MergeCell;
  for var i := list.Count - 1 downto 0 do
  begin
    var area: TArea;
    if TArea.TryParse(list[i].Ref, area) and area.Overlaps(aRange.Area) then
    begin
      Objects(True);
      list.Delete(i);
    end;
  end;
  if list.Count = 0 then // the schema wants one at least
    sheet.Clear('MergeCells')
  else if sheet.MergeCells.Present[@sheet.MergeCells.Count] then
    sheet.MergeCells.Count := list.Count;
  FreeAndNil(fMerges);
end;

// the workbook's <sheet> of this one
function TWorksheet.SheetEntry: TSheetCT;
begin
  for var entry: TSheetCT in fWorkbook.fBook.Package.Part<TWorkbookE>(fWorkbook.fBook.WorkbookPart).Sheets.Sheet do
    if entry.Name = fName then
      Exit(entry);
  Result := nil;
end;

function TWorksheet.GetVisible: TSheetVisibility;
begin
  var entry: TSheetCT := SheetEntry;
  if entry = nil then
    Exit(svVisible);
  case entry.State of
    stssHidden: Result := svHidden;
    stssVeryHidden: Result := svVeryHidden;
  else
    Result := svVisible;
  end;
end;

procedure TWorksheet.SetVisible(aValue: TSheetVisibility);
const
  cStates: array[TSheetVisibility] of TSheetStateST = (stssVisible, stssHidden, stssVeryHidden);
begin
  if aValue = GetVisible then
    Exit;
  var workbook: TWorkbookE := fWorkbook.fBook.Package.EditPart<TWorkbookE>(fWorkbook.fBook.WorkbookPart);
  var entries: TSheetCTList := workbook.Sheets.Sheet;
  var index: integer := -1;
  var visible: integer := 0;
  for var i := 0 to entries.Count - 1 do
  begin
    if entries[i].Name = fName then
      index := i
    else if entries[i].State = stssVisible then
      Inc(visible);
  end;
  if index < 0 then
    Exit;
  if (aValue <> svVisible) and (visible = 0) then
    raise EInvalidOpException.CreateFmt('%s is the last visible sheet: Excel keeps one at least', [fName]);
  if aValue = svVisible then
    entries[index].Clear(@entries[index].State)
  else
    entries[index].State := cStates[aValue];
  if aValue = svVisible then
    Exit;
  if not workbook.IsPresent('BookViews') then
    if index = 0 then // the first sheet is active without a view
      workbook.BookViews.WorkbookView.Add(TBookViewCT.Create)
    else
      Exit;
  // the active sheet hidden: the next visible one (else the one before) active, as Excel does
  for var view: TBookViewCT in workbook.BookViews.WorkbookView do
  begin
    if integer(view.ActiveTab) <> index then
      Continue;
    var active: integer := -1;
    for var i := index + 1 to entries.Count - 1 do
      if (active < 0) and (entries[i].State = stssVisible) then
        active := i;
    for var i := index - 1 downto 0 do
      if (active < 0) and (entries[i].State = stssVisible) then
        active := i;
    view.ActiveTab := active;
    view.SetPresent(@view.ActiveTab);
    if integer(view.FirstSheet) > active then
      view.FirstSheet := active;
    // the tabs selected: the new active one only
    for var sheet: TWorksheet in fWorkbook.fSheets do
    begin
      var tab: integer := entries.IndexOf(sheet.SheetEntry);
      var objects: TWorksheetE := sheet.Objects(False);
      if (tab = index) or (tab = active) then
        if objects.IsPresent('SheetViews') then
          for var sheetView: TSheetViewCT in objects.SheetViews.SheetView do
            if sheetView.TabSelected <> (tab = active) then
            begin
              sheet.Objects(True);
              if tab = active then
                sheetView.TabSelected := True
              else
                sheetView.Clear(@sheetView.TabSelected);
            end;
    end;
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
  var at: TArea;
  if (pane.TopLeftCell <> '') and TArea.TryParse(pane.TopLeftCell, at) and (at.Top = at.Bottom) and (at.Left = at.Right) then
    Result := TUtility.CellName(at.Top, at.Left)
  else
    Result := TUtility.CellName(Trunc(pane.YSplit) + 1, Trunc(pane.XSplit) + 1);
end;

// Excel's frozen pane and its selections, as Excel writes them for one view
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
  var sheet: TWorksheetE := Objects(False);
  var why: string := '';
  if sheet.IsPresent('SheetViews') and (sheet.SheetViews.SheetView.Count > 1) then
    why := 'the sheet has several views; Calcite freezes panes only with one'
  else if sheet.IsPresent('SheetViews') and (sheet.SheetViews.SheetView.Count = 1) and
    sheet.SheetViews.SheetView[0].IsPresent('Pane') and not fFresh then
    why := 'the sheet has panes of its own, which Calcite does not change yet';
  if why <> '' then
  begin
    fWorkbook.fIssues.Add(TIssueSeverity.isError, 'FreezePanes', fName, why + ' - not changed');
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
  pane.TopLeftCell := TUtility.CellName(row, column);
  pane.State := stpsFrozen;
  pane.SetPresent(@pane.State);
  // a selection in each pane that scrolls, its first cell: Excel's own
  var panes: TArray<TPaneST>;
  var cells: TArray<string>;
  if row = 1 then
  begin
    panes := [stpTopRight];
    cells := [TUtility.CellName(1, column)];
  end
  else if column = 1 then
  begin
    panes := [stpBottomLeft];
    cells := [TUtility.CellName(row, 1)];
  end
  else
  begin
    panes := [stpTopRight, stpBottomLeft, stpBottomRight];
    cells := [TUtility.CellName(1, column), TUtility.CellName(row, 1), TUtility.CellName(row, column)];
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

// why Excel or Calcite does not insert (aCount > 0) or delete (aCount < 0) the rows or columns from aFirst, '' when nothing
// stands in the way
function TWorksheet.ShiftBlocker(aByRows: boolean; aFirst, aCount: integer): string;
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
    for var spill: TArea in fSpills do
      if (spill.Top = aArea.Top) and (spill.Left = aArea.Left) then
        Exit(True);
    Result := False;
  end;

begin
  var sheet: TWorksheetE := Objects(False);
  var last: integer := aFirst - aCount - 1;
  var limit: integer := IfThen(aByRows, TUtility.cMaxRow, TUtility.cMaxColumn);
  FindFormulas;
  for var area: TArea in fArrays do
  begin
    var low: integer := IfThen(aByRows, area.Top, area.Left);
    var high: integer := IfThen(aByRows, area.Bottom, area.Right);
    if IsSpill(area) then
    begin // Excel moves the formula's cell and spills it again from there; with that cell it goes whole
      var moved: integer := ShiftedIndex(low, aFirst, aCount, limit);
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
            var along: integer := IfThen(aByRows, integer(row.R), TUtility.ColumnOf(cell.R));
            var across: integer := IfThen(aByRows, TUtility.ColumnOf(cell.R), integer(row.R));
            var place: integer := ShiftedIndex(along, aFirst, aCount, limit);
            if (place >= moved) and (place <= moved + high - low) and (across >= IfThen(aByRows, area.Left, area.Top)) and
              (across <= IfThen(aByRows, area.Right, area.Bottom)) then
              Exit(Format('cells moved into the spill of the dynamic array at %s (Excel shows #SPILL!)', [anchor]) +
                cNotYet);
          end;
      Continue;
    end;
    if (aCount > 0) and (aFirst > low) and (aFirst <= high) or
      (aCount < 0) and (aFirst <= high) and (last >= low) and ((aFirst > low) or (last < high)) then
      Exit('You can''t change part of an array.');
  end;
  if fDataTables.Count > 0 then
    Exit('a data table' + cLater);
  if aCount > 0 then // a cell with only a format there is dropped, as Excel drops it
    for var row: TRowCT in sheet.SheetData.Row do
      for var cell: TCellCT in row.C do
        if HasValue(cell) and (aByRows and (integer(row.R) > limit - aCount) or
          not aByRows and (TUtility.ColumnOf(cell.R) > limit - aCount)) then
          Exit(cPushedOff);
  Result := PivotsBlocker(aByRows, aFirst, aCount);
  if Result = '' then
    Result := TablesBlocker(aByRows, aFirst, aCount);
  if Result <> '' then
    Exit;
  for var i := 0 to High(cElements) do
    if sheet.IsPresent(cElements[i]) then
      Exit(cWhat[i] + cLater);
  Result := NotesBlocker(aByRows, aFirst, aCount);
end;

// the same with aSheet's tables: those deleted and their columns (structured references to them become #REF!), the ranges
// growing with them (PlanTables found them)
function SheetMap(const aFormulaSheet: string; aSheet: TWorksheet; aByRows: boolean; aFirst, aCount: integer): TReferenceMap;
begin
  Result := ShiftMap(aFormulaSheet, aSheet.fName, aByRows, aFirst, aCount);
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
function PlanFormulas(aSheet: TWorksheet; const aMap: TReferenceMap; aShifted: TWorksheet;
  aMoves: TList<TWorksheet.TFormulaMove>; aTexts: TList<TWorksheet.TTextMove>; aRefs: TDictionary<cardinal, string>;
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
    var move: TWorksheet.TTextMove := Default(TWorksheet.TTextMove);
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
  var count: integer := IfThen(aMap.Change = TReferenceChange.rcDelete, -aMap.Count, aMap.Count);
  var sheet: TWorksheetE := aSheet.Objects(False);
  for var row: TRowCT in sheet.SheetData.Row do
    for var cell: TCellCT in row.C do
    begin
      if not cell.IsPresent('F') or (cell.F.T = stcftDataTable) then
        Continue;
      if (cell.F.T = stcftShared) and (cell.F.Ref <> '') then
        aRefs.AddOrSetValue(cell.F.Si, cell.F.Ref);
      var move: TWorksheet.TFormulaMove;
      move.Cell := cell;
      move.Row := row.R;
      move.Column := TUtility.ColumnOf(cell.R);
      if not aSheet.FormulaText(move.Row, move.Column, move.Before) then
        Continue;
      if aShifted = aSheet then
        if aMap.ByRows then
          move.Row := ShiftedIndex(move.Row, aMap.First, count, TUtility.cMaxRow)
        else
          move.Column := ShiftedIndex(move.Column, aMap.First, count, TUtility.cMaxColumn);
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
procedure WriteTexts(aTexts: TList<TWorksheet.TTextMove>);
begin
  for var move: TWorksheet.TTextMove in aTexts do
  begin
    move.Sheet.Objects(True);
    if move.Rule <> nil then
      move.Rule.Formula[move.Index] := EncodeText(move.Text)
    else if move.Index = 1 then
      move.Validation.Formula1 := EncodeText(move.Text)
    else
      move.Validation.Formula2 := EncodeText(move.Text);
  end;
end;

procedure TWorksheet.ShowRows(aTop, aBottom: integer);
begin
  for var row: TRowCT in RowEntries(aTop, aBottom) do
    row.Clear(@row.Hidden);
end;

// a row inserted as Excel does: the format and height of the row above (not hidden), its cells' styles where they differ
// from what the new row shows anyway; nil when there is nothing to copy
function TWorksheet.CopiedRow(aSource: TRowCT; aNumber: integer): TRowCT;
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
    var shown: cardinal := ColumnStyle(column);
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
procedure TWorksheet.ShiftColumnEntries(aFirst, aCount: integer);
begin
  var sheet: TWorksheetE := Objects(True);
  if sheet.Cols.Count = 0 then
    Exit;
  var columns: TColCTList := SortedColumns;
  var last: integer := aFirst - aCount - 1;
  SplitColumns(columns, aFirst);
  if aCount < 0 then
  begin
    if last < TUtility.cMaxColumn then
      SplitColumns(columns, last + 1);
    for var i := columns.Count - 1 downto 0 do
      if (integer(columns[i].Min) >= aFirst) and (integer(columns[i].Max) <= last) then
        columns.Delete(i)
      else if integer(columns[i].Min) > last then
      begin
        columns[i].Min := integer(columns[i].Min) + aCount;
        columns[i].Max := integer(columns[i].Max) + aCount;
      end;
  end
  else
  begin
    var source: integer := -1;
    for var i := columns.Count - 1 downto 0 do
      if integer(columns[i].Min) >= aFirst then
      begin
        if integer(columns[i].Min) + aCount > TUtility.cMaxColumn then
          columns.Delete(i)
        else
        begin
          columns[i].Min := integer(columns[i].Min) + aCount;
          columns[i].Max := Min(integer(columns[i].Max) + aCount, TUtility.cMaxColumn);
        end;
      end
      else if integer(columns[i].Max) = aFirst - 1 then
        source := i;
    if source >= 0 then
      if not columns[source].Hidden and (columns[source].Width > 0) then
        columns[source].Max := integer(columns[source].Max) + aCount
      else
      begin
        var copy: TColCT := columns[source].Clone<TColCT>;
        copy.Min := aFirst;
        copy.Max := aFirst + aCount - 1;
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
procedure TWorksheet.ShiftCells(aByRows: boolean; aFirst, aCount: integer);
begin
  var sheet: TWorksheetE := Objects(True);
  var rows: TRowCTList := sheet.SheetData.Row;
  var last: integer := aFirst - aCount - 1;
  if aByRows then
  begin
    var index: integer;
    FindRow(sheet, aFirst, index);
    if aCount < 0 then
      while (index < rows.Count) and (integer(rows[index].R) <= last) do
      begin
        for var cell: TCellCT in rows[index].C do
          RemoveValue(cell);
        rows.Delete(index);
      end
    else
      for var i := rows.Count - 1 downto index do
        if integer(rows[i].R) + aCount > TUtility.cMaxRow then // only formats there (ShiftBlocker)
          rows.Delete(i);
    for var i := index to rows.Count - 1 do
    begin
      var row: TRowCT := rows[i];
      row.R := integer(row.R) + aCount;
      for var cell: TCellCT in row.C do
        cell.R := TUtility.CellName(row.R, TUtility.ColumnOf(cell.R));
    end;
    var above: integer;
    if (aCount > 0) and (aFirst > 1) and FindRow(sheet, aFirst - 1, above) then
      for var number := aFirst + aCount - 1 downto aFirst do
      begin
        var added: TRowCT := CopiedRow(rows[above], number);
        if added <> nil then
          rows.Insert(above + 1, added);
      end;
    Exit;
  end;
  ShiftColumnEntries(aFirst, aCount);
  for var row: TRowCT in rows do
  begin
    var cells: TCellCTList := row.C;
    var index: integer;
    FindInRow(row, aFirst, index);
    if aCount < 0 then
      while (index < cells.Count) and (TUtility.ColumnOf(cells[index].R) <= last) do
      begin
        RemoveValue(cells[index]);
        cells.Delete(index);
      end
    else
      for var i := cells.Count - 1 downto index do
        if TUtility.ColumnOf(cells[i].R) + aCount > TUtility.cMaxColumn then
          cells.Delete(i);
    for var i := index to cells.Count - 1 do
      cells[i].R := TUtility.CellName(row.R, TUtility.ColumnOf(cells[i].R) + aCount);
    if (aCount > 0) and (index > 0) and (TUtility.ColumnOf(cells[index - 1].R) = aFirst - 1) then
    begin
      var source: TCellCT := cells[index - 1];
      var shown: cardinal := ColumnStyle(aFirst);
      if row.CustomFormat then
        shown := row.S;
      if source.S <> shown then
        for var column := aFirst + aCount - 1 downto aFirst do
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
function TWorksheet.LiftSpills(aByRows: boolean; aFirst, aCount: integer): TArray<TSpill>;
begin
  Result := nil;
  FindFormulas;
  var rows: TRowCTList := Objects(False).SheetData.Row;
  for var area: TArea in fSpills do
  begin
    var spill: TSpill;
    spill.Area := area;
    spill.Values := nil;
    var index: integer;
    FindRow(Objects(False), area.Top, index);
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
        Objects(True);
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
procedure TWorksheet.PlaceSpills(const aSpills: TArray<TSpill>; aByRows: boolean; aFirst, aCount: integer);
begin
  for var spill: TSpill in aSpills do
  begin
    var moved: integer;
    if aByRows then
      moved := ShiftedIndex(spill.Area.Top, aFirst, aCount, TUtility.cMaxRow)
    else
      moved := ShiftedIndex(spill.Area.Left, aFirst, aCount, TUtility.cMaxColumn);
    var top: integer := IfThen(aByRows, moved, spill.Area.Top);
    var left: integer := IfThen(aByRows, spill.Area.Left, moved);
    for var value: TSpillValue in spill.Values do
      if moved = 0 then
      begin
        if value.Typed and (value.T = stctS) then
          fWorkbook.fBook.SharedStringReleased;
      end
      else
      begin
        var cell: TCellCT := CellForStyle(top + value.Row, left + value.Column);
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
procedure TWorksheet.FitAgain(aByRows: boolean; aFirst, aCount: integer);
begin
  if aByRows then
    Exit;
  var rows: TRowCTList := Objects(False).SheetData.Row;
  var moved: boolean := False;
  for var row: TRowCT in rows do
    if (row.C.Count > 0) and (TUtility.ColumnOf(row.C[row.C.Count - 1].R) >= aFirst) then
      moved := True;
  if not moved and (aCount > 0) then
    for var area: TArea in FindMerges do
      if (area.Left < aFirst) and (area.Right >= aFirst) then
        moved := True;
  if not moved then
    Exit;
  for var row: TRowCT in rows do
    if row.Present[@row.Ht] and not row.CustomHeight then
    begin
      Objects(True);
      row.Clear(@row.Ht);
    end;
end;

// an autofilter's columns through columns inserted or deleted (its first one was aOldLeft, is aLeft): True when the last
// filter went with them - Excel then shows the rows it hid
function ShiftFilterColumns(aFilter: TAutoFilterCT; aOldLeft, aLeft, aFirst, aCount: integer): boolean;
begin
  var filtered: boolean := aFilter.FilterColumn.Count > 0;
  for var i := aFilter.FilterColumn.Count - 1 downto 0 do
  begin
    var column: integer := ShiftedIndex(aOldLeft + integer(aFilter.FilterColumn[i].ColId), aFirst, aCount, TUtility.cMaxColumn);
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
procedure TWorksheet.ShiftLists(aByRows: boolean; aFirst, aCount: integer);
var
  sheet: TWorksheetE;
  last: integer;

  function Sqref(const aText: string; aGrowAfter: boolean = False): string;
  begin
    Result := ShiftedSqref(aText, aByRows, aFirst, aCount, aGrowAfter);
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
      var id: integer := ShiftedIndex(aBreaks.Brk[i].Id, aFirst, aCount, IfThen(aByRows, TUtility.cMaxRow, TUtility.cMaxColumn));
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
  sheet := Objects(True);
  last := aFirst - aCount - 1;
  if sheet.IsPresent('MergeCells') then
  begin
    var merged: TMergeCellCTList := sheet.MergeCells.MergeCell;
    for var i := merged.Count - 1 downto 0 do
    begin
      var area: TArea;
      if TArea.TryParse(merged[i].Ref, area) then
        if ShiftedArea(area, aByRows, aFirst, aCount, False) and ((area.Top <> area.Bottom) or (area.Left <> area.Right)) then
          merged[i].Ref := area.CellsAddress
        else
          merged.Delete(i);
    end;
    if merged.Count = 0 then
      sheet.Clear('MergeCells')
    else if sheet.MergeCells.Present[@sheet.MergeCells.Count] then
      sheet.MergeCells.Count := merged.Count;
  end;
  FreeAndNil(fMerges);
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
      if aByRows and (aCount < 0) and (aFirst <= area.Top) and (last >= area.Top) or
        not ShiftedArea(area, aByRows, aFirst, aCount, False) then
      begin
        sheet.Clear('AutoFilter');
        filterGone := True;
      end
      else
      begin
        filter.Ref := area.CellsAddress;
        if not aByRows and ShiftFilterColumns(filter, oldLeft, area.Left, aFirst, aCount) then
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
  if aByRows and sheet.IsPresent('RowBreaks') then
    ShiftBreaks(sheet.RowBreaks, 'RowBreaks');
  if not aByRows and sheet.IsPresent('ColBreaks') then
    ShiftBreaks(sheet.ColBreaks, 'ColBreaks');
  if sheet.IsPresent('SheetViews') then
    for var view: TSheetViewCT in sheet.SheetViews.SheetView do
      if view.IsPresent('Pane') and (view.Pane.State in [stpsFrozen, stpsFrozenSplit]) then
      begin
        var pane: TPaneCT := view.Pane;
        var split: integer := Trunc(pane.XSplit);
        if aByRows then
          split := Trunc(pane.YSplit);
        if (split = 0) or (aFirst > split) then
          Continue;
        var moved: integer := split + aCount;
        if aCount < 0 then
          moved := Max(1, split - (Min(last, split) - aFirst + 1));
        var at: TArea;
        if aByRows then
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
      if ShiftedArea(area, aByRows, aFirst, aCount, False) then
        sheet.Dimension.Ref := area.CellsAddress
      else
        sheet.Dimension.Ref := 'A1';
  end;
  if filterGone then // and its hidden name with it
  begin
    var workbook: TWorkbookE := fWorkbook.fBook.Package.EditPart<TWorkbookE>(fWorkbook.fBook.WorkbookPart);
    var tab: integer := workbook.Sheets.Sheet.IndexOf(SheetEntry);
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

{ TWorksheet.TAxis }

constructor TWorksheet.TAxis.Create(aSheet: TWorksheet; aByRows: boolean);
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
      Result := WidthPixels(aAxis.Size) * cPixel;
  end;

begin
  fSizes := TList<TPair<integer, Int64>>.Create;
  fDefault := Emus(aSheet.AxisDefault(aByRows));
  for var entry: TPair<integer, TAxisFormat> in aSheet.AxisEntries(aByRows) do
    fSizes.Add(TPair<integer, Int64>.Create(entry.Key, Emus(entry.Value)));
end;

destructor TWorksheet.TAxis.Destroy;
begin
  fSizes.Free;
  inherited;
end;

function TWorksheet.TAxis.Start(aIndex: integer): Int64;
begin
  Result := fDefault * aIndex;
  for var size: TPair<integer, Int64> in fSizes do
    if size.Key <= aIndex then
      Inc(Result, size.Value - fDefault)
    else
      Break;
end;

procedure TWorksheet.TAxis.Find(aPosition: Int64; out aIndex: integer; out aOffset: Int64);
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
function TWorksheet.TablesBlocker(aByRows: boolean; aFirst, aCount: integer): string;
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
      if (aLeft + integer(column.ColId) >= aFirst) and (aLeft + integer(column.ColId) <= last) then
        Inc(deleted);
    Result := not aByRows and (aCount < 0) and (deleted > 0) and (deleted < aFilter.FilterColumn.Count);
  end;

  // rows passing through it: an insert below its first row, a delete taking any
  function Through(const aArea: TArea): boolean;
  begin
    Result := aByRows and ((aCount > 0) and (aFirst > aArea.Top) and (aFirst <= aArea.Bottom) or
      (aCount < 0) and (aFirst <= aArea.Bottom) and (last >= aArea.Top));
  end;

begin
  last := aFirst - aCount - 1;
  var package: TPackageOoxml := fWorkbook.fBook.Package;
  for var relationship: TRelationshipOoxml in package.Relationships(fPartName) do
    if relationship.&Type.EndsWith(cTable) then
    begin
      var table: TTableE := package.Part<TTableE>(relationship.Part);
      var area: TArea;
      if (table = nil) or not TArea.TryParse(table.Ref, area) then
        Exit(Format('a table that does not read (%s)', [relationship.Part]));
      if IfThen(aByRows, area.Bottom, area.Right) < aFirst then
        Continue;
      if table.TableType <> stttWorksheet then
        Exit(Format('a table from a query or an XML map (%s, %s), which Calcite does not move yet', [table.Name,
          area.CellsAddress]));
      if aByRows and (aCount < 0) and (table.HeaderRowCount > 0) and (aFirst < area.Top + integer(table.HeaderRowCount)) and
        (last >= area.Top) and ((aFirst > area.Top) or (last < area.Bottom)) then
        Exit(Format('the header row of a table (%s, %s): Excel deletes it only with the whole table', [table.Name,
          area.CellsAddress]));
      if table.IsPresent('AutoFilter') and (table.AutoFilter.FilterColumn.Count > 0) and Through(area) then
        Exit(Format(cFiltered, ['table', table.Name]));
      if table.IsPresent('AutoFilter') and SomeFilters(table.AutoFilter, area.Left) then
        Exit(Format(cFilterDeleted, ['table', table.Name]));
    end;
  var sheet: TWorksheetE := Objects(False);
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
function TWorksheet.PivotsBlocker(aByRows: boolean; aFirst, aCount: integer): string;
begin
  var last: integer := aFirst - aCount - 1;
  FindFixedAreas;
  for var area: TArea in fPivots do
  begin
    var low: integer := IfThen(aByRows, area.Top, area.Left);
    var high: integer := IfThen(aByRows, area.Bottom, area.Right);
    if (aCount > 0) and (aFirst > low) and (aFirst <= high) or
      (aCount < 0) and (aFirst <= high) and (last >= low) and ((aFirst > low) or (last < high)) then
      Exit('We can''t make this change for the selected cells because it will affect a PivotTable. Use the field list to ' +
        'change the report. If you are trying to insert or delete cells, move the PivotTable and try again.');
  end;
  // a consolidation names its ranges by sheet
  var package: TPackageOoxml := fWorkbook.fBook.Package;
  for var relationship: TRelationshipOoxml in package.Relationships(fWorkbook.fBook.WorkbookPart) do
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
procedure TWorksheet.KeepTableRows(var aFirst, aCount: integer; aCleared: TList<TArea>);
begin
  var last: integer := aFirst - aCount - 1;
  var package: TPackageOoxml := fWorkbook.fBook.Package;
  for var relationship: TRelationshipOoxml in package.Relationships(fPartName) do
    if relationship.&Type.EndsWith(cTable) then
    begin
      var table: TTableE := package.Part<TTableE>(relationship.Part);
      var area: TArea;
      if (table = nil) or not TArea.TryParse(table.Ref, area) or
        (table.HeaderRowCount = 0) then
        Continue;
      var dataTop: integer := area.Top + integer(table.HeaderRowCount);
      var dataBottom: integer := area.Bottom - integer(table.TotalsRowCount);
      if (dataTop <= dataBottom) and (aFirst = dataTop) and (last >= dataBottom) then
      begin
        area.Top := dataTop;
        area.Bottom := dataTop;
        aCleared.Add(area);
      end;
    end;
  if aCleared.Count > 0 then
  begin
    Inc(aFirst);
    Inc(aCount);
  end;
end;

// the tables and table columns the change deletes (fGone), for the formulas naming them
procedure TWorksheet.PlanTables(aByRows: boolean; aFirst, aCount: integer);
begin
  fGone := nil;
  fBodies := nil;
  var last: integer := aFirst - aCount - 1;
  var package: TPackageOoxml := fWorkbook.fBook.Package;
  for var relationship: TRelationshipOoxml in package.Relationships(fPartName) do
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
      if aCount > 0 then
        Continue;
      if not ShiftedArea(area, aByRows, aFirst, aCount, False) then
        fGone := fGone + [string(table.Name)]
      else if not aByRows then
      begin
        TArea.TryParse(table.Ref, area);
        for var index := 0 to table.TableColumns.TableColumn.Count - 1 do
          if (area.Left + index >= aFirst) and (area.Left + index <= last) then
            fGone := fGone + [table.Name + '[' + table.TableColumns.TableColumn[index].Name + ']'];
      end;
    end;
end;

// the sheet's tables as Excel moves them: grown by rows or columns inserted inside (new columns named Column1...; new rows
// take the calculated columns' formulas), shrunk, gone with all their rows or columns; the totals row deleted, the table
// keeps none; the autofilter, its columns and sort follow
procedure TWorksheet.ShiftTables(aByRows: boolean; aFirst, aCount: integer);
var
  sheet: TWorksheetE;
  last: integer;

  function Changed(const aText: string): string;
  begin
    var why: string;
    if not ShiftFormula(aText, SheetMap(fName, Self, aByRows, aFirst, aCount), Result, why) then
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
    var cell: TCellCT := CellForWriting(aRow, aColumn);
    var index: integer := fWorkbook.fBook.SharedStringIndex(aName);
    if index >= 0 then
    begin
      cell.T := stctS;
      cell.V := IntToStr(index);
    end
    else
    begin
      cell.T := stctInlineStr;
      cell.&Is.T := EncodeText(aName);
    end;
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
    fWorkbook.fBook.Package.RemovePart(fPartName, aRelationship.Part);
  end;

begin
  sheet := Objects(True);
  last := aFirst - aCount - 1;
  var package: TPackageOoxml := fWorkbook.fBook.Package;
  for var relationship: TRelationshipOoxml in package.Relationships(fPartName) do
  begin
    if not relationship.&Type.EndsWith(cTable) then
      Continue;
    var table: TTableE := package.EditPart<TTableE>(relationship.Part);
    var old: TArea;
    if not TArea.TryParse(table.Ref, old) then
      Continue;
    var area: TArea := old;
    if not ShiftedArea(area, aByRows, aFirst, aCount, False) then
    begin
      Remove(relationship);
      Continue;
    end;
    var columns: TTableColumnCTList := table.TableColumns.TableColumn;
    var added: TArray<integer> := nil; // the new columns' numbers on the sheet
    if not aByRows and (aCount < 0) then
    begin
      for var index := columns.Count - 1 downto 0 do
        if (old.Left + index >= aFirst) and (old.Left + index <= last) then
          columns.Delete(index);
    end
    else if not aByRows and (aFirst > old.Left) and (aFirst <= old.Right) then
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
        for var index := 0 to aCount - 1 do
        begin
          while names.IndexOf('Column' + IntToStr(number)) >= 0 do
            Inc(number);
          var column: TTableColumnCT := TTableColumnCT.Create;
          Inc(id);
          column.Id := id;
          column.Name := 'Column' + IntToStr(number);
          names.Add(column.Name);
          columns.Insert(aFirst - old.Left + index, column);
          added := added + [aFirst + index];
        end;
      finally
        names.Free;
      end;
    end;
    table.TableColumns.Count := columns.Count;
    if aByRows and (aCount < 0) and (table.TotalsRowCount > 0) and (old.Bottom >= aFirst) and (old.Bottom <= last) then
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
    if aByRows and (aCount > 0) and (aFirst > old.Top) and (aFirst <= old.Bottom) then
      for var index := 0 to columns.Count - 1 do
        if columns[index].IsPresent('CalculatedColumnFormula') and not columns[index].CalculatedColumnFormula.&Array then
        begin
          var text: string := DecodeText(columns[index].CalculatedColumnFormula.XmlValue);
          for var row := Max(aFirst, dataTop) to Min(aFirst + aCount - 1, dataBottom) do
          begin
            var filled, why: string;
            if ShiftFormula(text, TReferenceMap.Fill(row - dataTop, 0), filled, why) then
            begin
              CellForWriting(row, area.Left + index).F.XmlValue := EncodeText(filled);
              fWorkbook.fBook.FormulaChanged;
            end;
          end;
        end;
    if table.IsPresent('AutoFilter') then
    begin
      var filter: TAutoFilterCT := table.AutoFilter;
      var shown: TArea := area;
      shown.Bottom := dataBottom;
      filter.Ref := shown.CellsAddress;
      if not aByRows and ShiftFilterColumns(filter, old.Left, area.Left, aFirst, aCount) then
        ShowRows(dataTop, dataBottom);
    end;
    if table.IsPresent('SortState') then
    begin
      var sort: TSortStateCT := table.SortState;
      var ref: string := ShiftedSqref(sort.Ref, aByRows, aFirst, aCount, False);
      if ref <> '' then
      begin
        sort.Ref := ref;
        for var i := sort.SortCondition.Count - 1 downto 0 do
        begin
          var condition: string := ShiftedSqref(sort.SortCondition[i].Ref, aByRows, aFirst, aCount, False);
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
procedure TWorksheet.ShiftPivots(aByRows: boolean; aFirst, aCount: integer);
begin
  var package: TPackageOoxml := fWorkbook.fBook.Package;
  for var relationship: TRelationshipOoxml in package.Relationships(fPartName) do
    if relationship.&Type.EndsWith(cPivotTable) then
    begin
      var pivot: TPivotTableDefinitionE := package.Part<TPivotTableDefinitionE>(relationship.Part);
      var area: TArea;
      if (pivot = nil) or not TArea.TryParse(pivot.Location.Ref, area) then
        Continue;
      var whole: TArea := area;
      if pivot.Location.RowPageCount > 0 then // the page fields and a blank row
        whole.Top := Max(1, area.Top - integer(pivot.Location.RowPageCount) - 1);
      if not ShiftedArea(whole, aByRows, aFirst, aCount, False) then
      begin
        var folder: integer := relationship.Part.LastIndexOf('/') + 1;
        package.RemovePart(relationship.Part, relationship.Part.Substring(0, folder) + '_rels/' +
          relationship.Part.Substring(folder) + '.rels');
        package.RemovePart(fPartName, relationship.Part);
      end
      else if ShiftedArea(area, aByRows, aFirst, aCount, False) then
        package.EditPart<TPivotTableDefinitionE>(relationship.Part).Location.Ref := area.CellsAddress;
    end;
  for var relationship: TRelationshipOoxml in package.Relationships(fWorkbook.fBook.WorkbookPart) do
    if relationship.&Type.EndsWith(cPivotCacheDefinition) then
    begin
      var cache: TPivotCacheDefinitionE := package.Part<TPivotCacheDefinitionE>(relationship.Part);
      if not cache.CacheSource.IsPresent('WorksheetSource') then
        Continue;
      var source: TWorksheetSourceCT := cache.CacheSource.WorksheetSource;
      if (source.Name <> '') or (source.Ref = '') or not AnsiSameText(source.Sheet, fName) or source.Present[@source.Id] then
        Continue;
      var ref: string := ShiftedSqref(source.Ref, aByRows, aFirst, aCount, False);
      if (ref <> '') and (ref <> source.Ref) then
        package.EditPart<TPivotCacheDefinitionE>(relationship.Part).CacheSource.WorksheetSource.Ref := ref;
    end;
end;

// the drawings' objects and where they start and end along the shifted axis before the change; aWhy for a drawing that
// does not read
function TWorksheet.PlanDrawings(aByRows: boolean; out aWhy: string): TList<TAnchorMove>;
begin
  Result := TList<TAnchorMove>.Create;
  aWhy := '';
  var package: TPackageOoxml := fWorkbook.fBook.Package;
  var axis: TAxis := nil;
  try
    for var relationship: TRelationshipOoxml in package.Relationships(fPartName) do
      if relationship.&Type.EndsWith(cDrawing) then
      begin
        var drawing: TWsDrE := package.Part<TWsDrE>(relationship.Part);
        if drawing = nil then
        begin
          aWhy := Format('a drawing that does not read (%s)', [relationship.Part]);
          Exit;
        end;
        if axis = nil then
          axis := TAxis.Create(Self, aByRows);
        for var anchor: TTwoCellAnchorCT in drawing.TwoCellAnchor do
        begin
          var move: TAnchorMove := Default(TAnchorMove);
          move.Part := relationship.Part;
          move.Anchor := anchor;
          var fromIndex, toIndex: integer;
          var fromOffset, toOffset: Int64;
          if not MarkerPlace(anchor.From, aByRows, fromIndex, fromOffset) or
            not MarkerPlace(anchor.&To, aByRows, toIndex, toOffset) then
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
          if not MarkerPlace(anchor.From, aByRows, index, offset) then
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
procedure TWorksheet.ShiftDrawings(aMoves: TList<TAnchorMove>; aByRows: boolean; aFirst, aCount: integer);
var
  last, limit: integer;
  axis: TAxis;

  // a marker with its cell: one deleted goes to the start of what follows (its offset as written otherwise)
  procedure MoveMarker(aMarker: TMarkerCT);
  begin
    var index: integer;
    var offset: Int64;
    MarkerPlace(aMarker, aByRows, index, offset);
    var moved: integer := ShiftedIndex(index + 1, aFirst, aCount, limit);
    if (moved = 0) and (aCount < 0) then
      PlaceMarker(aMarker, aByRows, aFirst - 1, 0)
    else if aByRows then
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
    PlaceMarker(aMarker, aByRows, index, offset);
  end;

  // the marker's row or column among the deleted ones (an end: at the start of the one after them too)
  function Deleted(aMarker: TMarkerCT; aEnd: boolean): boolean;
  begin
    var index: integer;
    var offset: Int64;
    MarkerPlace(aMarker, aByRows, index, offset);
    Inc(index);
    Result := (aCount < 0) and ((index >= aFirst) and (index <= last) or aEnd and (index = last + 1) and (offset = 0));
  end;

begin
  if aMoves.Count = 0 then
    Exit;
  last := aFirst - aCount - 1;
  limit := IfThen(aByRows, TUtility.cMaxRow, TUtility.cMaxColumn);
  var package: TPackageOoxml := fWorkbook.fBook.Package;
  axis := TAxis.Create(Self, aByRows);
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
            MarkerPlace(anchor.From, aByRows, index, offset);
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
function ChartPoints(const aBefore, aAfter, aSheet: string; aByRows: boolean; aFirst, aCount: integer;
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
    var limit: integer := IfThen(aByRows, TUtility.cMaxRow, TUtility.cMaxColumn);
    SetLength(aIndexes, Length(before));
    for var i := 0 to High(before) do
    begin
      var cell: TChartCell := before[i];
      if AnsiSameText(cell.Sheet, aSheet) then
        if aByRows then
          cell.Row := ShiftedIndex(cell.Row, aFirst, aCount, limit)
        else
          cell.Column := ShiftedIndex(cell.Column, aFirst, aCount, limit);
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
function PlanCharts(aSheet: TWorksheet; const aMap: TReferenceMap; aMoves: TList<TWorksheet.TChartMove>;
  out aWhy: string): boolean;
begin
  Result := False;
  aWhy := '';
  var package: TPackageOoxml := aSheet.fWorkbook.fBook.Package;
  var drawings: TList<string> := TList<string>.Create;
  var charts: TList<string> := TList<string>.Create;
  var found: TList<TXmlite> := TList<TXmlite>.Create;
  var seen: TDictionary<TBasite, boolean> := TDictionary<TBasite, boolean>.Create;
  try
    var owners: TList<string> := TList<string>.Create;
    try
      for var sheet: TWorksheet in aSheet.fWorkbook.fSheets do
        if (sheet <> aSheet) or (aMap.Change <> TReferenceChange.rcSheetDelete) then
          owners.Add(sheet.fPartName);
      for var relationship: TRelationshipOoxml in package.Relationships(aSheet.fWorkbook.fBook.WorkbookPart) do
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
            var move: TWorksheet.TChartMove := Default(TWorksheet.TChartMove);
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
          var move: TWorksheet.TChartMove := Default(TWorksheet.TChartMove);
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
procedure TWorksheet.ShiftCharts(aMoves: TList<TChartMove>; aByRows: boolean; aFirst, aCount: integer);
begin
  var package: TPackageOoxml := fWorkbook.fBook.Package;
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
    var points: boolean := ChartPoints(move.Before, move.After, fName, aByRows, aFirst, aCount, indexes, total);
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
procedure TWorksheet.NotesParts(out aComments, aDrawing: string);
begin
  aComments := '';
  aDrawing := '';
  var sheet: TWorksheetE := Objects(False);
  var id: string := '';
  if sheet.IsPresent('LegacyDrawing') then
    id := sheet.LegacyDrawing.Id;
  for var relationship: TRelationshipOoxml in fWorkbook.fBook.Package.Relationships(fPartName) do
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
function TWorksheet.NotesBlocker(aByRows: boolean; aFirst, aCount: integer): string;
const
  cPushedOff = 'Microsoft Excel can''t insert new cells because it would push non-empty cells off the end of the ' +
    'worksheet. These non-empty cells might appear empty but have blank values, some formatting, or a formula. Delete ' +
    'enough rows or columns to make room for what you want to insert and then try again.';
begin
  Result := '';
  var package: TPackageOoxml := fWorkbook.fBook.Package;
  for var relationship: TRelationshipOoxml in package.Relationships(fPartName) do
    if relationship.&Type.EndsWith(cThreadedComment) then
      Exit('threaded comments, which Calcite does not move yet');
  var commentsPart, drawingPart: string;
  NotesParts(commentsPart, drawingPart);
  var limit: integer := IfThen(aByRows, TUtility.cMaxRow, TUtility.cMaxColumn);
  if commentsPart <> '' then
  begin
    var comments: TCommentsE := package.Part<TCommentsE>(commentsPart);
    if comments = nil then
      Exit(Format('notes that do not read (%s)', [commentsPart]));
    if aCount > 0 then
      for var comment: TCommentCT in comments.CommentList.Comment do
      begin
        var at: TArea;
        if TArea.TryParse(comment.Ref, at) and (IfThen(aByRows, at.Top, at.Left) > limit - aCount) then
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
procedure TWorksheet.ShiftNotes(aByRows: boolean; aFirst, aCount: integer);
const
  cPixel = 9525;
var
  anchor: array[0 .. 7] of integer; // not an inline var: Delphi 10.3 takes no structured type there
begin
  var commentsPart, drawingPart: string;
  NotesParts(commentsPart, drawingPart);
  if (commentsPart = '') and (drawingPart = '') then
    Exit;
  var package: TPackageOoxml := fWorkbook.fBook.Package;
  var limit: integer := IfThen(aByRows, TUtility.cMaxRow, TUtility.cMaxColumn);
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
      var index: integer := IfThen(aByRows, at.Top, at.Left);
      var moved: integer := ShiftedIndex(index, aFirst, aCount, limit);
      if moved = index then
        Continue;
      if not edited then
        package.EditPart<TCommentsE>(commentsPart);
      edited := True;
      if moved = 0 then
        comments.CommentList.Comment.Remove(comment)
      else if aByRows then
        comment.Ref := TUtility.CellName(moved, at.Left)
      else
        comment.Ref := TUtility.CellName(at.Top, moved);
    end;
    notesLeft := comments.CommentList.Comment.Count > 0;
  end;
  if drawingPart <> '' then
  begin
    var drawing: TVmlDrawing := package.Part<TVmlDrawing>(drawingPart);
    var axis: TAxis := TAxis.Create(Self, aByRows);
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
        var first: integer := IfThen(aByRows, 2, 0); // the start's index; its offset next, the end's 4 on
        var index: integer := IfThen(aByRows, row, column);
        var moved: integer := ShiftedIndex(index, aFirst, aCount, limit);
        if moved <> 0 then
          Inc(shapes);
        if (moved = index) and (anchor[first + 4] < aFirst - 1) then
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
        if aByRows then
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
        if aByRows then
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
    package.RemovePart(fPartName, commentsPart);
  if drawingPart <> '' then
  begin
    package.RemovePart(fPartName, drawingPart);
    Objects(True).Clear('LegacyDrawing');
  end;
end;

// the planned formulas written: a shared formula stays one while its cells still fill from its first cell's text (that cell
// gone, the next one is first) and it names no #REF! (Excel makes those plain), else each cell gets its own; aShifted: this
// sheet's rows or columns moved
procedure TWorksheet.ApplyFormulas(aMoves: TList<TFormulaMove>; aRefs: TDictionary<cardinal, string>; aShifted: boolean;
  aByRows: boolean; aFirst, aCount: integer);
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
        Objects(True);
        formula.XmlValue := EncodeText(move.After);
      end;
      var area: TArea;
      if aShifted and (formula.T = stcftArray) and TArea.TryParse(formula.Ref, area) then
        if (move.Cell.Cm > 0) and fWorkbook.fBook.IsDynamicArray(move.Cell.Cm) then
        begin // spilled again from its cell, as large as before
          var moved: TArea := area;
          moved.Top := move.Row;
          moved.Left := move.Column;
          moved.Bottom := move.Row + area.Bottom - area.Top;
          moved.Right := move.Column + area.Right - area.Left;
          formula.Ref := moved.CellsAddress;
        end
        else if ShiftedArea(area, aByRows, aFirst, aCount, False) then
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
      Objects(True);
      var first: TFormulaMove := aMoves[members[0]];
      var area: TArea;
      var ref: string;
      var shared: boolean := not first.After.Contains('#REF!') and aRefs.TryGetValue(group.Key, ref) and
        TArea.TryParse(ref, area) and
        (not aShifted or ShiftedArea(area, aByRows, aFirst, aCount, False));
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

// every defined name, print areas and titles too, changed as Excel changes references for rows or columns of aSheet inserted
// (aCount > 0) or deleted (aCount < 0) from aFirst. False with aWhy and nothing changed when one naming aSheet does not read
function ChangeNames(aBook: TWorkbook; const aSheet: string; aByRows: boolean; aFirst, aCount: integer;
  out aWhy: string): boolean;
begin
  var map: TReferenceMap := ShiftMap('', aSheet, aByRows, aFirst, aCount);
  for var sheet: TWorksheet in aBook.fSheets do
    if AnsiSameText(sheet.fName, aSheet) then
      map := SheetMap('', sheet, aByRows, aFirst, aCount);
  var changed: TArray<string>;
  Result := aBook.fBook.MappedNames(map, changed, aWhy);
  if Result then
    aBook.fBook.WriteNames(changed);
end;

// Excel's Insert (aCount rows or columns at aFirst) and Delete (-aCount of them from aFirst): all checked and planned
// first, so a refusal changes nothing
procedure TWorksheet.Shift(aByRows: boolean; aFirst, aCount: integer);
begin
  var last: integer := aFirst + Abs(aCount) - 1;
  var what: string := Format('Columns %s:%s', [TUtility.ColumnName(aFirst), TUtility.ColumnName(last)]);
  if aByRows then
    what := Format('Rows %d:%d', [aFirst, last]);
  var cleared: TList<TArea> := TList<TArea>.Create;
  var anchors: TList<TAnchorMove> := nil;
  var moves: TObjectList<TList<TFormulaMove>> := TObjectList<TList<TFormulaMove>>.Create;
  var refs: TObjectList<TDictionary<cardinal, string>> := TObjectList<TDictionary<cardinal, string>>.Create;
  var texts: TList<TTextMove> := TList<TTextMove>.Create;
  var charts: TList<TChartMove> := TList<TChartMove>.Create;
  try
    if aByRows and (aCount < 0) then
      KeepTableRows(aFirst, aCount, cleared);
    var why: string := '';
    if aCount <> 0 then
      why := ShiftBlocker(aByRows, aFirst, aCount);
    if why = '' then
    begin
      PlanTables(aByRows, aFirst, aCount);
      anchors := PlanDrawings(aByRows, why);
    end;
    if (why = '') and (aCount <> 0) then
      PlanCharts(Self, SheetMap('', Self, aByRows, aFirst, aCount), charts, why);
    if (why = '') and (aCount <> 0) then
      for var sheet: TWorksheet in fWorkbook.fSheets do
      begin
        moves.Add(TList<TFormulaMove>.Create);
        refs.Add(TDictionary<cardinal, string>.Create);
        if not PlanFormulas(sheet, SheetMap('', Self, aByRows, aFirst, aCount), Self, moves.Last, texts, refs.Last, why) then
          Break;
      end;
    if (why = '') and (aCount <> 0) then
      ChangeNames(fWorkbook, fName, aByRows, aFirst, aCount, why);
    if why <> '' then
    begin
      var done: string := 'deleted';
      if aCount > 0 then
        done := 'inserted';
      raise EInvalidOpException.CreateFmt('%s of %s not %s: %s', [what, fName, done, why]);
    end;
    WriteTexts(texts);
    if aCount <> 0 then
    begin
      FitAgain(aByRows, aFirst, aCount);
      var spills: TArray<TSpill> := LiftSpills(aByRows, aFirst, aCount);
      ShiftCells(aByRows, aFirst, aCount);
      PlaceSpills(spills, aByRows, aFirst, aCount);
      ShiftLists(aByRows, aFirst, aCount);
      for var index := 0 to fWorkbook.fSheets.fList.Count - 1 do
        fWorkbook.fSheets.fList[index].ApplyFormulas(moves[index], refs[index], fWorkbook.fSheets.fList[index] = Self,
          aByRows, aFirst, aCount);
      ShiftTables(aByRows, aFirst, aCount);
      ShiftPivots(aByRows, aFirst, aCount);
      ShiftDrawings(anchors, aByRows, aFirst, aCount);
      ShiftCharts(charts, aByRows, aFirst, aCount);
      ShiftNotes(aByRows, aFirst, aCount);
    end;
    for var area: TArea in cleared do
      for var row: TRowCT in RowEntries(area.Top, area.Bottom) do
        for var cell: TCellCT in row.C do
          if (TUtility.ColumnOf(cell.R) >= area.Left) and (TUtility.ColumnOf(cell.R) <= area.Right) then
            RemoveValue(cell);
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
  FreeAndNil(fTables);
  FreeAndNil(fTableRows);
  FreeAndNil(fPivots);
  for var sheet: TWorksheet in fWorkbook.fSheets do // other sheets' shared formulas may be plain now
    sheet.ForgetFormulas;
  FreeAndNil(fMerges);
  fWorkbook.fBook.ValueChanged;
  fWorkbook.fBook.FormulaChanged;
end;

procedure TWorksheet.RemoveValue(aCell: TCellCT);
begin
  if (aCell.T = stctS) and aCell.Present[@aCell.V] then
    fWorkbook.fBook.SharedStringReleased;
  if aCell.IsPresent('F') then
  begin
    if aCell.F.T <> stcftNormal then
      ForgetFormulas;
    aCell.Clear('F');
    fWorkbook.fBook.FormulaChanged;
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
  else if Uncovered(aRow, aColumn) and CanWrite(aRow, aColumn, aTarget) then
    CellForWriting(aRow, aColumn).V := TUtility.FloatText(aValue, ftDouble);
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
  var style: integer := EffectiveStyle(aRow, aColumn);
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
  var cell: TCellCT := CellForWriting(aRow, aColumn);
  cell.S := style;
  cell.V := TUtility.FloatText(serial, ftDouble);
end;

procedure TWorksheet.WriteText(aRow, aColumn: integer; const aValue: string; const aTarget: TRange);
begin
  if aValue.Length > TUtility.cMaxText then
    Refuse(aRow, aColumn, 'Value', Format('%d characters, Excel''s cells hold up to %d', [aValue.Length, TUtility.cMaxText]))
  else if Uncovered(aRow, aColumn) and CanWrite(aRow, aColumn, aTarget) then
  begin
    var index: integer := fWorkbook.fBook.SharedStringIndex(aValue);
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
  if Uncovered(aRow, aColumn) and CanWrite(aRow, aColumn, aTarget) then
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
  if Uncovered(aRow, aColumn) and CanWrite(aRow, aColumn, aTarget) then
  begin
    CellForWriting(aRow, aColumn).F.XmlValue := EncodeText(aText);
    fWorkbook.fBook.FormulaChanged;
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
  for var area: TArea in fArrays do
    if area.Overlaps(aRange.Area) and not aRange.Area.Contains(area) then
      why := 'part of an array formula (' + area.Address + '), which Excel changes only as a whole';
  for var area: TArea in fDataTables do
    if area.Overlaps(aRange.Area) then
      why := 'a data table, which Excel''s what-if analysis fills';
  for var area: TArea in fTableRows do
    if area.Overlaps(aRange.Area) then
      why := 'a table''s header or totals row (part of the table''s definition, which Calcite does not change yet)';
  if (aRange.RowCount > 1) or (aRange.ColumnCount > 1) then
    for var area: TArea in fTables do
      if area.Overlaps(aRange.Area) then
        why := 'a table, where Excel allows no array formula of several cells';
  for var area: TArea in fPivots do
    if area.Overlaps(aRange.Area) then
      why := 'a pivot table, which Excel builds again';
  for var area: TArea in FindMerges do
    if area.Overlaps(aRange.Area) then
      why := 'merged cells (' + area.Address + '), where Excel allows no array formula';
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
  formula.Ref := aRange.Area.CellsAddress;
  formula.XmlValue := EncodeText(text);
  ForgetFormulas;
  fWorkbook.fBook.FormulaChanged;
end;

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

procedure TWorksheet.ClearContents(const aRange: TRange);
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
    while (cellIndex < row.C.Count) and (TUtility.ColumnOf(row.C[cellIndex].R) <= aRange.fRight) do
    begin
      var cell: TCellCT := row.C[cellIndex];
      var column: integer := TUtility.ColumnOf(cell.R);
      var hasValue: boolean := cell.Present[@cell.V] or cell.IsPresent('F') or cell.IsPresent('Is');
      var area: TArea;
      if hasValue and MergedAt(row.R, column, area) and not aRange.Area.Contains(area) and
        ((integer(row.R) <> area.Top) or (column <> area.Left)) then
        hasValue := False; // covered, its area not cleared whole: as a write to it, nothing done
      if hasValue and not CanWrite(row.R, column, aRange) then
      begin
        Inc(cellIndex);
        Continue;
      end;
      if hasValue then
      begin
        Objects(True);
        RemoveValue(cell);
        fWorkbook.fBook.ValueChanged;
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

// a dynamic array whose formula now names #REF! gives #REF! alone, as Excel calculates it: its spill folded into its cell
procedure TWorksheet.FoldSpills(aMoves: TList<TFormulaMove>);
begin
  for var move: TFormulaMove in aMoves do
  begin
    var cell: TCellCT := move.Cell;
    var area: TArea;
    if (move.After = move.Before) or not move.After.Contains('#REF!') or (cell.F.T <> stcftArray) or (cell.Cm = 0) or
      not fWorkbook.fBook.IsDynamicArray(cell.Cm) or not TArea.TryParse(cell.F.Ref, area) then
      Continue;
    Objects(True);
    for var row: TRowCT in RowEntries(area.Top, area.Bottom) do
      for var i := row.C.Count - 1 downto 0 do
      begin
        var spilled: TCellCT := row.C[i];
        var column: integer := TUtility.ColumnOf(spilled.R);
        if (spilled = cell) or (column < area.Left) or (column > area.Right) then
          Continue;
        RemoveValue(spilled);
        if IsBare(spilled, ['S', 'Ph', 'ExtLst']) then
          row.Remove(spilled);
      end;
    cell.F.Ref := cell.R;
    cell.T := stctE;
    cell.V := '#REF!';
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
  else if fWorkbook.fBook.FormulasWritten then
    why := 'sheets are renamed before formulas are written: a formula may name the sheet'
  else
    why := fWorkbook.SheetNameError(aValue, Self);
  if not why.IsEmpty then
  begin
    fWorkbook.fIssues.Add(TIssueSeverity.isError, 'Rename', fName, why + ' - not renamed');
    Exit;
  end;
  for var entry: TSheetCT in fWorkbook.fBook.Package.EditPart<TWorkbookE>(fWorkbook.fBook.WorkbookPart).Sheets.Sheet do
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

procedure TWorkbook.FixedAreas(const aSheetPart: string; aTables, aTableRows, aPivots: TList<TArea>);
begin
  for var relationship: TRelationshipOoxml in fBook.Package.Relationships(aSheetPart) do
  begin
    var area: TArea;
    if relationship.&Type.EndsWith(cTable) then
    begin
      var table: TTableE := fBook.Package.Part<TTableE>(relationship.Part);
      if (table <> nil) and TArea.TryParse(table.Ref, area) then
      begin
        var whole: TArea := area;
        aTables.Add(whole);
        if table.HeaderRowCount > 0 then
        begin
          area.Bottom := whole.Top + integer(table.HeaderRowCount) - 1;
          aTableRows.Add(area);
        end;
        if table.TotalsRowCount > 0 then
        begin
          area.Top := whole.Bottom - integer(table.TotalsRowCount) + 1;
          area.Bottom := whole.Bottom;
          aTableRows.Add(area);
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
        aPivots.Add(area);
      end;
    end;
  end;
end;

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
    sheet.fPartName := sheets[i].Part;
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
  Result.fPartName := partName;
  Result.fFresh := True;
end;

// a part's own relationships part
function RelationshipsOf(const aPart: string): string;
begin
  var slash: integer := aPart.LastIndexOf('/');
  Result := aPart.Substring(0, slash + 1) + '_rels/' + aPart.Substring(slash + 1) + '.rels';
end;

// all checked and planned first, so a refusal changes nothing; then every other sheet's formulas, charts, names, tables'
// formulas and extensions, the names local to it, the views, its parts
procedure TWorksheet.Delete;
const
  cLastVisible = 'A workbook must contain at least one visible worksheet. To hide, delete, or move the selected sheet(s), ' +
    'you must first insert a new sheet or unhide a sheet that is already hidden.';
type
  // a formula of a table on another sheet (Formula), or of an extension's element kept as read (Index in XmlUnknown), changed
  TKeptMove = record
    Part: string;
    Sheet: TWorksheet;
    Formula: TTableFormulaCT;
    Extension: TXmlite;
    Index: integer;
    Text: string;
  end;
var
  book: TWorkbook;
  package: TPackageOoxml;
  map, cellsMap: TReferenceMap;
  why: string;
  kept: TList<TKeptMove>;

  procedure PlanTableFormula(aSheet: TWorksheet; const aPart: string; aFormula: TTableFormulaCT);
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

  procedure PlanExtensions(aSheet: TWorksheet);
  begin
    var objects: TWorksheetE := aSheet.Objects(False);
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

  // a <sheets> entry's tab selected: a worksheet's views or a chart sheet's
  procedure SelectTab(aEntry: TSheetCT);
  begin
    for var sheet: TWorksheet in book.fSheets do
      if sheet.SheetEntry = aEntry then
      begin
        var objects: TWorksheetE := sheet.Objects(False);
        if objects.IsPresent('SheetViews') then
          for var view: TSheetViewCT in objects.SheetViews.SheetView do
            if not view.TabSelected then
            begin
              sheet.Objects(True);
              view.TabSelected := True;
            end;
        Exit;
      end;
    for var relationship: TRelationshipOoxml in package.Relationships(book.fBook.WorkbookPart, cChartsheet) do
      if relationship.Id = aEntry.Id then
      begin
        var chartsheet: TChartsheetE := package.Part<TChartsheetE>(relationship.Part);
        if chartsheet <> nil then
          for var view: TChartsheetViewCT in chartsheet.SheetViews.SheetView do
            if not view.TabSelected then
            begin
              package.EditPart<TChartsheetE>(relationship.Part);
              view.TabSelected := True;
            end;
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
      names.Add(fPartName);
      parents.Add(book.fBook.WorkbookPart);
      found.Add(fPartName.ToUpper, True);
      for var cache: string in aCaches do
      begin
        names.Add(cache);
        parents.Add(book.fBook.WorkbookPart);
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
              ((queue[next] <> book.fBook.WorkbookPart) or (relationship.Part <> fPartName) and
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
  book := fWorkbook;
  package := book.fBook.Package;
  var entries: TSheetCTList := package.Part<TWorkbookE>(book.fBook.WorkbookPart).Sheets.Sheet;
  var entry: TSheetCT := SheetEntry;
  var index: integer := entries.IndexOf(entry);
  why := '';
  var visible: integer := 0;
  for var i := 0 to entries.Count - 1 do
    if (i <> index) and (entries[i].State = stssVisible) then
      Inc(visible);
  if GetVisible = svVeryHidden then
    why := 'a very hidden sheet, which Excel does not delete'
  else if visible = 0 then
    why := cLastVisible;
  for var relationship: TRelationshipOoxml in package.Relationships(fPartName) do
    if (why = '') and (relationship.&Type.EndsWith(cSlicer) or relationship.&Type.EndsWith(cTimeline)) then
      why := 'slicers or timelines, which Calcite does not remove yet';
  var sheets: TArray<string> := nil;
  for var sheet: TWorksheet in book.fSheets do
    sheets := sheets + [sheet.fName];
  map := TReferenceMap.SheetDeleted(fName, sheets);
  map.InName := True;
  for var relationship: TRelationshipOoxml in package.Relationships(fPartName, cTable) do
  begin
    var table: TTableE := package.Part<TTableE>(relationship.Part);
    if table <> nil then
      map.GoneTables := map.GoneTables + [string(table.Name)];
  end;
  cellsMap := map;
  cellsMap.InName := False;

  var others: TList<TWorksheet> := TList<TWorksheet>.Create;
  var moves: TObjectList<TList<TFormulaMove>> := TObjectList<TList<TFormulaMove>>.Create;
  var refs: TObjectList<TDictionary<cardinal, string>> := TObjectList<TDictionary<cardinal, string>>.Create;
  var texts: TList<TTextMove> := TList<TTextMove>.Create;
  var charts: TList<TChartMove> := TList<TChartMove>.Create;
  var caches: TList<string> := TList<string>.Create;
  kept := TList<TKeptMove>.Create;
  try
    for var sheet: TWorksheet in book.fSheets do
      if sheet <> Self then
        others.Add(sheet);
    if why = '' then
      for var sheet: TWorksheet in others do
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
      book.fBook.MappedNames(map, names, why);
    for var sheet: TWorksheet in others do
    begin
      PlanExtensions(sheet);
      for var relationship: TRelationshipOoxml in package.Relationships(sheet.fPartName, cTable) do
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
        var xml: TWorkbookE := package.Part<TWorkbookE>(book.fBook.WorkbookPart);
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

      book.fBook.WriteNames(names);
      var workbook: TWorkbookE := package.EditPart<TWorkbookE>(book.fBook.WorkbookPart);
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
      others[i].ApplyFormulas(moves[i], refs[i], False, True, 1, 0);
      others[i].FoldSpills(moves[i]);
    end;
    ShiftCharts(charts, True, 1, 0);
    for var move: TKeptMove in kept do
      if move.Formula <> nil then
      begin
        package.EditPart<TTableE>(move.Part);
        move.Formula.XmlValue := EncodeText(move.Text);
      end
      else
      begin
        move.Sheet.Objects(True);
        var item: TXmliteUnknown := move.Extension.XmlUnknown[move.Index];
        item.Xml := move.Text;
        move.Extension.XmlUnknown[move.Index] := item;
      end;

    var workbook: TWorkbookE := package.EditPart<TWorkbookE>(book.fBook.WorkbookPart);

    // the active sheet deleted: the next visible one (else the one before) active and selected, as Excel does
    var active: integer := -1;
    for var i := index + 1 to entries.Count - 1 do
      if (active < 0) and (entries[i].State = stssVisible) then
        active := i;
    for var i := index - 1 downto 0 do
      if (active < 0) and (entries[i].State = stssVisible) then
        active := i;
    if not workbook.IsPresent('BookViews') and (index = 0) then // the first sheet is active without a view
      workbook.BookViews.WorkbookView.Add(TBookViewCT.Create);
    if workbook.IsPresent('BookViews') then
      for var view: TBookViewCT in workbook.BookViews.WorkbookView do
      begin
        var tab: integer := view.ActiveTab;
        if tab = index then
        begin
          tab := active;
          SelectTab(entries[active]);
        end;
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
      for var sheet: TWorksheet in others do
        for var pivot: TRelationshipOoxml in package.Relationships(sheet.fPartName, cPivotTable) do
          for var cache: TRelationshipOoxml in package.Relationships(pivot.Part, cPivotCacheDefinition) do
            used.Add(cache.Part.ToUpper);
      for var pivot: TRelationshipOoxml in package.Relationships(fPartName, cPivotTable) do
        for var cache: TRelationshipOoxml in package.Relationships(pivot.Part, cPivotCacheDefinition) do
          if not used.Contains(cache.Part.ToUpper) and not caches.Contains(cache.Part) then
            caches.Add(cache.Part);
    finally
      used.Free;
    end;
    if workbook.IsPresent('PivotCaches') then
    begin
      for var relationship: TRelationshipOoxml in package.Relationships(book.fBook.WorkbookPart, cPivotCacheDefinition) do
        if caches.Contains(relationship.Part) then
          for var i := workbook.PivotCaches.PivotCache.Count - 1 downto 0 do
            if workbook.PivotCaches.PivotCache[i].Id = relationship.Id then
              workbook.PivotCaches.PivotCache.Delete(i);
      if workbook.PivotCaches.PivotCache.Count = 0 then
        workbook.Clear('PivotCaches');
    end;

    for var row: TRowCT in Objects(False).SheetData.Row do
      for var cell: TCellCT in row.C do
        if (cell.T = stctS) and cell.Present[@cell.V] then
          book.fBook.SharedStringReleased;
    RemoveParts(caches);
    entries.Delete(index);
    book.fBook.ValueChanged;
    book.fBook.FormulaChanged;
    for var sheet: TWorksheet in others do
      sheet.ForgetFormulas;
  finally
    kept.Free;
    caches.Free;
    charts.Free;
    texts.Free;
    refs.Free;
    moves.Free;
    others.Free;
  end;
  book.fSheets.fList.Remove(Self);
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
