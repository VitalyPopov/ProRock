---
icon: lucide/triangle-alert
---

# Limitations and notes

What to know before relying on it. Which XML and XML Schema constructs are covered, one by one: [XML support](xml-support.md); what
comes next: [Roadmap](roadmap.md). If your schema doesn't generate or doesn't read right, please
[open an issue](https://github.com/VitalyPopov/ProRock/issues/new/choose): coverage grows through real-world schemas.

## Platform and compatibility

| | |
|---|---|
| **Delphi 13 Florence** (13.1) | developed and tested on it, mainly on Win64; Win32 is supported as well |
| **Delphi 12, 11, 10.4, 10.3** | every release is verified to compile and pass the tests, Win64 and Win32<br>(10.4 Win32: compiled only) |
| before **10.3** | not supported: the code uses inline variables |
| **Client certificates** | Delphi 12 or later (System.Net's support for them) |
| **Android** 32/64-bit | all units compile (Delphi 13), running on a device is not verified yet |
| **ProRocket Lite**, the generator | runs on Windows 64-bit |

!!! note "Delphi 10.3 compiles large generated units much slower"
    All of FHIR R4 (a unit of about 46,000 lines, 49,000 with the XHTML unit for its narratives) takes about 3 minutes there, against
    10-20 seconds on Delphi 13. Only 10.3 does this, 10.4 and later do not. Why is not known, and honestly, it is an old Delphi, so
    there are no plans to investigate. Compile times of the others: [Tested schemas](tested-schemas.md).

## Writing a document back

A document read and written back keeps what its schema describes: values equal to their default, objects with only defaults, absent
values staying absent, enumeration texts, element order as in the schema ([presence](xmlite.md#absent-or-default-presence)), the
elements the schema does not describe, and mixed content with its text and order
([mixed content](xmlite.md#mixed-content-and-element-order)).

A value set in code that equals its default is written only when marked present (`SetPresent`).

!!! warning "ProRock does not validate"
    - A required element you don't set in an object built in code is written all the same, empty, or as `0` for a number, so a
      forgotten amount looks like a real `0`. Validate what you send where it matters. An object read from a document writes a
      required element only when the document had it or code sets it: nothing is made up.
    - An attribute on an element of a plain value (`<v extra="1">12</v>`, where the schema allows none) is not kept.
      `xml:space` is written again where the text needs it.

## Schema sets

- Namespaces that import each other share one unit, named after the one you gave: Delphi allows no circular `uses` between units.
  HL7 CDA's `urn:hl7-org:v3` and its SDTC extensions come out as one. If both refer to the other's global elements or attributes,
  the members of one of them are written in the wrong namespace: please
  [open an issue](https://github.com/VitalyPopov/ProRock/issues/new/choose) if you meet such a pair.

## Numbers

`xs:decimal`, `xs:float` and `xs:double` are `Double`, written as the shortest text that reads back the same value. A number of up to
15 significant digits comes back as the same number (`0.1` stays `0.1`; `1.50` is written `1.5`), a longer one as the same Double in
its shortest text, and digits beyond what a Double holds (about 17) are lost. `xs:integer` is `Int64`, `xs:unsignedLong` is `UInt64`.

!!! tip "For money arithmetic, convert to `Currency` before calculating"
    Arithmetic on a `Double` is binary floating point:
    `var price: Currency := line.Price; var total := price * line.Quantity;`
