# Samples

In [`Samples`](https://github.com/VitalyPopov/ProRock/tree/main/Samples) of the repository, one group project
(`ProRock.Samples.groupproj`). The generated units and the source WSDL/XSD files are included, so the samples build without
running the generator.

| Sample | What it shows |
|---|---|
| [`ProRock.Xmlite.Spreadsheet`](#excel-workbook) | an Excel workbook from the official SpreadsheetML schemas (22,000 generated lines): sheets, dates, formulas and tables shown, cells edited, written back with everything Excel put in it |
| [`ProRock.Xmlite.Fhir`](#fhir-resources) | HL7® FHIR® R4 resources from the official schemas (38,000 generated lines): a Bundle listed with each Observation's value, the narrative as text, written back as it was; a Bundle of 1,000 resources timed |
| [`ProRock.Xmlite.DocumentProperties`](#office-document-properties) | the properties of any Office document: open, edit, save; the sheet or slide titles |
| [`ProRock.Soapite.CheckVatService`](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Soapite.CheckVatService) | EU VIES VAT number validation through the generated `TCheckVatService`, with live SOAP Fault handling; `-name:` compares the trader's name too (`checkVatApprox`) and tells an absent match code from VALID with `Present` |
| [`ProRock.Soapite.WsSecurity`](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Soapite.WsSecurity) | a WS-Security UsernameToken (PasswordDigest, Nonce, Timestamp) in the SOAP header, from units generated from the OASIS schemas; offline, or `-live`. Other header blocks work the same way, e.g. the ebMS 3.0 `eb:Messaging` of AS4 |
| [`ProRock.Http.ClientCertificate`](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Http.ClientCertificate) | client certificates (mutual TLS) against the public test server client.badssl.com: HTTP 400 without, 200 with - from a file and from memory |
| [`ProRock.Soapite.Calculator`](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Soapite.Calculator) | a generated client calling a public calculator service (`-soap12` and `-xml` switches) |
| [`ProRock.Xmlite.Namespaces`](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Xmlite.Namespaces) | a generated metamodel from `order.xsd`: parsing, enums, serialization, round trip |
| [`ProRock.Xmlite.Basic`](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Xmlite.Basic) | hand-written models, basic parsing and serialization |

## Excel workbook

[`ProRock.Xmlite.Spreadsheet`](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Xmlite.Spreadsheet) opens an
Excel workbook (.xlsx) into the units ProRocket generates from the SpreadsheetML schemas of ECMA-376: the workbook, its
sheets, shared strings, styles and tables, found as Office finds them - through the package's relationships. Each sheet is
shown in a grid: text, numbers, dates (from the cell's style), the formula of the selected cell; the tables with their
columns. Cells without a formula can be edited. Save writes every part it read back from its objects - with everything
Excel put in them that the schema does not describe (`extLst`, revision ids, `mc:Ignorable`) - and copies every other part
as it is. Excel opens the saved file and recalculates its formulas. `demo.xlsx` is an invoice saved by Excel: a Table with
a calculated column and a total row (`SUBTOTAL(109,Table1[Amount])`).

```pascal
// a cell's text: a shared string by its index, a number as written, a date from its style
case cell.T of
  stctS: Result := SharedString(StrToIntDef(cell.V, -1));       // <c r="B3" t="s"><v>4</v></c>
  stctN: Result := cell.V;                                       // <c r="C6"><v>4</v></c>
end;
if cell.F.XmlValue <> '' then                                    // <f>C6*D6</f>
  Writeln('=', cell.F.XmlValue);

// an edit: Excel recalculates the totals when it opens the file
cell.V := '5';
workbook.CalcPr.FullCalcOnLoad := True;
```

## FHIR resources

[`ProRock.Xmlite.Fhir`](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Xmlite.Fhir) reads HL7® FHIR® R4
XML - a Bundle or a single resource - into the units ProRocket generates from the standard's schemas (`fhir-single.xsd`,
`fhir-xhtml.xsd`): 146 resource types, their data types and the narrative's XHTML, 38,000 lines. It lists each resource
with what it is, its value and when; the selected one's narrative is shown as text. Save as writes the file back as it
was read, and Speed test reads and writes a Bundle of 1,000 resources made of the same entries. `bundle.xml` holds the
Patient and Observation examples of the specification.

The resource of a Bundle entry is a choice of all 146 resource types; an Observation's `value[x]` is one of eleven.
Only the member in the document is created, and the typed shortcut gives it:

```pascal
for var entry in bundle.Entry do
begin
  var resource := entry.Resource.Chosen;               // the one resource in this entry
  if (resource <> nil) and resource.InheritsFrom(TObservationCT) then
  begin
    var value := TObservationCT(resource).ValueChosen; // TQuantityCT, TCodeableConceptCT, TStringCT... or nil
    if (value <> nil) and value.InheritsFrom(TQuantityCT) then
      Writeln(TQuantityCT(value).Value.Value, ' ', TQuantityCT(value).&Unit.Value); // 185 lbs
  end;
end;
```

The narrative is XHTML mixed content: `InnerText` gives its text; the sample walks `XmlContent` to end a line after
each paragraph. FHIR's own `meta` element hides ProRock's `Meta` in every resource class - `TBasite(resource).Meta` is
the class metadata.

Compiling the FHIR unit takes about a minute; the program starts in about a third of a second.

## Office document properties

[`ProRock.Xmlite.DocumentProperties`](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Xmlite.DocumentProperties)
opens any Office document (.docx, .xlsx, .pptx) and edits the properties Office shows in **File > Info**: title, subject,
author, keywords, description, category, status. Save writes them back; Excel opens the saved file without a repair prompt
and shows every value in File > Info.

![The DocumentProperties sample with an .xlsx file open: title, subject, author, keywords, comments and the other core properties, the application and the worksheets](assets/document-properties.png)

An Office document is a zip of XML parts (OPC, ECMA-376 Part 2). The sample uses units generated from the official schemas:

- `opc-relationships.xsd` - to find the core properties part through the package relationships (`_rels/.rels`)
- `opc-coreProperties.xsd`, built on Dublin Core - the properties themselves (`docProps/core.xml`)
- `shared-documentPropertiesExtended.xsd` (ECMA-376 Part 4) - what the application says about the document
  (`docProps/app.xml`): its name, and the titles of its parts - the sheets of a workbook, the slides of a presentation

```pascal
// the generated classes: Dublin Core elements carry their text in XmlValue (dc:title, dcterms:created), the elements of
// the core properties namespace are plain strings (cp:category), cp:keywords is mixed content - its text is XmlText
var properties := fDocument.Properties;
TitleEdit.Text := properties.Title.XmlValue;
KeywordsEdit.Text := properties.Keywords.XmlText;
CategoryEdit.Text := properties.Category;
```

On save, `Modified` is set to now (UTC) with the `xsi:type` OPC requires, and every other part of the file is copied byte for
byte, in the same order and with the same compression:

```pascal
fProperties.Modified.XmlValue := FormatDateTime('yyyy-mm-dd"T"hh":"nn":"ss"Z"', TTimeZone.Local.ToUniversalTime(Now));
fProperties.Modified.SetXsiType(TW3cdtfCT); // <dcterms:modified xsi:type="dcterms:W3CDTF">
var core: TBytes := TEncoding.UTF8.GetBytes(TXmlite.ObjectToXml(fProperties));
```

A digitally signed document gets a warning first: the signature usually covers the core properties, so saving breaks it.

The application's properties are shown, not edited (saved as they were). The titles of the parts are a list of plain
strings - a `vt:vector` of `vt:lpstr` - grouped by heading pairs, a name and a count each:

```xml
<HeadingPairs><vt:vector size="2" baseType="variant">
  <vt:variant><vt:lpstr>Worksheets</vt:lpstr></vt:variant><vt:variant><vt:i4>2</vt:i4></vt:variant>
</vt:vector></HeadingPairs>
<TitlesOfParts><vt:vector size="2" baseType="lpstr">
  <vt:lpstr>Sales</vt:lpstr><vt:lpstr>Costs</vt:lpstr>
</vt:vector></TitlesOfParts>
```

```pascal
var titles := extended.TitlesOfParts.Vector.Lpstr;     // a TList<string>: Sales, Costs
var pairs := extended.HeadingPairs.Vector.Variant;     // Worksheets, 2
for var i := 0 to pairs.Count div 2 - 1 do
begin
  var count: integer := pairs[2 * i + 1].I4;
  ...                                                  // "Worksheets: Sales, Costs"
end;
```

The schemas behind it use substitution groups and `xsi:type` - see [XML concepts](xml-concepts.md) for what they are.
