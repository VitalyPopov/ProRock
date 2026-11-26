unit ProRock.Calcite.Xlsx;

// the xlsx backend: a workbook's package and the parts every sheet shares, with the caches over them (internal)

interface

uses System.SysUtils, System.Classes, System.Generics.Collections, System.UITypes, ProRock.Xmlite, ProRock.Office.Ooxml,
  ProRock.Xmlite.Schema.Ooxml.Sml, ProRock.Calcite.Utility, ProRock.Calcite.Aspects;

const
  // relationship types end in these names - Transitional and Strict differ only before them
  cOfficeDocument = '/officeDocument';
  cTheme = '/theme';
  cWorksheet = '/worksheet';
  cSharedStrings = '/sharedStrings';
  cStyles = '/styles';
  cCalcChain = '/calcChain';
  cSheetMetadata = '/sheetMetadata';
  cTable = '/table';
  cPivotTable = '/pivotTable';
  cPivotCacheDefinition = '/pivotCacheDefinition';
  cDrawing = '/drawing';
  cChart = '/chart';
  cChartsheet = '/chartsheet';
  cChartEx = '/chartEx';
  cComments = '/comments';
  cThreadedComment = '/threadedComment';
  cSlicer = '/slicer';
  cTimeline = '/timeline';
  cContentTypes = '[Content_Types].xml';
  cSharedStringsType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml';
  cWorksheetType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml';

type
  // Calcite's own: a sheet's VML drawing (its notes' boxes), whose <xml> root no schema has; the shapes come in XmlAny
  [TXmliteAnyElement]
  [TName('xml')]
  TVmlDrawing = class(TXmlite);

  // a worksheet of workbook.xml as Load found it
  TXlsxSheetEntry = record
    Name, Part: string;
  end;

  // a workbook's xlsx storage; Package and WorkbookPart for the sheets' own parts until the sheet backend has them
  TXlsxBook = class
  private
    fPackage: TPackageOoxml;
    fWorkbookPart, fSharedStringsPart, fStylesPart, fCalcChainPart, fThemePart: string;
    fStrings: TDictionary<string, integer>; // shared strings by text, built on the first write
    // cellXfs, fonts, fills, borders by content (the items themselves, by ContentComparer), built on the first need
    fStyleKeys: TDictionary<TXfCT, integer>;
    fFontKeys: TDictionary<TFontCT, integer>;
    fFillKeys: TDictionary<TFillCT, integer>;
    fBorderKeys: TDictionary<TBorderCT, integer>;
    fThemeColors: TArray<integer>; // the theme's 12 in the order styles number them, read on the first need
    fDateStyleIds: TDictionary<UInt64, integer>; // DateStyle's answers: a style and a format, the style with it
    fDateStyles: TDictionary<cardinal, boolean>;
    fFormatIds: TDictionary<string, integer>; // FormatId's answers by the code asked for
    fFormats: TDictionary<cardinal, TCellFormat>; // FormatOf's answers by style
    fValuesChanged: boolean;
    fFormulasWritten: boolean;

    function ItemIndex<T: TXmlite>(aItems: TObjectList<T>; var aKeys: TDictionary<T, integer>; aWanted: T): integer;
    function XfIndex(aWanted: TXfCT): integer;
    function HasStyles: boolean;
    function ChangedAspects(aStyle: cardinal; aAspects: TAspects; aSides: TCellSides; const aFormat: TCellFormat): TAspects;
    function ChangedFont(aFont: cardinal; aAspects: TAspects; const aFormat: TCellFormat): integer;
    function ChangedFill(aFill: cardinal; aColor: TColor): integer;
    function ChangedBorder(aBorder: cardinal; aAspects: TAspects; aSides: TCellSides; const aFormat, aOld: TCellFormat):
      integer;
    function BorderAt(aBorder: cardinal): TBorderCT;
    function ThemeColor(aIndex: cardinal): integer;
    function StoredFormatId(const aCode: string): integer;
    function FormatCode(aStyle: cardinal): string;
    function StyleXf(aStyle: cardinal): TXfCT;
    function StyleFont(aStyle: cardinal): TFontCT;
    function StyleFill(aStyle: cardinal): TFillCT;
    function StyleBorder(aStyle: cardinal): TBorderCT;
    function ColorOf(aColor: TColorCT; aDefault: TColor): TColor;
    function ReadFormat(aStyle: cardinal): TCellFormat;
    procedure Forget;
  public
    constructor Create;
    destructor Destroy; override;

    procedure New;
    // aStream, or the file when it is nil; False: Package.Error says why
    function Open(const aFileName: string; aStream: TStream): boolean;
    // the main part and the shared ones found, the worksheets in the workbook's order; False with an issue's code and text
    function Load(out aSheets: TArray<TXlsxSheetEntry>; out aCode, aError: string): boolean;
    // the package has content types: parts can be added
    function CanAddParts: boolean;
    // .xlsx, .xlsm, .xltx or .xltm by the main part's content type; '' - none of them
    function Kind: string;

    // workbook.xml's sheets, chart sheets too
    function SheetCount: integer;
    // the sheet named aName (case ignored, as in Excel) other than aExcept; '' - none
    function SheetNamed(const aName, aExcept: string): string;
    // a worksheet part after the others and its entry; its part's name, '' when the package refuses it (an issue says why)
    function AddSheet(const aName: string): string;
    // the sheet's <sheet>, nil when there is none
    function SheetEntry(const aName: string): TSheetCT;
    // from 0, chart sheets counted; -1 when there is none
    function SheetIndex(const aName: string): integer;
    // in the workbook's order, chart sheets too
    function SheetStates: TArray<TSheetVisibility>;
    procedure SetSheetState(const aName: string; aValue: TSheetVisibility);
    procedure RenameSheet(const aName, aNewName: string);
    // the views showing sheet aFrom (the first one without a view: one added) show aTo, their first tab not after it; False
    // when none showed aFrom
    function MoveActiveSheet(aFrom, aTo: integer): boolean;
    // the views of the chart sheet at aIndex (workbook order) with their tab selected or not; nothing for a worksheet
    procedure SetChartTabSelected(aIndex: integer; aValue: boolean);

    function IsDynamicArray(aCellMetadata: cardinal): boolean;
    function IsLockedStyle(aStyle: cardinal): boolean;
    procedure ValueChanged;
    procedure FormulaChanged;
    function Date1904: boolean;
    function SharedString(aIndex: integer): string;
    function SharedStringIndex(const aText: string): integer;
    procedure SharedStringReleased;
    function IsDateStyle(aStyle: cardinal): boolean;
    // aStyle with aFormat's aspects (a border's on aSides) that differ from its own written, found in cellXfs by content or
    // added; aStyle itself when none differs; -1 when there are no styles
    function ChangedStyle(aStyle: cardinal; aAspects: TAspects; aSides: TCellSides; const aFormat: TCellFormat): integer;
    function DateStyle(aStyle: cardinal; aFormat: integer): integer;
    function FormatId(const aCode: string): integer;
    // a style as Excel reads it (one beyond cellXfs as the first); kept
    function FormatOf(aStyle: cardinal): TCellFormat;

    // the parts handed to the user (Workbook.Xlsx), each nil when the file has none; every cache is dropped (Forget)
    function EditWorkbook: TWorkbookE;
    function EditSharedStrings: TSstE;
    function EditStyles: TStyleSheetE;

    // every defined name's text through aMap (by the names' index; nil when there are none). False with aWhy when one naming
    // aMap's sheet does not read
    function MappedNames(const aMap: TReferenceMap; out aChanged: TArray<string>; out aWhy: string): boolean;
    // the names' texts MappedNames gave written, those that changed
    procedure WriteNames(const aChanged: TArray<string>);

    property Package: TPackageOoxml read fPackage;
    property WorkbookPart: string read fWorkbookPart;
    // a formula was written since Open or New (a sheet's rename is refused then: a formula may name it)
    property FormulasWritten: boolean read fFormulasWritten;
  end;

