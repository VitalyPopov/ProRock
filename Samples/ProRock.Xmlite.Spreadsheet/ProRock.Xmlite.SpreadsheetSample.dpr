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
  SpreadsheetDocument in 'SpreadsheetDocument.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
