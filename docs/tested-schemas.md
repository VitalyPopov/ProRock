---
icon: lucide/badge-check
---

# Tested schemas

The real schemas ProRock is tested on. For each of them the units are generated, compared with the expected
result and compiled with every change, except where the table says otherwise. The documents are from the last full check, in 1.7.

!!! tip "Your schema is not in the list?"
    Coverage grows through real schemas. Try it: if something does not work, please
    [open an issue](https://github.com/VitalyPopov/ProRock/issues/new/choose).

<!-- table: tests/SchemaTable.py -->

| Schema | Field | Where to see it | Generated lines | Compiles in | Real documents read and written back |
|---|---|---|---:|---:|---:|
| HL7 FHIR R4, all 146 resource types + XHTML for the narratives | healthcare | [sample](samples.md#fhir-resources) | 48,026 | 12 s | 17 |
| UBL 2.4 (Peppol, XRechnung) | e-invoicing | [sample](samples.md#electronic-invoices) | 42,417 | 15 s | 62 |
| UN/CEFACT CII D16B (ZUGFeRD, Factur-X, XRechnung) | e-invoicing | [sample](samples.md#electronic-invoices) | 9,026 | 2 s | 957 |
| ISO 20022 pain.001.001.09, camt.053.001.08 | banking | checked for 1.7, not in every run | 7,119 | 2 s | 5 |
| ECMA-376 SpreadsheetML and DrawingML | Office | [sample](samples.md#excel-workbook) | 22,680 | 4 s | 45 parts |
| OPC core and extended properties, Dublin Core | Office | [sample](samples.md#office-document-properties) | 1,506 | 1 s |  |
| EU VIES VAT service (WSDL) | SOAP | [sample](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Soapite.CheckVatService) | 253 | 1 s |  |
| WS-Security 1.0 | SOAP headers | [sample](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Soapite.WsSecurity) | 286 | 1 s |  |
| ebMS 3.0 / AS4 headers | SOAP headers | tested only | 452 | 1 s |  |
| XML Schema, WSDL 1.1, SOAP 1.1 and 1.2 | the standards | built into ProRock | 4,230 |  |  |

<!-- table end -->

"Compiles in": all the generated units of the schema with the library, Delphi 13, Win64, on one particular machine. Yours will differ,
the order of magnitude will not. Read and write times: [Large documents](large-documents.md).

Besides these, a set of small test schemas holds the corner cases: choices, mixed content, name collisions, type names, missing
files. What of XML and XML Schema is covered construct by construct: [XML support](xml-support.md).
