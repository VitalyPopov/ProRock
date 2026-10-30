program ProRock.Xmlite.SpreadsheetSample;

// An Excel workbook (.xlsx) read into the classes ProRocket generates from the official SpreadsheetML schemas
// (ECMA-376 Part 4, Transitional: 22,000 lines), shown sheet by sheet - values, dates, formulas, tables - edited, and
// written back with everything Excel put in it: its extensions, the table and its total row, the formulas' structured
// references. Every other part of the file is copied as it is. Usage: ProRock.Xmlite.SpreadsheetSample [<workbook>] - or
// open / drop a file in the window; demo.xlsx (an invoice saved by Excel) opens by default.
//
// The schema notices are in THIRD-PARTY-NOTICES.md (ECMA-376, (c) Ecma International).

uses
  Vcl.Forms,
  Form.Main in 'Form.Main.pas' {MainForm},
  SpreadsheetDocument in 'SpreadsheetDocument.pas',
  ProRock.Xmlite.Schema.Ooxml.Sml in 'ProRock.Xmlite.Schema.Ooxml.Sml.pas',
  ProRock.Xmlite.Schema.Ooxml.DmlSheet in 'ProRock.Xmlite.Schema.Ooxml.DmlSheet.pas',
  ProRock.Xmlite.Schema.Ooxml.DmlMain in 'ProRock.Xmlite.Schema.Ooxml.DmlMain.pas',
  ProRock.Xmlite.Schema.Ooxml.Rel in 'ProRock.Xmlite.Schema.Ooxml.Rel.pas',
  ProRock.Xmlite.Schema.Ooxml.SimpleTypes in 'ProRock.Xmlite.Schema.Ooxml.SimpleTypes.pas',
  ProRock.Xmlite.Schema.Relationships in 'ProRock.Xmlite.Schema.Relationships.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
