unit ProRock.Xmlite;

interface

uses System.Classes, System.SysUtils, System.StrUtils, System.Generics.Collections, System.Generics.Defaults, System.Rtti, System.Math,
  System.SyncObjs, System.TypInfo,
  ProRock.Basite, ProRock.Utility, ProRock.Xmlite.Utility;

// todo: realize Choice stuff somehow properly and useful

const
  cXmliteTextNodeFieldName = 'xmlText';
  cXmlDeclaration = '<?xml version="1.0" encoding="UTF-8"?>'; // todo: make it somehow better

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
  TPropertyList = ProRock.Basite.TPropertyList;
  TMeta = ProRock.Basite.TMeta;
  TMetaType = ProRock.Basite.TMetaType;
  TMetaBasite = ProRock.Basite.TMetaBasite;
  TMetaBasiteList = ProRock.Basite.TMetaBasiteList;
  TMetaBank = ProRock.Basite.TMetaBank;
  {$ENDREGION}

  TWriterXmlite = class(TWriterBase) // todo: should be moved to ProRock.Xmlite.Utility
  private
    fPretty: boolean;

    procedure WriteAttribute(const aName, aValue: string; const aPrefix: string = ''); inline;
    procedure WriteAttributes(aObject: TBasite; aNamespaces: boolean = False); inline;
  public
    property Pretty: boolean read fPretty write fPretty;

    procedure AddIndent; reintroduce; inline;
    procedure FinishLine(const aEndingText: string = ''); reintroduce; inline;

    procedure AddTagOpen(const aName: string; aObject: TBasite; aNamespaces: boolean); inline;
    procedure AddTagEmpty(const aName: string; aObject: TBasite; aNamespaces: boolean); inline;
    procedure AddTagClose(const aName: string); inline;
    // a tag with attributes and text content in one line - indentation would become a part of the text
    procedure AddTagText(const aName: string; aObject: TBasite; aNamespaces: boolean; const aText: string); inline;
    procedure AddTextNode(const aName, aValue: string; aFieldInfo: TProperty; aObject: TBasite = nil); inline;
    procedure AddXmlEscape(const aString: string); inline;
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
    property XmlAttributes: TDictionary<string, string> read fXmlAttributes; // todo: remove when XmlAnyAttribute will be ready
    property XmlText: string read fXmlText write fXmlText;
    // prefix -> URI for the prefixed names (and xsi:type values) in XmlAttributes - read from the document, set by
    // SetXsiType; the writer declares them, so a document read and written back stays valid XML
    property XmlAttributeNamespaces: TDictionary<string, string> read fXmlAttributeNamespaces;

    // xsi:type: this element holds a value of aType, a complex type derived from its declared one (XSD) - e.g. OPC requires
    // <dcterms:created xsi:type="dcterms:W3CDTF">: Created.SetXsiType(TW3cdtfCT). Raises EArgumentException for a class
    // that is not a registered complex type derived from the element's type
    procedure SetXsiType(aType: TClass);

    procedure Clear; overload; override;
    function IsEmptyOrDefault: boolean; override;
    function HasContent: boolean; override;
  end;

  TXmliteList<T: TXmlite, constructor> = class(TBasiteList<T>);
  TXmliteList = TXmliteList<TXmlite>;

  TXmliteComplexType = class(TXmlite); // so far just to mark ComplexType (without base type)
  TXmliteComplexTypeRestricted = class(TXmlite); // so far just to mark ComplexType based on restriction
  TXmliteAttributeGroup = class(TXmlite); // so far just to mark AttributeGroups
  TXmliteElement = class(TXmlite); // so far just to mark Elements
  TXmliteElementGroup = class(TXmlite); // so far just to mark Groups

  // todo: consider realizing it through generics, like TXmliteTextElement<TSomeType>
  TXmliteTextElement = class abstract(TXmlite) // todo: redesign parsing/serialization - it shouldn't present in general ToXml/FromXml
  protected
    function GetXmlText: string; virtual; abstract;
    procedure SetXmlText(const aValue: string); virtual; abstract;
  public
    function IsEmptyOrDefault: boolean; override;
  published
    property xmlText: string read GetXmlText write SetXmlText;
  end;

  TXmliteTextNodeString = class(TXmliteTextElement)
  private
    fValue: string;
  protected
    function GetXmlText: string; override;
    procedure SetXmlText(const aValue: string); override;
  public
    property Value: string read fValue write fValue;
  end;

  TXmliteTextNodeInteger = class(TXmliteTextElement)
  private
    fValue: integer;
  protected
    function GetXmlText: string; override;
    procedure SetXmlText(const aValue: string); override;
  public
    property Value: integer read fValue write fValue;
  end;

  TXmliteTextNodeInt64 = class(TXmliteTextElement)
  private
    fValue: Int64;
  protected
    function GetXmlText: string; override;
    procedure SetXmlText(const aValue: string); override;
  public
    property Value: Int64 read fValue write fValue;
  end;

  TXmliteTextNodeCardinal = class(TXmliteTextElement)
  private
    fValue: cardinal;
  protected
    function GetXmlText: string; override;
    procedure SetXmlText(const aValue: string); override;
  public
    property Value: cardinal read fValue write fValue;
  end;

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
    // aScope: the default namespace in scope (xmlns="...") - a child element is prefixed exactly when its namespace is another
    // one; aNamespaces: the element declares its namespaces (its own one becomes the default in scope)
    procedure ToXml(aWriter: TWriterXmlite; const aName: string; aScope: TNamespace; aNamespaces: boolean;
      aXmlHeader: boolean = False); overload;
  public
    constructor CreateFromXml(const aXml: string);

    function GetXmlns: string;

    procedure ToXml(aStream: TStream; const aName: string = ''; aXmlHeader: boolean = True); overload;
    function ToXml(const aName: string = ''; aXmlHeader: boolean = True): string; overload;
    function FromXml(const aXml: string): boolean; overload;
  end;

  TXmliteElementAttribute = class(TCustomAttribute);
  // the property holds the element's text content (XSD simpleContent: text and attributes, no child elements)
  TXmliteTextAttribute = class(TCustomAttribute);
  TXmliteAnyElementAttribute = class(TCustomAttribute);
  TXmliteAnyAttributeAttribute = class(TCustomAttribute); // todo: realize through TXmlite.ProcessAnyAttribute

  TNamespaceAttribute = class(TCustomAttribute)
  private
    fUri: string;
  public
    constructor Create(const aUri: string);
    property Uri: string read fUri;
  end;

  // XSD form="qualified": the attribute is written with its namespace prefix also in elements of its own namespace - a global
  // attribute referenced within its schema (wsu:Id in wsu:Timestamp); an attribute of another namespace is prefixed anyway
  TQualifiedAttribute = class(TCustomAttribute);

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

    // XML name of a property out of any namespace: [TName] (exact), property [TNaming], class [TNaming], default naming;
    // once registered in a namespace: [TName], property [TNaming], the namespace naming
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
    fIsTXmlite, fProcessAnyElement, fProcessAnyAttribute: boolean;
    fAttributes: TDictObjectList<TUriedName, TPropertyData>;
    fElements: TDictObjectList<TUriedName, TProperty>;
    fTextProperty: TPropertyData;

    function FieldIsElement(aField: TProperty): boolean; inline;
    function FieldIsText(aField: TProperty): boolean; inline;
    function GetMeta: TMetaBasite;
    function GetProcessAnyAttribute: boolean;
    function GetProcessAnyElement: boolean;
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
    property ProcessAnyAttribute: boolean read GetProcessAnyAttribute write fProcessAnyAttribute; // todo: realize it
  end;

  TMetaBasiteXmliteText = class(TMetaBasiteXmlite)
  private
    fXmlTextProperty: TPropertyData;
  public
    constructor Create(aMeta: TMetaBasite); override;

    property xmlTextProperty: TPropertyData read fXmlTextProperty;
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

