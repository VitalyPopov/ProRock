---
icon: lucide/sheet
---

# Excel (Calcite)

Calcite reads, writes and changes Excel workbooks (.xlsx) in plain Delphi: no Excel installed, no COM, no generator. It
speaks Excel's own language - `Range`, `Cells`, `Value`, `Formula`, `NumberFormat`, `Rows`, `Columns`, `Insert`, `Delete` -
and when you change a workbook, everything you did not change is saved as it was.

```pascal
uses ProRock.Calcite;

// a new workbook, as Excel's: Sheet1 and nothing in it
var workbook := TWorkbook.Create;
try
  workbook.Worksheets[1]['A1'].Value := 'Hello, Excel';
  // Open and Save answer False and say why; they do not raise
  if not workbook.SaveAs('hello.xlsx') then
    ShowMessage(workbook.Error);
finally
  workbook.Free;
end;
```

Nothing to create first: no rows, columns or cells. Write to any cell and Calcite makes what it needs on the fly; read an
empty one and you get `Empty`, with nothing added to the file.

!!! warning "Numbered from 1, the row first - as Excel's `Cells(row, column)`"
    - `sheet.Cells[1, 1]` is A1: rows, columns and sheets count from 1
    - `Cells[row, column]`, also `Cells[5, 'B']` as Excel's `Cells(5, "B")` - not the column first as in a `TStringGrid`
    - or an address, as Excel writes it: `sheet['B5']`, `sheet['A1:C10']`

Every example below is one button of the sample [ProRock.Calcite.Basics](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Calcite.Basics):
click it, see the sheet it wrote, read its handler. In the examples `sheet` is a `TWorksheet` -
`workbook.Worksheets[1]`, `workbook.Worksheets['Prices']` or `workbook.Worksheets.Find('Prices')` - `Log` is your own
output (a memo, `Writeln`) and `fFolder` the sample's folder.

## Files

??? example "Create a workbook and save it"
    ```pascal
    var workbook := TWorkbook.Create;
    try
      var sheet := workbook.Worksheets[1];
      sheet.Name := 'Prices';
      sheet['A1'].Value := 'Item';
      sheet['B1'].Value := 'Price';
      sheet['A2'].Value := 'Coffee';
      sheet['B2'].Value := 2.5;
      sheet['A3'].Value := 'Tea';
      sheet['B3'].Value := 1.8;
      if workbook.SaveAs(fFolder + 'Prices.xlsx') then
        Log('Saved ' + workbook.FileName)
      else
        Log(workbook.Error);
    finally
      workbook.Free;
    end;
    ```

??? example "Open a workbook and read it"
    `UsedRange` is Excel's: from the first cell to the last one the sheet has. Reading never changes the file.

    ```pascal
    var workbook := TWorkbook.Create;
    try
      if not workbook.Open(fFolder + 'Prices.xlsx') then
      begin
        Log(workbook.Error); // the file is not there: Create and save first
        Exit;
      end;
      var sheet := workbook.Worksheets['Prices'];
      for var row := 2 to sheet.UsedRange.LastRow do
        Log(sheet.Cells[row, 'A'].AsString + ': ' +
          FloatToStr(sheet.Cells[row, 'B'].AsFloat));
    finally
      workbook.Free;
    end;
    ```

??? example "Open, change, save"
    Only what you change is written again: every other part of the file - charts, pictures, macros, what Calcite does not
    know - is saved as the same bytes.

    ```pascal
    var workbook := TWorkbook.Create;
    try
      if not workbook.Open(fFolder + 'Prices.xlsx') then
      begin
        Log(workbook.Error);
        Exit;
      end;
      var sheet := workbook.Worksheets[1];
      // what is not changed is saved as it was
      sheet['B2'].Value := sheet['B2'].AsFloat + 0.1;
      if workbook.Save then
        Log('Coffee costs ' + FloatToStr(sheet['B2'].AsFloat) + ' now')
      else
        Log(workbook.Error);
    finally
      workbook.Free;
    end;
    ```