// ST_Xstring: a character XML cannot hold is written as _xHHHH_, and so is an underscore that would read as one
function DecodeText(const aText: string): string;
function EncodeText(const aText: string): string;
// a shared string or an inline one: plain text, or rich text in runs
function RichText(aItem: TRstCT): string;
// FFRRGGBB (or RRGGBB) as BGR
function RgbValue(const aHex: string): integer;

implementation

uses System.Math, System.DateUtils, System.Zip, ProRock.Calcite.Formulas, ProRock.Calcite.Formats,
  ProRock.Xmlite.Schema.Ooxml.DmlMain;

type
  {$REGION 'ProRock.Xmlite.Schema.Ooxml types aliases'}
  // DrawingML has ones of these names too
  TColorCT = ProRock.Xmlite.Schema.Ooxml.Sml.TColorCT;
  TFillCT = ProRock.Xmlite.Schema.Ooxml.Sml.TFillCT;
  TNumFmtCT = ProRock.Xmlite.Schema.Ooxml.Sml.TNumFmtCT;
  {$ENDREGION}

const
  cAutomaticIndex = 64; // indexed: the system's text color, Excel's automatic
  // each style as Excel reads it: LineStyle and Weight
  cBorderLines: array[TBorderStyleST] of TLineStyle = (lsNone, lsContinuous, lsContinuous, lsDash, lsDot, lsContinuous,
    lsDouble, lsContinuous, lsDash, lsDashDot, lsDashDot, lsDashDotDot, lsDashDotDot, lsSlantDashDot);
  cBorderWeights: array[TBorderStyleST] of TBorderWeight = (bwThin, bwThin, bwMedium, bwThin, bwThin, bwThick, bwThick,
    bwHairline, bwMedium, bwThin, bwMedium, bwThin, bwMedium, bwMedium);
  cUnderlines: array[TUnderlineValuesST] of TUnderline = (ulSingle, ulDouble, ulSingleAccounting, ulDoubleAccounting, ulNone);
  cUnderlineValues: array[TUnderline] of TUnderlineValuesST = (stuvNone, stuvSingle, stuvDouble, stuvSingleAccounting,
    stuvDoubleAccounting);
  cFontAspects = [asFontName, asFontSize, asFontColor, asBold, asItalic, asStrikethrough, asUnderline];
  cAlignmentAspects = [asHorizontalAlignment, asVerticalAlignment, asWrapText];

function IsOn(aList: TBooleanPropertyCTList): boolean;
begin
  Result := (aList.Count > 0) and aList[0].Val;
end;

function SideName(aEdge: TBorderEdge): string;
begin
  case aEdge of
    beLeft: Result := 'Left';
    beTop: Result := 'Top';
    beBottom: Result := 'Bottom';
  else
    Result := 'Right';
  end;
end;

function SideOf(aBorder: TBorderCT; aEdge: TBorderEdge): TBorderPrCT;
begin
  case aEdge of
    beLeft: Result := aBorder.Left;
    beTop: Result := aBorder.Top;
    beBottom: Result := aBorder.Bottom;
  else
    Result := aBorder.Right;
  end;
end;

function DrawnSide(aBorder: TBorderCT; aEdge: TBorderEdge): TBorderPrCT;
begin
  Result := nil;
  if (aBorder <> nil) and aBorder.IsPresent(SideName(aEdge)) then
  begin
    Result := SideOf(aBorder, aEdge);
    if Result.Style = stbsNone then
      Result := nil;
  end;
end;

// clDefault: Excel's automatic
procedure WriteColor(aColor: TColorCT; aValue: TColor);
begin
  aColor.Clear;
  if aValue = TColors.SysDefault then
  begin
    aColor.Indexed := cAutomaticIndex;
    aColor.SetPresent(@aColor.Indexed);
  end
  else
    aColor.Rgb := Format('FF%.2X%.2X%.2X', [aValue and $FF, aValue shr 8 and $FF, aValue shr 16 and $FF]);
end;

// aValue against a stored color Excel shows as aShown: automatic (clDefault) is not black
function ColorDiffers(aColor: TColorCT; aShown, aValue: TColor): boolean;
begin
  var automatic: boolean := (aColor = nil) or aColor.Auto or not aColor.Present[@aColor.Rgb] and
    not aColor.Present[@aColor.Theme] and (not aColor.Present[@aColor.Indexed] or (aColor.Indexed = cAutomaticIndex));
  if aValue = TColors.SysDefault then
    Result := not automatic
  else
    Result := automatic or (aShown <> aValue);
end;

procedure WriteFlag(aList: TBooleanPropertyCTList; aValue: boolean);
begin
  aList.Clear;
  if aValue then
  begin
    var item: TBooleanPropertyCT := TBooleanPropertyCT.Create;
    item.Val := True;
    aList.Add(item);
  end;
end;

procedure WriteUnderline(aFont: TFontCT; aValue: TUnderline);
begin
  aFont.U.Clear;
  if aValue = ulNone then
    Exit;
  var item: TUnderlinePropertyCT := TUnderlinePropertyCT.Create;
  item.Val := cUnderlineValues[aValue]; // single, the default, is written as <u/>
  aFont.U.Add(item);
