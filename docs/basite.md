---
icon: lucide/box
---

# The core (Basite)

Basite is the object core under [Xmlite](xmlite.md) and [Soapite](soapite.md). It knows nothing about XML: it knows plain Delphi
objects and their metadata - who owns what, which values are present, which member of a choice is set. Every generated class is a
`TBasite` underneath.

You never have to touch it: generate, read, write, call. This page is for whoever wants to look under the hood, or to build on
the same objects - the controls stay simple, the mechanism is there when you want it ([a cockpit, not an engine
room](principles.md#a-cockpit-not-an-engine-room)).

## What a Basite object is

A class derived from `TBasite`, declared in the interface section of a unit, with published properties of four kinds:

| Property | Example | Created |
|---|---|---|
| a plain value | `string`, `integer`, `Double`, `Boolean`, an enumeration | holds its default from the start |
| an object | another `TBasite` | with its parent, or on first access (below) |
| a list of objects | `TBasiteList<TItem>` | with its parent |
| a list of values | `TBasiteValueList<string>` | with its parent |

Everything else comes from RTTI: no registration, no base methods to override. The parent owns its objects and lists and frees
them with itself; you free only what you create.

## Creation and initialization

`Create` sets up the whole object before your code sees it:

- a plain value gets its default: `[TDefault(3)]` or the type's zero
- an object property read from a field is created with its parent; a type nested in itself only down to
  `TBasite.AutoInitMaxDepth` levels (1 by default), so a recursive schema does not create objects without end
- an object property with a getter is created on first access, by `Lazy` in the getter
  ([Large documents](large-documents.md)); a `[TRequired]` one with its parent all the same, because it is always written
- lists are created empty

To set something up in your own class, override `Initialize` (and free it in `Deinitialize`), not the constructor. An object
created with its parent comes from an internal constructor and skips an overridden `Create`; `Initialize` runs for every object,
after its properties exist:

```pascal
TOrder = class(TBasite)
private
  fLookup: TDictionary<string, integer>;
protected
  procedure Initialize; override;
  procedure Deinitialize; override;
...

procedure TOrder.Initialize;
begin
  inherited;
  fLookup := TDictionary<string, integer>.Create;
end;

procedure TOrder.Deinitialize;
begin
  fLookup.Free;
  inherited;
end;
```

`AutoInitMaxDepth` is one global value (1 to 5): set it once at startup if you want deeper recursive objects ready without reading.

## Presence

Every object remembers which of its properties are present, one bit each: read from a document, set to something other than the
default, marked by `SetPresent`, or (an object, a list) holding content. That is how an absent optional value stays absent and a
`0` that was read is written back. The verbs work by address or by name: `Present[@Order.Count]`, `IsPresent('Count')`,
`SetPresent(...)`, `Clear(...)`, `HasContent`. [Xmlite](xmlite.md#absent-or-default-presence) shows them on XML.

`[TChoice('Group')]` puts properties into a choice group; `Chosen('Group')` returns the present member's object, `ChosenProperty`
the property itself.

## MetaBank: the metadata

The first time a class is used, Basite reads its RTTI once into a `TMetaBasite` and keeps it in `TMetaBank`: the properties in
order, their kinds, defaults, `[TRequired]`, `[TChoice]`, which ones are lazy, the field each one reads and writes directly. Every
later object of the class finds it in one step, not a search, and no document scans RTTI again. Registration is thread-safe.

The metadata is yours to read too. `Meta` on any class or object gives it, and a property's value can be read and set as text:

```pascal
for var p: TProperty in order.Meta.Properties do
  if (p.PropertyType = ptData) and order.IsPresent(p) then
    Writeln(p.Name, ' = ', TPropertyData(p).Value[order]); // id = A1
```

## MetaBank extensions: a layer's own metadata

Basite alone carries no XML. A layer adds what it needs to know through a MetaBank extension:

- **Only when your program uses it.** `ProRock.Xmlite` registers its extension as it is linked in; a program that uses
  `ProRock.Basite` alone builds none of it.
- **For every class.** From then on each class and property also gets an XML part: names, namespaces, element or attribute,
  order (`TOrderE.Meta.Xmlite.Mixed`).
- **Soapite needs none:** its messages are Xmlite classes.

This is how another format can come as another layer on the same classes ([Design principles](principles.md#progressive-in-layers)).
