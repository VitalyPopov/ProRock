unit ProRock.Calcite.Aspects;

// Excel's cell formatting, format-neutral: what a style reads as, in the words every backend gives it (internal)

interface

uses System.UITypes;

type
  // Excel's names: XlUnderlineStyle, XlHAlign, XlVAlign, XlBordersIndex, XlLineStyle, XlBorderWeight
  TUnderline = (ulNone, ulSingle, ulDouble, ulSingleAccounting, ulDoubleAccounting);
  THAlign = (haGeneral, haLeft, haCenter, haRight, haFill, haJustify, haCenterAcrossSelection, haDistributed);
  TVAlign = (vaTop, vaCenter, vaBottom, vaJustify, vaDistributed);
  TBorderEdge = (beLeft, beTop, beBottom, beRight, beInsideVertical, beInsideHorizontal);
  TBorderEdges = set of TBorderEdge;
  TLineStyle = (lsNone, lsContinuous, lsDash, lsDot, lsDashDot, lsDashDotDot, lsDouble, lsSlantDashDot);
  TBorderWeight = (bwHairline, bwThin, bwMedium, bwThick);

  TBorderWeights = set of TBorderWeight;

  // the sides a cell's own border has
  TCellSide = beLeft .. beRight;
  TCellSides = set of TCellSide;

  // a side as Excel reads it
  TBorderLine = record
    LineStyle: TLineStyle;
    Weight: TBorderWeight;
    Color: TColor;
  end;

const
  cNoLine: TBorderLine = (LineStyle: lsNone; Weight: bwThin; Color: 0);

type

  // a style as Excel reads it (its CellFormat), the values as TRange's properties read them
  TCellFormat = record
    NumberFormat: string;
    FontName: string;
    FontSize: Double;
    FontColor: TColor;
    Bold, Italic, Strikethrough: boolean;
    Underline: TUnderline;
    FillColor: TColor;
    HorizontalAlignment: THAlign;
    VerticalAlignment: TVAlign;
    WrapText: boolean;
    Borders: array[TCellSide] of TBorderLine; // the cell's own sides, not the neighbours' facing ones
  end;

  // what a setter writes: TCellFormat's fields, a border's three (LineStyle, Weight, Color) for each of its sides
  TAspect = (asNumberFormat, asFontName, asFontSize, asFontColor, asBold, asItalic, asStrikethrough, asUnderline, asFillColor,
    asHorizontalAlignment, asVerticalAlignment, asWrapText, asLineStyle, asWeight, asBorderColor);
  TAspects = set of TAspect;

  // a write: the aspects' values in Value, the border's in Line, for the Sides
  TFormatChange = record
    Aspects: TAspects;
    Value: TCellFormat;
    Line: TBorderLine;
    Sides: TCellSides;
  end;

const
  cBorderAspects = [asLineStyle, asWeight, asBorderColor];
  // the weights Excel draws each line style in
  cLineWeights: array[TLineStyle] of TBorderWeights = ([], [bwHairline, bwThin, bwMedium, bwThick], [bwThin, bwMedium],
    [bwThin], [bwThin, bwMedium], [bwThin, bwMedium], [bwThick], [bwMedium]);

// aFormat with aChange written as Excel writes it; a border's side by Excel's rules: a weight or a color alone draws a
// continuous line, a weight the style has not makes it continuous, a style set without one takes its own
function Applied(const aFormat: TCellFormat; const aChange: TFormatChange): TCellFormat;

implementation

function Applied(const aFormat: TCellFormat; const aChange: TFormatChange): TCellFormat;
const
  cOwnWeights: array[TLineStyle] of TBorderWeight = (bwThin, bwThin, bwThin, bwThin, bwThin, bwThin, bwThick, bwMedium);
begin
  Result := aFormat;
  var aspects: TAspects := aChange.Aspects;
  var value: TCellFormat := aChange.Value;
  if asNumberFormat in aspects then
    Result.NumberFormat := value.NumberFormat;
  if asFontName in aspects then
    Result.FontName := value.FontName;
  if asFontSize in aspects then
    Result.FontSize := value.FontSize;
  if asFontColor in aspects then
    Result.FontColor := value.FontColor;
  if asBold in aspects then
    Result.Bold := value.Bold;
  if asItalic in aspects then
    Result.Italic := value.Italic;
  if asStrikethrough in aspects then
    Result.Strikethrough := value.Strikethrough;
  if asUnderline in aspects then
    Result.Underline := value.Underline;
  if asFillColor in aspects then
    Result.FillColor := value.FillColor;
  if asHorizontalAlignment in aspects then
    Result.HorizontalAlignment := value.HorizontalAlignment;
  if asVerticalAlignment in aspects then
    Result.VerticalAlignment := value.VerticalAlignment;
  if asWrapText in aspects then
    Result.WrapText := value.WrapText;
  if aspects * cBorderAspects = [] then
    Exit;
  for var side: TCellSide in aChange.Sides do
  begin
    var line: TBorderLine := Result.Borders[side];
    if asLineStyle in aspects then
      line.LineStyle := aChange.Line.LineStyle
    else if line.LineStyle = lsNone then
      line.LineStyle := lsContinuous;
    if asWeight in aspects then
      line.Weight := aChange.Line.Weight;
    if asBorderColor in aspects then
      line.Color := aChange.Line.Color;
    if not (line.Weight in cLineWeights[line.LineStyle]) then
      if (asWeight in aspects) and not (asLineStyle in aspects) then
        line.LineStyle := lsContinuous
      else
        line.Weight := cOwnWeights[line.LineStyle];
    if line.LineStyle = lsNone then
      line := cNoLine;
    Result.Borders[side] := line;
  end;
end;

end.
