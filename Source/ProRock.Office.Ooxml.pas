unit ProRock.Office.Ooxml;

// Office files (.xlsx, .docx, .pptx - any OPC package): parts read on first use, untouched bytes kept, nothing lost on save

interface

uses System.SysUtils, System.Classes, System.Generics.Collections, System.Zip, System.TypInfo,
  ProRock.Xmlite, ProRock.Xmlite.Schema.CoreProperties;

type
  {$REGION 'ProRock.Xmlite types aliases'}
  TIssueSeverity = ProRock.Xmlite.TIssueSeverity;
  TIssue = ProRock.Xmlite.TIssue;
  TIssueEvent = ProRock.Xmlite.TIssueEvent;
  TIssues = ProRock.Xmlite.TIssues;
  {$ENDREGION}

  TPackageOoxml = class;

  // a relationship as the package has it; Part - its target's part name, '' when the package lacks it or it is external
  TRelationshipOoxml = record
    Id, &Type, Target, Part: string;
  end;

  // the properties Office shows in File > Info, as plain values: '' and 0 - none, and setting them so removes the element,
  // as Office does; dates in UTC. The rest of the part (language, version...) through Xml
  TCoreProperties = class
  private
    fPackage: TPackageOoxml;
    function PartName: string;
    function Read: TCorePropertiesE;
    function Edit: TCorePropertiesE;
    function GetText(aIndex: integer): string;
    procedure SetText(aIndex: integer; const aValue: string);
    function GetDate(aIndex: integer): TDateTime;
    procedure SetDate(aIndex: integer; aValue: TDateTime);
    function GetXml: TCorePropertiesE;
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
    // Save sets it when anything changed, as Office does
    property Modified: TDateTime index 1 read GetDate write SetDate;
    // the generated objects, made when the package has none (nil when it cannot have them); once taken, saved from them
    property Xml: TCorePropertiesE read GetXml;
  end;

  TPackageOoxml = class
  private type
    TPart = class
    private
      fClass: TXmliteClass;
      fXml: TXmlite; // nil until first used
      fExact: boolean; // read without a loss: may be written back
      fChanged: boolean;
      fNew: boolean; // not in the package yet
      fLeftOut: boolean; // removed: its name is in fRemoved, GetPart's quick lookup passes it by
    public
      destructor Destroy; override;
    end;
  private
    fFileName: string;
    fError: string;
    fSource: TBytesStream;
    fZip: TZipFile; // over fSource; nil - nothing open
    fParts: TObjectDictionary<string, TPart>; // only the parts asked for
    fRemoved: TList<string>; // left out on save
    fMainType: string; // what the main part's relationship type starts with: Transitional and Strict differ
    fProperties: TCoreProperties;
    fIssues: TIssues;

    procedure Close;
    procedure Exchange(aOther: TPackageOoxml);
    function Fail(const aCode, aError: string): boolean;
    function ReadXml(aXml: TXmlite; const aPart: string; const aBytes: TBytes): boolean;
    function PartIndex(const aName: string): integer;
    function FindPart(const aName: string): string;
    function GetPart(const aName: string; aClass: TXmliteClass; aEdit: boolean): TXmlite;
    function Changed: boolean;
    function CanWrite: boolean;
    function Write(aStream: TStream): boolean;
    function GetSigned: boolean;
  public
    // nothing open: Open a file, or make the parts of a new one in a zip and Open that
    constructor Create;
    destructor Destroy; override;

    // False: Error says why, and the package open before stays open
    function Open(const aFileName: string): boolean; overload;
    function Open(aStream: TStream): boolean; overload;
    // Save: to the file opened. False: Error says why, and the file stays as it was
    function Save: boolean;
    function SaveAs(const aFileName: string): boolean; overload;
    function SaveAs(aStream: TStream): boolean; overload;

    // a part's objects, read on first use (nil: no such part, or it is read as another class already); EditPart: saved from
    // them - refused on save when the part did not read back exactly
    function Part<T: TXmlite>(const aName: string): T;
    function EditPart<T: TXmlite>(const aName: string): T;
    // aPart's relationships ('' - the package's); aType - all, or those whose type ends so: /worksheet, /metadata/core-properties
    function Relationships(const aPart: string; const aType: string = ''): TArray<TRelationshipOoxml>;
    function HasPart(const aName: string): boolean;
    // [Content_Types].xml's for a part: its Override, else the Default of its extension; '' - none
    function ContentType(const aName: string): string;
    // a new part, related from aFrom ('' - the package) with aType (a full URI, or an ending the main part's prefix goes
    // before) and its content type; its name, aId - the relationship's. '' (aXml freed): no content types, or the name is taken
    function AddPart(const aFrom, aType, aTarget, aContentType: string; aXml: TXmlite; out aId: string): string;
    // a part left out on save, with aFrom's relationships to it and its content type
    procedure RemovePart(const aFrom, aName: string);

    property FileName: string read fFileName;
    // why the last Open or Save returned False
    property Error: string read fError;
    // since the last Open: what Open and Save could not do, parts read not quite right
    property Issues: TIssues read fIssues;
    property OnIssue: TIssueEvent read fIssues.OnIssue write fIssues.OnIssue;
    property Properties: TCoreProperties read fProperties;
    // the package has a digital signature: it usually covers the core properties, so saving changes breaks it
    property Signed: boolean read GetSigned;
  end;

