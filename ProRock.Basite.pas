unit ProRock.Basite;

interface

{$DEFINE PROROCK}

uses System.Classes, System.Rtti, Generics.Collections, System.SysUtils, System.SyncObjs, System.IniFiles, System.Math, System.TypInfo,
  ProRock.Utility;

const
  cProRockVersion = '1.0.1';

  // Maximum depth for automatic initialization of self-nested TBasite properties.
  // Higher values allow deeper nesting but may slow down initialization.
  cAutoInitMaxDepth = 2;  // todo: recheck - probably something was changed, I don't remember the exact idea of how it should work

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
  public
    class function ClassParent: TBasiteClass; inline;
    class function Meta: TMetaBasite;

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
    TGetterInteger = function: integer of object;
    TGetterInt64 = function: Int64 of object;
    TGetterFloat = function: Extended of object;
    TGetterString = function: string of object;
    TGetterEnum = function: integer of object;

    TSetterInteger = procedure(const aValue: integer) of object;
    TSetterInt64 = procedure(const aValue: Int64) of object;
    TSetterFloat = procedure(const aValue: Extended) of object;
    TSetterString = procedure(const aValue: string) of object;
    TSetterEnum = procedure(const aValue: integer) of object;
  private
    fDefault: variant;

    function MethodAddress(aObject: TBasite; aMethod: Pointer): Pointer; inline;
    function GetterMethod(aObject: TBasite): TMethod; inline;
    function SetterMethod(aObject: TBasite): TMethod; inline;

    function GetValue(aObject: TBasite): string;
    procedure SetValue(aObject: TBasite; const aValue: string);
    function GetMeta: TMetaType;
  public
    constructor Create(aParentMeta: TMetaBasite; aProperty: TRttiProperty; aIsInherited: boolean = False;
      aNaming: TNaming = cBasiteDefaultNaming); override;

    property Meta: TMetaType read GetMeta;
    property Value[aObject: TBasite]: string read GetValue write SetValue;

    procedure SetDefaultValue(aObject: TBasite); inline;
    function ValueIsDefault(aObject: TBasite): boolean; inline;
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
    function Get(const aName: string; out aProperty: TProperty): boolean; inline;
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
    fEnumOrdType: TOrdType;
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

uses System.Types, Winapi.Windows, System.RegularExpressions, System.StrUtils, System.Variants;

function GetBasiteListClass(aClass: TClass): TClass;
begin
  if (aClass = TObject) or (aClass = nil) then
    Result := nil
  else if TRegEx.IsMatch(aClass.ClassName, cBasiteListPattern) then
    Result := aClass
  else
    Result := GetBasiteListClass(aClass.ClassParent);
end;

function ReadEnumFieldValue(aFieldData: Pointer; aOrdType: TOrdType): integer; inline;
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
  else
    Result := 0;
  end;
end;

procedure WriteEnumFieldValue(aFieldData: Pointer; aOrdType: TOrdType; aValue: Integer); inline;
begin
  case aOrdType of
    otUByte:
      System.Types.PByte(aFieldData)^ := aValue;
    otSByte:
      System.PShortInt(aFieldData)^ := aValue;
    otUWord:
      System.PWord(aFieldData)^ := aValue;
    otSWord:
      System.PSmallInt(aFieldData)^ := aValue;
    otSLong:
      System.PInteger(aFieldData)^ := aValue;
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
        TPropertyBasiteList(propertyInfo).ObjectPointer(Self).Clear;
      ptBasite:
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
          if aBreadcrumbs.Increase(propertyBasite.Meta) <= cAutoInitMaxDepth then
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
      break;
    end;

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
    tkInteger:
      begin
        var integerValue: integer;
        if fGetterIsField then
          integerValue := PInteger(fieldData)^
        else
          integerValue := TGetterInteger(GetterMethod(aObject));

        if not TryGetAliasForValue(Meta.ValuesAliases, integerValue, Result) then
          Result := integerValue.ToString;
      end;
    tkInt64:
      begin
        var int64Value: Int64;
        if fGetterIsField then
          int64Value := PInt64(fieldData)^
        else
          int64Value := TGetterInt64(GetterMethod(aObject));

        if not TryGetAliasForValue(Meta.ValuesAliases, int64Value, Result) then
          Result := int64Value.ToString;
      end;
    tkFloat:
      begin
        var floatValue: Extended;
        if fGetterIsField then
          floatValue := PExtended(fieldData)^
        else
          floatValue := TGetterFloat(GetterMethod(aObject));

        if not TryGetAliasForValue(Meta.ValuesAliases, floatValue, Result) then
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
        var enumValue: integer;
        if fGetterIsField then
          enumValue := ReadEnumFieldValue(fieldData, Meta.fEnumOrdType)
        else
          enumValue := TGetterEnum(GetterMethod(aObject));

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

