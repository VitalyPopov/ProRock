program ProRock.Xmlite.FhirSample;

// HL7® FHIR® R4 resources - a Bundle or one resource - read into the classes ProRocket generates from the official FHIR
// schemas (38,000 lines: 146 resource types, their data types, the narrative's XHTML), listed, and written back. Shows
// a choice read through its typed shortcut (an Observation's value[x]: ValueChosen), a Bundle entry's resource as the
// one chosen of 146 (Resource.Chosen), the narrative's mixed content as text (InnerText), and how long a Bundle of
// 1,000 resources takes. Usage: ProRock.Xmlite.FhirSample [<file>] - or open / drop a file in the window; bundle.xml
// (the Patient and Observation examples of the specification) opens by default.
// Compiling the FHIR unit takes about a minute; the program starts in about a third of a second.
//
// The schemas: Copyright (c) 2011+, HL7, Inc. - the notice is in fhir-single.xsd and THIRD-PARTY-NOTICES.md.

uses
  Vcl.Forms,
  Form.Main in 'Form.Main.pas' {MainForm},
  FhirDocument in 'FhirDocument.pas',
  ProRock.Xmlite.Schema.Fhir in 'ProRock.Xmlite.Schema.Fhir.pas',
  ProRock.Xmlite.Schema.Xhtml in 'ProRock.Xmlite.Schema.Xhtml.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
