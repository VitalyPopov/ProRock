object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'FHIR resources - ProRock sample'
  ClientHeight = 600
  ClientWidth = 880
  Color = clBtnFace
  Constraints.MinHeight = 400
  Constraints.MinWidth = 600
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
    Width = 864
    Height = 15
    Margins.Left = 8
    Margins.Right = 8
    Align = alTop
    AutoSize = False
    Caption = 
      'Open a FHIR R4 XML file - a Bundle or one resource - or drop it ' +
      'here'
    EllipsisPosition = epPathEllipsis
  end
  object StatusLabel: TLabel
    AlignWithMargins = True
    Left = 8
    Top = 68
    Width = 864
    Height = 15
    Margins.Left = 8
    Margins.Right = 8
    Align = alTop
    AutoSize = False
  end
  object Splitter: TSplitter
    Left = 0
    Top = 436
    Width = 880
    Height = 4
    Cursor = crVSplit
    Align = alBottom
  end
  object ButtonsPanel: TPanel
    Left = 0
    Top = 0
    Width = 880
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
    object SaveAsButton: TButton
      AlignWithMargins = True
      Left = 101
      Top = 8
      Width = 90
      Height = 28
      Margins.Left = 0
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alLeft
      Caption = 'Save as...'
      Enabled = False
      TabOrder = 1
      OnClick = SaveAsButtonClick
    end
    object SpeedButton: TButton
      AlignWithMargins = True
      Left = 194
      Top = 8
      Width = 120
      Height = 28
      Hint = 
        'A Bundle of 1,000 resources made of these entries, read and writ' +
        'ten'
      Margins.Left = 0
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alLeft
      Caption = 'Speed test'
      Enabled = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
      OnClick = SpeedButtonClick
    end
  end
  object EntriesView: TListView
    AlignWithMargins = True
    Left = 8
    Top = 89
    Width = 864
    Height = 347
    Margins.Left = 8
    Margins.Right = 8
    Margins.Bottom = 0
    Align = alClient
    Columns = <
      item
        Caption = 'Resource'
        Width = 110
      end
      item
        Caption = 'Id'
        Width = 150
      end
      item
        Caption = 'What'
        Width = 260
      end
      item
        Caption = 'Value'
        Width = 180
      end
      item
        Caption = 'When'
        Width = 150
      end>
    ReadOnly = True
    RowSelect = True
    TabOrder = 1
    ViewStyle = vsReport
    OnSelectItem = EntriesViewSelectItem
  end
  object NarrativeMemo: TMemo
    AlignWithMargins = True
    Left = 8
    Top = 443
    Width = 864
    Height = 149
    Margins.Left = 8
    Margins.Right = 8
    Margins.Bottom = 8
    Align = alBottom
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object OpenDialog: TOpenDialog
    Filter = 'FHIR XML (*.xml)|*.xml|All files (*.*)|*.*'
    Left = 784
    Top = 8
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'xml'
    Filter = 'FHIR XML (*.xml)|*.xml'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 832
    Top = 8
  end
end
