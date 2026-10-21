# Roadmap

Plans, not promises: priorities follow real use. Themes only, no dates. The details of each release are in the
[CHANGELOG](CHANGELOG.md).

We test ProRock against large real-world schemas - so far OOXML (SpreadsheetML, DrawingML) and FHIR R4. What they find
goes into the [known limitations](https://prorock.rocks/limitations/) and decides what comes first.

## Now

- **Unknown content kept**: elements a schema does not know - Office's own extensions in every real file - kept as they
  were instead of dropped. With it, an Office document read and written back stays complete
- **Lists of plain values**: a repeating element of a simple type (several `<given>` strings) - the last thing between the
  OOXML schemas and units that compile unchanged

## Next

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
