# Roadmap

Plans, not promises: priorities follow real use. Themes only, no dates. The details of each release are in the
[CHANGELOG](CHANGELOG.md).

ProRock is tested against large real-world schemas - FHIR R4, Office Open XML, e-invoices, ISO 20022 and
[more](https://prorock.rocks/tested-schemas/) - and against real Excel workbooks. What they find goes into the
[known limitations](https://prorock.rocks/limitations/) and decides what comes first.

## Now

- **Calcite after 1.8**: what you ask for decides the order. Possible next, no promises:
  - Excel's extensions: the newer conditional formats and data validation, sparklines
  - tables, pivot tables and charts made and changed from code (a workbook with them already opens and saves as it was)
  - ODS, the OpenDocument spreadsheet

  What do you need most? [Open an issue](https://github.com/VitalyPopov/ProRock/issues/new/choose), with a file that shows
  it if you can.

## Next

- **Polymorphic content**: substitution groups and full `xsi:type` - a property typed with a base element or type holds any
  of its derived ones

## Later / considering

- **Jsonite**: JSON through the same classes (opens 2.x) - also the JSON side of FHIR
- **Graphite**: Word documents (docx), on top of mixed content
- more formats on the same classes: YAML, EDI (X12, EDIFACT)
- a relaxed read with a log of what it had to skip; `xsi:nil`; exact decimals
- **Android**: a sample app verified on a device

What people ask for moves items up.

## Something doesn't work?

A schema doesn't generate, or a workbook doesn't open or save right? Open an
[issue](https://github.com/VitalyPopov/ProRock/issues/new/choose) with the schema (or a link to it) or the workbook, and what
went wrong. Real-world files decide what comes next.
