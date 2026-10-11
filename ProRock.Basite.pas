unit ProRock.Basite;

interface

{$DEFINE PROROCK}

uses System.Classes, System.Rtti, Generics.Collections, System.SysUtils, System.SyncObjs, System.IniFiles, System.Math, System.TypInfo,
  ProRock.Utility;

const
  cProRockVersion = '1.1.0';

  // TBasite.AutoInitMaxDepth range: 1 - library code relies on non-recursive paths (e.g. Envelope.Body); 5 - pre-created objects
  // grow as (self-references per type) ^ depth, so higher values only eat memory
  cAutoInitMaxDepthMin = 1;
  cAutoInitMaxDepthMax = 5;

  cBasiteDefaultNaming = TNaming.nCamelCase;
  cBasiteListPattern = 'TBasiteList<[A-Za-z0-9_.]+>';
  cBasiteListNameLength = Length('TBasiteList');

type
  TBaseTypeAttribute = class(TCustomAttribute)
  private
    fBaseType: string;
  public
    constructor Create(const aBaseType: string);
    property BaseType: string read fBaseType;
  end;

  TNameAttribute = class(TCustomAttribute)
  private
    fCustomName: string;
  public
    constructor Create(const aCustomName: string);
    property CustomName: string read fCustomName;
  end;

  TDefaultAttribute = class(TCustomAttribute)
  private
    fDefaultValue: variant;
  public
    constructor Create(const aDefaultValue: Int64); overload;
    constructor Create(const aDefaultValue: Extended); overload;
    constructor Create(const aDefaultValue: string); overload;
    constructor Create(const aDefaultValue: boolean); overload;

    property DefaultValue: variant read fDefaultValue;
  end;

  // value is serialized even when it equals the default one
  TRequiredAttribute = class(TCustomAttribute);

  TEnumCaptionAttribute = class(TCustomAttribute)
  private
    fCaption, fCustomCaption: string;
  public
    constructor Create(const aCaption, aCustomCaption: string);
    property Caption: string read fCaption;
    property CustomCaption: string read fCustomCaption;
  end;

  TValueAliasAttribute = class(TCustomAttribute)
  protected
    fAlias: string;
    fValue: variant;
  public
    constructor Create(const aValue: Int64; const aAlias: string); overload;
    constructor Create(const aValue, aAlias: string); overload;
    constructor Create(const aValue: Extended; const aAlias: string); overload;

    property Value: variant read fValue;
    property Alias: string read fAlias;
  end;

  TMeta = class;
  TMetaType = class;
  TMetaClass = class;
  TMetaBasite = class;
  TMetaBasiteList = class;
  TBasiteClass = class of TBasite;

  TBasite = class abstract(TPersistent)
  private
    class var fAutoInitMaxDepth: cardinal;

    class constructor Create;
    class procedure SetAutoInitMaxDepth(aValue: cardinal); static;
  public
    class function ClassParent: TBasiteClass; inline;
    class function Meta: TMetaBasite;

    // How often one type may occur on a path when nested objects are created with their parent (auto-init); a self-nested
    // type is cut there (nil), so the init ends. Only for init: reading creates whatever the data contains.
    // 1 (default) - each type once per path, recursion is never pre-created; 2 - one self-nested level pre-created, and so on.
    // Values outside cAutoInitMaxDepthMin..cAutoInitMaxDepthMax are clamped. One global value for all descendants (also
    // reached as TXmlite.AutoInitMaxDepth); set it once at startup, not while other threads create objects
    class property AutoInitMaxDepth: cardinal read fAutoInitMaxDepth write SetAutoInitMaxDepth;

  private
    constructor CreateNested(aBreadcrumbs: TSummaryDictionary<TMetaBasite>);
    procedure CreateProperties(aBreadcrumbs: TSummaryDictionary<TMetaBasite>);
  protected
    procedure Initialize; virtual;
    procedure Deinitialize; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    function ClassType: TBasiteClass;
    procedure Clear; virtual;
    function IsEmptyOrDefault: boolean; virtual;
    function AssignProperty(const aName, aValue: string): boolean; inline;
  end;

  PBasite = ^TBasite;

  TBasiteList<T: TBasite, constructor> = class(TObjectList<T>)
  public
    class function Meta: TMetaBasiteList; inline;
  public
    constructor Create; reintroduce; virtual;

    function IsEmpty: boolean; inline;
    procedure Clear; reintroduce; virtual;
  end;

  TBasiteList = TBasiteList<TBasite>;
  PBasiteList = ^TBasiteList;

  TPropertyType = (ptNotSupported, ptData, ptBasite, ptBasiteList { , ptDataList, ptDataArray, ptBasiteArray } );

  TPropertyExtension = class;

  TProperty = class abstract
  private
    fParentMeta: TMetaBasite;
    fName: string;
    fMeta: TMeta;
    fRttiProperty: TRttiProperty;
    fPropertyType: TPropertyType;
    fIsInherited: boolean;
    fExtensions: TObjectList<TPropertyExtension>;

    fFieldOffset: cardinal;
    fGetterIsField, fSetterIsField: boolean;
    fGetterAddress, fSetterAddress: Pointer;
  public
    constructor Create(aParentMeta: TMetaBasite; aProperty: TRttiProperty; aIsInherited: boolean = False;
      aNaming: TNaming = cBasiteDefaultNaming); virtual;
    destructor Destroy; override;

    property ParentMeta: TMetaBasite read fParentMeta;
    property Name: string read fName;
    property RttiProperty: TRttiProperty read fRttiProperty;
    property Meta: TMeta read fMeta;
    property PropertyType: TPropertyType read fPropertyType;
    property IsInherited: boolean read fIsInherited;
    property Extensions: TObjectList<TPropertyExtension> read fExtensions; // todo: needs protection

    function DataPointer(aObject: TBasite): Pointer; inline;
  end;

  TPropertyData = class(TProperty)
  private type
    // a getter/setter is called with its own declared type: the result/parameter registers differ per float type, and an
    // ordinal getter of a smaller type leaves the upper bits of the result undefined (cut by the ordinal type after the call)
    TGetterInteger = function: integer of object;
    TGetterInt64 = function: Int64 of object;
    TGetterSingle = function: Single of object;
    TGetterDouble = function: Double of object;
    TGetterExtended = function: Extended of object;
    TGetterComp = function: Comp of object;
    TGetterCurrency = function: Currency of object;
    TGetterString = function: string of object;

    TSetterInteger = procedure(const aValue: integer) of object;
    TSetterInt64 = procedure(const aValue: Int64) of object;
    TSetterSingle = procedure(const aValue: Single) of object;
    TSetterDouble = procedure(const aValue: Double) of object;
    TSetterExtended = procedure(const aValue: Extended) of object;
    TSetterComp = procedure(const aValue: Comp) of object;
    TSetterCurrency = procedure(const aValue: Currency) of object;
    TSetterString = procedure(const aValue: string) of object;
  private
    fDefault: variant;
    fRequired: boolean;

    function MethodAddress(aObject: TBasite; aMethod: Pointer): Pointer; inline;
    function GetterMethod(aObject: TBasite): TMethod; inline;
    function SetterMethod(aObject: TBasite): TMethod; inline;

    // tkInteger and tkEnumeration by their ordinal type, tkInt64 (UInt64 as its bits)
    function ReadOrdinal(aObject: TBasite; aFieldData: Pointer): Int64;
    procedure WriteOrdinal(aObject: TBasite; aFieldData: Pointer; aValue: Int64);
    // tkFloat by its float type, except Currency (Extended is only a Double on Win64 and would lose Currency's digits)
    function ReadFloat(aObject: TBasite; aFieldData: Pointer): Extended;
    procedure WriteFloat(aObject: TBasite; aFieldData: Pointer; const aValue: Extended);
    function ReadCurrency(aObject: TBasite; aFieldData: Pointer): Currency;
    procedure WriteCurrency(aObject: TBasite; aFieldData: Pointer; const aValue: Currency);

    function GetValue(aObject: TBasite): string;
    procedure SetValue(aObject: TBasite; const aValue: string);
    function GetMeta: TMetaType;
  public
    constructor Create(aParentMeta: TMetaBasite; aProperty: TRttiProperty; aIsInherited: boolean = False;
      aNaming: TNaming = cBasiteDefaultNaming); override;

    property Meta: TMetaType read GetMeta;
    property Value[aObject: TBasite]: string read GetValue write SetValue;
    property Required: boolean read fRequired;

    procedure SetDefaultValue(aObject: TBasite);
    function ValueIsDefault(aObject: TBasite): boolean;
  end;

  TPropertyClass = class abstract(TProperty)
  private
    function GetMeta: TMetaClass;
    function GetTypeClass: TClass;
  public
    property Meta: TMetaClass read GetMeta;
    property TypeClass: TClass read GetTypeClass;

    function ObjectPointer(aParentObject: TBasite): PObject;
  end;

  TPropertyBasite = class(TPropertyClass)
  private
    function GetMeta: TMetaBasite;
    function GetTypeClass: TBasiteClass;
  public
    constructor Create(aParentMeta: TMetaBasite; aProperty: TRttiProperty; aIsInherited: boolean = False;
      aNaming: TNaming = cBasiteDefaultNaming); override;

    property Meta: TMetaBasite read GetMeta;
    property TypeClass: TBasiteClass read GetTypeClass;

    function ObjectPointer(aParentObject: TBasite): PBasite;
  end;

  TPropertyBasiteList = class(TPropertyClass)
  private
    function GetMeta: TMetaBasiteList;
  public
    constructor Create(aParentMeta: TMetaBasite; aProperty: TRttiProperty; aIsInherited: boolean = False;
      aNaming: TNaming = cBasiteDefaultNaming); override;

    property Meta: TMetaBasiteList read GetMeta;

    function ObjectPointer(aParentObject: TBasite): PBasiteList;
  end;

  TPropertyExtension = class abstract
  private
    fProperty: TProperty;
  public
    constructor Create(aProperty: TProperty); virtual;

    property PropertyInfo: TProperty read fProperty;
  end;

  TPropertyList = class(TObjectList<TProperty>)
  private
    fParentMeta: TMetaBasite;
    fHashedList: TDictionary<string, TProperty>;
  public
    constructor Create(aParentMeta: TMetaBasite); reintroduce;
    destructor Destroy; override;

    function Add(aProperty: TProperty): integer; reintroduce;
    function Get(const aName: string; var aProperty: TProperty): boolean; inline;
  end;

  TMetaExtension = class;

  TMeta = class abstract
  private
    fRttiType: TRttiType;
    fIsSystem: boolean;
    fNaming: TNaming;
    fSimplifiedName, fFullName, fUnitQualifiedName: string;
    fExtensions: TObjectList<TMetaExtension>;
  public
    constructor Create(aRttiType: TRttiType); virtual;
    destructor Destroy; override;

    property RttiType: TRttiType read fRttiType;
    property IsSystem: boolean read fIsSystem;
    property Naming: TNaming read fNaming;
    property SimplifiedName: string read fSimplifiedName;
    property FullName: string read fFullName;
    property UnitQualifiedName: string read fUnitQualifiedName;
    property Extensions: TObjectList<TMetaExtension> read fExtensions; // todo: needs protection
  end;

  TMetaType = class(TMeta)
  private
    fValuesAliases: TDualDictionary<variant, string>;
    fOrdType: TOrdType;      // tkInteger, tkEnumeration
    fFloatType: TFloatType;  // tkFloat
    fUnsigned: boolean;      // tkInt64: UInt64
    fEnumNames: THashedStringList;
    fBaseType: TMetaType;
    function GetEnumName(aEnumValue: integer): string;
  public
    constructor Create(aType: PTypeInfo); reintroduce;
    destructor Destroy; override;

    property BaseType: TMetaType read fBaseType;
    property ValuesAliases: TDualDictionary<variant, string> read fValuesAliases;

    // todo: consider moving that to a separate Enum-info class
    property EnumName[aEnumValue: integer]: string read GetEnumName;
    function EnumValueDef(const aEnumName: string; aDefault: integer = 0): integer;

    function IsSystemType: boolean; inline;
  end;

  TMetaClass = class abstract(TMeta)
  private
    fClassItself: TClass;
    fCreateMethod: TRttiMethod;

    procedure SaveMetaClass(aClass: TClass; aMeta: TMetaClass); inline;
  public
    constructor Create(aClass: TClass); reintroduce; virtual;

    property ClassItself: TClass read fClassItself;
    property CreateMethod: TRttiMethod read fCreateMethod;
  end;

  TMetaBasite = class(TMetaClass)
  private
    fProperties: TPropertyList;

    function GetClassItself: TBasiteClass;
  public
    constructor Create(aClass: TBasiteClass); reintroduce; virtual;
    destructor Destroy; override;

    property ClassItself: TBasiteClass read GetClassItself;
    property Properties: TPropertyList read fProperties;
  end;

  TMetaBasiteList = class(TMetaClass)
  private
    fItemMeta: TMetaBasite;
  public
    property ItemMeta: TMetaBasite read fItemMeta;
  end;

  TMetaExtension = class abstract
  private
    fMeta: TMeta;
  public
    constructor Create(aMeta: TMeta); virtual;

    property Meta: TMeta read fMeta;
  end;

  TMetaBankExtension = class abstract
  private
    fIndex: cardinal;
  public
    constructor Create; virtual;

    property ExtensionIndex: cardinal read fIndex;

    function ItemCreate(aMeta: TMeta): TMetaExtension; virtual; abstract;
    function PropertyCreate(aProperty: TProperty): TPropertyExtension; virtual; abstract;
  public
    class procedure RegisterExtension;
  end;

  TMetaBankExtensionClass = class of TMetaBankExtension;

  TMetaBank = class sealed
  private
    class var fRttiContext: TRttiContext;

    class constructor Create;
    class destructor Destroy;

    class procedure CreateExtensions(aMeta: TMeta); overload;
    class procedure CreateExtensions(aProperty: TProperty); overload;
  protected
    class var Instance: TMetaBank;
  public
    class property RttiContext: TRttiContext read fRttiContext;

    class function GetMeta(aClass: TClass): TMeta; inline;

    class function RegisterType(aType: PTypeInfo): TMetaType;
    class function RegisterClass(aClass: TBasiteClass): TMetaBasite;
    class function RegisterList(aListClass: TClass): TMetaBasiteList;
    class function RegisterExtension(aClass: TMetaBankExtensionClass): TMetaBankExtension;

  public
    Locker: TCriticalSection;
    Items: TObjectDictionary<Pointer, TMeta>;
    Extensions: TObjectList<TMetaBankExtension>;

    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses System.Types, System.RegularExpressions, System.StrUtils, System.Variants,
  {$IFDEF MSWINDOWS}Winapi.Windows{$ENDIF}{$IFDEF POSIX}Posix.SysMman, Posix.Unistd{$ENDIF};

