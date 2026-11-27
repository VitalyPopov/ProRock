unit Form.Main;

// Calcite, a button at a time: each tab is one feature and writes its own sheet of one workbook; each button's handler is
// the code for one thing, as the docs show it. Save it or open it in Excel to see every sheet as Excel shows it

interface

uses Winapi.Windows, System.SysUtils, System.Classes, System.Variants, System.IOUtils, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Grids, Winapi.ShellAPI, Data.DB, Datasnap.DBClient,
  MidasLib, ProRock.Calcite, ProRock.Calcite.Data, SheetPreview;

type
  TMainForm = class(TForm)
    ToolPanel: TPanel;
    NewButton: TButton;
    OpenButton: TButton;
    SaveAsButton: TButton;
    ExcelButton: TButton;
    FileLabel: TLabel;
    Features: TPageControl;
    FilesTab: TTabSheet;
    CreateAndSaveButton: TButton;
    OpenAndReadButton: TButton;
    OpenEditSaveButton: TButton;
    FilePropertiesButton: TButton;
    ValuesTab: TTabSheet;
    WriteValuesButton: TButton;
    ReadValuesButton: TButton;
    CellsByNumberButton: TButton;
    BlockOfValuesButton: TButton;
    ClearValuesButton: TButton;
    FormulasTab: TTabSheet;
    WriteFormulasButton: TButton;
    ReadFormulasButton: TButton;
    ArrayFormulaButton: TButton;
    FormatsTab: TTabSheet;
    NumberFormatsButton: TButton;
    FontButton: TButton;
    FillButton: TButton;
    BordersButton: TButton;
    AlignmentButton: TButton;
    MergeButton: TButton;
    RowsTab: TTabSheet;
    FillListButton: TButton;
    InsertRowsButton: TButton;
    DeleteRowsButton: TButton;
    InsertColumnButton: TButton;
    HideColumnButton: TButton;
    SizesButton: TButton;
    AutoFitButton: TButton;
    FreezeButton: TButton;
    SheetsTab: TTabSheet;
    AddSheetButton: TButton;
    ListSheetsButton: TButton;
    HideSheetButton: TButton;
    DeleteSheetButton: TButton;
    DataSetTab: TTabSheet;
    ExportDataSetButton: TButton;
    IssuesTab: TTabSheet;
    RefusedWriteButton: TButton;
    IssuesAsTheyComeButton: TButton;
    FailedOpenButton: TButton;
    RefusedInsertButton: TButton;
    XlsxTab: TTabSheet;
    TabColorButton: TButton;
    SheetTabs: TTabControl;
    CellsGrid: TStringGrid;
    CellLabel: TLabel;
    LogMemo: TMemo;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure NewButtonClick(Sender: TObject);
    procedure OpenButtonClick(Sender: TObject);
    procedure SaveAsButtonClick(Sender: TObject);
    procedure ExcelButtonClick(Sender: TObject);
    procedure FeaturesChange(Sender: TObject);
    procedure SheetTabsChange(Sender: TObject);
    procedure CellsGridSelectCell(Sender: TObject; aCol, aRow: integer; var aCanSelect: boolean);
    procedure CreateAndSaveButtonClick(Sender: TObject);
    procedure OpenAndReadButtonClick(Sender: TObject);
    procedure OpenEditSaveButtonClick(Sender: TObject);
    procedure FilePropertiesButtonClick(Sender: TObject);
    procedure WriteValuesButtonClick(Sender: TObject);
    procedure ReadValuesButtonClick(Sender: TObject);
    procedure CellsByNumberButtonClick(Sender: TObject);
    procedure BlockOfValuesButtonClick(Sender: TObject);
    procedure ClearValuesButtonClick(Sender: TObject);
    procedure WriteFormulasButtonClick(Sender: TObject);
    procedure ReadFormulasButtonClick(Sender: TObject);
    procedure ArrayFormulaButtonClick(Sender: TObject);
    procedure NumberFormatsButtonClick(Sender: TObject);
    procedure FontButtonClick(Sender: TObject);
    procedure FillButtonClick(Sender: TObject);
    procedure BordersButtonClick(Sender: TObject);
    procedure AlignmentButtonClick(Sender: TObject);
    procedure MergeButtonClick(Sender: TObject);
    procedure FillListButtonClick(Sender: TObject);
    procedure InsertRowsButtonClick(Sender: TObject);
    procedure DeleteRowsButtonClick(Sender: TObject);
    procedure InsertColumnButtonClick(Sender: TObject);
    procedure HideColumnButtonClick(Sender: TObject);
    procedure SizesButtonClick(Sender: TObject);
    procedure AutoFitButtonClick(Sender: TObject);
    procedure FreezeButtonClick(Sender: TObject);
    procedure AddSheetButtonClick(Sender: TObject);
    procedure ListSheetsButtonClick(Sender: TObject);
    procedure HideSheetButtonClick(Sender: TObject);
    procedure DeleteSheetButtonClick(Sender: TObject);
    procedure ExportDataSetButtonClick(Sender: TObject);
    procedure RefusedWriteButtonClick(Sender: TObject);
    procedure IssuesAsTheyComeButtonClick(Sender: TObject);
    procedure FailedOpenButtonClick(Sender: TObject);
    procedure RefusedInsertButtonClick(Sender: TObject);
    procedure TabColorButtonClick(Sender: TObject);
  private
    fWorkbook: TWorkbook;
    fOrders: TClientDataSet;
    fPreview: TSheetPreview;
    fFolder: string;

    // the sample's own: the feature's sheet of the workbook, added when it has none; aEmpty: its rows deleted first
    function FeatureSheet(const aName: string; aEmpty: boolean = False): TWorksheet;
    procedure Preview(aSheet: TWorksheet);
    procedure ShowWorkbook;
    procedure Log(const aText: string);
    function CreateOrders: TClientDataSet;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  fFolder := ExtractFilePath(ParamStr(0));
  fWorkbook := TWorkbook.Create;
  fOrders := CreateOrders;
  fPreview := TSheetPreview.Create(CellsGrid);
  ShowWorkbook;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  fPreview.Free;
  fOrders.Free;
  fWorkbook.Free;
