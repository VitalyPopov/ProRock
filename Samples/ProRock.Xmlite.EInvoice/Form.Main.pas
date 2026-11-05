unit Form.Main;

// An electronic invoice shown: who, how much, the lines, the VAT, the totals - the same window for CII and UBL. Save as writes
// the file back. All the invoice work is in InvoiceDocument.pas, InvoiceCii.pas and InvoiceUbl.pas; this form only shows it

interface

uses Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  InvoiceDocument;

type
  TMainForm = class(TForm)
    ButtonsPanel: TPanel;
    OpenButton: TButton;
    SaveAsButton: TButton;
    CiiButton: TButton;
    UblButton: TButton;
    FileLabel: TLabel;
    StatusLabel: TLabel;
    HeaderMemo: TMemo;
    LinesView: TListView;
    BottomPanel: TPanel;
    VatView: TListView;
    TotalsView: TListView;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure OpenButtonClick(Sender: TObject);
    procedure SaveAsButtonClick(Sender: TObject);
    procedure CiiButtonClick(Sender: TObject);
    procedure UblButtonClick(Sender: TObject);
  private
    fDocument: TInvoiceDocument;
    fFileName: string;

    procedure WMDropFiles(var aMessage: TWMDropFiles); message WM_DROPFILES;

    procedure OpenDocument(const aFileName: string);
    procedure OpenExample(const aName: string);
    procedure ShowInvoice;
  public
    destructor Destroy; override;
  end;

var
  MainForm: TMainForm;

implementation

uses System.UITypes, Winapi.ShellAPI;

{$R *.dfm}

function Money(aValue: Double): string;
begin
  Result := FormatFloat('#,##0.00', aValue);
end;

function PartyText(const aParty: TInvoiceParty): string;
begin
  Result := JoinAddress([aParty.Name, aParty.Address]);
  if aParty.VatId <> '' then
    Result := Result + ', VAT ' + aParty.VatId;
end;

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  fDocument := TInvoiceDocument.Create;
  DragAcceptFiles(Handle, True);

  // the sample's invoice, unless a file is given
  if ParamCount > 0 then
    OpenDocument(ParamStr(1))
  else
    OpenExample('invoice-cii.xml');
end;

destructor TMainForm.Destroy;
begin
  fDocument.Free;
  inherited;
end;

procedure TMainForm.OpenExample(const aName: string);
begin
  var fileName: string := ExtractFilePath(ParamStr(0)) + aName;
  if FileExists(fileName) then
    OpenDocument(fileName);
end;

procedure TMainForm.OpenDocument(const aFileName: string);
begin
  try
    fDocument.Load(aFileName);
  except
    on e: EInvoiceDocument do
    begin
      MessageDlg(e.Message, mtWarning, [mbOK], 0);
      Exit;
    end;
  end;
  fFileName := aFileName;
  ShowInvoice;
end;

procedure TMainForm.ShowInvoice;

  procedure AddRow(aView: TListView; const aCaption: string; const aValues: array of string);
  begin
    var item: TListItem := aView.Items.Add;
    item.Caption := aCaption;
    for var value in aValues do
      item.SubItems.Add(value);
  end;

begin
  var invoice: TInvoice := fDocument.Invoice;

  FileLabel.Caption := fFileName;
  StatusLabel.Caption := Format('%s, %d line(s), read in %.1f ms', [invoice.Syntax, invoice.Lines.Count, fDocument.ReadMs]);
  SaveAsButton.Enabled := True;

  HeaderMemo.Lines.BeginUpdate;
  try
    HeaderMemo.Clear;
    HeaderMemo.Lines.Add(Format('%s %s, issued %s, in %s', [invoice.Kind, invoice.Number, invoice.IssueDate, invoice.Currency]));
    HeaderMemo.Lines.Add('Seller: ' + PartyText(invoice.Seller));
    HeaderMemo.Lines.Add('Buyer: ' + PartyText(invoice.Buyer));
    if invoice.Iban <> '' then
      HeaderMemo.Lines.Add('Pay to: ' + invoice.Iban);
    if invoice.DueDate <> '' then
      HeaderMemo.Lines.Add('Due: ' + invoice.DueDate);
    if invoice.PaymentTerms <> '' then
      HeaderMemo.Lines.Add(invoice.PaymentTerms);
  finally
    HeaderMemo.Lines.EndUpdate;
  end;

  LinesView.Items.BeginUpdate;
  try
    LinesView.Clear;
    for var line in invoice.Lines do
      AddRow(LinesView, line.Id, [line.Name, FormatFloat('#,##0.###', line.Quantity), line.UnitCode, FormatFloat('#,##0.00##', line.Price),
        FormatFloat('0.##', line.VatRate) + ' %', Money(line.Amount)]);
  finally
    LinesView.Items.EndUpdate;
  end;

  VatView.Items.BeginUpdate;
  try
    VatView.Clear;
    for var vat in invoice.Vat do
      AddRow(VatView, vat.Category, [FormatFloat('0.##', vat.Rate) + ' %', Money(vat.Basis), Money(vat.Amount)]);
  finally
    VatView.Items.EndUpdate;
  end;

  TotalsView.Items.BeginUpdate;
  try
    TotalsView.Clear;
    AddRow(TotalsView, 'Lines', [Money(invoice.LineTotal)]);
    AddRow(TotalsView, 'Without VAT', [Money(invoice.TaxBasisTotal)]);
    AddRow(TotalsView, 'VAT', [Money(invoice.TaxTotal)]);
    AddRow(TotalsView, 'With VAT', [Money(invoice.GrandTotal)]);
    AddRow(TotalsView, 'Due', [Money(invoice.DuePayable)]);
  finally
    TotalsView.Items.EndUpdate;
  end;
end;

procedure TMainForm.OpenButtonClick(Sender: TObject);
begin
  if OpenDialog.Execute then
    OpenDocument(OpenDialog.FileName);
end;

procedure TMainForm.CiiButtonClick(Sender: TObject);
begin
  OpenExample('invoice-cii.xml');
end;

procedure TMainForm.UblButtonClick(Sender: TObject);
begin
  OpenExample('invoice-ubl.xml');
end;

procedure TMainForm.SaveAsButtonClick(Sender: TObject);
begin
  SaveDialog.FileName := ChangeFileExt(ExtractFileName(fFileName), '') + ' (copy).xml';
  SaveDialog.InitialDir := ExtractFilePath(fFileName);
  if SaveDialog.Execute then
    fDocument.Save(SaveDialog.FileName);
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