function GetBasiteListClass(aClass: TClass): TClass;
begin
  if (aClass = TObject) or (aClass = nil) then
    Result := nil
  else if TRegEx.IsMatch(aClass.ClassName, cBasiteListPattern) then
    Result := aClass
  else
    Result := GetBasiteListClass(aClass.ClassParent);
end;

function ReadOrdinalFieldValue(aFieldData: Pointer; aOrdType: TOrdType): Int64; inline;
begin
  case aOrdType of
    otUByte:
      Result := System.Types.PByte(aFieldData)^;
    otSByte:
      Result := System.PShortInt(aFieldData)^;
    otUWord:
      Result := System.PWord(aFieldData)^;
    otSWord:
      Result := System.PSmallInt(aFieldData)^;
    otSLong:
      Result := System.PInteger(aFieldData)^;
    otULong:
      Result := System.PCardinal(aFieldData)^;
  else
    Result := 0;
  end;
end;

procedure WriteOrdinalFieldValue(aFieldData: Pointer; aOrdType: TOrdType; aValue: Int64); inline;
begin
  case aOrdType of
    otUByte:
      System.Types.PByte(aFieldData)^ := Byte(aValue);
    otSByte:
      System.PShortInt(aFieldData)^ := ShortInt(aValue);
    otUWord:
      System.PWord(aFieldData)^ := Word(aValue);
    otSWord:
      System.PSmallInt(aFieldData)^ := SmallInt(aValue);
    otSLong:
      System.PInteger(aFieldData)^ := Integer(aValue);
    otULong:
      System.PCardinal(aFieldData)^ := Cardinal(aValue);
  end;
