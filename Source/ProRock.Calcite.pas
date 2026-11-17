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
    // Text is stored as text: '=A1' is not a formula, '00123' not a number. Empty or '' clears the cell
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
  end;

  TWorksheet = class
  private
    fWorkbook: TWorkbook;
    fName: string;
    fPartName: string;
    fPrepared: boolean;
    // found on the first write: the areas of array formulas, tables' header and totals rows, pivot tables
    fArrays, fTableRows, fPivots: TList<TRange>;
    fLockedWritten: boolean; // reported once a sheet

    function GetXml: TWorksheetE;
    function Objects(aEdit: boolean): TWorksheetE;
    function FindRow(aSheet: TWorksheetE; aRow: integer; out aIndex: integer): boolean;
    function FindCell(aRow, aColumn: integer): TCellCT;
    function EffectiveStyle(aRow, aColumn: integer): cardinal;
    function CellValue(aCell: TCellCT; out aValue: Variant): TCellValueType;
    function CanWrite(aRow, aColumn: integer): boolean;
    function CellForWriting(aRow, aColumn: integer): TCellCT;
    procedure RemoveValue(aCell: TCellCT);
    procedure Refuse(aRow, aColumn: integer; const aCode, aWhy: string);
    function IsLocked(aRow, aColumn: integer): boolean;
    procedure WriteNumber(aRow, aColumn: integer; aValue: Double);
    procedure WriteDate(aRow, aColumn: integer; aValue: TDateTime);
    procedure WriteText(aRow, aColumn: integer; const aValue: string);
    procedure WriteBoolean(aRow, aColumn: integer; aValue: boolean);
    procedure WriteValue(aRow, aColumn: integer; const aValue: Variant);
    procedure ClearContents(const aRange: TRange);
    function MakeRange(aTop, aLeft, aBottom, aRight: integer): TRange;
    function GetRange(const aAddress: string): TRange;
    function GetCells(aRow, aColumn: integer): TRange;
    function GetCellsByLetters(aRow: integer; const aColumn: string): TRange;
    function GetUsedRange: TRange;
  public
    destructor Destroy; override;

    // the generated objects; once taken, the sheet is saved from them
    property Xml: TWorksheetE read GetXml;

    property Workbook: TWorkbook read fWorkbook;
    property Name: string read fName;
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
    fIssues: TIssues;

    class procedure Swap<T>(var aLeft, aRight: T); static; inline;
    procedure Close;
    function Load: boolean;
    function Fail(const aCode, aError: string): boolean;
    function ReadXml(aXml: TXmlite; const aPart: string; const aBytes: TBytes): boolean;
    function CanWrite: boolean;
    function Write(aStream: TStream): boolean;
    procedure Exchange(aOther: TWorkbook);
    function PartIndex(const aName: string): integer;
    procedure FixedAreas(const aSheetPart: string; aTableRows, aPivots: TList<TRange>);
    function AddPart(const aName: string; aClass: TXmliteClass): string;
    function NewPart(const aRelationship, aTarget, aContentType: string; aXml: TXmlite): string;
    // ReadPart leaves the part as its bytes, EditPart saves it from its objects
    function ReadPart(const aName: string): TXmlite;
    function EditPart(const aName: string): TXmlite;

    function IsLockedStyle(aStyle: cardinal): boolean;
    procedure ValueChanged;
    procedure FormulaRemoved;
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
    constructor Create;
    destructor Destroy; override;

    // the generated objects (nil when there are none); once taken, the part is saved from them
    property Xml: TWorkbookE read GetXml;
    property XmlSharedStrings: TSstE read GetXmlSharedStrings;
    property XmlStyles: TStyleSheetE read GetXmlStyles;

    // False: Error says why, and the workbook open before stays open
    function Open(const aFileName: string): boolean; overload;
    function Open(aStream: TStream): boolean; overload;
    // Save: to the file opened. False: Error says why, and the file stays as it was
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

uses System.IOUtils, System.Math, System.Variants, System.DateUtils, System.TypInfo,
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

  cMaxRow = 1048576;
  cMaxColumn = 16384;
  cMaxText = 32767;

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

