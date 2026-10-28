# Limitations and notes

Coverage grows through real-world schemas. If yours doesn't generate or doesn't read right,
[open an issue](https://github.com/VitalyPopov/ProRock/issues/new/choose) - see also the [roadmap](roadmap.md).

## Writing a document back

A document read and written back keeps what its schema describes: values equal to their default, objects with only
defaults, absent values stay absent, enumeration texts and element order as in the schema
([presence](xmlite.md#absent-or-default-presence)). Not yet:

- **Unknown elements** are dropped: elements not in the schema, like Office's own extensions (`mc:AlternateContent`, the
  content of `extLst`). Unknown attributes are kept
- **Mixed content** (text interleaved with child elements) is kept only partially (`XmlText`): text after an inline
  element is lost (XHTML `<p>Peter <b>James</b>, born 1974</p>`). Mixed content where no child element can occur is plain
  text (`XmlValue`)
- a value set in code that equals its default is written only when marked present (`SetPresent`) - see
  [presence](xmlite.md#absent-or-default-presence)

## Large schemas

FHIR R4 and the OOXML SpreadsheetML/DrawingML schemas generate units that compile unchanged. Very large units compile slowly:
all of FHIR R4 is one unit of about 49,000 lines, about 50 seconds for Delphi.

## Not covered yet

- **Elements standing in for their head**: a substitution group member gets its head's type, but a property of the head's type
  does not yet hold any member
- with `elementFormDefault="unqualified"`, local elements are written in the parent's default namespace (reading is fine)
- unions hold their value as written (a `string`, unless the union has exactly one named member type); facets (patterns,
  ranges, lengths) are not validated
- schemas without `targetNamespace` (including "chameleon" includes) cannot be loaded by the generator yet
- SOAP rpc/encoded operations are skipped by the generator (listed in the generated unit header)

[XML concepts for Delphi developers](xml-concepts.md) explains these terms with examples.

## Notes

- `TSoapiteError.Message`, `Detail` and `Response` are text controlled by the server and may contain its internals (stack
  traces, paths). Log them, and show your own message to end users.
- Generated string types (`TStringST = type string`) need a cast before string-helper methods:
  `string(response.Address).Replace(...)`.
- `xs:decimal`, `xs:float` and `xs:double` are `Double`: values up to about 15 significant digits read and write back unchanged,
  but arithmetic is binary floating point. For money arithmetic, convert to `Currency` before calculating:
  `var price: Currency := line.Price; var total := price * line.Quantity;`. `xs:integer` is `Int64`, `xs:unsignedLong` is
  `UInt64`.
- A property that fell back to `string` (a schema the generator reported missing) where the XML has child elements: parsing
  succeeds, the property stays empty and that content is dropped - also when written back. Add the schema and regenerate if
  that data matters.

## Platform and compatibility

Developed and tested with **Delphi 13 Florence** (13.1), mainly on **Win64**; **Win32** is supported as well. Every release is
also verified to compile and work with Delphi 12 Athens, 11 Alexandria, 10.4 Sydney and 10.3 Rio.

The code uses inline variable declarations, so Delphi versions before 10.3 are not supported. Client certificates use
System.Net's support for them, which works from Delphi 12 on.

ProRock has no Windows-only dependencies: all units compile for **Android** 32/64-bit (Delphi 13). Running on a device is not
verified yet.

ProRocket Lite (the generator) runs on Windows 64-bit.
