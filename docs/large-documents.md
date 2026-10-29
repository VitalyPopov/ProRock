# Large documents

Since 1.6, the members of a choice are created when your code first touches them, not together with their parent. A schema that
offers many alternatives - FHIR's resource container has 146 - no longer costs a full set of objects for each one. Nothing
changes in how you use the classes: create, read, work, write, free.

| A FHIR R4 Bundle of 1,000 Patients (1.8 MB) | 1.5 | 1.6 |
|---|---|---|
| read | 11.9 s | 0.10 s |
| write | 6.7 s | 0.08 s |
| free | 10.0 s | 0.05 s |
| objects in memory | 52.6 million | 94,000 |

Measured with Delphi 13, Win64. Reading the same 1,000 Patients one by one takes 0.09 s, so the Bundle now costs about what
its content does.

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

Each member is still a property of its own. The generator marks it `[TChoice]` and gives an object member a getter, which
creates the object on first access:

```pascal
TShipmentE = class(TXmliteElement)
private
  fPickup: TPickupCT;
  fCourier: TCourierCT;
  function GetPickup: TPickupCT;
  function GetCourier: TCourierCT;
published
  [TChoice('Pickup')]
  property Pickup: TPickupCT read GetPickup;
  [TChoice('Pickup')]
  property Courier: TCourierCT read GetCourier;
end;
```

Every other object is created with its parent, as before.

## Working with a choice

```pascal
shipment.Courier.Address.City := 'Dubai';   // touching a member creates it
TFile.WriteAllText('shipment.xml', shipment.ToXml, TEncoding.UTF8);  // only members with content are written
```

Reading creates only the member that is in the document. To find out which one it is, ask the group - this creates nothing:

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

- **Looking creates.** `if shipment.Courier.Address.City <> ''` creates an empty courier. It is not written (it has no
  content), but to test which member is there, `Chosen` is cheaper and clearer.
- **A recursive walk stops at empty objects, not at nil.** A getter always returns an object, so code that descends through
  the properties of a recursive type (a node with a node below) must stop where there is no content:

    ```pascal
    procedure Walk(aNode: TNodeCT);
    begin
      if not aNode.HasContent then // not "if aNode = nil": a getter never returns nil
        Exit;
      ...
      Walk(aNode.Branch);
    end;
    ```

- **No address for a choice member.** `Present[@Obj.Pickup]`, `SetPresent(@...)` and `Clear(@...)` do not compile for a
  property with a getter; use the name: `shipment.IsPresent('pickup')`, `shipment.Clear('pickup')`.
- **Threads.** Reading one object from several threads at once is safe for members already created; the first access to an
  untouched member creates it, so do that from one thread.
- **Reading without a copy.** `FromXml` reads a copy of the text, so your string stays as it was. For a large text
  you read once, `FromXmlInPlace(xml)` saves that copy - the read writes into `xml`, so it no longer holds the document
  afterwards: `var xml := TFile.ReadAllText(...); bundle.FromXmlInPlace(xml);`

## Hand-written classes

The same works for your own classes: an object property with a getter is not created with its parent. Keep a field named
`f` + the property name - the reader and writer use the field directly - and create the object in the getter with `Lazy`:

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
`Chosen`.