end;

// a getter of a smaller ordinal type leaves the upper bits of the integer result undefined
function OrdinalOfType(aValue: integer; aOrdType: TOrdType): Int64; inline;
begin
  case aOrdType of
    otUByte:
      Result := Byte(aValue);
    otSByte:
      Result := ShortInt(aValue);
    otUWord:
      Result := Word(aValue);
    otSWord:
      Result := SmallInt(aValue);
    otULong:
      Result := Cardinal(aValue);
  else
    Result := aValue;
  end;
end;

function OrdinalFitsType(aValue: Int64; aOrdType: TOrdType): boolean; inline;
begin
  case aOrdType of
    otUByte:
      Result := (aValue >= 0) and (aValue <= High(Byte));
    otSByte:
      Result := (aValue >= Low(ShortInt)) and (aValue <= High(ShortInt));
    otUWord:
      Result := (aValue >= 0) and (aValue <= High(Word));
    otSWord:
      Result := (aValue >= Low(SmallInt)) and (aValue <= High(SmallInt));
    otSLong:
      Result := (aValue >= Low(Integer)) and (aValue <= High(Integer));
    otULong:
      Result := (aValue >= 0) and (aValue <= High(Cardinal));
  else
    Result := False;
  end;
end;

{ TNameAttribute }

constructor TNameAttribute.Create(const aCustomName: string);
begin
  fCustomName := aCustomName;
end;

{ TDefaultAttribute }

constructor TDefaultAttribute.Create(const aDefaultValue: Int64);
begin
  fDefaultValue := aDefaultValue;
end;

constructor TDefaultAttribute.Create(const aDefaultValue: Extended);
begin
  fDefaultValue := aDefaultValue;
end;

constructor TDefaultAttribute.Create(const aDefaultValue: string);
begin
  fDefaultValue := aDefaultValue;
end;

constructor TDefaultAttribute.Create(const aDefaultValue: boolean);
begin
  fDefaultValue := aDefaultValue;
end;

{ TEnumCaptionAttribute }

constructor TEnumCaptionAttribute.Create(const aCaption, aCustomCaption: string);
begin
  fCaption := aCaption;
  fCustomCaption := aCustomCaption;
end;

{ TValueAliasAttribute }

constructor TValueAliasAttribute.Create(const aValue: Int64; const aAlias: string);
begin
  fValue := aValue;
  fAlias := aAlias;
end;

constructor TValueAliasAttribute.Create(const aValue, aAlias: string);
begin
  fValue := aValue;
  fAlias := aAlias;
end;

constructor TValueAliasAttribute.Create(const aValue: Extended; const aAlias: string);
begin
  fValue := aValue;
  fAlias := aAlias;
end;

{ TBasite }

function TBasite.AssignProperty(const aName, aValue: string): boolean;
begin
  Result := False;

  var propertyInfo: TProperty;
  if Meta.Properties.Get(aName, propertyInfo) and (propertyInfo.PropertyType = ptData) then
  begin
    TPropertyData(propertyInfo).Value[Self] := aValue;
    Result := True;
  end;
end;

class function TBasite.ClassParent: TBasiteClass;
begin
  if Self = TBasite then
    Result := nil
  else
    Result := TBasiteClass(inherited ClassParent);
end;

function TBasite.ClassType: TBasiteClass;
begin
  Result := TBasiteClass(inherited ClassType);
end;

procedure TBasite.Clear;
begin
  for var propertyInfo: TProperty in Meta.Properties do
    case propertyInfo.PropertyType of
      ptBasiteList:
        if TPropertyBasiteList(propertyInfo).ObjectPointer(Self)^ <> nil then
          TPropertyBasiteList(propertyInfo).ObjectPointer(Self).Clear;
      ptBasite: // nil - not pre-created (AutoInitMaxDepth) and not read
        if TPropertyBasite(propertyInfo).ObjectPointer(Self)^ <> nil then
          TPropertyBasite(propertyInfo).ObjectPointer(Self).Clear;
      ptData:
        TPropertyData(propertyInfo).SetDefaultValue(Self);
    end;
end;

constructor TBasite.CreateNested(aBreadcrumbs: TSummaryDictionary<TMetaBasite>);
begin
  CreateProperties(aBreadcrumbs);

  Initialize;
end;

procedure TBasite.CreateProperties(aBreadcrumbs: TSummaryDictionary<TMetaBasite>);
begin
  for var propertyInfo in Meta.Properties do
    case propertyInfo.PropertyType of
      ptBasite:
        begin
          var propertyBasite: TPropertyBasite := TPropertyBasite(propertyInfo);
          if aBreadcrumbs.Increase(propertyBasite.Meta) <= fAutoInitMaxDepth then
            propertyBasite.ObjectPointer(Self)^ := propertyBasite.Meta.ClassItself.CreateNested(aBreadcrumbs);
          aBreadcrumbs.Decrease(propertyBasite.Meta);
        end;
      ptBasiteList:
        begin
          var propertyBasiteList: TPropertyBasiteList := TPropertyBasiteList(propertyInfo);
          if Assigned(propertyBasiteList.Meta.CreateMethod) then
            propertyBasiteList.ObjectPointer(Self)^ :=
              TBasiteList(propertyBasiteList.Meta.CreateMethod.Invoke(propertyBasiteList.Meta.ClassItself, []).AsObject);
        end;
      ptData:
        TPropertyData(propertyInfo).SetDefaultValue(Self);
    end;