{ TBasiteHelper }

constructor TBasiteHelper.CreateFromXml(const aXml: string);
begin
  inherited Create;
  FromXml(PChar(aXml));
end;

function TBasiteHelper.FromXml(const aXml: string): boolean;
begin
  // parsing works in place (unescaping, temporary terminators): the caller's own string is parsed with no copy,
  // but a literal (read-only memory) or a string shared with other owners must not be changed - they are copied
  var xmlCopy: string;
  var xmlCursor: PChar;
  if StringRefCount(aXml) = 1 then
    xmlCursor := PChar(aXml)
  else
  begin
    xmlCopy := aXml;
    UniqueString(xmlCopy);
    xmlCursor := PChar(xmlCopy);
  end;
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

  // pass DTD and comments
  while aXmlCursor[1] = '!' do
    if not TReaderXmlite.PassDtd(aXmlCursor) or not TReaderXmlite.MoveToChar(aXmlCursor, '<') then
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
        else if Meta.Xmlite.IsTXmlite then
          if (attributePrefix <> 'xmlns') and (not attributePrefix.IsEmpty or (attributeName <> 'xmlns')) then // pass xmlns stuff
          begin
            TXmlite(Self).XmlAttributes.AddOrSetValue(attributeFullName, attributeValue);
            // its prefix (xsi), and for xsi:type the prefix of the value (dcterms:W3CDTF) - declared again on write
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
      else
      begin
        if not TReaderXmlite.MoveToVisualChar(aXmlCursor) then
          Exit;

        if Meta.Xmlite.IsTXmlite and (aXmlCursor^ <> '<') then
          TXmlite(Self).xmlText := TReaderXmlite.ReadUnescapeInPlace(aXmlCursor, '<');
      end;

      ReadTagContents(aXmlCursor, objectName, xmlns);

      Result := True;
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

  procedure ReadTextNode(var aCursor: PChar; aTextNode: TXmliteTextElement; aXmlns: TXmlns); inline;
  begin
    if aCursor^ = ' ' then // attributes
      while TReaderXmlite.MoveToVisualChar(aCursor) and (aCursor^ <> '>') do
      begin
        var attributeName, attributeNameWithPrefix, attributePrefix, attributeValue: string;
        if not TReaderXmlite.ReadAttributeName(aCursor, attributePrefix, attributeName, attributeNameWithPrefix) then
          Exit;

        attributeValue := TReaderXmlite.ReadQuotedValueInPlace(aCursor);

        // the same lookup as for attributes of ordinary objects - by XML (Xmlite) name, not by Basite one
        var uri: string;
        if attributePrefix.IsEmpty and Assigned(aTextNode.Meta.Xmlite.Namespace) then
          uri := aTextNode.Meta.Xmlite.Namespace.Uri
        else
          uri := aXmlns[attributePrefix];

        var propertyData: TPropertyData := aTextNode.Meta.Xmlite.Attributes[TUriedName.Create(uri, attributeName)];
        if propertyData = nil then
          propertyData := aTextNode.Meta.Xmlite.Attributes[TUriedName.Create('', attributeName)];
        if propertyData <> nil then
          propertyData.Value[aTextNode] := attributeValue;
      end;

    aTextNode.xmlText := TReaderXmlite.ReadTextNodeContents(aCursor);
  end;

