# Changelog

All notable changes to ProRock (runtime library) and ProRocket Lite (code generator) are documented here. Both share one version
number since 1.1.0.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed
- Choice members are created on first access, not with their parent. A property that is one alternative of an `xs:choice`
  is now read through a getter: touching it (`Entry.Resource.Patient.Name...`) creates it as before, untouched ones cost
  nothing. A FHIR Bundle of 1,000 Patients: read 11.9 s -> 0.10 s, write 6.7 s -> 0.08 s, free 10.0 s -> 0.05 s - every
  entry pre-created two containers of 146 resources each (18,109 objects) before. Regenerate your units to get it
- `FromXml` returns `False` for malformed content - a tag not closed, crossed tags, an undeclared prefix in kept content.
  It returned `True` before, with what was read up to the error. The object still holds that part
- Code that walks generated objects recursively and stops at `nil` must stop at empty objects instead (`HasContent`): a
  choice member's getter always returns an object, so a walk through a recursive type would not end
- `@Obj.Member` (`Present`, `SetPresent`, `Clear` by address) does not compile for choice members - a property with a
  getter has no address; use the name forms (`IsPresent('patient')`)
- The first access to a choice member creates it: reading one object from several threads at once is not safe for
  untouched choice members
- `XmlText` of a mixed element is its leading text node: whitespace before the first child is kept, and setting it replaces
  that text. Inside a mixed element the writer writes no indentation - it would become a part of the text

### Added
- Content the schema does not describe is kept: elements without a property are kept as their exact text (`XmlUnknown`) and
  written back where they were - after the same element, between the same list items - and the document's namespace
  declarations are written back, so prefixes named in values stay declared (`mc:Ignorable="x14ac"`). An Excel workbook read
  and written back keeps Office's extensions (`extLst`, `mc:AlternateContent`, `xr:revisionPtr`). The content of `xs:any`
  from a namespace without generated units is kept the same way
- `[TChoice('Group')]` marks the members of a choice; `Chosen('Group')` returns the present member's object,
  `ChosenProperty('Group')` its property, without creating any member. `Chosen` without a name - the class's only choice
- A typed shortcut per choice group named by its members' common prefix: `Obs.ValueChosen` for FHIR's `value[x]`
  (`valueQuantity`, `valueString`...) instead of `Obs.Chosen('Value')`
- Hand-written classes: an object property with a getter is not pre-created; its field (`f` + the property name) is
  used by the reader and writer, and `TBasite.Lazy` creates it in the getter
- Lists of plain values: a repeating element of a simple type (`<author>Ann</author><author>Bob</author>`) is a
  `TXmliteValueList<T>` - a `TList<T>` of strings, numbers, enumerations or booleans, each value read and written as a
  property of its type would be: `Authors.Author.Add('Ann')`. Such units did not compile before; the OOXML SpreadsheetML and
  DrawingML schemas now generate units that compile unchanged
- A reference to a global element of a simple type (`<xs:element ref="lpstr"/>`) is a value too - a property of its type,
  a value list when it repeats - instead of an element class without a place for its text
- The DocumentProperties sample shows the application's properties (`docProps/app.xml`): the application and the titles of
  the parts, grouped by heading - "Worksheets: Sales, Costs" - read as a value list of `vt:lpstr`
