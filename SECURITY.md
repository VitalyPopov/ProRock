# Security Policy

## Supported versions

Security fixes go into the latest release (currently 1.1.x) of ProRock and ProRocket Lite.

## Reporting a vulnerability

Please do **not** open a public issue for a security problem.

Report it privately through GitHub: **[Report a vulnerability](https://github.com/VitalyPopov/ProRock/security/advisories/new)**
(the Security tab of this repository). Only the maintainer sees the report.

Please include what is affected (unit, version), how to reproduce it (an XML document, schema or WSDL that triggers it helps most),
and the impact you see. This is a one-person project: every report is taken seriously and answered as soon as possible. Once it is
resolved, the fix is released with a public advisory, crediting you if you wish.

## Scope

ProRock parses XML that may come from untrusted sources (files, SOAP responses), so parser issues are in scope: crashes, hangs,
excessive memory use, out-of-bounds reads. ProRocket Lite reports are welcome too.

## Dependencies

ProRock has no third-party code dependencies: it uses the Delphi RTL only (`System.Net` for HTTP in `ProRock.Http`). See
[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) for the schemas the generated metamodels are derived from.