begin
  Result := False;

  while not Result do
  begin
    if not TReaderXmlite.MoveToChar(aCursor, '<') then
      Exit;

    // pass DTD/comments
    while aCursor[1] = '!' do
      if not TReaderXmlite.PassDtd(aCursor) or not TReaderXmlite.MoveToChar(aCursor, '<') then
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

    // unqualified local element (elementFormDefault="unqualified", e.g. faultcode of SOAP 1.1 Fault) belongs to its parent type,
    // the same way as unprefixed attributes
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
          Continue;
        end
        else
          element.Free;
      end;
    end;

    if propertyElement = nil then // as a fallback - try to find such property without tag
      propertyElement := Meta.Xmlite.Elements[TUriedName.Create('', tagName)];

    // compat 1.3.0, drop in 2.0 (BACKLOG, compatibility shims): ProRock before 1.3.0 wrote some elements in the wrong namespace
    // (a reference or the content of another namespace's type in the parent's one: <ScopeItem><Code> instead of
    // <b:ScopeItem><b:Code>) - matched by name, so older documents still read; it also makes the reader lenient
    if propertyElement = nil then
      for var candidate: TProperty in Meta.Xmlite.Elements.Values do
        if candidate.Xmlite.Name = tagName then
        begin
          propertyElement := candidate;
          break;
        end;

    if propertyElement = nil then
    begin // no such name in elements list of the object - skip the whole node till it's end
      Inc(aCursor);
      if not TReaderXmlite.PassNode(aCursor, tagFullName) then
        Exit;
    end
    else
      case propertyElement.PropertyType of
        ptData:
          begin
            TPropertyData(propertyElement).Value[Self] := TReaderXmlite.ReadTextNodeContents(aCursor);
            TReaderXmlite.PassNode(aCursor, tagFullName);
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
            if propertyBasite.Meta.ClassItself.InheritsFrom(TXmliteTextElement) then
            begin
              ReadTextNode(aCursor, TXmliteTextElement(fieldObject), aXmlns);
              TReaderXmlite.PassNode(aCursor, tagFullName);
            end
            else
            begin
              aCursor := cursorStart;
              fieldObject.FromXml(aCursor, aXmlns);
            end;
            SetPresent(propertyElement); // also when all its values are defaults (<fill/>)
          end;
        ptBasiteList:
          begin
            var propertyObjectList: TPropertyBasiteList := TPropertyBasiteList(propertyElement);
            if propertyObjectList.ObjectPointer(Self)^ = nil then
            begin
              if not Assigned(propertyObjectList.Meta.CreateMethod) then
                Exit;
              propertyObjectList.ObjectPointer(Self)^ :=
                TBasiteList(propertyObjectList.Meta.CreateMethod.Invoke(propertyObjectList.Meta.ClassItself, []).AsObject);
            end;
            var objectListItem: TBasite := propertyObjectList.Meta.ItemMeta.ClassItself.Create;
            if propertyObjectList.Meta.ItemMeta.ClassItself.InheritsFrom(TXmliteTextElement) then
            begin
              ReadTextNode(aCursor, TXmliteTextElement(objectListItem), aXmlns);
              TReaderXmlite.PassNode(aCursor, tagFullName);
            end
            else
            begin
              aCursor := cursorStart;
              objectListItem.FromXml(aCursor, aXmlns);
            end;
            propertyObjectList.ObjectPointer(Self).Add(objectListItem);
            SetPresent(propertyElement);
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

  // text of mixed content (OOXML cp:keywords: "q3, plan"): read into XmlText, so written back too
  if Meta.Xmlite.IsTXmlite and not TXmlite(Self).XmlText.IsEmpty then
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

  // the namespace in scope is the default one: no prefix; any other namespace: prefixed (declared by GetXmlns)
  function elementName(aProperty: TProperty; aScope: TNamespace): string;
  begin
    if (aProperty.Xmlite.Namespace = nil) or (aProperty.Xmlite.Namespace = aScope) then
      Result := aProperty.Xmlite.Name
    else
      Result := aProperty.Xmlite.NamePrefixed;
  end;