procedure TPropertyData.SetDefaultValue(aObject: TBasite);
begin
  if (aObject = nil) or (fPropertyType <> ptData) or not fRttiProperty.IsWritable then
    Exit;

  var fieldData: Pointer := DataPointer(aObject);
  if fSetterIsField and (fieldData = nil) then
    Exit;

  case fRttiProperty.PropertyType.TypeKind of
    tkInteger:
      begin
        if fSetterIsField then
          PInteger(fieldData)^ := fDefault
        else
          TSetterInteger(SetterMethod(aObject))(fDefault);
      end;
    tkInt64:
      begin
        if fSetterIsField then
          PInt64(fieldData)^ := fDefault
        else
          TSetterInt64(SetterMethod(aObject))(fDefault);
      end;
    tkFloat:
      begin
        if fSetterIsField then
          PExtended(fieldData)^ := fDefault
        else
          TSetterFloat(SetterMethod(aObject))(fDefault);
      end;
    tkUString:
      begin
        if fSetterIsField then
          PUnicodeString(fieldData)^ := string(fDefault)
        else
          TSetterString(SetterMethod(aObject))(string(fDefault));
      end;
    tkEnumeration:
      begin
        if fSetterIsField then
          WriteEnumFieldValue(fieldData, Meta.fEnumOrdType, fDefault)
        else
          TSetterEnum(SetterMethod(aObject))(fDefault);
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

  case fRttiProperty.PropertyType.TypeKind of
    tkInteger:
      begin
        var integerValue: integer := StrToIntDef(value, fDefault);
        if fSetterIsField then
          PInteger(fieldData)^ := integerValue
        else
          TSetterInteger(SetterMethod(aObject))(integerValue);
      end;
    tkInt64:
      begin
        var int64Value: Int64 := StrToInt64Def(value, fDefault);
        if fSetterIsField then
          PInt64(fieldData)^ := int64Value
        else
          TSetterInt64(SetterMethod(aObject))(int64Value);
      end;
    tkFloat:
      begin
        var floatValue: Extended := StrToFloatDef(value, fDefault, FormatSettings.Invariant);
        if fSetterIsField then
          PExtended(fieldData)^ := floatValue
        else
          TSetterFloat(SetterMethod(aObject))(floatValue);
      end;
    tkUString:
      begin
        if fSetterIsField then
          PUnicodeString(fieldData)^ := value
        else
          TSetterString(SetterMethod(aObject))(value);
      end;
    tkEnumeration:
      begin
        var enumValue: integer := Meta.EnumValueDef(value, fDefault);
        if fSetterIsField then
          WriteEnumFieldValue(fieldData, Meta.fEnumOrdType, enumValue)
        else
          TSetterEnum(SetterMethod(aObject))(enumValue);
      end;
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
    tkInteger:
      begin
        var integerValue: integer;
        if fGetterIsField then
          integerValue := PInteger(fieldData)^
        else
          integerValue := TGetterInteger(GetterMethod(aObject));
        Result := integerValue = fDefault;
      end;
    tkInt64:
      begin
        var int64Value: Int64;
        if fGetterIsField then
          int64Value := PInt64(fieldData)^
        else
          int64Value := TGetterInt64(GetterMethod(aObject));
        Result := int64Value = fDefault;
      end;
    tkFloat:
      begin
        var floatValue: Extended;
        if fGetterIsField then
          floatValue := PExtended(fieldData)^
        else
          floatValue := TGetterFloat(GetterMethod(aObject));
        Result := SameValue(floatValue, fDefault);
      end;
    tkUString:
      begin
        var stringValue: string;
        if fGetterIsField then
          stringValue := PUnicodeString(fieldData)^
        else
          stringValue := TGetterString(GetterMethod(aObject));
        Result := stringValue = string(fDefault);
      end;
    tkEnumeration:
      begin
        var enumValue: integer;
        if fGetterIsField then
          enumValue := ReadEnumFieldValue(fieldData, Meta.fEnumOrdType)
        else
          enumValue := TGetterEnum(GetterMethod(aObject));
        Result := enumValue = fDefault;
      end;
  end;
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

      if aProperty.PropertyType.TypeKind in [tkInteger, tkInt64, tkChar, tkFloat, tkUString, tkEnumeration]
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

function TPropertyList.Get(const aName: string; out aProperty: TProperty): boolean;
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

procedure TMetaClass.SaveMetaClass(aClass: TClass; aMeta: TMetaClass);
begin
  var slot: PNativeUInt := PNativeUInt(NativeInt(aClass) + vmtAutoTable); // Address of vmtAutoTable slot

  var oldProtect: DWORD;
  if not VirtualProtect(slot, SizeOf(NativeUInt), PAGE_EXECUTE_READWRITE, oldProtect) then // Make the slot writable
    Exit;

  try
    slot^ := NativeUInt(aMeta); // Store meta pointer atomically
  finally
    var dummy: DWORD;
    VirtualProtect(slot, SizeOf(NativeUInt), oldProtect, dummy); // Restore original protection
  end;
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

  if RttiType.TypeKind = tkEnumeration then
  begin
    fEnumOrdType := RttiType.AsOrdinal.OrdType;

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
