unit ProRock.Xmlite.Schema.Envelope12;

(*
    This unit was automatically generated using ProRocket Lite 1.1.0 (ProRock 1.1.0)
    
    ProRock is a free and open-source Delphi library. Feedback and contributions are welcome.
    https://github.com/VitalyPopov/ProRock
    
    Generated (UTC): 2026-10-07T21:13:19.883Z
    Namespace: http://www.w3.org/2003/05/soap-envelope
*)


interface

uses
  ProRock.Xmlite, ProRock.Xmlite.Schema.Base, ProRock.Xmlite.Schema.Xml;

type
  [TNaming(TNaming.nCamelCase)]
  TEncodingStyleA = type ProRock.Xmlite.Schema.Base.TAnyURIST;
  [TNaming(TNaming.nCamelCase)]
  TFaultcodeEnumST = type ProRock.Xmlite.Schema.Base.TQNameST;
  [TNaming(TNaming.nCamelCase)]
  TMustUnderstandA = type ProRock.Xmlite.Schema.Base.TBooleanST;
  [TNaming(TNaming.nFlatCase)]
  TRelayA = type ProRock.Xmlite.Schema.Base.TBooleanST;
  [TNaming(TNaming.nFlatCase)]
  TRoleA = type ProRock.Xmlite.Schema.Base.TAnyURIST;

  TEnvelopeCT = class;
  THeaderCT = class;
  TBodyCT = class;
  TFaultCT = class;
  TFaultreasonCT = class;
  TReasontextCT = class;
  TFaultcodeCT = class;
  TSubcodeCT = class;
  TDetailCT = class;
  TNotUnderstoodTypeCT = class;
  TSupportedEnvTypeCT = class;
  TUpgradeTypeCT = class;
  TEnvelopeE = class;
  THeaderE = class;
  TBodyE = class;
  TFaultE = class;
  TNotUnderstoodE = class;
  TUpgradeE = class;

  TEnvelopeCTList = class;
  THeaderCTList = class;
  TBodyCTList = class;
  TFaultCTList = class;
  TFaultreasonCTList = class;
  TReasontextCTList = class;
  TFaultcodeCTList = class;
  TSubcodeCTList = class;
  TDetailCTList = class;
  TNotUnderstoodTypeCTList = class;
  TSupportedEnvTypeCTList = class;
  TUpgradeTypeCTList = class;
  TEnvelopeEList = class;
  THeaderEList = class;
  TBodyEList = class;
  TFaultEList = class;
  TNotUnderstoodEList = class;
  TUpgradeEList = class;

  TEnvelopeCT = class(TXmliteComplexType)
  private
    fHeader: THeaderE;
    fBody: TBodyE;
  published
    property Header: THeaderE read fHeader;
    property Body: TBodyE read fBody;
  end;

  [TXmliteAnyElement]
  THeaderCT = class(TXmliteComplexType);

  [TXmliteAnyElement]
  TBodyCT = class(TXmliteComplexType);

  TFaultCT = class(TXmliteComplexType)
  private
    fCode: TFaultcodeCT;
    fReason: TFaultreasonCT;
    fNode: ProRock.Xmlite.Schema.Base.TAnyURIST;
    fRole: ProRock.Xmlite.Schema.Base.TAnyURIST;
    fDetail: TDetailCT;
  published
    property Code: TFaultcodeCT read fCode;
    property Reason: TFaultreasonCT read fReason;
    [TXmliteElement]
    property Node: ProRock.Xmlite.Schema.Base.TAnyURIST read fNode write fNode;
    [TXmliteElement]
    property Role: ProRock.Xmlite.Schema.Base.TAnyURIST read fRole write fRole;
    property Detail: TDetailCT read fDetail;
  end;

  [TNaming(TNaming.nFlatCase)]
  TFaultreasonCT = class(TXmliteComplexType)
  private
    fText: TReasontextCTList;
  published
    property Text: TReasontextCTList read fText;
  end;

  [TNaming(TNaming.nFlatCase)]
  TReasontextCT = class(TXmliteComplexType)
  private
    fXmlValue: ProRock.Xmlite.Schema.Base.TStringST;
    fLang: ProRock.Xmlite.Schema.Xml.TLangA;
  published
    [TXmliteText]
    property XmlValue: ProRock.Xmlite.Schema.Base.TStringST read fXmlValue write fXmlValue;
    [TNamespace('http://www.w3.org/XML/1998/namespace')]
    [TRequired]
    [TNaming(TNaming.nFlatCase)]
    property Lang: ProRock.Xmlite.Schema.Xml.TLangA read fLang write fLang;
  end;

  [TNaming(TNaming.nFlatCase)]
  TFaultcodeCT = class(TXmliteComplexType)
  private
    fValue: TFaultcodeEnumST;
    fSubcode: TSubcodeCT;
  published
    [TXmliteElement]
    [TRequired]
    property Value: TFaultcodeEnumST read fValue write fValue;
    property Subcode: TSubcodeCT read fSubcode;
  end;

  [TNaming(TNaming.nFlatCase)]
  TSubcodeCT = class(TXmliteComplexType)
  private
    fValue: ProRock.Xmlite.Schema.Base.TQNameST;
    fSubcode: TSubcodeCT;
  published
    [TXmliteElement]
    [TRequired]
    property Value: ProRock.Xmlite.Schema.Base.TQNameST read fValue write fValue;
    property Subcode: TSubcodeCT read fSubcode;
  end;

  [TXmliteAnyElement]
  [TNaming(TNaming.nFlatCase)]
  TDetailCT = class(TXmliteComplexType);

  TNotUnderstoodTypeCT = class(TXmliteComplexType)
  private
    fQname: ProRock.Xmlite.Schema.Base.TQNameST;
  published
    [TRequired]
    [TNaming(TNaming.nFlatCase)]
    property Qname: ProRock.Xmlite.Schema.Base.TQNameST read fQname write fQname;
  end;

  TSupportedEnvTypeCT = class(TXmliteComplexType)
  private
    fQname: ProRock.Xmlite.Schema.Base.TQNameST;
  published
    [TRequired]
    [TNaming(TNaming.nFlatCase)]
    property Qname: ProRock.Xmlite.Schema.Base.TQNameST read fQname write fQname;
  end;

  TUpgradeTypeCT = class(TXmliteComplexType)
  private
    fSupportedEnvelope: TSupportedEnvTypeCTList;
  published
    property SupportedEnvelope: TSupportedEnvTypeCTList read fSupportedEnvelope;
  end;

  TEnvelopeE = class(TEnvelopeCT);

  THeaderE = class(THeaderCT);

  TBodyE = class(TBodyCT);

  TFaultE = class(TFaultCT);

  TNotUnderstoodE = class(TNotUnderstoodTypeCT);

  TUpgradeE = class(TUpgradeTypeCT);

  TEnvelopeCTList = class(TXmliteList<TEnvelopeCT>);
  THeaderCTList = class(TXmliteList<THeaderCT>);
  TBodyCTList = class(TXmliteList<TBodyCT>);
  TFaultCTList = class(TXmliteList<TFaultCT>);
  TFaultreasonCTList = class(TXmliteList<TFaultreasonCT>);
  TReasontextCTList = class(TXmliteList<TReasontextCT>);
  TFaultcodeCTList = class(TXmliteList<TFaultcodeCT>);
  TSubcodeCTList = class(TXmliteList<TSubcodeCT>);
  TDetailCTList = class(TXmliteList<TDetailCT>);
  TNotUnderstoodTypeCTList = class(TXmliteList<TNotUnderstoodTypeCT>);
  TSupportedEnvTypeCTList = class(TXmliteList<TSupportedEnvTypeCT>);
  TUpgradeTypeCTList = class(TXmliteList<TUpgradeTypeCT>);
  TEnvelopeEList = class(TXmliteList<TEnvelopeE>);
  THeaderEList = class(TXmliteList<THeaderE>);
  TBodyEList = class(TXmliteList<TBodyE>);
  TFaultEList = class(TXmliteList<TFaultE>);
  TNotUnderstoodEList = class(TXmliteList<TNotUnderstoodE>);
  TUpgradeEList = class(TXmliteList<TUpgradeE>);

implementation

initialization

TMetaBankXmlite.RegisterNamespace('http://www.w3.org/2003/05/soap-envelope',
  { simpleTypes }
  [TypeInfo(TFaultcodeEnumST)],
  { complexTypes }
  [TEnvelopeCT, THeaderCT, TBodyCT, TFaultCT, TFaultreasonCT, TReasontextCT, TFaultcodeCT, TSubcodeCT, TDetailCT, TNotUnderstoodTypeCT,
  TSupportedEnvTypeCT, TUpgradeTypeCT],
  { attributes }
  [TypeInfo(TMustUnderstandA), TypeInfo(TRelayA), TypeInfo(TRoleA), TypeInfo(TEncodingStyleA)],
  { attributeGroups }
  [],
  { elements }
  [TEnvelopeE, THeaderE, TBodyE, TFaultE, TNotUnderstoodE, TUpgradeE],
  { groups }
  [],
  'env', TNaming.nPascalCase);

end.