??? example "Title, author and dates (File > Info)"
    `Save` sets `Modified` when anything changed, as Excel does. The dates are in UTC.

    ```pascal
    var workbook := TWorkbook.Create;
    try
      if not workbook.Open(fFolder + 'Prices.xlsx') then
      begin
        Log(workbook.Error);
        Exit;
      end;
      workbook.Properties.Title := 'Price list';
      workbook.Properties.Creator := 'The ProRock sample';
      if workbook.Save then
        Log('Title: ' + workbook.Properties.Title + ', modified ' +
          DateTimeToStr(workbook.Properties.Modified) + ' UTC')
      else
        Log(workbook.Error);
    finally
      workbook.Free;
    end;
    ```

## Values

??? example "Text, numbers, dates, booleans"
    `Value` stores what it is given: text stays text (`'00123'` is no number, `'=A1'` no formula). A date into a cell
    without a date format gets Excel's short date, which Excel shows in the user's own form (31.12.2026, 12/31/2026);
    `workbook.DateFormat := 'dd.mm.yyyy'` fixes one for everyone.

    ```pascal
    sheet['A1'].Value := 'Text';
    sheet['B1'].Value := 'Calcite';
    sheet['A2'].Value := 'Number';
    sheet['B2'].Value := 1250.5;
    sheet['A3'].Value := 'Date';
    sheet['B3'].Value := Date; // a date gets a date format, as in Excel
    sheet['A4'].Value := 'Date and time';
    sheet['B4'].Value := Now;
    sheet['A5'].Value := 'Boolean';
    sheet['B5'].Value := True;
    sheet['A6'].Value := 'Text, not a number';
    sheet['B6'].Value := '00123'; // text stays text
    ```

??? example "Read values"
    `AsString`, `AsFloat`, `AsInteger`, `AsDateTime`, `AsBoolean` read the first cell; `AsString` gives a number as invariant
    text (1250.5) and a date as ISO 8601. `ValueType` tells a date from a number, as Excel keeps both as numbers.

    ```pascal
    for var row := 1 to sheet.UsedRange.LastRow do
      Log(sheet.Cells[row, 'A'].AsString + ' = ' +
        sheet.Cells[row, 'B'].AsString);
    if sheet['B3'].ValueType = cvDate then
      Log('B3 is a date: ' + DateToStr(sheet['B3'].AsDateTime));
    ```

??? example "Cells by row and column"
    `sheet.Cells[row, column]` from 1, in Excel's order; `sheet.Cells[5, 'B']` and `sheet['B5']` are the same cell.

    ```pascal
    for var row := 1 to 5 do
      for var column := 1 to 5 do
        // D1:H5, rows and columns from 1
        sheet.Cells[row, column + 3].Value := row * column;
    ```

??? example "A block of values at once"
    A range's `Value` is a Variant array `[1..rows, 1..columns]`, read and written in one go.

    ```pascal
    var values := VarArrayCreate([1, 3, 1, 2], varVariant); // [row, column]
    values[1, 1] := 'North';
    values[1, 2] := 120;
    values[2, 1] := 'South';
    values[2, 2] := 95;
    values[3, 1] := 'West';
    values[3, 2] := 210;
    sheet['J1:K3'].Value := values;
    var block := sheet['J1:K3'].Value; // read the same way
    Log('J3 holds ' + VarToStr(block[3, 1]));
    ```

??? example "Clear contents"
    ```pascal
    sheet['D1:H5'].ClearContents; // formats stay, as in Excel
    ```

## Formulas

??? example "Write formulas"
    `Formula` is Excel's own: English function names and `,` between arguments, whatever the language of the user's Excel. A formula
    written has no value until Excel calculates it, which it does when it opens the file. One Excel would not open (a
    bracket left open, `ROUND(1)`) is refused: the cell keeps its value and `Issues` says why.

    ```pascal
    sheet['A1'].Value := 10;
    sheet['A2'].Value := 20;
    sheet['A3'].Value := 30;
    sheet['A4'].Formula := '=SUM(A1:A3)';
    sheet['B1'].Formula := '=A1*2';
    // English names and commas, as Excel's Formula
    sheet['C1'].Formula := '=IF(A4>50,"big","small")';
    Log('Excel calculates the formulas when it opens the file');
    ```

