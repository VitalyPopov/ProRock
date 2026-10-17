# XML concepts for Delphi developers

The XML and XSD terms that come up with ProRock, each with a small example and what it becomes in Delphi. No prior XSD
knowledge needed.

## Elements and attributes

```xml
<item sku="SKU-001">
  <title>USB-C Cable</title>
</item>
```

`item` and `title` are **elements**; `sku` is an **attribute** of `item`. An element can hold text, other elements, or both; an
attribute holds a single value. In Delphi, both are properties of the class of `item`: `Sku` and `Title`.

## Namespaces and prefixes

Two vendors can both have an element called `name`. A **namespace** - a URI, usually looking like a web address or a `urn:` -
tells them apart:

```xml
<order xmlns="urn:demo:order" xmlns:c="urn:demo:common">
  <customer>
    <c:name>John Smith</c:name>
  </customer>
</order>
```

- `xmlns="urn:demo:order"` is the **default namespace**: `order` and `customer` are in it
- `xmlns:c="urn:demo:common"` binds the **prefix** `c` to another namespace: `c:name` is `name` of `urn:demo:common`

The prefix is only a local abbreviation. What counts is the URI: `<c:name>` and `<x:name>` are the same element if `c` and `x`
point to the same URI. So never compare prefixes - ProRock matches namespaces, and writes the prefixes itself.

In ProRock, each namespace becomes one unit: `urn:demo:order` → `ProRock.Xmlite.Schema.Order`.

## The schema (XSD)

An XSD describes which elements and attributes a document may have, in which order, with which types. It is the contract between
the sender and the receiver of a document, and what ProRocket Lite generates the Delphi classes from.

```xml
<xs:element name="order" type="OrderType"/>   <!-- an element: a name a document can use -->

<xs:complexType name="OrderType">             <!-- a type: the shape of the content -->
  <xs:sequence>
    <xs:element name="id" type="xs:string"/>
    <xs:element name="note" type="xs:string" minOccurs="0"/>
    <xs:element name="item" type="ItemType" maxOccurs="unbounded"/>
  </xs:sequence>
</xs:complexType>
```

- a **complex type** has child elements or attributes → a class (`TOrderTypeCT`)
- an **element** is a name with a type → a class too (`TOrderE`); the root of a document is always an element
- a **simple type** is a single value (a string, a number, an enumeration) → a Delphi type (`...ST`)
- `minOccurs="0"`: the element is optional; `maxOccurs="unbounded"`: it can repeat → a list property

The suffixes `E`, `CT` and `ST` keep an element and a type of the same name apart, as XSD does.

## Optional values: absent vs default

```xml
<order><id>1</id></order>               <!-- note is absent -->
<order><id>1</id><note></note></order>  <!-- note is present and empty -->
```

The schema sees two different documents. A Delphi `string` property is `''` in both cases. ProRock doesn't tell them apart yet:
an absent optional value reads as its default, and an optional value equal to its default is not written. For most documents
that is what you want; where the difference matters, it is a known limitation (on the [roadmap](roadmap.md)).

## Enumerations

```xml
<xs:simpleType name="OrderStatus">
  <xs:restriction base="xs:string">
    <xs:enumeration value="new"/>
    <xs:enumeration value="shipped"/>
  </xs:restriction>
</xs:simpleType>
```

A list of allowed values → a Delphi enum: `TOrderStatusST = (osNew, osShipped)`. The text `shipped` in the document reads as
`osShipped` and is written back as `shipped`.

## Text with attributes (simpleContent)

```xml
<price currency="EUR">9.99</price>
```

An element with a value and attributes, but no child elements. The class gets the attributes as properties and the value in
`XmlValue`: `price.XmlValue` is `9.99`, `price.Currency` is `EUR`.

## Mixed content

```xml
<p>Call <b>now</b> to order.</p>
```

Text and elements interleaved, like HTML. ProRock keeps the text of such an element in `XmlText`; the interleaving with child
elements is not kept yet. When the schema allows mixed content but no child elements can occur (Dublin Core's text values), it
is plain text in `XmlValue`.

## Derived types and `xsi:type`

A type can be derived from another one - extending it or restricting it - like a Delphi class inherits from its parent. In
Dublin Core, `W3CDTF` (a date or date-time) is derived from `SimpleLiteral` (any text):

```xml
<xs:complexType name="W3CDTF">
  <xs:simpleContent>
    <xs:restriction base="dc:SimpleLiteral"> ... </xs:restriction>
  </xs:simpleContent>
</xs:complexType>
```

Where the schema says "a `SimpleLiteral`", a document may put a `W3CDTF` instead - but then it has to say so, with the
attribute `xsi:type`:

```xml
<dcterms:modified xsi:type="dcterms:W3CDTF">2026-10-16T12:00:00Z</dcterms:modified>
```

`xsi` is the namespace `http://www.w3.org/2001/XMLSchema-instance`, the schema's own vocabulary inside documents. In ProRock,
`SetXsiType(TW3cdtfCT)` writes it. The Office document format requires it on `created` and `modified`, which is why the
[DocumentProperties sample](samples.md#office-document-properties) calls it.

## Substitution groups

An element can be declared as a stand-in for another one, its **head**:

```xml
<xs:element name="any" type="SimpleLiteral" abstract="true"/>
<xs:element name="title" substitutionGroup="dc:any"/>
<xs:element name="creator" substitutionGroup="dc:any"/>
```

Wherever the schema allows `dc:any`, a document uses `dc:title` or `dc:creator` instead (`abstract="true"`: the head itself
never appears). A member without a type of its own
takes its head's type, so ProRock generates `TTitleE = class(TAnyE)` - in Delphi terms, the members are descendants of the
head. A property of the head's type holding any member is not supported yet; it is on the [roadmap](roadmap.md) as
polymorphic content.

## Qualified and unqualified local elements

```xml
<xs:schema targetNamespace="urn:demo:order" elementFormDefault="qualified">
```

Elements declared inside a type (local elements) are in the schema's namespace with `qualified`, and in **no** namespace with
`unqualified`, the XSD default:

```xml
<o:order xmlns:o="urn:demo:order">
  <o:id>1</o:id>   <!-- qualified -->
  <id>1</id>       <!-- unqualified: no prefix, and no default namespace may be in scope -->
</o:order>
```

Most modern schemas use `qualified`. ProRock reads both; with `unqualified` it currently writes local elements in the
parent's default namespace.

## WSDL

A WSDL describes a SOAP service: its operations, the XSD types of their requests and responses (usually embedded in the WSDL),
and the address. ProRocket Lite turns the types into Xmlite units and the service into a client class with one method per
operation - see [Soapite](soapite.md).