end;

// the stored style of a pair Applied left
function PairStyle(const aLine: TBorderLine): TBorderStyleST;
begin
  for var style := Succ(stbsNone) to High(TBorderStyleST) do
    if (cBorderLines[style] = aLine.LineStyle) and (cBorderWeights[style] = aLine.Weight) then
      Exit(style);
  Result := stbsThin;
end;

// what a side's write changes: aLine its line (style and weight), aColor its color - ColorDiffers' rule, any color on a
// side with no line
procedure SideChanges(aBorder: TBorderCT; aSide: TCellSide; aAspects: TAspects; const aOld, aNew: TBorderLine;
  out aLine, aColor: boolean);
begin
  aLine := (aOld.LineStyle <> aNew.LineStyle) or (aNew.LineStyle <> lsNone) and (aOld.Weight <> aNew.Weight);
  aColor := False;
  if (aNew.LineStyle = lsNone) or not (asBorderColor in aAspects) then
    Exit;
  var drawn: TBorderPrCT := DrawnSide(aBorder, aSide);
  if drawn = nil then
    aColor := True
  else if drawn.IsPresent('Color') then
    aColor := ColorDiffers(drawn.Color, aOld.Color, aNew.Color)
  else
    aColor := ColorDiffers(nil, aOld.Color, aNew.Color);
end;


{$REGION 'xlsx text and built-in formats'}

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

function RichText(aItem: TRstCT): string;
begin
  Result := aItem.T;
  for var run: TREltCT in aItem.R do
    Result := Result + string(run.T);
  Result := DecodeText(Result);
end;

function RgbValue(const aHex: string): integer;
begin
  var value: integer := StrToIntDef('$' + aHex.Substring(Max(0, aHex.Length - 6)), 0);
  Result := value shr 16 and $FF or value and $FF00 or (value and $FF) shl 16;
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

// Excel's built-in date and time formats, and a format code with a date or time code (IsDateCode)
function IsDateFormat(aId: cardinal; aStyles: TStyleSheetE): boolean;
begin
  if aStyles.IsPresent('NumFmts') then
    for var numberFormat: TNumFmtCT in aStyles.NumFmts.NumFmt do
      if numberFormat.NumFmtId = aId then
        Exit(IsDateCode(DecodeText(numberFormat.FormatCode)));
  // 27-36 and 50-58: the East Asian ones
  Result := (aId <= 58) and (Byte(aId) in [14 .. 22, 27 .. 36, 45 .. 47, 50 .. 58]);
end;

{$ENDREGION}

{ TXlsxBook }

constructor TXlsxBook.Create;
begin
  inherited Create;
  fPackage := TPackageOoxml.Create;
end;

destructor TXlsxBook.Destroy;
begin
  fPackage.Free;
  fStrings.Free;
  fStyleKeys.Free;
  fFontKeys.Free;
  fFillKeys.Free;
  fBorderKeys.Free;
  fDateStyleIds.Free;
  fDateStyles.Free;
  fFormatIds.Free;
  fFormats.Free;
  inherited;
end;

// Excel's new workbook, read as a file would be: Transitional, no theme; styles with fonts, fills and borders (without them
// Excel refuses the file)
procedure TXlsxBook.New;
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
end;

function TXlsxBook.Open(const aFileName: string; aStream: TStream): boolean;
begin
  if aStream = nil then
    Result := fPackage.Open(aFileName)
  else
    Result := fPackage.Open(aStream);
end;

function TXlsxBook.Load(out aSheets: TArray<TXlsxSheetEntry>; out aCode, aError: string): boolean;
begin
  aSheets := nil;
  aCode := 'NotWorkbook';
  aError := '';
  // the main part is found, not assumed (xl/workbook.xml in Excel's files)
  for var relationship: TRelationshipOoxml in fPackage.Relationships('', cOfficeDocument) do
    fWorkbookPart := relationship.Part;
  if fWorkbookPart.IsEmpty then
  begin
    aError := 'Not an Office document: the package names no main part';
    Exit(False);
  end;
  var workbook: TWorkbookE := fPackage.Part<TWorkbookE>(fWorkbookPart);
  var relationships: TArray<TRelationshipOoxml> := fPackage.Relationships(fWorkbookPart);
  if Length(relationships) = 0 then
  begin
    aError := Format('%s is not a workbook: it has no relationships', [fWorkbookPart]);
    Exit(False);
  end;
  for var relationship: TRelationshipOoxml in relationships do
    if relationship.&Type.EndsWith(cSharedStrings) then
      fSharedStringsPart := relationship.Part
    else if relationship.&Type.EndsWith(cStyles) then
      fStylesPart := relationship.Part
    else if relationship.&Type.EndsWith(cCalcChain) then
      fCalcChainPart := relationship.Part
    else if relationship.&Type.EndsWith(cTheme) then
      fThemePart := relationship.Part;

  for var sheetEntry: TSheetCT in workbook.Sheets.Sheet do
    for var relationship: TRelationshipOoxml in relationships do
      if (relationship.Id = sheetEntry.Id) and relationship.&Type.EndsWith(cWorksheet) then
      begin
        if relationship.Part.IsEmpty then
        begin
          aCode := 'NoSheetPart';
          aError := Format('The sheet "%s" has no part (%s)', [sheetEntry.Name, relationship.Target]);
          Exit(False);
        end;
        SetLength(aSheets, Length(aSheets) + 1);
        aSheets[High(aSheets)].Name := sheetEntry.Name;
        aSheets[High(aSheets)].Part := relationship.Part;
      end;
  aCode := '';
  Result := True;
end;

function TXlsxBook.CanAddParts: boolean;
begin
  Result := fPackage.HasPart(cContentTypes);
end;

function TXlsxBook.Kind: string;
const
  cTypes = 'application/vnd.openxmlformats-';
begin
  var contentType: string := fPackage.ContentType(fWorkbookPart);
  Result := '';
  if contentType = cTypes + 'officedocument.spreadsheetml.sheet.main+xml' then
    Result := '.xlsx'
  else if contentType = 'application/vnd.ms-excel.sheet.macroEnabled.main+xml' then
    Result := '.xlsm'
  else if contentType = cTypes + 'officedocument.spreadsheetml.template.main+xml' then
    Result := '.xltx'
  else if contentType = 'application/vnd.ms-excel.template.macroEnabled.main+xml' then
    Result := '.xltm';
end;