implementation

uses System.IOUtils, System.DateUtils, System.Math,
  ProRock.Utility, ProRock.Xmlite.Schema.Relationships, ProRock.Xmlite.Schema.ContentTypes, ProRock.Xmlite.Schema.Dc.Terms;

const
  cContentTypes = '[Content_Types].xml';
  cTransitional = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
  cOfficeDocument = '/officeDocument';
  cCoreProperties = 'http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties';
  cCorePropertiesType = 'application/vnd.openxmlformats-package.core-properties+xml';
  cSignatureOrigin = '/digital-signature/origin';

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

function UtcNow: TDateTime;
begin
  Result := TTimeZone.Local.ToUniversalTime(Now);
end;

{ TCoreProperties }

function TCoreProperties.PartName: string;
begin
  Result := '';
  for var relationship: TRelationshipOoxml in fPackage.Relationships('', '/metadata/core-properties') do
    if not relationship.Part.IsEmpty then
      Exit(relationship.Part);
end;

function TCoreProperties.Read: TCorePropertiesE;
begin
  var name: string := PartName;
  if name.IsEmpty then
    Exit(nil);
  Result := fPackage.Part<TCorePropertiesE>(name);
end;

// made when missing (OPC: at most one, related from the package)
function TCoreProperties.Edit: TCorePropertiesE;
begin
  var name: string := PartName;
  if not name.IsEmpty then
    Exit(fPackage.EditPart<TCorePropertiesE>(name));
  var id: string;
  var added: TCorePropertiesE := TCorePropertiesE.Create;
  if fPackage.AddPart('', cCoreProperties, 'docProps/core.xml', cCorePropertiesType, added, id).IsEmpty then
    Exit(nil);
  Result := added;
end;

function TCoreProperties.GetXml: TCorePropertiesE;
begin
  Result := Edit;
end;

const
  cTextNames: array [0 .. 8] of string = ('Title', 'Subject', 'Creator', 'Keywords', 'Description', 'Category', 'ContentStatus',
    'LastModifiedBy', 'Revision');
  cDateNames: array [0 .. 1] of string = ('Created', 'Modified');

function TCoreProperties.GetText(aIndex: integer): string;
begin
  Result := '';
  var properties: TCorePropertiesE := Read;
  if (properties = nil) or not properties.IsPresent(cTextNames[aIndex]) then
    Exit;
  // Dublin Core elements carry their text in XmlValue, cp:keywords is mixed content, the cp elements are plain strings
  case aIndex of
    0: Result := properties.Title.XmlValue;
    1: Result := properties.Subject.XmlValue;
    2: Result := properties.Creator.XmlValue;
    3: Result := properties.Keywords.XmlText;
    4: Result := properties.Description.XmlValue;
    5: Result := properties.Category;
    6: Result := properties.ContentStatus;
    7: Result := properties.LastModifiedBy;
    8: Result := properties.Revision;
  end;
