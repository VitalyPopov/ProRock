unit MetaModel;

interface

uses ProRock.Basite, ProRock.Xmlite;

type
  TOrderStatus = (osNone, osNew, osPaid, osShipped);
  TCurrencyCode = (ccNone, ccUSD, ccEUR);

  TCustomer = class(TBasite)
  private
    fName: string;
    fAge: integer;
    fEmail: string;
    fIsVip: boolean;
  published
    [TXmliteElement]
    property name: string read fName write fName;
    [TXmliteElement]
    property email: string read fEmail write fEmail;
    [TXmliteElement]
    property age: integer read fAge write fAge;
    [TXmliteElement]
    property isVip: boolean read fIsVip write fIsVip;
  end;

  TItem = class(TBasite)
  private
    fPrice: double;
    fTitle: string;
    fQuantity: integer;
    fSku: string;
    fCurrency: TCurrencyCode;
  published
    property sku: string read fSku write fSku;
    property quantity: integer read fQuantity write fQuantity;

    [TXmliteElement]
    property title: string read fTitle write fTitle;
    [TXmliteElement]
    property price: double read fPrice write fPrice;
    [TXmliteElement]
    property currency: TCurrencyCode read fCurrency write fCurrency;
  end;

  TItems = class(TBasite)
  private
    fItem: TBasiteList<TItem>;
  published
    property item: TBasiteList<TItem> read fItem;
  end;

  TOrder = class(TBasite)
  private
    fCustomer: TCustomer;
    fItems: TItems;
    fTotal: extended;
    fId: string;
    fStatus: TOrderStatus;
  published
    property id: string read fId write fId;
    property status: TOrderStatus read fStatus write fStatus;

    property customer: TCustomer read fCustomer;
    property items: TItems read fItems;
    [TXmliteElement]
    property total: extended read fTotal write fTotal;
  end;

implementation

end.
