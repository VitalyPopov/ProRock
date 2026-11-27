object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Calcite basics - ProRock sample'
  ClientHeight = 720
  ClientWidth = 1080
  Color = clBtnFace
  Constraints.MinHeight = 480
  Constraints.MinWidth = 760
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object ToolPanel: TPanel
    Left = 0
    Top = 0
    Width = 1080
    Height = 44
    Align = alTop
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 0
    object NewButton: TButton
      Left = 8
      Top = 8
      Width = 100
      Height = 28
      Caption = 'New'
      TabOrder = 0
      OnClick = NewButtonClick
    end
    object OpenButton: TButton
      Left = 114
      Top = 8
      Width = 100
      Height = 28
      Caption = 'Open...'
      TabOrder = 1
      OnClick = OpenButtonClick
    end
    object SaveAsButton: TButton
      Left = 220
      Top = 8
      Width = 100
      Height = 28
      Caption = 'Save as...'
      TabOrder = 2
      OnClick = SaveAsButtonClick
    end
    object ExcelButton: TButton
      Left = 326
      Top = 8
      Width = 100
      Height = 28
      Caption = 'Open in Excel'
      TabOrder = 3
      OnClick = ExcelButtonClick
    end
    object FileLabel: TLabel
      Left = 440
      Top = 14
      Width = 620
      Height = 15
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      EllipsisPosition = epPathEllipsis
    end
  end
  object Features: TPageControl
    AlignWithMargins = True
    Left = 8
    Top = 47
    Width = 1064
    Height = 108
    Margins.Left = 8
    Margins.Right = 8
    Margins.Bottom = 0
    ActivePage = ValuesTab
    Align = alTop
    TabOrder = 1
    OnChange = FeaturesChange
    object FilesTab: TTabSheet
      Caption = 'Files'
      object CreateAndSaveButton: TButton
        Left = 6
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Create and save'
        TabOrder = 0
        OnClick = CreateAndSaveButtonClick
      end
      object OpenAndReadButton: TButton
        Left = 182
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Open and read'
        TabOrder = 1
        OnClick = OpenAndReadButtonClick
      end
      object OpenEditSaveButton: TButton
        Left = 358
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Open, change, save'
        TabOrder = 2
        OnClick = OpenEditSaveButtonClick
      end
      object FilePropertiesButton: TButton
        Left = 534
        Top = 6
        Width = 170
        Height = 28
        Caption = 'File properties'
        TabOrder = 3
        OnClick = FilePropertiesButtonClick
      end
    end
    object ValuesTab: TTabSheet
      Caption = 'Values'
      object WriteValuesButton: TButton
        Left = 6
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Text, numbers, dates'
        TabOrder = 0
        OnClick = WriteValuesButtonClick
      end
      object ReadValuesButton: TButton
        Left = 182
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Read them back'
        TabOrder = 1
        OnClick = ReadValuesButtonClick
      end
      object CellsByNumberButton: TButton
        Left = 358
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Cells by row and column'
        TabOrder = 2
        OnClick = CellsByNumberButtonClick
      end
      object BlockOfValuesButton: TButton
        Left = 534
        Top = 6
        Width = 170
        Height = 28
        Caption = 'A block at once'
        TabOrder = 3
        OnClick = BlockOfValuesButtonClick
      end
      object ClearValuesButton: TButton
        Left = 710
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Clear contents'
        TabOrder = 4
        OnClick = ClearValuesButtonClick
      end
    end
    object FormulasTab: TTabSheet
      Caption = 'Formulas'
      object WriteFormulasButton: TButton
        Left = 6
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Write formulas'
        TabOrder = 0
        OnClick = WriteFormulasButtonClick
      end
      object ReadFormulasButton: TButton
        Left = 182
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Read a formula'
        TabOrder = 1
        OnClick = ReadFormulasButtonClick
      end
      object ArrayFormulaButton: TButton
        Left = 358
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Array formula'
        TabOrder = 2
        OnClick = ArrayFormulaButtonClick
      end
    end
    object FormatsTab: TTabSheet
      Caption = 'Formats'
      object NumberFormatsButton: TButton
        Left = 6
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Number formats'
        TabOrder = 0
        OnClick = NumberFormatsButtonClick
      end
      object FontButton: TButton
        Left = 182
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Font'
        TabOrder = 1
        OnClick = FontButtonClick
      end
      object FillButton: TButton
        Left = 358
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Fill'
        TabOrder = 2
        OnClick = FillButtonClick
      end
      object BordersButton: TButton
        Left = 534
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Borders'
        TabOrder = 3
        OnClick = BordersButtonClick
      end
      object AlignmentButton: TButton
        Left = 710
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Alignment and wrap'
        TabOrder = 4
        OnClick = AlignmentButtonClick
      end
      object MergeButton: TButton
        Left = 886
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Merge cells'
        TabOrder = 5
        OnClick = MergeButtonClick
      end
    end
    object RowsTab: TTabSheet
      Caption = 'Rows and columns'
      object FillListButton: TButton
        Left = 6
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Fill a list'
        TabOrder = 0
        OnClick = FillListButtonClick
      end
      object InsertRowsButton: TButton
        Left = 182
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Insert rows 3:4'
        TabOrder = 1
        OnClick = InsertRowsButtonClick
      end
      object DeleteRowsButton: TButton
        Left = 358
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Delete rows 3:4'
        TabOrder = 2
        OnClick = DeleteRowsButtonClick
      end
      object InsertColumnButton: TButton
        Left = 534
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Insert column B'
        TabOrder = 3
        OnClick = InsertColumnButtonClick
      end
      object HideColumnButton: TButton
        Left = 710
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Hide or show column C'
        TabOrder = 4
        OnClick = HideColumnButtonClick
      end
      object SizesButton: TButton
        Left = 886
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Width and height'
        TabOrder = 5
        OnClick = SizesButtonClick
      end
      object AutoFitButton: TButton
        Left = 6
        Top = 40
        Width = 170
        Height = 28
        Caption = 'AutoFit columns'
        TabOrder = 6
        OnClick = AutoFitButtonClick
      end
      object FreezeButton: TButton
        Left = 182
        Top = 40
        Width = 170
        Height = 28
        Caption = 'Freeze the header'
        TabOrder = 7
        OnClick = FreezeButtonClick
      end
    end
    object SheetsTab: TTabSheet
      Caption = 'Sheets'
      object AddSheetButton: TButton
        Left = 6
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Add a sheet'
        TabOrder = 0
        OnClick = AddSheetButtonClick
      end
      object ListSheetsButton: TButton
        Left = 182
        Top = 6
        Width = 170
        Height = 28
        Caption = 'List the sheets'
        TabOrder = 1
        OnClick = ListSheetsButtonClick
      end
      object HideSheetButton: TButton
        Left = 358
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Hide the last sheet'
        TabOrder = 2
        OnClick = HideSheetButtonClick
      end
      object DeleteSheetButton: TButton
        Left = 534
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Delete the last sheet'
        TabOrder = 3
        OnClick = DeleteSheetButtonClick
      end
    end
    object DataSetTab: TTabSheet
      Caption = 'DataSet'
      object ExportDataSetButton: TButton
        Left = 6
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Export a DataSet'
        TabOrder = 0
        OnClick = ExportDataSetButtonClick
      end
    end
    object IssuesTab: TTabSheet
      Caption = 'Issues'
      object RefusedWriteButton: TButton
        Left = 6
        Top = 6
        Width = 170
        Height = 28
        Caption = 'A refused write'
        TabOrder = 0
        OnClick = RefusedWriteButtonClick
      end
      object IssuesAsTheyComeButton: TButton
        Left = 182
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Issues as they come'
        TabOrder = 1
        OnClick = IssuesAsTheyComeButtonClick
      end
      object FailedOpenButton: TButton
        Left = 358
        Top = 6
        Width = 170
        Height = 28
        Caption = 'A file that will not open'
        TabOrder = 2
        OnClick = FailedOpenButtonClick
      end
      object RefusedInsertButton: TButton
        Left = 534
        Top = 6
        Width = 170
        Height = 28
        Caption = 'A refused insert'
        TabOrder = 3
        OnClick = RefusedInsertButtonClick
      end
    end
    object XlsxTab: TTabSheet
      Caption = 'Xlsx objects'
      object TabColorButton: TButton
        Left = 6
        Top = 6
        Width = 170
        Height = 28
        Caption = 'Tab color'
        TabOrder = 0
        OnClick = TabColorButtonClick
      end
    end
  end
  object LogMemo: TMemo
    AlignWithMargins = True
    Left = 8
    Top = 530
    Width = 1064
    Height = 142
    Margins.Left = 8
    Margins.Right = 8
    Margins.Bottom = 8
    Align = alBottom
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object SheetTabs: TTabControl
    AlignWithMargins = True
    Left = 8
    Top = 158
    Width = 1064
    Height = 369
    Margins.Left = 8
    Margins.Right = 8
    Margins.Bottom = 0
    Align = alClient
    TabOrder = 2
    TabPosition = tpBottom
    OnChange = SheetTabsChange
    object CellLabel: TLabel
      AlignWithMargins = True
      Left = 7
      Top = 7
      Width = 1050
      Height = 15
      Align = alTop
      AutoSize = False
      EllipsisPosition = epEndEllipsis
    end
    object CellsGrid: TStringGrid
      AlignWithMargins = True
      Left = 7
      Top = 28
      Width = 1050
      Height = 310
      Align = alClient
      DefaultColWidth = 70
      DefaultRowHeight = 22
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing]
      TabOrder = 0
      OnSelectCell = CellsGridSelectCell
    end
  end
  object OpenDialog: TOpenDialog
    Filter = 'Excel workbooks (*.xlsx; *.xlsm)|*.xlsx;*.xlsm'
    Left = 960
    Top = 8
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'xlsx'
    Filter = 'Excel workbooks (*.xlsx)|*.xlsx'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 1008
    Top = 8
  end
end