end;

function TMainForm.FeatureSheet(const aName: string; aEmpty: boolean): TWorksheet;
begin
  Result := fWorkbook.Worksheets.Find(aName);
  if Result = nil then
  begin
    Result := fWorkbook.Worksheets[1];
    if (fWorkbook.FileName <> '') or (fWorkbook.Worksheets.Count > 1) or (Result.UsedRange.Address <> 'A1')
      or (Result['A1'].ValueType <> cvEmpty) then
      Result := fWorkbook.Worksheets.Add(aName)
    else
      Result.Name := aName; // a new workbook's empty Sheet1 becomes the first feature's
  end
  else if aEmpty and ((Result.UsedRange.Address <> 'A1') or (Result['A1'].ValueType <> cvEmpty)) then
    Result.UsedRange.EntireRow.Delete;
end;

procedure TMainForm.Preview(aSheet: TWorksheet);
begin
  SheetTabs.Tabs.BeginUpdate;
  try
    SheetTabs.Tabs.Clear;
    for var sheet in fWorkbook.Worksheets do
      SheetTabs.Tabs.Add(sheet.Name);
  finally
    SheetTabs.Tabs.EndUpdate;
  end;
  if aSheet.Workbook = fWorkbook then
    SheetTabs.TabIndex := SheetTabs.Tabs.IndexOf(aSheet.Name)
  else
    SheetTabs.TabIndex := -1; // a workbook of its own, freed after the button
  fPreview.Show(aSheet);
  CellLabel.Caption := fPreview.CellInfo(1, 1);
end;

procedure TMainForm.ShowWorkbook;
begin
  if fWorkbook.FileName = '' then
    FileLabel.Caption := 'A new workbook'
  else
    FileLabel.Caption := fWorkbook.FileName;
  Preview(fWorkbook.Worksheets[1]);
end;

procedure TMainForm.Log(const aText: string);
begin
  LogMemo.Lines.Add(aText);
end;

