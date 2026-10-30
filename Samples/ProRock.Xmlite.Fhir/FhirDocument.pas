unit FhirDocument;

// A FHIR document - a Bundle or a single resource - read into the classes generated from the FHIR R4 schemas, described
// for the list (resource, id, what, value, when), and written back. The resource of a Bundle entry is a choice of all
// 146 resource types: Resource.Chosen gives the one there, and only that one was created

interface

uses System.SysUtils, System.Classes, System.Diagnostics, System.Generics.Collections,
  ProRock.Basite, ProRock.Xmlite, ProRock.Xmlite.Schema.Fhir, ProRock.Xmlite.Schema.Xhtml;

type
  TFhirEntry = record
    Resource: TResourceCT;
    ResourceType, Id, What, Value, When: string;
  end;

  TFhirDocument = class
  private
    fRoot: TResourceCT; // a TBundleE, or the resource of a file that holds one
    fEntries: TList<TFhirEntry>;
    fReadMs: Double;

    procedure Describe;
  public
    constructor Create;
    destructor Destroy; override;

    // raises EFhirDocument for a file that is not FHIR XML
    procedure Load(const aFileName: string);
    procedure Save(const aFileName: string);

    // the narrative of a resource (the XHTML of text/div), as plain text
    function Narrative(aResource: TResourceCT): string;

    // the entries of the file repeated to aCount and read again: how long a large Bundle takes
    function SpeedTest(aCount: integer): string;

    property Entries: TList<TFhirEntry> read fEntries;
    property ReadMs: Double read fReadMs;
  end;

  EFhirDocument = class(Exception);

implementation

uses System.IOUtils, System.StrUtils, System.RegularExpressions, ProRock.Xmlite.Utility;

const
  cFhirUri = 'http://hl7.org/fhir';

// a value of a choice (value[x], effective[x]) as text: the types the Observation examples use
function ChoiceText(aChosen: TBasite): string;
begin
  Result := '';
  if aChosen = nil then
    Exit;

  if aChosen.InheritsFrom(TQuantityCT) then
    Result := (string(TQuantityCT(aChosen).Value.Value) + ' ' + string(TQuantityCT(aChosen).&Unit.Value)).Trim
  else if aChosen.InheritsFrom(TCodeableConceptCT) then
  begin
    var concept: TCodeableConceptCT := TCodeableConceptCT(aChosen);
    Result := concept.Text.Value;
    if (Result = '') and (concept.Coding.Count > 0) then
      Result := concept.Coding[0].Display.Value;
  end
  else if aChosen.InheritsFrom(TStringCT) then
    Result := TStringCT(aChosen).Value
  else if aChosen.InheritsFrom(TBooleanCT) then
    Result := BoolToStr(TBooleanCT(aChosen).Value, True)
  else if aChosen.InheritsFrom(TIntegerCT) then
    Result := IntToStr(TIntegerCT(aChosen).Value)
  else if aChosen.InheritsFrom(TDateTimeCT) then
    Result := TDateTimeCT(aChosen).Value
  else if aChosen.InheritsFrom(TPeriodCT) then
  begin
    Result := TPeriodCT(aChosen).Start.Value;
    if TPeriodCT(aChosen).&End.Value <> '' then
      Result := Result + ' - ' + string(TPeriodCT(aChosen).&End.Value);
  end
  else if aChosen.InheritsFrom(TSampledDataCT) then
    Result := Format('sampled data, %d dimension(s)', [TSampledDataCT(aChosen).Dimensions.Value])
  else
    Result := '(' + aChosen.ClassName + ')';
end;

{ TFhirDocument }

constructor TFhirDocument.Create;
begin
  inherited;
  fEntries := TList<TFhirEntry>.Create;
end;

destructor TFhirDocument.Destroy;
begin
  fEntries.Free;
  fRoot.Free;
  inherited;
end;

