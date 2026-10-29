unit ProRock.Xmlite;

interface

uses System.Classes, System.SysUtils, System.StrUtils, System.Generics.Collections, System.Generics.Defaults, System.Rtti, System.Math,
  System.SyncObjs, System.TypInfo,
  ProRock.Basite, ProRock.Utility, ProRock.Xmlite.Utility;

const
  cXmlDeclaration = '<?xml version="1.0" encoding="UTF-8"?>';

  cDefaultSuffixSimpleType = 'ST';
  cDefaultSuffixComplexType = 'CT';
  cDefaultSuffixAttribute = 'A';
  cDefaultSuffixAttributeGroup = 'AG';
  cDefaultSuffixElement = 'E';
  cDefaultSuffixElementGroup = 'EG';

  cDefaultSuffix: array [TXmliteComponentType] of string = ('', cDefaultSuffixSimpleType, cDefaultSuffixComplexType,
    cDefaultSuffixAttribute, cDefaultSuffixAttributeGroup, cDefaultSuffixElement, cDefaultSuffixElementGroup);

  cDefaultNaming = TNaming.nCamelCase;

type
  {$REGION 'ProRock.Basite types aliases'}
  TNaming = ProRock.Utility.TNaming;
  TNamingAttribute = ProRock.Utility.TNamingAttribute;
  TBaseTypeAttribute = ProRock.Basite.TBaseTypeAttribute;
  TNameAttribute = ProRock.Basite.TNameAttribute;
  TDefaultAttribute = ProRock.Basite.TDefaultAttribute;
  TRequiredAttribute = ProRock.Basite.TRequiredAttribute;
  TChoiceAttribute = ProRock.Basite.TChoiceAttribute;
  TEnumCaptionAttribute = ProRock.Basite.TEnumCaptionAttribute;
  TValueAliasAttribute = ProRock.Basite.TValueAliasAttribute;
  TBasite = ProRock.Basite.TBasite;
  TBasiteList = Prorock.Basite.TBasiteList;
  TPropertyType = ProRock.Basite.TPropertyType;
  TProperty = ProRock.Basite.TProperty;
  TPropertyData = ProRock.Basite.TPropertyData;
  TPropertyClass = ProRock.Basite.TPropertyClass;
  TPropertyBasite = ProRock.Basite.TPropertyBasite;
  TPropertyBasiteList = ProRock.Basite.TPropertyBasiteList;
  TPropertyDataList = ProRock.Basite.TPropertyDataList;
  TPropertyList = ProRock.Basite.TPropertyList;
  TMeta = ProRock.Basite.TMeta;
  TMetaType = ProRock.Basite.TMetaType;
  TMetaBasite = ProRock.Basite.TMetaBasite;
  TMetaBasiteList = ProRock.Basite.TMetaBasiteList;
  TMetaBank = ProRock.Basite.TMetaBank;
  {$ENDREGION}

  // an element the schema does not describe, kept as its text, written back after the AfterCount-th item of After (nil:
  // first); Namespaces - the prefixes ('' - default) it takes from its ancestors
  TXmliteUnknown = record
    Xml: string;
    After: TProperty;
    AfterCount: integer;
    Namespaces: TArray<TPair<string, string>>;
  end;

  TXmliteNodeKind = (xnkText, xnkElement, xnkUnknown);

  // a child in XmlContent: a text run, an element (its object, or a plain value: Element nil, Index in its list) or a kept
  // unknown element (Index in XmlUnknown, Text its name)
  TXmliteNode = record
    Kind: TXmliteNodeKind;
    Text: string;
    Element: TBasite;
    ElementProperty: TProperty; // nil for xs:any and unknown elements
    Index: integer;
    function IsText: boolean; inline;
    function IsElement<T: TBasite>: boolean; inline;
    // the element as its class, EInvalidCast for another one: node.ElementAs<TAE>.Href
    function ElementAs<T: TBasite>: T; inline;
    // the element's XML name (b, span) from the meta, an unknown element's (its Text); '' for text
    function Name: string;
  end;

  TWriterXmlite = class(TWriterBase)
  private
    fPretty: boolean;
    fDeclared: TObjectList<TDictionary<string, string>>; // prefix ('' - default) -> URI declared by the elements open now

    procedure WriteAttribute(const aName, aValue: string; const aPrefix: string = ''); inline;
    procedure WriteAttributes(aObject: TBasite; aNamespaces: boolean = False); inline;
  public
    destructor Destroy; override;

    property Pretty: boolean read fPretty write fPretty;

    procedure PopDeclared;
    // a kept element, declaring the outside prefixes it uses whose binding here differs
    procedure AddUnknown(const aUnknown: TXmliteUnknown);

    procedure AddIndent; reintroduce; inline;
    procedure FinishLine(const aEndingText: string = ''); reintroduce; inline;

    procedure AddTagOpen(const aName: string; aObject: TBasite; aNamespaces: boolean); inline;
    procedure AddTagEmpty(const aName: string; aObject: TBasite; aNamespaces: boolean); inline;
    procedure AddTagClose(const aName: string); inline;
    // a tag with attributes and text content in one line - indentation would become a part of the text
    procedure AddTagText(const aName: string; aObject: TBasite; aNamespaces: boolean; const aText: string); inline;
    procedure AddTextNode(const aName, aValue: string; aFieldInfo: TProperty; aObject: TBasite = nil); inline;
    procedure AddXmlEscape(const aString: string); inline;
    // text of mixed content: line breaks and tabs as they are, so the text reads back the same
    procedure AddTextEscape(const aString: string);
  end;

  TXmlite = class(TBasite)
  public
    class function XmlToObject(const aXml: string; aObject: TBasite): boolean; inline;
    class function ObjectToXml(aObject: TBasite): string; inline;

  private
    fXmlPrefix, fXmlName: string;
    fXmlAttributes: TDictionary<string, string>;
    fXmlAttributeNamespaces: TDictionary<string, string>;
    fXmlns: TXmlns;
    fXmlText: string;
    fXmlAny: TBasiteList<TBasite>;
    fXmlUnknown: TList<TXmliteUnknown>; // created with the first one
    fXmlContent: TList<TXmliteNode>; // created with the first node
    fXmlPosition: cardinal;
    function GetXmlUnknown: TList<TXmliteUnknown>;
    function GetXmlContent: TList<TXmliteNode>;
    function GetXmlText: string;
    procedure SetXmlText(const aValue: string);
    // a node at the end of XmlContent; text joins a text node before it (text, CDATA, text)
    procedure AddNode(aKind: TXmliteNodeKind; const aText: string; aElement: TBasite; aProperty: TProperty; aIndex: integer);
    function PropertyOfClass(aClass: TClass; const aName: string = ''): TProperty;
    function AddElement(aClass: TClass; const aProperty: string): TBasite;
  protected
    procedure Initialize; override;
    procedure Deinitialize; override;

    procedure DoBeforeSerialization; virtual;
    procedure DoAfterSerialization; virtual;
    procedure DoBeforeParsing; virtual;
    procedure DoAfterParsing; virtual;
  public
    property Xmlns: TXmlns read fXmlns;

    property XmlPrefix: string read fXmlPrefix write fXmlPrefix;
    property XmlName: string read fXmlName write fXmlName;
    property XmlAny: TBasiteList<TBasite> read fXmlAny;
    // the element's place in the document it was read from (0 - not read)
    property XmlPosition: cardinal read fXmlPosition;
    property XmlAttributes: TDictionary<string, string> read fXmlAttributes; // attributes without a property, kept for the round trip
    // elements without a property, kept for the round trip as their text (Clear removes them)
    property XmlUnknown: TList<TXmliteUnknown> read GetXmlUnknown;
    // [TOrdered]/[TMixed]: the children (and text) in document order, written so; children not in it come after. Remove a
    // child by Remove - one deleted through its list leaves a dangling node
    property XmlContent: TList<TXmliteNode> read GetXmlContent;
    // the text before the first child element; in mixed content the leading text node of XmlContent
    property XmlText: string read GetXmlText write SetXmlText;
    // prefix -> URI declared again on write: the document's declarations (prefixes appear in values: mc:Ignorable)
    property XmlAttributeNamespaces: TDictionary<string, string> read fXmlAttributeNamespaces;

    // writes xsi:type: the element holds aType, a complex type derived from its own - Created.SetXsiType(TW3cdtfCT).
    // Raises EArgumentException for any other class
    procedure SetXsiType(aType: TClass);

    // a new child of class T in the property of that class, in XmlContent of an ordered element: Div.Add<TPE>.AddText('...');
    // a single object's property gives its object. EArgumentException when no property, or more than one, has the class T
    function Add<T: TBasite>: T; overload;
    function Add<T: TBasite>(const aProperty: string): T; overload;
    // a text run at the end of mixed content; elsewhere added to XmlText
    procedure AddText(const aText: string);
    // a child out of XmlContent and its property: a list item freed, a single object cleared
    procedure Remove(aElement: TBasite);
    // all text of the element and its children in document order: Observation.Text.&Div.InnerText
    function InnerText: string;

    procedure Clear; overload; override;
    function IsEmptyOrDefault: boolean; override;
    function HasContent: boolean; override;
  end;

  TXmliteList<T: TXmlite, constructor> = class(TBasiteList<T>);
  // a list of plain values: TSTXstringSTList = class(TXmliteValueList<TSTXstringST>) - Authors.Author.Add('Ann')
  TXmliteValueList<T> = class(TBasiteValueList<T>);
  TXmliteList = TXmliteList<TXmlite>;

  // the kind of schema component a generated class stands for
  TXmliteComplexType = class(TXmlite);
  TXmliteComplexTypeRestricted = class(TXmlite);
  TXmliteAttributeGroup = class(TXmlite);
  TXmliteElement = class(TXmlite);
  TXmliteElementGroup = class(TXmlite);

  TNamespace = class;

  TBasiteHelper = class helper for TBasite
  private
    class var fPretty: boolean;
  public
    class property Pretty: boolean read fPretty write fPretty;

  private
    function TagType: TTagType;

    function ReadTagContents(var aCursor: PChar; const aName: string; aXmlns: TXmlns): boolean;

    function FromXml(var aXmlCursor: PChar; aXmlns: TXmlns = nil): boolean; overload;
    // aScope: the default namespace in scope; aNamespaces: the element declares its namespaces (a root)
    procedure ToXml(aWriter: TWriterXmlite; const aName: string; aScope: TNamespace; aNamespaces: boolean;
      aXmlHeader: boolean = False); overload;
  public
    constructor CreateFromXml(const aXml: string);

    // the namespace declarations a root writes; aDeclared, when given, gets them (prefix, '' - default -> URI)
    function GetXmlns(aDeclared: TDictionary<string, string> = nil): string;

    procedure ToXml(aStream: TStream; const aName: string = ''; aXmlHeader: boolean = True); overload;
    function ToXml(const aName: string = ''; aXmlHeader: boolean = True): string; overload;
    // reads a copy: aXml stays as it is
    function FromXml(const aXml: string): boolean; overload;
    // reads without a copy - aXml is changed by the read (large documents read once)
    function FromXmlInPlace(var aXml: string): boolean;
  end;

  TXmliteElementAttribute = class(TCustomAttribute);
  // the property holds the element's text content (XSD simpleContent: text and attributes, no child elements)
  TXmliteTextAttribute = class(TCustomAttribute);
  TXmliteAnyElementAttribute = class(TCustomAttribute);
  TXmliteAnyAttributeAttribute = class(TCustomAttribute); // reserved: unknown attributes are kept in XmlAttributes

  TNamespaceAttribute = class(TCustomAttribute)
  private
    fUri: string;
  public
    constructor Create(const aUri: string);
    property Uri: string read fUri;
  end;

  // XSD form="qualified": an attribute written prefixed also in elements of its own namespace (wsu:Id in wsu:Timestamp)
  TQualifiedAttribute = class(TCustomAttribute);

  // the children's document order kept in XmlContent (XSD: a repeating choice - one list per element would lose it)
  TOrderedAttribute = class(TCustomAttribute);
  // XSD mixed="true": text runs between the children kept too (an XHTML <p>); an ordered element
  TMixedAttribute = class(TCustomAttribute);

  TPropertyXmlite = class(TPropertyExtension)
  private
    fNamespace: TNamespace;
    fName, fNamePrefixed, fNameUried: string;
    fQualified: boolean;
  protected
    procedure NamespaceUnregister;
    procedure NamespaceRegister(aNamespace: TNamespace);
  public
    constructor Create(aProperty: TProperty); override;

    // a property's XML name: [TName], property [TNaming], then the class's (or, in a namespace, the namespace's) naming
    class function XmlName(aProperty: TProperty): string; static;

    property Name: string read fName;
    property NamePrefixed: string read fNamePrefixed;
    property NameUried: string read fNameUried;
    // [TQualified]: an attribute written prefixed even in an element of its own namespace
    property Qualified: boolean read fQualified;

    property Namespace: TNamespace read fNamespace;
  end;

  TPropertyHelper = class helper for TProperty
  public
    function Xmlite: TPropertyXmlite;
  end;

  TMetaXmlite = class(TMetaExtension)
  private
    fName, fNamePrefixed: string;
    fComponentType: TXmliteComponentType;
    fNamespace: TNamespace;
  protected
    procedure NamespaceUnregister; virtual;
    procedure NamespaceRegister(aNamespace: TNamespace; aType: TXmliteComponentType); virtual;
  public
    constructor Create(aMeta: TMeta); override;

    property ComponentType: TXmliteComponentType read fComponentType;
    property Name: string read fName;
    property NamePrefixed: string read fNamePrefixed;
    property Namespace: TNamespace read fNamespace;
  end;

  TMetaHelper = class helper for TMeta
  public
    function Xmlite: TMetaXmlite;
  end;

  TMetaTypeXmlite = class(TMetaXmlite)
  private
    function GetMeta: TMetaType;
  public
    constructor Create(aMeta: TMetaType); reintroduce; virtual;

    property Meta: TMetaType read GetMeta;
  end;

  TMetaTypeHelper = class helper for TMetaType
  public
    function Xmlite: TMetaTypeXmlite;
  end;

  TMetaBasiteXmlite = class(TMetaXmlite)
  private
    fIsTXmlite, fProcessAnyElement, fProcessAnyAttribute, fOrdered, fMixed: boolean;
    fAttributes: TDictObjectList<TUriedName, TPropertyData>;
    fElements: TDictObjectList<TUriedName, TProperty>;
    fTextProperty: TPropertyData;

    function FieldIsElement(aField: TProperty): boolean; inline;
    function FieldIsText(aField: TProperty): boolean; inline;
    function GetMeta: TMetaBasite;
    function GetProcessAnyAttribute: boolean;
    function GetProcessAnyElement: boolean;
    procedure SetMixed(aValue: boolean);
  protected
    procedure NamespaceUnregister; override;
    procedure NamespaceRegister(aNamespace: TNamespace; aType: TXmliteComponentType); override;
  public
    constructor Create(aMeta: TMetaBasite); reintroduce; virtual;
    destructor Destroy; override;

    property Meta: TMetaBasite read GetMeta;
    property Attributes: TDictObjectList<TUriedName, TPropertyData> read fAttributes;
    property Elements: TDictObjectList<TUriedName, TProperty> read fElements;
    // the [TXmliteText] property - the element's text content; nil when the element has no simpleContent
    property TextProperty: TPropertyData read fTextProperty;
    property IsTXmlite: boolean read fIsTXmlite;

    property ProcessAnyElement: boolean read GetProcessAnyElement write fProcessAnyElement;
    property ProcessAnyAttribute: boolean read GetProcessAnyAttribute write fProcessAnyAttribute; // reserved
    // [TOrdered], [TMixed] (inherited; mixed is ordered) - changeable at run time, for every object of the class
    property Ordered: boolean read fOrdered write fOrdered;
    property Mixed: boolean read fMixed write SetMixed;
  end;

  TMetaBasiteHelper = class helper for TMetaBasite
  public
    function Xmlite: TMetaBasiteXmlite;
  end;

  TNamespace = class
  private
    fUnitQualifiedName: string;
    fPrefix: string;
    fSuffixSimpleType, fSuffixComplexType, fSuffixAttribute, fSuffixAttributeGroup, fSuffixElement, fSuffixElementGroup: string;
    fSuffixLengthSimpleType, fSuffixLengthComplexType, fSuffixLengthAttribute, fSuffixLengthAttributeGroup, fSuffixLengthElement,
      fSuffixLengthElementGroup: integer;
    fUri: string;
    fNaming: TNaming;
    fSimpleTypes, fAttributes: TDictObjectList<string, TMetaType>;
    fComplexTypes, fAttributeGroups, fElements, fElementGroups: TDictObjectList<string, TMetaBasite>;
  public
    constructor Create(const aUri, aPrefix: string; aNaming: TNaming; const aSuffixSimpleType, aSuffixComplexType, aSuffixAttribute,
      aSuffixAttributeGroup, aSuffixElement, aSuffixElementGroup: string);
    destructor Destroy; override;

    property UnitQualifiedName: string read fUnitQualifiedName;
    property Uri: string read fUri;
    property Prefix: string read fPrefix;
    property Naming: TNaming read fNaming;

    property SuffixSimpleType: string read fSuffixSimpleType;
    property SuffixComplexType: string read fSuffixComplexType;
    property SuffixAttribute: string read fSuffixAttribute;
    property SuffixAttributeGroup: string read fSuffixAttributeGroup;
    property SuffixElement: string read fSuffixElement;
    property SuffixElementGroup: string read fSuffixElementGroup;

    property SimpleTypes: TDictObjectList<string, TMetaType> read fSimpleTypes;
    property ComplexTypes: TDictObjectList<string, TMetaBasite> read fComplexTypes;
    property Attributes: TDictObjectList<string, TMetaType> read fAttributes;
    property AttributeGroups: TDictObjectList<string, TMetaBasite> read fAttributeGroups;
    property Elements: TDictObjectList<string, TMetaBasite> read fElements;
    property ElementGroups: TDictObjectList<string, TMetaBasite> read fElementGroups;

    procedure Add(aMeta: TMeta; aType: TXmliteComponentType);
  end;

  TNamespaceList = class
  type
    TNamespaceIterate = reference to procedure (aNamespace: TNamespace);
  private
    fData: TDictObjectList<string, TNamespace>;
    fLocker: TCriticalSection;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    procedure Add(aNamespace: TNamespace);

    function GetNamespace(const aUri: string): TNamespace;
    function GetTypeName(const aUri: string; aType: TXmliteComponentType; const aXmlName: string; aFullName: boolean = False): string;
    function GetMetaBasite(const aUri: string; aType: TXmliteComponentType; const aXmlName: string): TMetaBasite;

    procedure IterateLocked(aNamespaceIterate: TNamespaceIterate);
  end;

  TMetaBankXmlite = class sealed(TMetaBankExtension)
  private
    class var Instance: TMetaBankXmlite;

    class constructor Create;
  public
    class function RegisterNamespace(const aUri: string; const aSimpleTypes: TArray<PTypeInfo>; const aComplexTypes: TArray<TBasiteClass>;
      const aAttributes: TArray<PTypeInfo>; const aAttributeGroups, aElements, aGroups: TArray<TBasiteClass>; const aPrefix: string;
      aNaming: TNaming = cDefaultNaming; const aSuffixSimpleType: string = cDefaultSuffixSimpleType;
      const aSuffixComplexType: string = cDefaultSuffixComplexType; const aSuffixAttribute: string = cDefaultSuffixAttribute;
      const aSuffixAttributeGroup: string = cDefaultSuffixAttributeGroup; const aSuffixElement: string = cDefaultSuffixElement;
      const aSuffixElementGroup: string = cDefaultSuffixElementGroup): TNamespace;

  private
    fNamespaces: TNamespaceList;
  public
    constructor Create; override;
    destructor Destroy; override;

    function ItemCreate(aMeta: TMeta): TMetaExtension; override;
    function PropertyCreate(aProperty: TProperty): TPropertyExtension; override;

    property Namespaces: TNamespaceList read fNamespaces;
    function TryGetNamespace(const aUri: string; var aNamespace: TNamespace): boolean;
  end;

  TMetaBankHelper = class helper for TMetaBank
  public
    class function Xmlite: TMetaBankXmlite;
  end;