function TXlsxBook.SheetCount: integer;
begin
  Result := fPackage.Part<TWorkbookE>(fWorkbookPart).Sheets.Sheet.Count;
end;

function TXlsxBook.SheetNamed(const aName, aExcept: string): string;
begin
  for var entry: TSheetCT in fPackage.Part<TWorkbookE>(fWorkbookPart).Sheets.Sheet do
    if AnsiSameText(entry.Name, aName) and (entry.Name <> aExcept) then
      Exit(entry.Name);
  Result := '';
end;

function TXlsxBook.AddSheet(const aName: string): string;
begin
  var folder: string := fWorkbookPart.Substring(0, fWorkbookPart.LastIndexOf('/') + 1);
  var number: integer := 0;
  var target: string;
  repeat
    Inc(number);
    target := 'worksheets/sheet' + IntToStr(number) + '.xml';
  until not fPackage.HasPart(folder + target);
  var id: string;
  Result := fPackage.AddPart(fWorkbookPart, cWorksheet, target, cWorksheetType, TWorksheetE.Create, id);
  if Result.IsEmpty then
    Exit;

  var workbook: TWorkbookE := fPackage.EditPart<TWorkbookE>(fWorkbookPart);
  var sheetId: cardinal := 0;
  for var entry: TSheetCT in workbook.Sheets.Sheet do
    if entry.SheetId > sheetId then
      sheetId := entry.SheetId;
  var added: TSheetCT := workbook.Sheets.Add<TSheetCT>;
  added.Name := aName;
  added.SheetId := sheetId + 1;
  added.Id := id;
end;

function TXlsxBook.SheetEntry(const aName: string): TSheetCT;
begin
  for var entry: TSheetCT in fPackage.Part<TWorkbookE>(fWorkbookPart).Sheets.Sheet do
    if entry.Name = aName then
      Exit(entry);
  Result := nil;
end;

function TXlsxBook.SheetIndex(const aName: string): integer;
begin
  Result := fPackage.Part<TWorkbookE>(fWorkbookPart).Sheets.Sheet.IndexOf(SheetEntry(aName));
end;

function TXlsxBook.SheetStates: TArray<TSheetVisibility>;
begin
  var entries: TSheetCTList := fPackage.Part<TWorkbookE>(fWorkbookPart).Sheets.Sheet;
  SetLength(Result, entries.Count);
  for var i := 0 to entries.Count - 1 do
    case entries[i].State of
      stssHidden: Result[i] := svHidden;
      stssVeryHidden: Result[i] := svVeryHidden;
    else
      Result[i] := svVisible;
    end;
end;

procedure TXlsxBook.SetSheetState(const aName: string; aValue: TSheetVisibility);
const
  cStates: array[TSheetVisibility] of TSheetStateST = (stssVisible, stssHidden, stssVeryHidden);
begin
  for var entry: TSheetCT in fPackage.EditPart<TWorkbookE>(fWorkbookPart).Sheets.Sheet do
    if entry.Name = aName then
      if aValue = svVisible then
        entry.Clear(@entry.State)
      else
        entry.State := cStates[aValue];
end;

procedure TXlsxBook.RenameSheet(const aName, aNewName: string);
begin
  for var entry: TSheetCT in fPackage.EditPart<TWorkbookE>(fWorkbookPart).Sheets.Sheet do
    if entry.Name = aName then
      entry.Name := aNewName;
end;

function TXlsxBook.MoveActiveSheet(aFrom, aTo: integer): boolean;
begin
  var workbook: TWorkbookE := fPackage.EditPart<TWorkbookE>(fWorkbookPart);
  if not workbook.IsPresent('BookViews') then
    if aFrom = 0 then
      workbook.BookViews.WorkbookView.Add(TBookViewCT.Create)
    else
      Exit(False);
  Result := False;
  for var view: TBookViewCT in workbook.BookViews.WorkbookView do
    if integer(view.ActiveTab) = aFrom then
    begin
      view.ActiveTab := aTo;
      view.SetPresent(@view.ActiveTab);
      if integer(view.FirstSheet) > aTo then
        view.FirstSheet := aTo;
      Result := True;
    end;
end;

procedure TXlsxBook.SetChartTabSelected(aIndex: integer; aValue: boolean);
begin
  var entry: TSheetCT := fPackage.Part<TWorkbookE>(fWorkbookPart).Sheets.Sheet[aIndex];
  for var relationship: TRelationshipOoxml in fPackage.Relationships(fWorkbookPart, cChartsheet) do
    if relationship.Id = entry.Id then
    begin
      var chartsheet: TChartsheetE := fPackage.Part<TChartsheetE>(relationship.Part);
      if chartsheet <> nil then
        for var view: TChartsheetViewCT in chartsheet.SheetViews.SheetView do
          if view.TabSelected <> aValue then
          begin
            fPackage.EditPart<TChartsheetE>(relationship.Part);
            if aValue then
              view.TabSelected := True
            else
              view.Clear(@view.TabSelected);
          end;
    end;
end;

// a cell's cm (from 1) names Excel 365's dynamic array: its metadata's records of the XLDAPR type
function TXlsxBook.IsDynamicArray(aCellMetadata: cardinal): boolean;
begin
  for var relationship: TRelationshipOoxml in fPackage.Relationships(fWorkbookPart) do
    if relationship.&Type.EndsWith(cSheetMetadata) and not relationship.Part.IsEmpty then
    begin
      var metadata: TMetadataE := fPackage.Part<TMetadataE>(relationship.Part);
      if not metadata.IsPresent('CellMetadata') or not metadata.IsPresent('MetadataTypes') or
        (aCellMetadata > cardinal(metadata.CellMetadata.Bk.Count)) then
        Exit(False);
      var types: TMetadataTypeCTList := metadata.MetadataTypes.MetadataType;
      for var record_: TMetadataRecordCT in metadata.CellMetadata.Bk[aCellMetadata - 1].Rc do
        if (record_.T >= 1) and (record_.T <= cardinal(types.Count)) and (types[record_.T - 1].Name = 'XLDAPR') then
          Exit(True);
      Exit(False);
    end;
  Result := False;
end;

// Excel's default: a cell is locked unless its style unlocks it
function TXlsxBook.IsLockedStyle(aStyle: cardinal): boolean;
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
procedure TXlsxBook.ValueChanged;
begin
  if fValuesChanged then
    Exit;
  fValuesChanged := True;
  fPackage.EditPart<TWorkbookE>(fWorkbookPart).CalcPr.FullCalcOnLoad := True;
end;

