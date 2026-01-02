unit Form.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids;

type
  TFormMain = class(TForm)
    ParseButton: TButton;
    Label3: TLabel;
    Label2: TLabel;
    Label1: TLabel;
    StringGrid1: TStringGrid;
    Label4: TLabel;
    procedure ParseButtonClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

uses System.IOUtils, System.TypInfo,
  ProRock.Xmlite, ProRock.Utility,
  MetaModel;

{$R *.dfm}

procedure TFormMain.FormShow(Sender: TObject);
begin
  Label1.Caption := '';
  Label2.Caption := '';
  Label3.Caption := '';
  Label4.Caption := '';
  StringGrid1.RowCount := 0;
end;

procedure TFormMain.ParseButtonClick(Sender: TObject);
begin
  var xml := TFile.ReadAllText('demo.xml', TEncoding.UTF8);
  var order := TOrder.Create;
  try
    if not order.FromXml(xml) then
    begin
      Label1.Caption := 'Error parsing demo.xml';
      Label2.Caption := '';
      Label3.Caption := '';
      Label4.Caption := '';
      StringGrid1.RowCount := 0;

      Exit;
    end;

    Label1.Caption := 'id: ' + order.id;
    Label2.Caption := 'status: ' + GetEnumName(TypeInfo(TOrderStatus), ord(order.status));
    Label3.Caption := 'customer name: ' + order.customer.name;
    Label4.Caption := 'total: ' + order.total.ToString;

    StringGrid1.RowCount := order.items.item.Count;
    for var i := 0 to StringGrid1.RowCount - 1 do
    begin
      StringGrid1.Cells[0, i] := order.items.item[i].title;
      StringGrid1.Cells[1, i] := order.items.item[i].quantity.ToString;
      StringGrid1.Cells[2, i] := order.items.item[i].price.ToString;
    end;

  finally
    order.Free;
  end;
end;

end.
