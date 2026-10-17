# Xmlite

Xmlite reads and writes XML through plain Delphi objects: one class per element or type of the schema, one property per child
element or attribute. It is namespace- and schema-aware, and parses in place on the text, without building a DOM.

Classes come from two places:

- **generated** by [ProRocket Lite](prorocket-lite.md) from an XSD or WSDL - exact to the schema, regenerated when it changes
- **hand-written**, for a small format without a schema or to start simple

## Reading and writing

```pascal
uses System.SysUtils, System.IOUtils,
  ProRock.Xmlite, // FromXml and ToXml (a class helper: visible only where ProRock.Xmlite is in uses)
  ProRock.Xmlite.Schema.Order;

var order := TOrderE.Create; // the root element's class: <order> -> TOrderE
try
  if order.FromXml(TFile.ReadAllText('order.xml', TEncoding.UTF8)) then // True when the text was parsed
    Writeln(order.Customer.Name, ': ', order.Items.Item.Count, ' items');

  order.Status := osShipped;
  TFile.WriteAllText('order.xml', order.ToXml, TEncoding.UTF8);
finally
  order.Free;
end;
```

- Nested objects and lists are created and freed with their parent (read-only properties); just use them.
- Enumerations are Delphi enums, `maxOccurs > 1` gives a typed list (`...List`).
- `TXmlite.ObjectToXml(obj)` writes any object, also one that is not a root element.

## What the generator makes of a schema

From this part of an XSD:

```xml
<xs:simpleType name="OrderStatus">
  <xs:restriction base="xs:string">
    <xs:enumeration value="new"/>
    <xs:enumeration value="shipped"/>
  </xs:restriction>
</xs:simpleType>

<xs:complexType name="ItemsType">
  <xs:sequence>
    <xs:element name="item" type="ItemType" maxOccurs="unbounded"/>
  </xs:sequence>
</xs:complexType>
```

you get:

```pascal
TOrderStatusST = (osNew, osShipped);

TItemsTypeCT = class(TXmliteComplexType)
private
  fItem: TItemTypeCTList;
published
  [TNaming(TNaming.nFlatCase)]
  property Item: TItemTypeCTList read fItem;
end;
```

The suffix tells what a name was in the schema: `E` an element, `CT` a complex type, `ST` a simple type. One unit per XML
namespace (`ProRock.Xmlite.Schema.<Name>`), so the units of a schema set use each other as the schemas import each other.

| XSD | Delphi |
|---|---|
| `xs:string`, `xs:token`, ... | `string` types (`TStringST = type string`) |
| `xs:integer`, `xs:long`, `xs:int`, `xs:short`, ... | `Int64` types |
| `xs:unsignedLong` and its derived types | `UInt64` types |
| `xs:decimal`, `xs:float`, `xs:double` | `Double` types |
| `xs:boolean` | `Boolean` |
| `xs:date`, `xs:dateTime`, `xs:duration`, ... | `string` types: the text as in the document |
| enumeration | a Delphi enum |
| complex type, element | a class |
| `maxOccurs > 1` | a typed list |
| simpleContent (text plus attributes) | the text in `XmlValue`, the attributes as properties |

!!! note "Generated string types"
    `TStringST` is `type string`, so string-helper methods need a cast: `string(response.Address).Replace(...)`.

## Hand-written classes

Without a schema, write the classes yourself. A published property is an attribute by default; `[TXmliteElement]` makes it a
child element:

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

You can start with simple models like these and move to generated, namespace-aware classes when a schema arrives. The samples
[`ProRock.Xmlite.Basic`](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Xmlite.Basic) (hand-written) and [`ProRock.Xmlite.Namespaces`](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Xmlite.Namespaces) (generated) show both.

## Derived types: `xsi:type`

When the schema allows a derived type in place of the declared one, the document says so with `xsi:type`. To write it, tell the
element which class it holds:

```pascal
props.Modified.SetXsiType(TW3cdtfCT); // <dcterms:modified xsi:type="dcterms:W3CDTF">
```

`SetXsiType` refuses a class that is not a complex type derived from the element's type. See
[XML concepts](xml-concepts.md#derived-types-and-xsitype) for what this means.

## Under the hood

`TXmlite` and `TXmliteList` inherit from `TBasite` and `TBasiteList`. **Basite** is the core: a metadata-driven object model,
independent of any data format. It keeps the metadata of each class in one place (no repeated RTTI scanning), creates and
frees nested objects, and lets a format attach its own metadata. Xmlite is one such format; Soapite builds on Xmlite.

The metamodels that ship with ProRock - XML Schema itself, WSDL, the SOAP envelopes and bindings
(`ProRock.Xmlite.Schema.*`) - are ordinary generated units: ProRocket Lite generates them from their official schemas with
every release, and reads every XSD and WSDL through them.

Limits of the current version: [Limitations and notes](limitations.md).
