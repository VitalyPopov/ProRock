unit ProRock.Calcite.Data;

// A TDataSet to an Excel sheet: ExportDataSet(Query, Workbook.Worksheets[1])

interface

uses Data.DB, ProRock.Calcite;

// The visible fields, every record from the first: a bold header of DisplayLabel, a row a record, each value as its type
// (text, a number, a date, a Boolean; null left empty; blobs and other binary fields left out), a number format from the
// field (its DisplayFormat, a currency, a BCD's decimals, a date's kind), the columns fitted to what they show and the header
// frozen. The data set is back at its record after. Returns the range written, the header included
function ExportDataSet(aDataSet: TDataSet; aSheet: TWorksheet; const aTopLeft: string = 'A1'): TRange;

implementation

uses System.SysUtils, System.Classes, System.Generics.Collections, Data.FMTBcd;

type
  TValueKind = (vkNone, vkText, vkInteger, vkFloat, vkDate, vkBoolean);

function KindOf(aField: TField): TValueKind;
begin
  case aField.DataType of
    ftString, ftWideString, ftFixedChar, ftFixedWideChar, ftMemo, ftWideMemo, ftFmtMemo, ftGuid:
      Result := vkText;
    ftSmallint, ftInteger, ftWord, ftAutoInc, ftLargeint, ftShortint, ftByte, ftLongWord:
      Result := vkInteger;
    ftFloat, ftCurrency, ftBCD, ftFMTBcd, ftExtended, ftSingle:
      Result := vkFloat;
    ftDate, ftTime, ftDateTime, ftTimeStamp, ftTimeStampOffset:
      Result := vkDate;
    ftBoolean:
      Result := vkBoolean;
  else
    Result := vkNone;
  end;
end;

