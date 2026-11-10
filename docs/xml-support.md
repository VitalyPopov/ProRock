---
icon: lucide/list-checks
---

# XML support

What of XML and XML Schema works, what works in part, and what is not covered yet. The real schemas it is all tested on:
[Tested schemas](tested-schemas.md).

!!! note "ProRock reads and writes, it does not validate"
    Documents are not checked against their schema. What does not fit is [kept and written back](xmlite.md#content-the-schema-does-not-describe).

## The document

| | | <span class="status-legend">✅ supported · 🟡 in part · ⏳ not yet · ❌ not supported</span> |
|---|---|---|
| Elements, attributes, text | ✅ | |
| Namespaces and prefixes | ✅ | any prefixes on read; the document's declarations are written back, its elements with each namespace's own prefix, which can differ from the document's |
| Character and entity references | ✅ | `&amp;`, `&lt;`, `&#65;`, `&#x42;` |
| CDATA sections | ✅ | read as text as it is, written escaped (`a&lt;b`) |
| Comments, processing instructions, DOCTYPE | ✅ | skipped on read, not written back |
| Entities declared in a DTD | ❌ | `&name;` stays text - which also rules out entity-expansion attacks |
| `xml:space="preserve"` | ✅ | written for text with leading or trailing spaces in Office's namespaces, which trim it otherwise; elsewhere the spaces are kept without it, as a schema's simple type has no such attribute |
| Attributes the schema does not know | ✅ | kept and written back - not on an element of a plain value, which has no place for them ([Limitations](limitations.md)) |
| Elements the schema does not know | ✅ | kept as their exact text and written back where they were - Office's own extensions (`extLst`, `mc:AlternateContent`) survive a round trip ([Xmlite](xmlite.md#content-the-schema-does-not-describe)) |
| Values that do not fit their type | ✅ | `12,50` in a decimal, `XXX` in an enumeration, an empty number: the property is not present, the value is kept and written back as it came, attributes and list items too; setting the property replaces it. CDATA in such a value comes back as escaped text |
| Malformed XML | ✅ | the read fails: `FromXml` returns `False` - tags not closed or crossed, an undeclared prefix in kept content |
| Mixed content | ✅ | text runs and child elements in document order (`XmlContent`, `InnerText`) - a FHIR narrative round-trips; text-only mixed content is plain text (`XmlValue`) ([Xmlite](xmlite.md#mixed-content-and-element-order)) |

## Structures

| | | <span class="status-legend">✅ supported · 🟡 in part · ⏳ not yet · ❌ not supported</span> |
|---|---|---|
| Sequences, element order | ✅ | written in the schema's order |
| Choices | ✅ | members created on first access; `Chosen` tells which is there ([Large documents](large-documents.md)) |
| `xs:all` | ✅ | |
| Repeating elements | ✅ | typed lists - of objects, or of plain values: `Authors.Author.Add('Ann')` |
| A repeating choice in mixed order | ✅ | `<a/><b/><a/>`: each member in its own list, their order across members in `XmlContent` (`[TOrdered]`) |
| Groups, attribute groups, references | ✅ | a reference to an element of a simple type is a plain value |
| Anonymous (inline) types | ✅ | |
| Presence: absent vs. default | ✅ | `Present`, `SetPresent`, `Clear` ([Xmlite](xmlite.md#absent-or-default-presence)) |
| `xs:any` | ✅ | elements of namespaces with generated units are read as objects; others are kept as text |
| `xs:anyAttribute` | 🟡 | such attributes are kept as attributes the schema does not know, not typed |
| `elementFormDefault="unqualified"` | 🟡 | read correctly; on write, local elements get the parent's default namespace |

## Types

| | | <span class="status-legend">✅ supported · 🟡 in part · ⏳ not yet · ❌ not supported</span> |
|---|---|---|
| Built-in simple types | ✅ | strings, integers, decimals, booleans, dates as text ([Generated code](generated-code.md#from-xsd-to-delphi)) |
| Enumerations | ✅ | Delphi enums; the exact texts are kept (`true` and `True` are two values) |
| Restrictions | 🟡 | the base type is used; facets (patterns, lengths, ranges) are not checked |
| Lists (`xs:list`) | 🟡 | `"1 2 3"` is read and written as the text it is, a string |
| Unions | 🟡 | the text as written, unless the union has one named member type |
| Defaults | ✅ | default values, written only when present or required |
| `xsi:nil` | ⏳ | a nil element reads as its default and is written with a value |
| Exact decimals | 🟡 | `xs:decimal` is a `Double`: up to 15 significant digits come back as the same number, beyond about 17 they are lost ([notes](limitations.md#numbers)) |
| Text with attributes (simpleContent) | ✅ | the text in `XmlValue`, the attributes as properties |
| Complex types by extension or restriction | ✅ | an extension is a Delphi descendant; a restriction a class of its own |

## Polymorphism

| | | <span class="status-legend">✅ supported · 🟡 in part · ⏳ not yet · ❌ not supported</span> |
|---|---|---|
| Derived types with `xsi:type` | 🟡 | written with `SetXsiType`; on read the attribute is kept and written back, but the object stays the declared class - members only the derived type has are not read |
| Substitution groups | 🟡 | a member gets its head's type; a property of the head's type does not hold members yet |

## Schema sets

| | | <span class="status-legend">✅ supported · 🟡 in part · ⏳ not yet · ❌ not supported</span> |
|---|---|---|
| Imports (other namespaces) | ✅ | one unit per namespace, units use each other |
| Includes (the same namespace) | ✅ | several files, one unit |
| Schemas without `targetNamespace` | ⏳ | including "chameleon" includes |
| `xs:redefine` | ❌ | reported by the generator |
| WSDL 1.1, SOAP document/literal | ✅ | rpc/encoded operations are skipped (listed in the generated unit's header) |

What is planned next is on the [roadmap](roadmap.md). A schema that does not generate or read right is worth an
[issue](https://github.com/VitalyPopov/ProRock/issues/new/choose): coverage grows through real-world schemas.
