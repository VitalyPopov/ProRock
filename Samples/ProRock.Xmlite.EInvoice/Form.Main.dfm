object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Electronic invoice - ProRock sample'
  ClientHeight = 600
  ClientWidth = 880
  Color = clBtnFace
  Constraints.MinHeight = 480
  Constraints.MinWidth = 640
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
    Caption = 'Open an invoice in CII or UBL, or drop it here'
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
    object CiiButton: TButton
      AlignWithMargins = True
      Left = 194
      Top = 8
      Width = 120
      Height = 28
      Hint = 'The example invoice in CII'
      Margins.Left = 0
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alLeft
      Caption = 'Example in CII'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
      OnClick = CiiButtonClick
    end
    object UblButton: TButton
      AlignWithMargins = True
      Left = 317
      Top = 8
      Width = 120
      Height = 28
      Hint = 'The same invoice in UBL'
      Margins.Left = 0
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alLeft
      Caption = 'Same in UBL'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      OnClick = UblButtonClick
    end
  end
  object HeaderMemo: TMemo
    AlignWithMargins = True
    Left = 8
    Top = 89
    Width = 864
    Height = 96
    Margins.Left = 8
    Margins.Right = 8
    Margins.Bottom = 0
    Align = alTop
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object LinesView: TListView
    AlignWithMargins = True
    Left = 8
    Top = 188
    Width = 864
    Height = 244
    Margins.Left = 8
    Margins.Right = 8
    Margins.Bottom = 0
    Align = alClient
    Columns = <
      item
        Caption = 'Line'
      end
      item
        Caption = 'Item'
        Width = 330
      end
      item
        Alignment = taRightJustify
        Caption = 'Quantity'
        Width = 80
      end
      item
        Caption = 'Unit'
      end
      item
        Alignment = taRightJustify
        Caption = 'Net price'
        Width = 100
      end
      item
        Alignment = taRightJustify
        Caption = 'VAT'
        Width = 70
      end
      item
        Alignment = taRightJustify
        Caption = 'Amount'
        Width = 150
      end>
    ReadOnly = True
    RowSelect = True
    TabOrder = 2
    ViewStyle = vsReport
  end
  object BottomPanel: TPanel
    Left = 0
    Top = 432
    Width = 880
    Height = 168
    Align = alBottom
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 3
    object VatView: TListView
      AlignWithMargins = True
      Left = 8
      Top = 3
      Width = 590
      Height = 157
      Margins.Left = 8
      Margins.Right = 0
      Margins.Bottom = 8
      Align = alClient
      Columns = <
        item
          Caption = 'VAT category'
          Width = 100
        end
        item
          Alignment = taRightJustify
          Caption = 'Rate'
          Width = 80
        end
        item
          Alignment = taRightJustify
          Caption = 'Basis'
          Width = 130
        end
        item
          Alignment = taRightJustify
          Caption = 'VAT'
          Width = 130
        end>
      ReadOnly = True
      RowSelect = True
      TabOrder = 0
      ViewStyle = vsReport
    end
    object TotalsView: TListView
      AlignWithMargins = True
      Left = 606
      Top = 3
      Width = 266
      Height = 157
      Margins.Left = 8
      Margins.Right = 8
      Margins.Bottom = 8
      Align = alRight
      Columns = <
        item
          Caption = 'Total'
          Width = 110
        end
        item
          Alignment = taRightJustify
          Caption = 'Amount'
          Width = 130
        end>
      ReadOnly = True
      RowSelect = True
      TabOrder = 1
      ViewStyle = vsReport
    end
  end
  object OpenDialog: TOpenDialog
    Filter = 'Invoices (*.xml)|*.xml|All files (*.*)|*.*'
    Left = 784
    Top = 8
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'xml'
    Filter = 'Invoices (*.xml)|*.xml'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 832
    Top = 8
  end
end