procedure TFhirDocument.Load(const aFileName: string);
begin
  var xml: string := TFile.ReadAllText(aFileName, TEncoding.UTF8);

  // the root element names the resource: <Bundle>, <Observation>... - its class comes from the metadata the generated
  // unit registers, by namespace and name
  var root: TMatch := TRegEx.Match(xml, '<([A-Za-z]+)[\s>/]'); // a letter: not <?xml or <!--
  if not root.Success then
    raise EFhirDocument.Create('Not an XML file');
  var meta: TMetaBasite := TMetaBank.Xmlite.Namespaces.GetMetaBasite(cFhirUri, xctElement, root.Groups[1].Value);
  if (meta = nil) or not meta.ClassItself.InheritsFrom(TResourceCT) then
    raise EFhirDocument.CreateFmt('<%s> is not a FHIR R4 resource', [root.Groups[1].Value]);

  FreeAndNil(fRoot);
  fEntries.Clear;
  fRoot := TResourceCT(meta.ClassItself.Create);

  // read without a copy of the text: xml is not needed afterwards
  var watch: TStopwatch := TStopwatch.StartNew;
  if not fRoot.FromXmlInPlace(xml) then
    raise EFhirDocument.Create('The file is not well-formed XML');
  fReadMs := watch.Elapsed.TotalMilliseconds;

  Describe;
end;

procedure TFhirDocument.Save(const aFileName: string);
begin
  if fRoot <> nil then
    TFile.WriteAllText(aFileName, fRoot.ToXml, TEncoding.UTF8);
end;

procedure TFhirDocument.Describe;

  procedure Add(aResource: TResourceCT);
  begin
    var entry: TFhirEntry := Default(TFhirEntry);
    entry.Resource := aResource;
    // FHIR's own element "meta" hides ProRock's Meta in every resource class: TBasite(...).Meta is the class metadata
    entry.ResourceType := TBasite(aResource).Meta.Xmlite.Name;
    entry.Id := aResource.Id.Value;

    if aResource.InheritsFrom(TObservationCT) then
    begin
      var observation: TObservationCT := TObservationCT(aResource);
      entry.What := ChoiceText(observation.Code);
      // value[x]: one of eleven types - ValueChosen is the one in the document, nil when there is none
      entry.Value := ChoiceText(observation.ValueChosen);
      if entry.Value = '' then // blood pressure: the values are in the components
        for var component: TObservationComponentCT in observation.Component do
          entry.Value := entry.Value + IfThen(entry.Value = '', '', ' / ') + ChoiceText(component.ValueChosen);
      entry.When := ChoiceText(observation.EffectiveChosen);
    end
    else if aResource.InheritsFrom(TPatientCT) then
    begin
      var patient: TPatientCT := TPatientCT(aResource);
      if patient.Name.Count > 0 then
      begin
        var name: THumanNameCT := patient.Name[0];
        for var given: TStringCT in name.Given do
          entry.What := entry.What + string(given.Value) + ' ';
        entry.What := entry.What + string(name.Family.Value);
      end;
      entry.When := patient.BirthDate.Value;
    end;

    fEntries.Add(entry);
  end;

begin
  if fRoot.InheritsFrom(TBundleCT) then
  begin
    for var bundleEntry: TBundleEntryCT in TBundleCT(fRoot).Entry do
      // the entry's resource: a choice of every resource type - Chosen is the one there
      if (bundleEntry.Resource.Chosen <> nil) and bundleEntry.Resource.Chosen.InheritsFrom(TResourceCT) then
        Add(TResourceCT(bundleEntry.Resource.Chosen));
  end
  else
    Add(fRoot);
end;

