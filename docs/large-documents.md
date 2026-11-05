# Large documents

Since 1.7, in generated classes an object is created when your code first touches it, not together with its parent. A schema can
offer hundreds of members and a document uses a few, so the rest no longer cost anything. Nothing changes in how you use the
classes: create, read, work, write, free. In your own classes you choose: see [Hand-written classes](#hand-written-classes).

| The e-invoice sample's UBL invoice (5 lines) | 1.6 | 1.7 |
|---|---|---|
| read | 73 ms | 0.44 ms |
| write | 45 ms | 0.36 ms |
| free | 69 ms | 0.10 ms |
| objects in memory | 161,839 | 148 |

| A FHIR R4 Bundle of 1,000 Patients (1.8 MB) | 1.5 | 1.6 (choices) | 1.7 |
|---|---|---|---|
| read | 11.9 s | 0.11 s | 0.08 s |
| write | 6.7 s | 0.09 s | 0.07 s |
| free | 10.0 s | 0.06 s | 0.03 s |
| objects in memory | 52.6 million | 94,000 | 32,000 |

Measured with Delphi 13, Win64. Documents are written byte for byte as before.

## The rule

In a generated class an object is created on first access. A required one comes with its parent, because it is always written:

```pascal
TOrderE = class(TXmliteElement)
private
  fId: TValueCT;
  fSeller: TPartyCT;
  function GetSeller: TPartyCT;
published
  [TRequired]
  property Id: TValueCT read fId;                // minOccurs 1: created with the order, written always
  property Seller: TPartyCT read GetSeller;      // minOccurs 0: created when you touch it
end;
```

```pascal
order.Seller.City.XmlValue := 'Dubai';   // touching creates the way down
TFile.WriteAllText('order.xml', order.ToXml, TEncoding.UTF8);  // only what has content is written
```

Reading creates what is in the document. Touching an object that stays empty is harmless: it is not written, and whatever it holds
is created only when touched in turn. Lists are still created with their parent.

## Choices: one of several

An `xs:choice` holds exactly one of its members:

```xml
<xs:element name="shipment">
  <xs:complexType>
    <xs:choice>
      <xs:element name="pickup" type="Pickup"/>
      <xs:element name="courier" type="Courier"/>
    </xs:choice>
  </xs:complexType>
</xs:element>
```

Each member is still a property of its own, created on first access. The generator marks it `[TChoice]`:

```pascal
TShipmentE = class(TXmliteElement)
private
  fPickup: TPickupCT;
  fCourier: TCourierCT;
  function GetPickup: TPickupCT;
  function GetCourier: TCourierCT;
published
  [TChoice('Pickup')]                 // the group, named after its first member
  property Pickup: TPickupCT read GetPickup;
  [TChoice('Pickup')]
  property Courier: TCourierCT read GetCourier;
end;
```

To find out which member a document has, ask the group - this creates nothing:

```pascal
var member := shipment.Chosen('Pickup');   // the present member's object, or nil
if member is TCourierCT then
  ...
```

- The group is named after its members' common prefix: FHIR's `valueQuantity`, `valueString`... form the group `Value`, and
  the generator adds a typed shortcut for it: `Obs.ValueChosen` is `Obs.Chosen('Value')`. Without a common prefix the group
  takes its first member's name (`Pickup` above), and there is no shortcut.
- `Chosen` without a name works for a class with a single choice: `Entry.Resource.Chosen`.
- `ChosenProperty('Value')` returns the property of the present member - also for a member that is a plain value (a string,
  a number), which has no object.

To switch to another member, clear the parent first:

```pascal
shipment.Clear;                       // empties every member in place
shipment.Pickup.Point := 'Gate 4';
```

`Clear` empties objects, it does not free them: a reference to a member you keep in a variable stays valid.

If code fills two members of one choice, both are written. The document no longer matches its schema, but nothing is dropped
silently.

## Things to keep in mind

- **Looking creates.** `if order.Seller.City.XmlValue <> ''` creates an empty seller and city. They are not written, and it is no
  more than was always there before 1.7. To test whether an element is there without creating it, use the name:
  `order.IsPresent('Seller')`; for a choice, `Chosen`.
- **A getter never returns nil.** `if order.Seller = nil` is never true, and code that descends through the properties of a
  recursive type (a node with a node below) must stop where there is no content:

    ```pascal
    procedure Walk(aNode: TNodeCT);
    begin
      if not aNode.HasContent then // not "if aNode = nil"
        Exit;
      ...
      Walk(aNode.Branch);
    end;
    ```

- **No address for an object created on first access.** `Present[@Obj.Seller]`, `SetPresent(@...)` and `Clear(@...)` do not compile
  for a property with a getter (E2036); use the name: `order.IsPresent('Seller')`, `order.Clear('Seller')`. Plain values and required
  objects keep the `@` form. A name that does not exist returns `False`, so check the result where it matters.
- **Threads.** Several threads may read one object at once: the first access to an untouched member gives all of them the same
  object. Writing to it while others read still needs your own lock.
- **Reading without a copy.** `FromXml` reads a copy of the text, so your string stays as it was. For a large text
  you read once, `FromXmlInPlace(xml)` saves that copy - the read writes into `xml`, so it no longer holds the document
  afterwards: `var xml := TFile.ReadAllText(...); bundle.FromXmlInPlace(xml);`

## Hand-written classes

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
