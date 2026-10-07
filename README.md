# ProRock 🤟

**Schema-typed XML for Delphi.** Generate exact Delphi classes from XSD and WSDL, parse and write XML through them, call SOAP
services with them.

> **When the schema changes, regenerate, don't re-patch.**

A schema changes: a new e-invoicing version, an ISO 20022 release, a service adding fields. Hand-written or hand-patched mappings
then have to be found and fixed one by one. With ProRock you regenerate the units, and the compiler shows exactly what changed.

- **ProRock** - the runtime library: open source (Apache 2.0), pure Delphi source, no dependencies beyond the RTL
- **ProRocket Lite** - the code generator: XSD/WSDL in, Delphi units out. Free for any use, including commercial
  ([download](#prorocket-lite-code-generator))

Contents:
- [Quick start: a SOAP client from a WSDL](#quick-start-a-soap-client-from-a-wsdl)
- [Quick start: XML from an XSD](#quick-start-xml-from-an-xsd)
- [Samples](#samples)
- [Core architecture](#core-architecture)
- [ProRocket Lite (code generator)](#prorocket-lite-code-generator)
- [Known limitations and notes](#known-limitations-and-notes)
- [Platform and compatibility](#platform-and-compatibility)
- [Installation](#installation)
- [Development](#development)

---

## Quick start: a SOAP client from a WSDL

1. Open ProRocket Lite, add the WSDL (here `checkVatService.wsdl`, the EU VIES VAT number service), click **Generate**.
2. You get two units: the types (`ProRock.Xmlite.Schema.CheckVatService`) and the client (`ProRock.Soapite.CheckVatService`).
   The client unit re-exports every type its calls need, so it is the only unit to use.
3. Call the service:

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

Every operation comes in two forms: `TryCheckVat` returns `False` with the reason in `TSoapiteError` (SOAP Fault or transport
failure), `CheckVat` returns the response and raises `ESoapiteFault` / `ESoapiteTransport` instead. SOAP 1.1 and 1.2 are both
supported.

## Quick start: XML from an XSD

Generate the units from the XSD the same way, then parse and write documents through the typed classes:

```pascal
uses ProRock.Xmlite.Schema.Order;

var order := TOrderE.Create;
try
  if order.FromXml(TFile.ReadAllText('order.xml', TEncoding.UTF8)) then
    Writeln(order.customer.name, ': ', order.items.item.Count, ' items');

  order.status := osShipped;
  TFile.WriteAllText('order.xml', order.ToXml, TEncoding.UTF8);
finally
  order.Free;
end;
```

Enumerations are Delphi enums, lists are typed lists, nested objects are created and freed automatically. Parsing works in place on the text,
without building a DOM.

## Samples

In [`Samples`](Samples) (one group project, `ProRock.Samples.groupproj`):

|   |   |
|---|---|
| `ProRock.Soapite.CheckVatService` | EU VIES VAT number validation through the generated `TCheckVatService`, with live SOAP Fault handling |
| `ProRock.Soapite.Calculator` | a generated client calling a public calculator service (`-soap12` and `-xml` switches) |
| `ProRock.Xmlite.Namespaces` | a generated metamodel from `order.xsd`: parsing, enums, serialization, round trip |
| `ProRock.Xmlite.Basic` | hand-written models, basic parsing and serialization |

The generated units and the source WSDL/XSD files are included, so the samples build without running the generator.

---

## Core architecture

### Basite (core)

**Basite** is the foundation of ProRock: a metadata-driven object model system for Delphi, independent of any data format.

It handles:
- **MetaModels** - plain Delphi object models (PODOs)
- **MetaBank** - centralized metadata storage and indexing
- **fast access** to metadata without repeated RTTI scanning
- **automatic initialization and lifecycle management** of nested object structures
- an **extension mechanism** for attaching format-specific metadata and behavior

### Extensions

Each format is a Basite extension: it adds its own metadata and behavior, does not modify the data models, and is used only when
needed.

|   |   |   |
|---|---|---|
| 🟢 | **Xmlite** | XML parsing and serialization to and from PODOs, namespace- and schema-aware |
| 🟢 | **Soapite** | SOAP 1.1 / 1.2 clients on top of Xmlite, generated from WSDL |
| 🔵 | **Jsonite** | JSON parsing and serialization to and from the same PODOs. Planned |
| 🟡 | **Calcite** | OOXML spreadsheet processing on top of Xmlite. Partially developed, not yet public |
| ⚪ | **Other** | FHIR, EDI and similar formats. Planned |

### Xmlite

`TXmlite` and `TXmliteList` inherit from `TBasite` and `TBasiteList`. Xmlite adds elements, attributes and namespaces as metadata,
and the parsing and serialization on top of them. Most helpers work with plain `TBasite` models too, so you can start with simple,
DOM-style models and opt into namespace- and schema-aware processing when needed.

### Soapite

`TSoapiteClient` sends typed requests and reads typed responses through a replaceable HTTP transport (`ProRock.Http`, System.Net
based by default). SOAP Faults of both versions are mapped to `TSoapiteError` (code, subcode, reason, actor/node, detail), also when
a service answers a fault with HTTP 200. `OnRequest` / `OnResponse` events give the raw XML for logging.

---

## ProRocket Lite (code generator)

**[Download ProRocket-Lite.zip](https://github.com/VitalyPopov/ProRock/releases/latest/download/ProRocket-Lite.zip)** (Windows
64-bit) - always the newest release. The SHA-256 checksum is in the [release notes](https://github.com/VitalyPopov/ProRock/releases).

- XSD and WSDL in; Delphi units out: one metamodel unit per namespace, one client unit per `wsdl:service`
- deterministic output: regenerating an unchanged schema gives an unchanged unit, so a schema update shows up as a clean diff
- free for any use, including commercial; the generated code is yours and is not covered by the ProRocket Lite license
- closed source, with its own license (`LICENSE.txt` in the zip); ProRock itself is Apache 2.0

The executable is not code-signed yet, so Windows SmartScreen may warn on the first start: **More info → Run anyway**.

ProRocket Lite is not needed to use ProRock: models can be written by hand as well.

---

## Known limitations and notes

Coverage grows through real-world schemas. Not covered yet:
- **mixed content** (text interleaved with child elements) is kept only partially (`XmlText`)
- **absent vs default**: an absent optional value reads as its default, and an optional value equal to its default is not written
  (for example, an absent optional enum reads as its first value)
- with `elementFormDefault="unqualified"`, local elements are written in the parent's default namespace (reading is fine)
- unions are partly realized; facets (patterns, ranges, lengths) are not validated
- SOAP rpc/encoded operations are skipped by the generator (listed in the generated unit header)

Notes:
- `TSoapiteError.Message`, `Detail` and `Response` are text controlled by the server and may contain its internals (stack traces,
  paths). Log them, and show your own message to end users.
- Generated string types (`TStringST = type string`) need a cast before string-helper methods:
  `string(response.Address).Replace(...)`.

---

## Platform and compatibility

Developed and tested with **Delphi 13 Florence** (13.1), mainly on **Win64**; **Win32** is supported as well.

The library is also verified to compile and work with:
- Delphi 12 Athens
- Delphi 11 Alexandria
- Delphi 10.4 Sydney
- Delphi 10.3 Rio

The code uses inline variable declarations, so Delphi versions before 10.3 are not supported.

## Installation

ProRock is a pure source library: no installation, no design-time packages, no component registration.

1. Clone or download the repository
2. Add the ProRock directory to your project's search path or the IDE library path
3. Use the units you need

## Development

Changes are listed in the [CHANGELOG](CHANGELOG.md). Security issues: see [SECURITY.md](SECURITY.md).

Since October 2026, development is assisted by [Claude Code](https://claude.com/claude-code) (Anthropic): it helps with
implementation, tests and generator fixes. Design, decisions and verification remain the author's.

Feedback, real-world schemas that do not work yet, and contributions are welcome. If ProRock is useful to you, you can
[support the project](https://github.com/sponsors/VitalyPopov).

## License

ProRock is licensed under the [Apache License 2.0](LICENSE). ProRocket Lite is a free closed-source tool with its own license.
The generated metamodels are derived from W3C, IBM and Microsoft schemas; their notices are in
[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

Have fun, and let's ProRock! 🤟
