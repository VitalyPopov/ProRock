unit Form.Main;

// The core properties of an Office document - the ones File > Info shows - opened, edited and saved. All the document
// work is in OfficeDocument.pas; this form only shows the values and takes them back

interface

uses Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  OfficeDocument;

type
  TMainForm = class(TForm)
    ButtonsPanel: TPanel;
    OpenButton: TButton;
    SaveButton: TButton;
    SaveAsButton: TButton;
    FileLabel: TLabel;
    SignedLabel: TLabel;
    FieldsPanel: TPanel;
    TitlePanel: TPanel;
    TitleLabel: TLabel;
    TitleEdit: TEdit;
    SubjectPanel: TPanel;
    SubjectLabel: TLabel;
    SubjectEdit: TEdit;
    CreatorPanel: TPanel;
    CreatorLabel: TLabel;
    CreatorEdit: TEdit;
    KeywordsPanel: TPanel;
    KeywordsLabel: TLabel;
    KeywordsEdit: TEdit;
    DescriptionPanel: TPanel;
    DescriptionLabel: TLabel;
    DescriptionMemo: TMemo;
    CategoryPanel: TPanel;
    CategoryLabel: TLabel;
    CategoryEdit: TEdit;
    ContentStatusPanel: TPanel;
    ContentStatusLabel: TLabel;
    ContentStatusEdit: TEdit;
    LastModifiedByPanel: TPanel;
    LastModifiedByLabel: TLabel;
    LastModifiedByEdit: TEdit;
    RevisionPanel: TPanel;
    RevisionLabel: TLabel;
    RevisionEdit: TEdit;
    CreatedPanel: TPanel;
    CreatedLabel: TLabel;
    CreatedEdit: TEdit;
    ModifiedPanel: TPanel;
    ModifiedLabel: TLabel;
    ModifiedEdit: TEdit;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure OpenButtonClick(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
    procedure SaveAsButtonClick(Sender: TObject);
  private
    fDocument: TOfficeDocument;

    procedure WMDropFiles(var aMessage: TWMDropFiles); message WM_DROPFILES;

    procedure OpenDocument(const aFileName: string);
    procedure SaveDocument(const aFileName: string);
    procedure ShowProperties;
    procedure TakeProperties;
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
  fDocument := TOfficeDocument.Create;
  DragAcceptFiles(Handle, True);

  if ParamCount > 0 then
    OpenDocument(ParamStr(1));
end;

destructor TMainForm.Destroy;
begin
  fDocument.Free;
  inherited;
end;

procedure TMainForm.ShowProperties;
begin
  // the generated classes: Dublin Core elements carry their text in XmlValue (dc:title, dcterms:created), the elements of
  // the core properties namespace are plain strings (cp:category), cp:keywords is mixed content - its text is XmlText
  var properties := fDocument.Properties;
  TitleEdit.Text := properties.Title.XmlValue;
  SubjectEdit.Text := properties.Subject.XmlValue;
  CreatorEdit.Text := properties.Creator.XmlValue;
  KeywordsEdit.Text := properties.Keywords.XmlText;
  DescriptionMemo.Text := properties.Description.XmlValue;
  CategoryEdit.Text := properties.Category;
  ContentStatusEdit.Text := properties.ContentStatus;
  LastModifiedByEdit.Text := properties.LastModifiedBy;
  RevisionEdit.Text := properties.Revision;
  CreatedEdit.Text := properties.Created.XmlValue;
  ModifiedEdit.Text := properties.Modified.XmlValue;

  FileLabel.Caption := fDocument.FileName;
  SignedLabel.Visible := fDocument.Signed;
  FieldsPanel.Enabled := True;
  SaveButton.Enabled := True;
  SaveAsButton.Enabled := True;
end;

procedure TMainForm.TakeProperties;
begin
  // an empty value is not written: the element disappears from the document, as in Office
  var properties := fDocument.Properties;
  properties.Title.XmlValue := TitleEdit.Text;
  properties.Subject.XmlValue := SubjectEdit.Text;
  properties.Creator.XmlValue := CreatorEdit.Text;
  properties.Keywords.XmlText := KeywordsEdit.Text;
  properties.Description.XmlValue := DescriptionMemo.Text;
  properties.Category := CategoryEdit.Text;
  properties.ContentStatus := ContentStatusEdit.Text;
  properties.LastModifiedBy := LastModifiedByEdit.Text;
  properties.Revision := RevisionEdit.Text;
end;

procedure TMainForm.OpenDocument(const aFileName: string);
begin
  try
    fDocument.Load(aFileName);
  except
    on e: EOfficeDocument do
    begin
      MessageDlg(e.Message, mtWarning, [mbOK], 0);
      Exit;
    end;
  end;
  ShowProperties;
end;

procedure TMainForm.SaveDocument(const aFileName: string);
begin
  if fDocument.Signed and (MessageDlg('The document is digitally signed. Saving changes its properties and breaks the ' +
    'signature. Save anyway?', mtConfirmation, [mbYes, mbNo], 0, mbNo) <> mrYes) then
    Exit;

  TakeProperties;
  fDocument.Save(aFileName);
  ShowProperties; // Modified is the time of this save now
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
  var extension: string := ExtractFileExt(fDocument.FileName);
  SaveDialog.Filter := Format('The same kind (*%s)|*%s', [extension, extension]);
  SaveDialog.DefaultExt := extension.Substring(1);
  SaveDialog.FileName := ChangeFileExt(ExtractFileName(fDocument.FileName), '') + ' (copy)' + extension;
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
