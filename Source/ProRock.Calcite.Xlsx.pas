unit ProRock.Calcite.Xlsx;

// the xlsx backend: a workbook's package and the parts every sheet shares, with the caches over them (internal)

interface

uses System.SysUtils, System.Classes, System.Generics.Collections, System.UITypes, ProRock.Xmlite, ProRock.Office.Ooxml,
  ProRock.Xmlite.Schema.Ooxml.Sml, ProRock.Calcite.Utility;

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
  cAutomaticIndex = 64; // indexed: the system's text color, Excel's automatic

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
    fValuesChanged: boolean;
    fFormulasWritten: boolean;

    function ChangedItem<T: TXmlite, constructor>(aItems: TObjectList<T>; var aKeys: TDictionary<T, integer>;
      aIndex: cardinal; const aChange: TProc<T>): integer;
    function ThemeColor(aIndex: cardinal): integer;
    function StoredFormatId(const aCode: string): integer;
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

    function IsDynamicArray(aCellMetadata: cardinal): boolean;
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
    function ChangedFont(aFont: cardinal; const aChange: TProc<TFontCT>): integer;
    function ChangedFill(aFill: cardinal; const aChange: TProc<TFillCT>): integer;
    function ChangedBorder(aBorder: cardinal; const aChange: TProc<TBorderCT>): integer;
    function StyleXf(aStyle: cardinal): TXfCT;
    function StyleFont(aStyle: cardinal): TFontCT;
    function StyleFill(aStyle: cardinal): TFillCT;
    function StyleBorder(aStyle: cardinal): TBorderCT;
    function BorderAt(aBorder: cardinal): TBorderCT;
    function ColorOf(aColor: TColorCT; aDefault: TColor): TColor;

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

// aStyle changed by aChange, found in cellXfs by content or added; -1 when there are no styles
function TXlsxBook.ChangedStyle(aStyle: cardinal; const aChange: TProc<TXfCT>): integer;
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
    fStyleKeys := TDictionary<TXfCT, integer>.Create(TXfCT.ContentComparer<TXfCT>);
    for var i := 0 to formats.Count - 1 do
      fStyleKeys.TryAdd(formats[i], i);
  end;
  // everything it has kept: alignment, protection, extensions
  var wanted: TXfCT := formats[aStyle].Clone<TXfCT>;
  try
    aChange(wanted);
    if fStyleKeys.TryGetValue(wanted, Result) then
      Exit;
    styles := fPackage.EditPart<TStyleSheetE>(fStylesPart);
    formats.Add(wanted);
    Result := formats.Count - 1;
    fStyleKeys.Add(wanted, Result);
    wanted := nil;
    if styles.CellXfs.Present[@styles.CellXfs.Count] then
      styles.CellXfs.Count := formats.Count;
  finally
    wanted.Free;
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
  Result := ChangedStyle(aStyle,
    procedure(aXf: TXfCT)
    begin
      aXf.NumFmtId := aFormat;
      aXf.ApplyNumberFormat := True;
    end);
  fDateStyleIds.Add(key, Result);
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

// aItems[aIndex] changed by aChange, found by content or added (the keys built on the first need); the caller checks there
// are items
function TXlsxBook.ChangedItem<T>(aItems: TObjectList<T>; var aKeys: TDictionary<T, integer>; aIndex: cardinal;
  const aChange: TProc<T>): integer;
begin
  if aIndex >= cardinal(aItems.Count) then
    aIndex := 0; // as Excel shows such a cell
  if aKeys = nil then
  begin
    aKeys := TDictionary<T, integer>.Create(TXmlite.ContentComparer<T>);
    for var i := 0 to aItems.Count - 1 do
      aKeys.TryAdd(aItems[i], i);
  end;
  var wanted: T := aItems[aIndex].Clone<T>;
  try
    aChange(wanted);
    if aKeys.TryGetValue(wanted, Result) then
      Exit;
    fPackage.EditPart<TStyleSheetE>(fStylesPart);
    aItems.Add(wanted);
    Result := aItems.Count - 1;
    aKeys.Add(wanted, Result);
    wanted := nil;
  finally
    wanted.Free;
  end;
end;

// -1 when there are no fonts
function TXlsxBook.ChangedFont(aFont: cardinal; const aChange: TProc<TFontCT>): integer;
begin
  if fStylesPart.IsEmpty then
    Exit(-1);
  var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
  if not styles.IsPresent('Fonts') or (styles.Fonts.Font.Count = 0) then
    Exit(-1);
  Result := ChangedItem<TFontCT>(styles.Fonts.Font, fFontKeys, aFont, aChange);
  if styles.Fonts.Present[@styles.Fonts.Count] and (styles.Fonts.Count <> cardinal(styles.Fonts.Font.Count)) then
    styles.Fonts.Count := styles.Fonts.Font.Count;
end;

// -1 when there are no fills
function TXlsxBook.ChangedFill(aFill: cardinal; const aChange: TProc<TFillCT>): integer;
begin
  if fStylesPart.IsEmpty then
    Exit(-1);
  var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
  if not styles.IsPresent('Fills') or (styles.Fills.Fill.Count = 0) then
    Exit(-1);
  Result := ChangedItem<TFillCT>(styles.Fills.Fill, fFillKeys, aFill, aChange);
  if styles.Fills.Present[@styles.Fills.Count] and (styles.Fills.Count <> cardinal(styles.Fills.Fill.Count)) then
    styles.Fills.Count := styles.Fills.Fill.Count;
end;

// -1 when there are no borders
function TXlsxBook.ChangedBorder(aBorder: cardinal; const aChange: TProc<TBorderCT>): integer;
begin
  if fStylesPart.IsEmpty then
    Exit(-1);
  var styles: TStyleSheetE := fPackage.Part<TStyleSheetE>(fStylesPart);
  if not styles.IsPresent('Borders') or (styles.Borders.Border.Count = 0) then
    Exit(-1);
  Result := ChangedItem<TBorderCT>(styles.Borders.Border, fBorderKeys, aBorder, aChange);
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
