unit Form.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids, Vcl.Mask, Vcl.ExtCtrls;

type
  TFormMain = class(TForm)
    ParseButton: TButton;
    Label2: TLabel;
    StringGrid1: TStringGrid;
    Label4: TLabel;
    LabeledEdit1: TLabeledEdit;
    LabeledEdit2: TLabeledEdit;
    ComboBox1: TComboBox;
    SerializeButton: TButton;
    procedure ParseButtonClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SerializeButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

uses System.IOUtils, System.TypInfo, System.StrUtils, System.Math,
  ProRock.Xmlite, ProRock.Basite,
  ProRock.Xmlite.Schema.urndemoorder;

{$R *.dfm}

procedure TFormMain.FormShow(Sender: TObject);
begin
  LabeledEdit1.Text := '';
  for var status: TOrderStatusST := Low(TOrderStatusST) to High(TOrderStatusST) do
    ComboBox1.Items.Add(GetEnumName(TypeInfo(TOrderStatusST), ord(status)));
  ComboBox1.ItemIndex := 0;
  Label4.Caption := '';

  TBasite.Pretty := True;
end;

procedure TFormMain.ParseButtonClick(Sender: TObject);
begin
  var xml := TFile.ReadAllText('demo.xml', TEncoding.UTF8);
  var order := TOrderE.Create;
  try
    if not order.FromXml(xml) then
    begin
      LabeledEdit1.Text := 'Error parsing demo.xml';
      LabeledEdit2.Text := '';
      Label4.Caption := '';

      for var i := 0 to StringGrid1.RowCount - 1 do
        for var j := 0 to StringGrid1.ColCount - 1 do
          StringGrid1.Cells[j, i] := '';

      Exit;
    end;

    LabeledEdit1.Text := order.id;
    ComboBox1.ItemIndex := ord(order.status);
    LabeledEdit2.Text := order.customer.name;
    Label4.Caption := 'total: ' + FloatToStr(order.total.Amount);

    for var i := 0 to Min(order.items.item.Count, StringGrid1.RowCount) - 1 do
    begin
      StringGrid1.Cells[0, i] := order.items.item[i].title;
      StringGrid1.Cells[1, i] := IntToStr(order.items.item[i].quantity);
      StringGrid1.Cells[2, i] := FloatToStr(order.items.item[i].price);
    end;

    for var i := order.items.item.Count to StringGrid1.RowCount - 1 do
      for var j := 0 to StringGrid1.ColCount - 1 do
        StringGrid1.Cells[j, i] := '';
  finally
    order.Free;
  end;
end;

procedure TFormMain.SerializeButtonClick(Sender: TObject);
begin
  var order := TOrderE.Create;
  try
    order.id := LabeledEdit1.Text;
    order.status := TOrderStatusST(ComboBox1.ItemIndex);
    ComboBox1.ItemIndex := ord(order.status);
    order.customer.name := LabeledEdit2.Text;
    order.total.Amount := StrToFloatDef(StringReplace(Label4.Caption, 'total: ', '', []), 0);

    for var i := 0 to StringGrid1.RowCount - 1 do
      if not StringGrid1.Cells[0, i].Trim.IsEmpty then
      begin
        var item := TItemTypeCT.Create;
        item.title := StringGrid1.Cells[0, i];
        item.quantity := StrToIntDef(StringGrid1.Cells[1, i], 0);
        item.price := StrToFloatDef(StringGrid1.Cells[2, i], 0);
        order.items.item.Add(item);
      end;

    TFile.WriteAllText('order.xml', order.ToXml('order'), TEncoding.UTF8);
  finally
    order.Free;
  end;
end;

end.