end;

class constructor TBasite.Create;
begin
  fAutoInitMaxDepth := cAutoInitMaxDepthMin;
end;

constructor TBasite.Create;
begin
  var breadcrumbs: TSummaryDictionary<TMetaBasite> := TSummaryDictionary<TMetaBasite>.Create(Meta);
  CreateProperties(breadcrumbs);
  breadcrumbs.Free;

  Initialize;
end;

procedure TBasite.Deinitialize;
begin
end;

destructor TBasite.Destroy;
begin
  Deinitialize;

  for var propertyInfo in Meta.Properties do
    if propertyInfo.PropertyType in [ptBasite, ptBasiteList] then
      TPropertyClass(propertyInfo).ObjectPointer(Self).Free;
  inherited;
end;

class procedure TBasite.SetAutoInitMaxDepth(aValue: cardinal);
begin
  if aValue < cAutoInitMaxDepthMin then
    fAutoInitMaxDepth := cAutoInitMaxDepthMin
  else if aValue > cAutoInitMaxDepthMax then
    fAutoInitMaxDepth := cAutoInitMaxDepthMax
  else
    fAutoInitMaxDepth := aValue;
end;

class function TBasite.Meta: TMetaBasite;
begin
  Result := TMetaBasite(Pointer(NativeInt(Self) + vmtAutoTable)^);
  if Result = nil then
    Result := TMetaBank.RegisterClass(Self);
end;

procedure TBasite.Initialize;
begin
end;

function TBasite.IsEmptyOrDefault: boolean;
begin
  Result := True;

  for var propertyInfo in Meta.Properties do
  begin
    case propertyInfo.PropertyType of
      ptData:
        Result := TPropertyData(propertyInfo).ValueIsDefault(Self);
      ptBasite:
        if TPropertyBasite(propertyInfo).ObjectPointer(Self)^ <> nil then
          Result := TPropertyBasite(propertyInfo).ObjectPointer(Self).IsEmptyOrDefault;
      ptBasiteList:
        if TPropertyBasiteList(propertyInfo).ObjectPointer(Self)^ <> nil then
          Result := TPropertyBasiteList(propertyInfo).ObjectPointer(Self).Count = 0;
    end;
    if not Result then
      Exit;
  end;
end;

{ TBasiteList<T> }

procedure TBasiteList<T>.Clear;
begin
  inherited;
end;

constructor TBasiteList<T>.Create;
begin
  inherited;
end;

function TBasiteList<T>.IsEmpty: boolean;
begin
  Result := Count = 0;
end;

class function TBasiteList<T>.Meta: TMetaBasiteList;
begin
  Result := TMetaBasiteList(Pointer(NativeInt(Self) + vmtAutoTable)^);
  if Result = nil then
    Result := TMetaBank.RegisterList(Self);
end;

{ TProperty }

constructor TProperty.Create(aParentMeta: TMetaBasite; aProperty: TRttiProperty; aIsInherited: boolean; aNaming: TNaming);
begin
  for var attribute: TCustomAttribute in aProperty.GetAttributes do
    if attribute.ClassType = TNameAttribute then
    begin
      fName := TNameAttribute(attribute).CustomName;
      break;
    end;
  if fName.IsEmpty then
    fName := TUtility.FromPascalCase(aProperty.Name, aNaming);

  fParentMeta := aParentMeta;
  fRttiProperty := aProperty;
  fIsInherited := aIsInherited;

  fExtensions := TObjectList<TPropertyExtension>.Create;

  fGetterAddress := TRttiInstanceProperty(fRttiProperty).PropInfo.GetProc;
  fGetterIsField := (IntPtr(fGetterAddress) and PROPSLOT_MASK) = PROPSLOT_FIELD;

  fSetterAddress := TRttiInstanceProperty(fRttiProperty).PropInfo.SetProc;
  fSetterIsField := (fSetterAddress <> nil) and ((IntPtr(fSetterAddress) and PROPSLOT_MASK) = PROPSLOT_FIELD);

  if (fPropertyType in [ptBasite, ptBasiteList]) or ((fPropertyType = ptData) and fGetterIsField) then
    fFieldOffset := NativeInt(fGetterAddress) and $00FFFFFF
  else if (fPropertyType = ptData) and fSetterIsField then
    fFieldOffset := NativeInt(fSetterAddress) and $00FFFFFF;
end;

function TProperty.DataPointer(aObject: TBasite): Pointer;
begin
  if fFieldOffset > 0 then
    Result := Pointer(NativeInt(aObject) + NativeInt(fFieldOffset))
  else
    Result := nil;
end;

destructor TProperty.Destroy;
begin
  fExtensions.Free;
  inherited;
end;

{ TPropertyData }

constructor TPropertyData.Create(aParentMeta: TMetaBasite; aProperty: TRttiProperty; aIsInherited: boolean; aNaming: TNaming);
begin
  fPropertyType := ptData;
  inherited;

  fMeta := TMetaBank.RegisterType(RttiProperty.PropertyType.Handle);

  var defaultIsDefined: boolean := False;
  for var attribute: TCustomAttribute in aProperty.GetAttributes do
    if attribute.ClassType = TDefaultAttribute then
    begin
      var defaultAttribute: TDefaultAttribute := TDefaultAttribute(attribute);
      if VarType(defaultAttribute.DefaultValue) = varBoolean then
        fDefault := Byte(defaultAttribute.DefaultValue)
      else
        fDefault := defaultAttribute.DefaultValue;

      defaultIsDefined := True;
    end
    else if attribute.ClassType = TRequiredAttribute then
      fRequired := True;

  if not defaultIsDefined then
    case fRttiProperty.PropertyType.TypeKind of
      tkInteger, tkInt64, tkFloat, tkEnumeration:
        fDefault := 0;
      tkUString:
        fDefault := '';
    end;
end;

function TPropertyData.GetMeta: TMetaType;
begin
  Result := TMetaType(inherited Meta);
end;

function TPropertyData.GetterMethod(aObject: TBasite): TMethod;
begin
  Result.Code := MethodAddress(aObject, fGetterAddress);
  Result.Data := aObject;
end;

function TPropertyData.GetValue(aObject: TBasite): string;

  function TryGetAliasForValue(aValuesAliases: TDualDictionary<variant, string>; const aValue: variant; out aAlias: string)
    : boolean; inline;
  begin
    if aValuesAliases.Count = 0 then
      Exit(False);

    Result := aValuesAliases.TryGetValueByKey(aValue, aAlias);
  end;