function TMainForm.CreateOrders: TClientDataSet;
begin
  Result := TClientDataSet.Create(nil);
  Result.FieldDefs.Add('Order', ftInteger);
  Result.FieldDefs.Add('Customer', ftString, 30);
  Result.FieldDefs.Add('Date', ftDate);
  Result.FieldDefs.Add('Amount', ftCurrency);
  Result.FieldDefs.Add('Paid', ftBoolean);
  Result.CreateDataSet;
  Result.AppendRecord([1001, 'Northwind Traders', EncodeDate(2026, 11, 2), 1250.5, True]);
  Result.AppendRecord([1002, 'Contoso Ltd', EncodeDate(2026, 11, 9), 320, False]);
  Result.AppendRecord([1003, 'Fabrikam Inc', EncodeDate(2026, 11, 16), 4100.75, True]);
  Result.AppendRecord([1004, 'Adventure Works', EncodeDate(2026, 11, 23), 89.9, False]);
  Result.First;
end;

// the toolbar: the sample's workbook

procedure TMainForm.NewButtonClick(Sender: TObject);
begin
  var onIssue := fWorkbook.OnIssue;
  fWorkbook.Free;
  fWorkbook := TWorkbook.Create;
  fWorkbook.OnIssue := onIssue;
  ShowWorkbook;
end;

procedure TMainForm.OpenButtonClick(Sender: TObject);
begin
  if not OpenDialog.Execute then
    Exit;
  if fWorkbook.Open(OpenDialog.FileName) then
    ShowWorkbook
  else
    Log(fWorkbook.Error);
end;

procedure TMainForm.SaveAsButtonClick(Sender: TObject);
begin
  if not SaveDialog.Execute then
    Exit;
  if fWorkbook.SaveAs(SaveDialog.FileName) then
    ShowWorkbook
  else
    Log(fWorkbook.Error);
end;

procedure TMainForm.ExcelButtonClick(Sender: TObject);
begin
  // a copy next to the program: a file opened here is never overwritten
  if not fWorkbook.SaveAs(fFolder + 'Calcite sample.xlsx') then
    Log(fWorkbook.Error) // Excel keeps a file it shows locked: close it there first
  else
  begin
    ShowWorkbook;
    ShellExecute(Handle, 'open', PChar(fWorkbook.FileName), nil, nil, SW_SHOWNORMAL);
  end;
end;

procedure TMainForm.FeaturesChange(Sender: TObject);
begin
  var sheet := fWorkbook.Worksheets.Find(Features.ActivePage.Caption);
  if sheet <> nil then
    Preview(sheet);
end;

procedure TMainForm.SheetTabsChange(Sender: TObject);
begin
  Preview(fWorkbook.Worksheets[SheetTabs.TabIndex + 1]);
end;

procedure TMainForm.CellsGridSelectCell(Sender: TObject; aCol, aRow: integer; var aCanSelect: boolean);
begin
  CellLabel.Caption := fPreview.CellInfo(aCol, aRow);
end;

// Files: a workbook of its own in each button

procedure TMainForm.CreateAndSaveButtonClick(Sender: TObject);
begin
  var workbook := TWorkbook.Create;
  try
    var sheet := workbook.Worksheets[1];
    sheet.Name := 'Prices';
    sheet['A1'].Value := 'Item';
    sheet['B1'].Value := 'Price';
    sheet['A2'].Value := 'Coffee';
    sheet['B2'].Value := 2.5;
    sheet['A3'].Value := 'Tea';
    sheet['B3'].Value := 1.8;
    if workbook.SaveAs(fFolder + 'Prices.xlsx') then
      Log('Saved ' + workbook.FileName)
    else
      Log(workbook.Error);
    Preview(sheet);
  finally
    workbook.Free;
  end;
end;

procedure TMainForm.OpenAndReadButtonClick(Sender: TObject);
begin
  var workbook := TWorkbook.Create;
  try
    if not workbook.Open(fFolder + 'Prices.xlsx') then
    begin
      Log(workbook.Error); // the file is not there: Create and save first
      Exit;
    end;
    var sheet := workbook.Worksheets['Prices'];
    for var row := 2 to sheet.UsedRange.LastRow do
      Log(sheet.Cells[row, 'A'].AsString + ': ' + FloatToStr(sheet.Cells[row, 'B'].AsFloat));
    Preview(sheet);
  finally
    workbook.Free;
  end;
end;

