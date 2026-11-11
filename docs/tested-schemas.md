---
icon: lucide/badge-check
hide:
  - toc
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
| HL7 FHIR R4, all 146 resource types + XHTML for the narratives | healthcare | [sample](samples.md#fhir-resources) | 49,051 | 13 s | 17 |
| HL7 CDA R2 with the SDTC extensions, from `CDA_SDTC.xsd` alone | healthcare | tested only | 9,613 | 2 s | 3 |
| UBL 2.4 (Peppol, XRechnung) | e-invoicing | [sample](samples.md#electronic-invoices) | 42,552 | 16 s | 62 |
| UN/CEFACT CII D16B (ZUGFeRD, Factur-X, XRechnung) | e-invoicing | [sample](samples.md#electronic-invoices) | 9,062 | 2 s | 957 |
| ISO 20022 pain.001.001.09, camt.053.001.08 | banking | checked for 1.7, not in every run | 7,139 | 2 s | 5 |
| BMEcat 2005.2 | product catalogs | checked for 1.7, not in every run | 6,704 | 4 s |  |
| GAEB DA XML 3.3, bill of quantities (X83) | construction | checked for 1.7, not in every run | 4,400 | 2 s |  |
| GPX 1.1 | GPS tracks | checked for 1.7, not in every run | 506 | 1 s |  |
| ECMA-376 SpreadsheetML and DrawingML | Office | [sample](samples.md#excel-workbook) | 22,734 | 5 s | 45 parts |
| OPC core and extended properties, Dublin Core | Office | [sample](samples.md#office-document-properties) | 1,578 | 1 s |  |
| EU VIES VAT service (WSDL) | SOAP | [sample](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Soapite.CheckVatService) | 271 | 1 s |  |
| WS-Security 1.0 | SOAP headers | [sample](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Soapite.WsSecurity) | 304 | 1 s |  |
| ebMS 3.0 / AS4 headers | SOAP headers | tested only | 461 | 1 s |  |
| SAML 2.0 assertions, protocol, metadata + XML Encryption, XML Signature | single sign-on | checked for 1.7, not in every run | 3,162 | 2 s |  |
| MSBuild project files (`.dproj`), from `Microsoft.Build.xsd` alone | build tools | tested only | 5,125 | 1 s | 5 |
| XML Schema, WSDL 1.1, SOAP 1.1 and 1.2 | the standards | built into ProRock | 4,302 |  |  |

<!-- table end -->

"Compiles in": all the generated units of the schema with the library, Delphi 13, Win64, on one particular machine. Yours will differ,
the order of magnitude will not. Read and write times: [Large documents](large-documents.md).

Besides these, a set of small test schemas holds the corner cases: choices, mixed content, name collisions, type names, missing
files. What of XML and XML Schema is covered construct by construct: [XML support](xml-support.md).