procedure TRange.SetValue(const aValue: Variant);
begin
  if not VarIsArray(aValue) then
  begin
    for var row := fTop to fBottom do
      for var column := fLeft to fRight do
        fSheet.WriteValue(row, column, aValue);
    Exit;
  end;
  // an array as Excel takes it: its shape the range's (one dimension: a row)
  var rows, columns: integer;
  var twoDimensions: boolean := VarArrayDimCount(aValue) = 2;
  if twoDimensions then
  begin
    rows := VarArrayHighBound(aValue, 1) - VarArrayLowBound(aValue, 1) + 1;
    columns := VarArrayHighBound(aValue, 2) - VarArrayLowBound(aValue, 2) + 1;
  end
  else if VarArrayDimCount(aValue) = 1 then
  begin
    rows := 1;
    columns := VarArrayHighBound(aValue, 1) - VarArrayLowBound(aValue, 1) + 1;
  end
  else
    raise EArgumentException.Create('An array for a range has one or two dimensions');
  if (rows <> RowCount) or (columns <> ColumnCount) then
    raise EArgumentException.CreateFmt('An array of %d x %d for %s (%d x %d)', [rows, columns, Address, RowCount, ColumnCount]);
  for var row := 0 to rows - 1 do
    for var column := 0 to columns - 1 do
      if twoDimensions then
        fSheet.WriteValue(fTop + row, fLeft + column,
          aValue[VarArrayLowBound(aValue, 1) + row, VarArrayLowBound(aValue, 2) + column])
      else
        fSheet.WriteValue(fTop + row, fLeft + column, aValue[VarArrayLowBound(aValue, 1) + column]);
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

{ TWorksheet }

destructor TWorksheet.Destroy;
begin
  fPivots.Free;
  fTableRows.Free;
  fArrays.Free;
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

// False: a shared or an array formula holds the cell (formulas are not written yet), a table's header or totals row (the
// table's own definition, a header its column's name in formulas), a pivot table (Excel builds it from its cache)
function TWorksheet.CanWrite(aRow, aColumn: integer): boolean;
begin
  var cell: TCellCT := FindCell(aRow, aColumn);
  if (cell <> nil) and cell.IsPresent('F') and (cell.F.T <> stcftNormal) then
  begin
    Refuse(aRow, aColumn, 'Formula', 'part of a shared or array formula, which Calcite does not change yet');
    Exit(False);
  end;
  if fArrays = nil then
  begin
    fArrays := TList<TRange>.Create;
    for var row: TRowCT in Objects(False).SheetData.Row do
      for var rowCell: TCellCT in row.C do
        if rowCell.IsPresent('F') and (rowCell.F.T in [stcftArray, stcftDataTable]) then
        begin
          var area: TRange;
          if ParseAddress(rowCell.F.Ref, area.fTop, area.fLeft, area.fBottom, area.fRight) then
            fArrays.Add(area);
        end;
    fTableRows := TList<TRange>.Create;
    fPivots := TList<TRange>.Create;
    fWorkbook.FixedAreas(fPartName, fTableRows, fPivots);
  end;
  for var area: TRange in fArrays do
    if (aRow >= area.fTop) and (aRow <= area.fBottom) and (aColumn >= area.fLeft) and (aColumn <= area.fRight) then
    begin
      Refuse(aRow, aColumn, 'Formula', 'part of an array formula, which Calcite does not change yet');
      Exit(False);
    end;
  for var area: TRange in fTableRows do
    if (aRow >= area.fTop) and (aRow <= area.fBottom) and (aColumn >= area.fLeft) and (aColumn <= area.fRight) then
    begin
      Refuse(aRow, aColumn, 'TableRow',
        'a table''s header or totals row (part of the table''s definition, which Calcite does not change yet)');
      Exit(False);
    end;
  for var area: TRange in fPivots do
    if (aRow >= area.fTop) and (aRow <= area.fBottom) and (aColumn >= area.fLeft) and (aColumn <= area.fRight) then
    begin
      Refuse(aRow, aColumn, 'PivotTable', 'part of a pivot table, which Excel builds again');
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
    aCell.Clear('F');
    fWorkbook.FormulaRemoved;
  end;
  aCell.Clear('Is');
  aCell.Clear(@aCell.V);
  aCell.Clear(@aCell.T);
  // cell and value metadata (dynamic arrays, rich values) belong to the value
  aCell.Clear(@aCell.Cm);
  aCell.Clear(@aCell.Vm);
