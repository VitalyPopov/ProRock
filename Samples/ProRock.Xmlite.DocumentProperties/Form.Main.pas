unit Form.Main;

// The core properties of an Office document - the ones File > Info shows - opened, edited and saved, and what the
// application says about its contents (the sheets of a workbook), shown. All the document work is in OfficeDocument.pas;
// this form only shows the values and takes them back

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
    ApplicationPanel: TPanel;
    ApplicationLabel: TLabel;
    ApplicationEdit: TEdit;
    PartsPanel: TPanel;
    PartsLabel: TLabel;
    PartsMemo: TMemo;
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
    procedure ShowContents;
    procedure TakeProperties;
  public
    destructor Destroy; override;
  end;

var
  MainForm: TMainForm;

implementation

uses System.UITypes, System.Math, Winapi.ShellAPI, ProRock.Xmlite.Schema.CoreProperties, ProRock.Xmlite.Schema.Ooxml.PropVar;

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
  ShowContents;

  FileLabel.Caption := fDocument.FileName;
  SignedLabel.Visible := fDocument.Signed;
  FieldsPanel.Enabled := True;
  SaveButton.Enabled := True;
  SaveAsButton.Enabled := True;
end;

procedure TMainForm.ShowContents;
begin
  // docProps/app.xml: the titles of the parts are a list of plain strings (a vt:vector of vt:lpstr), grouped by the heading
  // pairs - a name and a count each (vt:variant holding a vt:lpstr, then one holding a vt:i4): "Worksheets: Sales, Costs"
  var extended := fDocument.ExtendedProperties;
  ApplicationEdit.Text := extended.Application;

  var titles := extended.TitlesOfParts.Vector.Lpstr;
  var pairs := extended.HeadingPairs.Vector.Variant;
  PartsMemo.Lines.BeginUpdate;
  try
    PartsMemo.Clear;
    var first: integer := 0;
    for var i := 0 to pairs.Count div 2 - 1 do
    begin
      var count: integer := pairs[2 * i + 1].I4;
      var names: TArray<string> := [];
      for var j := first to Min(first + count, titles.Count) - 1 do
        names := names + [string(titles[j])];
      PartsMemo.Lines.Add(string(pairs[2 * i].Lpstr) + ': ' + string.Join(', ', names));
      Inc(first, count);
    end;
    for var j := first to titles.Count - 1 do // titles without a heading
      PartsMemo.Lines.Add(titles[j]);
  finally
    PartsMemo.Lines.EndUpdate;
  end;
end;

procedure TMainForm.TakeProperties;
var
  properties: TCorePropertiesE;

  // an empty field removes the element from the document, as in Office (Clear); an assigned '' would be a value - an empty
  // element. False: removed, nothing to assign
  function TakeText(aField: Pointer; const aText: string): boolean;
  begin
    Result := not aText.IsEmpty;
    if not Result then
      properties.Clear(aField);
  end;

begin
  properties := fDocument.Properties;
  if TakeText(@properties.Title, TitleEdit.Text) then
    properties.Title.XmlValue := TitleEdit.Text;
  if TakeText(@properties.Subject, SubjectEdit.Text) then
    properties.Subject.XmlValue := SubjectEdit.Text;
  if TakeText(@properties.Creator, CreatorEdit.Text) then
    properties.Creator.XmlValue := CreatorEdit.Text;
  if TakeText(@properties.Keywords, KeywordsEdit.Text) then
    properties.Keywords.XmlText := KeywordsEdit.Text;
  if TakeText(@properties.Description, DescriptionMemo.Text) then
    properties.Description.XmlValue := DescriptionMemo.Text;
  if TakeText(@properties.Category, CategoryEdit.Text) then
    properties.Category := CategoryEdit.Text;
  if TakeText(@properties.ContentStatus, ContentStatusEdit.Text) then
    properties.ContentStatus := ContentStatusEdit.Text;
  if TakeText(@properties.LastModifiedBy, LastModifiedByEdit.Text) then
    properties.LastModifiedBy := LastModifiedByEdit.Text;
  if TakeText(@properties.Revision, RevisionEdit.Text) then
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
