# 🤟 ProRock <a href="https://prorock.rocks/"><img align="right" src="docs/pages/assets/minerals-row.webp" alt="Calcite, Soapite, Xmlite and Basite"></a>

**Excel workbooks and tamed XML in plain Delphi.** Open, change, save: nothing lost. No DOM, no XPath, no namespace juggling.

An open-source Delphi library for Excel, XML and SOAP, and a free XSD and WSDL code generator. Pure Delphi source, nothing to install: Delphi 10.3 to 13, Win64 and Win32.

## Excel (Calcite), new in 1.8

Excel workbooks in plain Delphi: no Excel, no COM, no generator.

- **Nothing lost** on open, edit and save: charts, pivot tables, tables, images, notes, print setup, external links
- Excel opens it without "We found a problem with some content"
- **A TDataSet in one call**: `ExportDataSet(Query, Sheet)`, with formats from the fields, columns fitted and the header frozen
- **Fast**: half a million cells read in under a second

```pascal
uses ProRock.Calcite;

var book := TWorkbook.Create;
try
  if book.Open('Template.xlsx') then
  begin
    var sheet := book.Worksheets['Invoice'];
    sheet.Rows['12:14'].Insert;  // totals move down
    sheet['B12'].Value := 'Consulting';
    sheet['D12'].Value := 1200;
    book.SaveAs('Invoice 1042.xlsx');
  end;
finally
  book.Free;
end;
```

## XML and SOAP

- **XML (Xmlite)**: your XSD in, ready Delphi classes out. Writes back what it read, even what the schema does not describe; an e-invoice reads in 0.15 ms; proven on HL7® FHIR® R4, e-invoices, ISO 20022 and Excel's own XML. Schema changed? Regenerate: a clean diff, and the compiler shows the rest.
- **SOAP (Soapite)**: a ready-to-use SOAP client, generated from the WSDL. Every operation is a method, with typed requests, responses and faults; SOAP 1.1 and 1.2; tested on the EU VIES VAT check.
- **ProRocket Lite**: the code generator for both (GUI and command line), Windows 64-bit, free for any use.

## Start here

Visit **[https://prorock.rocks](https://prorock.rocks/)**:

- Getting started
- The documentation
- Samples and screenshots
- The free code generator

## It is young, and it grows with you

One developer builds it, and real use is what moves it forward. Try it on your own workbooks and schemas, and [open an issue](https://github.com/VitalyPopov/ProRock/issues/new/choose) when something breaks or is missing: each one shapes the next release.

Hit the ⭐ Star so other Delphi developers can find it, and if ProRock helps you, you can [support the project](https://github.com/sponsors/VitalyPopov).

I'm genuinely grateful for **every** star, issue and kind word! Thank you 🤟
