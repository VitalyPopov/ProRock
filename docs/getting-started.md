# Getting started in 5 minutes

From a WSDL to a working SOAP call: get the library and the generator, generate the units, call the service. The example is the
EU VIES VAT number service, which is public and needs no account.

!!! tip "Working with an AI coding assistant?"
    The steps below can be done by the assistant as well. The ProRocket Lite zip contains `CLI.md`, written for people and for AI
    assistants alike: how to verify the download, run `ProRocketCli.exe`, read its problem lines, add missing schemas, and lay
    out the project. Point your assistant to it (or to the [Command line](cli.md) page, the same text). In a blind test an AI
    agent built a working VIES client app from the zip and the documentation alone, asking the developer before downloading
    and running the generator.

## 1. Get ProRock

ProRock is a pure source library: no installation, no design-time packages, no component registration. Clone it at a release
tag (tags have no `v`) next to your project:

```
git clone --branch 1.4.0 https://github.com/VitalyPopov/ProRock ThirdParty\ProRock
```

or download the source zip of the [latest release](https://github.com/VitalyPopov/ProRock/releases/latest).

## 2. Get ProRocket Lite

[Download ProRocket-Lite.zip](https://github.com/VitalyPopov/ProRock/releases/latest/download/ProRocket-Lite.zip) (Windows
64-bit) and unzip it into a folder of its own. The SHA-256 checksum is in the
[release notes](https://github.com/VitalyPopov/ProRock/releases).

The executables are not code-signed yet, so Windows SmartScreen may warn on the first start: **More info → Run anyway**.

## 3. Generate the units

Save the [VIES WSDL](https://ec.europa.eu/taxation_customs/vies/checkVatService.wsdl) as `checkVatService.wsdl`. Then either
open `ProRocket.Lite.exe`, add the file and click **Generate**, or run the command line:

```
ProRocketCli.exe -o Generated checkVatService.wsdl
```

You get two units:

- `ProRock.Xmlite.Schema.CheckVatService` - the request and response types
- [`ProRock.Soapite.CheckVatService`](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Soapite.CheckVatService) - the client, `TCheckVatService`

## 4. Set up the project

```
MyApp  MyApp.dproj
  Generated\          the generated units - regenerate them, never edit by hand
  ThirdParty\ProRock\ the ProRock release named in the unit header
```

Add `ThirdParty\ProRock\Source;Generated` to the project's search path in the **Base** configuration
(**Project Options > Delphi Compiler > Search path**). Relative paths keep the project portable. ProRock 1.4 and earlier
have their units in the repository folder itself: `ThirdParty\ProRock;Generated`.

## 5. Call the service

The client unit re-exports the request and response types, `TSoapiteError` and the exceptions, so for plain calls it is the only
unit to use. Pass the endpoint: the default is the WSDL's `soap:address`, and VIES still declares `http://` there.

```pascal
uses ProRock.Soapite.CheckVatService;

var service := TCheckVatService.Create('https://ec.europa.eu/taxation_customs/vies/services/checkVatService');
try
  var request := TCheckVatE.Create;
  try
    request.CountryCode := 'IE';
    request.VatNumber := '6388047V';

    var response: TCheckVatResponseE;
    var error: TSoapiteError;
    if service.TryCheckVat(request, response, error) then // never raises for service or network failures
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

That's it. Next: [Soapite](soapite.md) for timeouts, authentication and faults.

## The same from an XSD

Generate the units from the XSD the same way, then parse and write documents through the typed classes:

```pascal
uses System.SysUtils, System.IOUtils,
  ProRock.Xmlite, // FromXml and ToXml (a class helper: visible only where ProRock.Xmlite is in uses)
  ProRock.Xmlite.Schema.Order;

var order := TOrderE.Create;
try
  if order.FromXml(TFile.ReadAllText('order.xml', TEncoding.UTF8)) then
    Writeln(order.Customer.Name, ': ', order.Items.Item.Count, ' items');

  order.Status := osShipped;
  TFile.WriteAllText('order.xml', order.ToXml, TEncoding.UTF8);
finally
  order.Free;
end;
```

Next: [Xmlite](xmlite.md).

## When the schema changes

Generate into a folder under version control. When a new version of the schema arrives, regenerate: the diff of the units shows
what changed in the schema, and the compiler shows every place in your code that has to follow.
