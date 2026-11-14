unit ProRock.Calcite;

// Excel workbooks (.xlsx): open, change and save with nothing lost

interface

uses System.SysUtils, System.Classes, System.Generics.Collections, System.Zip,
  ProRock.Xmlite, ProRock.Xmlite.Schema.Ooxml.Sml;

type
  TWorkbook = class;

  TWorksheet = class
  private
    fWorkbook: TWorkbook;
    fName: string;
    fPartName: string;

    function GetXml: TWorksheetE;
  public
    // the generated objects; once taken, the sheet is saved from them
    property Xml: TWorksheetE read GetXml;

    property Workbook: TWorkbook read fWorkbook;
    property Name: string read fName;
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
    public
      destructor Destroy; override;
    end;
  private
    fFileName: string;
    fError: string;
    fSource: TBytesStream;
    fZip: TZipFile; // over fSource
    fParts: TObjectDictionary<string, TPart>; // only the parts Calcite has classes for
    fWorkbookPart, fSharedStringsPart, fStylesPart: string;
    fSheets: TWorksheets;

    procedure Close;
    function Load: boolean;
    function Fail(const aError: string): boolean;
    function CanWrite: boolean;
    function Write(aStream: TStream): boolean;
    procedure Exchange(aOther: TWorkbook);
    function PartIndex(const aName: string): integer;
    function AddPart(const aName: string; aClass: TXmliteClass): string;
    // ReadPart leaves the part as its bytes, EditPart saves it from its objects
    function ReadPart(const aName: string): TXmlite;
    function EditPart(const aName: string): TXmlite;

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
    property Sheets: TWorksheets read fSheets;
  end;

implementation

uses System.IOUtils,
  ProRock.Xmlite.Schema.Relationships;

const
  // relationship types end in these names - Transitional and Strict differ only before them
  cOfficeDocument = '/officeDocument';
  cWorksheet = '/worksheet';
  cSharedStrings = '/sharedStrings';
  cStyles = '/styles';

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

{ TWorksheet }

function TWorksheet.GetXml: TWorksheetE;
begin
  Result := TWorksheetE(fWorkbook.EditPart(fPartName));
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
end;

destructor TWorkbook.Destroy;
begin
  Close;
  fSheets.Free;
  fParts.Free;
  inherited;
end;

procedure TWorkbook.Close;
begin
  fSheets.fList.Clear;
  fParts.Clear;
  FreeAndNil(fZip);
  FreeAndNil(fSource);
  fFileName := '';
  fWorkbookPart := '';
  fSharedStringsPart := '';
  fStylesPart := '';
end;

// an answer for the caller (False and Error); everything else still raises: a bug
function IsFileError(aError: Exception): boolean;
begin
  Result := aError.InheritsFrom(EStreamError) or aError.InheritsFrom(EInOutError) or aError.InheritsFrom(EZipException) or
    aError.InheritsFrom(EEncodingError) or aError.InheritsFrom(EOSError);
end;

function TWorkbook.Fail(const aError: string): boolean;
begin
  fError := aError;
  Result := False;
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
      Exit(Fail(e.Message));
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
  // into a workbook of its own first: a failed Open leaves this one as it was
  var opened: TWorkbook := TWorkbook.Create;
  try
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
          Exit(Fail('Not an .xlsx file (not a zip package)'));
      end;
      if not opened.Load then
        Exit(Fail(opened.fError));
    except
      on e: Exception do
      begin
        if not IsFileError(e) then
          raise;
        Exit(Fail(e.Message));
      end;
    end;
    Exchange(opened);
    fError := '';
    Result := True;
  finally
    opened.Free; // with what was open here before
  end;
end;

procedure TWorkbook.Exchange(aOther: TWorkbook);
begin
  var fileName: string := fFileName;
  fFileName := aOther.fFileName;
  aOther.fFileName := fileName;
  var source: TBytesStream := fSource;
  fSource := aOther.fSource;
  aOther.fSource := source;
  var zip: TZipFile := fZip;
  fZip := aOther.fZip;
  aOther.fZip := zip;
  var parts: TObjectDictionary<string, TPart> := fParts;
  fParts := aOther.fParts;
  aOther.fParts := parts;
  var workbookPart: string := fWorkbookPart;
  fWorkbookPart := aOther.fWorkbookPart;
  aOther.fWorkbookPart := workbookPart;
  var sharedStringsPart: string := fSharedStringsPart;
  fSharedStringsPart := aOther.fSharedStringsPart;
  aOther.fSharedStringsPart := sharedStringsPart;
  var stylesPart: string := fStylesPart;
  fStylesPart := aOther.fStylesPart;
  aOther.fStylesPart := stylesPart;
  var sheets: TWorksheets := fSheets;
  fSheets := aOther.fSheets;
  aOther.fSheets := sheets;
  for var sheet: TWorksheet in fSheets do
    sheet.fWorkbook := Self;
  for var sheet: TWorksheet in aOther.fSheets do
    sheet.fWorkbook := aOther;