begin
  if Self = nil then
    Exit;

  aWriter.Pretty := TBasite.Pretty;

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
        aWriter.AddTagOpen(objectName, Self, aNamespaces);

        if Meta.Xmlite.IsTXmlite and not TXmlite(Self).XmlText.IsEmpty then
          aWriter.AddXmlEscape(TXmlite(Self).XmlText);

        aWriter.IncLevel;

        for var propertyElement in Meta.Xmlite.Elements.Values do
          case propertyElement.PropertyType of
            ptData:
              begin
                var propertyData: TPropertyData := TPropertyData(propertyElement);
                if propertyData.Required or IsPresent(propertyData) then
                  aWriter.AddTextNode(elementName(propertyElement, scope), propertyData.Value[Self], propertyData);
              end;
            ptBasite:
              begin
                // a pre-created object is written only when present (read, marked, or with content) or required - its own
                // required values do not make it present (<drawing r:id=""/> was written though absent)
                var propertyBasite: TPropertyBasite := TPropertyBasite(propertyElement);
                var fieldObject: TBasite := propertyBasite.ObjectPointer(Self)^;
                if (fieldObject = nil) or not (propertyBasite.Required or IsPresent(propertyBasite)) then
                  Continue;
                if propertyBasite.Meta.ClassItself.InheritsFrom(TXmliteTextElement) then
                  aWriter.AddTextNode(elementName(propertyElement, scope), TXmliteTextElement(fieldObject).xmlText,
                    TMetaBasiteXmliteText(fieldObject.Meta.Xmlite).xmlTextProperty, fieldObject)
                else
                  fieldObject.ToXml(aWriter, elementName(propertyElement, scope), scope, False);
              end;
            ptBasiteList:
              begin
                // list items are always written - an item with only defaults too (<fill/>: Excel refers to it by index)
                var propertyBasiteList: TPropertyBasiteList := TPropertyBasiteList(propertyElement);
                var list: TBasiteList := propertyBasiteList.ObjectPointer(Self)^;
                if list = nil then
                  Continue;
                for var i := 0 to list.Count - 1 do
                  if propertyBasiteList.Meta.ItemMeta.ClassItself.InheritsFrom(TXmliteTextElement) then
                    aWriter.AddTextNode(elementName(propertyElement, scope), TXmliteTextElement(list[i]).xmlText,
                      TMetaBasiteXmliteText(list[i].Meta.Xmlite).xmlTextProperty, list[i])
                  else
                    list[i].ToXml(aWriter, elementName(propertyElement, scope), scope, False);
              end;
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

        aWriter.DecLevel;

        aWriter.AddIndent;
        aWriter.AddTagClose(objectName);
      end;
  end;

  if Meta.Xmlite.IsTXmlite then
    TXmlite(Self).DoAfterSerialization;
