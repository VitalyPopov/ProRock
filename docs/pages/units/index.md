---
icon: lucide/package
---

# Using ProRock

ProRock keeps your `uses` short: usually one unit for the job (Calcite for Excel, your generated unit for XML or SOAP).
Add the others only when you need what they give.

The units below and the generated `ProRock.Xmlite.Schema.*` are the ones to use. Every other unit in `Source` is internal:
usable, but not designed to be used directly.

---

## Excel

### ProRock.Calcite { .uses }

Excel workbooks (.xlsx): open, change and save with nothing lost.

- `TWorkbook`: `Open`, `Save`, `SaveAs`
- `book.Worksheets['Invoice']`, the cells as `sheet['B12'].Value`
- `sheet.Rows['12:14'].Insert` and `Delete`: formulas, charts and tables move with them
- `book.Error` when `Open` or `Save` answers `False`, `book.Issues` for changes Calcite refused

More: [Excel (Calcite)](../calcite.md).

### ProRock.Calcite.Data { .uses }

A TDataSet to a sheet, with formats from the fields, columns fitted and the header frozen.

- `ExportDataSet(Query, Sheet)`

More: [A DataSet to a sheet](../calcite.md#a-dataset-to-a-sheet).

### ProRock.Office.Ooxml { .uses }

Any Office file (.xlsx, .docx, .pptx) as a package: parts read on first use, untouched bytes kept, nothing lost on save.

- `TPackageOoxml`: `Open`, `Save`, `SaveAs`
- `Properties`: the document's Title, Subject, Creator, Keywords...
- `Part<T>` to read a part, `EditPart<T>` to change it

More: the [Office document properties](../samples.md#office-document-properties) sample.

---

## SOAP

### ProRock.Soapite { .uses }

SOAP clients: the units you generate from a WSDL build on it.

- `TSoapiteClient`, the base of every generated client: `Endpoint`, `SoapVersion`, `Transport`
- every operation in two forms: `TryCheckVat` returns `False` and a `TSoapiteError`, `CheckVat` raises
- `OnRequest` and `OnResponse` to log the XML

More: [SOAP (Soapite)](../soapite.md).

### ProRock.Http { .uses }

The HTTP transport for SOAP clients.

- `THttpTransportNative`: timeouts, authentication, certificates
- `THttpTransport` to write your own

More: [Transport](../soapite.md#transport-timeouts-authentication-certificates).

---

## XML

### ProRock.Xmlite { .uses }

XML to objects and back, through the classes generated from your XSD.

- `FromXml` to read, `ToXml` to write
- `TXmlite`, the base of every generated class
- content the schema does not describe, kept and written back

More: [XML (Xmlite)](../xmlite.md).

---

## The core

### ProRock.Basite { .uses }

Plain Delphi objects described by their metadata: who owns what, which values are present.

- `TBasite` and `TBasiteList<T>`, the base of every object and list
- attributes such as `[TRequired]` and `[TChoice('Delivery')]` for classes you write yourself

More: [The core (Basite)](../basite.md) and [Hand-written classes](../hand-written.md).

---

## Generated units

Units you generate with [ProRocket Lite](../prorocket-lite/index.md):

- `ProRock.Xmlite.Schema.<Name>` from an XSD
- `ProRock.Soapite.<Service>` from a WSDL

More: [Generated code](../generated-code.md).

ProRock comes with generated units of its own in `Source`, such as `ProRock.Xmlite.Schema.Envelope` for SOAP and
`ProRock.Xmlite.Schema.Ooxml.Sml` for Excel. Calcite and Soapite use them; you rarely name them.
