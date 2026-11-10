---
icon: lucide/file-code
---

# Generated code

What the generator makes of a schema. You will rarely need this page, because code completion shows the classes; it is here for
when you wonder why something looks the way it does.

!!! tip "Two recommendations"
    - **Regenerate rather than edit.** A run overwrites the units of the same names. If you know what you are doing, change a unit and
      keep it changed, just do not run the generator over it.
    - **Keep the versions together.** Use the ProRock release named in the unit header. Other pairs mostly work, but there are breaking
      changes sometimes, and both are improving all the time, so regenerate when you update ProRock.

## From XSD to Delphi

| XSD | Delphi |
|---|---|
| complex type, element | a class |
| enumeration | a Delphi enum |
| `maxOccurs > 1` | a typed list: of objects, or of values (`TXmliteValueList<T>`, a `TList<T>`) for a simple type |
| `xs:string`, `xs:token`, ... | `string` types (`TStringST = type string`) |
| `xs:integer`, `xs:long`, `xs:int`, `xs:short`, ... | `Int64` types |
| `xs:unsignedLong` and its derived types | `UInt64` types |
| `xs:decimal`, `xs:float`, `xs:double` | `Double` types |
| `xs:boolean` | `Boolean` |
| `xs:date`, `xs:dateTime`, `xs:duration`, ... | `string` types: the text as in the document |
| simpleContent (text plus attributes) | the text in `XmlValue`, the attributes as properties |

`TStringST` is `type string`, so string-helper methods need a cast: `string(response.Address).Replace(...)`.

Facets (lengths, patterns, ranges) are not validated: a 2-character code is a plain string type.

## Units

**One unit per XML namespace**, `ProRock.Xmlite.Schema.<Name>.pas`, so the units of a schema set use each other as the schemas
import each other. Several files of one namespace (`xs:include`) give one unit. The name comes from the last segment of the
namespace URI:

| Namespace | Unit name |
|---|---|
| `urn:example:orders`, `http://example.com/schemas/order` | `Orders`, `Order` |
| a version alone takes the segment before it: `urn:example:orders:2`, `.../orders/v2` | `Orders2`, `OrdersV2` |
| a file name loses its extension: `.../oasis-200401-wss-wssecurity-secext-1.0.xsd` | `Oasis200401WssWssecuritySecext10` |
| well-known namespaces: SOAP, WSDL, XML Schema, WS-Security, ebMS 3.0 / AS4 | fixed names (`WsSecurity`, `Ebms3`, ...) |

**One client unit per `wsdl:service`**, `ProRock.Soapite.<Service>.pas`. Schemas embedded in the WSDL go into
`ProRock.Xmlite.Schema.<Service>.pas`. The client unit re-exports the request and response types, `TSoapiteError` and the
exceptions, so for plain calls it is the only unit to put in `uses`.

**Each unit checks the ProRock it compiles with.** A release that changes what regenerating gives raises ProRock's code level,
and the [changelog](changelog.md) says why; a release that does not keeps it, so most updates warn about nothing.

| When | The compiler says |
|---|---|
| ProRock has a higher code level than the unit | warning: `Generated for an older ProRock: regenerate this unit` |
| ProRock has a lower code level than the unit | error: `Generated for a newer ProRock: update ProRock` |
| ProRock 1.6 or older | error: `Needs ProRock 1.7 or later` |

The unit keeps working as it did; the warning only says that regenerating brings something. `PROROCK_NO_REGENERATE_WARNING` in the
project's defines silences it. Delphi shows a message when it compiles the unit: after an update the units recompile and warn, a
later Make reuses them quietly, a Build warns again. Units generated before 1.7 have no check.

## Type names

`T` + the XML name + a suffix for its kind: `CT` a complex type, `ST` a simple type, `AG` an attribute group, `EG` an element group,
`E` an element. What all the types of one kind in a namespace share says nothing about any of them, so it stays out of the Delphi
name, and the exact XML name is kept in `[TName]`:

- `CT_Font` -> `TFontCT` where every complex type starts with `CT_`
- `InvoiceType` -> `TInvoiceCT` where every one ends with `Type`

The fine print:

- A part stays when it is a word of the names: `CT_Picture` next to `CT_PictureNonVisual` gives `TPictureCT` and
  `TPictureNonVisualCT`, `Amount` next to `SmallAmount` stays as it is.
- A part without a separator needs at least three types (`CT_` needs two), and a type alone keeps its whole name.
- If two types would get one name, or a new name is another type's old one, the type keeps its old name.
- Adding a type without the shared part to a schema brings the whole name back for that kind, so a new schema version can
  rename types. `--full-type-names` always keeps the whole name, if that matters more, or if a name reads badly.

!!! note "Units generated before 1.7"
    They used the whole names. Those remain as `deprecated` aliases until 2.0.

## Member names

Members follow the XML names in Delphi style. The XML names come back from the Delphi names by the schema's own styles, which
`RegisterNamespace` at the end of the unit states (FHIR: `TNaming.nPascalCase, TNaming.nCamelCase, TNaming.nKebabCase`, for types,
for the elements and attributes inside them, for enumeration items). `[TEnumNaming]` marks a list named differently; `[TNaming]`,
`[TName]` and `[TEnumCaption]` appear only where those do not give the exact name.

## When names collide

Delphi ignores case and has names of its own, and schemas do not care. One rule covers every case, and the XML name is always kept:

- **Two schema names meeting: a number from 2**, in schema order, elements before attributes, ancestors before the class.
  `item` and `Item` give `Item` and `Item2`; an element repeated by two extensions gives `Note`, `Note2`, `Note3`; for an element
  and an attribute of one name, the element keeps it.
- **A schema name meeting Delphi or the library: a trailing `_`**, after the number. FHIR's `meta` is `Meta_`, because `Meta` is the
  class metadata, and `add` is `Add_`. With both `meta` and `Meta` in a class: `Meta_`, `Meta2`.
- SOAP operations likewise, together with their `Try` twins: `Call` gives `Call_` and `TryCall_`; `Foo` and `foo` give `Foo`,
  `Foo2`, `TryFoo2`.

ProRock's own members keep their names, and new ones take the `Xml` prefix, so a later version does not rename an element of yours.

## Objects and choices

- Lists and required objects are created with their parent and freed with it. Optional objects are created on first access, so
  a getter never returns `nil` ([Large documents](large-documents.md)).
- A member of an `xs:choice` is a property of its own. Which one the document has: `Chosen`, as in `Entry.Resource.Chosen`, or a
  typed shortcut such as `Obs.ValueChosen` for FHIR's `value[x]` ([Choices](large-documents.md#choices-one-of-several)).
- A property that fell back to `string` because of a [missing schema](cli.md#problem-lines), where the XML has child elements: parsing
  succeeds, the property stays empty, and that content is dropped, also when written back. Resolve the problem and regenerate if
  that data matters.