end;

procedure TBasiteHelper.ToXml(aStream: TStream; const aName: string; aXmlHeader: boolean);
begin
  var writer: TWriterXmlite := TWriterXmlite.Create(aStream);
  try
    ToXml(writer, aName, nil, True, aXmlHeader);
  finally
    writer.Free;
  end;
end;

function TBasiteHelper.ToXml(const aName: string; aXmlHeader: boolean): string;
begin
  var writer: TWriterXmlite := TWriterXmlite.Create;
  try
    ToXml(writer, aName, nil, True, aXmlHeader);
    Result := writer.Text;
  finally
    writer.Free;
  end;
end;

function TBasiteHelper.GetXmlns: string;

  // aPrefixed: namespaces used with a prefix in this subtree - the own one is then declared with a prefix too (a qualified
  // attribute); aScope: the default namespace in scope - xs:any content of another one declares its namespaces itself
  // aKept: prefix -> URI of kept attributes (TXmlite.XmlAttributeNamespaces)
  procedure FillXmlnsList(aXmlnsList, aPrefixed: THashedObjectList<TNamespace>; aKept: TDictionary<string, string>; aObject: TBasite;
    aScope: TNamespace);

    procedure AddPropertyDataXmlns(aXmlnsList: THashedObjectList<TNamespace>; aPropertyData: TPropertyData; aObject: TBasite); inline;
    begin
      if not aPropertyData.Required and not aObject.IsPresent(aPropertyData) then
        Exit;

      aXmlnsList.Add(aPropertyData.Xmlite.Namespace);
      aXmlnsList.Add(aPropertyData.Meta.Xmlite.Namespace);
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
      if element.PropertyType in [ptBasite, ptBasiteList] then
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

    // xs:any content in the scope is written as it is (its namespaces are declared here); content of another namespace declares
    // its own (ToXml)
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

    // the prefixes of kept attributes, as the document had them (xsi of xsi:type) - unless the prefix is declared already
    // (for another URI too: the attribute would change meaning either way, the element's own names win)
    for var keptPrefix: TPair<string, string> in kept do
      if not declared.ContainsKey(keptPrefix.Key) and (keptPrefix.Key <> cXmlPrefix) then
      begin
        Result := Result + Format(' xmlns:%s="%s"', [keptPrefix.Key, keptPrefix.Value]);
        declared.Add(keptPrefix.Key, keptPrefix.Value);
      end;
  finally
    declared.Free;
    kept.Free;
    prefixed.Free;
    xmlnsList.Free;
  end;