end;

procedure TCoreProperties.SetText(aIndex: integer; const aValue: string);
begin
  var properties: TCorePropertiesE := Edit;
  if properties = nil then
    Exit;
  if aValue.IsEmpty then
  begin
    properties.Clear(cTextNames[aIndex]);
    Exit;
  end;
  case aIndex of
    0: properties.Title.XmlValue := aValue;
    1: properties.Subject.XmlValue := aValue;
    2: properties.Creator.XmlValue := aValue;
    3: properties.Keywords.XmlText := aValue;
    4: properties.Description.XmlValue := aValue;
    5: properties.Category := aValue;
    6: properties.ContentStatus := aValue;
    7: properties.LastModifiedBy := aValue;
    8: properties.Revision := aValue;
  end;
end;

function TCoreProperties.GetDate(aIndex: integer): TDateTime;
begin
  Result := 0;
  var properties: TCorePropertiesE := Read;
  if (properties = nil) or not properties.IsPresent(cDateNames[aIndex]) then
    Exit;
  var text: string;
  if aIndex = 0 then
    text := properties.Created.XmlValue
  else
    text := properties.Modified.XmlValue;
  if not TryISO8601ToDate(text, Result, True) then
    Result := 0;
end;

procedure TCoreProperties.SetDate(aIndex: integer; aValue: TDateTime);
begin
  var properties: TCorePropertiesE := Edit;
  if properties = nil then
    Exit;
  if aValue = 0 then
  begin
    properties.Clear(cDateNames[aIndex]);
    Exit;
  end;
  // the W3CDTF form OPC requires, with its xsi:type
  var text: string := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"Z"', aValue);
  if aIndex = 0 then
  begin
    properties.Created.XmlValue := text;
    properties.Created.SetXsiType(TW3cdtfCT);
  end
  else
  begin
    properties.Modified.XmlValue := text;
    properties.Modified.SetXsiType(TW3cdtfCT);
  end;
end;

{ TPackageOoxml.TPart }

destructor TPackageOoxml.TPart.Destroy;
begin
  fXml.Free;
  inherited;
end;

{ TPackageOoxml }

constructor TPackageOoxml.Create;
begin
  inherited;
  fParts := TObjectDictionary<string, TPart>.Create([doOwnsValues]);
  fRemoved := TList<string>.Create;
  fProperties := TCoreProperties.Create;
  fProperties.fPackage := Self;
end;

destructor TPackageOoxml.Destroy;
begin
  Close;
  fProperties.Free;
  fRemoved.Free;
  fParts.Free;
  inherited;
end;

procedure TPackageOoxml.Close;
begin
  fParts.Clear;
  fRemoved.Clear;
  FreeAndNil(fZip);
  FreeAndNil(fSource);
  fFileName := '';
  fMainType := '';
end;

// everything but Error and Properties: what is open here goes to aOther
procedure TPackageOoxml.Exchange(aOther: TPackageOoxml);
begin
  var name: string := fFileName;
  fFileName := aOther.fFileName;
  aOther.fFileName := name;
  var source: TBytesStream := fSource;
  fSource := aOther.fSource;
  aOther.fSource := source;
  var zip: TZipFile := fZip;
  fZip := aOther.fZip;
  aOther.fZip := zip;
  var parts: TObjectDictionary<string, TPart> := fParts;
  fParts := aOther.fParts;
  aOther.fParts := parts;
  var removed: TList<string> := fRemoved;
  fRemoved := aOther.fRemoved;
  aOther.fRemoved := removed;
  var mainType: string := fMainType;
  fMainType := aOther.fMainType;
  aOther.fMainType := mainType;
  var issues: TIssues := fIssues;
  fIssues := aOther.fIssues;
  aOther.fIssues := issues;