begin
  Result := '';
  if (aObject = nil) or (fPropertyType <> ptData) then
    Exit;

  var fieldData: Pointer := DataPointer(aObject);
  if fGetterIsField and (fieldData = nil) then
    Exit;

  case fRttiProperty.PropertyType.TypeKind of
    tkInteger, tkInt64:
      begin
        var ordinalValue: Int64 := ReadOrdinal(aObject, fieldData);
        if Meta.fUnsigned then
        begin
          if not TryGetAliasForValue(Meta.ValuesAliases, UInt64(ordinalValue), Result) then
            Result := UIntToStr(UInt64(ordinalValue));
        end
        else if not TryGetAliasForValue(Meta.ValuesAliases, ordinalValue, Result) then
          Result := IntToStr(ordinalValue);
      end;
    tkFloat:
      if Meta.fFloatType = ftCurr then
      begin
        var currencyValue: Currency := ReadCurrency(aObject, fieldData);
        if not TryGetAliasForValue(Meta.ValuesAliases, currencyValue, Result) then
          Result := CurrToStr(currencyValue, FormatSettings.Invariant);
      end
      else
      begin
        var floatValue: Extended := ReadFloat(aObject, fieldData);
        if not TryGetAliasForValue(Meta.ValuesAliases, floatValue, Result) then
          if Meta.fFloatType = ftSingle then // Single digits only: 0.1 stays 0.1, not 0.100000001490116
            Result := FloatToStrF(floatValue, ffGeneral, 7, 0, FormatSettings.Invariant)
          else
            Result := FloatToStr(floatValue, FormatSettings.Invariant);
      end;
    tkUString:
      begin
        if fGetterIsField then
          Result := PUnicodeString(fieldData)^
        else
          Result := TGetterString(GetterMethod(aObject));

        if Meta.ValuesAliases.Count > 0 then
        begin
          var Alias: string;
          if Meta.ValuesAliases.TryGetValueByKey(Result, Alias) then
            Result := Alias;
        end;
      end;
    tkEnumeration:
      begin
        var enumValue: integer := ReadOrdinal(aObject, fieldData);
        if not TryGetAliasForValue(Meta.ValuesAliases, enumValue, Result) then
          Result := Meta.EnumName[enumValue];
      end;
  end;
end;

function TPropertyData.MethodAddress(aObject: TBasite; aMethod: Pointer): Pointer;
begin
  // some info: https://theroadtodelphi.com/2015/09/25/getting-the-getter-and-setter-of-a-property-using-rtti/
  if (IntPtr(aMethod) and PROPSLOT_MASK) = PROPSLOT_VIRTUAL then // virtual
    Result := PPointer(PNativeUInt(aObject)^ + (UIntPtr(aMethod) and $FFFF))^
  else // static
    Result := Pointer(aMethod);
end;

function TPropertyData.ReadCurrency(aObject: TBasite; aFieldData: Pointer): Currency;
begin
  if fGetterIsField then
    Result := PCurrency(aFieldData)^
  else
    Result := TGetterCurrency(GetterMethod(aObject));
end;

function TPropertyData.ReadFloat(aObject: TBasite; aFieldData: Pointer): Extended;
begin
  if fGetterIsField then
    case Meta.fFloatType of
      ftSingle:
        Result := PSingle(aFieldData)^;
      ftDouble:
        Result := PDouble(aFieldData)^;
      ftComp:
        Result := PComp(aFieldData)^;
    else
      Result := PExtended(aFieldData)^;
    end
  else
    case Meta.fFloatType of
      ftSingle:
        Result := TGetterSingle(GetterMethod(aObject));
      ftDouble:
        Result := TGetterDouble(GetterMethod(aObject));
      ftComp:
        Result := TGetterComp(GetterMethod(aObject));
    else
      Result := TGetterExtended(GetterMethod(aObject));
    end;
end;

function TPropertyData.ReadOrdinal(aObject: TBasite; aFieldData: Pointer): Int64;
begin
  if fRttiProperty.PropertyType.TypeKind = tkInt64 then
  begin
    if fGetterIsField then
      Result := PInt64(aFieldData)^
    else
      Result := TGetterInt64(GetterMethod(aObject));
  end
  else if fGetterIsField then
    Result := ReadOrdinalFieldValue(aFieldData, Meta.fOrdType)
  else
    Result := OrdinalOfType(TGetterInteger(GetterMethod(aObject)), Meta.fOrdType);
end;

procedure TPropertyData.SetDefaultValue(aObject: TBasite);
begin
  if (aObject = nil) or (fPropertyType <> ptData) or not fRttiProperty.IsWritable then
    Exit;

  var fieldData: Pointer := DataPointer(aObject);
  if fSetterIsField and (fieldData = nil) then
    Exit;

  case fRttiProperty.PropertyType.TypeKind of
    tkInteger, tkInt64, tkEnumeration:
      WriteOrdinal(aObject, fieldData, fDefault);
    tkFloat:
      if Meta.fFloatType = ftCurr then
        WriteCurrency(aObject, fieldData, fDefault)
      else
        WriteFloat(aObject, fieldData, fDefault);
    tkUString:
      begin
        if fSetterIsField then
          PUnicodeString(fieldData)^ := string(fDefault)
        else
          TSetterString(SetterMethod(aObject))(string(fDefault));
      end;
  end;
end;

function TPropertyData.SetterMethod(aObject: TBasite): TMethod;
begin
  Result.Code := MethodAddress(aObject, fSetterAddress);
  Result.Data := aObject;
end;

procedure TPropertyData.SetValue(aObject: TBasite; const aValue: string);
begin
  if (aObject = nil) or (fPropertyType <> ptData) or not fRttiProperty.IsWritable then
    Exit;

  var fieldData: Pointer := DataPointer(aObject);
  if fSetterIsField and (fieldData = nil) then
    Exit;

  var value: string := aValue;

  if Meta.fValuesAliases.Count > 0 then
  begin
    var aliasValue: variant;
    if Meta.fValuesAliases.TryGetKeyByValue(aValue, aliasValue) then
      value := VarToStr(aliasValue);
  end;

  // text that does not fit the type (not a number, out of its range) gives the default, as invalid text did before
  case fRttiProperty.PropertyType.TypeKind of
    tkInteger:
      begin
        var ordinalValue: Int64;
        if not TryStrToInt64(value, ordinalValue) or not OrdinalFitsType(ordinalValue, Meta.fOrdType) then
          ordinalValue := fDefault;
        WriteOrdinal(aObject, fieldData, ordinalValue);
      end;
    tkInt64:
      if Meta.fUnsigned then
      begin
        var unsignedValue: UInt64;
        if not TryStrToUInt64(value, unsignedValue) then
          unsignedValue := fDefault;
        WriteOrdinal(aObject, fieldData, Int64(unsignedValue));
      end
      else
        WriteOrdinal(aObject, fieldData, StrToInt64Def(value, fDefault));
    tkFloat:
      // parsed into the property's own type: a value out of its range fails here instead of overflowing on assignment
      case Meta.fFloatType of
        ftSingle:
          begin
            var singleValue: Single;
            if not TryStrToFloat(value, singleValue, FormatSettings.Invariant) then
              singleValue := fDefault;
            WriteFloat(aObject, fieldData, singleValue);
          end;
        ftDouble:
          begin
            var doubleValue: Double;
            if not TryStrToFloat(value, doubleValue, FormatSettings.Invariant) then
              doubleValue := fDefault;
            WriteFloat(aObject, fieldData, doubleValue);
          end;
        ftCurr:
          begin
            var currencyValue: Currency;
            if not TryStrToCurr(value, currencyValue, FormatSettings.Invariant) then
              currencyValue := fDefault;
            WriteCurrency(aObject, fieldData, currencyValue);
          end;
      else
        WriteFloat(aObject, fieldData, StrToFloatDef(value, fDefault, FormatSettings.Invariant));
      end;
    tkUString:
      begin
        if fSetterIsField then
          PUnicodeString(fieldData)^ := value
        else
          TSetterString(SetterMethod(aObject))(value);
      end;
    tkEnumeration:
      WriteOrdinal(aObject, fieldData, Meta.EnumValueDef(value, fDefault));
  end;
