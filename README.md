<img align="right" src="docs/assets/minerals-row.webp" alt="Basite, Xmlite and Soapite">

# ProRock 🤟

**Your schema in. Ready Delphi classes out.** A free generator for XSD and WSDL, with a GUI and a command line, and an open-source
library that reads and writes XML and calls SOAP services through the classes it makes.

> **When the schema changes, regenerate, don't re-patch.**

## What you get

- **Plain Delphi objects** you own: no DOM, no XPath, no interfaces. The classes are the schema, and code completion is their documentation
- **Proven on real schemas**: HL7® FHIR® R4, e-invoices (ZUGFeRD, Factur-X, XRechnung, Peppol), Excel workbooks, ISO 20022, SOAP services
- **Writes back what it read**, even what the schema does not describe: Excel opens the file and recalculates
- **Fast**: lazy objects, an e-invoice reads in under a millisecond
- **A clean diff** when the schema changes, and the compiler shows the rest

## See everything at [prorock.rocks](https://prorock.rocks/)

**[How it works](https://prorock.rocks/how-it-works/)** · **[Getting started in 5 minutes](https://prorock.rocks/getting-started/)** ·
[Samples](https://prorock.rocks/samples/) · [Tested schemas](https://prorock.rocks/tested-schemas/) ·
[Limitations](https://prorock.rocks/limitations/) · [Roadmap](ROADMAP.md) · [Changelog](CHANGELOG.md)

<p align="center"><img src="docs/assets/prorocket-lite.png" alt="ProRocket Lite, the code generator, with the FHIR R4 schemas generated"></p>

## Get it

- **ProRocket Lite**, the generator: **[download the zip](https://github.com/VitalyPopov/ProRock/releases/latest/download/ProRocket-Lite.zip)**.
  Windows 64-bit, free for any use, including commercial; SHA-256 in the [release notes](https://github.com/VitalyPopov/ProRock/releases)
- **ProRock**, the library: clone this repository and add its `Source` folder to your search path. Pure Delphi source
  (Apache 2.0), nothing to install. Delphi 10.3 to 13, Win64 and Win32

## From a WSDL to a SOAP call

```
ProRocketCli.exe checkVatService.wsdl
```

```pascal
uses ProRock.Soapite.CheckVatService;

var service := TCheckVatService.Create('https://ec.europa.eu/taxation_customs/vies/services/checkVatService');
var request := TCheckVatE.Create;
try
  request.CountryCode := 'IE';
  request.VatNumber := '6388047V';
  var response := service.CheckVat(request);
  try
    Writeln(response.Name, ' - valid: ', response.Valid);
  finally
    response.Free;
  end;
finally
  request.Free;
  service.Free;
end;
```

## It is young, and it grows with you

Try it on your schema and tell what breaks: please [open an issue](https://github.com/VitalyPopov/ProRock/issues/new/choose). If
ProRock is useful to you, smash the ⭐ Star, and you can [support the project](https://github.com/sponsors/VitalyPopov). Thank you! 🤟

Contributing: [CONTRIBUTING.md](CONTRIBUTING.md). Security issues: [SECURITY.md](SECURITY.md).

[Apache License 2.0](LICENSE); ProRocket Lite is a free closed-source tool with its own license. Third-party notices:
[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

Have fun, and let's ProRock! 🤟
