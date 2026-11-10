---
icon: lucide/terminal
---

# Command line

`ProRocketCli.exe` is ProRocket Lite from the command line: the same generator as the [GUI](gui.md), giving the same units, for
scripts, build steps and AI coding assistants.

## In just one command

```
ProRocketCli.exe -o Generated main.xsd imported.xsd
```

Give the main XSD or WSDL and the files it imports and includes. If a file is missing, a problem line names it: add it and run
again. Then use the units from `Generated`, with the `Source` folder of the ProRock release named in the unit header on the
search path.

!!! tip "Working with an AI coding assistant?"
    Point it to **`CLI.md`** in the zip, or to the same text [here](cli-full.md): how to verify the download's SHA-256, ask you before
    running anything, read the problem lines, and set up the project. Written for assistants and people alike.

## Command

```
ProRocketCli.exe [-o <output folder>] [--strict] [--no-timestamp] [--full-type-names] <file.xsd|file.wsdl> ...
```

| Option | Meaning |
|---|---|
| `-o <folder>` | where the units are written; created if missing. Default: the current folder |
| `--strict` | write nothing if there are problems; exit code 1 |
| `--no-timestamp` | leave out the `Generated (UTC)` header line: an unchanged schema gives a byte-identical unit |
| `--full-type-names` | keep the whole XML name in Delphi type names ([Type names](generated-code.md#type-names)) |
| `--version` | the version; the generated units need the ProRock release with that number |
| `-h`, `--help` | usage |

**Generate all the schemas of a project in one run, every time.** Units generated separately, or by different versions, may not
fit together, and regenerating everything costs nothing. The CLI never downloads anything: it follows a local relative
`schemaLocation` (`../common/types.xsd`, never a URL), and a file you give wins over the one found there. It does not expand
wildcards either; list the files, or let the shell do it.

The standard schemas are part of ProRock, so you do not give them: XML Schema, `xml:` and `xsi:` attributes, the SOAP envelopes,
WSDL and its SOAP bindings.

## Output

Units, named as in [Generated code](generated-code.md#units), overwriting files of the same names. Generate into a folder under
version control: an updated schema then shows up as a clean diff. stdout gets one line per written unit:
`generated: <full path>`.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | units generated, no problems |
| 1 | nothing generated: bad arguments, a file that is missing or cannot be loaded, an error, two units with the same name (`duplicate-unit`), or problems with `--strict` |
| 2 | units generated, but with problems (listed on stderr) |

## Problem lines

On stderr, sorted, one per problem:

```
problem: <kind> key="value" key="value" ...
```

Values are always in double quotes. Errors (exit code 1) are `error: <message>` lines.

| Kind | Example | What to do |
|---|---|---|
| `missing-schema` | `namespace="urn:b" location="b.xsd" from="a.xsd"` | `a.xsd` imports and uses namespace `urn:b`, and no file of it is given or found at `location` (a relative path is followed, a URL never); add that schema. Its types fall back to `string` and its elements are left out until then |
| `missing-include` | `namespace="urn:a" location="a-part.xsd" from="a.xsd"` | the included file is not at `location` (relative to `a.xsd`) and not given; add it - a given file with the same name counts |
| `unresolved-ref` | `kind="type" name="NoSuchType" namespace="urn:a" from="a.xsd"` | a name that exists in no given file of that namespace: a typo in the schema, or a definition in a file still missing (an include). Types fall back to `string`, element references are left out |
| `unsupported` | `feature="redefine" location="base.xsd" from="a.xsd"` | `xs:redefine` is not supported: the redefined components come out in their original form |
| `duplicate-unit` | `unit="ProRock.Xmlite.Schema.Order"` | two namespaces get the same unit name (e.g. the same path under two hosts); nothing is written (exit code 1). Generate them in separate runs into separate folders, and tell the developer |

`kind` in `unresolved-ref` is one of `type` (complex or simple), `complexType`, `simpleType`, `element`, `attribute`,
`attributeGroup`, `group`. References into a namespace that is reported as `missing-schema` are not listed one by one.

!!! warning "Limits"
    - runs on Windows 64-bit; the generated units need Delphi 10.3 or later
    - namespaces that import each other come out in one unit (Delphi allows no circular `uses`)
    - WSDL problems (skipped operations, `wsdl:import`) are written in the unit header, not as problem lines

    All of them: [Limitations and notes](limitations.md).