end;

function TPropertyData.ValueIsDefault(aObject: TBasite): boolean;
begin
  Result := True;

  if (aObject = nil) or (fPropertyType <> ptData) then
    Exit;

  var fieldData: Pointer := DataPointer(aObject);
  if fGetterIsField and (fieldData = nil) then
    Exit;

  case fRttiProperty.PropertyType.TypeKind of
    tkInteger, tkInt64, tkEnumeration:
      Result := ReadOrdinal(aObject, fieldData) = fDefault;
    tkFloat:
      if Meta.fFloatType = ftCurr then
        Result := ReadCurrency(aObject, fieldData) = Currency(fDefault)
      else
        Result := SameValue(ReadFloat(aObject, fieldData), Extended(fDefault));
    tkUString:
      begin
        var stringValue: string;
        if fGetterIsField then
          stringValue := PUnicodeString(fieldData)^
        else
          stringValue := TGetterString(GetterMethod(aObject));
        Result := stringValue = string(fDefault);
      end;
  end;
end;

procedure TPropertyData.WriteCurrency(aObject: TBasite; aFieldData: Pointer; const aValue: Currency);
begin
  if fSetterIsField then
    PCurrency(aFieldData)^ := aValue
  else
    TSetterCurrency(SetterMethod(aObject))(aValue);
end;

procedure TPropertyData.WriteFloat(aObject: TBasite; aFieldData: Pointer; const aValue: Extended);
begin
  if fSetterIsField then
    case Meta.fFloatType of
      ftSingle:
        PSingle(aFieldData)^ := aValue;
      ftDouble:
        PDouble(aFieldData)^ := aValue;
      ftComp:
        PComp(aFieldData)^ := aValue;
    else
      PExtended(aFieldData)^ := aValue;
    end
  else
    case Meta.fFloatType of
      ftSingle:
        TSetterSingle(SetterMethod(aObject))(aValue);
      ftDouble:
        TSetterDouble(SetterMethod(aObject))(aValue);
      ftComp:
        TSetterComp(SetterMethod(aObject))(aValue);
    else
      TSetterExtended(SetterMethod(aObject))(aValue);
    end;
end;

procedure TPropertyData.WriteOrdinal(aObject: TBasite; aFieldData: Pointer; aValue: Int64);
begin
  if fRttiProperty.PropertyType.TypeKind = tkInt64 then
  begin
    if fSetterIsField then
      PInt64(aFieldData)^ := aValue
    else
      TSetterInt64(SetterMethod(aObject))(aValue);
  end
  else if fSetterIsField then
    WriteOrdinalFieldValue(aFieldData, Meta.fOrdType, aValue)
  else // a smaller ordinal parameter takes the low bits of the register
    TSetterInteger(SetterMethod(aObject))(Integer(aValue));
end;

{ TPropertyClass }

function TPropertyClass.GetMeta: TMetaClass;
begin
  Result := TMetaClass(inherited Meta);
end;

function TPropertyClass.GetTypeClass: TClass;
begin
  Result := fRttiProperty.PropertyType.Handle.TypeData.ClassType;
end;

function TPropertyClass.ObjectPointer(aParentObject: TBasite): PObject;
begin
  Result := DataPointer(aParentObject);
end;

{ TPropertyBasite }

constructor TPropertyBasite.Create(aParentMeta: TMetaBasite; aProperty: TRttiProperty; aIsInherited: boolean; aNaming: TNaming);
begin
  fPropertyType := ptBasite;
  inherited;

  fMeta := TypeClass.Meta;
end;

function TPropertyBasite.GetMeta: TMetaBasite;
begin
  Result := TMetaBasite(inherited Meta);
end;

function TPropertyBasite.GetTypeClass: TBasiteClass;
begin
  Result := TBasiteClass(inherited TypeClass);
end;

function TPropertyBasite.ObjectPointer(aParentObject: TBasite): PBasite;
begin
  Result := DataPointer(aParentObject);
end;

{ TPropertyBasiteList }

constructor TPropertyBasiteList.Create(aParentMeta: TMetaBasite; aProperty: TRttiProperty; aIsInherited: boolean; aNaming: TNaming);
begin
  fPropertyType := ptBasiteList;
  inherited;

  fMeta := TMetaBank.GetMeta(TypeClass);
  if fMeta = nil then
    fMeta := TMetaBank.RegisterList(TypeClass);
end;

function TPropertyBasiteList.GetMeta: TMetaBasiteList;
begin
  Result := TMetaBasiteList(inherited Meta);
end;

function TPropertyBasiteList.ObjectPointer(aParentObject: TBasite): PBasiteList;
begin
  Result := DataPointer(aParentObject);
end;

{ TPropertyList }

function TPropertyList.Add(aProperty: TProperty): integer;
begin
  fHashedList.AddOrSetValue(aProperty.Name, aProperty);
  Result := inherited Add(aProperty)
end;

constructor TPropertyList.Create(aParentMeta: TMetaBasite);

  procedure AddProperties(aClass: TBasiteClass; aNaming: TNaming; aIsParentClass: boolean = False);

    function DeterminePropertyType(aProperty: TRttiProperty): TPropertyType; inline;
    begin
      Result := ptNotSupported;

      if (aProperty.Visibility <> mvPublished) or not aProperty.IsReadable then
        Exit;

      if aProperty.PropertyType.TypeKind in [tkInteger, tkInt64, tkFloat, tkUString, tkEnumeration]
      then
        Exit(ptData);

      if aProperty.PropertyType.TypeKind = tkClass then
      begin
        if aProperty.PropertyType.Handle.TypeData.ClassType.InheritsFrom(TBasite) then
          Exit(ptBasite);

        if GetBasiteListClass(aProperty.PropertyType.Handle.TypeData.ClassType) <> nil then
          Exit(ptBasiteList);
      end;
    end;

  begin
    if (aClass.ClassParent <> nil) and (aClass.ClassParent <> TBasite) then
      AddProperties(aClass.ClassParent, aNaming);

    for var rttiProperty: TRttiProperty in TMetaBank.RttiContext.GetType(aClass.ClassInfo).GetDeclaredProperties do
    begin
      var propertyInfo: TProperty;;
      case DeterminePropertyType(rttiProperty) of
        ptBasite:
          propertyInfo := TPropertyBasite.Create(fParentMeta, rttiProperty, not aIsParentClass, aNaming);
        ptBasiteList:
          propertyInfo := TPropertyBasiteList.Create(fParentMeta, rttiProperty, not aIsParentClass, aNaming);
        ptData:
          propertyInfo := TPropertyData.Create(fParentMeta, rttiProperty, not aIsParentClass, aNaming);
      else
        Continue;
      end;
      Add(propertyInfo);
    end;
  end;

