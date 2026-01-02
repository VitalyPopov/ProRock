program ProRock.Xmlite.Basic;

uses
  Vcl.Forms,
  Form.Main in 'Form.Main.pas' {FormMain},
  MetaModel in 'MetaModel.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
