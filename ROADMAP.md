# Roadmap

Plans, not promises: priorities follow real use. Themes only, no dates. The details of each release are in the
[CHANGELOG](CHANGELOG.md).

We test ProRock against large real-world schemas - so far FHIR R4 and Office Open XML (SpreadsheetML, DrawingML). What they
find goes into the [known limitations](https://prorock.rocks/limitations/) and decides what comes first.

## Now

- **E-invoicing and ISO 20022**: the schemas behind today's legal and banking requirements, explored end to end the way
  FHIR and Excel were - with a sample
- **Nicer generated names**: schema naming conventions (`CT_Font`, `FontType`) left out of the class names, the XML names
  kept exact - with a way for code written against the current names to keep compiling

## Next

- **Calcite**: Excel workbooks through plain objects - sheets, cells, styles, tables - read, changed and written back with
  everything in them; OOXML end to end
- **Polymorphic content**: substitution groups and full `xsi:type` - a property typed with a base element or type holds any
  of its derived ones

## Later / considering

- **Jsonite**: JSON through the same classes (opens 2.x) - also the JSON side of FHIR
- **Graphite**: Word documents (docx), on top of mixed content
- more formats on the same classes: YAML, EDI (X12, EDIFACT)
- a relaxed read with a log of what it had to skip; `xsi:nil`; schemas without a target namespace; exact decimals
- **Android**: a sample app verified on a device

What people ask for moves items up.

## Your schema doesn't generate?

Open an [issue](https://github.com/VitalyPopov/ProRock/issues/new/choose) with the schema (or a link to it) and what went wrong.
Real-world schemas decide what comes next.