begin
  inherited Create;
  fParentMeta := aParentMeta;
  fHashedList := TDictionary<string, TProperty>.Create;

  if fParentMeta.ClassItself.InheritsFrom(TBasite) then
    AddProperties(TBasiteClass(fParentMeta.ClassItself), fParentMeta.Naming, True);
end;

destructor TPropertyList.Destroy;
begin
  fHashedList.Free;
  inherited;
end;

function TPropertyList.Get(const aName: string; var aProperty: TProperty): boolean;
begin
  Result := fHashedList.TryGetValue(aName, aProperty);
end;

{ TMeta }

constructor TMeta.Create(aRttiType: TRttiType);
begin
  fRttiType := aRttiType;
  fSimplifiedName := SimplifiedGenericName(aRttiType.Name);
  fFullName := fRttiType.QualifiedName;

  fUnitQualifiedName := fRttiType.QualifiedName;
  var cursor: PChar := PChar(fUnitQualifiedName) + High(fUnitQualifiedName) - 1;
  while cursor <> PChar(fUnitQualifiedName) do
  begin
    if cursor^ = '.' then
    begin
      cursor^ := #0;
      fUnitQualifiedName := PChar(fUnitQualifiedName);
      cursor^ := '.';
      break;
    end;
    Dec(cursor);
  end;

  fIsSystem := fUnitQualifiedName = 'System';

  fNaming := cBasiteDefaultNaming;
  for var attribute: TCustomAttribute in fRttiType.GetAttributes do
    if attribute.ClassType.InheritsFrom(TNamingAttribute) then
    begin
      fNaming := TNamingAttribute(attribute).Naming;
      break;
    end;

  fExtensions := TObjectList<TMetaExtension>.Create;
end;

destructor TMeta.Destroy;
begin
  fExtensions.Free;
  inherited;
end;

{ TMetaClass }

constructor TMetaClass.Create(aClass: TClass);
begin
  fClassItself := aClass;
  inherited Create(TMetaBank.RttiContext.GetType(fClassItself));
  fCreateMethod := RttiType.GetMethod('Create');

  SaveMetaClass(aClass, Self);
end;

// The meta is cached in the class's own VMT slot (vmtAutoTable), so TBasite.Meta is one pointer read. The VMT is read-only
// memory; if the OS refuses to make it writable, nothing is stored and Meta finds the class through TMetaBank.RegisterClass
// (the registry under a lock) - correct, only slower
procedure TMetaClass.SaveMetaClass(aClass: TClass; aMeta: TMetaClass);
begin
  var slot: PNativeUInt := PNativeUInt(NativeInt(aClass) + vmtAutoTable); // Address of vmtAutoTable slot

  {$IFDEF MSWINDOWS}
  var oldProtect: DWORD;
  if not VirtualProtect(slot, SizeOf(NativeUInt), PAGE_EXECUTE_READWRITE, oldProtect) then // Make the slot writable
    Exit;

  try
    slot^ := NativeUInt(aMeta); // Store meta pointer atomically
  finally
    var dummy: DWORD;
    VirtualProtect(slot, SizeOf(NativeUInt), oldProtect, dummy); // Restore original protection
  end;
  {$ENDIF}
  {$IFDEF POSIX}
  // mprotect works on whole pages. The page stays writable: POSIX cannot tell its original protection, and guessing read-only
  // could break other data on the page; code and data never share a page (ELF segments are page-aligned), so no code is touched
  var pageSize: NativeUInt := sysconf(_SC_PAGESIZE);
  var page: Pointer := Pointer(NativeUInt(slot) and not (pageSize - 1));
  if mprotect(page, NativeUInt(slot) - NativeUInt(page) + SizeOf(NativeUInt), PROT_READ or PROT_WRITE) <> 0 then
    Exit;

  slot^ := NativeUInt(aMeta); // Store meta pointer atomically
  {$ENDIF}
end;

{ TMetaBasite }

constructor TMetaBasite.Create(aClass: TBasiteClass);
begin
  inherited Create(aClass);
  fProperties := TPropertyList.Create(Self);
end;

destructor TMetaBasite.Destroy;
begin
  fProperties.Free;
  inherited;
end;

function TMetaBasite.GetClassItself: TBasiteClass;
begin
  Result := TBasiteClass(inherited ClassItself);
end;

{ TMetaType }

constructor TMetaType.Create(aType: PTypeInfo);
begin
  inherited Create(TMetaBank.RttiContext.GetType(aType));

  for var attribute: TCustomAttribute in RttiType.GetAttributes do
    if attribute.ClassType.InheritsFrom(TBaseTypeAttribute) then
    begin
      var baseTypeAttribute: TBaseTypeAttribute := TBaseTypeAttribute(attribute);

      var baseTypeQualifiedName: string := baseTypeAttribute.BaseType;
      if Pos('.', baseTypeQualifiedName) = 0 then
        baseTypeQualifiedName := UnitQualifiedName + '.' + baseTypeQualifiedName;

      var rttiBaseType: TRttiType := TMetaBank.RttiContext.FindType(baseTypeQualifiedName);
      if rttiBaseType <> nil then
        fBaseType := TMetaBank.RegisterType(rttiBaseType.Handle);
      break;
    end;

  if (fBaseType = nil) and (UnitQualifiedName <> 'System') then
    case RttiType.TypeKind of
      tkUString:
        fBaseType := TMetaBank.RegisterType(TypeInfo(string));
      tkInteger:
        fBaseType := TMetaBank.RegisterType(TypeInfo(integer));
      tkInt64:
        fBaseType := TMetaBank.RegisterType(TypeInfo(Int64));
      tkFloat:
        fBaseType := TMetaBank.RegisterType(TypeInfo(Extended));
      tkEnumeration:
        fBaseType := TMetaBank.RegisterType(TypeInfo(integer));
    end;

  case RttiType.TypeKind of
    tkInteger:
      fOrdType := RttiType.AsOrdinal.OrdType;
    tkInt64: // the RTL's own test for an unsigned 64-bit type (System.TypInfo)
      fUnsigned := GetTypeData(aType).MinInt64Value > GetTypeData(aType).MaxInt64Value;
    tkFloat:
      fFloatType := GetTypeData(aType).FloatType;
  end;

  if RttiType.TypeKind = tkEnumeration then
  begin
    fOrdType := RttiType.AsOrdinal.OrdType;

    fEnumNames := THashedStringList.Create;

    // default captions
    var enums: TRttiOrdinalType := RttiType.AsOrdinal;
    for var i := enums.MinValue to enums.MaxValue do
      fEnumNames.Add(GetEnumerationName(aType, i));

    // custom captions
    for var attribute: TCustomAttribute in RttiType.GetAttributes do
      if attribute.ClassType.InheritsFrom(TEnumCaptionAttribute) then
      begin
        var attrubuteEnumCaption: TEnumCaptionAttribute := TEnumCaptionAttribute(attribute);
        if attrubuteEnumCaption.Caption.IsEmpty or attrubuteEnumCaption.CustomCaption.IsEmpty then
          Continue;

        var elementIndex: integer := fEnumNames.IndexOf(attrubuteEnumCaption.Caption);
        if (elementIndex >= 0) and (fEnumNames.IndexOf(attrubuteEnumCaption.CustomCaption) < 0) then
          fEnumNames[elementIndex] := attrubuteEnumCaption.CustomCaption;
      end;
  end;

  fValuesAliases := TDualDictionary<variant, string>.Create;
  for var attribute: TCustomAttribute in RttiType.GetAttributes do
    if attribute.ClassType.InheritsFrom(TValueAliasAttribute) then
      fValuesAliases.Add(TValueAliasAttribute(attribute).Value, TValueAliasAttribute(attribute).Alias);
