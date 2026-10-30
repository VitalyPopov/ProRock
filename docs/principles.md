# Design principles

What is kept in mind while building ProRock - and what it is not. Not rules it follows to the letter: an orientation, there
when each new problem is met.

## A cockpit, not an engine room

The hard parts stay inside: schemas, namespaces, prefixes, object lifetimes, laziness, metadata. Outside are a few clear
controls - properties, enums, lists and a handful of verbs. The FHIR unit is 38,000 generated lines, and a Bundle entry is
a choice of 146 resource types; using it is this:

```pascal
bundle.FromXml(xml);
for var entry in bundle.Entry do
  if entry.Resource.Chosen is TObservationCT then
    Show(TObservationCT(entry.Resource.Chosen).ValueChosen); // a quantity, a code, a text...
```

The library pays for the complexity, so its user does not.

## Little to learn, quick to start

Nothing to study beyond the Delphi you know - not even XML, XSD or WSDL themselves: get the schemas, generate, use. No DOM,
no XPath, no node API: the classes are the schema, and code completion is their documentation. When an XML term does come
up, [XML concepts](xml-concepts.md) explains it in Delphi terms.

Nothing to install either - no packages, no DLLs, no design-time components: add `Source` to the search path and use the
units. From a WSDL to a working SOAP call takes [5 minutes](getting-started.md).

## Hide the mechanism, never the control

You do not need to know how it works, but you always decide what happens:

- **Ownership is explicit.** A parent creates and frees its children; you free what you create; a response is yours to
  free. No interfaces, no reference counting, no lifetime you cannot see.
- **Output is deterministic.** An unchanged schema gives an unchanged unit - with `--no-timestamp` byte for byte - so a new
  schema version shows up as a clean diff.
- **Writing follows what you have.** What was read is written back, what you set is written, an absent optional value
  stays absent ([presence](xmlite.md#absent-or-default-presence)).

## Prevent what can be prevented, tolerate the rest

Many mistakes cannot happen at all: a misspelled element, a value outside an enumeration, a child in the wrong place do not
compile. What cannot be prevented - real-world data, incomplete schema sets - does not stop the work:

- Content the schema does not describe is kept and written back, not rejected
  ([Xmlite](xmlite.md#content-the-schema-does-not-describe)).
- A schema set with a missing file still generates; the gaps fall back to plain strings, and each is reported in one line
  for whoever wants to fix it ([Command line](cli.md#problem-lines)).
- The result may not be perfect yet, but it works - and the reports tell why it is not perfect. An optional log of what a
  read had to skip is planned.

One limit: tolerance never becomes a false claim. Kept content is written back as it was read, so content that is not
well-formed XML fails the read instead of being written back broken.

## As fast as it can be made

Wherever something can be faster, it is made faster. You do not pay for what you do not touch: the members of a choice
are created on first access, and a FHIR Bundle of 1,000 Patients reads in 0.10 s ([Large documents](large-documents.md)).
Parsing works on the text without building a DOM; class metadata is built once, not scanned again for every document.
Measured on real documents, with the numbers published.

## Reality decides

Real schemas, real files and real requests set the priorities: FHIR R4, Office's own files, the EU VIES service, and what
its users ask for. A feature counts as supported when it is verified on such data, and the
[XML support](xml-support.md) page says as plainly what is partial or missing.

## Progressive, in layers

Whatever is built becomes the ground for what comes next. The core, **Basite**, knows nothing about XML: it knows plain
Delphi objects and their metadata - who owns what, which values are present. XML is one layer on top of it (**Xmlite**),
SOAP one on top of XML (**Soapite**). So JSON can come as another layer on the same classes, not as a second library
([roadmap](roadmap.md)) - and what one layer gains, the next ones get.

The generator stands on the same ground: ProRocket Lite reads every XSD and WSDL through ProRock itself, with classes it
generated - whatever it needs, the library gets first.

And forward, not backward: modern Delphi, 10.3 and later, where inline variables start - no weight carried for older ones.

## What ProRock is not

- **Not a validator - today.** Documents are read and written, not checked against their schema; facets are not enforced.
- **Not a DOM.** XML is read into classes - generated from its schema, or written by hand when there is none
  ([Xmlite](xmlite.md#hand-written-classes)) - not into a tree of nodes.
- **Not a company product.** One developer builds it, free to use; [support](https://github.com/sponsors/VitalyPopov) is
  what keeps it going, and it is highly appreciated.
- **Not a competitor.** There is no one to beat: other libraries do their work, and collaboration moves Delphi forward.
- **Not a textbook.** Some choices may look off next to common patterns. They are made for the result, not to show a best
  practice.
- **Not finished.** What of XML Schema is covered, in part or not yet, is listed on [XML support](xml-support.md).

## How it is built

Since October 2026 with [Claude Code](https://claude.com/claude-code) (Anthropic) as an assistant: it helps with
implementation, tests and generator fixes. Design and decisions are the author's, and every change is tested with Delphi
10.3 to 13 and on real documents before it ships.

> Yes, this mention is mine, not the AI's. I value the boost Claude has given ProRock, and this is my tribute to it. 🤟
>
> — Vitaly Popov, the author
