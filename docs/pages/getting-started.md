---
icon: lucide/play
---

# Getting started

Get ProRock once, then take the path you need: Excel workbooks need nothing more, SOAP and XML start from the free generator.

## Get ProRock

ProRock is a pure source library: no installation, no design-time packages, no component registration. Clone it at a release
tag (tags have no `v`) next to your project:

```
git clone --branch 1.8.0 https://github.com/VitalyPopov/ProRock ThirdParty\ProRock
```

or download the source zip of the [latest release](https://github.com/VitalyPopov/ProRock/releases/latest).

Add `ThirdParty\ProRock\Source` to the project's search path, in the **Base** configuration
(**Project Options > Delphi Compiler > Search path**). Nothing else to set up.

## Excel workbooks { #excel }

No generator, no Excel installed. Make the workbook in Excel - formulas, charts, pivot tables, print setup - and fill it from
Delphi: inserted rows move them all, and everything you did not change is saved as it was.

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

Next: [Excel (Calcite)](calcite.md) for values, formulas, formats, sheets and a `TDataSet` in one call, and the
[Calcite sample](samples.md#excel-workbook) with a button for each.

## SOAP in 5 minutes { #soap }

From a WSDL to a working SOAP call: get the generator, generate the units, call the service. The example is the EU VIES VAT
number service, which is public and needs no account.

!!! tip "Working with an AI coding assistant?"
    It can do these steps too: point it to `CLI.md` in the zip, or to [the same text](cli-full.md) here. In a blind test an AI agent
    built a working VIES client app from the zip and the documentation alone, asking the developer before running the generator.

### 1. Get ProRocket Lite

<a class="md-button md-button--primary prorock-get" href="https://github.com/VitalyPopov/ProRock/releases/latest/download/ProRocket-Lite.zip"><img src="../assets/prorocket.png" alt=""><span>Download ProRocket-Lite.zip<small>free generator, GUI and CLI</small></span></a>

Windows 64-bit. Unzip it into a folder of its own. The SHA-256 checksum is in the
[release notes](https://github.com/VitalyPopov/ProRock/releases).

!!! warning "Windows SmartScreen may warn on the first start"
    The executables are not code-signed yet. Click **More info → Run anyway**.

### 2. Generate the units

Save the [VIES WSDL](https://ec.europa.eu/taxation_customs/vies/checkVatService.wsdl) as `checkVatService.wsdl` in your project
folder. Then either open `ProRocket.Lite.exe`, add the file and click **Generate**, or run the command line there (with the path
of the folder you unzipped to):

```
ProRocketCli.exe -o Generated checkVatService.wsdl
```

You get two units:

- `ProRock.Xmlite.Schema.CheckVatService` - the request and response types
- [ProRock.Soapite.CheckVatService](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Soapite.CheckVatService) - the client, `TCheckVatService`

### 3. Set up the project

Add the `Generated` folder to the search path, next to ProRock's `Source`.

### 4. Call the service

The client unit re-exports the request and response types, `TSoapiteError` and the exceptions, so for plain calls it is the only
unit to use. Pass the endpoint: the default is the WSDL's `soap:address`, and VIES still declares `http://` there.

```pascal
uses ProRock.Soapite.CheckVatService;

var service := TCheckVatService.Create(
  'https://ec.europa.eu/taxation_customs/vies/services/checkVatService');
try
  var request := TCheckVatE.Create;
  try
    request.CountryCode := 'IE';
    request.VatNumber := '6388047V';

    var response: TCheckVatResponseE;
    var error: TSoapiteError;
    // never raises for service or network failures
    if service.TryCheckVat(request, response, error) then
      try
        Writeln(response.Name, ' - valid: ', response.Valid);
      finally
        response.Free;
      end
    else
      Writeln('failed [', error.Code, ']: ', error.Message);
  finally
    request.Free;
  end;
finally
  service.Free;
end;
```

That's it. Next: [SOAP](soapite.md) for timeouts, authentication and faults.

## XML from an XSD { #xml }

Generate the units from the XSD as for SOAP (steps 1 to 3), then parse and write documents through the typed classes. To try it, the
[ProRock.Xmlite.Namespaces](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Xmlite.Namespaces) sample
has this `order.xsd` and a document for it (`demo.xml`):

```pascal
uses System.SysUtils,
  // FromXmlFile and ToXmlFile: a class helper, visible only where this unit is in uses
  ProRock.Xmlite,
  ProRock.Xmlite.Schema.Order;

var order := TOrderE.Create;
try
  if order.FromXmlFile('demo.xml') then // in its encoding: UTF-8, UTF-16, ISO-8859-1...
    Writeln(order.Customer.Name, ': ', order.Items.Item.Count, ' items');

  order.Status := osShipped;
  order.ToXmlFile('shipped.xml'); // UTF-8
finally
  order.Free;
end;
```

Next: [XML](xmlite.md), and [how it works](how-it-works.md) if you skipped it.

## When the schema changes

Generate into a folder under version control. When a new version of the schema arrives, regenerate: the diff of the units shows
what changed in the schema, and the compiler shows every place in your code that has to follow.
