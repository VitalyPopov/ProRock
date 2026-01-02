object FormMain: TFormMain
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Basic sample of ProRock Xmlite usage'
  ClientHeight = 312
  ClientWidth = 571
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnShow = FormShow
  TextHeight = 15
  object Label3: TLabel
    Left = 192
    Top = 92
    Width = 52
    Height = 15
    Caption = 'Customer'
  end
  object Label2: TLabel
    Left = 192
    Top = 63
    Width = 32
    Height = 15
    Caption = 'Status'
  end
  object Label1: TLabel
    Left = 192
    Top = 34
    Width = 11
    Height = 15
    Caption = 'ID'
  end
  object Label4: TLabel
    Left = 192
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
    FixedRows = 0
    ScrollBars = ssVertical
    TabOrder = 1
    ColWidths = (
      163
      63
      64)
  end
end