end;

function TWorkbook.Load: boolean;

  // nil when none; never written back
  function Relationships(const aPart: string): TRelationshipsE;
  begin
    Result := nil;
    var index: integer := PartIndex(RelationshipsPart(aPart));
    if index < 0 then
      Exit;
    var bytes: TBytes;
    fZip.Read(index, bytes);
    Result := TRelationshipsE.Create;
    Result.FromXmlBytes(bytes);
  end;

begin
  // the main part is found, not assumed (xl/workbook.xml in Excel's files)
  var packageRelationships: TRelationshipsE := Relationships('');
  if packageRelationships <> nil then
    try
      for var relationship: TRelationshipE in packageRelationships.Relationship do
        if string(relationship.&Type).EndsWith(cOfficeDocument) then
          fWorkbookPart := AddPart(ResolveTarget('', relationship.Target), TWorkbookE);
    finally
      packageRelationships.Free;
    end;
  if fWorkbookPart.IsEmpty then
    Exit(Fail('Not an Office document: the package names no main part'));
  var workbook: TWorkbookE := TWorkbookE(ReadPart(fWorkbookPart));

  var workbookRelationships: TRelationshipsE := Relationships(fWorkbookPart);
  if workbookRelationships = nil then
    Exit(Fail(Format('%s is not a workbook: it has no relationships', [fWorkbookPart])));
  try
    for var relationship: TRelationshipE in workbookRelationships.Relationship do
      if string(relationship.&Type).EndsWith(cSharedStrings) then
        fSharedStringsPart := AddPart(ResolveTarget(fWorkbookPart, relationship.Target), TSstE)
      else if string(relationship.&Type).EndsWith(cStyles) then
        fStylesPart := AddPart(ResolveTarget(fWorkbookPart, relationship.Target), TStyleSheetE);

    for var sheetEntry: TSheetCT in workbook.Sheets.Sheet do
      for var relationship: TRelationshipE in workbookRelationships.Relationship do
        if (relationship.Id = sheetEntry.Id) and string(relationship.&Type).EndsWith(cWorksheet) then
        begin
          var partName: string := AddPart(ResolveTarget(fWorkbookPart, relationship.Target), TWorksheetE);
          if partName.IsEmpty then
            Exit(Fail(Format('The sheet "%s" has no part (%s)', [sheetEntry.Name, relationship.Target])));
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

function TWorkbook.ReadPart(const aName: string): TXmlite;
begin
  var part: TPart := fParts[aName];
  if part.fXml = nil then
  begin
    var bytes: TBytes;
    fZip.Read(PartIndex(aName), bytes);
    part.fXml := part.fClass.Create;
    // False: read as far as it goes, but it would not be written back as it was
    part.fExact := part.fXml.FromXmlBytes(bytes);
  end;
  Result := part.fXml;
end;

// a part that did not read back exactly too: Save refuses it
function TWorkbook.EditPart(const aName: string): TXmlite;
begin
  Result := ReadPart(aName);
  fParts[aName].fChanged := True;
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
    Result := TSstE(EditPart(fSharedStringsPart));
end;

function TWorkbook.GetXmlStyles: TStyleSheetE;
begin
  Result := nil;
  if not fStylesPart.IsEmpty then
    Result := TStyleSheetE(EditPart(fStylesPart));
end;

function TWorkbook.Save: boolean;
begin
  if fZip = nil then
    Exit(Fail('No workbook is open'));
  if fFileName.IsEmpty then
    Exit(Fail('The workbook has no file to save to (it was opened from a stream): use SaveAs'));
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
        Result := Fail(e.Message);
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
      Result := Fail(e.Message);
    end;
  end;
  if Result then
    fError := '';
end;

function TWorkbook.CanWrite: boolean;
begin
  if fZip = nil then
    Exit(Fail('No workbook is open'));
  // refused rather than written broken
  for var pair: TPair<string, TPart> in fParts do
    if pair.Value.fChanged and not pair.Value.fExact then
      Exit(Fail(Format('%s cannot be saved changed: it did not read back exactly, writing it could lose something',
        [pair.Key])));
  Result := True;
end;

function TWorkbook.Write(aStream: TStream): boolean;
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
      var compression: TZipCompression := TZipCompression(fZip.FileInfo[i].CompressionMethod);
      var part: TPart;
      if fParts.TryGetValue(name, part) and part.fChanged then
      begin
        var xml: TBytesStream := TBytesStream.Create;
        try
          // as Excel writes: compact whatever TBasite.Pretty says, booleans as 1 and 0
          part.fXml.ToXml(xml, [woBooleanDigits]);
          xml.Position := 0;
          target.Add(xml, name, compression);
        finally
          xml.Free;
        end;
      end
      else
      begin
        var bytes: TBytes;
        fZip.Read(i, bytes);
        target.Add(bytes, name, compression);
      end;
    end;
    target.Close;
  finally
    target.Free;
  end;
  Result := True;
end;

end.
