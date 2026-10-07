unit ProRock.Xmlite.Schema.Order;

(*
    This unit was automatically generated using ProRocket Lite 1.1.0 (ProRock 1.1.0)
    
    ProRock is a free and open-source Delphi library. Feedback and contributions are welcome.
    https://github.com/VitalyPopov/ProRock
    
    Generated (UTC): 2026-10-07T21:18:53.882Z
    Namespace: urn:demo:order
*)


interface

uses
  ProRock.Xmlite, ProRock.Xmlite.Schema.Base;

type
  TOrderStatusST = (osNew, osProcessing, osShipped, osCompleted, osCancelled);

  TCurrencyCodeST = type ProRock.Xmlite.Schema.Base.TStringST;

  TCustomerTypeCT = class;
  TItemTypeCT = class;
  TItemsTypeCT = class;
  TMoneyTypeCT = class;
  TOrderE = class;

  TCustomerTypeCTList = class;
  TItemTypeCTList = class;
  TItemsTypeCTList = class;
  TMoneyTypeCTList = class;
  TOrderEList = class;

  TCustomerTypeCT = class(TXmliteComplexType)
  private
    fId: ProRock.Xmlite.Schema.Base.TStringST;
    fName: ProRock.Xmlite.Schema.Base.TStringST;
    fEmail: ProRock.Xmlite.Schema.Base.TStringST;
  published
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nFlatCase)]
    property Id: ProRock.Xmlite.Schema.Base.TStringST read fId write fId;
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nFlatCase)]
    property Name: ProRock.Xmlite.Schema.Base.TStringST read fName write fName;
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nFlatCase)]
    property Email: ProRock.Xmlite.Schema.Base.TStringST read fEmail write fEmail;
  end;

  TItemTypeCT = class(TXmliteComplexType)
  type
    TQuantity = type ProRock.Xmlite.Schema.Base.TIntST;
    TPrice = type ProRock.Xmlite.Schema.Base.TDecimalST;
  private
    fSku: ProRock.Xmlite.Schema.Base.TStringST;
    fTitle: ProRock.Xmlite.Schema.Base.TStringST;
    fQuantity: TQuantity;
    fPrice: TPrice;
    fCurrency: TCurrencyCodeST;
  published
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nFlatCase)]
    property Sku: ProRock.Xmlite.Schema.Base.TStringST read fSku write fSku;
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nFlatCase)]
    property Title: ProRock.Xmlite.Schema.Base.TStringST read fTitle write fTitle;
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nFlatCase)]
    property Quantity: TQuantity read fQuantity write fQuantity;
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nFlatCase)]
    property Price: TPrice read fPrice write fPrice;
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nFlatCase)]
    property Currency: TCurrencyCodeST read fCurrency write fCurrency;
  end;

  TItemsTypeCT = class(TXmliteComplexType)
  private
    fItem: TItemTypeCTList;
  published
    [TNaming(TNaming.nFlatCase)]
    property Item: TItemTypeCTList read fItem;
  end;

  TMoneyTypeCT = class(TXmliteComplexType)
  private
    fAmount: ProRock.Xmlite.Schema.Base.TDecimalST;
    fCurrency: TCurrencyCodeST;
  published
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nFlatCase)]
    property Amount: ProRock.Xmlite.Schema.Base.TDecimalST read fAmount write fAmount;
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nFlatCase)]
    property Currency: TCurrencyCodeST read fCurrency write fCurrency;
  end;

  [TNaming(TNaming.nFlatCase)]
  TOrderE = class(TXmliteElement)
  private
    fId: ProRock.Xmlite.Schema.Base.TStringST;
    fDate: ProRock.Xmlite.Schema.Base.TDateTimeST;
    fStatus: TOrderStatusST;
    fCustomer: TCustomerTypeCT;
    fItems: TItemsTypeCT;
    fTotal: TMoneyTypeCT;
  published
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nFlatCase)]
    property Id: ProRock.Xmlite.Schema.Base.TStringST read fId write fId;
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nFlatCase)]
    property Date: ProRock.Xmlite.Schema.Base.TDateTimeST read fDate write fDate;
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nFlatCase)]
    property Status: TOrderStatusST read fStatus write fStatus;
    [TNaming(TNaming.nFlatCase)]
    property Customer: TCustomerTypeCT read fCustomer;
    [TNaming(TNaming.nFlatCase)]
    property Items: TItemsTypeCT read fItems;
    [TNaming(TNaming.nFlatCase)]
    property Total: TMoneyTypeCT read fTotal;
  end;

  TCustomerTypeCTList = class(TXmliteList<TCustomerTypeCT>);
  TItemTypeCTList = class(TXmliteList<TItemTypeCT>);
  TItemsTypeCTList = class(TXmliteList<TItemsTypeCT>);
  TMoneyTypeCTList = class(TXmliteList<TMoneyTypeCT>);
  TOrderEList = class(TXmliteList<TOrderE>);

implementation

initialization

TMetaBankXmlite.RegisterNamespace('urn:demo:order',
  { simpleTypes }
  [TypeInfo(TOrderStatusST), TypeInfo(TCurrencyCodeST)],
  { complexTypes }
  [TCustomerTypeCT, TItemTypeCT, TItemsTypeCT, TMoneyTypeCT],
  { attributes }
  [],
  { attributeGroups }
  [],
  { elements }
  [TOrderE],
  { groups }
  [],
  'o', TNaming.nPascalCase);

end.
