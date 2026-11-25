unit ProRock.Xmlite.Utility;

// XML-level functions: reading, escaping, names (internal)

interface

{$SCOPEDENUMS ON}

uses System.Classes, System.SysUtils, System.StrUtils, System.Generics.Collections, System.Generics.Defaults,
  ProRock.Utility;

type
  {$REGION 'ProRock.Utility: its types, so a unit names only this Utility'}
  TNaming = ProRock.Utility.TNaming;
  TCustomAttributeClass = ProRock.Utility.TCustomAttributeClass;
  TNamingAttribute = ProRock.Utility.TNamingAttribute;
  TWriterBase = ProRock.Utility.TWriterBase;
  TReaderBase = ProRock.Utility.TReaderBase;
  TIssueSeverity = ProRock.Utility.TIssueSeverity;
  TIssue = ProRock.Utility.TIssue;
  TIssueEvent = ProRock.Utility.TIssueEvent;
  TIssues = ProRock.Utility.TIssues;
  PIssues = ProRock.Utility.PIssues;
  // generics have no aliases: empty subclasses; a parent's object does not go into a child-typed variable (E2008)
  THashSet<T> = class(ProRock.Utility.THashSet<T>);
  THashedObjectList<T: class> = class(ProRock.Utility.THashedObjectList<T>);
  TDictObjectList<K; V: class> = class(ProRock.Utility.TDictObjectList<K, V>);
  TDualDictionary<TKey, TValue> = class(ProRock.Utility.TDualDictionary<TKey, TValue>);
  TSummaryDictionary<T: class> = class(ProRock.Utility.TSummaryDictionary<T>);
  {$ENDREGION}

  TUtility = class abstract(ProRock.Utility.TUtility)
  public const
    // the "xml" prefix is bound to it by definition - documents never declare it (xml:lang, xml:space)
    cXmlPrefix = 'xml';
    cXmlPrefixUri = 'http://www.w3.org/XML/1998/namespace';
    // xsi:type, xsi:nil - the prefix is usual, not fixed: it is declared like any other
    cXsiPrefix = 'xsi';
    cXsiUri = 'http://www.w3.org/2001/XMLSchema-instance';
    // Office's namespaces, transitional and strict
    cOoxmlUriPrefix = 'http://schemas.openxmlformats.org/';
    cOoxmlStrictUriPrefix = 'http://purl.oclc.org/ooxml/';
  end;

  TXmliteComponentType = (xctUndefined, xctSimpleType, xctComplexType, xctAttribute, xctAttributeGroup, xctElement, xctElementGroup);
  TTagType = (xttNone, xttOpenClose, xttEmpty, xttText);

  // a dictionary key with its own comparers: the RTL's default ones compare a record's memory - string pointers, not text
  TUriedName = record
    Uri, Name: string;
  public
    constructor Create(const aUri, aName: string); overload;
    constructor Create(const aName: string); overload;
    class operator Equal(const aRecordA, aRecordB: TUriedName): boolean;

  public type
    TComparer = class(TInterfacedObject, IComparer<TUriedName>)
    public
      function Compare(const aLeft, aRight: TUriedName): integer;
    end;

    TEqualityComparer = class(TInterfacedObject, IEqualityComparer<TUriedName>)
    public
      function Equals(const aLeft, aRight: TUriedName): boolean; reintroduce;
      function GetHashCode(const aValue: TUriedName): integer; reintroduce;
    end;
  end;

  // the namespaces in scope (prefix -> URI), read only: an element's scope is shared with the elements inside it
  TXmlns = class
  private
    fUris: TDictionary<string, string>;
    fDefaultUri: string;
    function GetUri(const aPrefix: string): string;
    function GetCount: integer;
  public
    constructor Create;
    destructor Destroy; override;

    function TryGetValue(const aPrefix: string; out aUri: string): boolean;
    function ContainsKey(const aPrefix: string): boolean;
    function GetEnumerator: TDictionary<string, string>.TPairEnumerator;

    property Count: integer read GetCount;
    property DefaultUri: string read fDefaultUri;
    // a prefix not declared: the default namespace ('xml' is always XML's own)
    property Uri[const aPrefix: string]: string read GetUri; default;
  end;

  // the reader's: declarations added while a start tag is read, then shared by its elements
  TXmlnsScope = class(TXmlns)
  private
    fOwners: integer;
  public
    constructor Create; overload;
    constructor Create(aParent: TXmlns); overload;

    procedure Declare(const aPrefix, aUri: string);
    procedure DeclareDefault(const aUri: string);
    procedure Undeclare(const aPrefix: string);

    // one owner more: each owner calls Release instead of Free, the last one frees it
    function Share: TXmlnsScope;
    procedure Release;
  end;

