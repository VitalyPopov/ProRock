# Contributing to ProRock

Thank you for helping. ProRock is a one-person project, so the most valuable help is a precise report.

## Reporting a schema or WSDL that doesn't work

ProRock's coverage grows through real-world schemas. If ProRocket Lite fails on a schema, generates code that doesn't compile, or
the generated classes read or write XML wrongly, open a **Schema / WSDL support** issue with:
- the schema or WSDL (attached, or a public link), including the files it imports
- a sample XML document, if the problem is in reading or writing
- what you expected and what happened (error message, wrong output)
- the Delphi version and platform (Win64 / Win32), and the ProRock / ProRocket Lite versions

Strip confidential data from samples; the structure is what matters.

## Reporting a bug

Use the **Bug report** template. A minimal repro (a few lines of code and the XML involved) gets a bug fixed fastest.

Security problems: please don't open a public issue, see [SECURITY.md](SECURITY.md).

## Pull requests

Small, focused pull requests are welcome. Before you start something bigger, open an issue to discuss it.

- The code must compile with Delphi 13 and keep compiling with Delphi 10.3 (no language features newer than 10.3, e.g. no
  conditional expressions, no multiline strings)
- follow the existing style: 140-character lines, inline `var`, `a`-prefixed parameters, `f`-prefixed fields, `{ TClass }`
  section comments
- every fix comes with its repro (the XML or schema that failed before)
- the generated units (`ProRock.Xmlite.Schema.*`) are not edited by hand; they change by regenerating

The test suite currently lives in the private ProRocket repository: the maintainer runs it for every pull request. Describe how you
checked your change (Delphi version, platform, what you ran).

## License of contributions

ProRock is licensed under the [Apache License 2.0](LICENSE). By submitting a contribution, you agree that it is licensed under the
same terms (Apache License 2.0, section 5).
