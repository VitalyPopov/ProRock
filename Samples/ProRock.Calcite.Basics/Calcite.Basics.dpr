program Calcite.Basics;

// Calcite, Excel workbooks (.xlsx) in plain Delphi: a tab per feature - values, formulas, formats, rows and columns, sheets,
// a DataSet, issues - and a button per thing it does; each button's handler is the code to copy. The preview shows the sheet
// a button wrote, read back through Calcite; Open in Excel saves the workbook next to the program and opens it there.
//
// The schema notices are in THIRD-PARTY-NOTICES.md (ECMA-376, (c) Ecma International).

uses
  Vcl.Forms,
  Form.Main in 'Form.Main.pas' {MainForm},
  SheetPreview in 'SheetPreview.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
