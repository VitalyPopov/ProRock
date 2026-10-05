unit ProRock.Xmlite.Schema.CheckVatService;

(*
    This unit was automatically generated using ProRocket Lite 1.0.6 (ProRock 1.0.3)
    
    ProRock is a free and open-source Delphi library. Feedback and contributions are welcome.
    https://github.com/VitalyPopov/ProRock
    
    Generated (UTC): 2026-10-05T20:48:57.370Z
    Namespace: urn:ec.europa.eu:taxud:vies:services:checkVat:types
*)


interface

uses
  ProRock.Xmlite, ProRock.Xmlite.Schema.Base;

type
  TMatchCodeST = (mc1, mc2, mc3);

  TCompanyTypeCodeST = type ProRock.Xmlite.Schema.Base.TStringST;

  TCheckVatE = class;
  TCheckVatResponseE = class;
  TCheckVatApproxE = class;
  TCheckVatApproxResponseE = class;

  TCheckVatEList = class;
  TCheckVatResponseEList = class;
  TCheckVatApproxEList = class;
  TCheckVatApproxResponseEList = class;

  TCheckVatE = class(TXmliteElement)
  private
    fCountryCode: ProRock.Xmlite.Schema.Base.TStringST;
    fVatNumber: ProRock.Xmlite.Schema.Base.TStringST;
  published
    [TXmliteElement]
    [TRequired]
    property CountryCode: ProRock.Xmlite.Schema.Base.TStringST read fCountryCode write fCountryCode;
    [TXmliteElement]
    [TRequired]
    property VatNumber: ProRock.Xmlite.Schema.Base.TStringST read fVatNumber write fVatNumber;
  end;

  TCheckVatResponseE = class(TXmliteElement)
  private
    fCountryCode: ProRock.Xmlite.Schema.Base.TStringST;
    fVatNumber: ProRock.Xmlite.Schema.Base.TStringST;
    fRequestDate: ProRock.Xmlite.Schema.Base.TDateST;
    fValid: ProRock.Xmlite.Schema.Base.TBooleanST;
    fName: ProRock.Xmlite.Schema.Base.TStringST;
    fAddress: ProRock.Xmlite.Schema.Base.TStringST;
  published
    [TXmliteElement]
    [TRequired]
    property CountryCode: ProRock.Xmlite.Schema.Base.TStringST read fCountryCode write fCountryCode;
    [TXmliteElement]
    [TRequired]
    property VatNumber: ProRock.Xmlite.Schema.Base.TStringST read fVatNumber write fVatNumber;
    [TXmliteElement]
    [TRequired]
    property RequestDate: ProRock.Xmlite.Schema.Base.TDateST read fRequestDate write fRequestDate;
    [TXmliteElement]
    [TRequired]
    property Valid: ProRock.Xmlite.Schema.Base.TBooleanST read fValid write fValid;
    [TXmliteElement]
    property Name: ProRock.Xmlite.Schema.Base.TStringST read fName write fName;
    [TXmliteElement]
    property Address: ProRock.Xmlite.Schema.Base.TStringST read fAddress write fAddress;
  end;

  TCheckVatApproxE = class(TXmliteElement)
  private
    fCountryCode: ProRock.Xmlite.Schema.Base.TStringST;
    fVatNumber: ProRock.Xmlite.Schema.Base.TStringST;
    fTraderName: ProRock.Xmlite.Schema.Base.TStringST;
    fTraderCompanyType: TCompanyTypeCodeST;
    fTraderStreet: ProRock.Xmlite.Schema.Base.TStringST;
    fTraderPostcode: ProRock.Xmlite.Schema.Base.TStringST;
    fTraderCity: ProRock.Xmlite.Schema.Base.TStringST;
    fRequesterCountryCode: ProRock.Xmlite.Schema.Base.TStringST;
    fRequesterVatNumber: ProRock.Xmlite.Schema.Base.TStringST;
  published
    [TXmliteElement]
    [TRequired]
    property CountryCode: ProRock.Xmlite.Schema.Base.TStringST read fCountryCode write fCountryCode;
    [TXmliteElement]
    [TRequired]
    property VatNumber: ProRock.Xmlite.Schema.Base.TStringST read fVatNumber write fVatNumber;
    [TXmliteElement]
    property TraderName: ProRock.Xmlite.Schema.Base.TStringST read fTraderName write fTraderName;
    [TXmliteElement]
    property TraderCompanyType: TCompanyTypeCodeST read fTraderCompanyType write fTraderCompanyType;
    [TXmliteElement]
    property TraderStreet: ProRock.Xmlite.Schema.Base.TStringST read fTraderStreet write fTraderStreet;
    [TXmliteElement]
    property TraderPostcode: ProRock.Xmlite.Schema.Base.TStringST read fTraderPostcode write fTraderPostcode;
    [TXmliteElement]
    property TraderCity: ProRock.Xmlite.Schema.Base.TStringST read fTraderCity write fTraderCity;
    [TXmliteElement]
    property RequesterCountryCode: ProRock.Xmlite.Schema.Base.TStringST read fRequesterCountryCode write fRequesterCountryCode;
    [TXmliteElement]
    property RequesterVatNumber: ProRock.Xmlite.Schema.Base.TStringST read fRequesterVatNumber write fRequesterVatNumber;
  end;

  TCheckVatApproxResponseE = class(TXmliteElement)
  private
    fCountryCode: ProRock.Xmlite.Schema.Base.TStringST;
    fVatNumber: ProRock.Xmlite.Schema.Base.TStringST;
    fRequestDate: ProRock.Xmlite.Schema.Base.TDateST;
    fValid: ProRock.Xmlite.Schema.Base.TBooleanST;
    fTraderName: ProRock.Xmlite.Schema.Base.TStringST;
    fTraderCompanyType: TCompanyTypeCodeST;
    fTraderAddress: ProRock.Xmlite.Schema.Base.TStringST;
    fTraderStreet: ProRock.Xmlite.Schema.Base.TStringST;
    fTraderPostcode: ProRock.Xmlite.Schema.Base.TStringST;
    fTraderCity: ProRock.Xmlite.Schema.Base.TStringST;
    fTraderNameMatch: TMatchCodeST;
    fTraderCompanyTypeMatch: TMatchCodeST;
    fTraderStreetMatch: TMatchCodeST;
    fTraderPostcodeMatch: TMatchCodeST;
    fTraderCityMatch: TMatchCodeST;
    fRequestIdentifier: ProRock.Xmlite.Schema.Base.TStringST;
  published
    [TXmliteElement]
    [TRequired]
    property CountryCode: ProRock.Xmlite.Schema.Base.TStringST read fCountryCode write fCountryCode;
    [TXmliteElement]
    [TRequired]
    property VatNumber: ProRock.Xmlite.Schema.Base.TStringST read fVatNumber write fVatNumber;
    [TXmliteElement]
    [TRequired]
    property RequestDate: ProRock.Xmlite.Schema.Base.TDateST read fRequestDate write fRequestDate;
    [TXmliteElement]
    [TRequired]
    property Valid: ProRock.Xmlite.Schema.Base.TBooleanST read fValid write fValid;
    [TXmliteElement]
    property TraderName: ProRock.Xmlite.Schema.Base.TStringST read fTraderName write fTraderName;
    [TXmliteElement]
    property TraderCompanyType: TCompanyTypeCodeST read fTraderCompanyType write fTraderCompanyType;
    [TXmliteElement]
    property TraderAddress: ProRock.Xmlite.Schema.Base.TStringST read fTraderAddress write fTraderAddress;
    [TXmliteElement]
    property TraderStreet: ProRock.Xmlite.Schema.Base.TStringST read fTraderStreet write fTraderStreet;
    [TXmliteElement]
    property TraderPostcode: ProRock.Xmlite.Schema.Base.TStringST read fTraderPostcode write fTraderPostcode;
    [TXmliteElement]
    property TraderCity: ProRock.Xmlite.Schema.Base.TStringST read fTraderCity write fTraderCity;
    [TXmliteElement]
    property TraderNameMatch: TMatchCodeST read fTraderNameMatch write fTraderNameMatch;
    [TXmliteElement]
    property TraderCompanyTypeMatch: TMatchCodeST read fTraderCompanyTypeMatch write fTraderCompanyTypeMatch;
    [TXmliteElement]
    property TraderStreetMatch: TMatchCodeST read fTraderStreetMatch write fTraderStreetMatch;
    [TXmliteElement]
    property TraderPostcodeMatch: TMatchCodeST read fTraderPostcodeMatch write fTraderPostcodeMatch;
    [TXmliteElement]
    property TraderCityMatch: TMatchCodeST read fTraderCityMatch write fTraderCityMatch;
    [TXmliteElement]
    [TRequired]
    property RequestIdentifier: ProRock.Xmlite.Schema.Base.TStringST read fRequestIdentifier write fRequestIdentifier;
  end;

  TCheckVatEList = class(TXmliteList<TCheckVatE>);
  TCheckVatResponseEList = class(TXmliteList<TCheckVatResponseE>);
  TCheckVatApproxEList = class(TXmliteList<TCheckVatApproxE>);
  TCheckVatApproxResponseEList = class(TXmliteList<TCheckVatApproxResponseE>);

implementation

initialization

TMetaBankXmlite.RegisterNamespace('urn:ec.europa.eu:taxud:vies:services:checkVat:types',
  { simpleTypes }
  [TypeInfo(TCompanyTypeCodeST), TypeInfo(TMatchCodeST)],
  { complexTypes }
  [],
  { attributes }
  [],
  { attributeGroups }
  [],
  { elements }
  [TCheckVatE, TCheckVatResponseE, TCheckVatApproxE, TCheckVatApproxResponseE],
  { groups }
  [],
  'tns1');

end.
