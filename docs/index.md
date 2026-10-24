# ProRock

**Schema-typed XML for Delphi.** Generate exact Delphi classes from XSD and WSDL, parse and write XML through them, call SOAP
services with them.

> **When the schema changes, regenerate, don't re-patch.**

A schema changes: a new e-invoicing version, an ISO 20022 release, a service adding fields. Hand-written or hand-patched mappings
then have to be found and fixed one by one. With ProRock you regenerate the units, and the compiler shows exactly what changed.

[Get started in 5 minutes](getting-started.md){ .md-button .md-button--primary }
[![](assets/prorocket.png){ .button-icon } Download ProRocket Lite](https://github.com/VitalyPopov/ProRock/releases/latest/download/ProRocket-Lite.zip){ .md-button }

## Two parts

**ProRock** - the runtime library. Open source (Apache 2.0), pure Delphi source, no dependencies beyond the RTL, no packages
to install.

- [Basite](xmlite.md#under-the-hood): the core - plain Delphi objects described once by their metadata (MetaBank): nested
  objects created and freed with their parent, presence of every value. Independent of any data format, the base for Xmlite
  and later Jsonite
- [Xmlite](xmlite.md): XML parsing and serialization to and from plain Delphi objects, namespace- and schema-aware. Parsing works
  in place on the text, without building a DOM
- [Soapite](soapite.md): SOAP 1.1 / 1.2 clients on top of Xmlite, generated from WSDL, with typed requests, responses and faults

**ProRocket Lite** - the code generator: XSD and WSDL in, Delphi units out, in a [GUI](prorocket-lite.md) and from the
[command line](cli.md) - friendly to scripts and AI coding assistants. Free for any use, including commercial; the generated
code is yours.

## What it looks like

```pascal
uses ProRock.Soapite.CheckVatService; // generated from the EU VIES WSDL

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

## Platforms

Delphi 10.3 Rio to 13 Florence, Win64 and Win32. All units compile for Android 32/64-bit (Delphi 13); running on a device is
not verified yet. Details: [Limitations and notes](limitations.md#platform-and-compatibility).

## Feedback

Feedback, real-world schemas that do not work yet, and contributions are welcome:
[open an issue](https://github.com/VitalyPopov/ProRock/issues/new/choose) or see
[CONTRIBUTING.md](https://github.com/VitalyPopov/ProRock/blob/main/CONTRIBUTING.md).

If ProRock is useful to you, at least smash the ⭐ [Star on GitHub](https://github.com/VitalyPopov/ProRock) - it costs nothing
and helps other Delphi developers find it. And if you'd like to do more, you can
[support the project](https://github.com/sponsors/VitalyPopov). Thank you! 🤟

Since October 2026, development is assisted by [Claude Code](https://claude.com/claude-code) (Anthropic): it helps with
implementation, tests and generator fixes. Design, decisions and verification remain the author's.
