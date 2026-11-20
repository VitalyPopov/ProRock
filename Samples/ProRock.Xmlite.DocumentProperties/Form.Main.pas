unit Form.Main;

// The core properties of an Office document - the ones File > Info shows - opened, edited and saved, and what the
// application says about its contents (the sheets of a workbook), shown. The document is a TPackageOoxml
// (ProRock.Office.Ooxml): its Properties are plain values; docProps/app.xml is read into the generated classes

interface

uses Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  ProRock.Office.Ooxml;

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
    fDocument: TPackageOoxml;

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

uses System.UITypes, System.Math, System.DateUtils, Winapi.ShellAPI, ProRock.Xmlite.Schema.Ooxml.PropExt,
  ProRock.Xmlite.Schema.Ooxml.PropVar;

{$R *.dfm}

// the properties keep UTC, File > Info shows local time
function LocalTime(aValue: TDateTime): string;
begin
  Result := '';
  if aValue <> 0 then
    Result := DateTimeToStr(TTimeZone.Local.ToLocalTime(aValue));
end;

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  fDocument := TPackageOoxml.Create;
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
  var properties: TCoreProperties := fDocument.Properties;
  TitleEdit.Text := properties.Title;
  SubjectEdit.Text := properties.Subject;
  CreatorEdit.Text := properties.Creator;
  KeywordsEdit.Text := properties.Keywords;
  DescriptionMemo.Text := AdjustLineBreaks(properties.Description); // XML keeps line breaks as LF
  CategoryEdit.Text := properties.Category;
  ContentStatusEdit.Text := properties.ContentStatus;
  LastModifiedByEdit.Text := properties.LastModifiedBy;
  RevisionEdit.Text := properties.Revision;
  CreatedEdit.Text := LocalTime(properties.Created);
  ModifiedEdit.Text := LocalTime(properties.Modified);
  ShowContents;

  FileLabel.Caption := fDocument.FileName;
  SignedLabel.Visible := fDocument.Signed;
  FieldsPanel.Enabled := True;
  SaveButton.Enabled := True;
  SaveAsButton.Enabled := True;
end;

procedure TMainForm.ShowContents;
begin
  ApplicationEdit.Text := '';
  PartsMemo.Clear;
  // the application's properties are optional, found through the package's relationships
  var extended: TPropertiesE := nil;
  for var relationship: TRelationshipOoxml in fDocument.Relationships('', '/extended-properties') do
    if not relationship.Part.IsEmpty then
      extended := fDocument.Part<TPropertiesE>(relationship.Part);
  if extended = nil then
    Exit;
  ApplicationEdit.Text := extended.Application;

  // the titles of the parts are a list of plain strings (a vt:vector of vt:lpstr), grouped by the heading pairs - a name
  // and a count each (vt:variant holding a vt:lpstr, then one holding a vt:i4): "Worksheets: Sales, Costs"
  var titles := extended.TitlesOfParts.Vector.Lpstr;
  var pairs := extended.HeadingPairs.Vector.Variant;
  PartsMemo.Lines.BeginUpdate;
  try
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

// only what changed: a save with nothing changed leaves the file as it was. An empty field removes the property, as in Office
procedure TMainForm.TakeProperties;
begin
  var properties: TCoreProperties := fDocument.Properties;
  if TitleEdit.Text <> properties.Title then
    properties.Title := TitleEdit.Text;
  if SubjectEdit.Text <> properties.Subject then
    properties.Subject := SubjectEdit.Text;
  if CreatorEdit.Text <> properties.Creator then
    properties.Creator := CreatorEdit.Text;
  if KeywordsEdit.Text <> properties.Keywords then
    properties.Keywords := KeywordsEdit.Text;
  var description: string := string(DescriptionMemo.Text).Replace(#13#10, #10);
  if description <> properties.Description then
    properties.Description := description;
  if CategoryEdit.Text <> properties.Category then
    properties.Category := CategoryEdit.Text;
  if ContentStatusEdit.Text <> properties.ContentStatus then
    properties.ContentStatus := ContentStatusEdit.Text;
  if LastModifiedByEdit.Text <> properties.LastModifiedBy then
    properties.LastModifiedBy := LastModifiedByEdit.Text;
  if RevisionEdit.Text <> properties.Revision then
    properties.Revision := RevisionEdit.Text;
end;

procedure TMainForm.OpenDocument(const aFileName: string);
begin
  if not fDocument.Open(aFileName) then
  begin
    MessageDlg(fDocument.Error, mtWarning, [mbOK], 0);
    Exit;
  end;
  ShowProperties;
end;

procedure TMainForm.SaveDocument(const aFileName: string);
begin
  if fDocument.Signed and (MessageDlg('The document is digitally signed. Saving changes its properties and breaks the ' +
    'signature. Save anyway?', mtConfirmation, [mbYes, mbNo], 0, mbNo) <> mrYes) then
    Exit;

  TakeProperties;
  if not fDocument.SaveAs(aFileName) then
  begin
    MessageDlg(fDocument.Error, mtWarning, [mbOK], 0);
    Exit;
  end;
  ShowProperties; // Modified is the time of this save when something changed
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
