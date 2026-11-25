unit ProRock.Xmlite;

// XML to objects and back through the metadata of generated classes

interface

uses System.Classes, System.SysUtils, System.StrUtils, System.Generics.Collections, System.Generics.Defaults, System.Rtti, System.Math,
  System.SyncObjs, System.TypInfo,
  ProRock.Basite, ProRock.Xmlite.Utility;

const
  {$REGION 'ProRock.Basite constants aliases'}
  // re-exported: a generated unit's {$IF} sees only the units of its own uses
  cProRockCodeLevel = ProRock.Basite.cProRockCodeLevel;
  {$ENDREGION}

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
  {$REGION 'ProRock.Xmlite.Utility types aliases'}
  TNaming = ProRock.Xmlite.Utility.TNaming;
  TIssueSeverity = ProRock.Xmlite.Utility.TIssueSeverity;
  TIssue = ProRock.Xmlite.Utility.TIssue;
  TIssueEvent = ProRock.Xmlite.Utility.TIssueEvent;
  TIssues = ProRock.Xmlite.Utility.TIssues;
  TNamingAttribute = ProRock.Xmlite.Utility.TNamingAttribute;
  TWriterBase = ProRock.Xmlite.Utility.TWriterBase;
  TXmliteComponentType = ProRock.Xmlite.Utility.TXmliteComponentType;
  TUriedName = ProRock.Xmlite.Utility.TUriedName;
  TXmlns = ProRock.Xmlite.Utility.TXmlns;
  TXmlnsScope = ProRock.Xmlite.Utility.TXmlnsScope;
  TReaderBase = ProRock.Xmlite.Utility.TReaderBase;
  {$ENDREGION}

  {$REGION 'ProRock.Basite types aliases'}
  TBaseTypeAttribute = ProRock.Basite.TBaseTypeAttribute;
  TPlainNumberAttribute = ProRock.Basite.TPlainNumberAttribute;
  TNameAttribute = ProRock.Basite.TNameAttribute;
  TDefaultAttribute = ProRock.Basite.TDefaultAttribute;
  TRequiredAttribute = ProRock.Basite.TRequiredAttribute;
  TChoiceAttribute = ProRock.Basite.TChoiceAttribute;
  TEnumCaptionAttribute = ProRock.Basite.TEnumCaptionAttribute;
  TEnumNamingAttribute = ProRock.Basite.TEnumNamingAttribute;
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

  // an element the schema does not describe, or one whose value does not fit its type, kept as its text, written back after
  // the AfterCount-th item of After (nil: first); Namespaces - the prefixes ('' - default) it takes from its ancestors;
  // Value - the single property it did not fill: once that property is set, this one is not written
  TXmliteUnknown = record
    Xml: string;
    After: TProperty;
    AfterCount: integer;
    Namespaces: TArray<TPair<string, string>>;
    Value: TProperty;
  end;

  TXmliteContentKind = (xckText, xckElement, xckKept);

  // an item of XmlContent: a text run, an element (its object, or a plain value: Element nil, Index in its list) or a kept
  // unknown element (Index in XmlUnknown, Text its name)
  TXmliteContentItem = record
    Kind: TXmliteContentKind;
    Text: string;
    Element: TBasite;
    ElementProperty: TProperty; // nil for xs:any and unknown elements
    Index: integer;
    function IsText: boolean; inline;
    function IsElement<T: TBasite>: boolean; inline;
    // the element as its class, EInvalidCast for another one: item.ElementAs<TAE>.Href
    function ElementAs<T: TBasite>: T; inline;
    // the element's XML name (b, span) from the meta, an unknown element's (its Text); '' for text
    function Name: string;
  end;

  TXmliteNodeKind = TXmliteContentKind deprecated 'use TXmliteContentKind';
  TXmliteNode = TXmliteContentItem deprecated 'use TXmliteContentItem';

const
  xnkText = xckText deprecated 'use xckText';
  xnkElement = xckElement deprecated 'use xckElement';
  xnkUnknown = xckKept deprecated 'use xckKept';

