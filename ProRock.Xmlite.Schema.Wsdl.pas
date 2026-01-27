unit ProRock.Xmlite.Schema.Wsdl;

(*
    This unit was automatically generated using ProRocket Lite 1.0.6 (ProRock 1.0.3)
    Generated (UTC): 2026-01-27T23:07:24.674Z
    Namespace: http://schemas.xmlsoap.org/wsdl/
    
    ProRock is a free and open-source Delphi library. Feedback and contributions are welcome.
    https://github.com/VitalyPopov/ProRock
*)


interface

uses
  ProRock.Xmlite, ProRock.Xmlite.Schema.Base;

type

  TArrayTypeA = type ProRock.Xmlite.Schema.Base.TStringST;
  TRequiredA = type ProRock.Xmlite.Schema.Base.TBooleanST;

  TTDocumentationCT = class;
  TTDocumentedCT = class;
  TTExtensibleAttributesDocumentedCT = class;
  TTExtensibleDocumentedCT = class;
  TTDefinitionsCT = class;
  TTImportCT = class;
  TTTypesCT = class;
  TTMessageCT = class;
  TTPartCT = class;
  TTPortTypeCT = class;
  TTOperationCT = class;
  TTParamCT = class;
  TTFaultCT = class;
  TTBindingCT = class;
  TTBindingOperationMessageCT = class;
  TTBindingOperationFaultCT = class;
  TTBindingOperationCT = class;
  TTServiceCT = class;
  TTPortCT = class;
  TTExtensibilityElementCT = class;
  TDefinitionsE = class;
  TAnyTopLevelOptionalElementEG = class;
  TRequestResponseOrOneWayOperationEG = class;
  TSolicitResponseOrNotificationOperationEG = class;

  TTDocumentationCTList = class;
  TTDocumentedCTList = class;
  TTExtensibleAttributesDocumentedCTList = class;
  TTExtensibleDocumentedCTList = class;
  TTDefinitionsCTList = class;
  TTImportCTList = class;
  TTTypesCTList = class;
  TTMessageCTList = class;
  TTPartCTList = class;
  TTPortTypeCTList = class;
  TTOperationCTList = class;
  TTParamCTList = class;
  TTFaultCTList = class;
  TTBindingCTList = class;
  TTBindingOperationMessageCTList = class;
  TTBindingOperationFaultCTList = class;
  TTBindingOperationCTList = class;
  TTServiceCTList = class;
  TTPortCTList = class;
  TTExtensibilityElementCTList = class;
  TDefinitionsEList = class;

  [TXmliteAnyElement]
  TTDocumentationCT = class(TXmliteComplexType);

  TTDocumentedCT = class(TXmliteComplexType)
  private
    fDocumentation: TTDocumentationCT;
  published
    property Documentation: TTDocumentationCT read fDocumentation;
  end;

  TTExtensibleAttributesDocumentedCT = class(TTDocumentedCT);

  [TXmliteAnyElement]
  TTExtensibleDocumentedCT = class(TTDocumentedCT);

  TTDefinitionsCT = class(TTExtensibleDocumentedCT)
  private
    fTargetNamespace: ProRock.Xmlite.Schema.Base.TAnyURIST;
    fName: ProRock.Xmlite.Schema.Base.TNCNameST;
    fImport: TTImportCTList;
    fTypes: TTTypesCTList;
    fMessage: TTMessageCTList;
    fPortType: TTPortTypeCTList;
    fBinding: TTBindingCTList;
    fService: TTServiceCTList;
  published
    property TargetNamespace: ProRock.Xmlite.Schema.Base.TAnyURIST read fTargetNamespace write fTargetNamespace;
    property Name: ProRock.Xmlite.Schema.Base.TNCNameST read fName write fName;
    property Import: TTImportCTList read fImport;
    property Types: TTTypesCTList read fTypes;
    property Message: TTMessageCTList read fMessage;
    property PortType: TTPortTypeCTList read fPortType;
    property Binding: TTBindingCTList read fBinding;
    property Service: TTServiceCTList read fService;
  end;

  TTImportCT = class(TTExtensibleAttributesDocumentedCT)
  private
    fNamespace: ProRock.Xmlite.Schema.Base.TAnyURIST;
    fLocation: ProRock.Xmlite.Schema.Base.TAnyURIST;
  published
    property Namespace: ProRock.Xmlite.Schema.Base.TAnyURIST read fNamespace write fNamespace;
    property Location: ProRock.Xmlite.Schema.Base.TAnyURIST read fLocation write fLocation;
  end;

  TTTypesCT = class(TTExtensibleDocumentedCT);

  TTMessageCT = class(TTExtensibleDocumentedCT)
  private
    fName: ProRock.Xmlite.Schema.Base.TNCNameST;
    fPart: TTPartCTList;
  published
    property Name: ProRock.Xmlite.Schema.Base.TNCNameST read fName write fName;
    property Part: TTPartCTList read fPart;
  end;

  TTPartCT = class(TTExtensibleAttributesDocumentedCT)
  private
    fName: ProRock.Xmlite.Schema.Base.TNCNameST;
    fElement: ProRock.Xmlite.Schema.Base.TQNameST;
    fType: ProRock.Xmlite.Schema.Base.TQNameST;
  published
    property Name: ProRock.Xmlite.Schema.Base.TNCNameST read fName write fName;
    property Element: ProRock.Xmlite.Schema.Base.TQNameST read fElement write fElement;
    property &Type: ProRock.Xmlite.Schema.Base.TQNameST read fType write fType;
  end;

  TTPortTypeCT = class(TTExtensibleAttributesDocumentedCT)
  private
    fName: ProRock.Xmlite.Schema.Base.TNCNameST;
    fOperation: TTOperationCTList;
  published
    property Name: ProRock.Xmlite.Schema.Base.TNCNameST read fName write fName;
    property Operation: TTOperationCTList read fOperation;
  end;

  TTOperationCT = class(TTExtensibleDocumentedCT)
  private
    fName: ProRock.Xmlite.Schema.Base.TNCNameST;
    fParameterOrder: ProRock.Xmlite.Schema.Base.TNmtokensST;
    fInput: TTParamCT;
    fOutput: TTParamCT;
    fFault: TTFaultCTList;
  published
    property Name: ProRock.Xmlite.Schema.Base.TNCNameST read fName write fName;
    property ParameterOrder: ProRock.Xmlite.Schema.Base.TNmtokensST read fParameterOrder write fParameterOrder;
    property Input: TTParamCT read fInput;
    property Output: TTParamCT read fOutput;
    property Fault: TTFaultCTList read fFault;
  end;

  TTParamCT = class(TTExtensibleAttributesDocumentedCT)
  private
    fName: ProRock.Xmlite.Schema.Base.TNCNameST;
    fMessage: ProRock.Xmlite.Schema.Base.TQNameST;
  published
    property Name: ProRock.Xmlite.Schema.Base.TNCNameST read fName write fName;
    property Message: ProRock.Xmlite.Schema.Base.TQNameST read fMessage write fMessage;
  end;

  TTFaultCT = class(TTExtensibleAttributesDocumentedCT)
  private
    fName: ProRock.Xmlite.Schema.Base.TNCNameST;
    fMessage: ProRock.Xmlite.Schema.Base.TQNameST;
  published
    property Name: ProRock.Xmlite.Schema.Base.TNCNameST read fName write fName;
    property Message: ProRock.Xmlite.Schema.Base.TQNameST read fMessage write fMessage;
  end;

  TTBindingCT = class(TTExtensibleDocumentedCT)
  private
    fName: ProRock.Xmlite.Schema.Base.TNCNameST;
    fType: ProRock.Xmlite.Schema.Base.TQNameST;
    fOperation: TTBindingOperationCTList;
  published
    property Name: ProRock.Xmlite.Schema.Base.TNCNameST read fName write fName;
    property &Type: ProRock.Xmlite.Schema.Base.TQNameST read fType write fType;
    property Operation: TTBindingOperationCTList read fOperation;
  end;

  TTBindingOperationMessageCT = class(TTExtensibleDocumentedCT)
  private
    fName: ProRock.Xmlite.Schema.Base.TNCNameST;
  published
    property Name: ProRock.Xmlite.Schema.Base.TNCNameST read fName write fName;
  end;

  TTBindingOperationFaultCT = class(TTExtensibleDocumentedCT)
  private
    fName: ProRock.Xmlite.Schema.Base.TNCNameST;
  published
    property Name: ProRock.Xmlite.Schema.Base.TNCNameST read fName write fName;
  end;

  TTBindingOperationCT = class(TTExtensibleDocumentedCT)
  private
    fName: ProRock.Xmlite.Schema.Base.TNCNameST;
    fInput: TTBindingOperationMessageCT;
    fOutput: TTBindingOperationMessageCT;
    fFault: TTBindingOperationFaultCTList;
  published
    property Name: ProRock.Xmlite.Schema.Base.TNCNameST read fName write fName;
    property Input: TTBindingOperationMessageCT read fInput;
    property Output: TTBindingOperationMessageCT read fOutput;
    property Fault: TTBindingOperationFaultCTList read fFault;
  end;

  TTServiceCT = class(TTExtensibleDocumentedCT)
  private
    fName: ProRock.Xmlite.Schema.Base.TNCNameST;
    fPort: TTPortCTList;
  published
    property Name: ProRock.Xmlite.Schema.Base.TNCNameST read fName write fName;
    property Port: TTPortCTList read fPort;
  end;

  TTPortCT = class(TTExtensibleDocumentedCT)
  private
    fName: ProRock.Xmlite.Schema.Base.TNCNameST;
    fBinding: ProRock.Xmlite.Schema.Base.TQNameST;
  published
    property Name: ProRock.Xmlite.Schema.Base.TNCNameST read fName write fName;
    property Binding: ProRock.Xmlite.Schema.Base.TQNameST read fBinding write fBinding;
  end;

  TTExtensibilityElementCT = class(TXmliteComplexType)
  private
    fRequired: TRequiredA;
  published
    property Required: TRequiredA read fRequired write fRequired;
  end;

  TDefinitionsE = class(TTDefinitionsCT);

  TAnyTopLevelOptionalElementEG = class(TXmliteElementGroup)
  private
    fImport: TTImportCT;
    fTypes: TTTypesCT;
    fMessage: TTMessageCT;
    fPortType: TTPortTypeCT;
    fBinding: TTBindingCT;
    fService: TTServiceCT;
  published
    property Import: TTImportCT read fImport;
    property Types: TTTypesCT read fTypes;
    property Message: TTMessageCT read fMessage;
    property PortType: TTPortTypeCT read fPortType;
    property Binding: TTBindingCT read fBinding;
    property Service: TTServiceCT read fService;
  end;

  [TNaming(TNaming.nKebabCase)]
  TRequestResponseOrOneWayOperationEG = class(TXmliteElementGroup)
  private
    fInput: TTParamCT;
  published
    property Input: TTParamCT read fInput;
  end;

  [TNaming(TNaming.nKebabCase)]
  TSolicitResponseOrNotificationOperationEG = class(TXmliteElementGroup)
  private
    fOutput: TTParamCT;
  published
    property Output: TTParamCT read fOutput;
  end;

  TTDocumentationCTList = class(TXmliteList<TTDocumentationCT>);
  TTDocumentedCTList = class(TXmliteList<TTDocumentedCT>);
  TTExtensibleAttributesDocumentedCTList = class(TXmliteList<TTExtensibleAttributesDocumentedCT>);
  TTExtensibleDocumentedCTList = class(TXmliteList<TTExtensibleDocumentedCT>);
  TTDefinitionsCTList = class(TXmliteList<TTDefinitionsCT>);
  TTImportCTList = class(TXmliteList<TTImportCT>);
  TTTypesCTList = class(TXmliteList<TTTypesCT>);
  TTMessageCTList = class(TXmliteList<TTMessageCT>);
  TTPartCTList = class(TXmliteList<TTPartCT>);
  TTPortTypeCTList = class(TXmliteList<TTPortTypeCT>);
  TTOperationCTList = class(TXmliteList<TTOperationCT>);
  TTParamCTList = class(TXmliteList<TTParamCT>);
  TTFaultCTList = class(TXmliteList<TTFaultCT>);
  TTBindingCTList = class(TXmliteList<TTBindingCT>);
  TTBindingOperationMessageCTList = class(TXmliteList<TTBindingOperationMessageCT>);
  TTBindingOperationFaultCTList = class(TXmliteList<TTBindingOperationFaultCT>);
  TTBindingOperationCTList = class(TXmliteList<TTBindingOperationCT>);
  TTServiceCTList = class(TXmliteList<TTServiceCT>);
  TTPortCTList = class(TXmliteList<TTPortCT>);
  TTExtensibilityElementCTList = class(TXmliteList<TTExtensibilityElementCT>);
  TDefinitionsEList = class(TXmliteList<TDefinitionsE>);

implementation

initialization

TMetaBankXmlite.RegisterNamespace('http://schemas.xmlsoap.org/wsdl/',
  { simpleTypes }
  [],
  { complexTypes }
  [TTDocumentationCT, TTDocumentedCT, TTExtensibleAttributesDocumentedCT, TTExtensibleDocumentedCT, TTDefinitionsCT, TTImportCT,
  TTTypesCT, TTMessageCT, TTPartCT, TTPortTypeCT, TTOperationCT, TTParamCT, TTFaultCT, TTBindingCT, TTBindingOperationMessageCT,
  TTBindingOperationFaultCT, TTBindingOperationCT, TTServiceCT, TTPortCT, TTExtensibilityElementCT],
  { attributes }
  [TypeInfo(TArrayTypeA), TypeInfo(TRequiredA)],
  { attributeGroups }
  [],
  { elements }
  [TDefinitionsE],
  { groups }
  [TAnyTopLevelOptionalElementEG, TRequestResponseOrOneWayOperationEG, TSolicitResponseOrNotificationOperationEG],
  'wsdl');

end.
