unit SheetPreview;

// A sheet shown in a TStringGrid: values, fills, fonts and alignment read through Calcite into a snapshot, so the grid paints
// from it and needs the workbook no longer. Only the sample's view: what a button wrote is in the workbook, not here

interface

uses System.SysUtils, System.Math, System.Types, System.Variants, System.UITypes, Vcl.Graphics, Vcl.Grids, Winapi.Windows,
  ProRock.Calcite;

type
  TShownCell = record
    Text: string;
    Fill: TColor;
    FontColor: TColor;
    FontStyle: TFontStyles;
    Align: THAlign;
    Info: string; // B5: number, 0.00, =SUM(A1:A3)
  end;

  TSheetPreview = class
  private const
    cMaxRows = 300;
    cMaxColumns = 40;
  private
    fGrid: TStringGrid;
    fCells: TArray<TArray<TShownCell>>;
    procedure DrawCell(Sender: TObject; aCol, aRow: integer; aRect: TRect; aState: TGridDrawState);
    class function ShownText(const aCell: TRange): string; static;
    class function Info(const aCell: TRange): string; static;
  public
    constructor Create(aGrid: TStringGrid);
    procedure Show(aSheet: TWorksheet);
    procedure Clear;
    // a cell of the grid: its address, type, number format and formula
    function CellInfo(aCol, aRow: integer): string;
  end;

implementation

const
  cTypeNames: array [TCellValueType] of string = ('empty', 'number', 'date', 'text', 'boolean', 'error');

constructor TSheetPreview.Create(aGrid: TStringGrid);
begin
  inherited Create;
  fGrid := aGrid;
  fGrid.OnDrawCell := DrawCell;
  Clear;
end;

procedure TSheetPreview.Clear;
begin
  fCells := nil;
  fGrid.RowCount := 2;
  fGrid.ColCount := 2;
  fGrid.Cells[1, 1] := '';
end;

class function TSheetPreview.ShownText(const aCell: TRange): string;
begin
  case aCell.ValueType of
    cvEmpty:
      if aCell.HasFormula then
        Result := aCell.Formula // no value until Excel calculates it
      else
        Result := '';
    cvNumber:
      Result := FloatToStr(aCell.AsFloat);
    cvDate:
      if Frac(aCell.AsDateTime) = 0 then
        Result := DateToStr(aCell.AsDateTime)
      else
        Result := DateTimeToStr(aCell.AsDateTime);
  else
    Result := aCell.AsString;
  end;
end;

class function TSheetPreview.Info(const aCell: TRange): string;
begin
  Result := aCell.Address + ': ' + cTypeNames[aCell.ValueType] + ', ' + aCell.NumberFormat;
  if aCell.HasFormula then
    Result := Result + ', ' + aCell.Formula;
end;

procedure TSheetPreview.Show(aSheet: TWorksheet);
var
  shown: TShownCell; // 10.3: no inline var of a record with strings
begin
  var used := aSheet.UsedRange;
  var lastRow := used.LastRow;
  if lastRow > cMaxRows then
    lastRow := cMaxRows;
  var lastColumn := used.LastColumn;
  if lastColumn > cMaxColumns then
    lastColumn := cMaxColumns;

  fGrid.RowCount := lastRow + 1;
  fGrid.ColCount := lastColumn + 1;
  SetLength(fCells, lastRow + 1, lastColumn + 1);
  for var column := 1 to lastColumn do
  begin
    var address := aSheet.Cells[1, column].Address;
    fGrid.Cells[column, 0] := address.Substring(0, address.Length - 1);
    if aSheet.Columns[column].Hidden then
      fGrid.ColWidths[column] := -1
    else
      fGrid.ColWidths[column] := Round(aSheet.Columns[column].ColumnWidth * 7) + 5;
  end;
  for var row := 1 to lastRow do
  begin
    fGrid.Cells[0, row] := IntToStr(row);
    if aSheet.Rows[row].Hidden then
      fGrid.RowHeights[row] := -1
    else
      fGrid.RowHeights[row] := Max(fGrid.DefaultRowHeight, Round(aSheet.Rows[row].RowHeight * 96 / 72)); // points
    for var column := 1 to lastColumn do
    begin
      var cell := aSheet.Cells[row, column];
      shown.Text := ShownText(cell);
      shown.Fill := cell.Interior.Color;
      shown.FontColor := cell.Font.Color;
      shown.FontStyle := cell.Font.Style;
      shown.Align := cell.HorizontalAlignment;
      shown.Info := Info(cell);
      fCells[row, column] := shown;
      fGrid.Cells[column, row] := shown.Text;
    end;
  end;
  fGrid.Invalidate;
end;

function TSheetPreview.CellInfo(aCol, aRow: integer): string;
begin
  if (aRow > 0) and (aRow < Length(fCells)) and (aCol > 0) and (aCol < Length(fCells[aRow])) then
    Result := fCells[aRow, aCol].Info
  else
    Result := '';
end;

procedure TSheetPreview.DrawCell(Sender: TObject; aCol, aRow: integer; aRect: TRect; aState: TGridDrawState);
var
  shown: TShownCell;
begin
  if (aCol = 0) or (aRow = 0) or (aRow >= Length(fCells)) or (aCol >= Length(fCells[aRow])) then
    Exit;
  shown := fCells[aRow, aCol];
  var canvas := fGrid.Canvas;
  if gdSelected in aState then
  begin
    canvas.Brush.Color := clHighlight;
    canvas.Font.Color := clHighlightText;
  end
  else
  begin
    if (shown.Fill = clNone) or (shown.Fill = clDefault) then
      canvas.Brush.Color := clWindow
    else
      canvas.Brush.Color := shown.Fill;
    if shown.FontColor = clDefault then
      canvas.Font.Color := clWindowText
    else
      canvas.Font.Color := shown.FontColor;
  end;
  canvas.Font.Style := shown.FontStyle;
  canvas.FillRect(aRect);

  var flags: cardinal := DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS;
  case shown.Align of
    haCenter, haCenterAcrossSelection:
      flags := flags or DT_CENTER;
    haRight:
      flags := flags or DT_RIGHT;
    haGeneral: // Excel's General: numbers to the right
      if (shown.Text <> '') and CharInSet(shown.Text[1], ['0' .. '9', '-']) then
        flags := flags or DT_RIGHT;
  end;
  var textRect := aRect;
  InflateRect(textRect, -4, 0);
  DrawText(canvas.Handle, PChar(shown.Text), Length(shown.Text), textRect, flags);
end;

end.
