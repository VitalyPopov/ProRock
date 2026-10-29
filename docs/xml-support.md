# XML support

ProRock reads and writes XML through classes generated from XSD and WSDL. These real-world schema sets generate units that
compile, and documents read and write back with them:

- **FHIR R4** (HL7) - all resources, a Bundle of 1,000 Patients read in 0.1 s ([Large documents](large-documents.md))
- **Office Open XML** - SpreadsheetML and DrawingML (main, chart, picture, spreadsheet drawing), the package's core and
  extended properties ([sample](samples.md#office-document-properties)) on Dublin Core
- **SOAP 1.1 and 1.2**, WSDL 1.1, WS-Security, ebMS 3.0 messaging headers, the EU VIES VAT service
  ([samples](samples.md))

This page lists what of XML and XML Schema works, what works in part, and what is not covered yet. ProRock reads and writes
documents; it does not validate them against their schema.

## The document

| | Status | Notes |
|---|---|---|
| Elements, attributes, text | supported | |
| Namespaces and prefixes | supported | any prefixes on read; the document's declarations are written back, its elements with each namespace's own prefix, which can differ from the document's |
| Character and entity references | supported | `&amp;`, `&lt;`, `&#65;`, `&#x42;` |
| CDATA sections | supported | read as text as it is, written escaped (`a&lt;b`) |
| Comments, processing instructions, DOCTYPE | supported | skipped on read, not written back |
| Entities declared in a DTD | not supported | `&name;` stays text - which also rules out entity-expansion attacks |
| `xml:space="preserve"` | supported | written for text with leading or trailing spaces |
| Attributes the schema does not know | supported | kept and written back |
| Elements the schema does not know | supported | kept as their exact text and written back where they were - Office's own extensions (`extLst`, `mc:AlternateContent`) survive a round trip ([Xmlite](xmlite.md#content-the-schema-does-not-describe)) |
| Malformed XML | supported | the read fails: `FromXml` returns `False` - tags not closed or crossed, an undeclared prefix in kept content |
| Mixed content | supported | text runs and child elements in document order (`XmlContent`, `InnerText`) - a FHIR narrative round-trips; text-only mixed content is plain text (`XmlValue`) ([Xmlite](xmlite.md#mixed-content-and-element-order)) |

## Structures

| | Status | Notes |
|---|---|---|
| Sequences, element order | supported | written in the schema's order |
| Choices | supported | members created on first access; `Chosen` tells which is there ([Large documents](large-documents.md)) |
| `xs:all` | supported | |
| Repeating elements | supported | typed lists - of objects, or of plain values: `Authors.Author.Add('Ann')` |
| A repeating choice in mixed order | supported | `<a/><b/><a/>`: each member in its own list, their order across members in `XmlContent` (`[TOrdered]`) |
| Groups, attribute groups, references | supported | a reference to an element of a simple type is a plain value |
| Anonymous (inline) types | supported | |
| Presence: absent vs. default | supported | `Present`, `SetPresent`, `Clear` ([Xmlite](xmlite.md#absent-or-default-presence)) |
| `xs:any` | supported | elements of namespaces with generated units are read as objects; others are kept as text |
| `xs:anyAttribute` | partial | such attributes are kept as attributes the schema does not know, not typed |
| `elementFormDefault="unqualified"` | partial | read correctly; on write, local elements get the parent's default namespace |

## Types

| | Status | Notes |
|---|---|---|
| Built-in simple types | supported | strings, integers, decimals, booleans, dates as text ([Xmlite](xmlite.md#what-the-generator-makes-of-a-schema)) |
| Enumerations | supported | Delphi enums; the exact texts are kept (`true` and `True` are two values) |
| Restrictions | partial | the base type is used; facets (patterns, lengths, ranges) are not checked |
| Lists (`xs:list`) | partial | `"1 2 3"` is read and written as the text it is, a string |
| Unions | partial | the text as written, unless the union has one named member type |
| Defaults | supported | default values, written only when present or required |
| `xsi:nil` | not yet | a nil element reads as its default and is written with a value |
| Exact decimals | partial | `xs:decimal` is a `Double`: about 15 significant digits ([notes](limitations.md#notes)) |
| Text with attributes (simpleContent) | supported | the text in `XmlValue`, the attributes as properties |
| Complex types by extension or restriction | supported | an extension is a Delphi descendant; a restriction a class of its own |

## Polymorphism

| | Status | Notes |
|---|---|---|
| Derived types with `xsi:type` | partial | written with `SetXsiType`; on read the attribute is kept and written back, but the object stays the declared class - members only the derived type has are not read |
| Substitution groups | partial | a member gets its head's type; a property of the head's type does not hold members yet |

## Schema sets

| | Status | Notes |
|---|---|---|
| Imports (other namespaces) | supported | one unit per namespace, units use each other |
| Includes (the same namespace) | supported | several files, one unit |
| Schemas without `targetNamespace` | not yet | including "chameleon" includes |
| `xs:redefine` | not supported | reported by the generator |
| WSDL 1.1, SOAP document/literal | supported | rpc/encoded operations are skipped (listed in the generated unit's header) |

What is planned next is on the [roadmap](roadmap.md). A schema that does not generate or read right is worth an
[issue](https://github.com/VitalyPopov/ProRock/issues/new/choose): coverage grows through real-world schemas.