end;

destructor TMetaType.Destroy;
begin
  fValuesAliases.Free;
  fEnumNames.Free;
  inherited;
end;

function TMetaType.EnumValueDef(const aEnumName: string; aDefault: integer): integer;
begin
  var enumIndex: integer := fEnumNames.IndexOf(aEnumName);
  Result := IfThen(enumIndex < 0, aDefault, enumIndex);
end;

function TMetaType.GetEnumName(aEnumValue: integer): string;
begin
  if (fEnumNames = nil) or (aEnumValue > fEnumNames.Count - 1) then
    Result := ''
  else
    Result := fEnumNames[aEnumValue];
end;

function TMetaType.IsSystemType: boolean;
begin
  Result := fBaseType = nil;
end;

{ TMetaBank }

constructor TMetaBank.Create;
begin
  if Instance <> nil then
    Exit;

  fRttiContext := TRttiContext.Create;
  Instance := inherited Create;

  Locker := TCriticalSection.Create;
  Items := TObjectDictionary<Pointer, TMeta>.Create([doOwnsValues]);
  Extensions := TObjectList<TMetaBankExtension>.Create;
end;

class procedure TMetaBank.CreateExtensions(aMeta: TMeta);
begin
  if Instance.Extensions.Count = 0 then
    Exit;

  aMeta.Extensions.Clear;
  for var extension: TMetaBankExtension in Instance.Extensions do
    aMeta.Extensions.Add(extension.ItemCreate(aMeta));

  if aMeta.ClassType = TMetaBasite then
    for var propertyInfo: TProperty in TMetaBasite(aMeta).Properties do
      CreateExtensions(propertyInfo);
end;

class constructor TMetaBank.Create;
begin
  TMetaBank.Create;
end;

class procedure TMetaBank.CreateExtensions(aProperty: TProperty);
begin
  if Instance.Extensions.Count = 0 then
    Exit;

  aProperty.Extensions.Clear;
  for var extension: TMetaBankExtension in Instance.Extensions do
    aProperty.Extensions.Add(extension.PropertyCreate(aProperty));
end;

class destructor TMetaBank.Destroy;
begin
  Instance.Free;
end;

destructor TMetaBank.Destroy;
begin
  Locker.Free;
  Extensions.Free;
  Items.Free;
  inherited;
end;

class function TMetaBank.GetMeta(aClass: TClass): TMeta;
begin
  Result := TMeta(Pointer(NativeInt(aClass) + vmtAutoTable)^);
end;

class function TMetaBank.RegisterClass(aClass: TBasiteClass): TMetaBasite;
var meta: TMeta absolute Result;
var metaClass: TMetaClass absolute Result;
begin
  Instance.Locker.Enter;
  try
    if not Instance.Items.TryGetValue(aClass.ClassInfo, meta) or (meta.ClassType <> TMetaBasite) then
    begin
      metaClass := TMetaBasite.Create(aClass);
      Instance.Items.AddOrSetValue(aClass.ClassInfo, metaClass);
      CreateExtensions(metaClass);
    end;
  finally
    Instance.Locker.Leave;
  end;
end;

class function TMetaBank.RegisterExtension(aClass: TMetaBankExtensionClass): TMetaBankExtension;
begin
  Instance.Locker.Enter;
  try
    for var extension in Instance.Extensions do
      if extension.ClassType = aClass then
        Exit(extension); // extension is already registered

    Result := aClass.Create;
    Result.fIndex := Instance.Extensions.Add(Result);
    for var item: TMeta in Instance.Items.Values do
    begin
      item.Extensions.Add(Result.ItemCreate(item));

      if item.ClassType = TMetaBasite then
        for var propertyInfo: TProperty in TMetaBasite(item).Properties do
          propertyInfo.Extensions.Add(Result.PropertyCreate(propertyInfo));
    end;
  finally
    Instance.Locker.Leave;
  end;
end;

class function TMetaBank.RegisterList(aListClass: TClass): TMetaBasiteList;
var meta: TMeta absolute Result;
var metaClass: TMetaClass absolute Result;
begin
  Instance.Locker.Enter;
  try
    if not Instance.Items.TryGetValue(aListClass.ClassInfo, meta) or (meta.ClassType <> TMetaBasiteList) then
    begin
      var listClass: TClass := GetBasiteListClass(aListClass);
      if listClass = nil then // turns out not a TBasiteList class in the end
        Exit;

      var itemClassName: string := PChar(listClass.ClassName) + CBasiteListNameLength + 1;
      SetLength(itemClassName, High(itemClassName) - 1);
      var rttiItemType: TRttiType := RttiContext.FindType(itemClassName);
      if rttiItemType = nil then // means something is wrong with the item class name
        Exit;
      if not rttiItemType.Handle.TypeData.ClassType.InheritsFrom(TBasite) then // that BasiteList contains non-TBasite items
        Exit;

      Result := TMetaBasiteList.Create(aListClass);
      // for supporting self-nested lists TMetaBasiteList should be stored in vmtAutoTable first, only then Itema-Meta is read/initialized
      Result.fItemMeta := TBasiteClass(rttiItemType.Handle.TypeData.ClassType).Meta;

      Instance.Items.AddOrSetValue(aListClass.ClassInfo, metaClass);
      CreateExtensions(metaClass);
    end;
  finally
    Instance.Locker.Leave;
  end;
end;

class function TMetaBank.RegisterType(aType: PTypeInfo): TMetaType;
var
  meta: TMeta absolute Result;
  metaType: TMetaType absolute Result;
begin
  if not(aType.Kind in [tkInteger, tkInt64, tkFloat, tkEnumeration, tkUString]) then
    Exit(nil);

  Instance.Locker.Enter;
  try
    if not Instance.Items.TryGetValue(aType, meta) or (meta.ClassType <> TMetaType) then
    begin
      metaType := TMetaType.Create(aType);
      Instance.Items.AddOrSetValue(aType, metaType);
      CreateExtensions(metaType);
    end;
  finally
    Instance.Locker.Leave;
  end;
end;

{ TMetaExtension }

constructor TMetaExtension.Create(aMeta: TMeta);
begin
  fMeta := aMeta;
end;

{ TMetaBankExtension }

constructor TMetaBankExtension.Create;
begin
  inherited;
end;

class procedure TMetaBankExtension.RegisterExtension;
begin
  TMetaBank.RegisterExtension(Self);
end;

{ TBaseTypeAttribute }

constructor TBaseTypeAttribute.Create(const aBaseType: string);
begin
  fBaseType := aBaseType;
end;

{ TPropertyExtension }

constructor TPropertyExtension.Create(aProperty: TProperty);
begin
  fProperty := aProperty;
end;

end.
