object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Office document properties - ProRock sample'
  ClientHeight = 520
  ClientWidth = 584
  Color = clBtnFace
  Constraints.MinHeight = 480
  Constraints.MinWidth = 480
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object FileLabel: TLabel
    AlignWithMargins = True
    Left = 8
    Top = 47
    Width = 568
    Height = 15
    Margins.Left = 8
    Margins.Right = 8
    Align = alTop
    AutoSize = False
    Caption = 'Open a .docx, .xlsx or .pptx file - or drop it here'
    EllipsisPosition = epPathEllipsis
  end
  object SignedLabel: TLabel
    AlignWithMargins = True
    Left = 8
    Top = 68
    Width = 568
    Height = 15
    Margins.Left = 8
    Margins.Right = 8
    Align = alTop
    Caption = 'The document is digitally signed: saving it breaks the signature'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Visible = False
    ExplicitWidth = 331
  end
  object ButtonsPanel: TPanel
    Left = 0
    Top = 0
    Width = 584
    Height = 44
    Align = alTop
    BevelOuter = bvNone
    Padding.Left = 8
    Padding.Top = 8
    Padding.Right = 8
    Padding.Bottom = 8
    ShowCaption = False
    TabOrder = 0
    object OpenButton: TButton
      AlignWithMargins = True
      Left = 8
      Top = 8
      Width = 90
      Height = 28
      Margins.Left = 0
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alLeft
      Caption = 'Open...'
      TabOrder = 0
      OnClick = OpenButtonClick
    end
    object SaveButton: TButton
      AlignWithMargins = True
      Left = 101
      Top = 8
      Width = 90
      Height = 28
      Margins.Left = 0
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alLeft
      Caption = 'Save'
      Enabled = False
      TabOrder = 1
      OnClick = SaveButtonClick
    end
    object SaveAsButton: TButton
      AlignWithMargins = True
      Left = 194
      Top = 8
      Width = 90
      Height = 28
      Margins.Left = 0
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alLeft
      Caption = 'Save As...'
      Enabled = False
      TabOrder = 2
      OnClick = SaveAsButtonClick
    end
  end
  object FieldsPanel: TPanel
    AlignWithMargins = True
    Left = 12
    Top = 89
    Width = 560
    Height = 423
    Margins.Left = 12
    Margins.Right = 12
    Margins.Bottom = 8
    Align = alClient
    BevelOuter = bvNone
    Enabled = False
    ShowCaption = False
    TabOrder = 1
    object TitlePanel: TPanel
      Left = 0
      Top = 0
      Width = 560
      Height = 32
      Align = alTop
      BevelOuter = bvNone
      ShowCaption = False
      TabOrder = 0
      object TitleLabel: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 130
        Height = 26
        Align = alLeft
        AutoSize = False
        Caption = 'Title'
        Layout = tlCenter
      end
      object TitleEdit: TEdit
        AlignWithMargins = True
        Left = 139
        Top = 3
        Width = 418
        Height = 26
        Align = alClient
        TabOrder = 0
        ExplicitHeight = 23
      end
    end
    object SubjectPanel: TPanel
      Left = 0
      Top = 32
      Width = 560
      Height = 32
      Align = alTop
      BevelOuter = bvNone
      ShowCaption = False
      TabOrder = 1
      object SubjectLabel: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 130
        Height = 26
        Align = alLeft
        AutoSize = False
        Caption = 'Subject'
        Layout = tlCenter
      end
      object SubjectEdit: TEdit
        AlignWithMargins = True
        Left = 139
        Top = 3
        Width = 418
        Height = 26
        Align = alClient
        TabOrder = 0
        ExplicitHeight = 23
      end
    end
    object CreatorPanel: TPanel
      Left = 0
      Top = 64
      Width = 560
      Height = 32
      Align = alTop
      BevelOuter = bvNone
      ShowCaption = False
      TabOrder = 2
      object CreatorLabel: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 130
        Height = 26
        Align = alLeft
        AutoSize = False
        Caption = 'Author'
        Layout = tlCenter
      end
      object CreatorEdit: TEdit
        AlignWithMargins = True
        Left = 139
        Top = 3
        Width = 418
        Height = 26
        Align = alClient
        TabOrder = 0
        ExplicitHeight = 23
      end
    end
    object KeywordsPanel: TPanel
      Left = 0
      Top = 96
      Width = 560
      Height = 32
      Align = alTop
      BevelOuter = bvNone
      ShowCaption = False
      TabOrder = 3
      object KeywordsLabel: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 130
        Height = 26
        Align = alLeft
        AutoSize = False
        Caption = 'Keywords'
        Layout = tlCenter
      end
      object KeywordsEdit: TEdit
        AlignWithMargins = True
        Left = 139
        Top = 3
        Width = 418
        Height = 26
        Align = alClient
        TabOrder = 0
        ExplicitHeight = 23
      end
    end
    object DescriptionPanel: TPanel
      Left = 0
      Top = 128
      Width = 560
      Height = 72
      Align = alTop
      BevelOuter = bvNone
      ShowCaption = False
      TabOrder = 4
      object DescriptionLabel: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 130
        Height = 66
        Align = alLeft
        AutoSize = False
        Caption = 'Comments'
      end
      object DescriptionMemo: TMemo
        AlignWithMargins = True
        Left = 139
        Top = 3
        Width = 418
        Height = 66
        Align = alClient
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
    object CategoryPanel: TPanel
      Left = 0
      Top = 200
      Width = 560
      Height = 32
      Align = alTop
      BevelOuter = bvNone
      ShowCaption = False
      TabOrder = 5
      object CategoryLabel: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 130
        Height = 26
        Align = alLeft
        AutoSize = False
        Caption = 'Category'
        Layout = tlCenter
      end
      object CategoryEdit: TEdit
        AlignWithMargins = True
        Left = 139
        Top = 3
        Width = 418
        Height = 26
        Align = alClient
        TabOrder = 0
        ExplicitHeight = 23
      end
    end
    object ContentStatusPanel: TPanel
      Left = 0
      Top = 232
      Width = 560
      Height = 32
      Align = alTop
      BevelOuter = bvNone
      ShowCaption = False
      TabOrder = 6
      object ContentStatusLabel: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 130
        Height = 26
        Align = alLeft
        AutoSize = False
        Caption = 'Status'
        Layout = tlCenter
      end
      object ContentStatusEdit: TEdit
        AlignWithMargins = True
        Left = 139
        Top = 3
        Width = 418
        Height = 26
        Align = alClient
        TabOrder = 0
        ExplicitHeight = 23
      end
    end
    object LastModifiedByPanel: TPanel
      Left = 0
      Top = 264
      Width = 560
      Height = 32
      Align = alTop
      BevelOuter = bvNone
      ShowCaption = False
      TabOrder = 7
      object LastModifiedByLabel: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 130
        Height = 26
        Align = alLeft
        AutoSize = False
        Caption = 'Last modified by'
        Layout = tlCenter
      end
      object LastModifiedByEdit: TEdit
        AlignWithMargins = True
        Left = 139
        Top = 3
        Width = 418
        Height = 26
        Align = alClient
        TabOrder = 0
        ExplicitHeight = 23
      end
    end
    object RevisionPanel: TPanel
      Left = 0
      Top = 296
      Width = 560
      Height = 32
      Align = alTop
      BevelOuter = bvNone
      ShowCaption = False
      TabOrder = 8
      object RevisionLabel: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 130
        Height = 26
        Align = alLeft
        AutoSize = False
        Caption = 'Revision'
        Layout = tlCenter
      end
      object RevisionEdit: TEdit
        AlignWithMargins = True
        Left = 139
        Top = 3
        Width = 418
        Height = 26
        Align = alClient
        TabOrder = 0
        ExplicitHeight = 23
      end
    end
    object CreatedPanel: TPanel
      Left = 0
      Top = 328
      Width = 560
      Height = 32
      Align = alTop
      BevelOuter = bvNone
      ShowCaption = False
      TabOrder = 9
      object CreatedLabel: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 130
        Height = 26
        Align = alLeft
        AutoSize = False
        Caption = 'Created (UTC)'
        Layout = tlCenter
      end
      object CreatedEdit: TEdit
        AlignWithMargins = True
        Left = 139
        Top = 3
        Width = 418
        Height = 26
        TabStop = False
        Align = alClient
        ParentColor = True
        ReadOnly = True
        TabOrder = 0
        ExplicitHeight = 23
      end
    end
    object ModifiedPanel: TPanel
      Left = 0
      Top = 360
      Width = 560
      Height = 32
      Align = alTop
      BevelOuter = bvNone
      ShowCaption = False
      TabOrder = 10
      object ModifiedLabel: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 130
        Height = 26
        Align = alLeft
        AutoSize = False
        Caption = 'Modified (UTC)'
        Layout = tlCenter
      end
      object ModifiedEdit: TEdit
        AlignWithMargins = True
        Left = 139
        Top = 3
        Width = 418
        Height = 26
        TabStop = False
        Align = alClient
        ParentColor = True
        ReadOnly = True
        TabOrder = 0
        ExplicitHeight = 23
      end
    end
  end
  object OpenDialog: TOpenDialog
    Filter = 
      'Office documents (*.docx, *.xlsx, *.pptx)|*.docx;*.docm;*.xlsx;*' +
      '.xlsm;*.pptx;*.pptm|All files (*.*)|*.*'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 496
    Top = 8
  end
  object SaveDialog: TSaveDialog
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 536
    Top = 8
  end
end
