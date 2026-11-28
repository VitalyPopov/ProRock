---
icon: lucide/house
hide:
  - toc
---

# ProRock { .hero-hidden }

<div class="hero"><div class="hero-top"><div class="hero-name">🤟 Pro<span>Rock</span></div><div class="hero-minerals"><a href="calcite/" title="Excel (Calcite)"><img src="assets/calcite.webp" alt=""><span>Calcite</span><em>NEW</em></a><a href="soapite/" title="SOAP (Soapite)"><img src="assets/soapite.webp" alt=""><span>Soapite</span></a><a href="xmlite/" title="XML (Xmlite)"><img src="assets/xmlite.webp" alt=""><span>Xmlite</span></a><a href="basite/" title="The core (Basite)"><img src="assets/basite.webp" alt=""><span>Basite</span></a></div></div><div class="hero-main"><div class="hero-lines"><div class="hero-claim">Excel workbooks and tamed XML in plain Delphi</div><p class="hero-sub">Open, change, save: nothing lost. No DOM, no XPath, no namespace juggling.</p><p class="hero-second">An open-source Delphi library for Excel, XML and SOAP, and a free XSD and WSDL code generator.</p></div><ul class="hero-facts"><li>Pure Delphi source</li><li>Nothing to install</li><li>Win64 / Win32</li><li>Delphi 10.3+</li></ul></div></div>

<div class="panes" markdown>

=== "Excel (Calcite)"

    Excel workbooks in plain Delphi: no Excel, no COM

    [Docs](calcite/){ .md-button .md-button--primary } [Samples](samples/#excel-workbook){ .md-button }
    { .pane-buttons }

    - Nothing lost on open, edit and save: charts, pivot tables, tables, images, notes, print setup, external links
    - Excel opens it without "We found a problem with some content"
    - A TDataSet in one call: `ExportDataSet(Query, Sheet)`, with formats from the fields, columns fitted and the header frozen
    - Half a million cells read in under a second

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

=== "SOAP (Soapite)"

    A ready-to-use SOAP client, generated from the WSDL

    [Docs](soapite/){ .md-button .md-button--primary } [5-minute start](getting-started/#soap){ .md-button } [Free generator](prorocket-lite/){ .md-button }
    { .pane-buttons }

    - Every operation is a method, with typed requests, responses and faults
    - SOAP 1.1 and 1.2
    - Tested on real services: the EU VIES VAT check
    - From a WSDL to a working call in 5 minutes

    ```pascal
    uses ProRock.Soapite.CheckVatService;

    var service := TCheckVatService.Create(
      'https://ec.europa.eu/taxation_customs/' +
      'vies/services/checkVatService');
    var request := TCheckVatE.Create;
    try
      request.CountryCode := 'IE';
      request.VatNumber := '6388047V';
      var response := service.CheckVat(request);
      Writeln(response.Name, ' - valid: ', response.Valid);
      response.Free;
    finally
      request.Free;
      service.Free;
    end;
    ```

=== "XML (Xmlite)"

    Your XSD in, ready Delphi classes out

    [Docs](xmlite/){ .md-button .md-button--primary } [Samples](samples/){ .md-button } [Tested schemas](tested-schemas/){ .md-button } [Free generator](prorocket-lite/){ .md-button }
    { .pane-buttons }

    - Writes back what it read, even what the schema does not describe
    - An e-invoice reads in 0.15 ms, 1,000 FHIR resources (3.2 MB) in 160 ms
    - Proven on FHIR R4, e-invoices, ISO 20022 and Excel's own XML
    - Schema changed? Regenerate: a clean diff, and the compiler shows the rest

    ```pascal
    uses ProRock.Xmlite, ProRock.Xmlite.Schema.Invoice2;

    var invoice := TInvoiceE.Create;  // UBL's <Invoice>
    try
      if invoice.FromXmlFile('invoice.xml') then
        for var line in invoice.InvoiceLine do
          Writeln(line.Item.Name.XmlValue);
      invoice.ToXmlFile('copy.xml');  // all it read, back
    finally
      invoice.Free;
    end;
    ```

</div>

<div class="ask"><div class="ask-head"><h2 id="it-is-young">It is young, and it grows with you</h2><div class="ask-buttons"><a class="md-button md-button--primary" href="https://github.com/VitalyPopov/ProRock">⭐ Star on GitHub</a><a class="md-button" href="https://github.com/VitalyPopov/ProRock/issues/new/choose">Open an issue</a><a class="md-button ask-support" href="https://github.com/sponsors/VitalyPopov">Support the project</a></div></div><p>One developer builds it, and real use is what moves it forward. Try it on your own workbooks and schemas, and open an issue when something breaks or is missing: each one shapes the next release.</p><p>Hit the star on GitHub so other Delphi developers can find it, and if ProRock helps you, you can support the project.</p><p>I'm genuinely grateful for <b>every</b> star, issue and kind word! Thank you 🤟</p></div>
