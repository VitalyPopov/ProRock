# Changelog

All notable changes to ProRock (runtime library) and ProRocket Lite (code generator) are documented here. Both share one version
number since 1.1.0.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Soapite / HTTP: client certificates (mutual TLS) on `THttpTransportNative` - `ClientCertificate` (a PFX/P12 file; on
  Android the name or fingerprint of an installed certificate) and `ClientCertificatePassword`. A missing file or a wrong
  password fails the call (`sekNetwork` in Soapite) with the System.Net message, never with the password
- Sample `ProRock.Soapite.WsSecurity`: a WS-Security UsernameToken with PasswordDigest, Nonce and Timestamp in the
  SOAP header (through `OnRequestHeader`), from units generated from the official OASIS schemas; offline by default
  (prints the request), `-live` against the public Calculator service
- Xmlite: `[TQualified]` - an attribute written with its namespace prefix also in an element of its own namespace (XSD:
  a global attribute referenced within its schema, e.g. `wsu:Id` in `wsu:Timestamp`). ProRocket Lite generates it for
  same-namespace attribute references; `ProRock.Xmlite.Schema.Xml`, `.Envelope` (`encodingStyle`) and `.Wsdl`
  (`required`) are regenerated with it
- ProRocket Lite: known names for OASIS WS-Security 1.0 (`ProRock.Xmlite.Schema.WsSecurity`, `.WsSecurityUtility`,
  prefixes `wsse`, `wsu`) and ebMS 3.0, the AS4 message header (`ProRock.Xmlite.Schema.Ebms3`, prefix `eb`); a namespace ending in a file name gets a readable unit name
  (`.../oasis-200401-wss-wssecurity-secext-1.0.xsd` -> `Oasis200401WssWssecuritySecext10`)
- ProRocket CLI (`ProRocketCli.exe`, in the ProRocket Lite zip): the generator from the command line, for scripts, build
  steps and AI coding assistants, with `CLI.md`. Problems are reported instead of passing silently - missing imported
  schemas and includes, names that resolve to nothing, `xs:redefine` - as machine-readable lines (exit code 2), also in
  the GUI; `--strict` writes nothing when there are problems; `--no-timestamp` leaves out the `Generated (UTC)` line, so
  an unchanged schema gives a byte-identical unit; `--version`

### Fixed
- ProRocket Lite: two versioned namespaces of one vendor (`urn:acme:orders:2`, `urn:acme:common:2`) got the same unit name,
  and one unit overwrote the other; a version-only last segment now takes the segment before it (`Orders2`), and two units
  with one name are reported and nothing is written
- Xmlite writer: `xs:any` content of the parent's namespace was written with a prefix that was never declared, and the
  prefixes it used inside were not declared either (e.g. `<wsse:UsernameToken wsu:Id=...>` in `wsse:Security`) - not
  well-formed XML. Such content is now written unprefixed below an unprefixed parent, and every prefix it uses is declared;
  found with the OASIS WS-Security schemas, the result validates against them
- Xmlite writer: element namespaces follow the default namespace in scope - a child is prefixed exactly when its namespace is
  another one. Before, content of another namespace's type was written in the parent's one (`ord:Buyer` of type
  `cmn:PartyType` wrote `<Buyer><Name>` instead of `<Buyer><cmn:Name>`), and so was the content below a prefixed element.
  A property typed with a global declaration (an element class: `xs:element ref`, an attribute type: `xs:attribute ref`)
  now belongs to that declaration's namespace (`<b:BElem>`, was `<BElem>` in the parent's namespace); such attributes are
  qualified. Documents written by earlier versions still read (an element is matched by name when no namespace fits).
  Behavior change for hand-written classes: an element class used as the type of a member puts it in its own namespace.
  Generated units no longer carry `[TNamespace]`/`[TQualified]` on references (derived from the type); global attributes
  are registered before the classes of their namespace
- ProRocket Lite: two attribute references with the same name from different namespaces (ebMS `eb:Messaging`:
  `S11:mustUnderstand` and `S12:mustUnderstand`) became one property - the second replaced the first; now two
  (`MustUnderstandEnvelope`, `MustUnderstandEnvelope12`, both `[TName('mustUnderstand')]`)