end;

function TPackageOoxml.Fail(const aCode, aError: string): boolean;
begin
  fError := aError;
  fIssues.Add(TIssueSeverity.isError, aCode, '', aError);
  Result := False;
end;

// what the read reports, the part named; content not in the schema is kept anyway (left out)
function TPackageOoxml.ReadXml(aXml: TXmlite; const aPart: string; const aBytes: TBytes): boolean;
begin
  var read: TIssues;
  Result := aXml.FromXmlBytes(aBytes, read);
  for var issue: TIssue in read do
    if issue.Severity <> TIssueSeverity.isHint then
    begin
      var named: TIssue := issue;
      if named.Where.IsEmpty then
        named.Where := aPart
      else
        named.Where := aPart + ', ' + named.Where;
      fIssues.Add(named);
    end;
end;

function TPackageOoxml.Open(const aFileName: string): boolean;
begin
  var stream: TFileStream;
  try
    // others may write it meanwhile: a document open in Office can still be read
    stream := TFileStream.Create(aFileName, fmOpenRead or fmShareDenyNone);
  except
    on e: Exception do
    begin
      if not TUtility.IsFileError(e) then
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

function TPackageOoxml.Open(aStream: TStream): boolean;
begin
  // into a package of its own first: a failed Open leaves this one as it was, with this Open's issues
  fIssues.Clear;
  var opened: TPackageOoxml := TPackageOoxml.Create;
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
          Exit(Fail('NotPackage', 'Not an Office file (not a zip package)'));
      end;
      if opened.PartIndex('_rels/.rels') < 0 then
        Exit(Fail('NotPackage', 'Not an Office file: the package has no relationships (_rels/.rels)'));
      opened.fMainType := cTransitional;
      for var relationship: TRelationshipOoxml in opened.Relationships('', cOfficeDocument) do
        opened.fMainType := relationship.&Type.Substring(0, relationship.&Type.Length - Length(cOfficeDocument));
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

// part names ignore case (OPC); Office's own match exactly
function TPackageOoxml.PartIndex(const aName: string): integer;
begin
  if fZip = nil then
    Exit(-1);
  Result := fZip.IndexOf(aName);
  if Result < 0 then
    for var i := 0 to fZip.FileCount - 1 do
      if SameText(fZip.FileNames[i], aName) then
        Exit(i);
end;

// the name as the package has it, new parts too; '' - none, or removed
function TPackageOoxml.FindPart(const aName: string): string;
begin
  Result := '';
  var name: string := aName;
  if name.StartsWith('/') then
    name := name.Substring(1);
  if fParts.ContainsKey(name) then
    Result := name
  else
  begin
    var index: integer := PartIndex(name);
    if index >= 0 then
      Result := fZip.FileNames[index]
    else
      for var key: string in fParts.Keys do
        if SameText(key, name) then
          Exit(key);
  end;
  for var removed: string in fRemoved do
    if SameText(removed, Result) then
      Exit('');
end;

function TPackageOoxml.HasPart(const aName: string): boolean;
begin
  Result := not FindPart(aName).IsEmpty;
end;

function TPackageOoxml.ContentType(const aName: string): string;
begin
  Result := '';
  var name: string := FindPart(aName);
  var types: TTypesE := Part<TTypesE>(cContentTypes);
  if name.IsEmpty or (types = nil) then
    Exit;
  for var entry: TOverrideE in types.Override do
    if SameText(entry.PartName, '/' + name) then
      Exit(entry.ContentType);
  var extension: string := ExtractFileExt(name).Substring(1);
  for var entry: TDefaultE in types.Default do
    if SameText(entry.Extension, extension) then
      Exit(entry.ContentType);
end;

