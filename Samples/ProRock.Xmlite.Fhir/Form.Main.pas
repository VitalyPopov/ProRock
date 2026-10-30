unit Form.Main;

// A FHIR document - a Bundle or one resource - listed: each resource's type, id, what it is, its value and when; the
// selected one's narrative as text. Save as writes it back; Speed test reads a large Bundle made of the same entries. All
// the FHIR work is in FhirDocument.pas; this form only shows it

interface

uses Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  FhirDocument;

type
  TMainForm = class(TForm)
    ButtonsPanel: TPanel;
    OpenButton: TButton;
    SaveAsButton: TButton;
    SpeedButton: TButton;
    FileLabel: TLabel;
    StatusLabel: TLabel;
    EntriesView: TListView;
    Splitter: TSplitter;
    NarrativeMemo: TMemo;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure OpenButtonClick(Sender: TObject);
    procedure SaveAsButtonClick(Sender: TObject);
    procedure SpeedButtonClick(Sender: TObject);
    procedure EntriesViewSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
  private
    fDocument: TFhirDocument;
    fFileName: string;

    procedure WMDropFiles(var aMessage: TWMDropFiles); message WM_DROPFILES;

    procedure OpenDocument(const aFileName: string);
    procedure ShowEntries;
  public
    destructor Destroy; override;
  end;

var
  MainForm: TMainForm;

implementation

uses System.UITypes, Winapi.ShellAPI;

{$R *.dfm}

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  fDocument := TFhirDocument.Create;
  DragAcceptFiles(Handle, True);

  // the sample's Bundle (the Patient and Observation examples of the specification), unless a file is given
  if ParamCount > 0 then
    OpenDocument(ParamStr(1))
  else if FileExists(ExtractFilePath(ParamStr(0)) + 'bundle.xml') then
    OpenDocument(ExtractFilePath(ParamStr(0)) + 'bundle.xml');
end;

destructor TMainForm.Destroy;
begin
  fDocument.Free;
  inherited;
end;

procedure TMainForm.OpenDocument(const aFileName: string);
begin
  try
    fDocument.Load(aFileName);
  except
    on e: EFhirDocument do
    begin
      MessageDlg(e.Message, mtWarning, [mbOK], 0);
      Exit;
    end;
  end;
  fFileName := aFileName;
  ShowEntries;
end;

procedure TMainForm.ShowEntries;
begin
  EntriesView.Items.BeginUpdate;
  try
    EntriesView.Clear;
    for var i := 0 to fDocument.Entries.Count - 1 do
    begin
      var entry: TFhirEntry := fDocument.Entries[i];
      var item: TListItem := EntriesView.Items.Add;
      item.Caption := entry.ResourceType;
      item.SubItems.Add(entry.Id);
      item.SubItems.Add(entry.What);
      item.SubItems.Add(entry.Value);
      item.SubItems.Add(entry.When);
      item.Data := Pointer(i);
    end;
  finally
    EntriesView.Items.EndUpdate;
  end;

  FileLabel.Caption := fFileName;
  StatusLabel.Caption := Format('%d resource(s) read in %.1f ms', [fDocument.Entries.Count, fDocument.ReadMs]);
  NarrativeMemo.Clear;
  SaveAsButton.Enabled := True;
  SpeedButton.Enabled := fDocument.Entries.Count > 0;
  if EntriesView.Items.Count > 0 then
    EntriesView.Items[0].Selected := True;
end;

procedure TMainForm.EntriesViewSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if Selected then
    NarrativeMemo.Text := fDocument.Narrative(fDocument.Entries[NativeInt(Item.Data)].Resource);
end;

procedure TMainForm.OpenButtonClick(Sender: TObject);
begin
  if OpenDialog.Execute then
    OpenDocument(OpenDialog.FileName);
end;

procedure TMainForm.SaveAsButtonClick(Sender: TObject);
begin
  SaveDialog.FileName := ChangeFileExt(ExtractFileName(fFileName), '') + ' (copy).xml';
  SaveDialog.InitialDir := ExtractFilePath(fFileName);
  if SaveDialog.Execute then
    fDocument.Save(SaveDialog.FileName);
end;

procedure TMainForm.SpeedButtonClick(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  try
    StatusLabel.Caption := fDocument.SpeedTest(1000);
  finally
    Screen.Cursor := crDefault;
  end;
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
