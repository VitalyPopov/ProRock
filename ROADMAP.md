# Roadmap

Plans, not promises: priorities follow real use. Themes only, no dates. The details of each release are in the
[CHANGELOG](CHANGELOG.md).

ProRock is tested against large real-world schemas - FHIR R4, Office Open XML, e-invoices, ISO 20022 and
[more](https://prorock.rocks/tested-schemas/). What they find goes into the [known limitations](https://prorock.rocks/limitations/)
and decides what comes first.

## Now

- **Calcite**: Excel workbooks through plain objects - sheets, cells, styles, tables - read, changed and written back with
  everything in them; OOXML end to end

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

## Your schema doesn't generate?

Open an [issue](https://github.com/VitalyPopov/ProRock/issues/new/choose) with the schema (or a link to it) and what went wrong.
Real-world schemas decide what comes next.
