# ProRock 🤟

**Schema-typed XML for Delphi.** Generate exact Delphi classes from XSD and WSDL, parse and write XML through them, call SOAP
services with them.

> **When the schema changes, regenerate, don't re-patch.**

A schema changes: a new e-invoicing version, an ISO 20022 release, a service adding fields. Hand-written or hand-patched mappings
then have to be found and fixed one by one. With ProRock you regenerate the units, and the compiler shows exactly what changed.

- **ProRock** - the runtime library: open source (Apache 2.0), pure Delphi source, no dependencies beyond the RTL
  - **Xmlite** - XML parsing and serialization to and from plain Delphi objects, namespace- and schema-aware, without a DOM
  - **Soapite** - SOAP 1.1 / 1.2 clients on top of Xmlite, generated from WSDL
- **ProRocket Lite** - the code generator: XSD/WSDL in, Delphi units out, in a GUI and from the command line - friendly to
  scripts and AI coding assistants. Free for any use, including commercial

**[Download ProRocket-Lite.zip](https://github.com/VitalyPopov/ProRock/releases/latest/download/ProRocket-Lite.zip)**
(Windows 64-bit, always the newest release; SHA-256 in the [release notes](https://github.com/VitalyPopov/ProRock/releases))

## Documentation

The full documentation is at **[prorock.rocks](https://prorock.rocks/)** (searchable):

|   |   |
|---|---|
| [Getting started](https://prorock.rocks/getting-started/) | from a WSDL to a working SOAP call in 5 minutes |
| [Xmlite](https://prorock.rocks/xmlite/) · [Soapite](https://prorock.rocks/soapite/) | XML through typed classes · SOAP clients, transport, authentication |
| [ProRocket Lite](https://prorock.rocks/prorocket-lite/) | the generator: GUI and command line |
| [Samples](https://prorock.rocks/samples/) | seven samples, from Office document properties to WS-Security |
| [XML concepts](https://prorock.rocks/xml-concepts/) | namespaces, XSD types, substitution groups - explained for Delphi developers |

## Quick start: a SOAP client from a WSDL

1. Open ProRocket Lite, add the WSDL (here `checkVatService.wsdl`, the EU VIES VAT number service), click **Generate** -
   or from the command line: `ProRocketCli.exe checkVatService.wsdl`.
2. You get two units: the types (`ProRock.Xmlite.Schema.CheckVatService`) and the client (`ProRock.Soapite.CheckVatService`).
3. Call the service. Pass the endpoint: the default is the WSDL's `soap:address`, and VIES still declares `http://` there.

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

The same from an XSD, the project setup, timeouts, authentication and faults:
[getting started](https://prorock.rocks/getting-started/) and
[Soapite](https://prorock.rocks/soapite/).

## Installation

ProRock is a pure source library: no installation, no design-time packages, no component registration. Clone or download the
repository, add the ProRock directory to your project's search path, use the units you need.

Delphi 10.3 Rio to 13 Florence, Win64 and Win32; all units compile for Android (Delphi 13), running on a device is not verified
yet. The [Samples](Samples) folder has one group project with seven samples - Office document properties, EU VIES, WS-Security,
client certificates and more.

## Known limitations and notes

Coverage grows through real-world schemas. Not covered yet: mixed content with child elements, absent vs default values,
elements standing in for their substitution group head; facets are not validated. The full list, with notes on decimals, string
types and server error texts: [Limitations and notes](https://prorock.rocks/limitations/). What comes next:
[ROADMAP](ROADMAP.md).

## Development

Changes are listed in the [CHANGELOG](CHANGELOG.md), plans in the [ROADMAP](ROADMAP.md). Security issues: see
[SECURITY.md](SECURITY.md).

Since October 2026, development is assisted by [Claude Code](https://claude.com/claude-code) (Anthropic): it helps with
implementation, tests and generator fixes. Design, decisions and verification remain the author's.

Feedback, real-world schemas that do not work yet, and contributions are welcome - see [CONTRIBUTING.md](CONTRIBUTING.md).

If ProRock is useful to you, at least smash the ⭐ Star - it costs nothing and helps other Delphi developers find it. And if
you'd like to do more, you can [support the project](https://github.com/sponsors/VitalyPopov). Thank you! 🤟

## License

ProRock is licensed under the [Apache License 2.0](LICENSE). ProRocket Lite is a free closed-source tool with its own license.
The generated metamodels are derived from W3C, IBM and Microsoft schemas; their notices are in
[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

Have fun, and let's ProRock! 🤟