end;

procedure TWorksheet.WriteNumber(aRow, aColumn: integer; aValue: Double);
begin
  if IsNan(aValue) or IsInfinite(aValue) then
    Refuse(aRow, aColumn, 'Value', 'Excel holds no NaN or infinity')
  else if CanWrite(aRow, aColumn) then
    CellForWriting(aRow, aColumn).V := FloatText(aValue, ftDouble);
end;

procedure TWorksheet.WriteDate(aRow, aColumn: integer; aValue: TDateTime);
begin
  var serial: Double;
  if not DateToSerial(aValue, fWorkbook.Date1904, serial) then
  begin
    Refuse(aRow, aColumn, 'Value', 'a date before the first one Excel has (' + DateToISO8601(aValue) + ')');
    Exit;
  end;
  if not CanWrite(aRow, aColumn) then
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

procedure TWorksheet.WriteText(aRow, aColumn: integer; const aValue: string);
begin
  if aValue.Length > cMaxText then
    Refuse(aRow, aColumn, 'Value', Format('%d characters, Excel''s cells hold up to %d', [aValue.Length, cMaxText]))
  else if CanWrite(aRow, aColumn) then
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

procedure TWorksheet.WriteBoolean(aRow, aColumn: integer; aValue: boolean);
begin
  if CanWrite(aRow, aColumn) then
  begin
    var cell: TCellCT := CellForWriting(aRow, aColumn);
    cell.T := stctB;
    cell.V := IntToStr(Ord(aValue));
  end;
end;

procedure TWorksheet.WriteValue(aRow, aColumn: integer; const aValue: Variant);
begin
  case VarType(aValue) of
    varEmpty, varNull:
      ClearContents(MakeRange(aRow, aColumn, aRow, aColumn));
    varSmallint, varInteger, varShortInt, varByte, varWord, varLongWord, varInt64, varUInt64, varSingle, varDouble, varCurrency:
      WriteNumber(aRow, aColumn, aValue);
    varDate:
      WriteDate(aRow, aColumn, VarToDateTime(aValue));
    varBoolean:
      WriteBoolean(aRow, aColumn, aValue);
    varOleStr, varString, varUString:
      if string(aValue) = '' then // as in Excel
        ClearContents(MakeRange(aRow, aColumn, aRow, aColumn))
      else
        WriteText(aRow, aColumn, aValue);
  else
    raise EArgumentException.CreateFmt('A cell takes a number, a date, a string or a Boolean, not a Variant of type %d',
      [VarType(aValue)]);
  end;
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
      if hasValue and not CanWrite(row.R, column) then
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

constructor TWorkbook.Create;
begin
  inherited;
  fParts := TObjectDictionary<string, TPart>.Create([doOwnsValues]);
  fSheets := TWorksheets.Create;
  fDropped := TList<string>.Create;
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
  var opened: TWorkbook := TWorkbook.Create;
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
  Swap<TIssues>(fIssues, aOther.fIssues);
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
procedure TWorkbook.FixedAreas(const aSheetPart: string; aTableRows, aPivots: TList<TRange>);
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

// a part of the workbook's, with its relationship and content type; '' (aXml freed) when the package has no content types
function TWorkbook.NewPart(const aRelationship, aTarget, aContentType: string; aXml: TXmlite): string;
begin
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

  var contentType: TOverrideE := TTypesE(EditPart(fContentTypesPart)).Add<TOverrideE>;
  contentType.PartName := '/' + Result;
  contentType.ContentType := aContentType;
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

// the calculation chain is Excel's cache: a stale entry is its repair prompt, so it goes and Excel builds a new one
procedure TWorkbook.FormulaRemoved;
begin
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
    fSharedStringsPart := NewPart(cSharedStrings, 'sharedStrings.xml', cSharedStringsType, added);
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
    Exit(Fail('NoFileName', 'The workbook has no file to save to (it was opened from a stream): use SaveAs'));
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