procedure TMainForm.OpenEditSaveButtonClick(Sender: TObject);
begin
  var workbook := TWorkbook.Create;
  try
    if not workbook.Open(fFolder + 'Prices.xlsx') then
    begin
      Log(workbook.Error);
      Exit;
    end;
    var sheet := workbook.Worksheets[1];
    sheet['B2'].Value := sheet['B2'].AsFloat + 0.1; // what is not changed is saved as it was
    if workbook.Save then
      Log('Coffee costs ' + FloatToStr(sheet['B2'].AsFloat) + ' now')
    else
      Log(workbook.Error);
    Preview(sheet);
  finally
    workbook.Free;
  end;
end;

procedure TMainForm.FilePropertiesButtonClick(Sender: TObject);
begin
  var workbook := TWorkbook.Create;
  try
    if not workbook.Open(fFolder + 'Prices.xlsx') then
    begin
      Log(workbook.Error);
      Exit;
    end;
    workbook.Properties.Title := 'Price list';
    workbook.Properties.Creator := 'The ProRock sample';
    if workbook.Save then
      Log('Title: ' + workbook.Properties.Title + ', modified ' + DateTimeToStr(workbook.Properties.Modified) + ' UTC')
    else
      Log(workbook.Error);
  finally
    workbook.Free;
  end;
end;

// Values

procedure TMainForm.WriteValuesButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Values');
  sheet['A1'].Value := 'Text';
  sheet['B1'].Value := 'Calcite';
  sheet['A2'].Value := 'Number';
  sheet['B2'].Value := 1250.5;
  sheet['A3'].Value := 'Date';
  sheet['B3'].Value := Date; // a date gets a date format, as in Excel
  sheet['A4'].Value := 'Date and time';
  sheet['B4'].Value := Now;
  sheet['A5'].Value := 'Boolean';
  sheet['B5'].Value := True;
  sheet['A6'].Value := 'Text, not a number';
  sheet['B6'].Value := '00123'; // text stays text
  Preview(sheet);
end;

procedure TMainForm.ReadValuesButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Values');
  for var row := 1 to sheet.UsedRange.LastRow do
    Log(sheet.Cells[row, 'A'].AsString + ' = ' + sheet.Cells[row, 'B'].AsString);
  if sheet['B3'].ValueType = cvDate then
    Log('B3 is a date: ' + DateToStr(sheet['B3'].AsDateTime));
  Preview(sheet);
end;

procedure TMainForm.CellsByNumberButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Values');
  for var row := 1 to 5 do
    for var column := 1 to 5 do
      sheet.Cells[row, column + 3].Value := row * column; // D1:H5, rows and columns from 1
  Preview(sheet);
end;

procedure TMainForm.BlockOfValuesButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Values');
  var values := VarArrayCreate([1, 3, 1, 2], varVariant); // [row, column]
  values[1, 1] := 'North';
  values[1, 2] := 120;
  values[2, 1] := 'South';
  values[2, 2] := 95;
  values[3, 1] := 'West';
  values[3, 2] := 210;
  sheet['J1:K3'].Value := values;
  var block := sheet['J1:K3'].Value; // read the same way
  Log('J3 holds ' + VarToStr(block[3, 1]));
  Preview(sheet);
end;

procedure TMainForm.ClearValuesButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Values');
  sheet['D1:H5'].ClearContents; // formats stay, as in Excel
  Preview(sheet);
end;

// Formulas

procedure TMainForm.WriteFormulasButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Formulas');
  sheet['A1'].Value := 10;
  sheet['A2'].Value := 20;
  sheet['A3'].Value := 30;
  sheet['A4'].Formula := '=SUM(A1:A3)';
  sheet['B1'].Formula := '=A1*2';
  sheet['C1'].Formula := '=IF(A4>50,"big","small")'; // English names and commas, as Excel's Formula
  Log('Excel calculates the formulas when it opens the file');
  Preview(sheet);
end;

procedure TMainForm.ReadFormulasButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Formulas');
  if sheet['A4'].HasFormula then
    Log('A4: ' + sheet['A4'].Formula);
  Preview(sheet);
end;

procedure TMainForm.ArrayFormulaButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Formulas');
  sheet['E1:E3'].FormulaArray := '=A1:A3*10'; // one formula over the three cells
  Log('E2 is in the array ' + sheet['E2'].CurrentArray.Address);
  Preview(sheet);
end;

// Formats

