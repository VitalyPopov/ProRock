---
icon: lucide/code-xml
---

# XML (Xmlite)

Reading and writing XML through plain Delphi objects: one class per element or type of the schema, one property per child element
or attribute. Xmlite is namespace- and schema-aware, and parses in place on the text, without building a DOM.

The classes come from the [generator](prorocket-lite/index.md); for a small format without a schema you can
[write them by hand](hand-written.md).

## Reading and writing

```pascal
uses System.SysUtils,
  ProRock.Xmlite,
  ProRock.Xmlite.Schema.Order;

var order := TOrderE.Create; // the root element's class: <order> -> TOrderE
try
  if order.FromXmlFile('order.xml') then // True when the file was read and parsed
    Writeln(order.Customer.Name, ': ', order.Items.Item.Count, ' items');

  order.Status := osShipped;
  order.ToXmlFile('order.xml');
finally
  order.Free;
end;
```

!!! warning "`FromXml` and `ToXml` need `ProRock.Xmlite` in `uses`"
    They come from a class helper, visible only where that unit is listed. Without it: E2003, undeclared identifier.

- Nested objects and lists are created and freed with their parent; just use them. What each schema construct becomes:
  [Generated code](generated-code.md).
- A repeating element of a simple type is a list of plain values: `<author>Ann</author><author>Bob</author>` is
  `Authors.Author.Add('Ann')`, a `TList<T>` to use.
- `FromXmlFile` and `FromXmlBytes` read a document in its encoding: the BOM (UTF-8, UTF-16), else the declaration's
  `encoding=` (ISO-8859-1, windows-1252...), else UTF-8. `False` also when the encoding is unknown or the bytes do not fit it.
  `ToXmlFile` writes UTF-8 without a BOM. `FromXml` and `ToXml` take and give a string, for text you have already.
- `TXmlite.ObjectToXml(obj)` writes any object, also one that is not a root element.

## Absent or default: presence

An optional value can be missing from a document, or there with any value - also its default:

```xml
<sheet count="0"/>   <!-- count is there, and it is 0 -->
<sheet/>             <!-- count is absent -->
```

Both read as `Count = 0`. Xmlite remembers which values the document had, and writes exactly those back - also when they equal
their default (`count="0"`, FHIR `gender value="male"`, an Excel fill with only defaults). You can ask, mark and remove:

```pascal
if response.Present[@response.TraderNameMatch] then // VIES: in the response, not just the first enum value
  ...
sheet.Count := 0;               // set in code and equal to the default: not written...
sheet.SetPresent(@sheet.Count); // ...unless marked present: count="0"
sheet.Clear('Drawing');         // removes a value or an object: back to its default, and absent
```

- `Present[@Obj.X]` tells exactly what the writer does: present when read, marked, not the default, or (an object) with any
  content. `[TRequired]` values and objects are written always when built in code; read from a document, only when it had
  them or code sets them.
- An assignment in code is not seen (properties write their fields), so a value equal to its default set in code needs
  `SetPresent`. A value that was read stays present when code assigns it the default (`Title.XmlValue := ''` writes an empty
  element); to remove it, use `Clear`.
- `@Obj.X` works for properties that read a field: plain values and required objects. An optional object has a getter
  ([created on first access](large-documents.md)), so pass its name, the property's or the schema's: `SetPresent('Drawing')`. A wrong
  one is skipped, nothing raises: the functions return `False`.

## Content the schema does not describe

Real documents carry more than their schema: Office writes its own extensions into every file, a newer version of a format
adds elements. Xmlite keeps such content and writes it back:

```xml
<workbook ...>
  <workbookPr defaultThemeVersion="202300"/>
  <xr:revisionPtr revIDLastSave="0" documentId="..."/>   <!-- not in the schema: kept -->
  <bookViews>...</bookViews>
```

- **Attributes** without a property are kept in `XmlAttributes`.
- **Elements** without a property are kept as their exact text in `XmlUnknown` and written back where they were - after the
  same element, between the same list items. The content of `xs:any` from a namespace without generated units is kept the
  same way.
- **Values that do not fit their type** (`12,50` in a decimal, `XXX` in an enumeration, `<amount currency="EUR"/>`): the property
  is not present and holds its default, the read goes on, and the value is written back as it came - an element through
  `XmlUnknown`, an attribute through `XmlAttributes`, the text of an element with attributes through `XmlText`. Setting the property
  replaces it; to set it to its default, `SetPresent` too.
- **Namespace declarations** of the document are written back too, so prefixes that only appear in values
  (`mc:Ignorable="x14ac"`) stay declared.
- `Clear` removes the kept content with the rest.

Kept content is never written without being checked: an element whose tags are not closed or crossed, or which uses an
undeclared prefix, fails the read - as any malformed XML does: `FromXml` returns `False`, and the object holds what was read
up to there.

!!! tip "ProRock reads on, it does not validate"
    A value that does not fit is kept and written back, so a document comes through unharmed. The other end will still refuse it,
    as it would have refused the document before.

## Mixed content and element order

```xml
<p><b>status</b>: final <span>(Details)</span></p>
```

Text between child elements, as in HTML - or a FHIR resource's narrative, which is XHTML. A mixed type (`mixed="true"`) gets
`[TMixed]`, and its object keeps the text runs and its children in document order in `XmlContent`. A repeating choice
(`<font>` in Excel styles: `<sz/><color/><name/>` in any order) gets `[TOrdered]`: the same order, without text. The typed
lists stay as they are - `p.B[0]` is the first `<b>` - and `XmlContent` refers to the same objects:

```pascal
Writeln(obs.Text.&Div.InnerText);   // all the text, children included, in document order

for var node in p.XmlContent do
  if node.IsText then
    Write(node.Text)
  else if node.IsElement<TAE> then
    Write('[', node.Element.InnerText, '](', node.ElementAs<TAE>.Href, ')')
  else
    Write(node.Element.InnerText);   // node.Name: the element's name - b, span
```

Built in code, in the order of the calls:

```pascal
var p := obs.Text.&Div.Add<TPE>;   // added to Div.P and to the order
p.Add<TBE>.AddText('status');
p.AddText(': final');
// <div xmlns="http://www.w3.org/1999/xhtml"><p><b>status</b>: final</p></div>
```

- `XmlText` of a mixed element is its leading text (`cp:keywords`: the whole text); setting it replaces that text.
- Children added straight to a typed list are written after the ones in `XmlContent`, in the schema's order.
- Remove a child with `Remove(child)`: it leaves both its list and `XmlContent`. A child deleted through its list only is
  no longer written, but its node in `XmlContent` refers to a freed object.
- Inside a mixed element the writer writes no indentation (`Pretty`): it would become a part of the text.
- `Ordered` and `Mixed` are settings of the class's metadata (`TPE.Meta.Xmlite.Mixed`) - changeable at run time, for every
  object of the class. Units generated before 1.6 have no `[TMixed]`: regenerate them.

## Derived types: `xsi:type`

When the schema allows a derived type in place of the declared one, the document says so with `xsi:type`. To write it, tell the
element which class it holds:

```pascal
props.Modified.SetXsiType(TW3cdtfCT); // <dcterms:modified xsi:type="dcterms:W3CDTF">
```

`SetXsiType` refuses a class that is not a complex type derived from the element's type. See
[XML concepts](xml-concepts.md#derived-types-and-xsitype) for what this means.

What of XML and XML Schema is covered: [XML support](xml-support.md); notes for using it: [Limitations and notes](limitations.md).
