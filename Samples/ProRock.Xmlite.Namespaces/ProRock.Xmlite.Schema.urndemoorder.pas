unit ProRock.Xmlite.Schema.urndemoorder;

(*
    This unit was automatically generated using ProRocket 1.0.0 Lite (ProRock 1.0.0)
    Generated (UTC): 2026-01-04T10:21:03.820Z
    Namespace: urn:demo:order
    
    ProRock is a free and open-source Delphi library. Feedback and contributions are welcome.
    https://github.com/VitalyPopov/ProRock
*)


interface

uses
  ProRock.Xmlite, ProRock.Xmlite.Schema.Base;

type
  TOrderStatusST = (osNew, osProcessing, osShipped, osCompleted, osCancelled);

  TCurrencyCodeST = type TStringST;

  TMoneyTypeCT = class;
  TCustomerTypeCT = class;
  TItemTypeCT = class;
  TItemsTypeCT = class;
  TOrderE = class;

  TMoneyTypeCTList = class;
  TCustomerTypeCTList = class;
  TItemTypeCTList = class;
  TItemsTypeCTList = class;
  TOrderEList = class;

  TMoneyTypeCT = class(TXmliteComplexType)
  private
    fAmount: TDecimalST;
    fCurrency: TCurrencyCodeST;
  published
    property Amount: TDecimalST read fAmount write fAmount;
    property Currency: TCurrencyCodeST read fCurrency write fCurrency;
  end;

  TCustomerTypeCT = class(TXmliteComplexType)
  private
    fId: TStringST;
    fName: TStringST;
    fEmail: TStringST;
  published
    property Id: TStringST read fId write fId;
    property Name: TStringST read fName write fName;
    property Email: TStringST read fEmail write fEmail;
  end;

  TItemTypeCT = class(TXmliteComplexType)
  private
    fSku: TStringST;
    fQuantity: TIntST;
    fTitle: TStringST;
    fPrice: TDecimalST;
    fCurrency: TCurrencyCodeST;
  published
    property Sku: TStringST read fSku write fSku;
    property Quantity: TIntST read fQuantity write fQuantity;
    property Title: TStringST read fTitle write fTitle;
    property Price: TDecimalST read fPrice write fPrice;
    property Currency: TCurrencyCodeST read fCurrency write fCurrency;
  end;

  TItemsTypeCT = class(TXmliteComplexType)
  private
    fItem: TItemTypeCTList;
  published
    property Item: TItemTypeCTList read fItem;
  end;

  [TNamingAttribute(TNaming.nFlatCase)]
  TOrderE = class(TXmliteElement)
  private
    fId: TStringST;
    fDate: TDateTimeST;
    fStatus: TOrderStatusST;
    fCustomer: TCustomerTypeCT;
    fItems: TItemsTypeCT;
    fTotal: TMoneyTypeCT;
  published
    property Id: TStringST read fId write fId;
    property Date: TDateTimeST read fDate write fDate;
    property Status: TOrderStatusST read fStatus write fStatus;
    property Customer: TCustomerTypeCT read fCustomer;
    property Items: TItemsTypeCT read fItems;
    property Total: TMoneyTypeCT read fTotal;
  end;

  TMoneyTypeCTList = class(TXmliteList<TMoneyTypeCT>);
  TCustomerTypeCTList = class(TXmliteList<TCustomerTypeCT>);
  TItemTypeCTList = class(TXmliteList<TItemTypeCT>);
  TItemsTypeCTList = class(TXmliteList<TItemsTypeCT>);
  TOrderEList = class(TXmliteList<TOrderE>);

implementation

initialization

TMetaBankXmlite.RegisterNamespace('urn:demo:order', [TypeInfo(TOrderStatusST), TypeInfo(TCurrencyCodeST)], [TMoneyTypeCT, TCustomerTypeCT,
  TItemTypeCT, TItemsTypeCT], [], [], [TOrderE], [], 'o', TNaming.nPascalCase);

end.
