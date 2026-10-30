object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Excel workbook - ProRock sample'
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
    Caption = 'Open an .xlsx file - or drop it here'
    EllipsisPosition = epPathEllipsis
  end
  object TablesLabel: TLabel
    AlignWithMargins = True
    Left = 8
    Top = 68
    Width = 864
    Height = 15
    Margins.Left = 8
    Margins.Right = 8
    Align = alTop
    AutoSize = False
    EllipsisPosition = epEndEllipsis
  end
  object CellLabel: TLabel
    AlignWithMargins = True
    Left = 8
    Top = 89
    Width = 864
    Height = 15
    Margins.Left = 8
    Margins.Right = 8
    Align = alTop
    AutoSize = False
    EllipsisPosition = epEndEllipsis
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
      Caption = 'Save as...'
      Enabled = False
      TabOrder = 2
      OnClick = SaveAsButtonClick
    end
  end
  object SheetTabs: TTabControl
    AlignWithMargins = True
    Left = 8
    Top = 110
    Width = 864
    Height = 482
    Margins.Left = 8
    Margins.Right = 8
    Margins.Bottom = 8
    Align = alClient
    TabOrder = 1
    OnChange = SheetTabsChange
    OnChanging = SheetTabsChanging
    object CellsGrid: TStringGrid
      AlignWithMargins = True
      Left = 7
      Top = 9
      Width = 850
      Height = 466
      Align = alClient
      DefaultColWidth = 110
      DefaultRowHeight = 22
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing]
      TabOrder = 0
      OnSelectCell = CellsGridSelectCell
      OnSetEditText = CellsGridSetEditText
    end
  end
  object OpenDialog: TOpenDialog
    Filter = 'Excel workbooks (*.xlsx)|*.xlsx'
    Left = 784
    Top = 8
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'xlsx'
    Filter = 'Excel workbooks (*.xlsx)|*.xlsx'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 832
    Top = 8
  end
end