// the calculation chain is Excel's cache: a stale entry is its repair prompt, a missing one is not calculated, so it goes with
// any change of a formula and Excel builds a new one
procedure TXlsxBook.FormulaChanged;
begin
  fFormulasWritten := True;
  if fCalcChainPart.IsEmpty then
    Exit;
  fPackage.RemovePart(fWorkbookPart, fCalcChainPart);
  fCalcChainPart := '';
end;

function TXlsxBook.Date1904: boolean;
begin
  var workbook: TWorkbookE := fPackage.Part<TWorkbookE>(fWorkbookPart);
  Result := workbook.IsPresent('WorkbookPr') and workbook.WorkbookPr.Date1904;
end;

function TXlsxBook.SharedString(aIndex: integer): string;
begin
  Result := '';
  if fSharedStringsPart.IsEmpty then
    Exit;
  var strings: TSstE := fPackage.Part<TSstE>(fSharedStringsPart);
  if (aIndex >= 0) and (aIndex < strings.Si.Count) then
    Result := RichText(strings.Si[aIndex]);
end;

// found or added, one more use counted; -1 when there are no shared strings and they cannot be added
function TXlsxBook.SharedStringIndex(const aText: string): integer;
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

procedure TXlsxBook.SharedStringReleased;
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

function TXlsxBook.IsDateStyle(aStyle: cardinal): boolean;
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

function TXlsxBook.HasStyles: boolean;
begin
  if fStylesPart.IsEmpty then
    Exit(False);
  var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
  Result := styles.IsPresent('CellXfs') and (styles.CellXfs.Xf.Count > 0);
end;

function TXlsxBook.ChangedStyle(aStyle: cardinal; aAspects: TAspects; aSides: TCellSides; const aFormat: TCellFormat): integer;
begin
  if not HasStyles then
    Exit(-1);
  var changed: TAspects := ChangedAspects(aStyle, aAspects, aSides, aFormat);
  if changed = [] then
    Exit(aStyle);
  // everything it has kept: protection, extensions, the aspects not changed
  var wanted: TXfCT := StyleXf(aStyle).Clone<TXfCT>;
  try
    if changed * cFontAspects <> [] then
    begin
      var font: integer := ChangedFont(wanted.FontId, changed, aFormat);
      if font >= 0 then
      begin
        wanted.FontId := font;
        wanted.ApplyFont := True;
      end;
    end;
    if asFillColor in changed then
    begin
      var fill: integer := ChangedFill(wanted.FillId, aFormat.FillColor);
      if fill >= 0 then
      begin
        wanted.FillId := fill;
        wanted.ApplyFill := True;
      end;
    end;
    if changed * cBorderAspects <> [] then
    begin
      var border: integer := ChangedBorder(wanted.BorderId, changed, aSides, aFormat, FormatOf(aStyle));
      if border >= 0 then
      begin
        wanted.BorderId := border;
        wanted.ApplyBorder := True;
      end;
    end;
    if asNumberFormat in changed then
    begin
      wanted.NumFmtId := FormatId(aFormat.NumberFormat);
      wanted.ApplyNumberFormat := True;
    end;
    if changed * cAlignmentAspects <> [] then
    begin
      var alignment: TCellAlignmentCT := wanted.Alignment;
      if asHorizontalAlignment in changed then
        if aFormat.HorizontalAlignment = haGeneral then
          alignment.Clear(@alignment.Horizontal)
        else
          alignment.Horizontal := THorizontalAlignmentST(Ord(aFormat.HorizontalAlignment));
      if asVerticalAlignment in changed then
        if aFormat.VerticalAlignment = vaBottom then
          alignment.Clear(@alignment.Vertical)
        else
          alignment.Vertical := TVerticalAlignmentST(Ord(aFormat.VerticalAlignment));
      if asWrapText in changed then
        if aFormat.WrapText then
          alignment.WrapText := True
        else
          alignment.Clear(@alignment.WrapText);
      if not alignment.HasContent then
        wanted.Clear('Alignment'); // left with Excel's defaults: none written, as Excel writes none
      wanted.ApplyAlignment := True;
    end;
  except
    wanted.Free;
    raise;
  end;
  Result := XfIndex(wanted);
end;

// the aspects of aAspects whose value in aFormat is not aStyle's own; a stored color by ColorDiffers, a number format by id
function TXlsxBook.ChangedAspects(aStyle: cardinal; aAspects: TAspects; aSides: TCellSides; const aFormat: TCellFormat): TAspects;
begin
  Result := [];
  var old: TCellFormat := FormatOf(aStyle);
  for var aspect: TAspect in aAspects - cBorderAspects do
  begin
    var differs: boolean;
    case aspect of
      asNumberFormat:
        differs := FormatId(aFormat.NumberFormat) <> integer(StyleXf(aStyle).NumFmtId);
      asFontName:
        differs := not SameText(old.FontName, aFormat.FontName);
      asFontSize:
        differs := old.FontSize <> aFormat.FontSize;
      asFontColor:
      begin
        var font: TFontCT := StyleFont(aStyle);
        var stored: TColorCT := nil;
        if (font <> nil) and (font.Color.Count > 0) then
          stored := font.Color[0];
        differs := ColorDiffers(stored, old.FontColor, aFormat.FontColor);
      end;
      asBold:
        differs := old.Bold <> aFormat.Bold;
      asItalic:
        differs := old.Italic <> aFormat.Italic;
      asStrikethrough:
        differs := old.Strikethrough <> aFormat.Strikethrough;
      asUnderline:
        differs := old.Underline <> aFormat.Underline;
      asFillColor:
        differs := old.FillColor <> aFormat.FillColor;
      asHorizontalAlignment:
        differs := old.HorizontalAlignment <> aFormat.HorizontalAlignment;
      asVerticalAlignment:
        differs := old.VerticalAlignment <> aFormat.VerticalAlignment;
    else
      differs := old.WrapText <> aFormat.WrapText;
    end;
    if differs then
      Include(Result, aspect);
  end;
  if aAspects * cBorderAspects = [] then
    Exit;
  var border: TBorderCT := StyleBorder(aStyle);
  for var side: TCellSide in aSides do
  begin
    var line, color: boolean;
    SideChanges(border, side, aAspects, old.Borders[side], aFormat.Borders[side], line, color);
    if line or color then
      Exit(Result + aAspects * cBorderAspects);
  end;
end;

