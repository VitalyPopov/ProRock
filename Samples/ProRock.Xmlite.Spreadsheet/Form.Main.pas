unit Form.Main;

// An Excel workbook shown sheet by sheet in a grid: values, dates, the formula of the selected cell, the tables. Cells that
// hold no formula can be edited; Save writes the workbook back - Excel recalculates the formulas when it opens it. All the
// workbook work is in SpreadsheetDocument.pas; this form only shows it and takes the edits

interface

uses Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Grids,
  SpreadsheetDocument;

type
  TMainForm = class(TForm)
    ButtonsPanel: TPanel;
    OpenButton: TButton;
    SaveButton: TButton;
    SaveAsButton: TButton;
    FileLabel: TLabel;
    TablesLabel: TLabel;
    CellLabel: TLabel;
    SheetTabs: TTabControl;
    CellsGrid: TStringGrid;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure OpenButtonClick(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
    procedure SaveAsButtonClick(Sender: TObject);
    procedure SheetTabsChanging(Sender: TObject; var AllowChange: Boolean);
    procedure SheetTabsChange(Sender: TObject);
    procedure CellsGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure CellsGridSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
  private
    fDocument: TSpreadsheetDocument;
    fEdits: TStringList; // ref=text of the cells edited on the current sheet, taken into the document before a save

    procedure WMDropFiles(var aMessage: TWMDropFiles); message WM_DROPFILES;

    procedure OpenDocument(const aFileName: string);
    procedure SaveDocument(const aFileName: string);
    procedure ShowSheet;
    procedure TakeEdits;
    function CurrentSheet: TSheet;
  public
    destructor Destroy; override;
  end;

var
  MainForm: TMainForm;

implementation

uses System.UITypes, System.Math, System.StrUtils, Winapi.ShellAPI, ProRock.Xmlite.Schema.Ooxml.Sml;

{$R *.dfm}

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  fDocument := TSpreadsheetDocument.Create;
  fEdits := TStringList.Create;
  DragAcceptFiles(Handle, True);

  // the sample's workbook (an invoice with a table and a total row, saved by Excel), unless a file is given
  if ParamCount > 0 then
    OpenDocument(ParamStr(1))
  else if FileExists(ExtractFilePath(ParamStr(0)) + 'demo.xlsx') then
    OpenDocument(ExtractFilePath(ParamStr(0)) + 'demo.xlsx');
end;

destructor TMainForm.Destroy;
begin
  fEdits.Free;
  fDocument.Free;
  inherited;
end;

function TMainForm.CurrentSheet: TSheet;
begin
  if (SheetTabs.TabIndex >= 0) and (SheetTabs.TabIndex < fDocument.Sheets.Count) then
    Result := fDocument.Sheets[SheetTabs.TabIndex]
  else
    Result := nil;
end;

procedure TMainForm.OpenDocument(const aFileName: string);
begin
  try
    fDocument.Load(aFileName);
  except
    on e: ESpreadsheetDocument do
    begin
      MessageDlg(e.Message, mtWarning, [mbOK], 0);
      Exit;
    end;
  end;
  fEdits.Clear;

  SheetTabs.Tabs.Clear;
  for var sheet: TSheet in fDocument.Sheets do
    SheetTabs.Tabs.Add(sheet.Name);
  SheetTabs.TabIndex := 0;

  var tables: string := '';
  for var table: TTableE in fDocument.Tables do
  begin
    var columns: TArray<string> := [];
    for var column: TCTTableColumnCT in table.TableColumns.TableColumn do
      columns := columns + [string(column.Name)];
    tables := tables + Format('%s (%s): %s%s.  ', [string(table.DisplayName), string(table.Ref), string.Join(', ', columns),
      IfThen(table.TotalsRowCount > 0, ' + a total row', '')]);
  end;
  TablesLabel.Caption := IfThen(tables = '', 'No tables', 'Tables: ' + tables);

  FileLabel.Caption := aFileName;
  SaveButton.Enabled := True;
  SaveAsButton.Enabled := True;
  ShowSheet;
end;

procedure TMainForm.ShowSheet;
begin
  var sheet: TSheet := CurrentSheet;
  if sheet = nil then
    Exit;

  // the grid as large as the sheet's cells, and a little more to type into
  var lastCol: integer := 4;
  var lastRow: integer := 19;
  for var row: TCTRowCT in sheet.Worksheet.SheetData.Row do
    for var cell: TCTCellCT in row.C do
    begin
      var col, rowIndex: integer;
      if ParseRef(cell.R, col, rowIndex) then
      begin
        lastCol := Max(lastCol, col + 2);
        lastRow := Max(lastRow, rowIndex + 5);
      end;
    end;
  CellsGrid.ColCount := lastCol + 2;
  CellsGrid.RowCount := lastRow + 2;

  for var col := 1 to CellsGrid.ColCount - 1 do
    CellsGrid.Cells[col, 0] := CellRef(col - 1, 0).TrimRight(['1']);
  for var row := 1 to CellsGrid.RowCount - 1 do
  begin
    CellsGrid.Cells[0, row] := IntToStr(row);
    for var col := 1 to CellsGrid.ColCount - 1 do
      CellsGrid.Cells[col, row] := fDocument.CellText(fDocument.Cell(sheet, CellRef(col - 1, row - 1)));
  end;
  CellLabel.Caption := '';
end;

procedure TMainForm.TakeEdits;
begin
  var sheet: TSheet := CurrentSheet;
  if sheet <> nil then
    for var i := 0 to fEdits.Count - 1 do
      fDocument.SetCellText(sheet, fEdits.Names[i], fEdits.ValueFromIndex[i]);
  fEdits.Clear;
end;

procedure TMainForm.SheetTabsChanging(Sender: TObject; var AllowChange: Boolean);
begin
  TakeEdits; // into the sheet they were made on
end;

procedure TMainForm.SheetTabsChange(Sender: TObject);
begin
  ShowSheet;
end;

procedure TMainForm.CellsGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  var sheet: TSheet := CurrentSheet;
  if (sheet = nil) or (ACol < 1) or (ARow < 1) then
    Exit;

  // a formula is shown, not edited: Excel recalculates its value
  var ref: string := CellRef(ACol - 1, ARow - 1);
  var cell: TCTCellCT := fDocument.Cell(sheet, ref);
  if (cell <> nil) and (cell.F.XmlValue <> '') then
  begin
    CellLabel.Caption := Format('%s  =%s', [ref, string(cell.F.XmlValue)]);
    CellsGrid.Options := CellsGrid.Options - [goEditing];
  end
  else
  begin
    CellLabel.Caption := ref;
    CellsGrid.Options := CellsGrid.Options + [goEditing];
  end;
end;

procedure TMainForm.CellsGridSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
begin
  fEdits.Values[CellRef(ACol - 1, ARow - 1)] := Value;
end;

procedure TMainForm.SaveDocument(const aFileName: string);
begin
  try
    TakeEdits;
    fDocument.Save(aFileName);
  except
    on e: ESpreadsheetDocument do
    begin
      MessageDlg(e.Message, mtWarning, [mbOK], 0);
      Exit;
    end;
  end;
  OpenDocument(aFileName); // what was written, read back
  CellLabel.Caption := 'Saved - Excel recalculates the formulas when it opens the file';
end;

procedure TMainForm.OpenButtonClick(Sender: TObject);
begin
  if OpenDialog.Execute then
    OpenDocument(OpenDialog.FileName);
end;

procedure TMainForm.SaveButtonClick(Sender: TObject);
begin
  SaveDocument(fDocument.FileName);
end;

procedure TMainForm.SaveAsButtonClick(Sender: TObject);
begin
  SaveDialog.FileName := ChangeFileExt(ExtractFileName(fDocument.FileName), '') + ' (copy).xlsx';
  SaveDialog.InitialDir := ExtractFilePath(fDocument.FileName);
  if SaveDialog.Execute then
    SaveDocument(SaveDialog.FileName);
end;

procedure TMainForm.WMDropFiles(var aMessage: TWMDropFiles);
var
  fileName: array [0 .. MAX_PATH] of Char;
begin
  try
    if DragQueryFile(aMessage.Drop, 0, fileName, MAX_PATH) > 0 then
      OpenDocument(fileName);
  finally
    DragFinish(aMessage.Drop);
  end;
end;

end.