??? example "Read a formula"
    ```pascal
    if sheet['A4'].HasFormula then
      Log('A4: ' + sheet['A4'].Formula);
    ```

??? example "Array formula"
    ```pascal
    // one formula over the three cells
    sheet['E1:E3'].FormulaArray := '=A1:A3*10';
    Log('E2 is in the array ' + sheet['E2'].CurrentArray.Address);
    ```

## Formats

??? example "Number formats"
    Excel's codes, in English: `'0.00'`, `'#,##0.00'`, `'0%'`, `'dd.mm.yyyy'`, `'@'` for text. Excel shows them with
    the separators of the user's language: `'#,##0.00'` is 1,234.50 in English, 1.234,50 in German.

    ```pascal
    sheet['A1'].Value := 1234.5;
    sheet['A1'].NumberFormat := '#,##0.00';
    sheet['A2'].Value := 0.25;
    sheet['A2'].NumberFormat := '0%';
    sheet['A3'].Value := Date;
    sheet['A3'].NumberFormat := 'dd.mm.yyyy';
    // text: Excel takes what is typed there as it is
    sheet['A4'].NumberFormat := '@';
    sheet['A4'].Value := '2026-11-27';
    ```

??? example "Font"
    `Font.Style := [fsBold, fsItalic]` sets the four styles at once, as Delphi's `TFont`.

    ```pascal
    sheet['C1'].Value := 'Bold';
    sheet['C1'].Font.Bold := True;
    sheet['C2'].Value := 'Italic red';
    sheet['C2'].Font.Style := [fsItalic];
    sheet['C2'].Font.Color := clRed;
    sheet['C3'].Value := 'Consolas 14';
    sheet['C3'].Font.Name := 'Consolas';
    sheet['C3'].Font.Size := 14;
    ```

??? example "Fill"
    Colors are `TColor`, Excel's own order: `clYellow`, `RGB(...)`. `clNone` removes the fill.

    ```pascal
    sheet['E1:E3'].Interior.Color := clYellow;
    // TColor, as Excel's Color
    sheet['E2'].Interior.Color := RGB(198, 239, 206);
    ```

??? example "Borders"
    ```pascal
    // every edge, the inside ones too
    sheet['A6:E8'].Borders.LineStyle := lsContinuous;
    sheet['A6:E8'].BorderAround(lsContinuous, bwMedium);
    sheet['A6:E6'].Borders[beBottom].LineStyle := lsDouble;
    ```

??? example "Alignment and wrap"
    ```pascal
    sheet['G1'].Value := 'Centered';
    sheet['G1'].HorizontalAlignment := haCenter;
    sheet['G2'].Value := 'A long text wrapped in its cell';
    sheet['G2'].WrapText := True;
    sheet['G2'].VerticalAlignment := vaTop;
    ```

??? example "Merge cells"
    The first value stays in the top-left cell, as in Excel; `UnMerge` splits the area again.

    ```pascal
    sheet['A10'].Value := 'A title over five columns';
    sheet['A10:E10'].Merge;
    sheet['A10'].HorizontalAlignment := haCenter;
    Log('C10 is in the merged area ' + sheet['C10'].MergeArea.Address);
    ```

??? example "A range, a row, a column"
    Every format works on a range, a whole row or a whole column, as Excel's `Range` does: one write formats every cell.
    Read from a range with mixed formats, a property gives its first cell's.

    ```pascal
    sheet['A12:D12'].Value := VarArrayOf(['North', 'South', 'East', 'West']);
    // one write formats every cell of the range
    sheet['A12:D12'].Font.Bold := True;
    sheet['A12:D12'].HorizontalAlignment := haCenter;
    sheet['A13:D14'].Value := 1250.5;
    sheet['A13:D14'].NumberFormat := '#,##0.00';
    // a whole row or column: cells written there later get it too, as in Excel
    sheet.Rows[15].Interior.Color := clSilver;
    sheet.Columns['F'].NumberFormat := '0.0%';
    sheet['F13'].Value := 0.125;
    sheet['A15'].Value := 'A whole row';
    ```

