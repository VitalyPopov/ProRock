unit OfficeDocument;

// An Office document (.docx, .xlsx, .pptx - any OPC package) and its core properties, the ones Office shows in File > Info.
// Read and written with units generated from the official schemas: opc-coreProperties.xsd (on Dublin Core) for the
// properties, opc-relationships.xsd for finding them. The package is a zip; every other part is copied as it is.

interface

uses System.SysUtils,
  ProRock.Xmlite.Schema.CoreProperties;

type
  EOfficeDocument = class(Exception);

  TOfficeDocument = class
  private
    fFileName: string;
    fCorePartName: string; // its name in the zip, e.g. docProps/core.xml
    fProperties: TCorePropertiesE;
    fSigned: boolean;
  public
    constructor Create;
    destructor Destroy; override;

    // raises EOfficeDocument: not a zip, not an OPC package, no core properties
    procedure Load(const aFileName: string);
    // writes the package to aFileName - the loaded file or a new one: every part as it was, the core properties from
    // Properties, Modified set to now (UTC) as Office does
    procedure Save(const aFileName: string);

    property FileName: string read fFileName;
    property Properties: TCorePropertiesE read fProperties;
    // the package has a digital signature: it usually covers the core properties, so saving breaks it
    property Signed: boolean read fSigned;
  end;

implementation

uses System.Classes, System.IOUtils, System.Zip, System.DateUtils,
  ProRock.Basite, ProRock.Xmlite, ProRock.Xmlite.Schema.Relationships, ProRock.Xmlite.Schema.Dc.Terms;

const
  // OPC (ECMA-376 Part 2): the package's relationships, and the types of the two we look for (Annex E)
  cPackageRelationships = '_rels/.rels';
  cCorePropertiesType = 'http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties';
  cSignatureOriginType = 'http://schemas.openxmlformats.org/package/2006/relationships/digital-signature/origin';

// XML parts are UTF-8 (a BOM or not) or UTF-16 with a BOM
function PartText(const aBytes: TBytes): string;
begin
  var encoding: TEncoding := nil;
  var bomLength: integer := TEncoding.GetBufferEncoding(aBytes, encoding, TEncoding.UTF8);
  Result := encoding.GetString(aBytes, bomLength, Length(aBytes) - bomLength);
end;

// part names are case-insensitive (OPC); a relationship target is relative to the package root here, "/" or not
function PartIndex(aZip: TZipFile; const aPartName: string): integer;
begin
  var name: string := aPartName;
  if name.StartsWith('/') then
    name := name.Substring(1);

  for Result := 0 to aZip.FileCount - 1 do
    if SameText(aZip.FileNames[Result], name) then
      Exit;
  Result := -1;
end;

{ TOfficeDocument }

constructor TOfficeDocument.Create;
begin
  inherited;
  fProperties := TCorePropertiesE.Create;
end;

destructor TOfficeDocument.Destroy;
begin
  fProperties.Free;
  inherited;
end;

procedure TOfficeDocument.Load(const aFileName: string);
begin
  if not TZipFile.IsValid(aFileName) then
    raise EOfficeDocument.CreateFmt('%s is not an Office document (not a zip package)', [ExtractFileName(aFileName)]);

  var zip: TZipFile := TZipFile.Create;
  var relationships: TRelationshipsE := TRelationshipsE.Create;
  var properties: TCorePropertiesE := TCorePropertiesE.Create;
  try
    zip.Open(aFileName, zmRead);

    var index: integer := PartIndex(zip, cPackageRelationships);
    if index < 0 then
      raise EOfficeDocument.CreateFmt('%s is not an Office document (no %s)', [ExtractFileName(aFileName), cPackageRelationships]);

    var bytes: TBytes;
    zip.Read(index, bytes);
    if not TXmlite.XmlToObject(PartText(bytes), relationships) then
      raise EOfficeDocument.CreateFmt('%s: %s cannot be read', [ExtractFileName(aFileName), cPackageRelationships]);

    // OPC: at most one core properties part, found through the package's core properties relationship
    var corePartName: string := '';
    var signed: boolean := False;
    for var relationship: TRelationshipE in relationships.Relationship do
      if relationship.&Type = cCorePropertiesType then
        corePartName := relationship.Target
      else if relationship.&Type = cSignatureOriginType then
        signed := True;

    if corePartName.IsEmpty then
      raise EOfficeDocument.CreateFmt('%s has no core properties', [ExtractFileName(aFileName)]);

    index := PartIndex(zip, corePartName);
    if index < 0 then
      raise EOfficeDocument.CreateFmt('%s: the core properties part %s is missing', [ExtractFileName(aFileName), corePartName]);

    zip.Read(index, bytes);
    if not TXmlite.XmlToObject(PartText(bytes), properties) then
      raise EOfficeDocument.CreateFmt('%s: the core properties cannot be read', [ExtractFileName(aFileName)]);

    // loaded: from here on the document is this file
    fFileName := aFileName;
    fCorePartName := zip.FileNames[index];
    fSigned := signed;
    fProperties.Free;
    fProperties := properties;
    properties := nil;
  finally
    properties.Free;
    relationships.Free;
    zip.Free;
  end;
end;

procedure TOfficeDocument.Save(const aFileName: string);
begin
  if fFileName.IsEmpty then
    raise EOfficeDocument.Create('Nothing loaded to save');

  // like Office: the time of this change, in the W3CDTF form OPC requires (dcterms:modified xsi:type="dcterms:W3CDTF")
  fProperties.Modified.XmlValue := FormatDateTime('yyyy-mm-dd"T"hh":"nn":"ss"Z"', TTimeZone.Local.ToUniversalTime(Now));
  fProperties.Modified.SetXsiType(TW3cdtfCT);
  var core: TBytes := TEncoding.UTF8.GetBytes(TXmlite.ObjectToXml(fProperties));

  // a new package next to the target, then moved over it - the loaded file stays intact until the new one is complete
  var temporary: string := aFileName + '.saving';
  var source: TZipFile := TZipFile.Create;
  var target: TZipFile := TZipFile.Create;
  try
    try
      source.Open(fFileName, zmRead);
      target.Open(temporary, zmWrite);
      for var i := 0 to source.FileCount - 1 do
        if SameText(source.FileNames[i], fCorePartName) then
          target.Add(core, source.FileNames[i])
        else
        begin // as it was: the same bytes, the same compression, in the same order
          var bytes: TBytes;
          source.Read(i, bytes);
          target.Add(bytes, source.FileNames[i], TZipCompression(source.FileInfo[i].CompressionMethod));
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

end.
