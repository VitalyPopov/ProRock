---
icon: lucide/workflow
---

# How it works

An XML schema (XSD) already says exactly what a document may contain. ProRock turns that description into Delphi classes, and
from then on you work with objects: no parsing code, no node walking.

<div class="flow"><div class="flow-box"><svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" class="lucide lucide-scroll-text" viewBox="0 0 24 24"><path d="M15 12h-5M15 8h-5M19 17V5a2 2 0 0 0-2-2H4"/><path d="M8 21h12a2 2 0 0 0 2-2v-1a1 1 0 0 0-1-1H11a1 1 0 0 0-1 1v1a2 2 0 1 1-4 0V5a2 2 0 1 0-4 0v2a1 1 0 0 0 1 1h3"/></svg><b>Your schema</b><span>.xsd, .wsdl</span></div><div class="flow-arrow"><b>ProRocket Lite</b><i></i><span>GUI or CLI, before you compile</span></div><div class="flow-box flow-main"><svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" class="lucide lucide-file-code" viewBox="0 0 24 24"><path d="M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z"/><path d="M14 2v5a1 1 0 0 0 1 1h5M10 12.5 8 15l2 2.5M14 12.5l2 2.5-2 2.5"/></svg><b>Delphi units</b><span>one class per type of the schema</span></div><div class="flow-arrow"><b>ProRock</b><i></i><span>compiled in, the library</span></div><div class="flow-box"><svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" class="lucide lucide-app-window" viewBox="0 0 24 24"><rect width="20" height="16" x="2" y="4" rx="2"/><path d="M10 4v4M2 8h20M6 4v4"/></svg><b>Your program</b><span>XML text<br><em>⇅</em><br>Delphi objects</span></div></div>

!!! tip "Nothing of the generator ends up in your program"
    It works before you compile. What your program carries is the generated units and the library, as ordinary Delphi source.

## From a schema to working code

A small schema, shortened to what matters here:

```xml
<xs:simpleType name="Status">
  <xs:restriction base="xs:string">
    <xs:enumeration value="new"/>
    <xs:enumeration value="shipped"/>
  </xs:restriction>
</xs:simpleType>

<xs:element name="order">
  <xs:complexType>
    <xs:sequence>
      <xs:element name="customer" type="xs:string"/>
      <xs:element name="item" type="Item" maxOccurs="unbounded"/>
      <xs:element name="note" type="xs:string" minOccurs="0"/>
    </xs:sequence>
    <xs:attribute name="status" type="Status"/>
  </xs:complexType>
</xs:element>
```

Generating is one click in the [GUI](gui.md) or one command:

```text
ProRocketCli.exe order.xsd
```

Out comes `ProRock.Xmlite.Schema.Order.pas`. The heart of it:

```pascal
TStatusST = (sNew, sShipped);

TOrderE = class(TXmliteElement)
published
  property Status: TStatusST read fStatus write fStatus;
  [TXmliteElement]
  [TRequired]
  property Customer: TStringST read fCustomer write fCustomer;
  property Item: TItemCTList read fItem;
  [TXmliteElement]
  property Note: TStringST read fNote write fNote;
end;
```

The schema's enumeration is a Delphi enum, the repeating element a typed list, and every name is there for code completion.
Using it:

```pascal
var order := TOrderE.Create;
try
  order.FromXml(TFile.ReadAllText('order.xml', TEncoding.UTF8));

  Writeln(order.Customer, ': ', order.Item[0].Quantity, ' x ', order.Item[0].Title); // Ann: 2 x Rocket

  order.Status := sShipped;
  order.Note := 'Left at the door';
  Writeln(order.ToXml);
finally
  order.Free;
end;
```

```xml
<order xmlns="urn:shop:order" status="shipped"><customer>Ann</customer><item><title>Rocket</title><quantity>2</quantity></item><note>Left at the door</note></order>
```

That is the whole idea. The real schemas are bigger, not different: all of [FHIR R4](samples.md#fhir-resources) or an
[electronic invoice](samples.md#electronic-invoices) work the same way.

A WSDL goes the same road and gives one more unit: a client class with a method for each operation of the service. From there,
calling the service is a method call ([Getting started](getting-started.md)).

## The objects are yours

The generated classes are plain Delphi objects with explicit ownership. You free what you create. A parent creates and frees
its children, so the one `order.Free` above frees the items as well. No DOM stays behind them, no interfaces, no reference
counting.

Reading and writing back also keep to what the document had: a value that was absent stays absent
([details](xmlite.md#absent-or-default-presence)), and parts the schema does not describe
[are kept](xmlite.md#content-the-schema-does-not-describe).

## When the schema changes

Schemas move: a new e-invoicing version, a service adding fields. You run the generator again on the new schema, and two tools
you already have tell you the rest:

- **your diff tool**: the output is deterministic, so the units change only where the schema changed (`--no-timestamp` leaves out the time in the header)
- **the compiler**: an element that was renamed or removed is now a compile error at every place that used it

Nothing to hunt for by hand.

## Which part does what

| | What it is | You get it |
|---|---|---|
| **ProRocket Lite** | the generator: XSD and WSDL in, Delphi units out, GUI and command line | a [free download](prorocket-lite/index.md), also for commercial use |
| **ProRock** | the library the units compile against, pure Delphi source | open source (Apache 2.0): add its `Source` folder to the search path |
| **Your units** | the generated classes | the code is yours, no strings attached |

Inside the library, three names you will meet: **Xmlite** reads and writes XML through the classes, **Soapite** makes SOAP calls
on top of it, **Basite** is the object core under both ([Design principles](principles.md#progressive-in-layers)).

## Where next

- Try it: [Getting started](getting-started.md), 5 minutes from a WSDL to a working call
- See it on real data: [Samples](samples.md)
- What the generator makes of each schema construct: [Generated code](generated-code.md)