implementation

uses System.IniFiles, System.Variants, System.Hash;

// the read order of elements (TXmlite.XmlPosition): one counter per thread, so parsing in several threads needs no lock
threadvar
  gXmlReadPosition: cardinal;

{ TBasiteHelper }

constructor TBasiteHelper.CreateFromXml(const aXml: string);
begin
  inherited Create;
  FromXml(aXml);
end;

function TBasiteHelper.FromXml(const aXml: string): boolean;
begin
  var xml: string := aXml;
  Result := FromXmlInPlace(xml); // shared now: copied there
end;

function TBasiteHelper.FromXmlInPlace(var aXml: string): boolean;
begin
  // the parser writes into the text: a shared string gets its own copy first, so only aXml changes
  UniqueString(aXml);
  var xmlCursor: PChar := PChar(aXml);
  if not TReaderXmlite.MoveToChar(xmlCursor, '<') then
    Exit(False);

  // declaration
  while (xmlCursor^ = '<') and (xmlCursor[1] = '?') do
  begin
    Inc(xmlCursor, 2);
    while xmlCursor[1] <> '>' do
      if not TReaderXmlite.MoveToChar(xmlCursor, '?') then
        Exit(False);

    if not TReaderXmlite.MoveToChar(xmlCursor, '<') then
      Exit(False);
  end;

  Clear;

  Result := FromXml(xmlCursor);
end;