function TFhirDocument.Narrative(aResource: TResourceCT): string;

  // InnerText would give the text alone; here a block element (p, li, tr...) also ends a line and a cell is followed by a
  // tab, so the narrative reads as it is laid out
  procedure AddText(aElement: TXmlite; aText: TStringBuilder);

    procedure AddChild(aChild: TBasite; const aName: string);
    begin
      if (aChild = nil) or not aChild.InheritsFrom(TXmlite) then
        Exit;
      AddText(TXmlite(aChild), aText);
      if MatchText(aName, ['p', 'div', 'li', 'tr', 'br', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'table', 'ul', 'ol']) then
        aText.AppendLine
      else if MatchText(aName, ['td', 'th']) then
        aText.Append(#9);
    end;

  begin
    // mixed content (p, td, b...): XmlContent holds its text runs and child elements in document order; whitespace
    // collapses as in HTML
    if TBasite(aElement).Meta.Xmlite.Ordered then
      for var node: TXmliteNode in aElement.XmlContent do
        if node.IsText then
          aText.Append(TRegEx.Replace(node.Text, '\s+', ' '))
        else
          AddChild(node.Element, node.Name)
    else
      // an element that keeps no order (a table, its rows): its children in schema order - a sequence's order - from the
      // class's metadata
      for var child: TProperty in TBasite(aElement).Meta.Xmlite.Elements.Values do
        case child.PropertyType of
          ptBasite:
            if aElement.IsPresent(child) then
              AddChild(TPropertyBasite(child).ObjectPointer(aElement)^, child.Xmlite.Name);
          ptBasiteList:
            if TPropertyBasiteList(child).ObjectPointer(aElement)^ <> nil then
              for var item: TBasite in TPropertyBasiteList(child).ObjectPointer(aElement)^ do
                AddChild(item, child.Xmlite.Name);
        end;
  end;

begin
  Result := '';
  if (aResource = nil) or not aResource.InheritsFrom(TDomainResourceCT) then
    Exit;
  var text: TStringBuilder := TStringBuilder.Create;
  try
    AddText(TDomainResourceCT(aResource).Text.&Div, text);
    // each line trimmed: the indentation of the document was text too
    var lines: TArray<string> := text.ToString.Split([sLineBreak]);
    for var i := 0 to High(lines) do
      lines[i] := lines[i].Trim;
    Result := string.Join(sLineBreak, lines).Trim;
  finally
    text.Free;
  end;
end;

function TFhirDocument.SpeedTest(aCount: integer): string;
begin
  if (fRoot = nil) or (fEntries.Count = 0) then
    Exit('Open a file first');

  // the entries written once, then repeated into one Bundle of aCount entries
  var entriesXml: TStringBuilder := TStringBuilder.Create;
  try
    for var entry: TFhirEntry in fEntries do
    begin
      var resourceXml: string := entry.Resource.ToXml('', False);
      entriesXml.Append('<entry><resource>').Append(resourceXml).Append('</resource></entry>');
    end;
    var once: string := entriesXml.ToString;
    entriesXml.Clear;
    entriesXml.Append('<Bundle xmlns="' + cFhirUri + '"><type value="collection"/>');
    for var i := 1 to (aCount + fEntries.Count - 1) div fEntries.Count do
      entriesXml.Append(once);
    entriesXml.Append('</Bundle>');

    var xml: string := entriesXml.ToString;
    var megabytes: Double := Length(xml) * SizeOf(Char) / 1048576;
    var bundle: TBundleE := TBundleE.Create;
    try
      var watch: TStopwatch := TStopwatch.StartNew;
      bundle.FromXmlInPlace(xml);
      var readMs: Double := watch.Elapsed.TotalMilliseconds;
      watch := TStopwatch.StartNew;
      var written: string := bundle.ToXml;
      var writeMs: Double := watch.Elapsed.TotalMilliseconds;
      Result := Format('A Bundle of %d resources (%.1f MB): read in %.0f ms, written in %.0f ms (%.1f MB)',
        [bundle.Entry.Count, megabytes, readMs, writeMs, Length(written) * SizeOf(Char) / 1048576]);
    finally
      bundle.Free;
    end;
  finally
    entriesXml.Free;
  end;
end;

end.
