program ProRock.Xmlite.Namespaces;

uses
  Vcl.Forms,
  Form.Main in 'Form.Main.pas' {FormMain},
  ProRock.Xmlite.Schema.urndemoorder in 'ProRock.Xmlite.Schema.urndemoorder.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
