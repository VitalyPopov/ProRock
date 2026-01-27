unit ProRock.Xmlite.Schema.Soap;

(*
    This unit was automatically generated using ProRocket Lite 1.0.6 (ProRock 1.0.3)
    Generated (UTC): 2026-01-27T23:07:24.675Z
    Namespace: http://schemas.xmlsoap.org/wsdl/soap/
    
    ProRock is a free and open-source Delphi library. Feedback and contributions are welcome.
    https://github.com/VitalyPopov/ProRock
*)


interface

uses
  ProRock.Xmlite, ProRock.Xmlite.Schema.Base, ProRock.Xmlite.Schema.Wsdl;

type
  TTStyleChoiceST = (tscRpc, tscDocument);
  TUseChoiceST = (ucLiteral, ucEncoded);

  TEncodingStyleST = type string;

  TTBindingCT = class;
  TTOperationCT = class;
  TTBodyCT = class;
  TTFaultResCT = class;
  TTFaultCT = class;
  TTHeaderCT = class;
  TTHeaderFaultCT = class;
  TTAddressCT = class;
  TTBodyAttributesAG = class;
  TTHeaderAttributesAG = class;
  TBindingE = class;
  TOperationE = class;
  TBodyE = class;
  TFaultE = class;
  THeaderE = class;
  THeaderfaultE = class;
  TAddressE = class;

  TTBindingCTList = class;
  TTOperationCTList = class;
  TTBodyCTList = class;
  TTFaultResCTList = class;
  TTFaultCTList = class;
  TTHeaderCTList = class;
  TTHeaderFaultCTList = class;
  TTAddressCTList = class;
  TBindingEList = class;
  TOperationEList = class;
  TBodyEList = class;
  TFaultEList = class;
  THeaderEList = class;
  THeaderfaultEList = class;
  TAddressEList = class;

  TTBindingCT = class(ProRock.Xmlite.Schema.Wsdl.TTExtensibilityElementCT)
  private
    fTransport: ProRock.Xmlite.Schema.Base.TAnyURIST;
    fStyle: TTStyleChoiceST;
  published
    property Transport: ProRock.Xmlite.Schema.Base.TAnyURIST read fTransport write fTransport;
    property Style: TTStyleChoiceST read fStyle write fStyle;
  end;

  TTOperationCT = class(ProRock.Xmlite.Schema.Wsdl.TTExtensibilityElementCT)
  private
    fSoapAction: ProRock.Xmlite.Schema.Base.TAnyURIST;
    fStyle: TTStyleChoiceST;
  published
    property SoapAction: ProRock.Xmlite.Schema.Base.TAnyURIST read fSoapAction write fSoapAction;
    property Style: TTStyleChoiceST read fStyle write fStyle;
  end;

  TTBodyCT = class(ProRock.Xmlite.Schema.Wsdl.TTExtensibilityElementCT)
  private
    fParts: ProRock.Xmlite.Schema.Base.TNmtokensST;
    fEncodingStyle: TEncodingStyleST;
    fUse: TUseChoiceST;
    fNamespace: ProRock.Xmlite.Schema.Base.TAnyURIST;
  published
    property Parts: ProRock.Xmlite.Schema.Base.TNmtokensST read fParts write fParts;
    property EncodingStyle: TEncodingStyleST read fEncodingStyle write fEncodingStyle;
    property Use: TUseChoiceST read fUse write fUse;
    property Namespace: ProRock.Xmlite.Schema.Base.TAnyURIST read fNamespace write fNamespace;
  end;

  TTFaultResCT = class(TXmliteComplexTypeRestricted)
  private
    fRequired: ProRock.Xmlite.Schema.Wsdl.TRequiredA;
    fEncodingStyle: TEncodingStyleST;
    fUse: TUseChoiceST;
    fNamespace: ProRock.Xmlite.Schema.Base.TAnyURIST;
  published
    property Required: ProRock.Xmlite.Schema.Wsdl.TRequiredA read fRequired write fRequired;
    property EncodingStyle: TEncodingStyleST read fEncodingStyle write fEncodingStyle;
    property Use: TUseChoiceST read fUse write fUse;
    property Namespace: ProRock.Xmlite.Schema.Base.TAnyURIST read fNamespace write fNamespace;
  end;

  TTFaultCT = class(TTFaultResCT)
  private
    fName: ProRock.Xmlite.Schema.Base.TNCNameST;
  published
    property Name: ProRock.Xmlite.Schema.Base.TNCNameST read fName write fName;
  end;

  TTHeaderCT = class(ProRock.Xmlite.Schema.Wsdl.TTExtensibilityElementCT)
  private
    fMessage: ProRock.Xmlite.Schema.Base.TQNameST;
    fPart: ProRock.Xmlite.Schema.Base.TNmtokenST;
    fUse: TUseChoiceST;
    fEncodingStyle: TEncodingStyleST;
    fNamespace: ProRock.Xmlite.Schema.Base.TAnyURIST;
    fHeaderfault: THeaderfaultEList;
  published
    property Message: ProRock.Xmlite.Schema.Base.TQNameST read fMessage write fMessage;
    property Part: ProRock.Xmlite.Schema.Base.TNmtokenST read fPart write fPart;
    property Use: TUseChoiceST read fUse write fUse;
    property EncodingStyle: TEncodingStyleST read fEncodingStyle write fEncodingStyle;
    property Namespace: ProRock.Xmlite.Schema.Base.TAnyURIST read fNamespace write fNamespace;
    property Headerfault: THeaderfaultEList read fHeaderfault;
  end;

  TTHeaderFaultCT = class(TXmliteComplexType)
  private
    fMessage: ProRock.Xmlite.Schema.Base.TQNameST;
    fPart: ProRock.Xmlite.Schema.Base.TNmtokenST;
    fUse: TUseChoiceST;
    fEncodingStyle: TEncodingStyleST;
    fNamespace: ProRock.Xmlite.Schema.Base.TAnyURIST;
  published
    property Message: ProRock.Xmlite.Schema.Base.TQNameST read fMessage write fMessage;
    property Part: ProRock.Xmlite.Schema.Base.TNmtokenST read fPart write fPart;
    property Use: TUseChoiceST read fUse write fUse;
    property EncodingStyle: TEncodingStyleST read fEncodingStyle write fEncodingStyle;
    property Namespace: ProRock.Xmlite.Schema.Base.TAnyURIST read fNamespace write fNamespace;
  end;

  TTAddressCT = class(ProRock.Xmlite.Schema.Wsdl.TTExtensibilityElementCT)
  private
    fLocation: ProRock.Xmlite.Schema.Base.TAnyURIST;
  published
    property Location: ProRock.Xmlite.Schema.Base.TAnyURIST read fLocation write fLocation;
  end;

  TTBodyAttributesAG = class(TXmliteAttributeGroup)
  private
    fEncodingStyle: TEncodingStyleST;
    fUse: TUseChoiceST;
    fNamespace: ProRock.Xmlite.Schema.Base.TAnyURIST;
  published
    property EncodingStyle: TEncodingStyleST read fEncodingStyle write fEncodingStyle;
    property Use: TUseChoiceST read fUse write fUse;
    property Namespace: ProRock.Xmlite.Schema.Base.TAnyURIST read fNamespace write fNamespace;
  end;

  TTHeaderAttributesAG = class(TXmliteAttributeGroup)
  private
    fMessage: ProRock.Xmlite.Schema.Base.TQNameST;
    fPart: ProRock.Xmlite.Schema.Base.TNmtokenST;
    fUse: TUseChoiceST;
    fEncodingStyle: TEncodingStyleST;
    fNamespace: ProRock.Xmlite.Schema.Base.TAnyURIST;
  published
    property Message: ProRock.Xmlite.Schema.Base.TQNameST read fMessage write fMessage;
    property Part: ProRock.Xmlite.Schema.Base.TNmtokenST read fPart write fPart;
    property Use: TUseChoiceST read fUse write fUse;
    property EncodingStyle: TEncodingStyleST read fEncodingStyle write fEncodingStyle;
    property Namespace: ProRock.Xmlite.Schema.Base.TAnyURIST read fNamespace write fNamespace;
  end;

  TBindingE = class(TTBindingCT);

  TOperationE = class(TTOperationCT);

  TBodyE = class(TTBodyCT);

  TFaultE = class(TTFaultCT);

  THeaderE = class(TTHeaderCT);

  THeaderfaultE = class(TTHeaderFaultCT);

  TAddressE = class(TTAddressCT);

  TTBindingCTList = class(TXmliteList<TTBindingCT>);
  TTOperationCTList = class(TXmliteList<TTOperationCT>);
  TTBodyCTList = class(TXmliteList<TTBodyCT>);
  TTFaultResCTList = class(TXmliteList<TTFaultResCT>);
  TTFaultCTList = class(TXmliteList<TTFaultCT>);
  TTHeaderCTList = class(TXmliteList<TTHeaderCT>);
  TTHeaderFaultCTList = class(TXmliteList<TTHeaderFaultCT>);
  TTAddressCTList = class(TXmliteList<TTAddressCT>);
  TBindingEList = class(TXmliteList<TBindingE>);
  TOperationEList = class(TXmliteList<TOperationE>);
  TBodyEList = class(TXmliteList<TBodyE>);
  TFaultEList = class(TXmliteList<TFaultE>);
  THeaderEList = class(TXmliteList<THeaderE>);
  THeaderfaultEList = class(TXmliteList<THeaderfaultE>);
  TAddressEList = class(TXmliteList<TAddressE>);

implementation

initialization

TMetaBankXmlite.RegisterNamespace('http://schemas.xmlsoap.org/wsdl/soap/',
  { simpleTypes }
  [TypeInfo(TEncodingStyleST), TypeInfo(TTStyleChoiceST), TypeInfo(TUseChoiceST)],
  { complexTypes }
  [TTBindingCT, TTOperationCT, TTBodyCT, TTFaultResCT, TTFaultCT, TTHeaderCT, TTHeaderFaultCT, TTAddressCT],
  { attributes }
  [],
  { attributeGroups }
  [TTBodyAttributesAG, TTHeaderAttributesAG],
  { elements }
  [TBindingE, TOperationE, TBodyE, TFaultE, THeaderE, THeaderfaultE, TAddressE],
  { groups }
  [],
  'soap');

end.