type
  TXmlite = class;

  // XmlContent, read-only: Count, Items (the default), for-in; a view of the object's order, taken when used
  TXmliteContent = record
  public type
    TEnumerator = record
    private
      fOwner: TXmlite;
      fIndex: integer;
      function GetCurrent: TXmliteContentItem; inline;
    public
      function MoveNext: boolean; inline;
      property Current: TXmliteContentItem read GetCurrent;
    end;
  private
    fOwner: TXmlite;
    function GetCount: integer;
    function GetItem(aIndex: integer): TXmliteContentItem; inline;
  public
    function GetEnumerator: TEnumerator; inline;
    property Count: integer read GetCount;
    property Items[aIndex: integer]: TXmliteContentItem read GetItem; default;
  end;

  // how ToXml writes: woPretty indented; woBooleanDigits xs:boolean as 1 and 0, as Office writes it
  TXmliteWriteOption = (woPretty, woBooleanDigits);
  TXmliteWriteOptions = set of TXmliteWriteOption;

  TReaderXmlite = class abstract(TReaderBase)
  public const
    cXmlNameStartChars = ['a' .. 'z', 'A' .. 'Z', '_', ':']; // valid starting characters for XML names
    cXmlNameChars = cXmlNameStartChars + ['0' .. '9', '-', '.']; // valid subsequent characters for XML names
  public
    class procedure DecodeNumericEscapeEntity(var aCursor, aResultCursor: PChar); static; inline;
    class procedure DecodeNamedEscapeEntity(var aCursor, aResultCursor: PChar); static; inline;
    class function ReadUnescapeInPlace(var aCursor: PChar; aStringEndsAt: Char = #0): string; static; inline;
    class function ReadQuotedValueInPlace(var aCursor: PChar): string; static; inline;
    // the text of a document's bytes: the BOM, else UTF-16 by its first characters, else the declaration's encoding, else UTF-8
    class function DecodeXml(const aBytes: TBytes; out aXml: string): boolean; static;
    class function PassDtd(var aCursor: PChar): boolean; static; inline;
    // a comment, CDATA, a processing instruction or a DOCTYPE, passed to its own end (it may hold < and >)
    class function PassMarkup(var aCursor: PChar): boolean; static;
    // an element as its exact text, the buffer not changed; False unless well-formed (nesting, closing, declared prefixes).
    // aNamespaces gets the prefixes ('' - default) it takes from outside, with their URIs
    class function ReadFragment(var aCursor: PChar; aXmlns: TXmlns; out aXml: string;
      aNamespaces: TDictionary<string, string>): boolean; static;

    class function PassNode(var aCursor: PChar; const aNodeName: string): boolean; static; inline;
    // at '<': the end tag of aName passed, compared where it is (no string made); False - another tag, the cursor stays
    class function PassEndTag(var aCursor: PChar; const aName: string): boolean; static;

    class function ReadName(var aCursor: PChar; out aPrefix, aName, aFullName: string; const aCustomEndChars: TSysCharSet = []): boolean;
     static; inline;
    class function ReadTagName(var aCursor: PChar; var aIsEndTag: boolean; out aPrefix, aName, aFullName: string): boolean; overload;
      static; inline;
    class function ReadTagName(var aCursor: PChar; var aIsEndTag: boolean; out aFullName: string): boolean; overload; static; inline;
    class function ReadAttributeName(var aCursor: PChar; out aPrefix, aName, aFullName: string): boolean; static; inline;

    class function ReadTextNodeContents(var aCursor: PChar): string; static; inline;
    // a text-only element, from after its name to after its end: aText ('' for <a/>), aTagEnd after its start tag
    class function ReadValueNode(var aCursor: PChar; const aNodeName: string; out aText: string; out aTagEnd: PChar): boolean; static;
    class function ReadXmlns(aCursor: PChar; aXmlns: TXmlnsScope): boolean; static; inline;
  end;

  TWriterXmlite = class(TWriterBase)
  private
    fPretty: boolean;
    fBooleanDigits: boolean;
    fDeclared: TObjectList<TDictionary<string, string>>; // prefix ('' - default) -> URI declared by the elements open now

    procedure WriteAttribute(const aName, aValue: string; const aPrefix: string = ''); inline;
    procedure WriteAttributes(aObject: TBasite; aNamespaces: boolean = False); inline;
    // the default namespace declared around the current element ('' when none)
    function DefaultInScope: string;
  public
    destructor Destroy; override;

    property Pretty: boolean read fPretty write fPretty;
    property BooleanDigits: boolean read fBooleanDigits write fBooleanDigits;

    // a value's text as written: BooleanDigits applied
    function ValueText(aProperty: TProperty; const aText: string): string; inline;
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

  // a new member takes the Xml prefix: a generated one named like it would get a trailing _ when regenerated
  TXmlite = class(TBasite)
  public
    class function XmlToObject(const aXml: string; aObject: TBasite): boolean;
    class function ObjectToXml(aObject: TBasite): string;

  private
    fXmlPrefix, fXmlName: string;
    // these three created on first access through their properties (most elements have none): Xmlite's own reads
    // use the fields, nil meaning empty - a read through the property would create one for every element
    fXmlAttributes: TDictionary<string, string>;
    fXmlAttributeNamespaces: TDictionary<string, string>;
    fXmlAny: TBasiteList<TBasite>;
    fXmlns: TXmlnsScope;
    fXmlText: string;
    fXmlUnknown: TList<TXmliteUnknown>; // created with the first one
    fXmlBadAttributes: TDictionary<string, TProperty>; // a name in XmlAttributes -> the property it did not fill; with the first one
    fXmlPosition: cardinal;
    fXmlTextEmpty: boolean; // simple content that came empty and does not fit its type: written empty while not present
    // a kept value stands in for this property
    function HasBadValue(aProperty: TProperty): boolean;
    procedure ReadEmptyText;
    function GetXmlUnknown: TList<TXmliteUnknown>;
    function GetXmlAny: TBasiteList<TBasite>;
    function GetXmlAttributes: TDictionary<string, string>;
    function GetXmlAttributeNamespaces: TDictionary<string, string>;
    // nil: empty
    class function CountOf(aMap: TDictionary<string, string>): integer; overload; static; inline;
    class function CountOf(aMap: TDictionary<string, TProperty>): integer; overload; static; inline;
    class function CountOf(aList: TBasiteList<TBasite>): integer; overload; static; inline;
    class function CountOf(aList: TList<TXmliteUnknown>): integer; overload; static; inline;
    function GetXmlContent: TXmliteContent; inline;
    function ContentCount: integer; inline;
    function ContentItem(aIndex: integer): TXmliteContentItem;
    function GetXmlText: string;
    function GetXmlnsInScope: TXmlns;
    procedure SetXmlText(const aValue: string);
    // an item at the end of the order; text joins a text item before it (text, CDATA, text)
    procedure AddContent(aKind: TXmliteContentKind; const aText: string; aElement: TBasite; aProperty: TProperty; aIndex: integer);
    function PropertyOfClass(aClass: TClass; const aName: string = ''): TProperty;
    function AddElement(aClass: TClass; const aProperty: string): TBasite;
    // a kept element for this copy: False when its anchors are not this class's
    function KeptCopy(const aUnknown: TXmliteUnknown; out aCopy: TXmliteUnknown): boolean;
  private const
    // the order's own kinds (TBasiteOrderItem.Format): a text run, a kept element (Index in XmlUnknown, Text its name)
    cOrderText = 1;
    cOrderKept = 2;
  protected
    procedure Deinitialize; override;
    // xs:any by its place in XmlAny, a kept element by its place in XmlUnknown (both copied before)
    function CopyOrderItem(aSource: TBasite; var aItem: TBasiteOrderItem): boolean; override;
    // with the properties: the name, attributes, declarations, text, xs:any, kept elements and values, the order; not
    // XmlPosition (a copy was not read). From another class only what names its properties too
    procedure CopyFrom(aSource: TBasite; aCommon: TMetaBasite); override;

    procedure DoBeforeSerialization; virtual;
    procedure DoAfterSerialization; virtual;
    procedure DoBeforeParsing; virtual;
    procedure DoAfterParsing; virtual;
  public
    // the namespaces in scope here (prefix -> URI), for prefixed values (QNames); shared with the elements inside that
    // declare none, so read it, don't change it
    property Xmlns: TXmlns read GetXmlnsInScope;

    property XmlPrefix: string read fXmlPrefix write fXmlPrefix;
    property XmlName: string read fXmlName write fXmlName;
    property XmlAny: TBasiteList<TBasite> read GetXmlAny;
    // the element's place in the document it was read from (0 - not read)
    property XmlPosition: cardinal read fXmlPosition;
    property XmlAttributes: TDictionary<string, string> read GetXmlAttributes; // attributes without a property, kept for the round trip
    // elements without a property, kept for the round trip as their text (Clear removes them)
    property XmlUnknown: TList<TXmliteUnknown> read GetXmlUnknown;
    // [TOrdered]/[TMixed]: the children (and text) in document order, written so; children not in it come after. A child
    // removed (Remove, or through its list: Delete, Extract, Clear) leaves it too. Read-only: Add<T>, AddText, Remove change it
    property XmlContent: TXmliteContent read GetXmlContent;
    // the text before the first child element; in mixed content the leading text item of XmlContent
    property XmlText: string read GetXmlText write SetXmlText;
    // prefix -> URI declared again on write: the document's declarations (prefixes appear in values: mc:Ignorable)
    property XmlAttributeNamespaces: TDictionary<string, string> read GetXmlAttributeNamespaces;

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
    // with the properties: the name, attributes, declarations, text, xs:any, kept elements and values, the order
    function SameAs(aOther: TBasite): boolean; override;
  end;

  // an object of a class known only at run time: aClass.Create (the constructor is virtual)
  TXmliteClass = class of TXmlite;

  TXmliteList<T: TXmlite, constructor> = class(TBasiteList<T>);
  // a list of plain values: TXstringSTList = class(TXmliteValueList<TXstringST>) - Authors.Author.Add('Ann')
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
    // not a class var: one in this helper crashes the compiler on a direct TBasite descendant in a build with debug info
    class function GetPretty: boolean; static;
    class procedure SetPretty(aValue: boolean); static;
  public
    class property Pretty: boolean read GetPretty write SetPretty;

  private
    function TagType: TTagType;
    // written when present, or required - unless a kept value that did not fit its type stands in for it
    function ValueIsWritten(aProperty: TProperty): boolean;
    // required and written although not present: built in code (a forgotten value shows); a read object writes what it read
    function WritesRequired(aProperty: TProperty): boolean; inline;

    function ReadTagContents(var aCursor: PChar; const aName: string; aXmlns: TXmlnsScope): boolean;
    function ReadInPlace(var aXml: string; aIssues: PIssues; const aSource: string = ''): boolean;

    function FromXml(var aXmlCursor: PChar; aXmlns: TXmlnsScope = nil): boolean; overload;
    // aScope: the default namespace in scope; aNamespaces: the element declares its namespaces (a root)
    procedure ToXml(aWriter: TWriterXmlite; const aName: string; aScope: TNamespace; aNamespaces: boolean;
      aXmlHeader: boolean = False); overload;
  public
    constructor CreateFromXml(const aXml: string);

    // the namespace declarations a root writes; aDeclared, when given, gets them (prefix, '' - default -> URI)
    // (overloads: a default parameter of a generic type here crashes Delphi 10.3 on a direct TBasite descendant, URW1237)
    function GetXmlns: string; overload;
    function GetXmlns(aDeclared: TDictionary<string, string>): string; overload;

    // indented or compact as Pretty says; the overloads with aOptions decide per call, whatever Pretty says ([] - compact)
    procedure ToXml(aStream: TStream; const aName: string = ''; aXmlHeader: boolean = True); overload;
    procedure ToXml(aStream: TStream; aOptions: TXmliteWriteOptions; const aName: string = ''; aXmlHeader: boolean = True);
      overload;
    function ToXml(const aName: string = ''; aXmlHeader: boolean = True): string; overload;
    function ToXml(aOptions: TXmliteWriteOptions; const aName: string = ''; aXmlHeader: boolean = True): string; overload;
    // reads a copy: aXml stays as it is
    function FromXml(const aXml: string): boolean; overload;
    // reads without a copy - aXml is changed by the read (large documents read once)
    function FromXmlInPlace(var aXml: string): boolean; overload;
    // a file or bytes in their encoding: the BOM (UTF-8, UTF-16), else the declaration's encoding="", else UTF-8. False also
    // when the encoding is unknown or the bytes do not fit it
    function FromXmlFile(const aFileName: string): boolean; overload;
    function FromXmlBytes(const aXml: TBytes): boolean; overload;
    // the same, and aIssues gets why a read answered False, values kept that do not fit their type, content not in the
    // schema (once a name); added to what aIssues holds. These answer instead of raising: a file not read is False too
    function FromXml(const aXml: string; var aIssues: TIssues): boolean; overload;
    function FromXmlInPlace(var aXml: string; var aIssues: TIssues): boolean; overload;
    function FromXmlFile(const aFileName: string; var aIssues: TIssues): boolean; overload;
    function FromXmlBytes(const aXml: TBytes; var aIssues: TIssues): boolean; overload;
    // UTF-8 without a BOM, as the declaration says
    procedure ToXmlFile(const aFileName: string; const aName: string = ''); overload;
    procedure ToXmlFile(const aFileName: string; aOptions: TXmliteWriteOptions; const aName: string = ''); overload;
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
    fSameName: TDictionary<TProperty, TProperty>; // the next element of the same XML name; nil while no name is declared twice
    fTextProperty: TPropertyData;

    procedure RegisterElement(const aName: TUriedName; aProperty: TProperty);
    function FieldIsElement(aField: TProperty): boolean; inline;
    function FieldIsText(aField: TProperty): boolean; inline;
    function GetMeta: TMetaBasite;
    function GetProcessAnyAttribute: boolean;
    function GetProcessAnyElement: boolean;
    procedure SetMixed(aValue: boolean);
    procedure BindMembers;
  protected
    procedure NamespaceUnregister; override;
    procedure NamespaceRegister(aNamespace: TNamespace; aType: TXmliteComponentType); override;
  public
    constructor Create(aMeta: TMetaBasite); reintroduce; virtual;
    destructor Destroy; override;

    property Meta: TMetaBasite read GetMeta;
    property Attributes: TDictObjectList<TUriedName, TPropertyData> read fAttributes;
    // in class order; a name declared twice gives the first
    property Elements: TDictObjectList<TUriedName, TProperty> read fElements;
    // aFirst or another of its name: the first at or after aLast, the element read before, not read yet; by position, branches unknown
    function ElementOfName(aFirst, aLast: TProperty; aObject: TBasite): TProperty;
    // by URI and name (an empty URI: unqualified); nil - the class has none
    function Element(const aUri, aName: string): TProperty;
    function Attribute(const aUri, aName: string): TPropertyData;
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
    fNaming, fMemberNaming, fItemNaming: TNaming;
    fExactNames: boolean; // registered with members' and items' naming: FromPascalCaseExact (older units rely on B meaning <B>)
    fSimpleTypes, fAttributes: TDictObjectList<string, TMetaType>;
    fComplexTypes, fAttributeGroups, fElements, fElementGroups: TDictObjectList<string, TMetaBasite>;
  public
    constructor Create(const aUri, aPrefix: string; aNaming: TNaming; const aSuffixSimpleType, aSuffixComplexType, aSuffixAttribute,
      aSuffixAttributeGroup, aSuffixElement, aSuffixElementGroup: string);
    destructor Destroy; override;

    property UnitQualifiedName: string read fUnitQualifiedName;
    property Uri: string read fUri;
    property Prefix: string read fPrefix;
    property Naming: TNaming read fNaming; // of the components (types, global elements)
    property MemberNaming: TNaming read fMemberNaming; // of elements and attributes inside them
    property ItemNaming: TNaming read fItemNaming; // of enumeration items

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
    class procedure RegisteredTwice(aNamespace: TNamespace); static;
    class procedure AddComponents(aNamespace: TNamespace; const aSimpleTypes: TArray<PTypeInfo>; const aComplexTypes: TArray<TBasiteClass>;
      const aAttributes: TArray<PTypeInfo>; const aAttributeGroups, aElements, aGroups: TArray<TBasiteClass>);
  public
    class function RegisterNamespace(const aUri: string; const aSimpleTypes: TArray<PTypeInfo>; const aComplexTypes: TArray<TBasiteClass>;
      const aAttributes: TArray<PTypeInfo>; const aAttributeGroups, aElements, aGroups: TArray<TBasiteClass>; const aPrefix: string;
      aNaming: TNaming = cDefaultNaming; const aSuffixSimpleType: string = cDefaultSuffixSimpleType;
      const aSuffixComplexType: string = cDefaultSuffixComplexType; const aSuffixAttribute: string = cDefaultSuffixAttribute;
      const aSuffixAttributeGroup: string = cDefaultSuffixAttributeGroup; const aSuffixElement: string = cDefaultSuffixElement;
      const aSuffixElementGroup: string = cDefaultSuffixElementGroup): TNamespace; overload;
    // members and enumeration items are often named differently from the types, but the same across a schema
    class function RegisterNamespace(const aUri: string; const aSimpleTypes: TArray<PTypeInfo>; const aComplexTypes: TArray<TBasiteClass>;
      const aAttributes: TArray<PTypeInfo>; const aAttributeGroups, aElements, aGroups: TArray<TBasiteClass>; const aPrefix: string;
      aNaming, aMemberNaming, aItemNaming: TNaming): TNamespace; overload;

  private
    fNamespaces: TNamespaceList;
    // a type not registered yet -> the classes of its unit with a member of it: bound again when it registers
    fPending: TObjectDictionary<TMeta, TList<TMetaBasite>>;

    procedure AddPending(aType: TMeta; aOwner: TMetaBasite);
    procedure BindPending(aType: TMeta);
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

uses System.IniFiles, System.Variants, System.IOUtils;

type
  // what the read in progress on this thread reports to, and where its text starts (for a line and column)
  TReadIssues = record
    Issues: PIssues;
    Source: string; // a file name, before the line
    Start: PChar;
    Failed: boolean; // the first failure is reported: the innermost, where the read stopped
    Named: THashSet<string>; // what is reported once a read: code + key
    // where the lines were counted to: counted on from there, as a read moves forward
    LineCursor, LineStart: PChar;
    Line: integer;
  end;
  PReadIssues = ^TReadIssues;

  // TUriedName's layout, its strings not owned: a key for one lookup without counting references (the caller holds them)
  TUriedNameView = record
    Uri, Name: Pointer;
  end;
  PUriedName = ^TUriedName;

// the read order of elements (TXmlite.XmlPosition): one counter per thread, so parsing in several threads needs no lock
threadvar
  gXmlReadPosition: cardinal;
  gReadIssues: PReadIssues; // nil: no issues asked for

// line 3, column 20 - in the text as the parser left it: a &#10; unescaped before aCursor moves it by a line
function ReadPlace(aContext: PReadIssues; aCursor: PChar): string;
begin
  if aCursor < aContext.LineCursor then
  begin
    aContext.LineCursor := aContext.Start;
    aContext.LineStart := aContext.Start;
    aContext.Line := 1;
  end;
  while aContext.LineCursor < aCursor do
  begin
    if aContext.LineCursor^ = #10 then
    begin
      Inc(aContext.Line);
      aContext.LineStart := aContext.LineCursor + 1;
    end;
    Inc(aContext.LineCursor);
  end;
  Result := Format('line %d, column %d', [aContext.Line, aCursor - aContext.LineStart + 1]);
  if not aContext.Source.IsEmpty then
    Result := aContext.Source + ', ' + Result;
end;

// False, for Exit(ReadFailed(...))
function ReadFailed(aCursor: PChar; const aMessage: string): boolean;
begin
  Result := False;
  var context: PReadIssues := gReadIssues;
  if (context = nil) or context.Failed then
    Exit;
  context.Failed := True;
  context.Issues.Add(TIssueSeverity.isError, 'Malformed', ReadPlace(context, aCursor), aMessage);
end;

// aKey (an element and a name in it): reported once a read under aCode; '' - every time
procedure ReadReport(aCursor: PChar; aSeverity: TIssueSeverity; const aCode, aKey, aMessage: string);
begin
  var context: PReadIssues := gReadIssues;
  if context = nil then
    Exit;
  if not aKey.IsEmpty then
  begin
    if context.Named = nil then
      context.Named := THashSet<string>.Create;
    if context.Named.Contains(aCode + ' ' + aKey) then
      Exit;
    context.Named.Add(aCode + ' ' + aKey);
  end;
  context.Issues.Add(aSeverity, aCode, ReadPlace(context, aCursor), aMessage);
end;

function Quoted(const aValue: string): string;
const
  cLength = 40;
begin
  if aValue.Length > cLength then
    Result := '"' + aValue.Substring(0, cLength) + '..."'
  else
    Result := '"' + aValue + '"';
end;

{ TBasiteHelper }

constructor TBasiteHelper.CreateFromXml(const aXml: string);
begin
  inherited Create;
  FromXml(aXml);
end;

function TBasiteHelper.FromXmlFile(const aFileName: string): boolean;
begin
  Result := FromXmlBytes(TFile.ReadAllBytes(aFileName));
end;

function TBasiteHelper.FromXmlBytes(const aXml: TBytes): boolean;
begin
  var xml: string;
  Result := TReaderXmlite.DecodeXml(aXml, xml) and ReadInPlace(xml, nil);
end;

function TBasiteHelper.FromXml(const aXml: string; var aIssues: TIssues): boolean;
begin
  var xml: string := aXml;
  Result := ReadInPlace(xml, @aIssues);
end;

function TBasiteHelper.FromXmlInPlace(var aXml: string; var aIssues: TIssues): boolean;
begin
  Result := ReadInPlace(aXml, @aIssues);
end;

function DecodeXml(const aBytes: TBytes; out aXml: string; var aIssues: TIssues; const aSource: string): boolean;
begin
  Result := TReaderXmlite.DecodeXml(aBytes, aXml);
  if not Result then
    aIssues.Add(TIssueSeverity.isError, 'Encoding', aSource, 'the encoding is unknown, or the bytes do not fit it');
end;

function TBasiteHelper.FromXmlBytes(const aXml: TBytes; var aIssues: TIssues): boolean;
begin
  var xml: string;
  Result := DecodeXml(aXml, xml, aIssues, '') and ReadInPlace(xml, @aIssues);
end;

function TBasiteHelper.FromXmlFile(const aFileName: string; var aIssues: TIssues): boolean;
begin
  var bytes: TBytes;
  try
    bytes := TFile.ReadAllBytes(aFileName);
  except
    on e: Exception do
    begin
      // 10.3 - 10.4: EFileNotFoundException and its kin are no EInOutError yet
      if not (e.InheritsFrom(EStreamError) or e.InheritsFrom(EInOutError) or e.InheritsFrom(EOSError) or
        e.InheritsFrom(EFileNotFoundException) or e.InheritsFrom(EDirectoryNotFoundException) or
        e.InheritsFrom(EPathTooLongException)) then
        raise;
      aIssues.Add(TIssueSeverity.isError, 'File', aFileName, e.Message);
      Exit(False);
    end;
  end;
  var xml: string;
  Result := DecodeXml(bytes, xml, aIssues, aFileName) and ReadInPlace(xml, @aIssues, aFileName);
end;

procedure TBasiteHelper.ToXmlFile(const aFileName: string; const aName: string);
begin
  TFile.WriteAllBytes(aFileName, TEncoding.UTF8.GetBytes(ToXml(aName)));
end;

procedure TBasiteHelper.ToXmlFile(const aFileName: string; aOptions: TXmliteWriteOptions; const aName: string);
begin
  TFile.WriteAllBytes(aFileName, TEncoding.UTF8.GetBytes(ToXml(aOptions, aName)));
end;

function TBasiteHelper.FromXml(const aXml: string): boolean;
begin
  var xml: string := aXml;
  Result := ReadInPlace(xml, nil);
end;

// XML 1.0, 2.11: a raw CRLF or CR is a line feed before anything is read; a reference (&#xD;) stays a carriage return
procedure NormalizeLineEnds(var aXml: string);
begin
  var first: integer := Pos(#13, aXml);
  if first = 0 then
    Exit;
  var source: PChar := PChar(aXml) + first - 1;
  var target: PChar := source;
  var stop: PChar := PChar(aXml) + aXml.Length;
  while source < stop do
  begin
    if source^ = #13 then
    begin
      target^ := #10;
      if source[1] = #10 then
        Inc(source);
    end
    else
      target^ := source^;
    Inc(source);
    Inc(target);
  end;
  SetLength(aXml, target - PChar(aXml));
end;

function TBasiteHelper.FromXmlInPlace(var aXml: string): boolean;
begin
  Result := ReadInPlace(aXml, nil);
end;

function TBasiteHelper.ReadInPlace(var aXml: string; aIssues: PIssues; const aSource: string): boolean;
begin
  // the parser writes into the text: a shared string gets its own copy first, so only aXml changes
  UniqueString(aXml);
  NormalizeLineEnds(aXml);
  var xmlCursor: PChar := PChar(aXml);

  // a read inside a read (an OnIssue handler's) reports to its own list, or to none
  var outer: PReadIssues := gReadIssues;
  var context: TReadIssues;
  context.Named := nil;
  if aIssues = nil then
    gReadIssues := nil
  else
  begin
    context.Issues := aIssues;
    context.Source := aSource;
    context.Start := xmlCursor;
    context.Failed := False;
    context.LineCursor := xmlCursor;
    context.LineStart := xmlCursor;
    context.Line := 1;
    gReadIssues := @context;
  end;
  try
    if not TReaderXmlite.MoveToChar(xmlCursor, '<') then
      Exit(ReadFailed(xmlCursor, 'no element: the text holds no XML'));

    // declaration
    while (xmlCursor^ = '<') and (xmlCursor[1] = '?') do
    begin
      var declaration: PChar := xmlCursor;
      Inc(xmlCursor, 2);
      while xmlCursor[1] <> '>' do
        if not TReaderXmlite.MoveToChar(xmlCursor, '?') then
          Exit(ReadFailed(declaration, '<? is not closed by ?>'));

      if not TReaderXmlite.MoveToChar(xmlCursor, '<') then
        Exit(ReadFailed(xmlCursor, 'no element after the XML declaration'));
    end;

    Clear;

    Result := FromXml(xmlCursor);
    if not Result then
      ReadFailed(xmlCursor, 'not well-formed XML'); // a failure not described where it happened
  finally
    gReadIssues := outer;
    context.Named.Free;
  end;
end;

// a quick check before reading declarations; a false positive costs only the full read
function TagDeclaresXmlns(aCursor: PChar): boolean;
begin
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

// the scope a tag reads in: its parent's, shared, when it declares nothing; else a new one with its declarations (False:
// the start tag is not well-formed)
function TagScope(aTagStart: PChar; aParent: TXmlnsScope; out aScope: TXmlnsScope): boolean;
begin
  if (aParent <> nil) and not TagDeclaresXmlns(aTagStart) then
  begin
    aScope := aParent.Share;
    Exit(True);
  end;
  if aParent = nil then
    aScope := TXmlnsScope.Create
  else
    aScope := TXmlnsScope.Create(aParent);
  Result := TReaderXmlite.ReadXmlns(aTagStart, aScope);
end;

function TBasiteHelper.FromXml(var aXmlCursor: PChar; aXmlns: TXmlnsScope): boolean;
const
  cWhitespaces = [#32, #9, #$A, #$D];
begin
  Result := False;

  if Meta.Xmlite.IsTXmlite then
    TXmlite(Self).DoBeforeParsing;

  if not TReaderXmlite.MoveToChar(aXmlCursor, '<') then
    Exit(ReadFailed(aXmlCursor, 'an element expected'));

  // pass the DOCTYPE, comments, processing instructions
  while (aXmlCursor[1] = '!') or (aXmlCursor[1] = '?') do
  begin
    var markup: PChar := aXmlCursor;
    if not TReaderXmlite.PassMarkup(aXmlCursor) or not TReaderXmlite.MoveToChar(aXmlCursor, '<') then
      Exit(ReadFailed(markup, 'a DOCTYPE, comment or processing instruction not closed, or no element after it'));
  end;

  var xmlns: TXmlnsScope;
  var wellFormed: boolean := TagScope(aXmlCursor, aXmlns, xmlns);

  if Meta.Xmlite.IsTXmlite then
  begin
    TXmlite(Self).fXmlns.Release;
    TXmlite(Self).fXmlns := xmlns;
    Inc(gXmlReadPosition);
    TXmlite(Self).fXmlPosition := gXmlReadPosition;
  end;

  try
    var tagStart: PChar := aXmlCursor;
    if not wellFormed then
      Exit(ReadFailed(tagStart, 'the start tag is not well-formed'));

    var isEndTag: boolean;
    var objectName, name, prefix: string;
    if not TReaderXmlite.ReadTagName(aXmlCursor, isEndTag, prefix, name, objectName) then
      Exit(ReadFailed(tagStart, 'a start tag expected'));

    if CharInSet(aXmlCursor^, cWhitespaces) then
      // attributes
      while TReaderXmlite.MoveToVisualChar(aXmlCursor) and not CharInSet(aXmlCursor^, ['/', '>']) do
      begin
        var attributeStart: PChar := aXmlCursor;
        var attributePrefix, attributeName, attributeFullName, attributeValue: string;
        if not TReaderXmlite.ReadAttributeName(aXmlCursor, attributePrefix, attributeName, attributeFullName) then
          Exit(ReadFailed(attributeStart, 'an attribute of <' + objectName + '> is not well-formed'));

        attributeValue := TReaderXmlite.ReadQuotedValueInPlace(aXmlCursor);

        var uri: string;
        if attributePrefix.IsEmpty and Assigned(Meta.Xmlite.Namespace) then
          // for unprefixed attributes parent's URI is used, as attributes do not inherit the default xmlns
          uri := Meta.Xmlite.Namespace.Uri
        else
          uri := xmlns[attributePrefix];

        var propertyData: TPropertyData := Meta.Xmlite.Attribute(uri, attributeName);
        if propertyData = nil then
          propertyData := Meta.Xmlite.Attribute('', attributeName);
        if (propertyData <> nil) and propertyData.TrySetValue(Self, attributeValue) then
          Continue;

        if Meta.Xmlite.IsTXmlite and (attributePrefix = 'xmlns') and (propertyData = nil) then
          TXmlite(Self).XmlAttributeNamespaces.AddOrSetValue(attributeName, attributeValue)
        else if Meta.Xmlite.IsTXmlite then
          if (attributePrefix <> 'xmlns') and (not attributePrefix.IsEmpty or (attributeName <> 'xmlns')) then // pass xmlns stuff
          begin
            TXmlite(Self).XmlAttributes.AddOrSetValue(attributeFullName, attributeValue);
            if propertyData <> nil then // does not fit its type: kept as it came
            begin
              if TXmlite(Self).fXmlBadAttributes = nil then
                TXmlite(Self).fXmlBadAttributes := TDictionary<string, TProperty>.Create;
              TXmlite(Self).fXmlBadAttributes.AddOrSetValue(attributeFullName, propertyData);
              ReadReport(attributeStart, TIssueSeverity.isWarning, 'BadValue', '',
                Format('%s=%s of <%s> does not fit its type: kept as read', [attributeFullName, Quoted(attributeValue), objectName]));
            end
            else if uri <> TUtility.cXsiUri then
              ReadReport(attributeStart, TIssueSeverity.isHint, 'UnknownAttribute', objectName + ' ' + attributeFullName,
                Format('%s of <%s> is not in the schema: kept as read', [attributeFullName, objectName]));
            // its prefix, and for xsi:type the value's (dcterms:W3CDTF) - declared again on write
            if not attributePrefix.IsEmpty and not uri.IsEmpty then
              TXmlite(Self).XmlAttributeNamespaces.AddOrSetValue(attributePrefix, uri);
            if (uri = TUtility.cXsiUri) and (attributeName = 'type') and (attributeValue.IndexOf(':') > 0) then
            begin
              // declared prefixes only: xmlns[] falls back to the default namespace, for a value that is no QName too
              var valuePrefix: string := attributeValue.Substring(0, attributeValue.IndexOf(':'));
              var valueUri: string;
              if xmlns.TryGetValue(valuePrefix, valueUri) and not valueUri.IsEmpty then
                TXmlite(Self).XmlAttributeNamespaces.AddOrSetValue(valuePrefix, valueUri);
            end;
          end;
      end
    else if not TReaderXmlite.MoveToVisualChar(aXmlCursor) then
      Exit(ReadFailed(tagStart, 'the text ends inside <' + objectName + '>'));

    if (aXmlCursor^ = '/') and (aXmlCursor[1] = '>') then
    begin // empty tag
      Inc(aXmlCursor, 2);
      if Meta.Xmlite.IsTXmlite then
        TXmlite(Self).ReadEmptyText;
      Result := True;
    end
    else if aXmlCursor^ = '>' then
    begin // start tag
      Inc(aXmlCursor);

      var textProperty: TPropertyData := Meta.Xmlite.TextProperty;
      if Assigned(textProperty) then
      begin // simpleContent: the text is the value - whitespace included; it may open with CDATA, a comment or a PI
        var text: string := '';
        if (aXmlCursor^ <> '<') or (aXmlCursor[1] = '!') or (aXmlCursor[1] = '?') then
          text := TReaderXmlite.ReadUnescapeInPlace(aXmlCursor, '<');
        if not text.IsEmpty then
        begin
          if not textProperty.TrySetValue(Self, text) and Meta.Xmlite.IsTXmlite then
          begin
            TXmlite(Self).fXmlText := text; // does not fit its type: kept as it came, written while the property is not present
            ReadReport(tagStart, TIssueSeverity.isWarning, 'BadValue', '', Format('the text %s of <%s> does not fit its type: kept as read',
              [Quoted(text), objectName]));
          end;
        end
        else if Meta.Xmlite.IsTXmlite then
          TXmlite(Self).ReadEmptyText;
        if aXmlCursor^ = #0 then
          Exit(ReadFailed(tagStart, 'the text ends before </' + objectName + '>'));
      end
      else if not Meta.Xmlite.Mixed then // mixed content: every text run read in ReadTagContents, whitespace included
      begin
        if not TReaderXmlite.MoveToVisualChar(aXmlCursor) then
          Exit(ReadFailed(tagStart, 'the text ends before </' + objectName + '>'));

        // CDATA, a comment or a PI may come first; only whitespace around a comment before the first child is no text
        if Meta.Xmlite.IsTXmlite and ((aXmlCursor^ <> '<') or (aXmlCursor[1] = '!') or (aXmlCursor[1] = '?')) then
        begin
          var text: string := TReaderXmlite.ReadUnescapeInPlace(aXmlCursor, '<');
          if not text.Trim.IsEmpty then
            TXmlite(Self).fXmlText := text;
        end;
      end;

      // malformed content fails the read; the object keeps what was read up to there
      Result := ReadTagContents(aXmlCursor, objectName, xmlns);
    end
    else if aXmlCursor^ = #0 then
      ReadFailed(tagStart, 'the text ends inside <' + objectName + '>')
    else
      ReadFailed(aXmlCursor, '> or /> expected in <' + objectName + '>');

  finally
    if not Meta.Xmlite.IsTXmlite then
      xmlns.Release;
  end;

  if Meta.Xmlite.IsTXmlite then
    TXmlite(Self).DoAfterParsing;
end;

// URI of a tag name: the tag's own xmlns declarations first, then the ones of its context
function TagUri(aTagStart: PChar; const aPrefix: string; aXmlns: TXmlns): string;

begin
  if TagDeclaresXmlns(aTagStart) then
  begin
    var tagXmlns: TXmlnsScope := TXmlnsScope.Create;
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
      tagXmlns.Release;
    end;
  end;

  Result := aXmlns[aPrefix];
end;

function TBasiteHelper.ReadTagContents(var aCursor: PChar; const aName: string; aXmlns: TXmlnsScope): boolean;

  // an element at aFragment kept as its text, passed - a well-formed one only
  function KeepFragment(var aFragment: PChar; const aTagFullName: string; aAfter: TProperty; aAfterCount: integer;
    aValue: TProperty): boolean;
  begin
    var namespaces: TDictionary<string, string> := TDictionary<string, string>.Create;
    try
      var unknown: TXmliteUnknown;
      Result := TReaderXmlite.ReadFragment(aFragment, aXmlns, unknown.Xml, namespaces);
      if not Result then
        Exit;
      unknown.After := aAfter;
      unknown.AfterCount := aAfterCount;
      unknown.Namespaces := namespaces.ToArray;
      unknown.Value := aValue;
      TXmlite(Self).XmlUnknown.Add(unknown);
      if Meta.Xmlite.Ordered then
        TXmlite(Self).AddContent(xckKept, aTagFullName, nil, nil, TXmlite(Self).XmlUnknown.Count - 1);
    finally
      namespaces.Free;
    end;
  end;

  // an element whose value does not fit its property's type; the read changed its text in the buffer, not its start tag
  function KeepBadValue(aStart, aTagEnd: PChar; const aText, aTagFullName: string; aProperty: TProperty; aAfterCount: integer): boolean;
  begin
    if not Meta.Xmlite.IsTXmlite then
      Exit(True);
    var xml: string;
    SetString(xml, aStart, aTagEnd - aStart);
    if aTagEnd[-2] <> '/' then
      xml := xml + aText.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace(#13, '&#x0D;') +
        '</' + aTagFullName + '>';
    var fragment: PChar := PChar(xml);
    var value: TProperty := nil;
    if aProperty.PropertyType = ptData then
      value := aProperty;
    Result := KeepFragment(fragment, aTagFullName, aProperty, aAfterCount, value);
  end;

begin
  Result := False;

  // the element read last: an unknown one after it is written back after it
  var lastProperty: TProperty := nil;
  var lastCount: integer := 0;

  // the children's order kept (XmlContent); mixed content's text too
  var ordered: boolean := Meta.Xmlite.IsTXmlite and Meta.Xmlite.Ordered;
  var mixed: boolean := ordered and Meta.Xmlite.Mixed;

  while not Result do
  begin
    if mixed then
    begin // the text up to the next tag, whitespace included - CDATA as text, comments and processing instructions passed
      var text: string := TReaderXmlite.ReadUnescapeInPlace(aCursor, '<');
      if aCursor^ = #0 then
        Exit(ReadFailed(aCursor, 'the text ends before </' + aName + '>'));
      if not text.IsEmpty then
        TXmlite(Self).AddContent(xckText, text, nil, nil, 0);
    end;

    if not TReaderXmlite.MoveToChar(aCursor, '<') then
      Exit(ReadFailed(aCursor, 'the text ends before </' + aName + '>'));

    // pass comments, CDATA and processing instructions between elements (mixed content's text is not kept)
    while (aCursor[1] = '!') or (aCursor[1] = '?') do
    begin
      var markup: PChar := aCursor;
      if not TReaderXmlite.PassMarkup(aCursor) or not TReaderXmlite.MoveToChar(aCursor, '<') then
        Exit(ReadFailed(markup, 'a comment, CDATA or processing instruction not closed, or the text ends before </' + aName +
          '>'));
    end;

    if (aCursor[1] = '/') and TReaderXmlite.PassEndTag(aCursor, aName) then
      Exit(True);
    var cursorStart: PChar := aCursor;
    var isEndTag: boolean;
    var tagFullName, tagName, tagPrefix: string;
    if not TReaderXmlite.ReadTagName(aCursor, isEndTag, tagPrefix, tagName, tagFullName) then
      Exit(ReadFailed(cursorStart, 'a tag expected in <' + aName + '>'));

    if isEndTag then
      if tagFullName = aName then
        Exit(True)
      else
        Exit(ReadFailed(cursorStart, Format('</%s> expected, </%s> found', [aName, tagFullName])));

    // xmlns declared on the tag itself applies to the tag's own name too (e.g. <AddResponse xmlns="http://tempuri.org/">)
    var elementUri: string := TagUri(cursorStart, tagPrefix, aXmlns);

    // get a property for property defined name, following prefix/uri
    var propertyElement: TProperty := Meta.Xmlite.Element(elementUri, tagName);

    // an unqualified local element (SOAP 1.1 faultcode) belongs to its parent's type, as an unprefixed attribute does
    if (propertyElement = nil) and elementUri.IsEmpty and Assigned(Meta.Xmlite.Namespace) then
      propertyElement := Meta.Xmlite.Element(Meta.Xmlite.Namespace.Uri, tagName);


    if (propertyElement = nil) and Meta.Xmlite.ProcessAnyElement then
    begin // for xs:any - try to find Namespace-registered element and parse it
      var metaElement: TMetaBasite := TMetaBank.Xmlite.Namespaces.GetMetaBasite(elementUri, TXmliteComponentType.xctElement, tagName);
      if Assigned(metaElement) then
      begin
        var element: TBasite := metaElement.ClassItself.Create;
        aCursor := cursorStart;
        if element.FromXml(aCursor, aXmlns) then
        begin
          TXmlite(Self).XmlAny.Add(element);
          if ordered then
            TXmlite(Self).AddContent(xckElement, '', element, nil, 0);
          Continue;
        end
        else
          element.Free;
      end;
    end;

    if propertyElement = nil then // as a fallback - try to find such property without tag
      propertyElement := Meta.Xmlite.Element('', tagName);

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
      if not KeepFragment(aCursor, tagFullName, lastProperty, lastCount, nil) then
        Exit(ReadFailed(cursorStart, '<' + tagFullName + '> is not well-formed'));
      ReadReport(cursorStart, TIssueSeverity.isHint, 'UnknownElement', aName + ' ' + tagFullName,
        Format('<%s> in <%s> is not in the schema: kept as read', [tagFullName, aName]));
    end
    else if propertyElement = nil then
    begin // no such name in elements list of the object - skip the whole node till it's end
      Inc(aCursor);
      if not TReaderXmlite.PassNode(aCursor, tagFullName) then
        Exit(ReadFailed(cursorStart, '<' + tagFullName + '> is not well-formed'));
      ReadReport(cursorStart, TIssueSeverity.isWarning, 'Skipped', aName + ' ' + tagFullName,
        Format('<%s> in <%s> is not in the schema: skipped', [tagFullName, aName]));
    end
    else
    begin
      propertyElement := Meta.Xmlite.ElementOfName(propertyElement, lastProperty, Self);
      if (propertyElement.PropertyType in [ptData, ptBasite]) and Meta.Xmlite.IsTXmlite and IsPresent(propertyElement) then
      begin // a single element that came again (the schema has it once): kept as its text, not read over the first
        aCursor := cursorStart;
        if not KeepFragment(aCursor, tagFullName, lastProperty, lastCount, nil) then
          Exit(ReadFailed(cursorStart, '<' + tagFullName + '> is not well-formed'));
        ReadReport(cursorStart, TIssueSeverity.isWarning, 'Repeated', '',
          Format('<%s> came again in <%s>, where the schema has it once: kept as read', [tagFullName, aName]));
        Continue;
      end;
      lastProperty := propertyElement;
      lastCount := 1;
      case propertyElement.PropertyType of
        ptData:
          begin
            var text: string;
            var tagEnd: PChar;
            if not TReaderXmlite.ReadValueNode(aCursor, tagFullName, text, tagEnd) then
              Exit(ReadFailed(cursorStart, '<' + tagFullName + '> is not well-formed'));
            if not TPropertyData(propertyElement).TrySetValue(Self, text) then
            begin
              if not KeepBadValue(cursorStart, tagEnd, text, tagFullName, propertyElement, 1) then
                Exit(ReadFailed(cursorStart, '<' + tagFullName + '> is not well-formed'));
              ReadReport(cursorStart, TIssueSeverity.isWarning, 'BadValue', '', Format('<%s>%s does not fit its type: kept as read',
                [tagFullName, Quoted(text)]));
            end
            else if ordered then
              TXmlite(Self).AddContent(xckElement, '', nil, propertyElement, 0);
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
              TXmlite(Self).AddContent(xckElement, '', fieldObject, propertyElement, 0);
            if not read then
              Exit;
          end;
        ptBasiteList:
          begin
            var propertyObjectList: TPropertyBasiteList := TPropertyBasiteList(propertyElement);
            if propertyObjectList.ObjectPointer(Self)^ = nil then
              propertyObjectList.ObjectPointer(Self)^ := propertyObjectList.Meta.CreateList(Self);
            var objectListItem: TBasite := propertyObjectList.Meta.ItemMeta.ClassItself.Create;
            aCursor := cursorStart;
            var read: boolean := objectListItem.FromXml(aCursor, aXmlns);
            propertyObjectList.ObjectPointer(Self).Add(objectListItem); // owned by the list, also when not read whole
            SetPresent(propertyElement);
            lastCount := propertyObjectList.ObjectPointer(Self).Count;
            if ordered then
              TXmlite(Self).AddContent(xckElement, '', objectListItem, propertyElement, lastCount - 1);
            if not read then
              Exit;
          end;
        ptDataList:
          begin
            var text: string;
            var tagEnd: PChar;
            if not TReaderXmlite.ReadValueNode(aCursor, tagFullName, text, tagEnd) then
              Exit(ReadFailed(cursorStart, '<' + tagFullName + '> is not well-formed'));
            var added: boolean := TPropertyDataList(propertyElement).TryAddText(Self, text);
            lastCount := TPropertyDataList(propertyElement).Count(Self);
            if not added then
            begin
              if not KeepBadValue(cursorStart, tagEnd, text, tagFullName, propertyElement, lastCount) then
                Exit(ReadFailed(cursorStart, '<' + tagFullName + '> is not well-formed'));
              ReadReport(cursorStart, TIssueSeverity.isWarning, 'BadValue', '', Format('<%s>%s does not fit its type: kept as read',
                [tagFullName, Quoted(text)]));
            end
            else if ordered then
              TXmlite(Self).AddContent(xckElement, '', nil, propertyElement, lastCount - 1);
          end;
      end;
    end;
  end;
end;

function TBasiteHelper.ValueIsWritten(aProperty: TProperty): boolean;
begin
  Result := IsPresent(aProperty) or (WritesRequired(aProperty) and not (Meta.Xmlite.IsTXmlite and TXmlite(Self).HasBadValue(aProperty)));
end;

function TBasiteHelper.WritesRequired(aProperty: TProperty): boolean;
begin
  Result := aProperty.Required and not (Meta.Xmlite.IsTXmlite and (TXmlite(Self).fXmlPosition <> 0));
end;

// the tag of an element that is written (its parent decided it is present): with content, or empty
function TBasiteHelper.TagType: TTagType;
begin
  Result := TTagType.xttEmpty;

  // simpleContent: text is written whenever the element is (<amount currency="EUR">0</amount> from code), unless it came empty
  var textProperty: TPropertyData := Meta.Xmlite.TextProperty;
  if Assigned(textProperty) and Meta.Xmlite.IsTXmlite and TXmlite(Self).fXmlTextEmpty and not IsPresent(textProperty) then
    textProperty := nil;
  if Assigned(textProperty) and (WritesRequired(textProperty) or IsPresent(textProperty)) then
    Exit(TTagType.xttOpenClose);

  if Meta.Xmlite.ProcessAnyElement and (TXmlite.CountOf(TXmlite(Self).fXmlAny) > 0) then
    Exit(TTagType.xttOpenClose);

  if Meta.Xmlite.IsTXmlite and (TXmlite(Self).fXmlUnknown <> nil) and (TXmlite(Self).fXmlUnknown.Count > 0) then
    Exit(TTagType.xttOpenClose);

  // text of mixed content (OOXML cp:keywords: "q3, plan"): read into XmlText, so written back too
  if Meta.Xmlite.IsTXmlite and not TXmlite(Self).XmlText.IsEmpty then
    Exit(TTagType.xttOpenClose);

  if Meta.Xmlite.IsTXmlite and (TXmlite(Self).ContentCount > 0) then
    Exit(TTagType.xttOpenClose);

  // the same test as ToXml makes for each child element
  for var propertyInfo: TProperty in Meta.Xmlite.Elements.Values do
    if ((propertyInfo.PropertyType <> ptBasite) or (TPropertyBasite(propertyInfo).ObjectPointer(Self)^ <> nil)) and
      (WritesRequired(propertyInfo) or IsPresent(propertyInfo)) then
      Exit(TTagType.xttOpenClose);

  if Assigned(textProperty) then
    Exit(TTagType.xttOpenClose);
end;

procedure TBasiteHelper.ToXml(aWriter: TWriterXmlite; const aName: string; aScope: TNamespace; aNamespaces, aXmlHeader: boolean);
var
  unknownWritten: TArray<boolean>;

  // the namespace in scope is the default one: no prefix; any other namespace: prefixed (declared by GetXmlns)
  function elementName(aProperty: TProperty; aScope: TNamespace): string;
  begin
    if (aProperty.Xmlite.Namespace = nil) or (aProperty.Xmlite.Namespace = aScope) or aProperty.Xmlite.Namespace.Uri.IsEmpty then
      Result := aProperty.Xmlite.Name
    else
      Result := aProperty.Xmlite.NamePrefixed;
  end;

  // an element of no namespace under a default one has no prefix to take: it declares itself (xmlns="", WriteAttributes)
  function declares(aProperty: TProperty; aScope: TNamespace): boolean;
  begin
    Result := (aProperty.Xmlite.Namespace <> nil) and aProperty.Xmlite.Namespace.Uri.IsEmpty and (aScope <> nil) and
      not aScope.Uri.IsEmpty;
  end;

  // a kept element, once; a value that did not fit its type not when the property was set since
  procedure WriteKept(aUnknowns: TList<TXmliteUnknown>; aIndex: integer);
  begin
    var unknown: TXmliteUnknown := aUnknowns[aIndex];
    if (unknown.Value = nil) or not IsPresent(unknown.Value) then
      aWriter.AddUnknown(unknown);
    unknownWritten[aIndex] := True;
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
        WriteKept(unknowns, i);
  end;

  // an ordered element's children in XmlContent's order, then the ones not in it in schema order; an item's object is
  // written only while its property (or XmlAny) holds it (ChildHeld: compared, never followed) and once
  procedure WriteOrdered(aScope: TNamespace);
  var
    written: TDictionary<TBasite, boolean>; // held children only, so the default comparer may follow them
    valuesWritten: TDictionary<TProperty, TArray<boolean>>;

    // aProperty nil: XmlAny's
    procedure WriteChild(aChild: TBasite; aProperty: TProperty);
    begin
      if written.ContainsKey(aChild) or ((aProperty <> nil) and (aProperty.PropertyType = ptBasite) and
        not WritesRequired(aProperty) and not IsPresent(aProperty)) then
        Exit;
      written.Add(aChild, True);
      if aProperty <> nil then
        aChild.ToXml(aWriter, elementName(aProperty, aScope), aScope, declares(aProperty, aScope))
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
      else if not ValueIsWritten(aProperty) then
        Exit;
      var done: TArray<boolean>;
      if not valuesWritten.TryGetValue(aProperty, done) then
        SetLength(done, count);
      if (aIndex < 0) or (aIndex >= count) or (aIndex >= Length(done)) or done[aIndex] then
        Exit;
      done[aIndex] := True;
      valuesWritten.AddOrSetValue(aProperty, done);
      if aProperty.PropertyType = ptDataList then
        aWriter.AddTextNode(elementName(aProperty, aScope), aWriter.ValueText(aProperty,
          TPropertyDataList(aProperty).ItemText(Self, aIndex)), aProperty)
      else
        aWriter.AddTextNode(elementName(aProperty, aScope), aWriter.ValueText(aProperty, TPropertyData(aProperty).Value[Self]),
          aProperty);
    end;

  begin
    var unknowns: TList<TXmliteUnknown> := TXmlite(Self).fXmlUnknown;
    if (unknowns <> nil) and (Length(unknownWritten) <> unknowns.Count) then
      SetLength(unknownWritten, unknowns.Count);

    written := TDictionary<TBasite, boolean>.Create;
    valuesWritten := TDictionary<TProperty, TArray<boolean>>.Create;
    try
      for var item: TBasiteOrderItem in TXmlite(Self).ChildOrder do
        case item.Format of
          TXmlite.cOrderText:
            if Meta.Xmlite.Mixed then
              aWriter.AddTextEscape(item.Text);
          TXmlite.cOrderKept:
            if (unknowns <> nil) and (item.Index >= 0) and (item.Index < unknowns.Count) and not unknownWritten[item.Index] then
              WriteKept(unknowns, item.Index);
          0:
            if item.Element = nil then
            begin
              if item.Child <> nil then
                WriteValue(item.Child, item.Index);
            end
            else if TXmlite(Self).ChildHeld(item) and ((item.Child <> nil) or Meta.Xmlite.ProcessAnyElement) then
              WriteChild(item.Element, item.Child);
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
              WriteChild(TPropertyBasite(propertyElement).ObjectPointer(Self)^, propertyElement);
          ptBasiteList:
            begin
              var list: TBasiteList := TPropertyBasiteList(propertyElement).ObjectPointer(Self)^;
              if list <> nil then
                for var item: TBasite in list do
                  WriteChild(item, propertyElement);
            end;
        end;
      if Meta.Xmlite.ProcessAnyElement and (TXmlite(Self).fXmlAny <> nil) then
        for var anyElement: TBasite in TXmlite(Self).fXmlAny do
          WriteChild(anyElement, nil);
      if unknowns <> nil then
        for var i := 0 to unknowns.Count - 1 do
          if not unknownWritten[i] then
            WriteKept(unknowns, i);
    finally
      valuesWritten.Free;
      written.Free;
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
    TTagType.xttEmpty:
      aWriter.AddTagEmpty(objectName, Self, aNamespaces);
    TTagType.xttOpenClose:
      if Assigned(Meta.Xmlite.TextProperty) then
        if Meta.Xmlite.IsTXmlite and (TXmlite(Self).fXmlTextEmpty or not TXmlite(Self).fXmlText.IsEmpty) and
          not IsPresent(Meta.Xmlite.TextProperty) then
          aWriter.AddTagText(objectName, Self, aNamespaces, TXmlite(Self).fXmlText) // did not fit its type, not set since
        else
          aWriter.AddTagText(objectName, Self, aNamespaces, aWriter.ValueText(Meta.Xmlite.TextProperty,
            Meta.Xmlite.TextProperty.Value[Self]))
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

        if Meta.Xmlite.IsTXmlite and Meta.Xmlite.Ordered and (TXmlite(Self).ContentCount > 0) then
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
                  if ValueIsWritten(propertyData) then
                    aWriter.AddTextNode(elementName(propertyElement, scope), aWriter.ValueText(propertyData, propertyData.Value[Self]),
                      propertyData);
                end;
              ptDataList:
                begin
                  var propertyDataList: TPropertyDataList := TPropertyDataList(propertyElement);
                  WriteUnknown(propertyElement, 0); // a kept item that did not fit its type, before the first good one
                  for var i := 0 to propertyDataList.Count(Self) - 1 do
                  begin
                    aWriter.AddTextNode(elementName(propertyElement, scope), aWriter.ValueText(propertyDataList,
                      propertyDataList.ItemText(Self, i)), propertyDataList);
                    WriteUnknown(propertyElement, i + 1);
                  end;
                end;
              ptBasite:
                begin
                  // written when present or required - its own required values do not make it present (<drawing r:id=""/>)
                  var propertyBasite: TPropertyBasite := TPropertyBasite(propertyElement);
                  var fieldObject: TBasite := propertyBasite.ObjectPointer(Self)^;
                  if (fieldObject <> nil) and (WritesRequired(propertyBasite) or IsPresent(propertyBasite)) then
                    fieldObject.ToXml(aWriter, elementName(propertyElement, scope), scope, declares(propertyElement, scope));
                end;
              ptBasiteList:
                begin
                  // list items are always written - an item with only defaults too (<fill/>: Excel refers to it by index)
                  var propertyBasiteList: TPropertyBasiteList := TPropertyBasiteList(propertyElement);
                  var list: TBasiteList := propertyBasiteList.ObjectPointer(Self)^;
                  if list <> nil then
                    for var i := 0 to list.Count - 1 do
                    begin
                      list[i].ToXml(aWriter, elementName(propertyElement, scope), scope, declares(propertyElement, scope));
                      WriteUnknown(propertyElement, i + 1);
                    end;
                end;
            end;
            WriteUnknown(propertyElement, -1); // after it, or after the items it has now
          end;

          if Meta.Xmlite.IsTXmlite and Meta.Xmlite.ProcessAnyElement and (TXmlite(Self).fXmlAny <> nil) then
            for var anyElement: TBasite in TXmlite(Self).fXmlAny do
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

// the options the overloads without them write with: indented as Pretty says
function GlobalWriteOptions: TXmliteWriteOptions;
begin
  Result := [];
  if TBasite.Pretty then
    Include(Result, woPretty);
end;

procedure TBasiteHelper.ToXml(aStream: TStream; const aName: string; aXmlHeader: boolean);
begin
  ToXml(aStream, GlobalWriteOptions, aName, aXmlHeader);
end;

procedure TBasiteHelper.ToXml(aStream: TStream; aOptions: TXmliteWriteOptions; const aName: string; aXmlHeader: boolean);
begin
  var writer: TWriterXmlite := TWriterXmlite.Create(aStream);
  try
    writer.Pretty := woPretty in aOptions;
    writer.BooleanDigits := woBooleanDigits in aOptions;
    ToXml(writer, aName, nil, True, aXmlHeader);
  finally
    writer.Free;
  end;
end;

function TBasiteHelper.ToXml(const aName: string; aXmlHeader: boolean): string;
begin
  Result := ToXml(GlobalWriteOptions, aName, aXmlHeader);
end;

function TBasiteHelper.ToXml(aOptions: TXmliteWriteOptions; const aName: string; aXmlHeader: boolean): string;
begin
  var writer: TWriterXmlite := TWriterXmlite.Create;
  try
    writer.Pretty := woPretty in aOptions;
    writer.BooleanDigits := woBooleanDigits in aOptions;
    ToXml(writer, aName, nil, True, aXmlHeader);
    Result := writer.Text;
  finally
    writer.Free;
  end;
end;

var
  gPretty: boolean;

class function TBasiteHelper.GetPretty: boolean;
begin
  Result := gPretty;
end;

class procedure TBasiteHelper.SetPretty(aValue: boolean);
begin
  gPretty := aValue;
end;

function TBasiteHelper.GetXmlns: string;
begin
  Result := GetXmlns(nil);
end;

function TBasiteHelper.GetXmlns(aDeclared: TDictionary<string, string>): string;

  // aPrefixed: namespaces used with a prefix in this subtree; aScope: the default one; aKept: the declarations kept
  procedure FillXmlnsList(aXmlnsList, aPrefixed: THashedObjectList<TNamespace>; aKept: TDictionary<string, string>; aObject: TBasite;
    aScope: TNamespace);
  begin
    // the element's own namespace first: a property of it (or of none) adds nothing, and is not asked whether it is written
    var meta: TMetaBasiteXmlite := aObject.Meta.Xmlite;
    var own: TNamespace := meta.Namespace;
    aXmlnsList.Add(own);
    if meta.IsTXmlite and (TXmlite(aObject).fXmlAttributeNamespaces <> nil) then
      for var attributeNamespace: TPair<string, string> in TXmlite(aObject).fXmlAttributeNamespaces do
        aKept.AddOrSetValue(attributeNamespace.Key, attributeNamespace.Value);
    for var attribute: TPropertyData in meta.Attributes.Values do
    begin
      var namespace: TNamespace := attribute.Xmlite.Namespace;
      if ((namespace <> own) and (namespace <> nil) or attribute.Xmlite.Qualified) and
        (aObject.WritesRequired(attribute) or aObject.IsPresent(attribute)) then
      begin
        aXmlnsList.Add(namespace);
        if attribute.Xmlite.Qualified then
          aPrefixed.Add(namespace);
      end;
    end;

    for var element: TProperty in meta.Elements.Values do
    begin
      // the element's own namespace, not its type's (xs of xs:string names nothing): an object's or a list's always, a value's
      // when written
      var namespace: TNamespace := element.Xmlite.Namespace;
      if (namespace <> own) and (namespace <> nil) and ((element.PropertyType in [ptBasite, ptBasiteList, ptDataList]) or
        (element.PropertyType = ptData) and (aObject.WritesRequired(element) or aObject.IsPresent(element))) then
        aXmlnsList.Add(namespace);
      case element.PropertyType of
        ptBasite:
          begin
            var propertyObject: TBasite := TPropertyBasite(element).ObjectPointer(aObject)^;
            if (propertyObject <> nil) and (aObject.WritesRequired(element) or aObject.IsPresent(element)) then
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
    if meta.IsTXmlite and meta.ProcessAnyElement and (TXmlite(aObject).fXmlAny <> nil) then
      for var anyElement: TBasite in TXmlite(aObject).fXmlAny do
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
      if (namespace <> nil) and (namespace.Uri <> TUtility.cXmlPrefixUri) then // the xml prefix is bound by definition, never declared
        if namespace = Meta.Xmlite.Namespace then
        begin
          if not namespace.Uri.IsEmpty then // no namespace: nothing to declare at a root (WriteAttributes undeclares one in scope)
            Result := Result + Format(' xmlns="%s"', [namespace.Uri]);
          declared.AddOrSetValue('', namespace.Uri);
          if prefixed.Contains(namespace) and not namespace.Prefix.IsEmpty then // a default namespace is not for attributes
          begin
            Result := Result + Format(' xmlns:%s="%s"', [namespace.Prefix, namespace.Uri]);
            declared.AddOrSetValue(namespace.Prefix, namespace.Uri);
          end;
        end
        else if not namespace.Uri.IsEmpty then // no namespace has no prefix: such an element declares itself
        begin
          Result := Result + Format(' xmlns:%s="%s"', [namespace.Prefix, namespace.Uri]);
          declared.AddOrSetValue(namespace.Prefix, namespace.Uri);
        end;

    // the kept declarations, unless the prefix is declared already (the element's own names win)
    for var keptPrefix: TPair<string, string> in kept do
      if not declared.ContainsKey(keptPrefix.Key) and (keptPrefix.Key <> TUtility.cXmlPrefix) then
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

{ TReaderXmlite }

class procedure TReaderXmlite.DecodeNamedEscapeEntity(var aCursor, aResultCursor: PChar);
begin
  if (aCursor = nil) or (aResultCursor = nil) then
    Exit;

  if (aCursor[1] = 'l') and (aCursor[2] = 't') and (aCursor[3] = ';') then
  begin // &lt;
    aResultCursor^ := '<';
    Inc(aCursor, 3);
  end
  else if (aCursor[1] = 'g') and (aCursor[2] = 't') and (aCursor[3] = ';') then
  begin // &gt;
    aResultCursor^ := '>';
    Inc(aCursor, 3);
  end
  else if (aCursor[1] = 'a') and (aCursor[2] = 'm') and (aCursor[3] = 'p') and (aCursor[4] = ';') then
  begin // &amp;
    aResultCursor^ := '&';
    Inc(aCursor, 4);
  end
  else if (aCursor[1] = 'q') and (aCursor[2] = 'u') and (aCursor[3] = 'o') and (aCursor[4] = 't') and (aCursor[5] = ';') then
  begin // &quot;
    aResultCursor^ := '"';
    Inc(aCursor, 5);
  end
  else if (aCursor[1] = 'a') and (aCursor[2] = 'p') and (aCursor[3] = 'o') and (aCursor[4] = 's') and (aCursor[5] = ';') then
  begin // &apos;
    aResultCursor^ := '''';
    Inc(aCursor, 5);
  end
  else // something else
    aResultCursor^ := aCursor^;
end;

class procedure TReaderXmlite.DecodeNumericEscapeEntity(var aCursor, aResultCursor: PChar);
begin
  if (aCursor = nil) or (aResultCursor = nil) then
    Exit;

  var cursor: PChar := aCursor + 2;
  var code: integer;;

  if cursor^ = 'x' then
  begin // hexadecimal
    Inc(cursor);
    code := TReaderXmlite.ReadInteger(cursor, True);
  end
  else // decimal
    code := TReaderXmlite.ReadInteger(cursor);

  if (code > 0) and (code <= $10FFFF) then
  begin
    if code <= $FFFF then // BMP character: directly assign
      aResultCursor^ := Char(code)
    else // code point above BMP: convert to surrogate pair
    begin
      code := code - $10000;
      aResultCursor^ := Char($D800 or (code shr 10)); // high surrogate
      Inc(aResultCursor);
      aResultCursor^ := Char($DC00 or (code and $3FF)); // low surrogate
    end;

    aCursor := cursor;
  end
  else
    aResultCursor^ := aCursor^; // seems, it's not a numeric entity
end;

class function TReaderXmlite.PassDtd(var aCursor: PChar): boolean;
begin
  Result := False;

  if not MoveToVisualChar(aCursor) or (aCursor^ <> '<') then
    Exit;
  Inc(aCursor);

  var bracketsCount: cardinal := 1;
  while bracketsCount > 0 do
  begin
    if not TReaderXmlite.MoveToChars(aCursor, ['<', '>']) then
      Exit;

    if aCursor^ = '<' then
      Inc(bracketsCount)
    else
      Dec(bracketsCount);

    Inc(aCursor);
  end;

  Result := True;
end;

class function TReaderXmlite.PassMarkup(var aCursor: PChar): boolean;

  function PassTo(const aEnd: string): boolean;
  begin
    var found: PChar := StrPos(aCursor, PChar(aEnd));
    Result := found <> nil;
    if Result then
      aCursor := found + Length(aEnd);
  end;

begin
  if StrLComp(aCursor, '<!--', 4) = 0 then
    Result := PassTo('-->')
  else if StrLComp(aCursor, '<![CDATA[', 9) = 0 then
    Result := PassTo(']]>')
  else if aCursor[1] = '?' then
    Result := PassTo('?>')
  else
    Result := PassDtd(aCursor);
end;

class function TReaderXmlite.ReadFragment(var aCursor: PChar; aXmlns: TXmlns; out aXml: string;
  aNamespaces: TDictionary<string, string>): boolean;
type
  TDeclaration = record
    Depth: integer;
    Prefix: string;
  end;
var
  names: TList<string>; // the open elements
  declarations: TList<TDeclaration>; // the prefixes they declare

  procedure PassSpaces;
  begin
    while CharInSet(aCursor^, [#32, #9, #$A, #$D]) do
      Inc(aCursor);
  end;

  function ReadName(out aName: string): boolean;
  begin
    var start: PChar := aCursor;
    while not CharInSet(aCursor^, [#0, #32, #9, #$A, #$D, '/', '>', '=', '<', '"', '''']) do
      Inc(aCursor);
    SetString(aName, start, aCursor - start);
    Result := not aName.IsEmpty;
  end;

  procedure CloseElement;
  begin
    for var i := declarations.Count - 1 downto 0 do
      if declarations[i].Depth = names.Count then
        declarations.Delete(i);
    names.Delete(names.Count - 1);
  end;

  // the prefix of a name: declared in the fragment, or outside - then recorded; an undeclared one is not well-formed
  function Resolve(const aName: string; aElement: boolean): boolean;
  begin
    Result := True;
    var prefix: string := '';
    if aName.IndexOf(':') > 0 then
      prefix := aName.Substring(0, aName.IndexOf(':'))
    else if not aElement then
      Exit; // an unprefixed attribute is in no namespace
    if (prefix = TUtility.cXmlPrefix) or (prefix = 'xmlns') then
      Exit;
    for var declaration: TDeclaration in declarations do
      if declaration.Prefix = prefix then
        Exit;
    if prefix.IsEmpty then
      aNamespaces.AddOrSetValue('', aXmlns.DefaultUri)
    else
    begin
      var uri: string;
      Result := aXmlns.TryGetValue(prefix, uri);
      if Result then
        aNamespaces.AddOrSetValue(prefix, uri);
    end;
  end;

begin
  Result := False;
  var start: PChar := aCursor;
  names := TList<string>.Create;
  declarations := TList<TDeclaration>.Create;
  try
    repeat
      if aCursor^ = #0 then
        Exit;
      if aCursor^ <> '<' then // text
      begin
        Inc(aCursor);
        Continue;
      end;

      if (aCursor[1] = '!') or (aCursor[1] = '?') then
      begin // a comment, CDATA, a processing instruction - a DOCTYPE has no place in an element
        if (StrLComp(aCursor, '<!--', 4) <> 0) and (StrLComp(aCursor, '<![CDATA[', 9) <> 0) and (aCursor[1] <> '?') then
          Exit;
        if not PassMarkup(aCursor) then
          Exit;
        Continue;
      end;

      if aCursor[1] = '/' then
      begin // an end tag closes the element opened last
        Inc(aCursor, 2);
        var name: string;
        if not ReadName(name) or (names.Count = 0) or (names.Last <> name) then
          Exit;
        PassSpaces;
        if aCursor^ <> '>' then
          Exit;
        Inc(aCursor);
        CloseElement;
        Continue;
      end;

      // a start tag: its declarations count for its own names
      Inc(aCursor);
      var name: string;
      if not ReadName(name) then
        Exit;
      names.Add(name);
      var attributes: TArray<string> := [];
      var empty: boolean := False;
      while True do
      begin
        PassSpaces;
        if aCursor^ = '>' then
        begin
          Inc(aCursor);
          Break;
        end;
        if (aCursor^ = '/') and (aCursor[1] = '>') then
        begin
          Inc(aCursor, 2);
          empty := True;
          Break;
        end;

        var attribute: string;
        if not ReadName(attribute) then
          Exit;
        PassSpaces;
        if aCursor^ <> '=' then
          Exit;
        Inc(aCursor);
        PassSpaces;
        if not CharInSet(aCursor^, ['"', '''']) then
          Exit;
        var quote: Char := aCursor^;
        Inc(aCursor);
        while aCursor^ <> quote do
        begin
          if (aCursor^ = #0) or (aCursor^ = '<') then // < is not allowed in an attribute value
            Exit;
          Inc(aCursor);
        end;
        Inc(aCursor);

        var declaration: TDeclaration;
        declaration.Depth := names.Count;
        if attribute = 'xmlns' then
        begin
          declaration.Prefix := '';
          declarations.Add(declaration);
        end
        else if attribute.StartsWith('xmlns:') then
        begin
          declaration.Prefix := attribute.Substring(6);
          declarations.Add(declaration);
        end
        else
          attributes := attributes + [attribute];
      end;

      if not Resolve(name, True) then
        Exit;
      for var attribute: string in attributes do
        if not Resolve(attribute, False) then
          Exit;
      if empty then
        CloseElement;
    until names.Count = 0;

    SetString(aXml, start, aCursor - start);
    Result := True;
  finally
    declarations.Free;
    names.Free;
  end;
end;

class function TReaderXmlite.PassEndTag(var aCursor: PChar; const aName: string): boolean;
begin
  Result := False;
  var cursor: PChar := aCursor + 2;
  for var i := 1 to Length(aName) do
    if cursor^ <> aName[i] then // the text's #0 differs too
      Exit
    else
      Inc(cursor);
  while CharInSet(cursor^, [#32, #9, #$A, #$D]) do
    Inc(cursor);
  if cursor^ <> '>' then
    Exit;
  aCursor := cursor + 1;
  Result := True;
end;

class function TReaderXmlite.PassNode(var aCursor: PChar; const aNodeName: string): boolean;
begin
  Result := False;

  while MoveToChars(aCursor, ['"', '''', '<', '/', '>']) do
    case aCursor^ of
      '"', '''': // attribute value
        PassQuotes(aCursor, aCursor^);
      '<': // next tag
        if (aCursor[1] = '!') or (aCursor[1] = '?') then // a comment, CDATA, a processing instruction, a DOCTYPE
        begin
          if not TReaderXmlite.PassMarkup(aCursor) then
            Exit;
        end
        else // regular node or end tag
        begin
          if (aCursor[1] = '/') and PassEndTag(aCursor, aNodeName) then
            Exit(True);
          var nestedNodeName: string;
          var isEndTag: boolean;
          if not ReadTagName(aCursor, isEndTag, nestedNodeName) then
            Exit;

          if isEndTag and (nestedNodeName = aNodeName) then
            Exit(True)
          else if not PassNode(aCursor, nestedNodeName) then
            Exit;
        end;
      '/': // empty tag
        begin
          Inc(aCursor);
          if not MoveToVisualChar(aCursor) then
            Exit;
          if aCursor^ = '>' then
          begin
            Inc(aCursor);
            Exit(True);
          end
          else
            Exit; // something is wrong
        end;
      '>': // possibly text-node contents go next
        begin
          var localCursor: PChar := aCursor; // for checking further contents without changing aCursor value
          Inc(localCursor);
          if not MoveToVisualChar(localCursor) then
            Exit;
          if localCursor^ <> '<' then
            ReadTextNodeContents(aCursor)
          else
            Inc(aCursor);
        end;
    end;
end;

class function TReaderXmlite.ReadAttributeName(var aCursor: PChar; out aPrefix, aName, aFullName: string): boolean;
begin
  Result := TReaderXmlite.ReadName(aCursor, aPrefix, aName, aFullName, ['=']) and TReaderXmlite.MoveToChar(aCursor, '=');
end;

class function TReaderXmlite.ReadName(var aCursor: PChar; out aPrefix, aName, aFullName: string;
  const aCustomEndChars: TSysCharSet): boolean;
begin
  aPrefix := '';
  aName := '';
  aFullName := '';
  Result := False; // should mean no valid name found or invalid format

  if not MoveToVisualChar(aCursor) then // pass any meaningless characters (spaces for instance), check for a nil input
    Exit;
  if CharInSet(aCursor^, aCustomEndChars) then
    Exit; // custom ending character appeared at the beginning

  if not CharInSet(aCursor^, cXmlNameStartChars) then
    Exit; // invalid start character for an XML name

  var nameStart: PChar := aCursor;
  var separatorPosition: PChar := nil;

  while (aCursor^ > #32) and not CharInSet(aCursor^, aCustomEndChars) do
  begin
    if aCursor^ = ':' then
      if separatorPosition = nil then
        separatorPosition := aCursor
      else
        Exit // having several colons is not allowed - something is wrong
    else if not CharInSet(aCursor^, cXmlNameChars) then
      Exit; // invalid character in XML name

    Inc(aCursor);
  end;

  SetString(aFullName, nameStart, aCursor - nameStart);
  if separatorPosition = nil then
    aName := aFullName // one string for both: no prefix
  else
  begin
    SetString(aPrefix, nameStart, separatorPosition - nameStart);
    if separatorPosition + 1 = aCursor then
      Exit; // a prefix without a name (<a:>): False, aPrefix and aFullName as read
    SetString(aName, separatorPosition + 1, aCursor - separatorPosition - 1);
  end;

  Result := True;
end;

class function TReaderXmlite.DecodeXml(const aBytes: TBytes; out aXml: string): boolean;

  // encoding="..." of a declaration in an ASCII-compatible encoding; '' when there is none
  function DeclaredEncoding: string;
  begin
    Result := '';
    var count: integer := Length(aBytes);
    if (count < 6) or (aBytes[0] <> Ord('<')) or (aBytes[1] <> Ord('?')) then
      Exit;
    var head: string := TEncoding.ASCII.GetString(aBytes, 0, Min(count, 200));
    var finish: integer := head.IndexOf('?>');
    if finish < 0 then
      Exit;
    head := head.Substring(0, finish);
    var at: integer := head.IndexOf('encoding');
    if at < 0 then
      Exit;
    at := head.IndexOfAny(['"', ''''], at);
    if at < 0 then
      Exit;
    var close: integer := head.IndexOf(head.Chars[at], at + 1);
    if close > at then
      Result := head.Substring(at + 1, close - at - 1).Trim.ToLower;
  end;

begin
  aXml := '';
  Result := False;
  var count: integer := Length(aBytes);
  var encoding: TEncoding := nil;
  var skip: integer := 0;
  if (count >= 3) and (aBytes[0] = $EF) and (aBytes[1] = $BB) and (aBytes[2] = $BF) then
  begin
    encoding := TEncoding.UTF8;
    skip := 3;
  end
  else if (count >= 2) and (aBytes[0] = $FF) and (aBytes[1] = $FE) then
  begin
    encoding := TEncoding.Unicode;
    skip := 2;
  end
  else if (count >= 2) and (aBytes[0] = $FE) and (aBytes[1] = $FF) then
  begin
    encoding := TEncoding.BigEndianUnicode;
    skip := 2;
  end
  else if (count >= 2) and (aBytes[0] = Ord('<')) and (aBytes[1] = 0) then
    encoding := TEncoding.Unicode
  else if (count >= 2) and (aBytes[0] = 0) and (aBytes[1] = Ord('<')) then
    encoding := TEncoding.BigEndianUnicode;

  var own: boolean := False;
  if encoding = nil then
  begin
    var name: string := DeclaredEncoding;
    // one byte per ASCII character here: a declared UTF-16 is wrong, the bytes are UTF-8
    if (name = '') or name.StartsWith('utf-8') or (name = 'utf8') or name.StartsWith('utf-16') or (name = 'us-ascii') or
      (name = 'ascii') then
      encoding := TEncoding.UTF8
    else
      try
        encoding := TEncoding.GetEncoding(name);
        own := not TEncoding.IsStandardEncoding(encoding);
      except
        on EEncodingError do
          Exit; // a name the system does not know
      end;
  end;

  try
    try
      aXml := encoding.GetString(aBytes, skip, count - skip);
      Result := True;
    except
      on EEncodingError do
        Exit; // bytes that do not fit the encoding
    end;
  finally
    if own then
      encoding.Free;
  end;
end;

class function TReaderXmlite.ReadQuotedValueInPlace(var aCursor: PChar): string;
begin
  Result := '';

  if not TReaderXmlite.MoveToChars(aCursor, ['"', '''']) then
    Exit; // no opening quote found
  var quoteChar: Char := aCursor^;

  Inc(aCursor);
  var valueStart: PChar := aCursor;

  if not TReaderXmlite.MoveToChar(aCursor, quoteChar) then
    Exit; // no closing quote found

  // decoded from a copy: a start tag is read twice (declarations, then attributes) - in place would corrupt the second read
  SetString(Result, valueStart, aCursor - valueStart);
  // a tab or line end typed in the value is a space (XML's attribute-value normalization); &#10; stays a line end
  var spaceCursor: PChar := PChar(Result);
  while spaceCursor^ <> #0 do
  begin
    if CharInSet(spaceCursor^, [#9, #10, #13]) then
      spaceCursor^ := ' ';
    Inc(spaceCursor);
  end;
  if Result.IndexOf('&') >= 0 then
  begin
    var copyCursor: PChar := PChar(Result);
    Result := ReadUnescapeInPlace(copyCursor);
  end;

  Inc(aCursor);
end;

class function TReaderXmlite.ReadTagName(var aCursor: PChar; var aIsEndTag: boolean; out aPrefix, aName, aFullName: string): boolean;
begin
  Result := False;
  aIsEndTag := False;

  if not TReaderXmlite.MoveToVisualChar(aCursor) or (aCursor^ <> '<') then
    Exit;
  Inc(aCursor);

  aIsEndTag := aCursor^ = '/';
  if aIsEndTag then
    Inc(aCursor);

  if not TReaderXmlite.ReadName(aCursor, aPrefix, aName, aFullName, ['>', '/']) then
    Exit;

  if aIsEndTag then
  begin
    if not TReaderXmlite.MoveToChar(aCursor, '>') then
      Exit;
    Inc(aCursor);
  end;

  Result := True;
end;

class function TReaderXmlite.ReadTagName(var aCursor: PChar; var aIsEndTag: boolean; out aFullName: string): boolean;
begin
  var prefix, name: string;
  Result := ReadTagName(aCursor, aIsEndTag, prefix, name, aFullName);
end;

class function TReaderXmlite.ReadTextNodeContents(var aCursor: PChar): string;
begin
  Result := '';

  // it is likely the contents of opening tag were already read and passed, but the start position of Text still needs to be defined
  if not TReaderXmlite.MoveToChar(aCursor, '>') then
    Exit;
  Inc(aCursor);

  Result := ReadUnescapeInPlace(aCursor, '<');
end;

class function TReaderXmlite.ReadValueNode(var aCursor: PChar; const aNodeName: string; out aText: string; out aTagEnd: PChar): boolean;
begin
  Result := False;
  aText := '';
  aTagEnd := nil;

  var quote: Char := #0;
  while (quote <> #0) or (aCursor^ <> '>') do
  begin
    if aCursor^ = #0 then
      Exit;
    if quote <> #0 then
    begin
      if aCursor^ = quote then
        quote := #0;
    end
    else if CharInSet(aCursor^, ['"', '''']) then
      quote := aCursor^;
    Inc(aCursor);
  end;
  Inc(aCursor);
  aTagEnd := aCursor;

  if aTagEnd[-2] = '/' then
    Exit(True);

  aText := ReadUnescapeInPlace(aCursor, '<');
  Result := PassNode(aCursor, aNodeName);
end;

class function TReaderXmlite.ReadUnescapeInPlace(var aCursor: PChar; aStringEndsAt: Char): string;
begin
  var resultStart: PChar := aCursor;
  var resultCursor: PChar := aCursor;

  while True do
  begin
    if aCursor^ = aStringEndsAt then
    begin
      // CDATA is text as it is, a comment or a processing instruction is skipped; any other < ends the text
      if aStringEndsAt <> '<' then
        Break;
      if StrLComp(aCursor, '<![CDATA[', 9) = 0 then
      begin
        Inc(aCursor, 9);
        while StrLComp(aCursor, ']]>', 3) <> 0 do
        begin
          if aCursor^ = #0 then
            Exit(''); // invalid input
          resultCursor^ := aCursor^;
          Inc(resultCursor);
          Inc(aCursor);
        end;
        Inc(aCursor, 3);
        Continue;
      end;
      if (StrLComp(aCursor, '<!--', 4) <> 0) and (aCursor[1] <> '?') then
        Break;
      if not PassMarkup(aCursor) then
        Exit(''); // invalid input
      Continue;
    end;

    if aCursor^ = #0 then
      Exit(''); // invalid input

    if aCursor^ = '&' then
      if (aCursor[1] = '#') then
        DecodeNumericEscapeEntity(aCursor, resultCursor)
      else
        DecodeNamedEscapeEntity(aCursor, resultCursor)
    else
      resultCursor^ := aCursor^;

    Inc(resultCursor);
    Inc(aCursor);
  end;

  // cut-off string with null-terminate and save result
  resultCursor^ := #0;
  Result := resultStart;

  // overwrite all left characters with spaces
  while resultCursor < aCursor do
  begin
    resultCursor^ := #32;
    Inc(resultCursor);
  end;

  // Reset cursor to termination character
  aCursor^ := aStringEndsAt;
end;

class function TReaderXmlite.ReadXmlns(aCursor: PChar; aXmlns: TXmlnsScope): boolean;
begin
  Result := False;

  if (aCursor = nil) or (aXmlns = nil) then
    Exit; // invalid input

  if not MoveToVisualChar(aCursor) or (aCursor^ <> '<') then
    Exit; // not a tag provided

  Inc(aCursor);
  if not MoveToVisualChar(aCursor) or not CharInSet(aCursor^, cXmlNameStartChars) then
    Exit; // invalid beginning of a tag name

  // the name ends at any whitespace: a line end or a tab before the first attribute is common (GPX's schema)
  if not MoveToChars(aCursor, [#32, #9, #10, #13, '>', '/']) then
    Exit; // expected to find space (beginning of xmlns/attribute) or at least ending of the tag

  while aCursor^ <= #32 do
  begin
    if not TReaderXmlite.MoveToVisualChar(aCursor) then
      Exit;

    if CharInSet(aCursor^, ['/', '>']) then
      Exit(True); // tag end reached

    var prefix, name, fullName: string;
    if not TReaderXmlite.ReadAttributeName(aCursor, prefix, name, fullName) then
      Exit;

    var value: string := TReaderXmlite.ReadQuotedValueInPlace(aCursor);

    if prefix = 'xmlns' then
      aXmlns.Declare(name, value)
    else if prefix.IsEmpty and (name = 'xmlns') then
      aXmlns.DeclareDefault(value);
  end;

  Result := True;
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
  if (aFieldInfo.Xmlite.Namespace <> nil) and aFieldInfo.Xmlite.Namespace.Uri.IsEmpty and not DefaultInScope.IsEmpty then
    Write(' xmlns=""');
  if aObject <> nil then
    WriteAttributes(aObject);
  var typeKind: TTypeKind := aFieldInfo.RttiProperty.PropertyType.TypeKind;
  if aFieldInfo.PropertyType = ptDataList then
    typeKind := TPropertyDataList(aFieldInfo).Meta.RttiType.TypeKind;
  // for Office only: Excel trims text without this (tested: spaces, tabs, line ends), also where its schema does not declare the
  // attribute (SpreadsheetML's t). A simple type elsewhere has no attributes, a validating reader refuses it, and readers keep the
  // spaces anyway
  if (typeKind in [tkString, tkLString, tkWString, tkUString]) and not aValue.IsEmpty and
    ((aValue.Chars[0] <= ' ') or (aValue.Chars[aValue.Length - 1] <= ' ')) and (aFieldInfo.Xmlite.Namespace <> nil) and
    (StartsText(TUtility.cOoxmlUriPrefix, aFieldInfo.Xmlite.Namespace.Uri) or
    StartsText(TUtility.cOoxmlStrictUriPrefix, aFieldInfo.Xmlite.Namespace.Uri)) then
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
          WriteChars(PChar(aString) + start - 1, i - start);
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
  WriteChars(PChar(aString) + start - 1, aString.Length + 1 - start);
end;

procedure TWriterXmlite.AddXmlEscape(const aString: string);
begin
  // the text between the escaped chars in one piece
  var cursor: PChar := PChar(aString);
  var start: PChar := cursor;
  while cursor^ <> #0 do
  begin
    case cursor^ of
      #9, #10, #13, '<', '>', '&', '"', '''', #$D800..#$DBFF:
        begin
          WriteChars(start, cursor - start);
          case cursor^ of
            #9: Write('&#x09;');
            #10: Write('&#x0A;');
            #13: Write('&#x0D;');
            '<': Write('&lt;');
            '>': Write('&gt;');
            '&': Write('&amp;');
            '"': Write('&quot;');
            '''': Write('&apos;');
          else // a high surrogate: with its low one, a reference to the code point; alone, invalid in XML and dropped
            if (Ord(cursor[1]) >= $DC00) and (Ord(cursor[1]) <= $DFFF) then
            begin
              var codePoint: cardinal := (Ord(cursor[0]) - $D800) * $400 + (Ord(cursor[1]) - $DC00) + $10000;
              Write('&#x');
              Write(codePoint.ToHexString(6));
              Write(';');
              Inc(cursor);
            end;
          end;
          start := cursor + 1;
        end;
    end; // a lone low surrogate stays in the text: written as U+FFFD
    Inc(cursor);
  end;
  WriteChars(start, cursor - start);
end;

// the value escaped like text (<, &, " and line breaks): FHIR comparator="&lt;=", a kept attribute read with entities
procedure TWriterXmlite.WriteAttribute(const aName, aValue, aPrefix: string);
begin
  Write(' ');
  if not aPrefix.IsEmpty then
  begin
    Write(aPrefix);
    Write(':');
  end;
  Write(aName);
  Write('="');
  AddXmlEscape(aValue);
  Write('"');
end;

function TWriterXmlite.DefaultInScope: string;
begin
  Result := '';
  if fDeclared <> nil then
    for var i := fDeclared.Count - 1 downto 0 do
      if fDeclared[i].TryGetValue('', Result) then
        Exit;
end;

function TWriterXmlite.ValueText(aProperty: TProperty; const aText: string): string;
begin
  var meta: TMetaType := TMetaType(aProperty.Meta); // data or a list of values: always a TMetaType
  if not (fBooleanDigits and meta.IsBoolean) then
    Result := aText
  else if meta.ValuesAliases.Count = 0 then // only true or false
  begin
    if aText.Length = 4 then
      Result := '1'
    else
      Result := '0';
  end
  else if aText = 'true' then
    Result := '1'
  else if aText = 'false' then
    Result := '0'
  else
    Result := aText; // an alias: as stated
end;

procedure TWriterXmlite.WriteAttributes(aObject: TBasite; aNamespaces: boolean);
begin
  if aNamespaces then
  begin
    if fDeclared = nil then
      fDeclared := TObjectList<TDictionary<string, string>>.Create;
    var declared: TDictionary<string, string> := TDictionary<string, string>.Create;
    var xmlns: string := aObject.GetXmlns(declared);
    var uri: string;
    if declared.TryGetValue('', uri) and uri.IsEmpty and not DefaultInScope.IsEmpty then // no namespace under a default one
      xmlns := ' xmlns=""' + xmlns;
    fDeclared.Add(declared);
    Write(xmlns);
  end;

  for var attribute: TPropertyData in aObject.Meta.Xmlite.Attributes.Values do
    if aObject.ValueIsWritten(attribute) then
      if (attribute.Xmlite.Namespace = attribute.ParentMeta.Xmlite.Namespace) and not attribute.Xmlite.Qualified then
        WriteAttribute(attribute.Xmlite.Name, ValueText(attribute, attribute.Value[aObject]))
      else
        WriteAttribute(attribute.Xmlite.NamePrefixed, ValueText(attribute, attribute.Value[aObject]));

  if aObject.Meta.Xmlite.IsTXmlite and (TXmlite(aObject).fXmlAttributes <> nil) then
    for var attribute: TPair<string, string> in TXmlite(aObject).fXmlAttributes do
    begin
      var badOf: TProperty := nil;
      if TXmlite(aObject).fXmlBadAttributes <> nil then
        TXmlite(aObject).fXmlBadAttributes.TryGetValue(attribute.Key, badOf);
      if (badOf = nil) or not aObject.IsPresent(badOf) then // did not fit its type, not set since
        WriteAttribute(attribute.Key, attribute.Value);
    end;
end;

{ TXmlite }

procedure TXmlite.Deinitialize;
begin
  fXmlBadAttributes.Free;
  fXmlUnknown.Free;
  fXmlAny.Free;
  fXmlns.Release;
  fXmlAttributeNamespaces.Free;
  fXmlAttributes.Free;
  inherited;
end;

// its own state first: Basite's copy of the order, at the end of inherited, finds the copies of xs:any and kept elements
procedure TXmlite.CopyFrom(aSource: TBasite; aCommon: TMetaBasite);
begin
  if aSource is TXmlite then
  begin
    var source: TXmlite := TXmlite(aSource);
    fXmlPrefix := source.fXmlPrefix;
    fXmlName := source.fXmlName;
    fXmlText := source.fXmlText;
    fXmlTextEmpty := source.fXmlTextEmpty;
    if CountOf(source.fXmlAttributes) > 0 then
      for var pair: TPair<string, string> in source.fXmlAttributes do
        XmlAttributes.AddOrSetValue(pair.Key, pair.Value);
    if CountOf(source.fXmlAttributeNamespaces) > 0 then
      for var pair: TPair<string, string> in source.fXmlAttributeNamespaces do
        XmlAttributeNamespaces.AddOrSetValue(pair.Key, pair.Value);
    fXmlns.Release;
    fXmlns := nil;
    if source.fXmlns <> nil then
      fXmlns := source.fXmlns.Share;
    if CountOf(source.fXmlAny) > 0 then
      for var item: TBasite in source.fXmlAny do
        XmlAny.Add(item.Clone);
    var own: TProperty;
    if source.fXmlBadAttributes <> nil then
      for var pair: TPair<string, TProperty> in source.fXmlBadAttributes do
        if Meta.Counterpart(pair.Value, own) then
        begin
          if fXmlBadAttributes = nil then
            fXmlBadAttributes := TDictionary<string, TProperty>.Create;
          fXmlBadAttributes.AddOrSetValue(pair.Key, own);
        end;
    // kept elements whose anchors are common
    var copy: TXmliteUnknown;
    if source.fXmlUnknown <> nil then
      for var unknown: TXmliteUnknown in source.fXmlUnknown do
        if KeptCopy(unknown, copy) then
          XmlUnknown.Add(copy);
  end;
  inherited;
end;

function TXmlite.KeptCopy(const aUnknown: TXmliteUnknown; out aCopy: TXmliteUnknown): boolean;
begin
  aCopy := aUnknown;
  Result := Meta.Counterpart(aUnknown.After, aCopy.After) and Meta.Counterpart(aUnknown.Value, aCopy.Value);
  if Result then
    aCopy.Namespaces := Copy(aUnknown.Namespaces);
end;

function TXmlite.CopyOrderItem(aSource: TBasite; var aItem: TBasiteOrderItem): boolean;
begin
  var source: TXmlite := TXmlite(aSource); // only Xmlite keeps items with Child nil
  case aItem.Format of
    cOrderKept: // the same place, or its place among the copied ones (another class may not have them all)
      begin
        if ClassType <> aSource.ClassType then
        begin
          var copy: TXmliteUnknown;
          var place: integer := 0;
          for var i := 0 to aItem.Index - 1 do
            if KeptCopy(source.fXmlUnknown[i], copy) then
              Inc(place);
          if not KeptCopy(source.fXmlUnknown[aItem.Index], copy) then
            Exit(False);
          aItem.Index := place;
        end;
        Result := True;
      end;
    0: // xs:any: held by XmlAny (its list's Notify), at the same place as its copy
      begin
        var place: integer := -1;
        if source.fXmlAny <> nil then
          place := source.fXmlAny.IndexOf(aItem.Element);
        Result := (place >= 0) and (place < CountOf(fXmlAny));
        if Result then
          aItem.Element := fXmlAny[place];
      end;
  else
    Result := inherited;
  end;
end;

function TXmlite.SameAs(aOther: TBasite): boolean;

  function SameMap(aMap, aOther: TDictionary<string, string>): boolean;
  begin
    if CountOf(aMap) <> CountOf(aOther) then
      Exit(False);
    if aMap = nil then
      Exit(True);
    for var pair: TPair<string, string> in aMap do
    begin
      var value: string;
      if not aOther.TryGetValue(pair.Key, value) or (value <> pair.Value) then
        Exit(False);
    end;
    Result := True;
  end;

  function SameUnknown(const aUnknown, aOther: TXmliteUnknown): boolean;
  begin
    Result := (aUnknown.Xml = aOther.Xml) and (aUnknown.After = aOther.After) and (aUnknown.AfterCount = aOther.AfterCount) and
      (aUnknown.Value = aOther.Value) and (Length(aUnknown.Namespaces) = Length(aOther.Namespaces));
    if Result then
      for var i := 0 to High(aUnknown.Namespaces) do
        if (aUnknown.Namespaces[i].Key <> aOther.Namespaces[i].Key) or (aUnknown.Namespaces[i].Value <> aOther.Namespaces[i].Value) then
          Exit(False);
  end;

begin
  Result := inherited SameAs(aOther);
  if not Result or (aOther = Self) then
    Exit;
  var other: TXmlite := TXmlite(aOther); // of this class: inherited checked it
  if (fXmlPrefix <> other.fXmlPrefix) or (fXmlName <> other.fXmlName) or (fXmlText <> other.fXmlText) or
    (fXmlTextEmpty <> other.fXmlTextEmpty) or not SameMap(fXmlAttributes, other.fXmlAttributes) or
    not SameMap(fXmlAttributeNamespaces, other.fXmlAttributeNamespaces) or
    (CountOf(fXmlAny) <> CountOf(other.fXmlAny)) or (CountOf(fXmlUnknown) <> CountOf(other.fXmlUnknown)) or
    (CountOf(fXmlBadAttributes) <> CountOf(other.fXmlBadAttributes)) then
    Exit(False);
  for var i := 0 to CountOf(fXmlAny) - 1 do
    if not fXmlAny[i].SameAs(other.fXmlAny[i]) then
      Exit(False);
  for var i := 0 to CountOf(fXmlUnknown) - 1 do
    if not SameUnknown(fXmlUnknown[i], other.fXmlUnknown[i]) then
      Exit(False);
  if fXmlBadAttributes <> nil then
    for var pair: TPair<string, TProperty> in fXmlBadAttributes do
    begin
      var badOf: TProperty;
      if not other.fXmlBadAttributes.TryGetValue(pair.Key, badOf) or (badOf <> pair.Value) then
        Exit(False);
    end;
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

function TXmlite.GetXmlAny: TBasiteList<TBasite>;
begin
  if fXmlAny = nil then
  begin
    fXmlAny := TBasiteList<TBasite>.Create;
    fXmlAny.Owner := Self;
  end;
  Result := fXmlAny;
end;

function TXmlite.GetXmlAttributes: TDictionary<string, string>;
begin
  if fXmlAttributes = nil then
    fXmlAttributes := TDictionary<string, string>.Create;
  Result := fXmlAttributes;
end;

function TXmlite.GetXmlAttributeNamespaces: TDictionary<string, string>;
begin
  if fXmlAttributeNamespaces = nil then
    fXmlAttributeNamespaces := TDictionary<string, string>.Create;
  Result := fXmlAttributeNamespaces;
end;

class function TXmlite.CountOf(aMap: TDictionary<string, string>): integer;
begin
  if aMap = nil then
    Result := 0
  else
    Result := aMap.Count;
end;

class function TXmlite.CountOf(aMap: TDictionary<string, TProperty>): integer;
begin
  if aMap = nil then
    Result := 0
  else
    Result := aMap.Count;
end;

class function TXmlite.CountOf(aList: TBasiteList<TBasite>): integer;
begin
  if aList = nil then
    Result := 0
  else
    Result := aList.Count;
end;

class function TXmlite.CountOf(aList: TList<TXmliteUnknown>): integer;
begin
  if aList = nil then
    Result := 0
  else
    Result := aList.Count;
end;

procedure TXmlite.Clear;
begin
  inherited;
  fXmlText := '';
  fXmlTextEmpty := False;
  fXmlPosition := 0;
  if fXmlAny <> nil then
    fXmlAny.Clear;
  if fXmlAttributes <> nil then
    fXmlAttributes.Clear;
  if fXmlAttributeNamespaces <> nil then
    fXmlAttributeNamespaces.Clear;
  if fXmlBadAttributes <> nil then
    fXmlBadAttributes.Clear;
  if fXmlUnknown <> nil then
    fXmlUnknown.Clear;
end;

function TXmlite.HasBadValue(aProperty: TProperty): boolean;
begin
  Result := False;
  if fXmlUnknown <> nil then
    for var unknown: TXmliteUnknown in fXmlUnknown do
      if unknown.Value = aProperty then
        Exit(True);
  if fXmlBadAttributes <> nil then
    for var badOf: TProperty in fXmlBadAttributes.Values do
      if badOf = aProperty then
        Exit(True);
end;

procedure TXmlite.ReadEmptyText;
begin
  // a string may be empty, and so may an enumeration with an empty item; <amount/> and <code/> otherwise would be written as 0 and
  // the first item
  var textProperty: TPropertyData := Meta.Xmlite.TextProperty;
  if Assigned(textProperty) and (textProperty.RttiProperty.PropertyType.TypeKind <> tkUString) and
    not textProperty.TrySetValue(Self, '') then
    fXmlTextEmpty := True;
end;

function TXmlite.GetXmlUnknown: TList<TXmliteUnknown>;
begin
  if fXmlUnknown = nil then
    fXmlUnknown := TList<TXmliteUnknown>.Create;
  Result := fXmlUnknown;
end;

function TXmlite.GetXmlContent: TXmliteContent;
begin
  Result.fOwner := Self;
end;

function TXmlite.ContentCount: integer;
begin
  if ChildOrder = nil then
    Result := 0
  else
    Result := ChildOrder.Count;
end;

function TXmlite.ContentItem(aIndex: integer): TXmliteContentItem;
begin
  var item: TBasiteOrderItem := ChildOrder[aIndex];
  case item.Format of
    cOrderText:
      Result.Kind := xckText;
    cOrderKept:
      Result.Kind := xckKept;
  else
    Result.Kind := xckElement;
  end;
  Result.Text := item.Text;
  Result.Element := item.Element;
  Result.ElementProperty := item.Child;
  Result.Index := item.Index;
end;

procedure TXmlite.AddContent(aKind: TXmliteContentKind; const aText: string; aElement: TBasite; aProperty: TProperty;
  aIndex: integer);
begin
  var order: TList<TBasiteOrderItem> := ChildOrder(True);
  if (aKind = xckText) and (order.Count > 0) and (order.Last.Format = cOrderText) then
  begin
    var last: TBasiteOrderItem := order.Last;
    last.Text := last.Text + aText;
    order[order.Count - 1] := last;
    Exit;
  end;

  var item: TBasiteOrderItem := Default(TBasiteOrderItem);
  case aKind of
    xckText:
      item.Format := cOrderText;
    xckKept:
      item.Format := cOrderKept;
  end;
  item.Text := aText;
  item.Element := aElement;
  item.Child := aProperty;
  item.Index := aIndex;
  order.Add(item);
end;

// created on the first need: an element read takes its scope's
function TXmlite.GetXmlnsInScope: TXmlns;
begin
  if fXmlns = nil then
    fXmlns := TXmlnsScope.Create;
  Result := fXmlns;
end;

function TXmlite.GetXmlText: string;
begin
  if not Meta.Xmlite.Mixed then
    Exit(fXmlText);
  Result := '';
  if (ContentCount > 0) and (ChildOrder[0].Format = cOrderText) then
    Result := ChildOrder[0].Text;
end;

procedure TXmlite.SetXmlText(const aValue: string);
begin
  if not Meta.Xmlite.Mixed then
  begin
    fXmlText := aValue;
    Exit;
  end;

  // the leading text item: replaced, inserted before the first child, or removed ('')
  if (ContentCount > 0) and (ChildOrder[0].Format = cOrderText) then
    if aValue.IsEmpty then
      ChildOrder.Delete(0)
    else
    begin
      var item: TBasiteOrderItem := ChildOrder[0];
      item.Text := aValue;
      ChildOrder[0] := item;
    end
  else if not aValue.IsEmpty then
  begin
    var item: TBasiteOrderItem := Default(TBasiteOrderItem);
    item.Format := cOrderText;
    item.Text := aValue;
    ChildOrder(True).Insert(0, item);
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
      propertyList.ObjectPointer(Self)^ := propertyList.Meta.CreateList(Self);
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
    AddContent(xckElement, '', Result, propertyElement, index);
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
    AddContent(xckText, aText, nil, nil, 0)
  else
    fXmlText := fXmlText + aText;
end;

procedure TXmlite.Remove(aElement: TBasite);
begin
  if aElement = nil then
    Exit;

  // its item leaves the order with it: through its list's Notify, or Clear of its property
  if (fXmlAny <> nil) and (fXmlAny.Remove(aElement) >= 0) then
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
  if Meta.Xmlite.Ordered and (ContentCount > 0) then
  begin
    Result := '';
    for var item: TBasiteOrderItem in ChildOrder do
      if item.Format = cOrderText then
        Result := Result + item.Text
      else if item.Format <> 0 then
        Continue
      else if item.Element <> nil then
      begin
        if ChildHeld(item) then // as the writer does
          Result := Result + TextOf(item.Element);
      end
      else if item.Child = nil then
        Continue
      else if item.Child.PropertyType = ptDataList then
      begin
        if item.Index < TPropertyDataList(item.Child).Count(Self) then // the list may have changed
          Result := Result + TPropertyDataList(item.Child).ItemText(Self, item.Index);
      end
      else if item.Child.PropertyType = ptData then
        Result := Result + TPropertyData(item.Child).Value[Self];
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
  Result := inherited and fXmlText.IsEmpty and not fXmlTextEmpty and (CountOf(fXmlAny) = 0) and (CountOf(fXmlAttributes) = 0) and
    (CountOf(fXmlUnknown) = 0) and (ContentCount = 0);
end;

function TXmlite.HasContent: boolean;
begin
  Result := not fXmlText.IsEmpty or fXmlTextEmpty or (CountOf(fXmlAny) > 0) or (CountOf(fXmlAttributes) > 0) or
    (CountOf(fXmlUnknown) > 0) or (ContentCount > 0) or inherited;
end;

{ TXmliteContentItem }

function TXmliteContentItem.IsText: boolean;
begin
  Result := Kind = xckText;
end;

function TXmliteContentItem.IsElement<T>: boolean;
begin
  Result := (Kind = xckElement) and (Element is T);
end;

function TXmliteContentItem.ElementAs<T>: T;
begin
  Result := Element as T;
end;

function TXmliteContentItem.Name: string;
begin
  Result := '';
  case Kind of
    xckElement:
      if ElementProperty <> nil then
        Result := ElementProperty.Xmlite.Name
      else if Element <> nil then
        Result := Element.Meta.Xmlite.Name;
    xckKept:
      Result := Text;
  end;
end;

{ TXmliteContent }

function TXmliteContent.GetCount: integer;
begin
  Result := fOwner.ContentCount;
end;

function TXmliteContent.GetItem(aIndex: integer): TXmliteContentItem;
begin
  Result := fOwner.ContentItem(aIndex);
end;

function TXmliteContent.GetEnumerator: TEnumerator;
begin
  Result.fOwner := fOwner;
  Result.fIndex := -1;
end;

function TXmliteContent.TEnumerator.MoveNext: boolean;
begin
  Inc(fIndex);
  Result := fIndex < fOwner.ContentCount;
end;

function TXmliteContent.TEnumerator.GetCurrent: TXmliteContentItem;
begin
  Result := fOwner.ContentItem(fIndex);
end;

procedure TXmlite.SetXsiType(aType: TClass);
begin
  if (aType = nil) or not aType.InheritsFrom(TBasite) then
    raise EArgumentException.Create('SetXsiType: a generated complex type class is expected');

  var typeMeta: TMetaBasite := TBasiteClass(aType).Meta;
  if (typeMeta.Xmlite.ComponentType <> TXmliteComponentType.xctComplexType) or (typeMeta.Xmlite.Namespace = nil) then
    raise EArgumentException.CreateFmt('SetXsiType: %s is not a complex type registered in a namespace', [aType.ClassName]);

  // XSD: the type must derive from the element's own one - the nearest complex type among the element's ancestors
  var declared: TClass := ClassType;
  while (declared <> nil) and declared.InheritsFrom(TBasite) and
    (TBasiteClass(declared).Meta.Xmlite.ComponentType <> TXmliteComponentType.xctComplexType) do
    declared := declared.ClassParent;
  if (declared = nil) or not declared.InheritsFrom(TBasite) or not aType.InheritsFrom(declared) then
    raise EArgumentException.CreateFmt('SetXsiType: %s is not derived from the type of %s', [aType.ClassName, ClassName]);

  XmlAttributes.AddOrSetValue(TUtility.cXsiPrefix + ':type', typeMeta.Xmlite.Namespace.Prefix + ':' + typeMeta.Xmlite.Name);
  XmlAttributeNamespaces.AddOrSetValue(TUtility.cXsiPrefix, TUtility.cXsiUri);
  XmlAttributeNamespaces.AddOrSetValue(typeMeta.Xmlite.Namespace.Prefix, typeMeta.Xmlite.Namespace.Uri);
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
  TMetaBankXmlite.Instance.BindPending(aMeta);
  if fExactNames and (aType in [TXmliteComponentType.xctSimpleType, TXmliteComponentType.xctAttribute]) then
    metaType.SetItemNaming(fItemNaming);
  case aType of
    TXmliteComponentType.xctSimpleType:
      fSimpleTypes.Add(aMeta.Xmlite.Name, metaType);
    TXmliteComponentType.xctComplexType:
      fComplexTypes.Add(aMeta.Xmlite.Name, metaBasite);
    TXmliteComponentType.xctAttribute:
      fAttributes.Add(aMeta.Xmlite.Name, metaType);
    TXmliteComponentType.xctAttributeGroup:
      fAttributeGroups.Add(aMeta.Xmlite.Name, metaBasite);
    TXmliteComponentType.xctElement:
      fElements.Add(aMeta.Xmlite.Name, metaBasite);
    TXmliteComponentType.xctElementGroup:
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
  fMemberNaming := aNaming;
  fItemNaming := cDefaultNaming;

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
    TXmliteComponentType.xctComplexType:
      Result := namespace.ComplexTypes[aXmlName];
    TXmliteComponentType.xctAttributeGroup:
      Result := namespace.AttributeGroups[aXmlName];
    TXmliteComponentType.xctElement:
      Result := namespace.Elements[aXmlName];
    TXmliteComponentType.xctElementGroup:
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
    TXmliteComponentType.xctSimpleType:
      component := namespace.SimpleTypes[aXmlName];
    TXmliteComponentType.xctComplexType:
      component := namespace.ComplexTypes[aXmlName];
    TXmliteComponentType.xctAttribute:
      component := namespace.Attributes[aXmlName];
    TXmliteComponentType.xctAttributeGroup:
      component := namespace.AttributeGroups[aXmlName];
    TXmliteComponentType.xctElement:
      component := namespace.Elements[aXmlName];
    TXmliteComponentType.xctElementGroup:
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
  fPending := TObjectDictionary<TMeta, TList<TMetaBasite>>.Create([doOwnsValues]);
end;

class constructor TMetaBankXmlite.Create;
begin
  TMetaBankXmlite.RegisterExtension;
end;

destructor TMetaBankXmlite.Destroy;
begin
  fPending.Free;
  fNamespaces.Free;
  inherited;
end;

procedure TMetaBankXmlite.AddPending(aType: TMeta; aOwner: TMetaBasite);
begin
  var owners: TList<TMetaBasite>;
  if not fPending.TryGetValue(aType, owners) then
  begin
    owners := TList<TMetaBasite>.Create;
    fPending.Add(aType, owners);
  end;
  if not owners.Contains(aOwner) then
    owners.Add(aOwner);
end;

procedure TMetaBankXmlite.BindPending(aType: TMeta);
begin
  var owners: TList<TMetaBasite>;
  if not fPending.TryGetValue(aType, owners) then
    Exit;
  fPending.ExtractPair(aType);
  try
    for var owner: TMetaBasite in owners do
      owner.Xmlite.BindMembers;
  finally
    owners.Free;
  end;
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
  if Instance.TryGetNamespace(aUri, Result) then
    RegisteredTwice(Result);

  Result := TNamespace.Create(aUri, aPrefix, aNaming, aSuffixSimpleType, aSuffixComplexType, aSuffixAttribute, aSuffixAttributeGroup,
    aSuffixElement, aSuffixElementGroup);
  AddComponents(Result, aSimpleTypes, aComplexTypes, aAttributes, aAttributeGroups, aElements, aGroups);
end;

class function TMetaBankXmlite.RegisterNamespace(const aUri: string; const aSimpleTypes: TArray<PTypeInfo>;
  const aComplexTypes: TArray<TBasiteClass>; const aAttributes: TArray<PTypeInfo>;
  const aAttributeGroups, aElements, aGroups: TArray<TBasiteClass>; const aPrefix: string; aNaming, aMemberNaming, aItemNaming: TNaming)
  : TNamespace;
begin
  if Instance.TryGetNamespace(aUri, Result) then
    RegisteredTwice(Result);

  Result := TNamespace.Create(aUri, aPrefix, aNaming, cDefaultSuffixSimpleType, cDefaultSuffixComplexType, cDefaultSuffixAttribute,
    cDefaultSuffixAttributeGroup, cDefaultSuffixElement, cDefaultSuffixElementGroup);
  Result.fMemberNaming := aMemberNaming;
  Result.fItemNaming := aItemNaming;
  Result.fExactNames := True;
  AddComponents(Result, aSimpleTypes, aComplexTypes, aAttributes, aAttributeGroups, aElements, aGroups);
end;

// a second unit's classes would stay unknown to the reader: a setup error, raised at the program's start
class procedure TMetaBankXmlite.RegisteredTwice(aNamespace: TNamespace);
begin
  raise EArgumentException.CreateFmt('RegisterNamespace: %s is registered already, by %s - a program uses one unit for a namespace',
    [aNamespace.Uri, aNamespace.UnitQualifiedName]);
end;

class procedure TMetaBankXmlite.AddComponents(aNamespace: TNamespace; const aSimpleTypes: TArray<PTypeInfo>;
  const aComplexTypes: TArray<TBasiteClass>; const aAttributes: TArray<PTypeInfo>;
  const aAttributeGroups, aElements, aGroups: TArray<TBasiteClass>);
begin
  for var simpleType: PTypeInfo in aSimpleTypes do
    aNamespace.Add(TMetaBank.RegisterType(simpleType), TXmliteComponentType.xctSimpleType);

  // global attributes before the classes: a member typed with one takes its namespace when it registers
  for var attribute: PTypeInfo in aAttributes do
    aNamespace.Add(TMetaBank.RegisterType(attribute), TXmliteComponentType.xctAttribute);

  for var complexType: TBasiteClass in aComplexTypes do
    aNamespace.Add(complexType.Meta, TXmliteComponentType.xctComplexType);

  for var attributeGroup: TBasiteClass in aAttributeGroups do
    aNamespace.Add(attributeGroup.Meta, TXmliteComponentType.xctAttributeGroup);

  for var element: TBasiteClass in aElements do
    aNamespace.Add(element.Meta, TXmliteComponentType.xctElement);

  for var elementGroup: TBasiteClass in aGroups do
    aNamespace.Add(elementGroup.Meta, TXmliteComponentType.xctElementGroup);

  Instance.fNamespaces.Add(aNamespace);
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
            RegisterElement(uriedName, propertyData)
          else
            fAttributes.Add(uriedName, propertyData);
        end;
      ptBasite, ptBasiteList, ptDataList:
        RegisterElement(uriedName, propertyInfo);
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
  fSameName.Free;
  inherited;
end;

procedure TMetaBasiteXmlite.RegisterElement(const aName: TUriedName; aProperty: TProperty);
begin
  // a member of its ancestor's Delphi name hides it (units before 1.7): the descendant's alone, as before
  var first: TProperty := fElements[aName];
  if (first <> nil) and SameText(first.RttiProperty.Name, aProperty.RttiProperty.Name) and
    ((fSameName = nil) or not fSameName.ContainsKey(first)) then
  begin
    fElements.Add(aName, aProperty);
    Exit;
  end;

  fElements.AddAnother(aName, aProperty);
  if first = nil then
    Exit;

  if fSameName = nil then
    fSameName := TDictionary<TProperty, TProperty>.Create;
  var last: TProperty := first;
  var next: TProperty;
  while fSameName.TryGetValue(last, next) do
    last := next;
  fSameName.Add(last, aProperty);
end;

function TMetaBasiteXmlite.Element(const aUri, aName: string): TProperty;
begin
  var key: TUriedNameView;
  key.Uri := Pointer(aUri);
  key.Name := Pointer(aName);
  Result := fElements[PUriedName(@key)^];
end;

function TMetaBasiteXmlite.Attribute(const aUri, aName: string): TPropertyData;
begin
  var key: TUriedNameView;
  key.Uri := Pointer(aUri);
  key.Name := Pointer(aName);
  Result := fAttributes[PUriedName(@key)^];
end;

function TMetaBasiteXmlite.ElementOfName(aFirst, aLast: TProperty; aObject: TBasite): TProperty;

  function IsList(aProperty: TProperty): boolean; inline;
  begin
    Result := aProperty.PropertyType in [ptBasiteList, ptDataList];
  end;

begin
  Result := aFirst;
  if (fSameName = nil) or not fSameName.ContainsKey(aFirst) then
    Exit;

  var lastIndex: integer := -1;
  if aLast <> nil then
    lastIndex := fElements.Values.IndexOf(aLast);
  var candidate: TProperty := aFirst;
  repeat
    if (fElements.Values.IndexOf(candidate) >= lastIndex) and ((IsList(candidate) and (candidate = aLast)) or
      not aObject.IsPresent(candidate)) then
      Exit(candidate);
  until not fSameName.TryGetValue(candidate, candidate);

  // a document out of the schema's order
  candidate := aFirst;
  repeat
    if not aObject.IsPresent(candidate) then
      Exit(candidate);
  until not fSameName.TryGetValue(candidate, candidate);
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
  BindMembers;
end;

// the members' namespaces and XML names, again when a type they name registers later (BindPending)
procedure TMetaBasiteXmlite.BindMembers;
begin
  fAttributes.Clear;
  fElements.Clear;
  FreeAndNil(fSameName);
  fTextProperty := nil;
  for var propertyInfo: TProperty in Meta.Properties do
  begin
    propertyInfo.Xmlite.NamespaceRegister(Namespace);

    var uriedName: TUriedName := TUriedName.Create(propertyInfo.Xmlite.Namespace.Uri, propertyInfo.Xmlite.Name);
    case propertyInfo.PropertyType of
      ptData:
        begin
          var propertyData: TPropertyData := TPropertyData(propertyInfo);
          if FieldIsText(propertyData) then
            fTextProperty := propertyData
          else if FieldIsElement(propertyData) then
            RegisterElement(uriedName, propertyData)
          else
            fAttributes.Add(uriedName, propertyData);
        end;

      ptBasite, ptBasiteList, ptDataList:
        RegisterElement(uriedName, propertyInfo);
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
  FreeAndNil(fSameName);

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
    TXmliteComponentType.xctSimpleType:
      if (fNamespace.fSuffixLengthSimpleType > 0) and fName.EndsWith(fNamespace.fSuffixSimpleType) then
        SetLength(fName, Length(fName) - fNamespace.fSuffixLengthSimpleType);
    TXmliteComponentType.xctComplexType:
      if (fNamespace.fSuffixLengthComplexType > 0) and fName.EndsWith(fNamespace.fSuffixComplexType) then
        SetLength(fName, Length(fName) - fNamespace.fSuffixLengthComplexType);
    TXmliteComponentType.xctAttribute:
      if (fNamespace.fSuffixLengthAttribute > 0) and fName.EndsWith(fNamespace.fSuffixAttribute) then
        SetLength(fName, Length(fName) - fNamespace.fSuffixLengthAttribute);
    TXmliteComponentType.xctAttributeGroup:
      if (fNamespace.fSuffixLengthAttributeGroup > 0) and fName.EndsWith(fNamespace.fSuffixAttributeGroup) then
        SetLength(fName, Length(fName) - fNamespace.fSuffixLengthAttributeGroup);
    TXmliteComponentType.xctElement:
      if (fNamespace.fSuffixLengthElement > 0) and fName.EndsWith(fNamespace.fSuffixElement) then
        SetLength(fName, Length(fName) - fNamespace.fSuffixLengthElement);
    TXmliteComponentType.xctElementGroup:
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
      TXmliteComponentType.xctSimpleType:
        fNamespace.SimpleTypes.Remove(fName);
      TXmliteComponentType.xctComplexType:
        fNamespace.ComplexTypes.Remove(fName);
      TXmliteComponentType.xctAttribute:
        fNamespace.Attributes.Remove(fName);
      TXmliteComponentType.xctAttributeGroup:
        fNamespace.AttributeGroups.Remove(fName);
      TXmliteComponentType.xctElement:
        fNamespace.Elements.Remove(fName);
      TXmliteComponentType.xctElementGroup:
        fNamespace.ElementGroups.Remove(fName);
    end;

  fNamespace := nil;
  fComponentType := TXmliteComponentType.xctUndefined;
  if Meta.SimplifiedName[1] = 'T' then
    fName := PChar(Meta.SimplifiedName) + 1
  else
    fName := Meta.SimplifiedName;
  // [TName('xml')] names a class of no namespace too (a document's own root)
  if Meta.RttiType <> nil then
    for var attribute: TCustomAttribute in Meta.RttiType.GetAttributes do
      if attribute.ClassType = TNameAttribute then
        fName := TNameAttribute(attribute).CustomName;
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

  // a reference to a global element or attribute belongs to its namespace (an attribute qualified); a local member to its owner.
  // A class of this unit not registered yet (namespaces that import each other share a unit: VML's o:lock in v:shape) is not
  // known as either: the owner is bound again when it registers
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
        TXmliteComponentType.xctElement:
          fNamespace := typeXmlite.Namespace;
        TXmliteComponentType.xctAttribute:
          begin
            fNamespace := typeXmlite.Namespace;
            fQualified := True;
          end;
      end
    else if (typeXmlite <> nil) and (PropertyInfo.ParentMeta <> nil) and
      (typeMeta.UnitQualifiedName = PropertyInfo.ParentMeta.UnitQualifiedName) then
      TMetaBankXmlite.Instance.AddPending(typeMeta, PropertyInfo.ParentMeta);
  end;

  if fNamespace = nil then
    fNamespace := aNamespace;

  // a member follows its namespace's members' naming, unless the property defines its own [TName] or [TNaming];
  // an inherited one follows the namespace of the class that declares it (UBL's cbc:Amount has udt's currencyID)
  if not hasOwnName then
  begin
    var naming: TNamespace := fNamespace;
    var declaring: TRttiType := PropertyInfo.RttiProperty.Parent;
    if (fNamespace = aNamespace) and declaring.IsInstance and declaring.AsInstance.MetaclassType.InheritsFrom(TBasite) then
    begin
      var declaringXmlite: TMetaXmlite := TBasiteClass(declaring.AsInstance.MetaclassType).Meta.Xmlite;
      if (declaringXmlite <> nil) and (declaringXmlite.Namespace <> nil) then
        naming := declaringXmlite.Namespace;
    end;
    if naming.fExactNames then
      fName := TUtility.FromPascalCaseExact(PropertyInfo.RttiProperty.Name, naming.MemberNaming)
    else
      fName := TUtility.FromPascalCase(PropertyInfo.RttiProperty.Name, naming.MemberNaming);
  end;

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