procedure TMainForm.NumberFormatsButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Formats');
  sheet['A1'].Value := 1234.5;
  sheet['A1'].NumberFormat := '#,##0.00';
  sheet['A2'].Value := 0.25;
  sheet['A2'].NumberFormat := '0%';
  sheet['A3'].Value := Date;
  sheet['A3'].NumberFormat := 'dd.mm.yyyy';
  sheet['A4'].NumberFormat := '@'; // text: Excel takes what is typed there as it is
  sheet['A4'].Value := '2026-11-27';
  Preview(sheet);
end;

procedure TMainForm.FontButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Formats');
  sheet['C1'].Value := 'Bold';
  sheet['C1'].Font.Bold := True;
  sheet['C2'].Value := 'Italic red';
  sheet['C2'].Font.Style := [fsItalic];
  sheet['C2'].Font.Color := clRed;
  sheet['C3'].Value := 'Consolas 14';
  sheet['C3'].Font.Name := 'Consolas';
  sheet['C3'].Font.Size := 14;
  Preview(sheet);
end;

procedure TMainForm.FillButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Formats');
  sheet['E1:E3'].Interior.Color := clYellow;
  sheet['E2'].Interior.Color := RGB(198, 239, 206); // TColor, as Excel's Color
  Preview(sheet);
end;

procedure TMainForm.BordersButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Formats');
  sheet['A6:E8'].Borders.LineStyle := lsContinuous; // every edge, the inside ones too
  sheet['A6:E8'].BorderAround(lsContinuous, bwMedium);
  sheet['A6:E6'].Borders[beBottom].LineStyle := lsDouble;
  Preview(sheet);
end;

procedure TMainForm.AlignmentButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Formats');
  sheet['G1'].Value := 'Centered';
  sheet['G1'].HorizontalAlignment := haCenter;
  sheet['G2'].Value := 'A long text wrapped in its cell';
  sheet['G2'].WrapText := True;
  sheet['G2'].VerticalAlignment := vaTop;
  Preview(sheet);
end;

procedure TMainForm.MergeButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Formats');
  sheet['A10'].Value := 'A title over five columns';
  sheet['A10:E10'].Merge;
  sheet['A10'].HorizontalAlignment := haCenter;
  Log('C10 is in the merged area ' + sheet['C10'].MergeArea.Address);
  Preview(sheet);
end;

// Rows and columns

procedure TMainForm.FillListButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Rows and columns', True);
  sheet['A1:D1'].Value := VarArrayOf(['Item', 'Quantity', 'Price', 'Amount']);
  sheet['A1:D1'].Font.Bold := True;
  for var row := 2 to 6 do
  begin
    sheet.Cells[row, 'A'].Value := 'Item ' + IntToStr(row - 1);
    sheet.Cells[row, 'B'].Value := row;
    sheet.Cells[row, 'C'].Value := 1.5 * row;
    sheet.Cells[row, 'D'].Formula := Format('=B%d*C%d', [row, row]);
  end;
  sheet['A7'].Value := 'Total';
  sheet['D7'].Formula := '=SUM(D2:D6)';
  Preview(sheet);
end;

procedure TMainForm.InsertRowsButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Rows and columns');
  sheet.Rows['3:4'].Insert; // formulas follow, as in Excel: the total's SUM grows
  var total := sheet.Cells[sheet.UsedRange.LastRow, sheet.UsedRange.LastColumn];
  Log('The total in ' + total.Address + ': ' + total.Formula);
  Preview(sheet);
end;

procedure TMainForm.DeleteRowsButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Rows and columns');
  sheet.Rows['3:4'].Delete;
  var total := sheet.Cells[sheet.UsedRange.LastRow, sheet.UsedRange.LastColumn];
  Log('The total in ' + total.Address + ': ' + total.Formula);
  Preview(sheet);
end;

procedure TMainForm.InsertColumnButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Rows and columns');
  sheet.Columns['B'].Insert;
  sheet['B1'].Value := 'Inserted';
  var amount := sheet.Cells[2, sheet.UsedRange.LastColumn]; // the formulas moved right with their cells
  Log(amount.Address + ': ' + amount.Formula);
  Preview(sheet);
end;

procedure TMainForm.HideColumnButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Rows and columns');
  sheet.Columns['C'].Hidden := not sheet.Columns['C'].Hidden;
  Preview(sheet);