// aStyle with the number format aFormat; -1 when there are no styles. Asked for each date written: kept
function TXlsxBook.DateStyle(aStyle: cardinal; aFormat: integer): integer;
begin
  var key: UInt64 := UInt64(aStyle) shl 32 or cardinal(aFormat);
  if fDateStyleIds = nil then
    fDateStyleIds := TDictionary<UInt64, integer>.Create;
  if fDateStyleIds.TryGetValue(key, Result) then
    Exit;
  Result := -1;
  if HasStyles then
  begin
    var wanted: TXfCT := StyleXf(aStyle).Clone<TXfCT>;
    wanted.NumFmtId := aFormat;
    wanted.ApplyNumberFormat := True;
    Result := XfIndex(wanted);
  end;
  fDateStyleIds.Add(key, Result);
end;

// aWanted (owned) found in cellXfs by content or added
function TXlsxBook.XfIndex(aWanted: TXfCT): integer;
begin
  var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
  var formats: TXfCTList := styles.CellXfs.Xf;
  if fStyleKeys = nil then
  begin
    fStyleKeys := TDictionary<TXfCT, integer>.Create(TXfCT.ContentComparer<TXfCT>);
    for var i := 0 to formats.Count - 1 do
      fStyleKeys.TryAdd(formats[i], i);
  end;
  if fStyleKeys.TryGetValue(aWanted, Result) then
  begin
    aWanted.Free;
    Exit;
  end;
  styles := fPackage.EditPart<TStyleSheetE>(fStylesPart);
  formats.Add(aWanted);
  Result := formats.Count - 1;
  fStyleKeys.Add(aWanted, Result);
  if styles.CellXfs.Present[@styles.CellXfs.Count] then
    styles.CellXfs.Count := formats.Count;
end;


// the style's number format as Excel's NumberFormat names it
function TXlsxBook.FormatCode(aStyle: cardinal): string;
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

// the id of a number format, built-in or in numFmts, added when there is none; -1 when there are no styles. Asked for each
// date written: kept
function TXlsxBook.FormatId(const aCode: string): integer;
begin
  if fFormatIds = nil then
    fFormatIds := TDictionary<string, integer>.Create;
  if fFormatIds.TryGetValue(aCode, Result) then
    Exit;
  Result := StoredFormatId(aCode);
  fFormatIds.Add(aCode, Result);
end;

function TXlsxBook.StoredFormatId(const aCode: string): integer;
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

// aWanted (owned) found in aItems by content or added (the keys built on the first need)
function TXlsxBook.ItemIndex<T>(aItems: TObjectList<T>; var aKeys: TDictionary<T, integer>; aWanted: T): integer;
begin
  if aKeys = nil then
  begin
    aKeys := TDictionary<T, integer>.Create(TXmlite.ContentComparer<T>);
    for var i := 0 to aItems.Count - 1 do
      aKeys.TryAdd(aItems[i], i);
  end;
  if aKeys.TryGetValue(aWanted, Result) then
  begin
    aWanted.Free;
    Exit;
  end;
  fPackage.EditPart<TStyleSheetE>(fStylesPart);
  aItems.Add(aWanted);
  Result := aItems.Count - 1;
  aKeys.Add(aWanted, Result);
end;

// font aFont (one beyond the fonts as the first) with aAspects of aFormat; -1 when there are no fonts
function TXlsxBook.ChangedFont(aFont: cardinal; aAspects: TAspects; const aFormat: TCellFormat): integer;
begin
  var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
  if not styles.IsPresent('Fonts') or (styles.Fonts.Font.Count = 0) then
    Exit(-1);
  if aFont >= cardinal(styles.Fonts.Font.Count) then
    aFont := 0;
  var font: TFontCT := styles.Fonts.Font[aFont].Clone<TFontCT>;
  if asFontName in aAspects then
  begin
    font.Name.Clear;
    var item: TFontNameCT := TFontNameCT.Create;
    item.Val := aFormat.FontName;
    font.Name.Add(item);
    // the old font's: a scheme would show the theme's font instead, as Excel drops it
    font.Scheme.Clear;
    font.Charset.Clear;
    font.Family.Clear;
  end;
  if asFontSize in aAspects then
  begin
    font.Sz.Clear;
    var item: TFontSizeCT := TFontSizeCT.Create;
    item.Val := aFormat.FontSize;
    font.Sz.Add(item);
  end;
  if asFontColor in aAspects then
  begin
    font.Color.Clear;
    if aFormat.FontColor <> TColors.SysDefault then // automatic: no color, as Excel writes it
    begin
      var item: TColorCT := TColorCT.Create;
      WriteColor(item, aFormat.FontColor);
      font.Color.Add(item);
    end;
  end;
  if asBold in aAspects then
    WriteFlag(font.B, aFormat.Bold);
  if asItalic in aAspects then
    WriteFlag(font.I, aFormat.Italic);
  if asStrikethrough in aAspects then
    WriteFlag(font.Strike, aFormat.Strikethrough);
  if asUnderline in aAspects then
    WriteUnderline(font, aFormat.Underline);
  Result := ItemIndex<TFontCT>(styles.Fonts.Font, fFontKeys, font);
  if styles.Fonts.Present[@styles.Fonts.Count] and (styles.Fonts.Count <> cardinal(styles.Fonts.Font.Count)) then
    styles.Fonts.Count := styles.Fonts.Font.Count;
end;

// a solid fill of aColor as Excel writes one, or none for clNone; -1 when there are no fills
function TXlsxBook.ChangedFill(aFill: cardinal; aColor: TColor): integer;
begin
  var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
  if not styles.IsPresent('Fills') or (styles.Fills.Fill.Count = 0) then
    Exit(-1);
  if aFill >= cardinal(styles.Fills.Fill.Count) then
    aFill := 0;
  var fill: TFillCT := styles.Fills.Fill[aFill].Clone<TFillCT>;
  fill.Clear;
  var pattern: TPatternFillCT := fill.PatternFill;
  if aColor = TColors.SysNone then
  begin
    pattern.PatternType := stptbNone;
    pattern.SetPresent(@pattern.PatternType);
  end
  else
  begin
    pattern.PatternType := stptbSolid;
    WriteColor(pattern.FgColor, aColor);
    pattern.BgColor.Indexed := cAutomaticIndex;
    pattern.BgColor.SetPresent(@pattern.BgColor.Indexed);
  end;
  Result := ItemIndex<TFillCT>(styles.Fills.Fill, fFillKeys, fill);
  if styles.Fills.Present[@styles.Fills.Count] and (styles.Fills.Count <> cardinal(styles.Fills.Fill.Count)) then
    styles.Fills.Count := styles.Fills.Fill.Count;
