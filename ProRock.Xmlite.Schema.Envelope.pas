unit ProRock.Xmlite.Schema.Envelope;

(*
    This unit was automatically generated using ProRocket Lite 1.0.6 (ProRock 1.0.3)
    Generated (UTC): 2026-01-27T23:07:24.675Z
    Namespace: http://schemas.xmlsoap.org/soap/envelope/
    
    ProRock is a free and open-source Delphi library. Feedback and contributions are welcome.
    https://github.com/VitalyPopov/ProRock
*)


interface

uses
  ProRock.Xmlite, ProRock.Xmlite.Schema.Base;

type

  [TNaming(TNaming.nFlatCase)]
  TActorA = type ProRock.Xmlite.Schema.Base.TAnyURIST;
  [TNaming(TNaming.nCamelCase)]
  TEncodingStyleST = type string;
  [TNaming(TNaming.nCamelCase)]
  TMustUnderstandA = type ProRock.Xmlite.Schema.Base.TBooleanST;
  [TNaming(TNaming.nCamelCase)]
  TEncodingStyleA = type TEncodingStyleST;

  TEnvelopeCT = class;
  THeaderCT = class;
  TBodyCT = class;
  TFaultCT = class;
  TDetailCT = class;
  TEncodingStyleAG = class;
  TEnvelopeE = class;
  THeaderE = class;
  TBodyE = class;
  TFaultE = class;

  TEnvelopeCTList = class;
  THeaderCTList = class;
  TBodyCTList = class;
  TFaultCTList = class;
  TDetailCTList = class;
  TEnvelopeEList = class;
  THeaderEList = class;
  TBodyEList = class;
  TFaultEList = class;

  [TXmliteAnyElement]
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
    fFaultcode: ProRock.Xmlite.Schema.Base.TQNameST;
    fFaultstring: ProRock.Xmlite.Schema.Base.TStringST;
    fFaultactor: ProRock.Xmlite.Schema.Base.TAnyURIST;
    fDetail: TDetailCT;
  published
    [TXmliteElement]
    property Faultcode: ProRock.Xmlite.Schema.Base.TQNameST read fFaultcode write fFaultcode;
    [TXmliteElement]
    property Faultstring: ProRock.Xmlite.Schema.Base.TStringST read fFaultstring write fFaultstring;
    [TXmliteElement]
    property Faultactor: ProRock.Xmlite.Schema.Base.TAnyURIST read fFaultactor write fFaultactor;
    property Detail: TDetailCT read fDetail;
  end;

  [TXmliteAnyElement]
  [TNaming(TNaming.nFlatCase)]
  TDetailCT = class(TXmliteComplexType);

  [TNaming(TNaming.nCamelCase)]
  TEncodingStyleAG = class(TXmliteAttributeGroup)
  private
    fEncodingStyle: TEncodingStyleA;
  published
    property EncodingStyle: TEncodingStyleA read fEncodingStyle write fEncodingStyle;
  end;

  TEnvelopeE = class(TEnvelopeCT);

  THeaderE = class(THeaderCT);

  TBodyE = class(TBodyCT);

  TFaultE = class(TFaultCT);

  TEnvelopeCTList = class(TXmliteList<TEnvelopeCT>);
  THeaderCTList = class(TXmliteList<THeaderCT>);
  TBodyCTList = class(TXmliteList<TBodyCT>);
  TFaultCTList = class(TXmliteList<TFaultCT>);
  TDetailCTList = class(TXmliteList<TDetailCT>);
  TEnvelopeEList = class(TXmliteList<TEnvelopeE>);
  THeaderEList = class(TXmliteList<THeaderE>);
  TBodyEList = class(TXmliteList<TBodyE>);
  TFaultEList = class(TXmliteList<TFaultE>);

implementation

initialization

TMetaBankXmlite.RegisterNamespace('http://schemas.xmlsoap.org/soap/envelope/',
  { simpleTypes }
  [TypeInfo(TEncodingStyleST)],
  { complexTypes }
  [TEnvelopeCT, THeaderCT, TBodyCT, TFaultCT, TDetailCT],
  { attributes }
  [TypeInfo(TMustUnderstandA), TypeInfo(TActorA), TypeInfo(TEncodingStyleA)],
  { attributeGroups }
  [TEncodingStyleAG],
  { elements }
  [TEnvelopeE, THeaderE, TBodyE, TFaultE],
  { groups }
  [],
  'tns', TNaming.nPascalCase);

end.
