# Limitations and notes

What of XML and XML Schema is supported, in part or not yet: [XML support](xml-support.md). This page has the notes for
using it; [XML concepts](xml-concepts.md) explains the XML Schema terms with examples. Coverage grows through real-world schemas. If yours doesn't generate or doesn't read right,
[open an issue](https://github.com/VitalyPopov/ProRock/issues/new/choose) - see also the [roadmap](roadmap.md).

## Writing a document back

A document read and written back keeps what its schema describes: values equal to their default, objects with only
defaults, absent values stay absent, enumeration texts and element order as in the schema
([presence](xmlite.md#absent-or-default-presence)), the elements the schema does not describe, and mixed content with its text
and order ([mixed content](xmlite.md#mixed-content-and-element-order)).

A value set in code that equals its default is written only when marked present (`SetPresent`) - see
[presence](xmlite.md#absent-or-default-presence).

## Large schemas

FHIR R4 and the OOXML SpreadsheetML/DrawingML schemas generate units that compile unchanged. Very large units compile slowly:
all of FHIR R4 is one unit of about 38,000 lines, which Delphi 13 compiles in a minute or more.

## Notes

- `TSoapiteError.Message`, `Detail` and `Response` are text controlled by the server and may contain its internals (stack
  traces, paths). Log them, and show your own message to end users.
- Generated string types (`TStringST = type string`) need a cast before string-helper methods:
  `string(response.Address).Replace(...)`.
- `xs:decimal`, `xs:float` and `xs:double` are `Double`, written as the shortest text that reads back the same value: a number
  of up to 15 significant digits comes back as the same number (`0.1` stays `0.1`; `1.50` is written `1.5`), a longer one
  as the same Double in its shortest text, and digits beyond what a Double holds (about 17) are lost. Arithmetic is binary floating point. For money arithmetic, convert to `Currency` before calculating:
  `var price: Currency := line.Price; var total := price * line.Quantity;`. `xs:integer` is `Int64`, `xs:unsignedLong` is
  `UInt64`.
- A property that fell back to `string` (a schema the generator reported missing) where the XML has child elements: parsing
  succeeds, the property stays empty and that content is dropped - also when written back. Add the schema and regenerate if
  that data matters.

## Platform and compatibility

Developed and tested with **Delphi 13 Florence** (13.1), mainly on **Win64**; **Win32** is supported as well. Every release is
also verified to compile and work with Delphi 12 Athens, 11 Alexandria, 10.4 Sydney and 10.3 Rio.

Large generated units compile much slower on Delphi 10.3 than on 10.4 and later.

The code uses inline variable declarations, so Delphi versions before 10.3 are not supported. Client certificates use
System.Net's support for them, which works from Delphi 12 on.

ProRock has no Windows-only dependencies: all units compile for **Android** 32/64-bit (Delphi 13). Running on a device is not
verified yet.

ProRocket Lite (the generator) runs on Windows 64-bit.