end;

// border aBorder (one beyond the borders as the first) with aFormat's sides of aSides that changed; -1 when there are no
// borders
function TXlsxBook.ChangedBorder(aBorder: cardinal; aAspects: TAspects; aSides: TCellSides; const aFormat,
  aOld: TCellFormat): integer;
begin
  var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
  if not styles.IsPresent('Borders') or (styles.Borders.Border.Count = 0) then
    Exit(-1);
  if aBorder >= cardinal(styles.Borders.Border.Count) then
    aBorder := 0;
  var old: TBorderCT := styles.Borders.Border[aBorder];
  var border: TBorderCT := old.Clone<TBorderCT>;
  for var side: TCellSide in aSides do
  begin
    var line, color: boolean;
    SideChanges(old, side, aAspects, aOld.Borders[side], aFormat.Borders[side], line, color);
    var written: TBorderPrCT := SideOf(border, side);
    if line then
      if aFormat.Borders[side].LineStyle = lsNone then
        written.Clear
      else
      begin
        written.Style := PairStyle(aFormat.Borders[side]);
        if not written.IsPresent('Color') then
          WriteColor(written.Color, TColors.SysDefault);
      end;
    if color then
      WriteColor(written.Color, aFormat.Borders[side].Color);
  end;
  Result := ItemIndex<TBorderCT>(styles.Borders.Border, fBorderKeys, border);
  if styles.Borders.Present[@styles.Borders.Count] and (styles.Borders.Count <> cardinal(styles.Borders.Border.Count)) then
    styles.Borders.Count := styles.Borders.Border.Count;
end;


// the style's xf (a style beyond cellXfs shows the first, as in Excel); nil when there is none
function TXlsxBook.StyleXf(aStyle: cardinal): TXfCT;
begin
  Result := nil;
  if fStylesPart.IsEmpty then
    Exit;
  var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
  if not styles.IsPresent('CellXfs') or (styles.CellXfs.Xf.Count = 0) then
    Exit;
  if aStyle >= cardinal(styles.CellXfs.Xf.Count) then
    aStyle := 0;
  Result := styles.CellXfs.Xf[aStyle];
end;

// the font a style shows; nil when there is none
function TXlsxBook.StyleFont(aStyle: cardinal): TFontCT;
begin
  Result := nil;
  if fStylesPart.IsEmpty then
    Exit;
  var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
  if not styles.IsPresent('Fonts') or (styles.Fonts.Font.Count = 0) then
    Exit;
  var font: cardinal := 0;
  var xf: TXfCT := StyleXf(aStyle);
  if xf <> nil then
    font := xf.FontId;
  if font >= cardinal(styles.Fonts.Font.Count) then
    font := 0;
  Result := styles.Fonts.Font[font];
end;

// the fill a style shows; nil when there is none
function TXlsxBook.StyleFill(aStyle: cardinal): TFillCT;
begin
  Result := nil;
  var xf: TXfCT := StyleXf(aStyle);
  if xf = nil then
    Exit;
  var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
  if styles.IsPresent('Fills') and (xf.FillId < cardinal(styles.Fills.Fill.Count)) then
    Result := styles.Fills.Fill[xf.FillId];
end;

// the border a style shows; nil when there is none
function TXlsxBook.StyleBorder(aStyle: cardinal): TBorderCT;
begin
  Result := nil;
  var xf: TXfCT := StyleXf(aStyle);
  if xf <> nil then
    Result := BorderAt(xf.BorderId);
end;

function TXlsxBook.BorderAt(aBorder: cardinal): TBorderCT;
begin
  Result := nil;
  if fStylesPart.IsEmpty then
    Exit;
  var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
  if styles.IsPresent('Borders') and (aBorder < cardinal(styles.Borders.Border.Count)) then
    Result := styles.Borders.Border[aBorder];
end;

// a theme color by its number in styles: 0 lt1 (window), 1 dk1 (text), 2 lt2, 3 dk2, then the accents and the links;
// without a theme, Excel's current Office one
function TXlsxBook.ThemeColor(aIndex: cardinal): integer;
const
  cOffice: array[0 .. 11] of integer = ($FFFFFF, $000000, $E8E8E8, $41280E, $826015, $3271E9, $246B19, $D59E0F, $932BA0,
    $2EA74E, $867846, $7D6096);
begin
  if fThemeColors = nil then
  begin
    SetLength(fThemeColors, Length(cOffice));
    for var i := 0 to High(cOffice) do
      fThemeColors[i] := cOffice[i];
    if not fThemePart.IsEmpty then
    begin
      var scheme: TColorSchemeCT := fPackage.Part<TThemeE>(fThemePart).ThemeElements.ClrScheme;
      var colors: TArray<ProRock.Xmlite.Schema.Ooxml.DmlMain.TColorCT> := [scheme.Lt1, scheme.Dk1, scheme.Lt2, scheme.Dk2,
        scheme.Accent1, scheme.Accent2, scheme.Accent3, scheme.Accent4, scheme.Accent5, scheme.Accent6, scheme.Hlink,
        scheme.FolHlink];
      for var i := 0 to High(colors) do
        if colors[i].IsPresent('SrgbClr') then
          fThemeColors[i] := RgbValue(colors[i].SrgbClr.Val)
        else if colors[i].IsPresent('SysClr') then
          fThemeColors[i] := RgbValue(colors[i].SysClr.LastClr);
    end;
  end;
  if aIndex < cardinal(Length(fThemeColors)) then
    Result := fThemeColors[aIndex]
  else
    Result := 0;
end;

// a stored color as Excel's Color: rgb, theme or indexed (the file's own palette first), with its tint; aDefault for
// automatic and none
function TXlsxBook.ColorOf(aColor: TColorCT; aDefault: TColor): TColor;
begin
  if (aColor = nil) or aColor.Auto then
    Exit(aDefault);
  var value: integer;
  if aColor.Present[@aColor.Rgb] then
    value := RgbValue(aColor.Rgb)
  else if aColor.Present[@aColor.Theme] then
    value := ThemeColor(aColor.Theme)
  else if aColor.Present[@aColor.Indexed] then
  begin
    value := TUtility.PaletteColor(aColor.Indexed);
    var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
    if (aColor.Indexed < cAutomaticIndex) and styles.IsPresent('Colors') and styles.Colors.IsPresent('IndexedColors') and
      (aColor.Indexed < cardinal(styles.Colors.IndexedColors.RgbColor.Count)) then
      value := RgbValue(styles.Colors.IndexedColors.RgbColor[aColor.Indexed].Rgb);
  end
  else
    Exit(aDefault);
  if aColor.Present[@aColor.Tint] then
    value := TUtility.TintedColor(value, aColor.Tint);
  Result := value;
