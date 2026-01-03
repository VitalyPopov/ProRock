object FormMain: TFormMain
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Basic sample of ProRock Xmlite usage'
  ClientHeight = 312
  ClientWidth = 700
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnShow = FormShow
  TextHeight = 15
  object Label2: TLabel
    Left = 241
    Top = 65
    Width = 32
    Height = 15
    Caption = 'Status'
  end
  object Label4: TLabel
    Left = 416
    Top = 268
    Width = 26
    Height = 15
    Caption = 'Total'
  end
  object ParseButton: TButton
    Left = 24
    Top = 24
    Width = 81
    Height = 41
    Caption = 'Parse demo.xml'
    TabOrder = 0
    WordWrap = True
    OnClick = ParseButtonClick
  end
  object StringGrid1: TStringGrid
    Left = 192
    Top = 128
    Width = 320
    Height = 120
    ColCount = 3
    FixedCols = 0
    RowCount = 20
    FixedRows = 0
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goAlwaysShowEditor, goFixedRowDefAlign]
    ScrollBars = ssVertical
    TabOrder = 4
    ColWidths = (
      163
      63
      64)
  end
  object LabeledEdit1: TLabeledEdit
    Left = 279
    Top = 33
    Width = 145
    Height = 23
    EditLabel.Width = 11
    EditLabel.Height = 23
    EditLabel.Caption = 'ID'
    LabelPosition = lpLeft
    TabOrder = 1
    Text = ''
  end
  object LabeledEdit2: TLabeledEdit
    Left = 279
    Top = 91
    Width = 145
    Height = 23
    EditLabel.Width = 52
    EditLabel.Height = 23
    EditLabel.Caption = 'Customer'
    LabelPosition = lpLeft
    TabOrder = 3
    Text = ''
  end
  object ComboBox1: TComboBox
    Left = 279
    Top = 62
    Width = 145
    Height = 23
    Style = csDropDownList
    TabOrder = 2
  end
  object SerializeButton: TButton
    Left = 592
    Top = 24
    Width = 81
    Height = 41
    Caption = 'Serialize to order.xml'
    TabOrder = 5
    WordWrap = True
    OnClick = SerializeButtonClick
  end
end
