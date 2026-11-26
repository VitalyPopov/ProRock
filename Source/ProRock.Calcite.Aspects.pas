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

  // the sides a cell's own border has
  TCellSide = beLeft .. beRight;

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

implementation

end.