- Mixed content: text between child elements (`<p><b>status</b>: final</p>`, a FHIR narrative's XHTML) is kept with the
  children in document order in `XmlContent` and written back as it was. A mixed type gets `[TMixed]`; a repeating choice
  gets `[TOrdered]` - its members' order is kept too (an Excel `<font>`). The typed lists stay as they are; `XmlContent`
  refers to their objects. Reading: `InnerText`, a node's `IsText`, `IsElement<T>`, `ElementAs<T>`, `Name`; building:
  `Add<T>` (the list by the class, in order), `AddText`, `Remove`. `Ordered` and `Mixed` are settings of the class's
  metadata, changeable at run time. Regenerate your units to get it

- Docs: an XML support page - what of XML and XML Schema works, in part, or not yet - and Large documents (choices)

### Removed
- `TXmliteTextElement` and `TXmliteTextNodeString`/`Integer`/`Int64`/`Cardinal`: an element of plain text as an object, never
  generated. Use a string property marked `[TXmliteElement]`, or a value list for a repeating one

### Fixed
- The writer no longer declares the namespaces of value types (`xmlns:xs="http://www.w3.org/2001/XMLSchema"` for any
  string): they name nothing in the document
- CDATA sections were read as empty, and every element after one was lost: `<name><![CDATA[a<b]]></name>` reads `a<b` now
  (the text as it is, written back escaped)
- A processing instruction inside an element (`<?app data?>`) lost everything after it; it is skipped now, as comments are.
  Comments and processing instructions holding `<` or `>` no longer upset skipping an unknown element

## [1.5.1] - 2026-10-24

A fix for Delphi 10.3 - lists never freed their items - and faster object creation. Units generated with 1.5.0 work
unchanged, there is nothing to regenerate. Verified on Delphi 10.3 to 13, Win32 and Win64.

### Changed
- Faster object creation: the lists of an object are created without RTTI method calls - about 3x faster for an object
  with lists (create and free), on every Delphi version

### Fixed
- Delphi 10.3: lists did not own their items, so every list item - read from a document or added in code - was never freed.
  `TBasiteList<T>` called a plain `inherited`, which on 10.3 reached `TList<T>.Create` (10.3's `TObjectList<T>` has no
  parameterless constructor). Delphi 10.4 and later were not affected

## [1.5.0] - 2026-10-22

Exact round trips: a document read and written back keeps what its schema describes - values equal to their default, enumeration texts, type
names, the schema's element order - and you can tell an absent value from a default one (`Present`, `SetPresent`, `Clear`). FHIR R4 and the
OOXML SpreadsheetML/DrawingML schemas generate units that compile (OOXML except lists of plain values); unknown elements, such as Office's
own extensions, are still dropped. The units moved to `Source\` - the one setup change. Verified on Delphi 10.3 to 13, Win32 and Win64.
Development of this release was assisted by Claude Code (Anthropic).

### Added
- Presence - absent vs default. A value read from a document is written back also when it equals its default
  (`count="0"`, `<gender value="male"/>`, an Excel fill with only defaults), and you can tell an absent value from a
  default one: `Patient.Present[@Patient.Gender]`. `SetPresent(@Obj.X)` marks a value set in code as present
  (`Count := 0` alone stays "not set": assignments are not seen), `Clear(@Obj.X)` removes a value - its default and absent.
  A property is given by the address of its field-backed property, or by name (`SetPresent('count')`) for one with a
  getter; a wrong one is skipped (`False`), no exception. Every object keeps one 64-bit word of presence bits (more only
  for classes with more than 64 properties)

- Xmlite: `[TName('Account.Coverage')]` on a type or class: its exact XML name, for a name no naming style gives back
- Xmlite: `TXmlite.XmlPosition` - when an element was read, increasing in document order (0: not read)

### Fixed
- ProRocket Lite: type names with dots (XHTML `a.content`, FHIR `Account.Coverage`, hundreds in FHIR) gave Delphi names
  that do not compile (`Ta.contentCT`); a dot now separates words (`TAContentCT`) and the type gets `[TName]` with its
  XML name. Also every type whose name came back wrong from its Delphi name - OPC `CT_CoreProperties` was registered as
  `CTCoreProperties`, Dublin Core `ISO639-2` as `ISO6392`, FHIR `QuantityComparator-list` as `Quantity-Comparator-List`
  (`xsi:type` values and lookups by type name) - gets `[TName]`. Two XML names that give one Delphi name
  (`Account.Coverage` and `AccountCoverage`, or names differing in case only) no longer clash: the second one gets a number
- ProRocket Lite and Xmlite: enumeration values are written with their exact text. One-letter values came out in upper
  case (OOXML `t="s"` written `t="S"`, which Excel rejects), OPC `TargetMode="External"` as `external`; values with
  symbols gave items that do not compile (FHIR `<`, `>=`, `text/cql`), `true` next to `True` an identifier redeclared.
  Items now get a valid name (`cLessEqual`, `mtTextCql`, `tfbTrue2`, `tfbEmpty` for `""`) and `[TEnumCaption]` with the
  exact text where the name does not give it; reading takes the exact text first, then ignoring case
- ProRocket Lite: generated units that did not compile - a class declared before the class it derives from (FHIR:
  `Element`, used by most types); an enumeration longer than Delphi's line limit of 1023 characters (OOXML
  `ST_PresetColorVal`, now wrapped at the unit width); a field with the name of another member (`fScore` for `score` and
  the property `FScore` of `fScore`: now `fScore_`); a member named like one ProRock relies on (OOXML `assign`: now
  `Assign_`, its XML name kept; `Assign`, `Free`, `Create`, `Destroy`, `Clear`, `ToXml`, `FromXml`). FHIR R4 and the
  SpreadsheetML/DrawingML schemas generate units that compile (SpreadsheetML except its lists of simple values)
- ProRocket Lite: the members of a sequence are generated in the schema's order, so documents are written in it - a choice
  or a group reference between elements came after them (FHIR `deceasedBoolean` after `address`; DrawingML shape
  properties: the fill after the line), which validators and Office reject. The XSD classes in
  `ProRock.Xmlite.Schema.Base` follow their schema's order too
- Xmlite: an attribute value with entities (`title="A &amp; B"`) was read with trailing spaces (`'A & B    '`): a start
  tag is read twice and the value was decoded in place
- Xmlite: attribute values were written without escaping - a `<`, `&` or `"` in a value (FHIR `comparator="&lt;="`, a
  kept attribute read with entities) gave invalid XML