function TPackageOoxml.GetPart(const aName: string; aClass: TXmliteClass; aEdit: boolean): TXmlite;
begin
  Result := nil;
  // a part asked for before by the name the package has: one lookup (Calcite asks for its sheet several times a cell)
  var name: string := aName;
  var part: TPart;
  if not fParts.TryGetValue(name, part) or part.fLeftOut then
  begin
    name := FindPart(aName);
    if name.IsEmpty then
      Exit;
    if not fParts.TryGetValue(name, part) then
    begin
      part := TPart.Create;
      part.fClass := aClass;
      fParts.Add(name, part);
    end;
  end;
  if part.fClass <> aClass then
  begin
    fIssues.Add(TIssueSeverity.isError, 'PartClass', name, Format('%s is read as %s already, not as %s', [name, part.fClass.ClassName,
      aClass.ClassName]));
    Exit;
  end;
  if part.fXml = nil then
  begin
    var bytes: TBytes;
    fZip.Read(PartIndex(name), bytes);
    part.fXml := aClass.Create;
    // False: read as far as it goes, but it would not be written back as it was
    part.fExact := ReadXml(part.fXml, name, bytes);
  end;
  if aEdit then
    part.fChanged := True;
  Result := part.fXml;
end;

function TPackageOoxml.Part<T>(const aName: string): T;
begin
  Result := T(GetPart(aName, TXmliteClass(GetTypeData(TypeInfo(T))^.ClassType), False));
end;

function TPackageOoxml.EditPart<T>(const aName: string): T;
begin
  Result := T(GetPart(aName, TXmliteClass(GetTypeData(TypeInfo(T))^.ClassType), True));
end;

function TPackageOoxml.Relationships(const aPart, aType: string): TArray<TRelationshipOoxml>;
begin
  Result := [];
  var relationships: TRelationshipsE := Part<TRelationshipsE>(RelationshipsPart(aPart));
  if relationships = nil then
    Exit;
  for var relationship: TRelationshipE in relationships.Relationship do
    if aType.IsEmpty or string(relationship.&Type).EndsWith(aType) then
    begin
      var item: TRelationshipOoxml;
      item.Id := relationship.Id;
      item.&Type := relationship.&Type;
      item.Target := relationship.Target;
      item.Part := '';
      if not relationship.IsPresent('TargetMode') or (relationship.TargetMode <> sttmExternal) then
        item.Part := FindPart(ResolveTarget(aPart, relationship.Target));
      Result := Result + [item];
    end;
end;

function TPackageOoxml.AddPart(const aFrom, aType, aTarget, aContentType: string; aXml: TXmlite; out aId: string): string;
begin
  aId := '';
  Result := ResolveTarget(aFrom, aTarget);
  if not HasPart(cContentTypes) or HasPart(Result) then
  begin
    if HasPart(Result) then
      fIssues.Add(TIssueSeverity.isError, 'PartExists', Result, Format('The package has %s already', [Result]))
    else
      fIssues.Add(TIssueSeverity.isError, 'NoContentTypes', Result, 'The package has no content types: a part cannot be added');
    aXml.Free;
    Exit('');
  end;
  var part: TPart := TPart.Create;
  part.fClass := TXmliteClass(aXml.ClassType);
  part.fXml := aXml;
  part.fExact := True;
  part.fChanged := True;
  part.fNew := True;
  fParts.Add(Result, part);

  var relationshipsName: string := RelationshipsPart(aFrom);
  var relationships: TRelationshipsE := EditPart<TRelationshipsE>(relationshipsName);
  if relationships = nil then
  begin
    relationships := TRelationshipsE.Create;
    var added: TPart := TPart.Create;
    added.fClass := TRelationshipsE;
    added.fXml := relationships;
    added.fExact := True;
    added.fChanged := True;
    added.fNew := True;
    fParts.Add(relationshipsName, added);
  end;
  var number: integer := 1;
  for var existing: TRelationshipE in relationships.Relationship do
    if string(existing.Id).StartsWith('rId') then
      number := Max(number, StrToIntDef(string(existing.Id).Substring(3), 0) + 1);
  var relationship: TRelationshipE := relationships.Add<TRelationshipE>;
  relationship.Id := 'rId' + IntToStr(number);
  if aType.StartsWith('http') then
    relationship.&Type := aType
  else
    relationship.&Type := fMainType + aType;
  relationship.Target := aTarget;
  aId := relationship.Id;

  var contentType: TOverrideE := EditPart<TTypesE>(cContentTypes).Add<TOverrideE>;
  contentType.PartName := '/' + Result;
  contentType.ContentType := aContentType;
