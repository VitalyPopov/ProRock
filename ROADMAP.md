# Roadmap

Plans, not promises: priorities follow real use. Themes only, no dates. The details of each release are in the
[CHANGELOG](CHANGELOG.md).

We test ProRock against large real-world schemas - so far OOXML (SpreadsheetML, DrawingML) and FHIR R4. What they find
goes into the [known limitations](https://prorock.rocks/limitations/) and decides what comes first.

## Now

- **Exact round trips**: read a document, change it, write it back - and get exactly your data. Today an optional value
  equal to its default is not written, and an optional element not in the document can be written anyway. In FHIR that
  drops a patient's `gender value="male"`, in Excel the first fill and cell format. ProRock will track what is present
- **Exact XML names**: enumeration values as the schema writes them (`s`, `<=`, `text/cql`, `true` next to `True`), type
  names with dots and hyphens (`a.content`, `QuantityComparator-list`)
- **Large schemas compile**: OOXML and FHIR R4 already generate; a few generator fixes (class order, clashing field names,
  very long enumerations) make them compile without changes

## Next

- **Unknown content kept**: elements a schema does not know - Office's own extensions in every real file - kept as they
  were instead of dropped
- **Lists of plain values**: a repeating element of a simple type (several `<given>` strings)
- **Polymorphic content**: substitution groups and full `xsi:type` - a property typed with a base element or type holds any
  of its derived ones
- **OOXML end to end**: the base for Calcite (xlsx and ods, one object model)
- **Android**: a sample app verified on a device

## Later / considering

- **Jsonite**: JSON through the same classes (opens 2.x) - also the JSON side of FHIR
- more formats on the same classes: YAML, EDI (X12, EDIFACT)
- exact decimals, mixed content with child elements, Graphite (docx and odt)

## Your schema doesn't generate?

Open an [issue](https://github.com/VitalyPopov/ProRock/issues/new/choose) with the schema (or a link to it) and what went wrong.
Real-world schemas decide what comes next.