implementation

uses System.Hash, System.Math;

{ TUriedName }

constructor TUriedName.Create(const aUri, aName: string);
begin
  Uri := aUri;
  Name := aName;
end;

constructor TUriedName.Create(const aName: string);
begin
  Uri := '';
  Name := aName;
end;

class operator TUriedName.Equal(const aRecordA, aRecordB: TUriedName): boolean;
begin
  Result := (aRecordA.Uri = aRecordB.Uri) and (aRecordA.Name = aRecordB.Name);
end;

{ TUriedName.TComparer }

function TUriedName.TComparer.Compare(const aLeft, aRight: TUriedName): integer;
begin
  Result := CompareStr(aLeft.Uri, aRight.Uri);
  if Result = 0 then
    Result := CompareStr(aLeft.Name, aRight.Name);
end;

{ TUriedName.TEqualityComparer }

function TUriedName.TEqualityComparer.Equals(const aLeft, aRight: TUriedName): boolean;
begin
  Result := aLeft = aRight;
end;

function TUriedName.TEqualityComparer.GetHashCode(const aValue: TUriedName): integer;
begin
  // the name only: a URI is long and shared by a class's names (hashing it was ~10% of a read); Equals tells URIs apart
{$IF CompilerVersion >= 35.0} // Delphi 11+
  Result := THashFNV1a32.GetHashValue(aValue.Name);
{$ELSE}
  Result := THashBobJenkins.GetHashValue(aValue.Name);
{$ENDIF}
end;

{ TXmlns }

constructor TXmlns.Create;
begin
  inherited Create;
  fUris := TDictionary<string, string>.Create;
end;

destructor TXmlns.Destroy;
begin
  fUris.Free;
  inherited;
end;

function TXmlns.GetUri(const aPrefix: string): string;
begin
  if aPrefix.IsEmpty or not fUris.TryGetValue(aPrefix, Result) then
    if aPrefix = TUtility.cXmlPrefix then
      Result := TUtility.cXmlPrefixUri
    else
      Result := fDefaultUri;
end;

function TXmlns.GetCount: integer;
begin
  Result := fUris.Count;
end;

function TXmlns.TryGetValue(const aPrefix: string; out aUri: string): boolean;
begin
  Result := fUris.TryGetValue(aPrefix, aUri);
end;

function TXmlns.ContainsKey(const aPrefix: string): boolean;
begin
  Result := fUris.ContainsKey(aPrefix);
end;

function TXmlns.GetEnumerator: TDictionary<string, string>.TPairEnumerator;
begin
  Result := fUris.GetEnumerator;
end;

{ TXmlnsScope }

constructor TXmlnsScope.Create;
begin
  inherited Create;
  fOwners := 1;
end;

constructor TXmlnsScope.Create(aParent: TXmlns);
begin
  Create;
  for var pair: TPair<string, string> in aParent.fUris do
    fUris.Add(pair.Key, pair.Value);
  fDefaultUri := aParent.fDefaultUri;
end;

procedure TXmlnsScope.Declare(const aPrefix, aUri: string);
begin
  fUris.AddOrSetValue(aPrefix, aUri);
end;

procedure TXmlnsScope.DeclareDefault(const aUri: string);
begin
  fDefaultUri := aUri;
end;

procedure TXmlnsScope.Undeclare(const aPrefix: string);
begin
  fUris.Remove(aPrefix);
end;

function TXmlnsScope.Share: TXmlnsScope;
begin
  Inc(fOwners);
  Result := Self;
end;

procedure TXmlnsScope.Release;
begin
  if Self = nil then
    Exit;
  Dec(fOwners);
  if fOwners <= 0 then
    Free;
end;

end.