### Changed
- **The units moved to `Source\`** - the one setup change of this release: point the search path at `ProRock\Source`
  instead of `ProRock` (`ThirdParty\ProRock\Source;Generated`). No unit is renamed, no `uses` changes; without the new
  path Delphi reports the units as not found. The folder keeps the repository root for the docs, samples and licence files,
  and leaves room for optional pre-generated schemas later
- Xmlite: an optional object created with its parent but absent from the data is no longer written - its required
  attributes made it appear (`<drawing r:id=""/>`); one with only default values, read from the data, no longer vanishes;
  list items and the root are always written (`<fill/>`); a required object element (`[TRequired]`, now generated for
  object elements too) is written also when empty. A child element with a default value no longer makes its absent
  parent appear as an empty `<a></a>`
- Xmlite: a value read from a document stays present when code assigns its default: `Title.XmlValue := ''` writes an
  empty `<dc:title></dc:title>`, 1.4 removed the element. To remove a value, `Clear(@Properties.Title)` (the
  DocumentProperties sample does so for empty fields)
- Xmlite: `Clear` of an Xmlite object also clears its kept content (`XmlText`, `XmlAny`, unknown attributes) - a document
  read into a used object no longer keeps any of the previous one

## [1.4.1] - 2026-10-18

Fixes found by generating the OOXML schemas (SpreadsheetML, DrawingML) and FHIR R4: default values that made every `ToXml`
of a class fail, `xs:boolean` values `1` and `0`, unions that crashed ProRocket Lite or came out wrong, and a crash at
program start with XHTML and FHIR.

### Fixed
- Xmlite: a class with a default value on a type of another unit - in generated units every `xs:boolean`, `xs:int`,
  `xs:double` attribute or element with `default=` - raised `EVariantTypeCastError` on every `ToXml`, also of an untouched
  object: the default was given as text (`[TDefault('false')]`) and compared with the value. ProRock now converts such a
  default into the property's type once, independent of the locale, so units generated by earlier versions work without
  regenerating; ProRocket Lite writes it in its type (`[TDefault(False)]`)
- Xmlite: `xs:boolean` text `1` and `0` (valid XML Schema, written by Excel and in SOAP headers) was read as the default
  value; now `True` and `False` like `true` and `false`
- Xmlite: registering a type whose content holds elements derived from itself - XHTML, where a `span` holds a `span`,
  and with it every FHIR resource (its narrative is XHTML) - raised an access violation at program start
- Xmlite: an `xs:unsignedLong` default above `High(Int64)` lost its digits (`18446744073709551615` became
  `9223372036854775808`)
- ProRocket Lite: unions (`xs:union`) - a simple type holding a value of any of several types. Members named only in
  `memberTypes` crashed the generator (`EArgumentOutOfRangeException`, e.g. OOXML `shared-commonSimpleTypes.xsd`);
  `memberTypes` was read as one type name, so a member named like the union resolved to the union itself (`type
  TPercentageST = type TPercentageST`, an endless loop with a default value, e.g. DrawingML `ST_Percentage`); a union with
  only inline members was left out while properties used it; a local union lost its attribute. A union now always declares
  its type: its only named member's type, otherwise the value as written (`string`)

## [1.4.0] - 2026-10-16

Office documents and a Windows encoding fix: non-ASCII text written to a string on Windows - so every Soapite request
body - came out garbled; fixed. Dublin Core and the OOXML core properties generate clean (substitution group members take
their head's type, text-only mixed content is text, `xsi:type`), shown by a sample that edits the properties of any Office
file; the client certificate from memory; plain-words hints for every problem line in ProRocket Lite. Verified on Delphi
10.3 to 13, Win32 and Win64. Development of this release was assisted by Claude Code (Anthropic).

### Added
- Soapite / HTTP: the client certificate from memory - `THttpTransportNative.ClientCertificateData` (the bytes of a
  PFX/P12 or PEM file: from a database, a resource, a key vault), next to `ClientCertificate` (a file). Either one, not both
  (the call fails with `EInvalidOpException`). Delphi 12 or later, like the file; not on Android, where System.Net uses
  only certificates installed on the device (`ENotSupportedException`). On Linux System.Net hands curl a temporary copy.
  The sample `ProRock.Http.ClientCertificate` makes the call both ways. Requested in issue #1
- ProRocket Lite: a hint for every problem line - what it means and what to do, in plain words, with the full path of the
  file (hover a line); "Copy all", Ctrl+C / Ctrl+A in the messages panel
- ProRocket Lite: the Del key deletes the selected project file
- ProRocket Lite: Dublin Core and OOXML core properties (`docProps/core.xml`) generate clean. A substitution group member
  without a type of its own gets its head's type (`<xs:element name="title" substitutionGroup="dc:any"/>` ->
  `TTitleE = class(TAnyE)`, so `dcterms:created` is a `dc:date` is a `dc:any`); mixed content where no child element can
  occur is text (`XmlValue`, like simpleContent - Dublin Core's SimpleLiteral). Mixed content with child elements and
  elements standing in for their head (a property of the head's type holding any member) are not supported yet
- Sample `ProRock.Xmlite.DocumentProperties`: the core properties of an Office document (.docx, .xlsx, .pptx) opened,
  edited and saved - units generated from the official OPC schemas, the core properties found through the package
  relationships, every other part kept byte for byte; warns before breaking a digital signature
- Xmlite: `TXmlite.SetXsiType(aType)` - an element holds a value of a derived type (`xsi:type`), from a generated class:
  `props.Created.SetXsiType(TW3cdtfCT)` writes `<dcterms:created xsi:type="dcterms:W3CDTF">` (OPC requires it on
  `created` / `modified`). Refuses a class that is not a complex type derived from the element's type

### Changed
- ProRocket Lite / CLI: `duplicate-unit` names the clashing namespaces and files
  (`sources="<uri> <uri>" from="a.xsd b.xsd"`) - every problem line has a `from` now
- ProRocket Lite: the messages panel spans the window width under the preview; project files show their file name
  (`a-part.xsd - urn:a`), so files sharing a namespace can be told apart. Virtual-TreeView 8.5

### Fixed
- Xmlite / Soapite: on Windows, non-ASCII text written to a string came out garbled (`Ё` as `РЃ`) - `ToXml`,
  `TXmlite.ObjectToXml` and so **every Soapite request body**: the UTF-8 bytes were read back with the ANSI code page.
  Writing to a stream or a file was not affected, nor were other platforms. Also the text of generated units (ProRocket)
- Xmlite: the text of mixed content (`XmlText`, e.g. OOXML `cp:keywords`) was read but not written back
- Xmlite: an attribute kept from the document (not in the schema, e.g. `xsi:type`) was written back without its prefix
  declared - invalid XML after a read-modify-write. Its prefix (and an `xsi:type` value's) is declared now, as the
  document had it (`XmlAttributeNamespaces`)
- ProRocket Lite: `<xs:any maxOccurs="0"/>` marked a type as accepting any element, and a group (`xs:sequence`, `xs:choice`,
  a group reference) with `maxOccurs="0"` still brought its elements
- ProRocket Lite: adding or deleting a file dropped the `unresolved-ref` lines of the other files until the next Generate
- ProRocket Lite: with a `duplicate-unit` problem Generate wrote both units into one file (the last one won); it writes
  nothing now, like the CLI

## [1.3.0] - 2026-10-14

The command line and correct namespaces: ProRocket CLI for scripts, build steps and AI coding assistants, with problem
reporting in CLI and GUI; client certificates; the Xmlite writer puts every element and attribute in its namespace (found
with the OASIS WS-Security and ebMS 3.0 schemas, validated against them). Verified on Delphi 10.3 to 13, Win32 and Win64.
Development of this release was assisted by Claude Code (Anthropic).

### Added
- Soapite / HTTP: client certificates (mutual TLS) on `THttpTransportNative` - `ClientCertificate` (a PFX/P12 file; on
  Android the name or fingerprint of an installed certificate) and `ClientCertificatePassword`. A missing file or a wrong
  password fails the call (`sekNetwork` in Soapite) with the System.Net message, never with the password. Needs Delphi 12 or later
  (System.Net of 10.3 ignores the file, of 10.4 and 11 cannot open it): there a call with a certificate raises
  `ENotSupportedException` instead of going out without it. Sample `ProRock.Http.ClientCertificate` (the public test server
  client.badssl.com)
- Sample `ProRock.Soapite.WsSecurity`: a WS-Security UsernameToken with PasswordDigest, Nonce and Timestamp in the
  SOAP header (through `OnRequestHeader`), from units generated from the official OASIS schemas; offline by default
  (prints the request), `-live` against the public Calculator service
- Xmlite: `[TQualified]` - an attribute written with its namespace prefix also in an element of its own namespace (XSD:
  form="qualified", e.g. `wsu:Id` in `wsu:Timestamp`). For hand-written classes; in generated units a reference to a global
  attribute is qualified by its type (see Fixed)
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
