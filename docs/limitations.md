# Limitations and notes

Coverage grows through real-world schemas. If yours doesn't generate or doesn't read right,
[open an issue](https://github.com/VitalyPopov/ProRock/issues/new/choose) - see also the [roadmap](roadmap.md).

## Writing a document back

Reading works well, also for large schemas. Writing a document you have read back is **not yet exact** - the first
items on the [roadmap](roadmap.md):

- **Absent vs default**: an optional value equal to its default is not written, and an object whose values are all
  defaults is not written at all. An enumeration's first value is its default - FHIR's `gender value="male"`,
  `use value="usual"` - so such values are lost; in an Excel style sheet the first fill and cell format disappear from
  their lists. The other way round, an absent optional value reads as its default (an absent enumeration reads as its
  first value)
- **Elements that were not there**: an optional child element whose type has a required attribute can be written with an
  empty value although the document did not have it (OOXML `<drawing r:id=""/>`)
- **Enumeration values** are written back from the Delphi names: a one-letter value comes back in upper case (OOXML
  `t="s"` as `t="S"`)
- **Unknown elements** are dropped: elements not in the schema, like Office's own extensions (`mc:AlternateContent`, the
  content of `extLst`). Unknown attributes are kept
- **Mixed content** (text interleaved with child elements) is kept only partially (`XmlText`): text after an inline
  element is lost (XHTML `<p>Peter <b>James</b>, born 1974</p>`). Mixed content where no child element can occur is plain
  text (`XmlValue`)

## Generated code that does not compile yet

Large schemas generate, but some of their units need changes before Delphi compiles them (found with OOXML and FHIR R4):

- names with dots (XHTML `a.content`, FHIR `Account.Coverage`)
- enumeration values that are no identifiers (`<`, `text/cql`, `0.0.80`) or differ only in case (`true` and `True`)
- a class declared before its parent class; field names clashing with another property (attributes `c` and `fc`)
- an enumeration with very many values (more than 1023 characters on one line)
- a repeating element of a simple type (a list of strings) - generated as a list type that does not exist

Very large units compile slowly: all of FHIR R4 is one unit of 35,000 lines, about 50 seconds for Delphi.

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