end;

procedure TPackageOoxml.RemovePart(const aFrom, aName: string);
begin
  var name: string := FindPart(aName);
  if name.IsEmpty then
    Exit;
  var relationships: TRelationshipsE := EditPart<TRelationshipsE>(RelationshipsPart(aFrom));
  if relationships <> nil then
    for var i := relationships.Relationship.Count - 1 downto 0 do
      if SameText(ResolveTarget(aFrom, relationships.Relationship[i].Target), name) then
        relationships.Remove(relationships.Relationship[i]);
  var types: TTypesE := EditPart<TTypesE>(cContentTypes);
  if types <> nil then
    for var i := types.Override.Count - 1 downto 0 do
      if SameText(types.Override[i].PartName, '/' + name) then
        types.Remove(types.Override[i]);
  var part: TPart;
  if fParts.TryGetValue(name, part) and part.fNew then
    fParts.Remove(name)
  else
  begin
    fRemoved.Add(name);
    if part <> nil then
      part.fLeftOut := True;
  end;
end;

function TPackageOoxml.GetSigned: boolean;
begin
  Result := Length(Relationships('', cSignatureOrigin)) > 0;
end;

function TPackageOoxml.Changed: boolean;
begin
  Result := fRemoved.Count > 0;
  for var part: TPart in fParts.Values do
    if part.fChanged then
      Exit(True);
end;

function TPackageOoxml.Save: boolean;
begin
  if fZip = nil then
    Exit(Fail('NotOpen', 'Nothing is open'));
  if fFileName.IsEmpty then
    Exit(Fail('NoFileName', 'The package has no file to save to (a new one, or opened from a stream): use SaveAs'));
  Result := SaveAs(fFileName);
end;

function TPackageOoxml.SaveAs(const aFileName: string): boolean;
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
        if not TUtility.IsFileError(e) then
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

function TPackageOoxml.SaveAs(aStream: TStream): boolean;
begin
  try
    Result := Write(aStream);
  except
    on e: Exception do
    begin
      if not TUtility.IsFileError(e) then
        raise;
      Result := Fail('File', e.Message);
    end;
  end;
  if Result then
    fError := '';
end;

function TPackageOoxml.CanWrite: boolean;
begin
  if fZip = nil then
    Exit(Fail('NotOpen', 'Nothing is open'));
  // refused rather than written broken
  for var pair: TPair<string, TPart> in fParts do
    if pair.Value.fChanged and not pair.Value.fExact then
      Exit(Fail('NotExact', Format('%s cannot be saved changed: it did not read back exactly, writing it could lose something',
        [pair.Key])));
  Result := True;
end;

function TPackageOoxml.Write(aStream: TStream): boolean;

  procedure AddXml(aTarget: TZipFile; aPart: TPart; const aName: string; aCompression: TZipCompression);
  begin
    var xml: TBytesStream := TBytesStream.Create;
    try
      // as Office writes: compact whatever TBasite.Pretty says, booleans as 1 and 0
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
  // a changed package is a new version, as Office saves it; a core part that would not be written back exactly stays as it was
  if Changed then
  begin
    var core: string := fProperties.PartName;
    if not core.IsEmpty and (Part<TCorePropertiesE>(core) <> nil) and fParts[core].fExact then
      fProperties.Modified := UtcNow;
  end;
  var target: TZipFile := TZipFile.Create;
  try
    target.Open(aStream, zmWrite);
    // the same order and compression as the original
    for var i := 0 to fZip.FileCount - 1 do
    begin
      var name: string := fZip.FileNames[i];
      if fRemoved.Contains(name) then
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
