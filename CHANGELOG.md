# Changelog

All notable changes to ProRock (runtime library) and ProRocket Lite (code generator) are documented here. Both share one version
number since 1.1.0.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versions follow [Semantic Versioning](https://semver.org/).

## [1.1.0] - 2026-10-08

The SOAP release: WSDL in, a typed client out, verified against live services. Development of this release was assisted by
Claude Code (Anthropic).

### Added

- **Soapite** - SOAP client runtime (`ProRock.Soapite`)
  - SOAP 1.1 and SOAP 1.2, with automatic fallback to 1.1 when a service does not declare 1.2
  - `TryCall` never raises for service or network failures: `False` and the reason in a `TSoapiteError` record (no exceptions
    needed); `Call` raises `ESoapiteFault` / `ESoapiteTransport` on top of it
  - SOAP Faults of both versions mapped to `TSoapiteError` (code, 1.2 subcode, reason, actor/node, detail), also when a service
    answers a fault with HTTP 200
  - `OnRequest` / `OnResponse` events with the raw XML for logging and debugging
- **Http** - protocol-agnostic HTTP transport (`ProRock.Http`), System.Net based, replaceable (e.g. a fake transport for tests)
- **Xmlite**
  - XSD simpleContent (text and attributes, no child elements): the `[TXmliteText]` property holds the typed element text,
    whitespace is preserved, text and attributes are written in one line
  - `[TRequired]` attribute: required values are written even when equal to the default (`<intA>0</intA>`)
  - the reserved `xml:` prefix (`xml:lang`, `xml:space`) is bound by definition and never declared
  - members follow the namespace naming; property-level `[TNaming]` and `[TName]`
  - `xs:any` content: registered elements of other namespaces are parsed and written with their own namespace
  - unqualified local elements are matched in their parent's namespace
- **Metamodels**: WSDL 1.1, SOAP 1.1 / 1.2 bindings, SOAP 1.1 / 1.2 envelopes (`ProRock.Xmlite.Schema.*`)
- **Samples**
  - `ProRock.Soapite.Calculator` - a generated client calling a public calculator service (`-soap12`, `-xml` switches)
  - `ProRock.Soapite.CheckVatService` - EU VIES VAT number validation through the generated `TCheckVatService`

### ProRocket Lite 1.1.0 (generator)

- WSDL support: a client unit per `wsdl:service` with `Method` (raises) and `TryMethod` (no exceptions) per operation; the client
  unit re-exports the types its calls need, so it is the only unit to use
- XSD simpleContent generated as an `XmlValue` property (also through extension chains)
- inline (anonymous) complex types with plain sequence / choice / all content are generated; as in XSD, they are not registered
  as namespace components
- `[TRequired]` generated for required attributes and effectively required elements
- referenced attributes of other namespaces (`xml:lang`, `wsdl:required`) get `[TNamespace]`
- enumerations of QNames stay QNames (their prefixes are document-dependent)
- deterministic output: sorted `uses`, stable layout - regenerating an unchanged schema gives an unchanged unit

### Changed

- **ProRocket Lite is free** for any use, including commercial (closed source, its own license; previously a sponsor reward). It is
  distributed with every ProRock release as `ProRocket-Lite.zip`; the generated code belongs to the user
- compatibility verified for this release: tests, samples and every unit built and run on Delphi 10.3, 10.4, 11, 12 and 13.1,
  Win64 and Win32; the Soapite samples now target Win64 as well
- documentation: new README (quick starts for SOAP and XSD), `CONTRIBUTING.md`, issue templates, `SECURITY.md` with private
  vulnerability reporting, `NOTICE` and `THIRD-PARTY-NOTICES.md` (notices of the W3C, IBM and Microsoft schemas behind the
  generated metamodels)
- ProRocket Lite: URN namespaces give their last segment as the unit name (`urn:demo:order` → `ProRock.Xmlite.Schema.Order`,
  previously `...Schema.urndemoorder`). Regenerating such a schema renames the unit
- ProRocket Lite: reserved words in unit names are escaped (`ProRock.Xmlite.Schema.&Inline`)
- generated metamodels regenerated (required members, namespace naming, foreign attribute namespaces)

### Fixed

- Xmlite: an empty-string text node no longer causes an access violation
- Xmlite: `FromXml` on a string literal or a shared string parses a copy (no writes into constant memory)
- Xmlite: a tag's own `xmlns` declaration applies to the tag's name

### Known limitations

- mixed content (text interleaved with child elements) is kept only partially (`XmlText`)
- absent and default values are not distinguished yet (an absent optional enum reads as its first value)
- with `elementFormDefault="unqualified"`, local elements are written in the parent's default namespace
- SOAP rpc/encoded operations are skipped by the generator (listed in the generated unit header)

## [1.0.3] - 2026-01-27

- Xmlite: correct XML name restoration on namespace registration with custom component naming
- Xmlite.Schema: regenerated base XML Schema metamodels - inline complexType classes are no longer registered as namespace
  components; no orphan local types for prohibited attributes; more readable `RegisterNamespace` calls
- Basite: `TUtility.NameWithoutPrefix`; handier `TDictObjectList<K, V>`; `NameAndPrefix` fixed for an empty prefix
- Xmlite: suffix naming (`E`, `CT`, `ST`, ...) instead of postfix; safer namespace registry

## [1.0.2] - 2026-01-10

- Xmlite: `xs:any` elements; single-quoted attribute values; element metadata lookup fix in namespace resolution
- Xmlite.Schema: XML Schema Instance (`xsi`) metamodel; overridden attribute restrictions in complexContent generated correctly

## [1.0.1] - 2026-01-07

- Delphi 10.3+ compatibility
- Xmlite.Schema: xs:simpleType generated as class-local types
- Xmlite: comments inside elements skipped correctly; XML header handling in `ToXml`; empty-URI fallback for element and
  attribute lookup
- Samples: basic Xmlite parsing and serialization demos, namespaces demo (schema, enums, round trip)

## [1.0.0] - 2026-01-02

- First public release: Basite (metadata-driven object model core) and Xmlite (XML parsing and serialization to and from PODOs)

[1.1.0]: https://github.com/VitalyPopov/ProRock/compare/1.0.3...1.1.0
[1.0.3]: https://github.com/VitalyPopov/ProRock/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/VitalyPopov/ProRock/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/VitalyPopov/ProRock/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/VitalyPopov/ProRock/releases/tag/1.0.0