function TBasiteHelper.FromXml(var aXmlCursor: PChar; aXmlns: TXmlns): boolean;
const
  cWhitespaces = [#32, #9, #$A, #$D];
begin
  Result := False;

  if Meta.Xmlite.IsTXmlite then
    TXmlite(Self).DoBeforeParsing;

  if not TReaderXmlite.MoveToChar(aXmlCursor, '<') then
    Exit;

  // pass the DOCTYPE, comments, processing instructions
  while (aXmlCursor[1] = '!') or (aXmlCursor[1] = '?') do
    if not TReaderXmlite.PassMarkup(aXmlCursor) or not TReaderXmlite.MoveToChar(aXmlCursor, '<') then
      Exit;

  var xmlns: TXmlns;

  if aXmlns = nil then
    xmlns := TXmlns.Create
  else
    xmlns := TXmlns.Create(aXmlns);

  if Meta.Xmlite.IsTXmlite then
  begin
    TXmlite(Self).fXmlns.Free;
    TXmlite(Self).fXmlns := xmlns;
    Inc(gXmlReadPosition);
    TXmlite(Self).fXmlPosition := gXmlReadPosition;
  end;

  try
    if not TReaderXmlite.ReadXmlns(aXmlCursor, xmlns) then
      Exit;

    var isEndTag: boolean;
    var objectName, name, prefix: string;
    if not TReaderXmlite.ReadTagName(aXmlCursor, isEndTag, prefix, name, objectName) then
      Exit;

    if CharInSet(aXmlCursor^, cWhitespaces) then
      // attributes
      while TReaderXmlite.MoveToVisualChar(aXmlCursor) and not CharInSet(aXmlCursor^, ['/', '>']) do
      begin
        var attributePrefix, attributeName, attributeFullName, attributeValue: string;
        if not TReaderXmlite.ReadAttributeName(aXmlCursor, attributePrefix, attributeName, attributeFullName) then
          Exit;

        attributeValue := TReaderXmlite.ReadQuotedValueInPlace(aXmlCursor);

        var uri: string;
        if attributePrefix.IsEmpty and Assigned(Meta.Xmlite.Namespace) then
          // for unprefixed attributes parent's URI is used, as attributes do not inherit the default xmlns
          uri := Meta.Xmlite.Namespace.Uri
        else
          uri := xmlns[attributePrefix];

        var propertyData: TPropertyData := Meta.Xmlite.Attributes[TUriedName.Create(uri, attributeName)];
        if propertyData = nil then
          propertyData := Meta.Xmlite.Attributes[TUriedName.Create('', attributeName)];
        if propertyData <> nil then
          propertyData.Value[Self] := attributeValue
        else if Meta.Xmlite.IsTXmlite and (attributePrefix = 'xmlns') then
          TXmlite(Self).XmlAttributeNamespaces.AddOrSetValue(attributeName, attributeValue)
        else if Meta.Xmlite.IsTXmlite then
          if (attributePrefix <> 'xmlns') and (not attributePrefix.IsEmpty or (attributeName <> 'xmlns')) then // pass xmlns stuff
          begin
            TXmlite(Self).XmlAttributes.AddOrSetValue(attributeFullName, attributeValue);
            // its prefix, and for xsi:type the value's (dcterms:W3CDTF) - declared again on write
            if not attributePrefix.IsEmpty and not uri.IsEmpty then
              TXmlite(Self).XmlAttributeNamespaces.AddOrSetValue(attributePrefix, uri);
            if (uri = cXsiUri) and (attributeName = 'type') and (attributeValue.IndexOf(':') > 0) then
            begin
              var valuePrefix: string := attributeValue.Substring(0, attributeValue.IndexOf(':'));
              if not xmlns[valuePrefix].IsEmpty then
                TXmlite(Self).XmlAttributeNamespaces.AddOrSetValue(valuePrefix, xmlns[valuePrefix]);
            end;
          end;
      end
    else if not TReaderXmlite.MoveToVisualChar(aXmlCursor) then
      Exit;

    if (aXmlCursor^ = '/') and (aXmlCursor[1] = '>') then
    begin // empty tag
      Inc(aXmlCursor, 2);
      Result := True;
    end
    else if aXmlCursor^ = '>' then
    begin // start tag
      Inc(aXmlCursor);

      var textProperty: TPropertyData := Meta.Xmlite.TextProperty;
      if Assigned(textProperty) then
      begin // simpleContent: the text is the value - whitespace included
        if aXmlCursor^ <> '<' then
          textProperty.Value[Self] := TReaderXmlite.ReadUnescapeInPlace(aXmlCursor, '<');
        if aXmlCursor^ = #0 then
          Exit;
      end
      else if not Meta.Xmlite.Mixed then // mixed content: every text run read in ReadTagContents, whitespace included
      begin
        if not TReaderXmlite.MoveToVisualChar(aXmlCursor) then
          Exit;

        if Meta.Xmlite.IsTXmlite and (aXmlCursor^ <> '<') then
          TXmlite(Self).fXmlText := TReaderXmlite.ReadUnescapeInPlace(aXmlCursor, '<');
      end;

      // malformed content fails the read; the object keeps what was read up to there
      Result := ReadTagContents(aXmlCursor, objectName, xmlns);
    end;

  finally
    if not Meta.Xmlite.IsTXmlite then
      xmlns.Free;
  end;

  if Meta.Xmlite.IsTXmlite then
    TXmlite(Self).DoAfterParsing;
end;

// URI of a tag name: the tag's own xmlns declarations first, then the ones of its context
function TagUri(aTagStart: PChar; const aPrefix: string; aXmlns: TXmlns): string;

  function TagDeclaresXmlns(aCursor: PChar): boolean; inline;
  begin // quick check before reading declarations; a false positive costs only the full read below
    var quote: Char := #0;
    while aCursor^ <> #0 do
    begin
      if quote <> #0 then
      begin
        if aCursor^ = quote then
          quote := #0;
      end
      else
        case aCursor^ of
          '"', '''':
            quote := aCursor^;
          '>':
            Exit(False);
          'x':
            if StrLComp(aCursor, 'xmlns', 5) = 0 then
              Exit(True);
        end;
      Inc(aCursor);
    end;
    Result := False;
  end;

begin
  if TagDeclaresXmlns(aTagStart) then
  begin
    var tagXmlns: TXmlns := TXmlns.Create;
    try
      TReaderXmlite.ReadXmlns(aTagStart, tagXmlns);
      if aPrefix.IsEmpty then
      begin
        if not tagXmlns.DefaultUri.IsEmpty then
          Exit(tagXmlns.DefaultUri);
      end
      else if tagXmlns.TryGetValue(aPrefix, Result) then
        Exit;
    finally
      tagXmlns.Free;
    end;
  end;

  Result := aXmlns[aPrefix];
end;

function TBasiteHelper.ReadTagContents(var aCursor: PChar; const aName: string; aXmlns: TXmlns): boolean;
begin
  Result := False;

  // the element read last: an unknown one after it is written back after it
  var lastProperty: TProperty := nil;
  var lastCount: integer := 0;

  // the children's order kept in XmlContent; mixed content's text too
  var ordered: boolean := Meta.Xmlite.IsTXmlite and Meta.Xmlite.Ordered;
  var mixed: boolean := ordered and Meta.Xmlite.Mixed;

  while not Result do
  begin
    if mixed then
    begin // the text up to the next tag, whitespace included - CDATA as text, comments and processing instructions passed
      var text: string := TReaderXmlite.ReadUnescapeInPlace(aCursor, '<');
      if aCursor^ = #0 then
        Exit;
      if not text.IsEmpty then
        TXmlite(Self).AddNode(xnkText, text, nil, nil, 0);
    end;

    if not TReaderXmlite.MoveToChar(aCursor, '<') then
      Exit;

    // pass comments, CDATA and processing instructions between elements (mixed content's text is not kept)
    while (aCursor[1] = '!') or (aCursor[1] = '?') do
      if not TReaderXmlite.PassMarkup(aCursor) or not TReaderXmlite.MoveToChar(aCursor, '<') then
        Exit;

    var cursorStart: PChar := aCursor;
    var isEndTag: boolean;
    var tagFullName, tagName, tagPrefix: string;
    if not TReaderXmlite.ReadTagName(aCursor, isEndTag, tagPrefix, tagName, tagFullName) then
      Exit;

    if isEndTag then
      if tagFullName = aName then
        Exit(True)
      else // closing tag with wrong name
        Exit;

    // xmlns declared on the tag itself applies to the tag's own name too (e.g. <AddResponse xmlns="http://tempuri.org/">)
    var elementUri: string := TagUri(cursorStart, tagPrefix, aXmlns);

    // get a property for property defined name, following prefix/uri
    var propertyElement: TProperty := Meta.Xmlite.Elements[TUriedName.Create(elementUri, tagName)];

    // an unqualified local element (SOAP 1.1 faultcode) belongs to its parent's type, as an unprefixed attribute does
    if (propertyElement = nil) and elementUri.IsEmpty and Assigned(Meta.Xmlite.Namespace) then
      propertyElement := Meta.Xmlite.Elements[TUriedName.Create(Meta.Xmlite.Namespace.Uri, tagName)];


    if (propertyElement = nil) and Meta.Xmlite.ProcessAnyElement then
    begin // for xs:any - try to find Namespace-registered element and parse it
      var metaElement: TMetaBasite := TMetaBank.Xmlite.Namespaces.GetMetaBasite(elementUri, xctElement, tagName);
      if Assigned(metaElement) then
      begin
        var element: TBasite := metaElement.ClassItself.Create;
        aCursor := cursorStart;
        if element.FromXml(aCursor, aXmlns) then
        begin
          TXmlite(Self).XmlAny.Add(element);
          if ordered then
            TXmlite(Self).AddNode(xnkElement, '', element, nil, 0);
          Continue;
        end
        else
          element.Free;
      end;
    end;

    if propertyElement = nil then // as a fallback - try to find such property without tag
      propertyElement := Meta.Xmlite.Elements[TUriedName.Create('', tagName)];

    // compat 1.3.0, drop in 2.0: matched by name - documents written before 1.3.0 put some elements in the parent's namespace
    if propertyElement = nil then
      for var candidate: TProperty in Meta.Xmlite.Elements.Values do
        if candidate.Xmlite.Name = tagName then
        begin
          propertyElement := candidate;
          break;
        end;

    if (propertyElement = nil) and Meta.Xmlite.IsTXmlite then
    begin // not described: kept as its text, to be written back where it was - a well-formed element only
      aCursor := cursorStart;
      var namespaces: TDictionary<string, string> := TDictionary<string, string>.Create;
      try
        var unknown: TXmliteUnknown;
        if not TReaderXmlite.ReadFragment(aCursor, aXmlns, unknown.Xml, namespaces) then
          Exit;
        unknown.After := lastProperty;
        unknown.AfterCount := lastCount;
        unknown.Namespaces := namespaces.ToArray;
        TXmlite(Self).XmlUnknown.Add(unknown);
        if ordered then
          TXmlite(Self).AddNode(xnkUnknown, tagFullName, nil, nil, TXmlite(Self).XmlUnknown.Count - 1);
      finally
        namespaces.Free;
      end;
    end
    else if propertyElement = nil then
    begin // no such name in elements list of the object - skip the whole node till it's end
      Inc(aCursor);
      if not TReaderXmlite.PassNode(aCursor, tagFullName) then
        Exit;
    end
    else
    begin
      lastProperty := propertyElement;
      lastCount := 1;
      case propertyElement.PropertyType of
        ptData:
          begin
            TPropertyData(propertyElement).Value[Self] := TReaderXmlite.ReadTextNodeContents(aCursor);
            if ordered then
              TXmlite(Self).AddNode(xnkElement, '', nil, propertyElement, 0);
            if not TReaderXmlite.PassNode(aCursor, tagFullName) then
              Exit;
          end;
        ptBasite:
          begin
            var propertyBasite: TPropertyBasite := TPropertyBasite(propertyElement);
            var fieldObject: TBasite := propertyBasite.ObjectPointer(Self)^;
            if fieldObject = nil then
            begin // not pre-created (a self-nested type beyond TBasite.AutoInitMaxDepth) - the data has it, so create it
              fieldObject := propertyBasite.Meta.ClassItself.Create;
              propertyBasite.ObjectPointer(Self)^ := fieldObject;
            end;
            aCursor := cursorStart;
            var read: boolean := fieldObject.FromXml(aCursor, aXmlns);
            SetPresent(propertyElement); // also when all its values are defaults (<fill/>)
            if ordered then
              TXmlite(Self).AddNode(xnkElement, '', fieldObject, propertyElement, 0);
            if not read then
              Exit;
          end;
        ptBasiteList:
          begin
            var propertyObjectList: TPropertyBasiteList := TPropertyBasiteList(propertyElement);
            if propertyObjectList.ObjectPointer(Self)^ = nil then
              propertyObjectList.ObjectPointer(Self)^ := propertyObjectList.Meta.CreateList;
            var objectListItem: TBasite := propertyObjectList.Meta.ItemMeta.ClassItself.Create;
            aCursor := cursorStart;
            var read: boolean := objectListItem.FromXml(aCursor, aXmlns);
            propertyObjectList.ObjectPointer(Self).Add(objectListItem); // owned by the list, also when not read whole
            SetPresent(propertyElement);
            lastCount := propertyObjectList.ObjectPointer(Self).Count;
            if ordered then
              TXmlite(Self).AddNode(xnkElement, '', objectListItem, propertyElement, lastCount - 1);
            if not read then
              Exit;
          end;
        ptDataList:
          begin
            TPropertyDataList(propertyElement).AddText(Self, TReaderXmlite.ReadTextNodeContents(aCursor));
            if not TReaderXmlite.PassNode(aCursor, tagFullName) then
              Exit;
            lastCount := TPropertyDataList(propertyElement).Count(Self);
            if ordered then
              TXmlite(Self).AddNode(xnkElement, '', nil, propertyElement, lastCount - 1);
          end;
      end;
    end;
  end;
end;

// the tag of an element that is written (its parent decided it is present): with content, or empty
function TBasiteHelper.TagType: TTagType;
begin
  Result := xttEmpty;

  // simpleContent: text is written whenever the element is (<amount currency="EUR">0</amount>, never <amount currency="EUR"/>)
  var textProperty: TPropertyData := Meta.Xmlite.TextProperty;
  if Assigned(textProperty) and (textProperty.Required or IsPresent(textProperty)) then
    Exit(xttOpenClose);

  if Meta.Xmlite.ProcessAnyElement and (TXmlite(Self).XmlAny.Count > 0) then
    Exit(xttOpenClose);

  if Meta.Xmlite.IsTXmlite and (TXmlite(Self).fXmlUnknown <> nil) and (TXmlite(Self).fXmlUnknown.Count > 0) then
    Exit(xttOpenClose);

  // text of mixed content (OOXML cp:keywords: "q3, plan"): read into XmlText, so written back too
  if Meta.Xmlite.IsTXmlite and not TXmlite(Self).XmlText.IsEmpty then
    Exit(xttOpenClose);

  if Meta.Xmlite.IsTXmlite and (TXmlite(Self).fXmlContent <> nil) and (TXmlite(Self).fXmlContent.Count > 0) then
    Exit(xttOpenClose);

  // the same test as ToXml makes for each child element
  for var propertyInfo: TProperty in Meta.Xmlite.Elements.Values do
    if ((propertyInfo.PropertyType <> ptBasite) or (TPropertyBasite(propertyInfo).ObjectPointer(Self)^ <> nil)) and
      (propertyInfo.Required or IsPresent(propertyInfo)) then
      Exit(xttOpenClose);

  if Assigned(textProperty) then
    Exit(xttOpenClose);
end;

procedure TBasiteHelper.ToXml(aWriter: TWriterXmlite; const aName: string; aScope: TNamespace; aNamespaces, aXmlHeader: boolean);
var
  unknownWritten: TArray<boolean>;

  // the namespace in scope is the default one: no prefix; any other namespace: prefixed (declared by GetXmlns)
  function elementName(aProperty: TProperty; aScope: TNamespace): string;
  begin
    if (aProperty.Xmlite.Namespace = nil) or (aProperty.Xmlite.Namespace = aScope) then
      Result := aProperty.Xmlite.Name
    else
      Result := aProperty.Xmlite.NamePrefixed;
  end;

  // the kept elements read after aAfter's aCount-th item (aAfter nil: before the first element); -1: all of aAfter's left
  procedure WriteUnknown(aAfter: TProperty; aCount: integer);
  begin
    var unknowns: TList<TXmliteUnknown> := TXmlite(Self).fXmlUnknown;
    if not Meta.Xmlite.IsTXmlite or (unknowns = nil) then
      Exit;
    if Length(unknownWritten) <> unknowns.Count then
      SetLength(unknownWritten, unknowns.Count);
    for var i := 0 to unknowns.Count - 1 do
      if not unknownWritten[i] and (unknowns[i].After = aAfter) and ((aCount < 0) or (unknowns[i].AfterCount = aCount)) then
      begin
        aWriter.AddUnknown(unknowns[i]);
        unknownWritten[i] := True;
      end;
  end;

  // an ordered element's children in XmlContent's order, then the ones not in it in schema order; a node's object is written
  // only while its property (or XmlAny) holds it - pointers compared, never followed - and once
  procedure WriteOrdered(aScope: TNamespace);
  var
    children: TDictionary<TBasite, TProperty>; // the children now -> their property (nil: XmlAny)
    valuesWritten: TDictionary<TProperty, TArray<boolean>>;

    procedure WriteChild(aChild: TBasite);
    begin
      var childProperty: TProperty;
      if not children.TryGetValue(aChild, childProperty) then
        Exit;
      children.Remove(aChild);
      if childProperty <> nil then
        aChild.ToXml(aWriter, elementName(childProperty, aScope), aScope, False)
      else if aChild.Meta.Xmlite.Namespace = aScope then // as XmlAny below
        aChild.ToXml(aWriter, aChild.Meta.Xmlite.Name, aScope, False)
      else
        aChild.ToXml(aWriter, aChild.Meta.Xmlite.Name, nil, True);
    end;

    procedure WriteValue(aProperty: TProperty; aIndex: integer);
    begin
      var count: integer := 1;
      if aProperty.PropertyType = ptDataList then
        count := TPropertyDataList(aProperty).Count(Self)
      else if not aProperty.Required and not IsPresent(aProperty) then
        Exit;
      var written: TArray<boolean>;
      if not valuesWritten.TryGetValue(aProperty, written) then
        SetLength(written, count);
      if (aIndex < 0) or (aIndex >= count) or (aIndex >= Length(written)) or written[aIndex] then
        Exit;
      written[aIndex] := True;
      valuesWritten.AddOrSetValue(aProperty, written);
      if aProperty.PropertyType = ptDataList then
        aWriter.AddTextNode(elementName(aProperty, aScope), TPropertyDataList(aProperty).ItemText(Self, aIndex), aProperty)
      else
        aWriter.AddTextNode(elementName(aProperty, aScope), TPropertyData(aProperty).Value[Self], aProperty);
    end;

  begin
    var unknowns: TList<TXmliteUnknown> := TXmlite(Self).fXmlUnknown;
    if (unknowns <> nil) and (Length(unknownWritten) <> unknowns.Count) then
      SetLength(unknownWritten, unknowns.Count);

    children := TDictionary<TBasite, TProperty>.Create;
    valuesWritten := TDictionary<TProperty, TArray<boolean>>.Create;
    try
      for var propertyElement in Meta.Xmlite.Elements.Values do
        case propertyElement.PropertyType of
          ptBasite:
            begin
              var fieldObject: TBasite := TPropertyBasite(propertyElement).ObjectPointer(Self)^;
              if (fieldObject <> nil) and (propertyElement.Required or IsPresent(propertyElement)) then
                children.AddOrSetValue(fieldObject, propertyElement);
            end;
          ptBasiteList:
            begin
              var list: TBasiteList := TPropertyBasiteList(propertyElement).ObjectPointer(Self)^;
              if list <> nil then
                for var item: TBasite in list do
                  children.AddOrSetValue(item, propertyElement);
            end;
        end;
      if Meta.Xmlite.ProcessAnyElement then
        for var anyElement: TBasite in TXmlite(Self).XmlAny do
          children.AddOrSetValue(anyElement, nil);

      for var node: TXmliteNode in TXmlite(Self).fXmlContent do
        case node.Kind of
          xnkText:
            if Meta.Xmlite.Mixed then
              aWriter.AddTextEscape(node.Text);
          xnkUnknown:
            if (unknowns <> nil) and (node.Index >= 0) and (node.Index < unknowns.Count) and not unknownWritten[node.Index] then
            begin
              aWriter.AddUnknown(unknowns[node.Index]);
              unknownWritten[node.Index] := True;
            end;
          xnkElement:
            if node.Element <> nil then
              WriteChild(node.Element)
            else if node.ElementProperty <> nil then
              WriteValue(node.ElementProperty, node.Index);
        end;

      // added straight to a list after reading: schema order
      for var propertyElement in Meta.Xmlite.Elements.Values do
        case propertyElement.PropertyType of
          ptData:
            WriteValue(propertyElement, 0);
          ptDataList:
            for var i := 0 to TPropertyDataList(propertyElement).Count(Self) - 1 do
              WriteValue(propertyElement, i);
          ptBasite:
            if TPropertyBasite(propertyElement).ObjectPointer(Self)^ <> nil then
              WriteChild(TPropertyBasite(propertyElement).ObjectPointer(Self)^);
          ptBasiteList:
            begin
              var list: TBasiteList := TPropertyBasiteList(propertyElement).ObjectPointer(Self)^;
              if list <> nil then
                for var item: TBasite in list do
                  WriteChild(item);
            end;
        end;
      if Meta.Xmlite.ProcessAnyElement then
        for var anyElement: TBasite in TXmlite(Self).XmlAny do
          WriteChild(anyElement);
      if unknowns <> nil then
        for var i := 0 to unknowns.Count - 1 do
          if not unknownWritten[i] then
            aWriter.AddUnknown(unknowns[i]);
    finally
      valuesWritten.Free;
      children.Free;
    end;
  end;

begin
  if Self = nil then
    Exit;

  if Meta.Xmlite.IsTXmlite then
    TXmlite(Self).DoBeforeSerialization;

  if aXmlHeader then
    aWriter.AddLine(cXmlDeclaration);

  var objectName: string := aName;
  if objectName.IsEmpty then
    objectName := Meta.Xmlite.Name;

  // an element declaring its namespaces makes its own one the default for its content
  var scope: TNamespace := aScope;
  if aNamespaces then
    scope := Meta.Xmlite.Namespace;

  case TagType of
    xttEmpty:
      aWriter.AddTagEmpty(objectName, Self, aNamespaces);
    xttOpenClose:
      if Assigned(Meta.Xmlite.TextProperty) then
        aWriter.AddTagText(objectName, Self, aNamespaces, Meta.Xmlite.TextProperty.Value[Self])
      else
      begin
        // mixed content: no indentation inside - it would become a part of the text
        var mixed: boolean := Meta.Xmlite.IsTXmlite and Meta.Xmlite.Mixed;
        var pretty: boolean := aWriter.Pretty;
        if mixed then
        begin
          aWriter.AddIndent;
          aWriter.Pretty := False;
        end;

        aWriter.AddTagOpen(objectName, Self, aNamespaces);

        if Meta.Xmlite.IsTXmlite and not mixed and not TXmlite(Self).fXmlText.IsEmpty then
          aWriter.AddXmlEscape(TXmlite(Self).fXmlText);

        aWriter.IncLevel;

        if Meta.Xmlite.IsTXmlite and Meta.Xmlite.Ordered and (TXmlite(Self).fXmlContent <> nil) and
          (TXmlite(Self).fXmlContent.Count > 0) then
          WriteOrdered(scope)
        else
        begin
          WriteUnknown(nil, 0);
          for var propertyElement in Meta.Xmlite.Elements.Values do
          begin
            case propertyElement.PropertyType of
              ptData:
                begin
                  var propertyData: TPropertyData := TPropertyData(propertyElement);
                  if propertyData.Required or IsPresent(propertyData) then
                    aWriter.AddTextNode(elementName(propertyElement, scope), propertyData.Value[Self], propertyData);
                end;
              ptDataList:
                begin
                  var propertyDataList: TPropertyDataList := TPropertyDataList(propertyElement);
                  for var i := 0 to propertyDataList.Count(Self) - 1 do
                  begin
                    aWriter.AddTextNode(elementName(propertyElement, scope), propertyDataList.ItemText(Self, i), propertyDataList);
                    WriteUnknown(propertyElement, i + 1);
                  end;
                end;
              ptBasite:
                begin
                  // written when present or required - its own required values do not make it present (<drawing r:id=""/>)
                  var propertyBasite: TPropertyBasite := TPropertyBasite(propertyElement);
                  var fieldObject: TBasite := propertyBasite.ObjectPointer(Self)^;
                  if (fieldObject <> nil) and (propertyBasite.Required or IsPresent(propertyBasite)) then
                    fieldObject.ToXml(aWriter, elementName(propertyElement, scope), scope, False);
                end;
              ptBasiteList:
                begin
                  // list items are always written - an item with only defaults too (<fill/>: Excel refers to it by index)
                  var propertyBasiteList: TPropertyBasiteList := TPropertyBasiteList(propertyElement);
                  var list: TBasiteList := propertyBasiteList.ObjectPointer(Self)^;
                  if list <> nil then
                    for var i := 0 to list.Count - 1 do
                    begin
                      list[i].ToXml(aWriter, elementName(propertyElement, scope), scope, False);
                      WriteUnknown(propertyElement, i + 1);
                    end;
                end;
            end;
            WriteUnknown(propertyElement, -1); // after it, or after the items it has now
          end;

          if Meta.Xmlite.IsTXmlite and Meta.Xmlite.ProcessAnyElement then
            for var anyElement: TBasite in TXmlite(Self).XmlAny do
              if anyElement.Meta.Xmlite.Namespace = scope then
                // the namespace in scope (wsse:UsernameToken in wsse:Security): unprefixed, declared by an ancestor
                anyElement.ToXml(aWriter, anyElement.Meta.Xmlite.Name, scope, False)
              else
                // another namespace: declares it as its default one - its unprefixed members then belong to it
                // (e.g. <Add xmlns="http://tempuri.org/"><intA>... inside soap:Body)
                anyElement.ToXml(aWriter, anyElement.Meta.Xmlite.Name, nil, True);

        end;

        aWriter.DecLevel;

        aWriter.AddIndent;
        aWriter.AddTagClose(objectName);

        if mixed then
        begin
          aWriter.Pretty := pretty;
          aWriter.FinishLine;
        end;
      end;
  end;

  if aNamespaces then
    aWriter.PopDeclared;

  if Meta.Xmlite.IsTXmlite then
    TXmlite(Self).DoAfterSerialization;
end;

procedure TBasiteHelper.ToXml(aStream: TStream; const aName: string; aXmlHeader: boolean);
begin
  var writer: TWriterXmlite := TWriterXmlite.Create(aStream);
  try
    writer.Pretty := TBasite.Pretty;
    ToXml(writer, aName, nil, True, aXmlHeader);
  finally
    writer.Free;
  end;
end;

function TBasiteHelper.ToXml(const aName: string; aXmlHeader: boolean): string;
begin
  var writer: TWriterXmlite := TWriterXmlite.Create;
  try
    writer.Pretty := TBasite.Pretty;
    ToXml(writer, aName, nil, True, aXmlHeader);
    Result := writer.Text;
  finally
    writer.Free;
  end;
end;

function TBasiteHelper.GetXmlns(aDeclared: TDictionary<string, string>): string;

  // aPrefixed: namespaces used with a prefix in this subtree; aScope: the default one; aKept: the declarations kept
  procedure FillXmlnsList(aXmlnsList, aPrefixed: THashedObjectList<TNamespace>; aKept: TDictionary<string, string>; aObject: TBasite;
    aScope: TNamespace);

    procedure AddPropertyDataXmlns(aXmlnsList: THashedObjectList<TNamespace>; aPropertyData: TPropertyData; aObject: TBasite); inline;
    begin
      if not aPropertyData.Required and not aObject.IsPresent(aPropertyData) then
        Exit;

      // the property's own namespace only: its value type's one (xs of xs:string) names nothing in the document
      aXmlnsList.Add(aPropertyData.Xmlite.Namespace);
    end;

  begin
    aXmlnsList.Add(aObject.Meta.Xmlite.Namespace);
    if aObject.Meta.Xmlite.IsTXmlite then
      for var attributeNamespace: TPair<string, string> in TXmlite(aObject).XmlAttributeNamespaces do
        aKept.AddOrSetValue(attributeNamespace.Key, attributeNamespace.Value);
    for var attribute: TPropertyData in aObject.Meta.Xmlite.Attributes.Values do
    begin
      AddPropertyDataXmlns(aXmlnsList, attribute, aObject);
      if attribute.Xmlite.Qualified and (attribute.Required or aObject.IsPresent(attribute)) then
        aPrefixed.Add(attribute.Xmlite.Namespace);
    end;

    for var element: TProperty in aObject.Meta.Xmlite.Elements.Values do
    begin
      if element.PropertyType in [ptBasite, ptBasiteList, ptDataList] then
        aXmlnsList.Add(element.Xmlite.Namespace); // the element's own namespace (its type may be another one's)
      case element.PropertyType of
        ptData:
          AddPropertyDataXmlns(aXmlnsList, TPropertyData(element), aObject);
        ptBasite:
          begin
            var propertyObject: TBasite := TPropertyBasite(element).ObjectPointer(aObject)^;
            if (propertyObject <> nil) and (element.Required or aObject.IsPresent(element)) then
              FillXmlnsList(aXmlnsList, aPrefixed, aKept, propertyObject, aScope);
          end;
        ptBasiteList:
          begin
            var propertyList: TBasiteList := TPropertyBasiteList(element).ObjectPointer(aObject)^;;
            if (propertyList <> nil) and (propertyList.Count > 0) then
              for var listObject: TBasite in propertyList do
                FillXmlnsList(aXmlnsList, aPrefixed, aKept, listObject, aScope);
          end;
      end;
    end;

    // xs:any content of the scope's namespace is declared here; of another one, by itself
    if aObject.Meta.Xmlite.IsTXmlite and aObject.Meta.Xmlite.ProcessAnyElement then
      for var anyElement: TBasite in TXmlite(aObject).XmlAny do
        if anyElement.Meta.Xmlite.Namespace = aScope then
          FillXmlnsList(aXmlnsList, aPrefixed, aKept, anyElement, aScope);
  end;

begin
  Result := '';

  var xmlnsList: THashedObjectList<TNamespace> := THashedObjectList<TNamespace>.Create(False);
  var prefixed: THashedObjectList<TNamespace> := THashedObjectList<TNamespace>.Create(False);
  var kept: TDictionary<string, string> := TDictionary<string, string>.Create;
  var declared: TDictionary<string, string> := TDictionary<string, string>.Create; // prefix -> URI
  try
    FillXmlnsList(xmlnsList, prefixed, kept, Self, Meta.Xmlite.Namespace);

    for var namespace: TNamespace in xmlnsList.Values do
      if (namespace <> nil) and (namespace.Uri <> cXmlPrefixUri) then // the xml prefix is bound by definition, never declared
        if namespace = Meta.Xmlite.Namespace then
        begin
          Result := Result + Format(' xmlns="%s"', [namespace.Uri]);
          declared.AddOrSetValue('', namespace.Uri);
          if prefixed.Contains(namespace) and not namespace.Prefix.IsEmpty then // a default namespace is not for attributes
          begin
            Result := Result + Format(' xmlns:%s="%s"', [namespace.Prefix, namespace.Uri]);
            declared.AddOrSetValue(namespace.Prefix, namespace.Uri);
          end;
        end
        else
        begin
          Result := Result + Format(' xmlns:%s="%s"', [namespace.Prefix, namespace.Uri]);
          declared.AddOrSetValue(namespace.Prefix, namespace.Uri);
        end;

    // the kept declarations, unless the prefix is declared already (the element's own names win)
    for var keptPrefix: TPair<string, string> in kept do
      if not declared.ContainsKey(keptPrefix.Key) and (keptPrefix.Key <> cXmlPrefix) then
      begin
        Result := Result + Format(' xmlns:%s="%s"', [keptPrefix.Key, keptPrefix.Value]);
        declared.Add(keptPrefix.Key, keptPrefix.Value);
      end;

    if aDeclared <> nil then
      for var declaration: TPair<string, string> in declared do
        aDeclared.AddOrSetValue(declaration.Key, declaration.Value);
  finally
    declared.Free;
    kept.Free;
    prefixed.Free;
    xmlnsList.Free;
  end;
end;

{ TWriterXmlite }

destructor TWriterXmlite.Destroy;
begin
  fDeclared.Free;
  inherited;
end;

procedure TWriterXmlite.PopDeclared;
begin
  if (fDeclared <> nil) and (fDeclared.Count > 0) then
    fDeclared.Delete(fDeclared.Count - 1);
end;

procedure TWriterXmlite.AddUnknown(const aUnknown: TXmliteUnknown);

  function DeclaredHere(const aPrefix, aUri: string): boolean;
  begin
    if fDeclared <> nil then
      for var i := fDeclared.Count - 1 downto 0 do
      begin
        var uri: string;
        if fDeclared[i].TryGetValue(aPrefix, uri) then
          Exit(uri = aUri);
      end;
    Result := aPrefix.IsEmpty and aUri.IsEmpty; // no default namespace declared: none in scope
  end;

begin
  var declarations: string := '';
  for var namespace: TPair<string, string> in aUnknown.Namespaces do
    if not DeclaredHere(namespace.Key, namespace.Value) then
      if namespace.Key.IsEmpty then
        declarations := declarations + Format(' xmlns="%s"', [namespace.Value])
      else
        declarations := declarations + Format(' xmlns:%s="%s"', [namespace.Key, namespace.Value]);

  AddIndent;
  if declarations.IsEmpty then
    Write(aUnknown.Xml)
  else
  begin // right after the element's name
    var nameEnd: integer := 1;
    while (nameEnd < aUnknown.Xml.Length) and not CharInSet(aUnknown.Xml.Chars[nameEnd], [#32, #9, #$A, #$D, '/', '>']) do
      Inc(nameEnd);
    Write(aUnknown.Xml.Substring(0, nameEnd) + declarations + aUnknown.Xml.Substring(nameEnd));
  end;
  FinishLine;
end;

procedure TWriterXmlite.AddIndent;
begin
  if fPretty then
    inherited;
end;

procedure TWriterXmlite.FinishLine(const aEndingText: string);
begin
  if fPretty then
    inherited;
end;

procedure TWriterXmlite.AddTagClose(const aName: string);
begin
  Write('</');
  Write(aName);
  Write('>');
  FinishLine;
end;

procedure TWriterXmlite.AddTagEmpty(const aName: string; aObject: TBasite; aNamespaces: boolean);
begin
  AddIndent;
  Write('<');
  Write(aName);
  WriteAttributes(aObject, aNamespaces);
  Write('/>');
  FinishLine;
end;

procedure TWriterXmlite.AddTagOpen(const aName: string; aObject: TBasite; aNamespaces: boolean);
begin
  AddIndent;
  Write('<');
  Write(aName);
  WriteAttributes(aObject, aNamespaces);
  Write('>');
  FinishLine;
end;

procedure TWriterXmlite.AddTagText(const aName: string; aObject: TBasite; aNamespaces: boolean; const aText: string);
begin
  AddIndent;
  Write('<');
  Write(aName);
  WriteAttributes(aObject, aNamespaces);
  Write('>');
  AddXmlEscape(aText);
  AddTagClose(aName);
end;

procedure TWriterXmlite.AddTextNode(const aName, aValue: string; aFieldInfo: TProperty; aObject: TBasite);
begin
  AddIndent;
  Write('<');
  Write(aName);
  if aObject <> nil then
    WriteAttributes(aObject);
  var typeKind: TTypeKind := aFieldInfo.RttiProperty.PropertyType.TypeKind;
  if aFieldInfo.PropertyType = ptDataList then
    typeKind := TPropertyDataList(aFieldInfo).Meta.RttiType.TypeKind;
  if (typeKind in [tkString, tkLString, tkWString, tkUString]) and not aValue.IsEmpty and
    ((aValue.Chars[0] <= ' ') or (aValue.Chars[aValue.Length - 1] <= ' ')) then
    WriteAttribute('xml:space', 'preserve');
  Write('>');
  AddXmlEscape(aValue);
  AddTagClose(aName);
end;

procedure TWriterXmlite.AddTextEscape(const aString: string);
begin
  // only what text needs escaped; a carriage return as a reference - a reader would turn it into a line feed
  var start: integer := 1;
  for var i := 1 to aString.Length do
    case aString[i] of
      '<', '>', '&', #13:
        begin
          Write(Copy(aString, start, i - start));
          case aString[i] of
            '<': Write('&lt;');
            '>': Write('&gt;');
            '&': Write('&amp;');
          else
            Write('&#x0D;');
          end;
          start := i + 1;
        end;
    end;
  Write(Copy(aString, start, MaxInt));
end;

procedure TWriterXmlite.AddXmlEscape(const aString: string);

  function IsHighSurrogate(aChar: PChar): boolean; inline;
  begin
    Result := (Ord(aChar^) >= $D800) and (Ord(aChar^) <= $DBFF);
  end;

  function IsLowSurrogate(aChar: PChar): boolean; inline;
  begin
    Result := (Ord(aChar^) >= $DC00) and (Ord(aChar^) <= $DFFF);
  end;

  function CombineSurrogates(aHighSurrogate, aLowSurrogate: PChar): cardinal; inline;
  begin
    Result := (Ord(aHighSurrogate^) - $D800) * $400 + (Ord(aLowSurrogate^) - $DC00) + $10000;
  end;

begin
  var cursor: PChar := PChar(aString);

  while cursor^ <> #0 do
  begin
    if IsHighSurrogate(cursor) then
    begin
      if IsLowSurrogate(cursor + 1) then
      begin
        var codePoint: cardinal := CombineSurrogates(cursor, cursor + 1); // combine surrogate pair and escape as a single code point
        Write('&#x');
        Write(codePoint.ToHexString(6));
        Write(';');
        Inc(cursor); // skip the low surrogate
      end
      { else - a high surrogate without its low one: invalid in XML, dropped }
    end
    { a low surrogate without its high one: invalid too, but written by the default branch below }
    else
      case cursor^ of
        #9, #10, #13: // tab and lineend
          begin
            Write('&#x');
            Write(Ord(cursor^).ToHexString(2));
            Write(';');
          end;
        '<':
          Write('&lt;');
        '>':
          Write('&gt;');
        '&':
          Write('&amp;');
        '"':
          Write('&quot;');
        '''':
          Write('&apos;');
      else
        Write(cursor^);
      end;

    Inc(cursor);
  end;
end;

// the value escaped like text (<, &, " and line breaks): FHIR comparator="&lt;=", a kept attribute read with entities
procedure TWriterXmlite.WriteAttribute(const aName, aValue, aPrefix: string);
begin
  if aPrefix.IsEmpty then
    Write(' %s="', [aName])
  else
    Write(' %s:%s="', [aPrefix, aName]);
  AddXmlEscape(aValue);
  Write('"');
end;

procedure TWriterXmlite.WriteAttributes(aObject: TBasite; aNamespaces: boolean);
begin
  if aNamespaces then
  begin
    if fDeclared = nil then
      fDeclared := TObjectList<TDictionary<string, string>>.Create;
    var declared: TDictionary<string, string> := TDictionary<string, string>.Create;
    fDeclared.Add(declared);
    Write(aObject.GetXmlns(declared));
  end;

  for var attribute: TPropertyData in aObject.Meta.Xmlite.Attributes.Values do
    if attribute.Required or aObject.IsPresent(attribute) then
      if (attribute.Xmlite.Namespace = attribute.ParentMeta.Xmlite.Namespace) and not attribute.Xmlite.Qualified then
        WriteAttribute(attribute.Xmlite.Name, attribute.Value[aObject])
      else
        WriteAttribute(attribute.Xmlite.NamePrefixed, attribute.Value[aObject]);

  if aObject.Meta.Xmlite.IsTXmlite then
    for var attribute: TPair<string, string> in TXmlite(aObject).XmlAttributes do
      WriteAttribute(attribute.Key, attribute.Value);
end;

{ TXmlite }

procedure TXmlite.Deinitialize;
begin
  fXmlContent.Free;
  fXmlUnknown.Free;
  fXmlAny.Free;
  fXmlns.Free;
  fXmlAttributeNamespaces.Free;
  fXmlAttributes.Free;
  inherited;
end;

procedure TXmlite.DoAfterParsing;
begin
end;

procedure TXmlite.DoAfterSerialization;
begin
end;

procedure TXmlite.DoBeforeParsing;
begin
end;

procedure TXmlite.DoBeforeSerialization;
begin
end;

procedure TXmlite.Initialize;
begin
  inherited;
  fXmlAttributes := TDictionary<string, string>.Create;
  fXmlAttributeNamespaces := TDictionary<string, string>.Create;
  fXmlns := TXmlns.Create;
  fXmlAny := TBasiteList<TBasite>.Create;
end;

procedure TXmlite.Clear;
begin
  inherited;
  fXmlText := '';
  fXmlPosition := 0;
  fXmlAny.Clear;
  fXmlAttributes.Clear;
  fXmlAttributeNamespaces.Clear;
  if fXmlUnknown <> nil then
    fXmlUnknown.Clear;
  if fXmlContent <> nil then
    fXmlContent.Clear;
end;

function TXmlite.GetXmlUnknown: TList<TXmliteUnknown>;
begin
  if fXmlUnknown = nil then
    fXmlUnknown := TList<TXmliteUnknown>.Create;
  Result := fXmlUnknown;
end;

function TXmlite.GetXmlContent: TList<TXmliteNode>;
begin
  if fXmlContent = nil then
    fXmlContent := TList<TXmliteNode>.Create;
  Result := fXmlContent;
end;

procedure TXmlite.AddNode(aKind: TXmliteNodeKind; const aText: string; aElement: TBasite; aProperty: TProperty; aIndex: integer);
begin
  var content: TList<TXmliteNode> := XmlContent;
  if (aKind = xnkText) and (content.Count > 0) and (content.Last.Kind = xnkText) then
  begin
    var node: TXmliteNode := content.Last;
    node.Text := node.Text + aText;
    content[content.Count - 1] := node;
    Exit;
  end;

  var node: TXmliteNode;
  node.Kind := aKind;
  node.Text := aText;
  node.Element := aElement;
  node.ElementProperty := aProperty;
  node.Index := aIndex;
  content.Add(node);
end;

function TXmlite.GetXmlText: string;
begin
  if not Meta.Xmlite.Mixed then
    Exit(fXmlText);
  Result := '';
  if (fXmlContent <> nil) and (fXmlContent.Count > 0) and (fXmlContent[0].Kind = xnkText) then
    Result := fXmlContent[0].Text;
end;

procedure TXmlite.SetXmlText(const aValue: string);
begin
  if not Meta.Xmlite.Mixed then
  begin
    fXmlText := aValue;
    Exit;
  end;

  // the leading text node: replaced, inserted before the first child, or removed ('')
  var content: TList<TXmliteNode> := XmlContent;
  if (content.Count > 0) and (content[0].Kind = xnkText) then
    if aValue.IsEmpty then
      content.Delete(0)
    else
    begin
      var node: TXmliteNode := content[0];
      node.Text := aValue;
      content[0] := node;
    end
  else if not aValue.IsEmpty then
  begin
    var node: TXmliteNode := Default(TXmliteNode);
    node.Kind := xnkText;
    node.Text := aValue;
    content.Insert(0, node);
  end;
end;

// the element property for children of aClass (aName: the one of that name); an exact class first, then a class it derives from
function TXmlite.PropertyOfClass(aClass: TClass; const aName: string): TProperty;
begin
  Result := nil;
  for var exact: boolean in [True, False] do
  begin
    var found: integer := 0;
    for var propertyElement: TProperty in Meta.Xmlite.Elements.Values do
    begin
      var propertyClass: TClass := nil;
      case propertyElement.PropertyType of
        ptBasite:
          propertyClass := TPropertyBasite(propertyElement).Meta.ClassItself;
        ptBasiteList:
          propertyClass := TPropertyBasiteList(propertyElement).Meta.ItemMeta.ClassItself;
      end;
      if (propertyClass = nil) or (not aName.IsEmpty and not SameText(propertyElement.Name, aName)) then
        Continue;
      if (exact and (propertyClass = aClass)) or (not exact and aClass.InheritsFrom(propertyClass)) then
      begin
        Result := propertyElement;
        Inc(found);
      end;
    end;
    if found > 1 then
      raise EArgumentException.CreateFmt('Add: %s has more than one property for %s - name the property',
        [ClassName, aClass.ClassName]);
    if found = 1 then
      Exit;
  end;
  raise EArgumentException.CreateFmt('Add: %s has no property for %s', [ClassName, aClass.ClassName]);
end;

function TXmlite.AddElement(aClass: TClass; const aProperty: string): TBasite;
begin
  var propertyElement: TProperty := PropertyOfClass(aClass, aProperty);
  var index: integer := 0;
  if propertyElement.PropertyType = ptBasiteList then
  begin
    var propertyList: TPropertyBasiteList := TPropertyBasiteList(propertyElement);
    if propertyList.ObjectPointer(Self)^ = nil then
      propertyList.ObjectPointer(Self)^ := propertyList.Meta.CreateList;
    Result := TBasiteClass(aClass).Create;
    propertyList.ObjectPointer(Self)^.Add(Result);
    index := propertyList.ObjectPointer(Self)^.Count - 1;
  end
  else
  begin // a single object: the one there (pre-created or lazy) - created when missing
    var propertyObject: TPropertyBasite := TPropertyBasite(propertyElement);
    if propertyObject.ObjectPointer(Self)^ = nil then
      propertyObject.ObjectPointer(Self)^ := TBasiteClass(aClass).Create;
    Result := propertyObject.ObjectPointer(Self)^;
  end;
  SetPresent(propertyElement);
  if Meta.Xmlite.Ordered then
    AddNode(xnkElement, '', Result, propertyElement, index);
end;

function TXmlite.Add<T>: T;
begin
  Result := T(AddElement(GetTypeData(TypeInfo(T))^.ClassType, ''));
end;

function TXmlite.Add<T>(const aProperty: string): T;
begin
  Result := T(AddElement(GetTypeData(TypeInfo(T))^.ClassType, aProperty));
end;

procedure TXmlite.AddText(const aText: string);
begin
  if aText.IsEmpty then
    Exit;
  if Meta.Xmlite.Mixed then
    AddNode(xnkText, aText, nil, nil, 0)
  else
    fXmlText := fXmlText + aText;
end;

procedure TXmlite.Remove(aElement: TBasite);
begin
  if aElement = nil then
    Exit;

  if fXmlContent <> nil then
    for var i := fXmlContent.Count - 1 downto 0 do
      if fXmlContent[i].Element = aElement then
        fXmlContent.Delete(i);

  if fXmlAny.Remove(aElement) >= 0 then
    Exit;
  for var propertyElement: TProperty in Meta.Xmlite.Elements.Values do
    case propertyElement.PropertyType of
      ptBasite:
        if TPropertyBasite(propertyElement).ObjectPointer(Self)^ = aElement then
        begin
          Clear(propertyElement);
          Exit;
        end;
      ptBasiteList:
        begin
          var list: TBasiteList := TPropertyBasiteList(propertyElement).ObjectPointer(Self)^;
          if (list <> nil) and (list.Remove(aElement) >= 0) then
          begin
            if list.Count = 0 then
              Clear(propertyElement);
            Exit;
          end;
        end;
    end;
end;

function TXmlite.InnerText: string;

  function TextOf(aChild: TBasite): string;
  begin
    if (aChild <> nil) and aChild.InheritsFrom(TXmlite) then
      Result := TXmlite(aChild).InnerText
    else
      Result := '';
  end;

begin
  if Meta.Xmlite.Ordered and (fXmlContent <> nil) and (fXmlContent.Count > 0) then
  begin
    Result := '';
    for var node: TXmliteNode in fXmlContent do
      case node.Kind of
        xnkText:
          Result := Result + node.Text;
        xnkElement:
          if node.Element <> nil then
            Result := Result + TextOf(node.Element)
          else if node.ElementProperty = nil then
            Continue
          else if node.ElementProperty.PropertyType = ptDataList then
          begin
            if node.Index < TPropertyDataList(node.ElementProperty).Count(Self) then // the list may have changed
              Result := Result + TPropertyDataList(node.ElementProperty).ItemText(Self, node.Index);
          end
          else if node.ElementProperty.PropertyType = ptData then
            Result := Result + TPropertyData(node.ElementProperty).Value[Self];
      end;
    Exit;
  end;

  // not ordered: XmlText, the text value, the children in schema order
  Result := fXmlText;
  if Assigned(Meta.Xmlite.TextProperty) then
    Result := Result + Meta.Xmlite.TextProperty.Value[Self];
  for var propertyElement: TProperty in Meta.Xmlite.Elements.Values do
    case propertyElement.PropertyType of
      ptData:
        if IsPresent(propertyElement) then
          Result := Result + TPropertyData(propertyElement).Value[Self];
      ptDataList:
        for var i := 0 to TPropertyDataList(propertyElement).Count(Self) - 1 do
          Result := Result + TPropertyDataList(propertyElement).ItemText(Self, i);
      ptBasite:
        if IsPresent(propertyElement) then
          Result := Result + TextOf(TPropertyBasite(propertyElement).ObjectPointer(Self)^);
      ptBasiteList:
        begin
          var list: TBasiteList := TPropertyBasiteList(propertyElement).ObjectPointer(Self)^;
          if list <> nil then
            for var item: TBasite in list do
              Result := Result + TextOf(item);
        end;
    end;
end;

function TXmlite.IsEmptyOrDefault: boolean;
begin
  // content kept in xs:any or as not described attributes is content as well
  Result := inherited and fXmlText.IsEmpty and (fXmlAny.Count = 0) and (fXmlAttributes.Count = 0) and
    ((fXmlUnknown = nil) or (fXmlUnknown.Count = 0)) and ((fXmlContent = nil) or (fXmlContent.Count = 0));
end;

function TXmlite.HasContent: boolean;
begin
  Result := not fXmlText.IsEmpty or (fXmlAny.Count > 0) or (fXmlAttributes.Count > 0) or
    ((fXmlUnknown <> nil) and (fXmlUnknown.Count > 0)) or ((fXmlContent <> nil) and (fXmlContent.Count > 0)) or inherited;
end;

{ TXmliteNode }

function TXmliteNode.IsText: boolean;
begin
  Result := Kind = xnkText;
end;

function TXmliteNode.IsElement<T>: boolean;
begin
  Result := (Kind = xnkElement) and (Element is T);
end;

function TXmliteNode.ElementAs<T>: T;
begin
  Result := Element as T;
end;

function TXmliteNode.Name: string;
begin
  Result := '';
  case Kind of
    xnkElement:
      if ElementProperty <> nil then
        Result := ElementProperty.Xmlite.Name
      else if Element <> nil then
        Result := Element.Meta.Xmlite.Name;
    xnkUnknown:
      Result := Text;
  end;
end;

procedure TXmlite.SetXsiType(aType: TClass);
begin
  if (aType = nil) or not aType.InheritsFrom(TBasite) then
    raise EArgumentException.Create('SetXsiType: a generated complex type class is expected');

  var typeMeta: TMetaBasite := TBasiteClass(aType).Meta;
  if (typeMeta.Xmlite.ComponentType <> xctComplexType) or (typeMeta.Xmlite.Namespace = nil) then
    raise EArgumentException.CreateFmt('SetXsiType: %s is not a complex type registered in a namespace', [aType.ClassName]);

  // XSD: the type must derive from the element's own one - the nearest complex type among the element's ancestors
  var declared: TClass := ClassType;
  while (declared <> nil) and declared.InheritsFrom(TBasite) and
    (TBasiteClass(declared).Meta.Xmlite.ComponentType <> xctComplexType) do
    declared := declared.ClassParent;
  if (declared = nil) or not declared.InheritsFrom(TBasite) or not aType.InheritsFrom(declared) then
    raise EArgumentException.CreateFmt('SetXsiType: %s is not derived from the type of %s', [aType.ClassName, ClassName]);

  fXmlAttributes.AddOrSetValue(cXsiPrefix + ':type', typeMeta.Xmlite.Namespace.Prefix + ':' + typeMeta.Xmlite.Name);
  fXmlAttributeNamespaces.AddOrSetValue(cXsiPrefix, cXsiUri);
  fXmlAttributeNamespaces.AddOrSetValue(typeMeta.Xmlite.Namespace.Prefix, typeMeta.Xmlite.Namespace.Uri);
end;

class function TXmlite.ObjectToXml(aObject: TBasite): string;
begin
  if aObject = nil then
    Exit;
  Result := aObject.ToXml;
end;

class function TXmlite.XmlToObject(const aXml: string; aObject: TBasite): boolean;
begin
  Result := (aObject <> nil) and aObject.FromXml(aXml);
end;

{ TNamespace }

procedure TNamespace.Add(aMeta: TMeta; aType: TXmliteComponentType);
var
  metaType: TMetaType absolute aMeta;
  metaBasite: TMetaBasite absolute aMeta;
begin
  aMeta.Xmlite.NamespaceRegister(Self, aType);
  case aType of
    xctSimpleType:
      fSimpleTypes.Add(aMeta.Xmlite.Name, metaType);
    xctComplexType:
      fComplexTypes.Add(aMeta.Xmlite.Name, metaBasite);
    xctAttribute:
      fAttributes.Add(aMeta.Xmlite.Name, metaType);
    xctAttributeGroup:
      fAttributeGroups.Add(aMeta.Xmlite.Name, metaBasite);
    xctElement:
      fElements.Add(aMeta.Xmlite.Name, metaBasite);
    xctElementGroup:
      fElementGroups.Add(aMeta.Xmlite.Name, metaBasite);
  end;

  if fUnitQualifiedName.IsEmpty then
    fUnitQualifiedName := aMeta.UnitQualifiedName;
end;

constructor TNamespace.Create(const aUri, aPrefix: string; aNaming: TNaming; const aSuffixSimpleType, aSuffixComplexType,
  aSuffixAttribute, aSuffixAttributeGroup, aSuffixElement, aSuffixElementGroup: string);
begin
  fUri := aUri;
  fPrefix := aPrefix;
  fNaming := aNaming;

  fSuffixSimpleType := aSuffixSimpleType;
  fSuffixLengthSimpleType := Length(fSuffixSimpleType);
  fSuffixComplexType := aSuffixComplexType;
  fSuffixLengthComplexType := Length(fSuffixComplexType);
  fSuffixAttributeGroup := aSuffixAttributeGroup;
  fSuffixLengthAttributeGroup := Length(fSuffixAttributeGroup);
  fSuffixAttribute := aSuffixAttribute;
  fSuffixLengthAttribute := Length(fSuffixAttribute);
  fSuffixElement := aSuffixElement;
  fSuffixLengthElement := Length(fSuffixElement);
  fSuffixElementGroup := aSuffixElementGroup;
  fSuffixLengthElementGroup := Length(fSuffixElementGroup);

  fAttributes := TDictObjectList<string, TMetaType>.Create(False);
  fAttributeGroups := TDictObjectList<string, TMetaBasite>.Create(False);
  fElements := TDictObjectList<string, TMetaBasite>.Create(False);
  fElementGroups := TDictObjectList<string, TMetaBasite>.Create(False);
  fSimpleTypes := TDictObjectList<string, TMetaType>.Create(False);
  fComplexTypes := TDictObjectList<string, TMetaBasite>.Create(False);
end;

destructor TNamespace.Destroy;
begin
  fComplexTypes.Free;
  fSimpleTypes.Free;
  fElementGroups.Free;
  fElements.Free;
  fAttributeGroups.Free;
  fAttributes.Free;
  inherited;
end;

{ TNamespaceList }

procedure TNamespaceList.Add(aNamespace: TNamespace);
begin
  fLocker.Enter;
  try
    fData.Add(aNamespace.Uri, aNamespace);
  finally
    fLocker.Leave;
  end;
end;

constructor TNamespaceList.Create;
begin
  fData := TDictObjectList<string, TNamespace>.Create;
  fLocker := TCriticalSection.Create;
end;

destructor TNamespaceList.Destroy;
begin
  fLocker.Free;
  fData.Free;
  inherited;
end;

function TNamespaceList.GetMetaBasite(const aUri: string; aType: TXmliteComponentType; const aXmlName: string): TMetaBasite;
begin
  Result := nil;
  if aUri.IsEmpty then
    Exit;

  var namespace: TNamespace := GetNamespace(aUri);
  if namespace = nil then
     Exit;

  case aType of
    xctComplexType:
      Result := namespace.ComplexTypes[aXmlName];
    xctAttributeGroup:
      Result := namespace.AttributeGroups[aXmlName];
    xctElement:
      Result := namespace.Elements[aXmlName];
    xctElementGroup:
      Result := namespace.ElementGroups[aXmlName];
  end;
end;

function TNamespaceList.GetNamespace(const aUri: string): TNamespace;
begin
  fLocker.Enter;
  try
    Result := fData[aUri];
  finally
    fLocker.Leave;
  end;
end;

function TNamespaceList.GetTypeName(const aUri: string; aType: TXmliteComponentType; const aXmlName: string; aFullName: boolean): string;
begin
  Result := '';
  if aUri.IsEmpty then
    Exit;

  var namespace: TNamespace := GetNamespace(aUri);
  if namespace = nil then
    Exit;

  var component: TMeta := nil;
  case aType of
    xctSimpleType:
      component := namespace.SimpleTypes[aXmlName];
    xctComplexType:
      component := namespace.ComplexTypes[aXmlName];
    xctAttribute:
      component := namespace.Attributes[aXmlName];
    xctAttributeGroup:
      component := namespace.AttributeGroups[aXmlName];
    xctElement:
      component := namespace.Elements[aXmlName];
    xctElementGroup:
      component := namespace.ElementGroups[aXmlName];
  end;

  if component <> nil then
    Result := IfThen(aFullName and not component.IsSystem, component.FullName, component.SimplifiedName);
end;

procedure TNamespaceList.IterateLocked(aNamespaceIterate: TNamespaceIterate);
begin
  fLocker.Enter;
  try
    for var namespace: TNamespace in fData.Values do
      aNamespaceIterate(namespace);
  finally
    fLocker.Leave;
  end;
end;

{ TMetaBankXmlite }

constructor TMetaBankXmlite.Create;
begin
  if Instance <> nil then
    Exit;
  Instance := inherited Create;
  fNamespaces := TNamespaceList.Create;
end;

class constructor TMetaBankXmlite.Create;
begin
  TMetaBankXmlite.RegisterExtension;
end;

destructor TMetaBankXmlite.Destroy;
begin
  fNamespaces.Free;
  inherited;
end;

function TMetaBankXmlite.ItemCreate(aMeta: TMeta): TMetaExtension;
begin
  if aMeta.ClassType = TMetaBasite then
    Result := TMetaBasiteXmlite.Create(TMetaBasite(aMeta))
  else if aMeta.ClassType = TMetaType then
    Result := TMetaTypeXmlite.Create(TMetaType(aMeta))
  else
    Result := TMetaXmlite.Create(aMeta);
end;

function TMetaBankXmlite.PropertyCreate(aProperty: TProperty): TPropertyExtension;
begin
  Result := TPropertyXmlite.Create(aProperty);
end;

class function TMetaBankXmlite.RegisterNamespace(const aUri: string; const aSimpleTypes: TArray<PTypeInfo>;
  const aComplexTypes: TArray<TBasiteClass>; const aAttributes: TArray<PTypeInfo>;
  const aAttributeGroups, aElements, aGroups: TArray<TBasiteClass>; const aPrefix: string; aNaming: TNaming;
  const aSuffixSimpleType, aSuffixComplexType, aSuffixAttribute, aSuffixAttributeGroup, aSuffixElement, aSuffixElementGroup: string)
  : TNamespace;
begin
  if Instance.TryGetNamespace(aUri, Result) then // already registered
    Exit;

  Result := TNamespace.Create(aUri, aPrefix, aNaming, aSuffixSimpleType, aSuffixComplexType, aSuffixAttribute, aSuffixAttributeGroup,
    aSuffixElement, aSuffixElementGroup);

  for var simpleType: PTypeInfo in aSimpleTypes do
    Result.Add(TMetaBank.RegisterType(simpleType), xctSimpleType);

  // global attributes before the classes: a member typed with one takes its namespace when it registers
  for var attribute: PTypeInfo in aAttributes do
    Result.Add(TMetaBank.RegisterType(attribute), xctAttribute);

  for var complexType: TBasiteClass in aComplexTypes do
    Result.Add(complexType.Meta, xctComplexType);

  for var attributeGroup: TBasiteClass in aAttributeGroups do
    Result.Add(attributeGroup.Meta, xctAttributeGroup);

  for var element: TBasiteClass in aElements do
    Result.Add(element.Meta, xctElement);

  for var elementGroup: TBasiteClass in aGroups do
    Result.Add(elementGroup.Meta, xctElementGroup);

  Instance.fNamespaces.Add(Result);
end;

function TMetaBankXmlite.TryGetNamespace(const aUri: string; var aNamespace: TNamespace): boolean;
begin
  aNamespace := fNamespaces.GetNamespace(aUri);
  Result := Assigned(aNamespace);
end;

{ TMetaHelper }

function TMetaHelper.Xmlite: TMetaXmlite;
begin
  if TMetaBankXmlite.Instance.ExtensionIndex < cardinal(Extensions.Count) then
    Result := TMetaXmlite(Extensions[TMetaBankXmlite.Instance.ExtensionIndex])
  else
    Result := nil;
end;

{ TMetaTypeHelper }

function TMetaTypeHelper.Xmlite: TMetaTypeXmlite;
begin
  Result := TMetaTypeXmlite(TMeta(Self).Xmlite);
end;

{ TMetaBasiteHelper }

function TMetaBasiteHelper.Xmlite: TMetaBasiteXmlite;
begin
  Result := TMetaBasiteXmlite(TMeta(Self).Xmlite);
end;

// [TXmliteAnyElement] on the class, or on one of its ancestors
function HasAnyElementAttribute(aClass: TClass; aWithAncestors: boolean = True): boolean;
begin
  Result := False;
  var someClass: TClass := aClass;
  while (someClass <> nil) and someClass.InheritsFrom(TXmlite) do
  begin
    for var attribute: TCustomAttribute in TMetaBank.RttiContext.GetType(someClass.ClassInfo).GetAttributes do
      if attribute.ClassType = TXmliteAnyElementAttribute then
        Exit(True);

    if not aWithAncestors then
      Exit;
    someClass := someClass.ClassParent;
  end;
end;

// [TOrdered] and [TMixed] on the class or one of its ancestors (an XHTML <b> is a mixed Inline) - RTTI, not the ancestors'
// extensions: those may not exist yet while classes register
procedure ReadOrderAttributes(aClass: TClass; out aOrdered, aMixed: boolean);
begin
  aOrdered := False;
  aMixed := False;
  var someClass: TClass := aClass;
  while (someClass <> nil) and someClass.InheritsFrom(TXmlite) and not aMixed do
  begin
    for var attribute: TCustomAttribute in TMetaBank.RttiContext.GetType(someClass.ClassInfo).GetAttributes do
      if attribute.ClassType = TOrderedAttribute then
        aOrdered := True
      else if attribute.ClassType = TMixedAttribute then
        aMixed := True;
    someClass := someClass.ClassParent;
  end;
end;

{ TMetaBasiteXmlite }

constructor TMetaBasiteXmlite.Create(aMeta: TMetaBasite);
begin
  inherited Create(aMeta);

  fAttributes := TDictObjectList<TUriedName, TPropertyData>.Create(TUriedName.TComparer.Create, TUriedName.TEqualityComparer.Create, False);
  fElements := TDictObjectList<TUriedName, TProperty>.Create(TUriedName.TComparer.Create, TUriedName.TEqualityComparer.Create, False);
  for var propertyInfo in Meta.Properties do
  begin
    var uriedName: TUriedName := TUriedName.Create(TPropertyXmlite.XmlName(propertyInfo));
    case propertyInfo.PropertyType of
      ptData:
        begin
          var propertyData: TPropertyData := TPropertyData(propertyInfo);
          if FieldIsText(propertyData) then
            fTextProperty := propertyData
          else if FieldIsElement(propertyData) then
            fElements.Add(uriedName, propertyData)
          else
            fAttributes.Add(uriedName, propertyData);
        end;
      ptBasite, ptBasiteList, ptDataList:
        fElements.Add(uriedName, propertyInfo);
    end;
  end;

  fIsTXmlite := Meta.ClassItself.InheritsFrom(TXmlite);
  if not fIsTXmlite then
    Exit;

  // inherited from the parent class - whose extension may not exist yet (XHTML span in span registers while registering)
  var parentXmlite: TMetaBasiteXmlite := aMeta.ClassItself.ClassParent.Meta.Xmlite;
  if parentXmlite <> nil then
    fProcessAnyElement := parentXmlite.ProcessAnyElement
  else
    fProcessAnyElement := HasAnyElementAttribute(aMeta.ClassItself.ClassParent);
  if not fProcessAnyElement then
    fProcessAnyElement := HasAnyElementAttribute(aMeta.ClassItself, False);

  var hasOrdered, hasMixed: boolean;
  ReadOrderAttributes(aMeta.ClassItself, hasOrdered, hasMixed);
  fOrdered := hasOrdered;
  Mixed := hasMixed;
end;

procedure TMetaBasiteXmlite.SetMixed(aValue: boolean);
begin
  fMixed := aValue;
  if aValue then
    fOrdered := True;
end;

destructor TMetaBasiteXmlite.Destroy;
begin
  fAttributes.Free;
  fElements.Free;
  inherited;
end;

function TMetaBasiteXmlite.FieldIsElement(aField: TProperty): boolean;
begin
  Result := False;
  for var attribute: TCustomAttribute in aField.RttiProperty.GetAttributes do
    if attribute.ClassType = TXmliteElementAttribute then
      Exit(True);
end;

function TMetaBasiteXmlite.FieldIsText(aField: TProperty): boolean;
begin
  Result := False;
  for var attribute: TCustomAttribute in aField.RttiProperty.GetAttributes do
    if attribute.ClassType = TXmliteTextAttribute then
      Exit(True);
end;

function TMetaBasiteXmlite.GetMeta: TMetaBasite;
begin
  Result := TMetaBasite(inherited Meta);
end;

function TMetaBasiteXmlite.GetProcessAnyAttribute: boolean;
begin
  Result := fIsTXmlite and fProcessAnyAttribute;
end;

function TMetaBasiteXmlite.GetProcessAnyElement: boolean;
begin
  Result := fIsTXmlite and fProcessAnyElement;
end;

procedure TMetaBasiteXmlite.NamespaceRegister(aNamespace: TNamespace; aType: TXmliteComponentType);
begin
  if Self = nil then
    Exit;

  inherited;
  for var propertyInfo: TProperty in Meta.Properties do
  begin
    propertyInfo.Xmlite.NamespaceRegister(aNamespace);

    var uriedName: TUriedName := TUriedName.Create(propertyInfo.Xmlite.Namespace.Uri, propertyInfo.Xmlite.Name);
    case propertyInfo.PropertyType of
      ptData:
        begin
          var propertyData: TPropertyData := TPropertyData(propertyInfo);
          if FieldIsText(propertyData) then
            fTextProperty := propertyData
          else if FieldIsElement(propertyData) then
            fElements.Add(uriedName, propertyData)
          else
            fAttributes.Add(uriedName, propertyData);
        end;

      ptBasite, ptBasiteList, ptDataList:
        fElements.Add(uriedName, propertyInfo);
    end;
  end;
end;

procedure TMetaBasiteXmlite.NamespaceUnregister;
begin
  if Self = nil then
    Exit;

  if fAttributes <> nil then
    fAttributes.Clear;
  if fElements <> nil then
    fElements.Clear;

  for var propertyInfo: TProperty in Meta.Properties do
    propertyInfo.Xmlite.NamespaceUnregister;

  inherited;
end;

{ TMetaBankHelper }

class function TMetaBankHelper.Xmlite: TMetaBankXmlite;
begin
  Result := TMetaBankXmlite.Instance;
end;

{ TMetaXmlite }

constructor TMetaXmlite.Create(aMeta: TMeta);
begin
  inherited;
  NamespaceUnregister;
end;

procedure TMetaXmlite.NamespaceRegister(aNamespace: TNamespace; aType: TXmliteComponentType);
begin
  if Self = nil then
    Exit;

  NamespaceUnregister;

  fComponentType := aType;
  fNamespace := aNamespace;
  fName := PChar(Meta.SimplifiedName) + 1 { T };

  case aType of
    xctSimpleType:
      if (fNamespace.fSuffixLengthSimpleType > 0) and fName.EndsWith(fNamespace.fSuffixSimpleType) then
        SetLength(fName, Length(fName) - fNamespace.fSuffixLengthSimpleType);
    xctComplexType:
      if (fNamespace.fSuffixLengthComplexType > 0) and fName.EndsWith(fNamespace.fSuffixComplexType) then
        SetLength(fName, Length(fName) - fNamespace.fSuffixLengthComplexType);
    xctAttribute:
      if (fNamespace.fSuffixLengthAttribute > 0) and fName.EndsWith(fNamespace.fSuffixAttribute) then
        SetLength(fName, Length(fName) - fNamespace.fSuffixLengthAttribute);
    xctAttributeGroup:
      if (fNamespace.fSuffixLengthAttributeGroup > 0) and fName.EndsWith(fNamespace.fSuffixAttributeGroup) then
        SetLength(fName, Length(fName) - fNamespace.fSuffixLengthAttributeGroup);
    xctElement:
      if (fNamespace.fSuffixLengthElement > 0) and fName.EndsWith(fNamespace.fSuffixElement) then
        SetLength(fName, Length(fName) - fNamespace.fSuffixLengthElement);
    xctElementGroup:
      if (fNamespace.fSuffixLengthElementGroup > 0) and fName.EndsWith(fNamespace.fSuffixElementGroup) then
        SetLength(fName, Length(fName) - fNamespace.fSuffixLengthElementGroup);
  end;

  // [TName('Account.Coverage')]: the exact XML name no naming style gives back; else the type's or namespace's naming
  var fNaming: TNaming := fNamespace.Naming;
  var customName: string := '';
  for var attribute: TCustomAttribute in Self.Meta.RttiType.GetAttributes do
    if attribute.ClassType = TNameAttribute then
      customName := TNameAttribute(attribute).CustomName
    else if attribute.ClassType.InheritsFrom(TNamingAttribute) then
      fNaming := TNamingAttribute(attribute).Naming;

  if customName.IsEmpty then
    fName := TUtility.FromPascalCase(fName, fNaming)
  else
    fName := customName;

  if not fNamespace.Prefix.IsEmpty then
    fNamePrefixed := fNamespace.Prefix + ':' + fName;
end;

procedure TMetaXmlite.NamespaceUnregister;
begin
  if Self = nil then
    Exit;

  if fNamespace <> nil then
    case fComponentType of
      xctSimpleType:
        fNamespace.SimpleTypes.Remove(fName);
      xctComplexType:
        fNamespace.ComplexTypes.Remove(fName);
      xctAttribute:
        fNamespace.Attributes.Remove(fName);
      xctAttributeGroup:
        fNamespace.AttributeGroups.Remove(fName);
      xctElement:
        fNamespace.Elements.Remove(fName);
      xctElementGroup:
        fNamespace.ElementGroups.Remove(fName);
    end;

  fNamespace := nil;
  fComponentType := xctUndefined;
  if Meta.SimplifiedName[1] = 'T' then
    fName := PChar(Meta.SimplifiedName) + 1
  else
    fName := Meta.SimplifiedName;
  fNamePrefixed := fName;
end;

{ TMetaTypeXmlite }

constructor TMetaTypeXmlite.Create(aMeta: TMetaType);
begin
  inherited Create(aMeta);
end;

function TMetaTypeXmlite.GetMeta: TMetaType;
begin
  Result := TMetaType(inherited Meta);
end;

{ TPropertyXmlite }

constructor TPropertyXmlite.Create(aProperty: TProperty);
begin
  inherited;
  NamespaceUnregister;
end;

class function TPropertyXmlite.XmlName(aProperty: TProperty): string;
begin
  // Basite name already follows [TName] or class [TNaming] (or the default naming); property [TNaming] is Xmlite-level
  Result := aProperty.Name;
  for var attribute: TCustomAttribute in aProperty.RttiProperty.GetAttributes do
    if attribute.ClassType = TNameAttribute then
      Exit(aProperty.Name)
    else if attribute.ClassType.InheritsFrom(TNamingAttribute) then
      Result := TUtility.FromPascalCase(aProperty.RttiProperty.Name, TNamingAttribute(attribute).Naming);
end;

procedure TPropertyXmlite.NamespaceRegister(aNamespace: TNamespace);
begin
  if Self = nil then
    Exit;

  NamespaceUnregister;

  var hasOwnName: boolean := False;
  fQualified := False;
  for var attribute: TCustomAttribute in PropertyInfo.RttiProperty.GetAttributes do
    if attribute.ClassType.InheritsFrom(TNamespaceAttribute) then
      TMetaBankXmlite.Instance.TryGetNamespace(TNamespaceAttribute(attribute).Uri, fNamespace)
    else if attribute.ClassType = TQualifiedAttribute then
      fQualified := True
    else if (attribute.ClassType = TNameAttribute) or attribute.ClassType.InheritsFrom(TNamingAttribute) then
      hasOwnName := True;

  // a reference to a global element or attribute belongs to its namespace (an attribute qualified); a local member to its owner
  if fNamespace = nil then
  begin
    var typeMeta: TMeta := PropertyInfo.Meta;
    if PropertyInfo.PropertyType = ptBasiteList then
      typeMeta := TPropertyBasiteList(PropertyInfo).Meta.ItemMeta;
    var typeXmlite: TMetaXmlite := nil;
    if typeMeta <> nil then
      typeXmlite := typeMeta.Xmlite;
    if (typeXmlite <> nil) and (typeXmlite.Namespace <> nil) then
      case typeXmlite.ComponentType of
        xctElement:
          fNamespace := typeXmlite.Namespace;
        xctAttribute:
          begin
            fNamespace := typeXmlite.Namespace;
            fQualified := True;
          end;
      end;
  end;

  if fNamespace = nil then
    fNamespace := aNamespace;

  // a member follows its namespace naming (as components do), unless the property defines its own [TName] or [TNaming]
  if not hasOwnName then
    fName := TUtility.FromPascalCase(PropertyInfo.RttiProperty.Name, fNamespace.Naming);

  if not fNamespace.Prefix.IsEmpty then
    fNamePrefixed := fNamespace.Prefix + ':' + fName;
  fNameUried := fNamespace.Uri + ':' + fName;
end;

procedure TPropertyXmlite.NamespaceUnregister;
begin
  if Self = nil then
    Exit;

  fNamespace := nil;
  fName := XmlName(PropertyInfo); // the name out of any namespace
  fNamePrefixed := fName;
  fNameUried := fName;
end;

{ TPropertyHelper }

function TPropertyHelper.Xmlite: TPropertyXmlite;
begin
  if TMetaBankXmlite.Instance.ExtensionIndex < cardinal(Extensions.Count) then
    Result := TPropertyXmlite(Extensions[TMetaBankXmlite.Instance.ExtensionIndex])
  else
    Result := nil;
end;

{ TNamespaceAttribute }

constructor TNamespaceAttribute.Create(const aUri: string);
begin
  fUri := aUri;
end;

end.