end;

{ TWriterXmlite }

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
  if (aFieldInfo.RttiProperty.PropertyType.TypeKind in [tkString, tkLString, tkWString, tkUString]) and not aValue.IsEmpty and
    ((aValue.Chars[0] <= ' ') or (aValue.Chars[aValue.Length - 1] <= ' ')) then
    WriteAttribute('xml:space', 'preserve');
  Write('>');
  AddXmlEscape(aValue);
  AddTagClose(aName);
end;

procedure TWriterXmlite.AddXmlEscape(const aString: string);

  // Check if the character is a high surrogate
  function IsHighSurrogate(aChar: PChar): boolean; inline;
  begin
    Result := (Ord(aChar^) >= $D800) and (Ord(aChar^) <= $DBFF);
  end;

  // Check if the character is a low surrogate
  function IsLowSurrogate(aChar: PChar): boolean; inline;
  begin
    Result := (Ord(aChar^) >= $DC00) and (Ord(aChar^) <= $DFFF);
  end;

  // Combine high and low surrogates into a single Unicode code point
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
      { else // Invalid: high surrogate without a matching low surrogate. Possibly todo: logging. }
    end
    { else if IsLowSurrogate(cursor) then // Invalid: low surrogate without a preceding high surrogate. Possibly todo: logging. }
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

procedure TWriterXmlite.WriteAttribute(const aName, aValue, aPrefix: string);
begin
  if aPrefix.IsEmpty then
    Write(' %s="%s"', [aName, aValue])
  else
    Write(' %s:%s="%s"', [aPrefix, aName, aValue]);
end;

procedure TWriterXmlite.WriteAttributes(aObject: TBasite; aNamespaces: boolean);
begin
  if aNamespaces then
    Write(aObject.GetXmlns); // todo: optimize

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
  fXmlAny.Clear;
  fXmlAttributes.Clear;
  fXmlAttributeNamespaces.Clear;
end;

function TXmlite.IsEmptyOrDefault: boolean;
begin
  // content kept in xs:any or as not described attributes is content as well
  Result := inherited and fXmlText.IsEmpty and (fXmlAny.Count = 0) and (fXmlAttributes.Count = 0);
end;

function TXmlite.HasContent: boolean;
begin
  Result := not fXmlText.IsEmpty or (fXmlAny.Count > 0) or (fXmlAttributes.Count > 0) or inherited;
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

{ TXmliteTextNodeString }

function TXmliteTextNodeString.GetXmlText: string;
begin
  Result := fValue;
end;

procedure TXmliteTextNodeString.SetXmlText(const aValue: string);
begin
  fValue := aValue;
end;

{ TXmliteTextNodeInteger }

function TXmliteTextNodeInteger.GetXmlText: string;
begin
  Result := fValue.ToString;
end;

procedure TXmliteTextNodeInteger.SetXmlText(const aValue: string);
begin
  fValue := StrToIntDef(aValue, 0);
end;

{ TXmliteTextNodeCardinal }

function TXmliteTextNodeCardinal.GetXmlText: string;
begin
  Result := fValue.ToString;
end;

procedure TXmliteTextNodeCardinal.SetXmlText(const aValue: string);
begin
  fValue := Max(StrToIntDef(aValue, 0), 0);
end;

{ TXmliteTextNodeInt64 }

function TXmliteTextNodeInt64.GetXmlText: string;
begin
  Result := fValue.ToString;
end;

procedure TXmliteTextNodeInt64.SetXmlText(const aValue: string);
begin
  fValue := StrToInt64Def(aValue, 0);
end;

{ TXmliteTextElement }

function TXmliteTextElement.IsEmptyOrDefault: boolean;
begin
  Result := xmlText.IsEmpty;
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

  // todo: make an ability to point out filename directly
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
    if TMetaBasite(aMeta).ClassItself.InheritsFrom(TXmliteTextElement) then
      Result := TMetaBasiteXmliteText.Create(TMetaBasite(aMeta))
    else
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

  // global attributes before the classes: a member typed with one belongs to its namespace and is qualified (derived when the
  // member registers - also within this namespace, e.g. wsu:Id in wsu:Timestamp)
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
      ptBasite, ptBasiteList:
        fElements.Add(uriedName, propertyInfo);
    end;
  end;

  fIsTXmlite := Meta.ClassItself.InheritsFrom(TXmlite);
  if not fIsTXmlite then
    Exit;

  // inherited from the parent class. The parent's meta may exist without its extension yet: a class whose content holds
  // its own descendants (XHTML: span in span) registers them while being registered itself - then the attributes of the
  // ancestors give it (reading the missing extension was an access violation)
  var parentXmlite: TMetaBasiteXmlite := aMeta.ClassItself.ClassParent.Meta.Xmlite;
  if parentXmlite <> nil then
    fProcessAnyElement := parentXmlite.ProcessAnyElement
  else
    fProcessAnyElement := HasAnyElementAttribute(aMeta.ClassItself.ClassParent);
  if not fProcessAnyElement then
    fProcessAnyElement := HasAnyElementAttribute(aMeta.ClassItself, False);
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
          if (Meta.ClassItself.InheritsFrom(TXmliteTextElement) and (propertyData.Name = cXmliteTextNodeFieldName)) then
            Continue; // pass xmlText property

          if FieldIsText(propertyData) then
            fTextProperty := propertyData
          else if FieldIsElement(propertyData) then
            fElements.Add(uriedName, propertyData)
          else
            fAttributes.Add(uriedName, propertyData);
        end;

      ptBasite, ptBasiteList:
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

  var fNaming: TNaming := fNamespace.Naming;
  for var attribute: TCustomAttribute in Self.Meta.RttiType.GetAttributes do
    if attribute.ClassType.InheritsFrom(TNamingAttribute) then
    begin
      fNaming := TNamingAttribute(attribute).Naming;
      break;
    end;

  fName := TUtility.FromPascalCase(fName, fNaming);

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

  // a reference to a global declaration (xs:element ref, xs:attribute ref): an element class or an attribute type IS that
  // declaration, so the member belongs to its namespace, and such an attribute is always qualified (XSD) - unlike a local
  // member, which belongs to its owner whatever its type (ord:ShipTo of type cmn:AddressType)
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

{ TMetaBasiteXmliteText }

constructor TMetaBasiteXmliteText.Create(aMeta: TMetaBasite);
begin
  inherited;
  // at initialization the key of property doesn't contain URI, the dictionary is reassembled during Namespace registration
  var textNodeFieldName: TUriedName := TUriedName.Create(cXmliteTextNodeFieldName);
  fXmlTextProperty := fAttributes[textNodeFieldName];
  fAttributes.Remove(textNodeFieldName);
end;

end.