## Rows and columns

`Insert` and `Delete` work on whole rows and columns, as Excel's: cells, formulas on every sheet, merged areas,
conditional formats, validation, tables, charts and notes move as Excel moves them. What Excel refuses raises
`EInvalidOpException` with nothing changed (see [Errors and issues](#errors-and-issues)).

??? example "Insert rows"
    ```pascal
    // formulas follow, as in Excel: the total's SUM grows
    sheet.Rows['3:4'].Insert;
    var used := sheet.UsedRange;
    var total := sheet.Cells[used.LastRow, used.LastColumn];
    Log('The total in ' + total.Address + ': ' + total.Formula);
    ```

??? example "Delete rows"
    ```pascal
    sheet.Rows['3:4'].Delete;
    var used := sheet.UsedRange;
    var total := sheet.Cells[used.LastRow, used.LastColumn];
    Log('The total in ' + total.Address + ': ' + total.Formula);
    ```

??? example "Insert a column"
    ```pascal
    sheet.Columns['B'].Insert;
    sheet['B1'].Value := 'Inserted';
    var used := sheet.UsedRange;
    // the formulas moved right with their cells
    var amount := sheet.Cells[2, used.LastColumn];
    Log(amount.Address + ': ' + amount.Formula);
    ```

??? example "Hide a column"
    `Hidden` works on whole rows and columns (`sheet.Rows[5]`, `sheet['B5'].EntireColumn`), as in Excel.

    ```pascal
    sheet.Columns['C'].Hidden := not sheet.Columns['C'].Hidden;
    ```

??? example "Width and height"
    ```pascal
    sheet.Columns['A'].ColumnWidth := 20; // characters
    sheet.Rows[1].RowHeight := 24; // points
    ```

??? example "AutoFit"
    Calcite measures no fonts: the widths are Excel's for Latin letters, digits and signs in Calibri and Aptos Narrow, close
    for others. `Rows.AutoFit` leaves the heights to Excel, which fits them when it opens the file.

    ```pascal
    sheet.UsedRange.Columns.AutoFit;
    ```

??? example "Freeze the header"
    ```pascal
    sheet.FreezePanes := 'A2'; // the first row stays put
    Log('Frozen above and left of ' + sheet.FreezePanes);
    ```

## Sheets

??? example "Add a sheet"
    `Add('Report')` names it; a name Excel would not open (over 31 characters, `[ ] : * ? / \`, taken) gets the next
    `SheetN` and an issue. A sheet added here can be renamed until formulas are written.

    ```pascal
    // Excel's next name: Sheet2, Sheet3...
    var sheet := fWorkbook.Worksheets.Add;
    sheet['A1'].Value := 'Added as ' + sheet.Name;
    ```

??? example "List the sheets"
    ```pascal
    for var sheet in fWorkbook.Worksheets do
      if sheet.Visible = svVisible then
        Log(sheet.Name)
      else
        Log(sheet.Name + ' (hidden)');
    ```

??? example "Hide a sheet"
    `svVeryHidden` hides it from Excel's Unhide too.

    ```pascal
    var sheet := fWorkbook.Worksheets[fWorkbook.Worksheets.Count];
    try
      sheet.Visible := svHidden;
      Log(sheet.Name + ' hidden');
    except
      on E: EInvalidOpException do
        Log(E.Message); // the last visible sheet stays, as in Excel
    end;
    ```

??? example "Delete a sheet"
    ```pascal
    var sheet := fWorkbook.Worksheets[fWorkbook.Worksheets.Count];
    var deleted := sheet.Name;
    try
      sheet.Delete; // formulas naming it become #REF!, as in Excel
      Log(deleted + ' deleted');
    except
      on E: EInvalidOpException do
        Log(E.Message); // the last visible sheet stays, as in Excel
    end;
    ```

## A DataSet to a sheet

??? example "Export a DataSet"
    In `ProRock.Calcite.Data`: the visible fields with their `DisplayLabel`, each value as its type, a number format from the
    field (`DisplayFormat`, currency, a date's kind). `ExportDataSet(Query, sheet, 'B3')` starts elsewhere.

    ```pascal
    // a bold header, a row a record, the columns fitted, the header frozen
    var exported := ExportDataSet(fOrders, sheet);
    Log('Exported to ' + exported.Address);
    ```

## Errors and issues

!!! success "Calcite's three promises"
    - **The file stays valid**: Excel opens it without a repair prompt.
    - **Nothing is lost silently**: what Calcite does not know is saved as it was, or the change is refused and reported.
    - **Every request is done or reported**: a refusal is an issue or an exception, never silence.

How it reports:

- `Open` and `Save` answer `False` and say why in `Error`: a file that is not there, open in Excel, not a workbook. They
  do not raise.
- Calcite refuses a write Excel would refuse: the cell keeps its value, and `Workbook.Issues` gets an Error.
- `Insert`, `Delete` and `Sheet.Delete` raise `EInvalidOpException` with nothing changed where Excel refuses (and list an
  Error too): your next addresses would be wrong otherwise.
- A programming mistake raises, as in a list: `Worksheets[9]` of three sheets, an address like `'B'`.

??? example "A refused write"
    ```pascal
    // a bracket missing: Calcite refuses it, as Excel would; an issue tells why
    sheet['A1'].Formula := '=SUM(B1:B3';
    // Issues: every one since Open, the newest last
    Log(fWorkbook.Issues[fWorkbook.Issues.Count - 1].ToString);
    ```

??? example "Issues as they come"
    ```pascal
    fWorkbook.OnIssue :=
      procedure(const aIssue: TIssue)
      begin
        Log('As it comes: ' + aIssue.ToString);
      end;
    Log('Issues are logged as they come now');
    ```

??? example "A file that will not open"
    ```pascal
    var workbook := TWorkbook.Create;
    try
      if not workbook.Open(fFolder + 'No such file.xlsx') then
        // Open and Save answer False and Error; they never raise
        Log(workbook.Error);
    finally
      workbook.Free;
    end;
    ```

??? example "A refused insert"
    ```pascal
    sheet['XFD1'].Value := 'The last column';
    try
      sheet.Columns['B'].Insert; // would push XFD1 off the sheet
    except
      on E: EInvalidOpException do
        Log('Refused, nothing changed: ' + E.Message);
    end;
    ```

## The xlsx objects

For what Calcite does not cover yet, `workbook.Xlsx` and `sheet.Xlsx` hand out the file's own objects, typed from the
official SpreadsheetML schemas. Calcite reads them back after your change.

!!! warning "At your own risk"
    Nothing checks what you write there: a wrong value can make Excel refuse the file.

??? example "A sheet tab color"
    ```pascal
    sheet['A1'].Value := 'This sheet''s tab is red';
    sheet.Xlsx.Worksheet.SheetPr.TabColor.Rgb := 'FFC00000'; // ARGB
    ```

## Current limitations

Calcite grows by what users need: [open an issue](https://github.com/VitalyPopov/ProRock/issues/new/choose) with what
you miss, and a file that shows it if you can.

- xlsx only (and .xlsm, .xltx, .xltm); no .xls, .ods or .csv
- no calculation: Excel calculates formulas when it opens the file
- inserting or deleting rows and columns on a sheet with Excel 2010's conditional formats, validation or sparklines,
  threaded comments, embedded objects or controls, Excel 2016's chart kinds, or a table from an XML map: Calcite cannot
  move those yet, so it refuses the change and leaves the sheet as it was; the same for deleting a sheet with slicers or
  timelines
- cells shifted within rows or columns, copy and paste, defined names: later
