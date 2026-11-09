---
icon: lucide/pen-line
---

# Hand-written classes

The usual way is to pick the schema, generate and use the classes, without thinking about how XML works. But if there is no schema, a
small format of your own for example, you are not left out: write the classes yourself, and everything else works the same.

A published property is an attribute by default; `[TXmliteElement]` makes it a child element:

```pascal
uses ProRock.Basite, ProRock.Xmlite;

type
  TItem = class(TBasite)
  private
    fSku: string;
    fTitle: string;
    fPrice: Double;
  published
    property sku: string read fSku write fSku;         // <item sku="...">
    [TXmliteElement]
    property title: string read fTitle write fTitle;   // <title>...</title>
    [TXmliteElement]
    property price: Double read fPrice write fPrice;
  end;

  TItems = class(TBasite)
  private
    fItem: TBasiteList<TItem>;
  published
    property item: TBasiteList<TItem> read fItem;     // created and freed with TItems
  end;
```

Using them is the same as with generated classes:

```pascal
var items := TItems.Create;
try
  if items.FromXml('<items><item sku="R1"><title>Rocket</title><price>9.5</price></item></items>') then
    Writeln(items.item[0].sku, ': ', items.item[0].title);  // R1: Rocket
  Writeln(items.ToXml('items'));                            // the root's name; without it, the class name: <Items>
finally
  items.Free;
end;
```

!!! warning "Declare the classes in the interface section of a unit"
    ProRock reads them through RTTI. A class declared in a program or an implementation section raises `ENonPublicType` on first use.

The sample [`ProRock.Xmlite.Basic`](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Xmlite.Basic) is built this way.

## Lazy creation

In your own classes the property says it: an object read from a field is created with its parent, down to
`TBasite.AutoInitMaxDepth` levels of a type nested in itself; one with a getter is created on first access. Keep a field named `f` +
the property name - the reader and writer use the field directly - and create the object in the getter with `Lazy`:

```pascal
TShipment = class(TXmliteComplexType)
private
  fCourier: TCourier;
  function GetCourier: TCourier;
published
  [TXmliteElement, TChoice('Delivery')]
  property Courier: TCourier read GetCourier;
end;

function TShipment.GetCourier: TCourier;
begin
  Result := TCourier(Lazy(fCourier, TCourier));
end;
```

Without the field the class reports it on first use. `[TChoice]` is optional: it only adds the property to a group for
`Chosen`. `[TRequired]` is independent of both forms: a required object is written always, so it is created with its parent,
with a getter too. Created with its parent does not mean required: an object from a field without `[TRequired]` is written only when
it has content.