end;

function TXlsxBook.FormatOf(aStyle: cardinal): TCellFormat;
begin
  if not fStylesPart.IsEmpty then
  begin
    var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
    if not styles.IsPresent('CellXfs') or (aStyle >= cardinal(styles.CellXfs.Xf.Count)) then
      aStyle := 0;
  end;
  if fFormats = nil then
    fFormats := TDictionary<cardinal, TCellFormat>.Create;
  if fFormats.TryGetValue(aStyle, Result) then
    Exit;
  Result := ReadFormat(aStyle);
  fFormats.Add(aStyle, Result);
end;

function TXlsxBook.ReadFormat(aStyle: cardinal): TCellFormat;
begin
  Result := Default(TCellFormat);
  Result.NumberFormat := FormatCode(aStyle);
  Result.FontSize := 11;
  Result.VerticalAlignment := vaBottom;
  var font: TFontCT := StyleFont(aStyle);
  if font <> nil then
  begin
    if font.Name.Count > 0 then
      Result.FontName := font.Name[0].Val;
    if font.Sz.Count > 0 then
      Result.FontSize := font.Sz[0].Val;
    if font.Color.Count > 0 then
      Result.FontColor := ColorOf(font.Color[0], 0);
    Result.Bold := IsOn(font.B);
    Result.Italic := IsOn(font.I);
    Result.Strikethrough := IsOn(font.Strike);
    if font.U.Count > 0 then
      Result.Underline := cUnderlines[font.U[0].Val];
  end;
  Result.FillColor := TColors.SysNone;
  var fill: TFillCT := StyleFill(aStyle);
  if (fill <> nil) and fill.IsPresent('PatternFill') then
  begin
    var pattern: TPatternFillCT := fill.PatternFill;
    case pattern.PatternType of
      stptbNone:
        ;
      stptbSolid:
        if pattern.IsPresent('FgColor') then
          Result.FillColor := ColorOf(pattern.FgColor, 0)
        else
          Result.FillColor := 0;
    else // the pattern's background: Excel's Interior.Color
      if pattern.IsPresent('BgColor') then
        Result.FillColor := ColorOf(pattern.BgColor, $FFFFFF)
      else
        Result.FillColor := $FFFFFF;
    end;
  end;
  var xf: TXfCT := StyleXf(aStyle);
  if (xf <> nil) and xf.IsPresent('Alignment') then
  begin
    Result.HorizontalAlignment := THAlign(Ord(xf.Alignment.Horizontal));
    Result.VerticalAlignment := TVAlign(Ord(xf.Alignment.Vertical));
    Result.WrapText := xf.Alignment.WrapText;
  end;
  var border: TBorderCT := StyleBorder(aStyle);
  for var side: TCellSide := Low(TCellSide) to High(TCellSide) do
  begin
    Result.Borders[side] := cNoLine;
    var drawn: TBorderPrCT := DrawnSide(border, side);
    if drawn <> nil then
    begin
      Result.Borders[side].LineStyle := cBorderLines[drawn.Style];
      Result.Borders[side].Weight := cBorderWeights[drawn.Style];
      if drawn.IsPresent('Color') then
        Result.Borders[side].Color := ColorOf(drawn.Color, 0);
    end;
  end;
end;

function TXlsxBook.MappedNames(const aMap: TReferenceMap; out aChanged: TArray<string>; out aWhy: string): boolean;
begin
  aWhy := '';
  aChanged := nil;
  var xml: TWorkbookE := nil;
  if not fWorkbookPart.IsEmpty then
    xml := fPackage.Part<TWorkbookE>(fWorkbookPart);
  if (xml = nil) or not xml.IsPresent('DefinedNames') then
    Exit(True);
  var map: TReferenceMap := aMap;
  map.OnSheet := False;
  map.InName := True;
  var names: TDefinedNameCTList := xml.DefinedNames.DefinedName;
  SetLength(aChanged, names.Count);
  for var index := 0 to names.Count - 1 do
  begin
    var text: string := DecodeText(names[index].XmlValue);
    var why: string;
    if not ShiftFormula(text, map, aChanged[index], why) then
    begin // one not naming the sheet stays as it is
      if text.ToUpper.Contains(aMap.Sheet.ToUpper) then
      begin
        aWhy := Format('the defined name %s does not read: %s', [names[index].Name, why]);
        Exit(False);
      end;
      aChanged[index] := text;
    end;
  end;
  Result := True;
end;

procedure TXlsxBook.WriteNames(const aChanged: TArray<string>);
begin
  if aChanged = nil then
    Exit;
  var names: TDefinedNameCTList := fPackage.Part<TWorkbookE>(fWorkbookPart).DefinedNames.DefinedName;
  for var index := 0 to names.Count - 1 do
    if aChanged[index] <> DecodeText(names[index].XmlValue) then
    begin
      names := fPackage.EditPart<TWorkbookE>(fWorkbookPart).DefinedNames.DefinedName;
      names[index].XmlValue := EncodeText(aChanged[index]);
    end;
end;

// what is built from the parts: the user may change them now
procedure TXlsxBook.Forget;
begin
  FreeAndNil(fStrings);
  FreeAndNil(fStyleKeys);
  FreeAndNil(fFontKeys);
  FreeAndNil(fFillKeys);
  FreeAndNil(fBorderKeys);
  FreeAndNil(fDateStyleIds);
  FreeAndNil(fDateStyles);
  FreeAndNil(fFormatIds);
  FreeAndNil(fFormats);
  fThemeColors := nil;
  fValuesChanged := False; // calcPr may be gone: set again on the next write
end;

function TXlsxBook.EditWorkbook: TWorkbookE;
begin
  Forget;
  Result := nil;
  if not fWorkbookPart.IsEmpty then
    Result := fPackage.EditPart<TWorkbookE>(fWorkbookPart);
end;

function TXlsxBook.EditSharedStrings: TSstE;
begin
  Forget;
  Result := nil;
  if not fSharedStringsPart.IsEmpty then
    Result := fPackage.EditPart<TSstE>(fSharedStringsPart);
end;

function TXlsxBook.EditStyles: TStyleSheetE;
begin
  Forget;
  Result := nil;
  if not fStylesPart.IsEmpty then
    Result := fPackage.EditPart<TStyleSheetE>(fStylesPart);
end;

end.