- ProRocket CLI: a long problem line could be split by a `generated:` line when stdout and stderr were read together;
  every line is now written and flushed in one piece
- README: the XSD quick start did not compile - `FromXml`/`ToXml` need `ProRock.Xmlite` in `uses` (a class helper)
- README: the SOAP client unit is not the only unit for everything - transport settings need `ProRock.Http`, error kinds
  `ProRock.Soapite`; the default endpoint is the WSDL's `soap:address` (VIES still declares `http://`)

## [1.2.0] - 2026-10-12

Authentication, SOAP headers and solid foundations: HTTP auth and header blocks for Soapite, correct number sizes in Basite,
reading of self-nested data of any depth, no Windows-only code (compiles for Android). Verified on Delphi 10.3 to 13, Win32 and
Win64. Development of this release was assisted by Claude Code (Anthropic).

### Added

- **HTTP authentication** (`ProRock.Http`, for Soapite and future protocol layers)
  - default headers on the transport, sent with every request: `SetHeader` (API keys, ...), `SetBasicAuth` (RFC 7617, UTF-8),
    `SetBearerToken` (OAuth 2.0); a header the request already has wins
  - `THttpTransportNative.UserName`/`Password` answer a server's 401 challenge: Basic, Digest, NTLM, Negotiate
  - credentials never reach `OnRequest`/`OnResponse` or error texts (they only see the XML body)
- **SOAP headers** (`ProRock.Soapite`): `OnRequestHeader` adds header blocks to the request envelope (WS-Addressing,
  WS-Security tokens, ebMS, a service's own headers), `OnResponseHeader` reads the response's header, faults included
- **Non-Windows platforms**: ProRock no longer depends on `Winapi.Windows`. The class meta cache (a pointer in the class's
  VMT) uses `mprotect` on POSIX; where the OS refuses it, the meta is found through the registry instead (correct, slower).
  All ProRock units compile for Android 32/64-bit; running on a device is not verified yet
- `TBasite.AutoInitMaxDepth`: how often one type may occur on a path when nested objects are created with their parent; replaces
  the `cAutoInitMaxDepth` constant. One global value, set it once at startup; clamped to 1..5

### Changed

- **Breaking:** a custom `THttpTransport` overrides `Send` instead of `Execute` (`Execute` adds the default headers, then calls
  `Send`); the compiler reports the old override
- `AutoInitMaxDepth` defaults to 1 (was 2): a self-nested object (e.g. SOAP 1.2 `Subcode` inside `Subcode`) is no longer
  pre-created, it is `nil` until set or read. Set `TBasite.AutoInitMaxDepth := 2` for the old behavior
- **Breaking:** `xs:decimal`, `xs:float` and `xs:double` are generated as `Double` (was `Extended`, which is 10 bytes on Win32
  only): the same values on every platform. Regenerate your units; code relying on `Extended` precision on Win32 changes
- **Breaking:** `xs:unsignedLong` (and `unsignedInt`/`unsignedShort`/`unsignedByte`, derived from it) is generated as `UInt64`
  (was `Int64`): values above `High(Int64)` are read and written. Regenerate your units
- Number text that does not fit a property's type (e.g. `300` for a `Byte`) gives the default value, as invalid text did
- ProRocket Lite: the generated unit header names the version once (`Generated by ProRocket Lite for ProRock 1.2.0`) and
  both only when generator and runtime differ

### Fixed

- Reading self-nested data deeper than the pre-created objects failed (`FromXml` returned `False`), e.g. a SOAP 1.2 fault with
  `Subcode` nested 3 levels deep. The reader now creates the missing objects
- `Clear` raised an access violation on a self-nested object that was not pre-created
- Data properties of hand-written classes: `Byte`, `ShortInt`, `Word`, `SmallInt`, `Cardinal`, `Single`, `Double` (Win32),
  `Currency` and `Comp` values were read and written as `Integer`/`Extended`, giving wrong values and overwriting the
  neighbouring fields; getter/setter methods of these types were called with the wrong type. Each type now uses its own size
  (generated code was not affected: it uses `Int64` and `Extended` only). `Single` is written with its own digits (`0.1`),
  `Currency` without passing through a float
- ProRocket Lite: decimal default values were written into the generated unit in the locale's format (`1,5` on a German
  system, which does not compile)

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