// FormatFloat's code as Excel's: the same placeholders; letters and % shown as they are (FormatFloat does not scale by %)
function NumberCode(const aCode: string): string;
begin
  Result := '';
  var i: integer := 1;
  while i <= aCode.Length do
  begin
    var c: char := aCode[i];
    if CharInSet(c, ['"', '''']) then
    begin
      var close: integer := Pos(c, aCode, i + 1);
      if close = 0 then
        close := aCode.Length + 1;
      Result := Result + '"' + Copy(aCode, i + 1, close - i - 1) + '"';
      i := close;
    end
    else if CharInSet(c, ['E', 'e']) and (i < aCode.Length) and CharInSet(aCode[i + 1], ['+', '-']) then
    begin
      Result := Result + 'E' + aCode[i + 1];
      Inc(i);
    end
    else if CharInSet(c, ['#', '0', '.', ',', ';', '+', '-', ' ', '(', ')']) then
      Result := Result + c
    else
      Result := Result + '\' + c;
    Inc(i);
  end;
end;

// FormatDateTime's code as Excel's: ddddd is Excel's built-in short date (the reader's order, as Delphi's), n minutes as m,
// z thousandths as 0, t and tt the times
function DateCode(const aCode: string): string;
begin
  Result := '';
  var lower: string := LowerCase(aCode);
  var i: integer := 1;
  while i <= aCode.Length do
  begin
    var c: char := lower[i];
    var run: integer := 1;
    while (i + run <= aCode.Length) and (lower[i + run] = c) do
      Inc(run);
    case c of
      '"', '''':
        begin
          var close: integer := Pos(aCode[i], aCode, i + 1);
          if close = 0 then
            close := aCode.Length + 1;
          Result := Result + '"' + Copy(aCode, i + 1, close - i - 1) + '"';
          run := close - i + 1;
        end;
      'c':
        Result := Result + 'm/d/yyyy h:mm:ss';
      'd':
        if run = 5 then
          Result := Result + 'm/d/yyyy'
        else if run >= 6 then
          Result := Result + 'dddd, mmmm d, yyyy'
        else
          Result := Result + Copy(lower, i, run);
      'm', 'y', 'h', 's':
        Result := Result + Copy(lower, i, run);
      'n':
        Result := Result + StringOfChar('m', run);
      'z':
        Result := Result + StringOfChar('0', run);
      't':
        if run = 1 then
          Result := Result + 'h:mm'
        else
          Result := Result + 'h:mm:ss';
      'a':
        if Copy(lower, i, 5) = 'am/pm' then
        begin
          Result := Result + 'AM/PM';
          run := 5;
        end
        else if Copy(lower, i, 4) = 'ampm' then
        begin
          Result := Result + 'AM/PM';
          run := 4;
        end
        else if Copy(lower, i, 3) = 'a/p' then
        begin
          Result := Result + 'A/P';
          run := 3;
        end
        else
        begin
          Result := Result + '\a';
          run := 1;
        end;
      '/', ':', ' ', '.', ',', '-':
        Result := Result + Copy(aCode, i, run);
    else
      for var k := i to i + run - 1 do
        Result := Result + '\' + aCode[k];
    end;
    Inc(i, run);
  end;
end;

// the number format a field's values get, '' - Calcite's own (General, a date's)
function FieldFormat(aField: TField; aWorkbook: TWorkbook): string;
begin
  Result := '';
  if (aField is TNumericField) and (TNumericField(aField).DisplayFormat <> '') then
    Exit(NumberCode(TNumericField(aField).DisplayFormat));
  if (aField is TDateTimeField) and (TDateTimeField(aField).DisplayFormat <> '') then
    Exit(DateCode(TDateTimeField(aField).DisplayFormat));
  case aField.DataType of
    ftDate:
      Result := aWorkbook.DateFormat;
    ftTime:
      Result := 'h:mm:ss';
    ftDateTime, ftTimeStamp, ftTimeStampOffset:
      Result := aWorkbook.DateTimeFormat;
    ftCurrency:
      Result := '#,##0.00';
    ftFloat, ftExtended, ftSingle:
      if TFloatField(aField).Currency then
        Result := '#,##0.00';
    ftBCD, ftFMTBcd:
      begin
        var currency: boolean := ((aField is TBCDField) and TBCDField(aField).Currency) or
          ((aField is TFMTBCDField) and TFMTBCDField(aField).Currency);
        if currency then
          Result := '#,##0.00'
        else if aField.Size > 0 then // the decimals
          Result := '#,##0.' + StringOfChar('0', aField.Size);
      end;
  end;
end;

function ExportDataSet(aDataSet: TDataSet; aSheet: TWorksheet; const aTopLeft: string): TRange;
begin
  var origin: TRange := aSheet.Range[aTopLeft];
  var top: integer := origin.Row;
  var left: integer := origin.Column;
  var fields: TList<TField> := TList<TField>.Create;
  try
    for var field: TField in aDataSet.Fields do
      if field.Visible and (KindOf(field) <> vkNone) then
        fields.Add(field);
    for var i := 0 to fields.Count - 1 do
      aSheet.Cells[top, left + i].AsString := fields[i].DisplayLabel;
    var row: integer := top;
    aDataSet.DisableControls;
    try
      var bookmark: TBookmark := nil;
      if not aDataSet.IsUniDirectional then
      begin
        bookmark := aDataSet.GetBookmark;
        aDataSet.First;
      end;
      try
        while not aDataSet.Eof do
        begin
          Inc(row);
          for var i := 0 to fields.Count - 1 do
          begin
            var field: TField := fields[i];
            if field.IsNull then
              Continue;
            var cell: TRange := aSheet.Cells[row, left + i];
            case KindOf(field) of
              vkText:
                cell.AsString := field.AsString;
              vkInteger:
                cell.AsInteger := field.AsLargeInt;
              vkFloat:
                cell.AsFloat := field.AsFloat;
              vkDate:
                cell.AsDateTime := field.AsDateTime;
              vkBoolean:
                cell.AsBoolean := field.AsBoolean;
            end;
          end;
          aDataSet.Next;
        end;
      finally
        if bookmark <> nil then
        begin
          if aDataSet.BookmarkValid(bookmark) then
            aDataSet.GotoBookmark(bookmark);
          aDataSet.FreeBookmark(bookmark);
        end;
      end;
    finally
      aDataSet.EnableControls;
    end;
    if fields.Count = 0 then
      Exit(origin);
    Result := aSheet.Range[origin.Address + ':' + aSheet.Cells[row, left + fields.Count - 1].Address];
    if row > top then
      for var i := 0 to fields.Count - 1 do
      begin
        var code: string := FieldFormat(fields[i], aSheet.Workbook);
        if code <> '' then
          aSheet.Range[aSheet.Cells[top + 1, left + i].Address + ':' + aSheet.Cells[row, left + i].Address].NumberFormat := code;
      end;
    aSheet.Range[origin.Address + ':' + aSheet.Cells[top, left + fields.Count - 1].Address].Font.Bold := True;
    Result.Columns.AutoFit;
    aSheet.FreezePanes := aSheet.Cells[top + 1, 1].Address;
  finally
    fields.Free;
  end;
end;

end.