end;

procedure TMainForm.SizesButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Rows and columns');
  sheet.Columns['A'].ColumnWidth := 20; // characters
  sheet.Rows[1].RowHeight := 24; // points
  Preview(sheet);
end;

procedure TMainForm.AutoFitButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Rows and columns');
  sheet.UsedRange.Columns.AutoFit;
  Preview(sheet);
end;

procedure TMainForm.FreezeButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Rows and columns');
  sheet.FreezePanes := 'A2'; // the first row stays put
  Log('Frozen above and left of ' + sheet.FreezePanes);
  Preview(sheet);
end;

// Sheets

procedure TMainForm.AddSheetButtonClick(Sender: TObject);
begin
  var sheet := fWorkbook.Worksheets.Add; // Excel's next name: Sheet2, Sheet3...
  sheet['A1'].Value := 'Added as ' + sheet.Name;
  Preview(sheet);
end;

procedure TMainForm.ListSheetsButtonClick(Sender: TObject);
begin
  for var sheet in fWorkbook.Worksheets do
    if sheet.Visible = svVisible then
      Log(sheet.Name)
    else
      Log(sheet.Name + ' (hidden)');
end;

procedure TMainForm.HideSheetButtonClick(Sender: TObject);
begin
  var sheet := fWorkbook.Worksheets[fWorkbook.Worksheets.Count];
  try
    sheet.Visible := svHidden;
    Log(sheet.Name + ' hidden');
  except
    on E: EInvalidOpException do
      Log(E.Message); // the last visible sheet stays, as in Excel
  end;
end;

procedure TMainForm.DeleteSheetButtonClick(Sender: TObject);
begin
  var sheet := fWorkbook.Worksheets[fWorkbook.Worksheets.Count];
  var deleted := sheet.Name;
  try
    sheet.Delete; // formulas naming it become #REF!, as in Excel
    Log(deleted + ' deleted');
  except
    on E: EInvalidOpException do
      Log(E.Message); // the last visible sheet stays, as in Excel
  end;
  Preview(fWorkbook.Worksheets[1]);
end;

// DataSet

procedure TMainForm.ExportDataSetButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('DataSet', True);
  var exported := ExportDataSet(fOrders, sheet); // a bold header, a row a record, the columns fitted, the header frozen
  Log('Exported to ' + exported.Address);
  Preview(sheet);
end;

// Issues

procedure TMainForm.RefusedWriteButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Issues');
  sheet['A1'].Formula := '=SUM(B1:B3'; // Excel refuses it: the cell keeps its value, an issue tells why
  Log(fWorkbook.Issues[fWorkbook.Issues.Count - 1].ToString); // Issues: every one since Open, the newest last
  Preview(sheet);
end;

procedure TMainForm.IssuesAsTheyComeButtonClick(Sender: TObject);
begin
  fWorkbook.OnIssue :=
    procedure(const aIssue: TIssue)
    begin
      Log('As it comes: ' + aIssue.ToString);
    end;
  Log('Issues are logged as they come now');
end;

procedure TMainForm.FailedOpenButtonClick(Sender: TObject);
begin
  var workbook := TWorkbook.Create;
  try
    if not workbook.Open(fFolder + 'No such file.xlsx') then
      Log(workbook.Error); // Open and Save answer False and Error, never raise for a file's trouble
  finally
    workbook.Free;
  end;
end;

procedure TMainForm.RefusedInsertButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Issues');
  sheet['XFD1'].Value := 'The last column';
  try
    sheet.Columns['B'].Insert; // would push XFD1 off the sheet
  except
    on E: EInvalidOpException do
      Log('Refused, nothing changed: ' + E.Message);
  end;
  Preview(sheet);
end;

// Xlsx objects: the file's own classes, for what Calcite does not cover yet (at your own risk: the file may break)

procedure TMainForm.TabColorButtonClick(Sender: TObject);
begin
  var sheet := FeatureSheet('Xlsx objects');
  sheet['A1'].Value := 'This sheet''s tab is red';
  sheet.Xlsx.Worksheet.SheetPr.TabColor.Rgb := 'FFC00000'; // ARGB
  Preview(sheet);
end;

end.
