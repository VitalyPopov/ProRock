unit ProRock.Calcite.Formulas;

// Excel's formula language: its functions, a formula read, checked and its references moved (internal)

interface

uses ProRock.Calcite.Utility;

// Excel's A1 formula text (without the =) as a file stores it. False with aWhy when Excel would not read it: a broken
// formula makes Excel refuse the whole file, even repaired. Checked: the grammar (values and operators in turn, brackets,
// arguments, array constants), the number of arguments Excel's own functions take (ROUND(1), SUM()) and a reference where one
// must stand (ROW(1)); an unknown function or name is Excel's #NAME?, the first unknown function aUnknown (a VBA or add-in one
// is unknown too). Without its prefix a file Excel refuses (FILTER) or shows #NAME? (XLOOKUP, LET's x): the stored form adds
// the prefixes, Excel's own functions in upper case
function StoredFormula(const aFormula: string; out aResult, aWhy, aUnknown: string): boolean;

// a formula's references changed by aMap (moved as Excel fills, or for rows or columns inserted or deleted, or a sheet
// deleted), one off the sheet or deleted becomes #REF!; the text between them as it was, aResult aFormula itself when nothing
// changes. Not checked (StoredFormula): False with aWhy (aResult aFormula) only when it does not read as a formula's pieces
function ShiftFormula(const aFormula: string; const aMap: TReferenceMap; out aResult, aWhy: string): boolean;

// a stored formula as Excel's Formula shows it (prefixes dropped); as it is when it does not read
function ShownFormula(const aStored: string): string;

// how a formula on aFormulaSheet ('' for a defined name's) changes with rows or columns of aSheet inserted (aCount > 0) or
// deleted from aFirst
function ShiftMap(const aFormulaSheet, aSheet: string; aByRows: boolean; aFirst, aCount: integer): TReferenceMap;

implementation

uses System.SysUtils, System.Math, System.Character, System.Generics.Collections;

type
  // a formula's text as a file stores it (_xlfn.XLOOKUP, LET's _xlpm.x) or as Excel's Formula shows it (XLOOKUP, x)
  TFormulaForm = (ffStored, ffShown);

  // one of Excel's functions: the argument counts it takes (those over Paired come in pairs: SUMIFS 3, 5, 7...; none when
  // Min is over Max: CALL), the prefix a file stores it with (cFunctionPrefixes), the arguments that must be references
  // (r; v - a value too; past its end the last one repeats, or the last two when paired), whether it may give one
  TExcelFunction = record
    Name: string;
    Min, Max, Paired, Prefix: byte;
    References: string;
    ReferenceResult: boolean;
  end;

const
  cErrors: array [0 .. 9] of string = ('#NULL!', '#DIV/0!', '#VALUE!', '#REF!', '#NAME?', '#NUM!', '#N/A', '#GETTING_DATA',
    '#SPILL!', '#CALC!');
  cParameterPrefix = '_xlpm.';
  cFunctionPrefixes: array [0 .. 2] of string = ('', '_xlfn.', '_xlfn._xlws.');
  // Excel's functions, made from Excel itself (each count tried, a saved file read): not edited by hand
  cFunctionCount = 518;
  cLetFunction = 277;
  cLambdaFunction = 270;
  {$REGION 'Excel functions'}
  cFunctions: array [0 .. cFunctionCount - 1] of TExcelFunction = (
  (Name: 'ABS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ACCRINT'; Min: 6; Max: 8; Paired: 8; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ACCRINTM'; Min: 4; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ACOS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ACOSH'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ACOT'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'ACOTH'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'ADDRESS'; Min: 2; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'AGGREGATE'; Min: 3; Max: 254; Paired: 254; Prefix: 1; References: 'vvvvrrr'; ReferenceResult: False),
  (Name: 'AMORDEGRC'; Min: 6; Max: 7; Paired: 7; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'AMORLINC'; Min: 6; Max: 7; Paired: 7; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'AND'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ARABIC'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'AREAS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: 'r'; ReferenceResult: False),
  (Name: 'ARRAYTOTEXT'; Min: 1; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'ASC'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ASIN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ASINH'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ATAN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ATAN2'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ATANH'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'AVEDEV'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'AVERAGE'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'AVERAGEA'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'AVERAGEIF'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: 'rvr'; ReferenceResult: False),
  (Name: 'AVERAGEIFS'; Min: 3; Max: 255; Paired: 3; Prefix: 0; References: 'rrvrvrv'; ReferenceResult: False),
  (Name: 'BAHTTEXT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BASE'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BESSELI'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BESSELJ'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BESSELK'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BESSELY'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BETA.DIST'; Min: 4; Max: 6; Paired: 6; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BETADIST'; Min: 3; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BETAINV'; Min: 3; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BIN2DEC'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BIN2HEX'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BIN2OCT'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BINOM.DIST'; Min: 4; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BINOM.DIST.RANGE'; Min: 3; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BINOM.INV'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BINOMDIST'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'BITAND'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BITLSHIFT'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BITOR'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BITRSHIFT'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BITXOR'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BYCOL'; Min: 1; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'BYROW'; Min: 1; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CALL'; Min: 1; Max: 0; Paired: 0; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CEILING'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CEILING.MATH'; Min: 1; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CEILING.PRECISE'; Min: 1; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CELL'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: 'vr'; ReferenceResult: False),
  (Name: 'CHAR'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CHIDIST'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CHIINV'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CHISQ.DIST'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CHISQ.DIST.RT'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CHISQ.INV'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CHISQ.INV.RT'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CHISQ.TEST'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CHITEST'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CHOOSE'; Min: 2; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: True),
  (Name: 'CHOOSECOLS'; Min: 2; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CHOOSEROWS'; Min: 2; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CLEAN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CODE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COLUMN'; Min: 0; Max: 1; Paired: 1; Prefix: 0; References: 'r'; ReferenceResult: False),
  (Name: 'COLUMNS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COMBIN'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COMBINA'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'COMPLEX'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CONCAT'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CONCATENATE'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CONFIDENCE'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CONFIDENCE.NORM'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CONFIDENCE.T'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CONVERT'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CORREL'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COSH'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COT'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'COTH'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'COUNT'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COUNTA'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COUNTBLANK'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: 'r'; ReferenceResult: False),
  (Name: 'COUNTIF'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: 'rv'; ReferenceResult: False),
  (Name: 'COUNTIFS'; Min: 2; Max: 254; Paired: 2; Prefix: 0; References: 'rvrvrv'; ReferenceResult: False),
  (Name: 'COUPDAYBS'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COUPDAYS'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COUPDAYSNC'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COUPNCD'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COUPNUM'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COUPPCD'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COVAR'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'COVARIANCE.P'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'COVARIANCE.S'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CRITBINOM'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CSC'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CSCH'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'CUBEKPIMEMBER'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CUBEMEMBER'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CUBEMEMBERPROPERTY'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CUBERANKEDMEMBER'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CUBESET'; Min: 2; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CUBESETCOUNT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CUBEVALUE'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CUMIPMT'; Min: 6; Max: 6; Paired: 6; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'CUMPRINC'; Min: 6; Max: 6; Paired: 6; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DATE'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DATEDIF'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DATEVALUE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DAVERAGE'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DAY'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DAYS'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'DAYS360'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DB'; Min: 4; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DBCS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DCOUNT'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DCOUNTA'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DDB'; Min: 4; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DEC2BIN'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DEC2HEX'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DEC2OCT'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DECIMAL'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'DEGREES'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DELTA'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DETECTLANGUAGE'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'DEVSQ'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DGET'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DISC'; Min: 4; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DMAX'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DMIN'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DOLLAR'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DOLLARDE'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DOLLARFR'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DPRODUCT'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DROP'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: True),
  (Name: 'DSTDEV'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DSTDEVP'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DSUM'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DURATION'; Min: 5; Max: 6; Paired: 6; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'DVAR'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'DVARP'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: 'rvv'; ReferenceResult: False),
  (Name: 'EDATE'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'EFFECT'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ENCODEURL'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'EOMONTH'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ERF'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ERF.PRECISE'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'ERFC'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ERFC.PRECISE'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'ERROR.TYPE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'EUROCONVERT'; Min: 0; Max: 254; Paired: 254; Prefix: 0; References: ''; ReferenceResult: True),
  (Name: 'EVEN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'EXACT'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'EXP'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'EXPAND'; Min: 2; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'EXPON.DIST'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'EXPONDIST'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'F.DIST'; Min: 4; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'F.DIST.RT'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'F.INV'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'F.INV.RT'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'F.TEST'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'FACT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FACTDOUBLE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FALSE'; Min: 0; Max: 0; Paired: 0; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FDIST'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FILTER'; Min: 2; Max: 3; Paired: 3; Prefix: 2; References: ''; ReferenceResult: False),
  (Name: 'FILTERXML'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'FINV'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FISHER'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FISHERINV'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FIXED'; Min: 1; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FLOOR'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FLOOR.MATH'; Min: 1; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'FLOOR.PRECISE'; Min: 1; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'FORECAST'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FORECAST.ETS'; Min: 3; Max: 6; Paired: 6; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'FORECAST.ETS.CONFINT'; Min: 3; Max: 7; Paired: 7; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'FORECAST.ETS.SEASONALITY'; Min: 2; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'FORECAST.ETS.STAT'; Min: 3; Max: 6; Paired: 6; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'FORECAST.LINEAR'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'FORMULATEXT'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: 'r'; ReferenceResult: False),
  (Name: 'FREQUENCY'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FTEST'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FV'; Min: 3; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'FVSCHEDULE'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'GAMMA'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'GAMMA.DIST'; Min: 4; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'GAMMA.INV'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'GAMMADIST'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'GAMMAINV'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'GAMMALN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'GAMMALN.PRECISE'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'GAUSS'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'GCD'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'GEOMEAN'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'GESTEP'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'GETPIVOTDATA'; Min: 2; Max: 254; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'GROUPBY'; Min: 3; Max: 8; Paired: 8; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'GROWTH'; Min: 1; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'HARMEAN'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'HEX2BIN'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'HEX2DEC'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'HEX2OCT'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'HLOOKUP'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'HOUR'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'HSTACK'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'HYPERLINK'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'HYPGEOM.DIST'; Min: 5; Max: 5; Paired: 5; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'HYPGEOMDIST'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IF'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: True),
  (Name: 'IFERROR'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IFNA'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'IFS'; Min: 2; Max: 254; Paired: 2; Prefix: 1; References: ''; ReferenceResult: True),
  (Name: 'IMABS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMAGE'; Min: 1; Max: 5; Paired: 5; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'IMAGINARY'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMARGUMENT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMCONJUGATE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMCOS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMCOSH'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'IMCOT'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'IMCSC'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'IMCSCH'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'IMDIV'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMEXP'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMLN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMLOG10'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMLOG2'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMPOWER'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMPRODUCT'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMREAL'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMSEC'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'IMSECH'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'IMSIN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMSINH'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'IMSQRT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMSUB'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMSUM'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IMTAN'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'INDEX'; Min: 2; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: True),
  (Name: 'INDIRECT'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: True),
  (Name: 'INFO'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'INT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'INTERCEPT'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'INTRATE'; Min: 4; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IPMT'; Min: 4; Max: 6; Paired: 6; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'IRR'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISBLANK'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISERR'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISERROR'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISEVEN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISFORMULA'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: 'r'; ReferenceResult: False),
  (Name: 'ISLOGICAL'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISNA'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISNONTEXT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISNUMBER'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISO.CEILING'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISODD'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISOMITTED'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'ISOWEEKNUM'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'ISPMT'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISREF'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ISTEXT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'JIS'; Min: 0; Max: 254; Paired: 254; Prefix: 0; References: ''; ReferenceResult: True),
  (Name: 'KURT'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LAMBDA'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: True),
  (Name: 'LARGE'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LCM'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LEFT'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LEFTB'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LEN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LENB'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LET'; Min: 3; Max: 253; Paired: 3; Prefix: 1; References: ''; ReferenceResult: True),
  (Name: 'LINEST'; Min: 1; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LOG'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LOG10'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LOGEST'; Min: 1; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LOGINV'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LOGNORM.DIST'; Min: 4; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'LOGNORM.INV'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'LOGNORMDIST'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LOOKUP'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'LOWER'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MAKEARRAY'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'MAP'; Min: 2; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'MATCH'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MAX'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MAXA'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MAXIFS'; Min: 3; Max: 253; Paired: 3; Prefix: 1; References: 'rrvrvrv'; ReferenceResult: False),
  (Name: 'MDETERM'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MDURATION'; Min: 5; Max: 6; Paired: 6; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MEDIAN'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MID'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MIDB'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MIN'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MINA'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MINIFS'; Min: 3; Max: 253; Paired: 3; Prefix: 1; References: 'rrvrvrv'; ReferenceResult: False),
  (Name: 'MINUTE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MINVERSE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MIRR'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MMULT'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MOD'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MODE'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MODE.MULT'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'MODE.SNGL'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'MONTH'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MROUND'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MULTINOMIAL'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'MUNIT'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'N'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NA'; Min: 0; Max: 0; Paired: 0; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NEGBINOM.DIST'; Min: 4; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'NEGBINOMDIST'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NETWORKDAYS'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NETWORKDAYS.INTL'; Min: 2; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NOMINAL'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NORM.DIST'; Min: 4; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'NORM.INV'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'NORM.S.DIST'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'NORM.S.INV'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'NORMDIST'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NORMINV'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NORMSDIST'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NORMSINV'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NOT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NOW'; Min: 0; Max: 0; Paired: 0; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NPER'; Min: 3; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NPV'; Min: 2; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'NUMBERVALUE'; Min: 1; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'OCT2BIN'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'OCT2DEC'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'OCT2HEX'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ODD'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ODDFPRICE'; Min: 8; Max: 9; Paired: 9; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ODDFYIELD'; Min: 8; Max: 9; Paired: 9; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ODDLPRICE'; Min: 7; Max: 8; Paired: 8; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ODDLYIELD'; Min: 7; Max: 8; Paired: 8; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'OFFSET'; Min: 3; Max: 5; Paired: 5; Prefix: 0; References: 'rvvvv'; ReferenceResult: True),
  (Name: 'OR'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PDURATION'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'PEARSON'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PERCENTILE'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PERCENTILE.EXC'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'PERCENTILE.INC'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'PERCENTOF'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'PERCENTRANK'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PERCENTRANK.EXC'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'PERCENTRANK.INC'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'PERMUT'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PERMUTATIONA'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'PHI'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'PHONETIC'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: 'r'; ReferenceResult: False),
  (Name: 'PI'; Min: 0; Max: 0; Paired: 0; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PIVOTBY'; Min: 4; Max: 11; Paired: 11; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'PMT'; Min: 3; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'POISSON'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'POISSON.DIST'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'POWER'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PPMT'; Min: 4; Max: 6; Paired: 6; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PRICE'; Min: 6; Max: 7; Paired: 7; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PRICEDISC'; Min: 4; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PRICEMAT'; Min: 5; Max: 6; Paired: 6; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PROB'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PRODUCT'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PROPER'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'PV'; Min: 3; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'QUARTILE'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'QUARTILE.EXC'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'QUARTILE.INC'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'QUOTIENT'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'RADIANS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'RAND'; Min: 0; Max: 0; Paired: 0; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'RANDARRAY'; Min: 0; Max: 5; Paired: 5; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'RANDBETWEEN'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'RANK'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: 'vrv'; ReferenceResult: False),
  (Name: 'RANK.AVG'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: 'vrv'; ReferenceResult: False),
  (Name: 'RANK.EQ'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: 'vrv'; ReferenceResult: False),
  (Name: 'RATE'; Min: 3; Max: 6; Paired: 6; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'RECEIVED'; Min: 4; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'REDUCE'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: True),
  (Name: 'REGEXEXTRACT'; Min: 2; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'REGEXREPLACE'; Min: 3; Max: 5; Paired: 5; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'REGEXTEST'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'REGISTER.ID'; Min: 1; Max: 0; Paired: 0; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'REPLACE'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'REPLACEB'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'REPT'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'RIGHT'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'RIGHTB'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ROMAN'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ROUND'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ROUNDDOWN'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ROUNDUP'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'ROW'; Min: 0; Max: 1; Paired: 1; Prefix: 0; References: 'r'; ReferenceResult: False),
  (Name: 'ROWS'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'RRI'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'RSQ'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'RTD'; Min: 3; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SCAN'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'SEARCH'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SEARCHB'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SEC'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'SECH'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'SECOND'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SEQUENCE'; Min: 1; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'SERIESSUM'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SHEET'; Min: 0; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'SHEETS'; Min: 0; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'SIGN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SIN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SINH'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SKEW'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SKEW.P'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'SLN'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SLOPE'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SMALL'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SORT'; Min: 1; Max: 4; Paired: 4; Prefix: 2; References: ''; ReferenceResult: False),
  (Name: 'SORTBY'; Min: 2; Max: 253; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'SQRT'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SQRTPI'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'STANDARDIZE'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'STDEV'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'STDEV.P'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'STDEV.S'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'STDEVA'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'STDEVP'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'STDEVPA'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'STEYX'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'STOCKHISTORY'; Min: 2; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'SUBSTITUTE'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SUBTOTAL'; Min: 2; Max: 255; Paired: 255; Prefix: 0; References: 'vrrrrr'; ReferenceResult: False),
  (Name: 'SUM'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SUMIF'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: 'rvr'; ReferenceResult: False),
  (Name: 'SUMIFS'; Min: 3; Max: 255; Paired: 3; Prefix: 0; References: 'rrvrvrv'; ReferenceResult: False),
  (Name: 'SUMPRODUCT'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SUMSQ'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SUMX2MY2'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SUMX2PY2'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SUMXMY2'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'SWITCH'; Min: 3; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: True),
  (Name: 'SYD'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'T'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'T.DIST'; Min: 3; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'T.DIST.2T'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'T.DIST.RT'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'T.INV'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'T.INV.2T'; Min: 2; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'T.TEST'; Min: 4; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'TAKE'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: True),
  (Name: 'TAN'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TANH'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TBILLEQ'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TBILLPRICE'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TBILLYIELD'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TDIST'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TEXT'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TEXTAFTER'; Min: 2; Max: 6; Paired: 6; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'TEXTBEFORE'; Min: 2; Max: 6; Paired: 6; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'TEXTJOIN'; Min: 3; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'TEXTSPLIT'; Min: 2; Max: 6; Paired: 6; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'TIME'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TIMEVALUE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TINV'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TOCOL'; Min: 1; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'TODAY'; Min: 0; Max: 0; Paired: 0; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TOROW'; Min: 1; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'TRANSLATE'; Min: 1; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'TRANSPOSE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TREND'; Min: 1; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TRIM'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TRIMMEAN'; Min: 2; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TRIMRANGE'; Min: 1; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: True),
  (Name: 'TRUE'; Min: 0; Max: 0; Paired: 0; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TRUNC'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TTEST'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'TYPE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'UNICHAR'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'UNICODE'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'UNIQUE'; Min: 1; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'UPPER'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'VALUE'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'VALUETOTEXT'; Min: 1; Max: 2; Paired: 2; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'VAR'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'VAR.P'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'VAR.S'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'VARA'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'VARP'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'VARPA'; Min: 1; Max: 255; Paired: 255; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'VDB'; Min: 5; Max: 7; Paired: 7; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'VLOOKUP'; Min: 3; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'VSTACK'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'WEBSERVICE'; Min: 1; Max: 1; Paired: 1; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'WEEKDAY'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'WEEKNUM'; Min: 1; Max: 2; Paired: 2; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'WEIBULL'; Min: 4; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'WEIBULL.DIST'; Min: 4; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'WORKDAY'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'WORKDAY.INTL'; Min: 2; Max: 4; Paired: 4; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'WRAPCOLS'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'WRAPROWS'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'XIRR'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'XLOOKUP'; Min: 3; Max: 6; Paired: 6; Prefix: 1; References: ''; ReferenceResult: True),
  (Name: 'XMATCH'; Min: 2; Max: 4; Paired: 4; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'XNPV'; Min: 3; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'XOR'; Min: 1; Max: 254; Paired: 254; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'YEAR'; Min: 1; Max: 1; Paired: 1; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'YEARFRAC'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'YIELD'; Min: 6; Max: 7; Paired: 7; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'YIELDDISC'; Min: 4; Max: 5; Paired: 5; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'YIELDMAT'; Min: 5; Max: 6; Paired: 6; Prefix: 0; References: ''; ReferenceResult: False),
  (Name: 'Z.TEST'; Min: 2; Max: 3; Paired: 3; Prefix: 1; References: ''; ReferenceResult: False),
  (Name: 'ZTEST'; Min: 2; Max: 3; Paired: 3; Prefix: 0; References: ''; ReferenceResult: False)
  );
  {$ENDREGION}

// aName against aText[aStart .. aFinish - 1] as CompareText orders them: ASCII letters in either case
function CompareSpan(const aName, aText: string; aStart, aFinish: integer): integer;
begin
  var count: integer := aFinish - aStart;
  for var i := 1 to Min(aName.Length, count) do
  begin
    var one: Char := aName[i];
    var other: Char := aText[aStart + i - 1];
    if CharInSet(one, ['a' .. 'z']) then
      one := Char(Ord(one) - 32);
    if CharInSet(other, ['a' .. 'z']) then
      other := Char(Ord(other) - 32);
    if one <> other then
      Exit(Ord(one) - Ord(other));
  end;
  Result := aName.Length - count;
end;

// whether aText[aStart .. aFinish - 1] begins with aWord, ASCII letters in either case
function StartsWithWord(const aText: string; aStart, aFinish: integer; const aWord: string): boolean;
begin
  Result := (aFinish - aStart >= aWord.Length) and (CompareSpan(aWord, aText, aStart, aStart + aWord.Length) = 0);
end;

// whether aText[aStart .. aFinish - 1] is aWord, ASCII letters in either case
function IsWord(const aText: string; aStart, aFinish: integer; const aWord: string): boolean;
begin
  Result := (aFinish - aStart = aWord.Length) and (CompareSpan(aWord, aText, aStart, aFinish) = 0);
end;

// Excel's function by its name without a prefix (aText[aStart .. aFinish - 1]), in any case; -1 when it is none of them
function FindFunction(const aText: string; aStart, aFinish: integer): integer; overload;
begin
  var low: integer := 0;
  var high: integer := cFunctionCount - 1;
  while low <= high do
  begin
    Result := (low + high) div 2;
    var order: integer := CompareSpan(cFunctions[Result].Name, aText, aStart, aFinish); // ASCII only: no SUMME, no СУММ
    if order = 0 then
      Exit
    else if order < 0 then
      low := Result + 1
    else
      high := Result - 1;
  end;
  Result := -1;
end;

function FindFunction(const aName: string): integer; overload;
begin
  Result := FindFunction(aName, 1, aName.Length + 1);
end;

function IsFormulaSpace(aChar: Char): boolean;
begin
  Result := CharInSet(aChar, [' ', #9, #10, #13]);
end;

function IsWordStart(aChar: Char): boolean;
begin
  Result := aChar.IsLetterOrDigit or CharInSet(aChar, ['_', '\', '$', '.']);
end;

type
  TFormulaTokenKind = (fkSpace, fkNumber, fkText, fkLogical, fkError, fkReference, fkName, fkFunction, fkTable, fkOperator,
    fkOpen, fkClose, fkArrayOpen, fkArrayClose, fkComma, fkSemicolon, fkPercent);

  // a formula's piece at Start .. Finish - 1: a function's name without its (, a table's name with its [...]. A reference, a
  // name or an error after a prefix (Sheet1!, 'My Sheet'!, [1]Sheet1!, Sheet1:Sheet3!, [1]!) has it at Prefix .. Bang - 1,
  // its ! at Bang, spaces may stand between the ! and Start; Prefix 0 when it has none
  TFormulaToken = record
    Kind: TFormulaTokenKind;
    Start, Finish, Prefix, Bang: integer;
    Reference: TReference; // a reference's ends
    NameFinish: integer; // a table's: where its [ begins (Start for one without its name: [@Sales])
  end;

  // a formula's pieces in turn, each told by the characters around it, never by the grammar: whether the pieces stand right
  // and what a name means in its place (LET's parameter) is a walk's. Nothing allocated
  TFormulaScanner = record
  private
    fText: string;
    fIndex, fLast: integer;
    function Fail(const aWhy: string): boolean;
    function WordEnd(aFrom: integer): integer;
    function ClosingQuote(aFrom: integer): integer;
    function ClosingBracket(aFrom: integer): integer;
    function SheetBang(aFrom: integer): integer;
    function QuotedBang(aFrom: integer; out aBang: integer): boolean;
    function Prefixed(var aToken: TFormulaToken; aBang: integer): boolean;
    function ErrorValue(var aToken: TFormulaToken): boolean;
    function Word(var aToken: TFormulaToken): boolean;
  public
    Error: string; // why reading stopped; '' at the formula's end
    constructor Create(const aFormula: string);
    // False at the end or when the text reads no further (Error)
    function Next(out aToken: TFormulaToken): boolean;
  end;

constructor TFormulaScanner.Create(const aFormula: string);
begin
  fText := aFormula;
  fIndex := 1;
  fLast := aFormula.Length;
  Error := '';
end;

function TFormulaScanner.Fail(const aWhy: string): boolean;
begin
  Error := aWhy;
  fIndex := fLast + 1;
  Result := False;
end;

function TFormulaScanner.WordEnd(aFrom: integer): integer;
begin
  Result := aFrom;
  while (Result <= fLast) and (fText[Result].IsLetterOrDigit or CharInSet(fText[Result], ['_', '\', '$', '.', '?'])) do
    Inc(Result);
end;

// the closing quote of the one at aFrom (a doubled one is inside), 0 when there is none
function TFormulaScanner.ClosingQuote(aFrom: integer): integer;
begin
  var quote: Char := fText[aFrom];
  Result := aFrom + 1;
  while Result <= fLast do
  begin
    if fText[Result] = quote then
    begin
      if (Result < fLast) and (fText[Result + 1] = quote) then
        Inc(Result)
      else
        Exit;
    end;
    Inc(Result);
  end;
  Result := 0;
end;

// the ] closing the [ at aFrom (nested ones inside, ' escaping the character after it), 0 when there is none
function TFormulaScanner.ClosingBracket(aFrom: integer): integer;
begin
  var depth: integer := 0;
  Result := aFrom;
  while Result <= fLast do
  begin
    case fText[Result] of
      '''':
        Inc(Result);
      '[':
        Inc(depth);
      ']':
        begin
          Dec(depth);
          if depth = 0 then
            Exit;
        end;
    end;
    Inc(Result);
  end;
  Result := 0;
end;

// the ! after a sheet's name that is a word from aFrom (Sheet1!, or Sheet1:Sheet3! - not from a cell: A3:Sheet1!A5 is a
// range, Excel quotes a sheet named like a cell); 0 when the word names no sheet
function TFormulaScanner.SheetBang(aFrom: integer): integer;
var
  row, column: integer;
  rowFixed, columnFixed: boolean;
begin
  Result := WordEnd(aFrom);
  if (Result <= fLast) and (fText[Result] = '!') then
    Exit;
  if (Result < fLast) and (fText[Result] = ':') and IsWordStart(fText[Result + 1]) and
    (TUtility.ReadReference(fText, aFrom, Result, row, column, rowFixed, columnFixed) <> TReferenceKind.rkCell) then
  begin
    Result := WordEnd(Result + 1);
    if (Result <= fLast) and (fText[Result] = '!') then
      Exit;
  end;
  Result := 0;
end;

// a quoted sheet's name at aFrom, its ! (aBang) after it
function TFormulaScanner.QuotedBang(aFrom: integer; out aBang: integer): boolean;
begin
  var close: integer := ClosingQuote(aFrom);
  if close = 0 then
    Exit(Fail('a sheet name without its closing quote'));
  if (close = fLast) or (fText[close + 1] <> '!') then
    Exit(Fail('a quoted sheet name without ! after it'));
  aBang := close + 1;
  Result := True;
end;

// the piece after a prefix whose ! is at aBang: a reference, a name or an error
function TFormulaScanner.Prefixed(var aToken: TFormulaToken; aBang: integer): boolean;
begin
  aToken.Prefix := aToken.Start;
  aToken.Bang := aBang;
  fIndex := aBang + 1;
  while (fIndex <= fLast) and IsFormulaSpace(fText[fIndex]) do
    Inc(fIndex);
  aToken.Start := fIndex;
  if fIndex > fLast then
    Exit(Fail('a reference missing'));
  if fText[fIndex] = '#' then
    Result := ErrorValue(aToken)
  else if IsWordStart(fText[fIndex]) then
    Result := Word(aToken)
  else
    Result := Fail('a reference missing');
  aToken.Finish := fIndex;
end;

function TFormulaScanner.ErrorValue(var aToken: TFormulaToken): boolean;
begin
  for var error: string in cErrors do
    if StartsWithWord(fText, fIndex, fLast + 1, error) then
    begin
      aToken.Kind := fkError;
      Inc(fIndex, error.Length);
      Exit(True);
    end;
  Result := Fail('an error value Excel does not have');
end;

// a word: a function's name (its ( next), a table's (its [...] next), a reference alone or a range of two, a number, TRUE or
// FALSE, a name
function TFormulaScanner.Word(var aToken: TFormulaToken): boolean;
begin
  var after: integer := WordEnd(fIndex);
  if (after <= fLast) and (fText[after] = '(') then
    aToken.Kind := fkFunction
  else if (after <= fLast) and (fText[after] = '[') then
  begin
    aToken.Kind := fkTable;
    aToken.NameFinish := after;
    var close: integer := ClosingBracket(after);
    if close = 0 then
      Exit(Fail('a [ without its ]'));
    after := close + 1;
  end
  else
  begin
    var kind: TReferenceKind := TUtility.ReadReference(fText, fIndex, after, aToken.Reference.Row, aToken.Reference.Column,
      aToken.Reference.RowFixed, aToken.Reference.ColumnFixed);
    aToken.Reference.Kind := kind;
    aToken.Reference.Range := False;
    if (kind <> TReferenceKind.rkNone) and (after < fLast) and (fText[after] = ':') and IsWordStart(fText[after + 1]) then
    begin
      var second: integer := WordEnd(after + 1);
      if TUtility.ReadReference(fText, after + 1, second, aToken.Reference.Row2, aToken.Reference.Column2,
        aToken.Reference.RowFixed2, aToken.Reference.ColumnFixed2) = kind then
      begin
        aToken.Reference.Range := True;
        after := second;
      end;
    end;
    if (kind <> TReferenceKind.rkNone) and ((kind = TReferenceKind.rkCell) or aToken.Reference.Range) then
      aToken.Kind := fkReference
    else if CharInSet(fText[fIndex], ['0' .. '9', '.']) then
    begin
      aToken.Kind := fkNumber;
      // the exponent's sign is no word's: 1.5E+3
      if CharInSet(fText[after - 1], ['E', 'e']) and (after < fLast) and CharInSet(fText[after], ['+', '-']) and
        CharInSet(fText[after + 1], ['0' .. '9']) then
        after := WordEnd(after + 1);
    end
    else if IsWord(fText, fIndex, after, 'TRUE') or IsWord(fText, fIndex, after, 'FALSE') then
      aToken.Kind := fkLogical
    else
      aToken.Kind := fkName;
  end;
  fIndex := after;
  Result := True;
end;

function TFormulaScanner.Next(out aToken: TFormulaToken): boolean;
begin
  if fIndex > fLast then
    Exit(False);
  aToken.Start := fIndex;
  aToken.Prefix := 0;
  aToken.Bang := 0;
  aToken.NameFinish := 0;
  var bang: integer;
  case fText[fIndex] of
    ' ', #9, #10, #13:
      begin
        aToken.Kind := fkSpace;
        repeat
          Inc(fIndex);
        until (fIndex > fLast) or not IsFormulaSpace(fText[fIndex]);
      end;
    '"':
      begin
        var close: integer := ClosingQuote(fIndex);
        if close = 0 then
          Exit(Fail('a text without its closing quote'));
        aToken.Kind := fkText;
        fIndex := close + 1;
      end;
    '''':
      Exit(QuotedBang(fIndex, bang) and Prefixed(aToken, bang));
    '[':
      begin // another workbook ([1]Sheet1!A1, [1]'My Sheet'!A1, [1]!Total) or a table's columns without its name ([@Sales])
        var close: integer := ClosingBracket(fIndex);
        if close = 0 then
          Exit(Fail('a [ without its ]'));
        var after: integer := close + 1;
        if after <= fLast then
          case fText[after] of
            '!':
              Exit(Prefixed(aToken, after));
            '''':
              Exit(QuotedBang(after, bang) and Prefixed(aToken, bang));
          else
            if IsWordStart(fText[after]) then
            begin
              bang := SheetBang(after);
              if bang > 0 then
                Exit(Prefixed(aToken, bang));
            end;
          end;
        aToken.Kind := fkTable;
        aToken.NameFinish := fIndex;
        fIndex := after;
      end;
    '#':
      if not ErrorValue(aToken) then
        Exit(False);
    '(', ')', '{', '}', ',', ';', '%':
      begin // the kinds fkOpen to fkPercent in this order
        aToken.Kind := TFormulaTokenKind(Ord(fkOpen) + Pos(fText[fIndex], '(){},;%') - 1);
        Inc(fIndex);
      end;
    '+', '-', '*', '/', '^', '&', '=', ':', '<', '>':
      begin
        aToken.Kind := fkOperator;
        Inc(fIndex);
        if (fIndex <= fLast) and (((fText[fIndex - 1] = '<') and CharInSet(fText[fIndex], ['>', '='])) or
          ((fText[fIndex - 1] = '>') and (fText[fIndex] = '='))) then
          Inc(fIndex);
      end;
  else
    if not IsWordStart(fText[fIndex]) then
      Exit(Fail('a character no formula has: ' + fText[fIndex]));
    bang := SheetBang(fIndex);
    if bang > 0 then
      Exit(Prefixed(aToken, bang));
    if not Word(aToken) then
      Exit(False);
  end;
  aToken.Finish := fIndex;
  Result := True;
end;

// StoredFormula's check, its references changed by aMap too (until the check is a walk over the scanner's tokens)
function CheckedFormula(const aFormula: string; const aMap: TReferenceMap; aForm: TFormulaForm; out aResult, aWhy,
  aUnknown: string): boolean;
const
  cSpaces = [' ', #9, #10, #13];
  cOperators = ['+', '-', '*', '/', '^', '&', '=', '<', '>', ':'];
  cMaxArguments = 255;
  cUnknown = -1;
  cResult = -2;
var
  builder: TStringBuilder;
  i, last: integer; // last: the formula's length
  // what comes next: a value (at the start, after an operator, an opening bracket, a comma) or an operator
  expectValue: boolean;
  // the value before was a constant (a number, a text, TRUE, an error, an array): no range or intersection with it
  constant: boolean;
  spaced: boolean; // spaces after a value: an intersection when another value follows
  ranged: boolean; // after a : the next value is a reference too
  arguments: boolean; // just after a function's ( or a comma between its arguments: an argument may be left out
  prefixed: boolean; // after Sheet1! or [1]: a reference follows
  prefixStart: integer; // where the prefix being read began: [1]Sheet1! is one; 0 between them
  prefix: string; // the last one before its ! (Sheet1, 'My Sheet', [1]Sheet1, Sheet1:Sheet3), for aMap
  prefixAt: integer; // where the builder has it: a sheet deleted rewrites it
  continued: boolean; // after a table's name: its [...] is the same value
  tableName: string; // that name, '' when another workbook's
  tableStart: integer; // where the builder has it
  called: boolean; // after a function's name: its ( follows
  calledFunction: integer; // that function: cFunctions' index, cUnknown, cResult (a LAMBDA's result or parameter called)
  callable: boolean; // just after a LAMBDA's ) or a call's: a ( calls its result, LAMBDA(x,x+1)(5)
  brackets: string; // what is open: f - a function's (, g - a group's (, { - an array constant
  commas: TArray<integer>; // a function's commas so far, for each bracket open
  functions: TArray<integer>; // a function's calledFunction, for each bracket open
  parameters: TList<string>; // LET's and LAMBDA's parameters in scope (Excel stores them _xlpm.x)
  scopes: TArray<integer>; // parameters' count at a function's (, for each bracket open: those after it end at its )
  // a function's argument so far may be a reference (A1, a name, (A1), A1:INDEX(...)), for each bracket open: a constant,
  // another operator or a call of a function giving a value spoils it, and Excel refuses a file with it where one must stand
  referenceLike: TArray<boolean>;

  function Fail(const aText: string): boolean;
  begin
    aWhy := aText;
    Result := False;
  end;

  function ReadWord(aFrom: integer): integer; // the index after it
  begin
    Result := aFrom;
    while (Result <= last) and (aFormula[Result].IsLetterOrDigit or CharInSet(aFormula[Result], ['_', '\', '$', '.', '?'])) do
      Inc(Result);
  end;

  function Inside: Char;
  begin
    if brackets = '' then
      Result := #0
    else
      Result := brackets[brackets.Length];
  end;

  // the first character after aFrom's spaces, #0 at the end
  function NextChar(aFrom: integer): Char;
  begin
    while (aFrom <= last) and CharInSet(aFormula[aFrom], cSpaces) do
      Inc(aFrom);
    if aFrom > last then
      Result := #0
    else
      Result := aFormula[aFrom];
  end;

  // a word ending before aEnd declares a parameter: LET's name (each other argument, not its last), LAMBDA's (all but its last)
  function Declares(aEnd: integer): boolean;
  begin
    Result := (Inside = 'f') and arguments and (NextChar(aEnd) = ',') and
      ((functions[brackets.Length - 1] = cLambdaFunction) or
      ((functions[brackets.Length - 1] = cLetFunction) and not Odd(commas[brackets.Length - 1])));
  end;

  // a parameter in scope as declared (Excel shows LAMBDA(Total,TOTAL*2) as LAMBDA(Total,Total*2)), '' when there is none
  function Declared(const aName: string): string;
  begin
    for var index := parameters.Count - 1 downto 0 do
      if SameText(parameters[index], aName) then
        Exit(parameters[index]);
    Result := '';
  end;

  // the innermost function's argument is no reference: a group's ( ) inside it is part of it, an array constant is not
  procedure NotAReference;
  begin
    for var index := brackets.Length downto 1 do
      case brackets[index] of
        'f':
          begin
            referenceLike[index - 1] := False;
            Exit;
          end;
        '{':
          Exit;
      end;
  end;

  // the argument ending here (aPosition, from 0) where Excel's function needs a reference: one or Excel refuses the file
  function CheckReference(aPosition: integer): boolean;
  begin
    var top: integer := brackets.Length - 1;
    Result := True;
    if functions[top] < 0 then
      Exit;
    var known: TExcelFunction := cFunctions[functions[top]];
    var pattern: string := known.References;
    if pattern = '' then
      Exit;
    var position: integer := aPosition;
    if position >= pattern.Length then
    begin // past its end the last one repeats, or the last two when paired
      var period: integer := 1;
      if known.Paired < known.Max then
        period := 2;
      position := pattern.Length - period + (position - pattern.Length) mod period;
    end;
    if (pattern[position + 1] = 'r') and (arguments or not referenceLike[top]) then
      Result := Fail(Format('%s''s argument %d must be a reference (A1, a name, INDEX(...)), not a value or left out',
        [known.Name, aPosition + 1]));
    referenceLike[top] := True;
  end;

  procedure OpenFunction(aFunction: integer);
  begin
    brackets := brackets + 'f';
    functions[brackets.Length - 1] := aFunction;
    scopes[brackets.Length - 1] := parameters.Count;
    referenceLike[brackets.Length - 1] := True;
    called := False;
    expectValue := True;
    arguments := True;
  end;

  // a function's ): Excel refuses a file where its own one has another number of arguments
  function CloseFunction: boolean;
  begin
    var top: integer := brackets.Length - 1;
    var count: integer := commas[top] + 1;
    if (commas[top] = 0) and expectValue then
      count := 0;
    parameters.DeleteRange(scopes[top], parameters.Count - scopes[top]);
    callable := (functions[top] = cLambdaFunction) or (functions[top] = cResult);
    if functions[top] < 0 then
      Exit(True);
    var known: TExcelFunction := cFunctions[functions[top]];
    if known.Min > known.Max then
      Exit(Fail(Format('Excel takes %s in no cell''s formula', [known.Name])));
    if (count >= known.Min) and (count <= known.Max) and ((count <= known.Paired) or not Odd(count - known.Paired)) then
      Exit((count = 0) or CheckReference(commas[top]));
    var counts: string := IntToStr(known.Min);
    if known.Max > known.Min then
      counts := counts + ' to ' + IntToStr(known.Max);
    if (known.Min = 1) and (known.Max = 1) then
      counts := counts + ' argument'
    else
      counts := counts + ' arguments';
    if known.Paired < known.Max then
      counts := Format('%s, those after %d in pairs', [counts, known.Paired]);
    Result := Fail(Format('%s takes %s, not %d', [known.Name, counts, count]));
  end;

  // a quoted text or sheet name: the index of its closing quote (a doubled one is inside), 0 when there is none
  function ClosingQuote(aQuote: Char): integer;
  begin
    Result := i + 1;
    while Result <= last do
    begin
      if aFormula[Result] = aQuote then
      begin
        if (Result < last) and (aFormula[Result + 1] = aQuote) then
          Inc(Result)
        else
          Exit;
      end;
      Inc(Result);
    end;
    Result := 0;
  end;

  // a value where one may stand: next to another only through spaces, both references (an intersection)
  function Value(aConstant: boolean): boolean;
  begin
    if not expectValue and not (spaced and not constant and not aConstant and (Inside <> '{')) then
      Exit(Fail('two values without an operator between them'));
    if (Inside = '{') and not aConstant then
      Exit(Fail('an array constant holds constants only'));
    if (ranged or prefixed) and aConstant then
      Exit(Fail('a reference missing'));
    if aConstant then
      NotAReference;
    expectValue := False;
    constant := aConstant;
    spaced := False;
    ranged := False;
    arguments := False;
    prefixed := False;
    Result := True;
  end;

  // anything but a value: not right after Sheet1!, a table's name or a :
  function NotAValue: boolean;
  begin
    Result := not prefixed and not continued and not ranged;
    if not Result then
      Fail('a reference missing');
    spaced := False;
  end;

  // a sheet deleted: the prefix written before the value gone (True; aName - the workbook's then, [0]!Total) or its 3-D
  // range's end moved
  function PrefixGone(aName: boolean): boolean;
  begin
    Result := False;
    var moved: string;
    case aMap.PrefixChange(prefix, moved) of
      TPrefixChange.pcGone:
        begin
          builder.Length := prefixAt;
          if aName then
            builder.Append('[0]!');
          Result := True;
        end;
      TPrefixChange.pcMoved:
        begin
          builder.Length := prefixAt;
          builder.Append(moved).Append('!');
        end;
    end;
  end;

  // a word: a reference alone or as one end of a range (moved, or #REF!), a number, TRUE, a name
  function Word(aEnd: integer): boolean;
  var
    reference: TReference;
  begin
    var wasPrefixed: boolean := prefixed;
    var word: string := Copy(aFormula, i, aEnd - i);
    var row, column: integer;
    var rowFixed, columnFixed: boolean;
    var kind: TReferenceKind := TUtility.ReadReference(word, row, column, rowFixed, columnFixed);
    var secondEnd: integer := 0;
    var row2: integer := 0;
    var column2: integer := 0;
    var rowFixed2: boolean := False;
    var columnFixed2: boolean := False;
    if (kind <> TReferenceKind.rkNone) and (aEnd < last) and (aFormula[aEnd] = ':') and IsWordStart(aFormula[aEnd + 1]) then
    begin
      secondEnd := ReadWord(aEnd + 1);
      if TUtility.ReadReference(Copy(aFormula, aEnd + 1, secondEnd - aEnd - 1), row2, column2, rowFixed2, columnFixed2) <> kind then
        secondEnd := 0;
    end;
    if (kind = TReferenceKind.rkNone) or ((kind <> TReferenceKind.rkCell) and (secondEnd = 0)) then
    begin // a number, TRUE, a name
      var isNumber: boolean := CharInSet(word[1], ['0' .. '9', '.']);
      if isNumber then
      begin // the exponent's sign was not part of the word: 1.5E+3
        if CharInSet(word[word.Length], ['E', 'e']) and (aEnd < last) and CharInSet(aFormula[aEnd], ['+', '-']) and
          CharInSet(aFormula[aEnd + 1], ['0' .. '9']) then
        begin
          aEnd := ReadWord(aEnd + 1);
          word := Copy(aFormula, i, aEnd - i);
        end;
        var number: Double;
        if not TUtility.TryFloatFromText(word, number) then
          Exit(Fail('not a number: ' + word));
      end;
      if not Value(isNumber or SameText(word, 'TRUE') or SameText(word, 'FALSE')) then
        Exit(False);
      if wasPrefixed then
        PrefixGone(True);
      builder.Append(word);
      i := aEnd;
      Exit(True);
    end;
    if not Value(False) then
      Exit(False);
    if secondEnd = 0 then
      secondEnd := aEnd
    else
      word := Copy(aFormula, i, secondEnd - i);
    var moved: string;
    if not wasPrefixed then
      prefix := '';
    reference.Kind := kind;
    reference.Row := row;
    reference.Column := column;
    reference.RowFixed := rowFixed;
    reference.ColumnFixed := columnFixed;
    reference.Range := secondEnd > aEnd;
    reference.Row2 := row2;
    reference.Column2 := column2;
    reference.RowFixed2 := rowFixed2;
    reference.ColumnFixed2 := columnFixed2;
    if wasPrefixed and PrefixGone(False) then
      builder.Append('#REF!')
    else if not aMap.Changes(prefix) then
      builder.Append(word)
    else if not aMap.Map(reference, moved) then
      builder.Append('#REF!')
    else if moved = '' then
      builder.Append(word)
    else
      builder.Append(moved);
    i := secondEnd;
    Result := True;
  end;

  function HasPrefix(const aWord, aPrefix: string): boolean;
  begin
    Result := SameText(Copy(aWord, 1, aPrefix.Length), aPrefix);
  end;

  function Unprefixed(const aWord: string): string;
  begin
    Result := aWord;
    if HasPrefix(Result, cParameterPrefix) then
      Result := Result.Substring(cParameterPrefix.Length);
  end;

  // LET's or LAMBDA's parameter ending before aEnd, declared or used; called when a ( follows (LET(f,LAMBDA(x,x+1),f(5)))
  function Parameter(aEnd: integer): boolean;
  begin
    var name: string := Unprefixed(Copy(aFormula, i, aEnd - i));
    var declaring: boolean := Declares(aEnd);
    if not Value(False) then
      Exit(False);
    if declaring then
      parameters.Add(name)
    else
      name := Declared(name);
    if aForm = ffStored then
      builder.Append(cParameterPrefix);
    builder.Append(name);
    i := aEnd;
    if (i <= last) and (aFormula[i] = '(') then
    begin
      called := True;
      calledFunction := cResult;
    end;
    Result := True;
  end;

  // a function's name ending before aEnd, its ( next: one of Excel's in aForm, upper case; another as it is
  function FunctionName(aEnd: integer): boolean;
  begin
    if not Value(False) then
      Exit(False);
    var word: string := Copy(aFormula, i, aEnd - i);
    var name: string := word;
    while HasPrefix(name, '_xlfn.') or HasPrefix(name, '_xlws.') do
      name := name.Substring(6);
    calledFunction := FindFunction(name);
    if calledFunction >= 0 then
    begin
      if not cFunctions[calledFunction].ReferenceResult then
        NotAReference;
      if aForm = ffStored then
        builder.Append(cFunctionPrefixes[cFunctions[calledFunction].Prefix]);
      builder.Append(cFunctions[calledFunction].Name);
    end
    else
    begin
      calledFunction := cUnknown;
      if (aUnknown = '') and not HasPrefix(word, '_xl') then // _xludf.: a user's function the file names so
        aUnknown := word;
      builder.Append(word);
    end;
    called := True;
    i := aEnd;
    Result := True;
  end;

  function Token: boolean;
  begin
    Result := False;
    var letter: Char := aFormula[i];
    var start: integer := i;
    var wasCallable: boolean := callable;
    callable := False;
    if CharInSet(letter, cSpaces) then
    begin
      if not expectValue then
        spaced := True;
      builder.Append(letter);
      Inc(i);
      Exit(True);
    end;
    case letter of
      '"':
        begin
          var close: integer := ClosingQuote(letter);
          if close = 0 then
            Exit(Fail('a text without its closing quote'));
          if not Value(True) then
            Exit;
          i := close + 1;
        end;
      '''':
        begin // a sheet name, its ! with it
          var close: integer := ClosingQuote(letter);
          if close = 0 then
            Exit(Fail('a sheet name without its closing quote'));
          if (close = last) or (aFormula[close + 1] <> '!') then
            Exit(Fail('a quoted sheet name without ! after it'));
          if not expectValue and not spaced then
            Exit(Fail('two values without an operator between them'));
          prefixed := True;
          if prefixStart = 0 then
          begin
            prefixStart := i;
            prefixAt := builder.Length;
          end;
          prefix := Copy(aFormula, prefixStart, close + 1 - prefixStart);
          prefixStart := 0;
          i := close + 2;
        end;
      '[':
        begin // a table's columns (Table1[[#This Row],[Sum]], ' escapes) or another workbook ([1]Sheet1!A1)
          var close: integer := i;
          var depth: integer := 0;
          while close <= last do
          begin
            case aFormula[close] of
              '''':
                Inc(close);
              '[':
                Inc(depth);
              ']':
                begin
                  Dec(depth);
                  if depth = 0 then
                    Break;
                end;
            end;
            Inc(close);
          end;
          if close > last then
            Exit(Fail('a [ without its ]'));
          i := close + 1;
          if continued then
          begin
            continued := False;
            if (tableName <> '') and aMap.TableGone(tableName, Copy(aFormula, start, i - start)) then
            begin
              builder.Length := tableStart;
              builder.Append('#REF!');
              Exit(True);
            end;
          end
          else if (i <= last) and (IsWordStart(aFormula[i]) or (aFormula[i] = '''')) then
          begin // a workbook: its sheet's name follows
            prefixStart := start;
            prefixAt := builder.Length;
          end
          else if (i <= last) and (aFormula[i] = '!') then
          begin // a workbook's name: [1]!Total
            prefixed := True;
            prefixAt := builder.Length;
            prefix := Copy(aFormula, start, i - start);
            Inc(i);
          end
          else if not Value(False) then
            Exit;
        end;
      '#':
        begin
          var error: string := '';
          for var index := Low(cErrors) to High(cErrors) do
            if SameText(Copy(aFormula, i, cErrors[index].Length), cErrors[index]) then
              error := cErrors[index];
          if error.IsEmpty then
            Exit(Fail('an error value Excel does not have'));
          var wasPrefixed: boolean := prefixed;
          if not Value(error <> '#REF!') then // Sheet1!#REF! stands for a reference
            Exit;
          if wasPrefixed then
            PrefixGone(False);
          builder.Append(error);
          Inc(i, error.Length);
          Exit(True);
        end;
      '(':
        begin
          if not NotAValue then
            Exit;
          SetLength(commas, brackets.Length + 1);
          SetLength(functions, brackets.Length + 1);
          SetLength(scopes, brackets.Length + 1);
          SetLength(referenceLike, brackets.Length + 1);
          commas[brackets.Length] := 0;
          if called then
            OpenFunction(calledFunction)
          else if wasCallable and not expectValue then
            OpenFunction(cResult)
          else if expectValue and (Inside <> '{') then
          begin
            brackets := brackets + 'g';
            arguments := False;
          end
          else
            Exit(Fail('a ( where an operator should be'));
          Inc(i);
        end;
      ')':
        begin
          if not NotAValue then
            Exit;
          case Inside of
            'f':
              if expectValue and not arguments then
                Exit(Fail('an operator without the value after it'))
              else if not CloseFunction then
                Exit;
            'g':
              if expectValue then
                Exit(Fail('a ( ) without a value inside'));
          else
            Exit(Fail('a ) without its opening one'));
          end;
          brackets := Copy(brackets, 1, brackets.Length - 1);
          expectValue := False;
          constant := False;
          arguments := False;
          Inc(i);
        end;
      '{':
        begin
          if not NotAValue then
            Exit;
          if not expectValue or (Inside = '{') then
            Exit(Fail('a { where it cannot stand'));
          brackets := brackets + '{';
          arguments := False;
          Inc(i);
        end;
      '}':
        begin
          if not NotAValue then
            Exit;
          if Inside <> '{' then
            Exit(Fail('a } without its opening one'));
          if expectValue then
            Exit(Fail('an array constant with a value missing'));
          brackets := Copy(brackets, 1, brackets.Length - 1);
          expectValue := True; // the array is the value
          if not Value(True) then
            Exit;
          Inc(i);
        end;
      ',':
        begin
          if not NotAValue then
            Exit;
          case Inside of
            'f':
              begin
                if not CheckReference(commas[brackets.Length - 1]) then
                  Exit;
                arguments := True; // an argument may be left out: IF(A1,,2)
                Inc(commas[brackets.Length - 1]);
                if commas[brackets.Length - 1] >= cMaxArguments then
                  Exit(Fail(Format('more than %d arguments to a function', [cMaxArguments])));
              end;
            'g', '{':
              if expectValue then
                Exit(Fail('a comma without a value before it'));
          else // a defined name's union: Sheet1!$A:$B,Sheet1!$1:$2
            if not aMap.InName then
              Exit(Fail('a comma outside a function''s brackets'))
            else if expectValue then
              Exit(Fail('a comma without a value before it'));
          end;
          expectValue := True;
          Inc(i);
        end;
      ';':
        begin
          if not NotAValue then
            Exit;
          if (Inside <> '{') or expectValue then
            Exit(Fail('a ; outside an array constant''s rows'));
          expectValue := True;
          Inc(i);
        end;
      '%':
        begin
          if not NotAValue then
            Exit;
          if expectValue or (Inside = '{') then
            Exit(Fail('a % without a value before it'));
          NotAReference;
          Inc(i);
        end;
    else
      if IsWordStart(letter) then
      begin
        var after: integer := ReadWord(i);
        var next: Char := #0;
        if after <= last then
          next := aFormula[after];
        // a 3-D reference's sheets: Sheet1:Sheet3!A1; not after a sheet's name (Sheet1!A3:Sheet1!A5) or from a cell
        // (A3:Sheet1!A5: Excel quotes a sheet named like a cell)
        var sheetsEnd: integer := 0;
        var row, column: integer;
        var rowFixed, columnFixed: boolean;
        if (next = ':') and (after < last) and IsWordStart(aFormula[after + 1]) and not prefixed and
          (TUtility.ReadReference(Copy(aFormula, i, after - i), row, column, rowFixed, columnFixed) <> TReferenceKind.rkCell) then
        begin
          sheetsEnd := ReadWord(after + 1);
          if (sheetsEnd > last) or (aFormula[sheetsEnd] <> '!') then
            sheetsEnd := 0;
        end;
        if (sheetsEnd > 0) or (next = '!') then
        begin // a sheet's name
          if prefixed or (not expectValue and not spaced) then
            Exit(Fail('two values without an operator between them'));
          prefixed := True;
          if prefixStart = 0 then
          begin
            prefixStart := i;
            prefixAt := builder.Length;
          end;
          if sheetsEnd > 0 then
            i := sheetsEnd
          else
            i := after;
          prefix := Copy(aFormula, prefixStart, i - prefixStart);
          prefixStart := 0;
          Inc(i);
        end
        else if Declares(after) or (Declared(Unprefixed(Copy(aFormula, i, after - i))) <> '') then
          Exit(Parameter(after))
        else if next = '(' then
          Exit(FunctionName(after))
        else if next = '[' then
        begin // a table: its [...] follows
          tableName := '';
          if not prefixed then
            tableName := Copy(aFormula, i, after - i);
          tableStart := builder.Length;
          if not Value(False) then
            Exit;
          continued := True;
          i := after;
        end
        else
          Exit(Word(after));
      end
      else if CharInSet(letter, cOperators) then
      begin
        if not NotAValue then
          Exit;
        if CharInSet(letter, ['+', '-']) and expectValue then
        begin // a sign
          arguments := False;
          NotAReference;
          Inc(i);
        end
        else if expectValue or (Inside = '{') then
          Exit(Fail('an operator without the value before it'))
        else
        begin
          if (letter = ':') and constant then
            Exit(Fail('a range of a constant'));
          ranged := letter = ':';
          if not ranged then
            NotAReference;
          Inc(i);
          if ((letter = '<') and (i <= last) and CharInSet(aFormula[i], ['>', '='])) or
            ((letter = '>') and (i <= last) and (aFormula[i] = '=')) then
            Inc(i);
          expectValue := True;
        end;
      end
      else
        Exit(Fail('a character no formula has: ' + letter));
    end;
    builder.Append(aFormula, start - 1, i - start);
    Result := True;
  end;

begin
  aResult := '';
  aWhy := '';
  aUnknown := '';
  last := aFormula.Length;
  expectValue := True;
  constant := False;
  spaced := False;
  ranged := False;
  arguments := False;
  prefixed := False;
  prefixStart := 0;
  prefixAt := 0;
  prefix := '';
  continued := False;
  tableName := '';
  tableStart := 0;
  called := False;
  calledFunction := cUnknown;
  callable := False;
  brackets := '';
  parameters := nil;
  builder := TStringBuilder.Create(last + 16);
  try
    parameters := TList<string>.Create;
    i := 1;
    while i <= last do
      if not Token then
        Exit(False);
    if Inside = '{' then
      Exit(Fail('a { without its closing one'));
    if brackets <> '' then
      Exit(Fail('a ( without its closing one'));
    if prefixed or continued or ranged then
      Exit(Fail('a reference missing'));
    if expectValue then
      if aFormula.Trim = '' then
        Exit(Fail('an empty formula'))
      else
        Exit(Fail('an operator without the value after it'));
    aResult := builder.ToString;
    Result := True;
  finally
    parameters.Free;
    builder.Free;
  end;
end;

function StoredFormula(const aFormula: string; out aResult, aWhy, aUnknown: string): boolean;
begin
  Result := CheckedFormula(aFormula, TReferenceMap.Fill(0, 0), ffStored, aResult, aWhy, aUnknown);
end;

// aFormula's pieces copied into a builder made at the first change
type
  TFormulaCopy = record
    Text: string;
    Builder: TStringBuilder;
    Copied: integer; // Text before it is in Builder
    procedure Start(const aText: string);
    // Text[aStart .. aFinish - 1] written as aWith
    procedure Replace(aStart, aFinish: integer; const aWith: string);
    function Done: string; // the text with the changes
  end;

procedure TFormulaCopy.Start(const aText: string);
begin
  Text := aText;
  Builder := nil;
  Copied := 1;
end;

procedure TFormulaCopy.Replace(aStart, aFinish: integer; const aWith: string);
begin
  if Builder = nil then
    Builder := TStringBuilder.Create(Text.Length + 16);
  Builder.Append(Text, Copied - 1, aStart - Copied).Append(aWith);
  Copied := aFinish;
end;

function TFormulaCopy.Done: string;
begin
  if Builder = nil then
    Exit(Text);
  Builder.Append(Text, Copied - 1, Text.Length + 1 - Copied);
  Result := Builder.ToString;
end;

function ShiftFormula(const aFormula: string; const aMap: TReferenceMap; out aResult, aWhy: string): boolean;
var
  scanner: TFormulaScanner;
  token: TFormulaToken;
  output: TFormulaCopy;
begin
  scanner := TFormulaScanner.Create(aFormula);
  output.Start(aFormula);
  try
    while scanner.Next(token) do
    begin
      var change: TPrefixChange := TPrefixChange.pcSame;
      var prefix: string := '';
      var moved: string;
      if (token.Prefix > 0) and (token.Kind in [fkReference, fkName, fkNumber, fkLogical, fkError]) then
      begin
        prefix := Copy(aFormula, token.Prefix, token.Bang - token.Prefix);
        change := aMap.PrefixChange(prefix, moved);
        if change = TPrefixChange.pcMoved then
          output.Replace(token.Prefix, token.Bang, moved);
      end;
      case token.Kind of
        fkReference:
          if change = TPrefixChange.pcGone then
            output.Replace(token.Prefix, token.Finish, '#REF!')
          else if not aMap.Changes(prefix) then
            // stays
          else if not aMap.Map(token.Reference, moved) then
            output.Replace(token.Start, token.Finish, '#REF!')
          else if (moved <> '') and not IsWord(aFormula, token.Start, token.Finish, moved) then
            output.Replace(token.Start, token.Finish, moved);
        fkName, fkNumber, fkLogical:
          if change = TPrefixChange.pcGone then
            output.Replace(token.Prefix, token.Start, '[0]!'); // the workbook's name then
        fkError:
          if change = TPrefixChange.pcGone then
            output.Replace(token.Prefix, token.Start, '');
        fkTable:
          if (token.Prefix = 0) and (token.NameFinish > token.Start) and (aMap.GoneTables <> nil) and
            aMap.TableGone(Copy(aFormula, token.Start, token.NameFinish - token.Start),
            Copy(aFormula, token.NameFinish, token.Finish - token.NameFinish)) then
            output.Replace(token.Start, token.Finish, '#REF!');
      end;
    end;
    aWhy := scanner.Error;
    Result := aWhy = '';
    if Result then
      aResult := output.Done
    else
      aResult := aFormula;
  finally
    output.Builder.Free;
  end;
end;

function ShownFormula(const aStored: string): string;
var
  scanner: TFormulaScanner;
  token: TFormulaToken;
  output: TFormulaCopy;
begin
  scanner := TFormulaScanner.Create(aStored);
  output.Start(aStored);
  try
    while scanner.Next(token) do
      if (token.Kind in [fkFunction, fkName]) and StartsWithWord(aStored, token.Start, token.Finish, cParameterPrefix) then
        output.Replace(token.Start, token.Start + cParameterPrefix.Length, '')
      else if token.Kind = fkFunction then
      begin // one of Excel's in upper case, without its prefixes; another as it is
        var start: integer := token.Start;
        while StartsWithWord(aStored, start, token.Finish, '_xlfn.') or StartsWithWord(aStored, start, token.Finish, '_xlws.') do
          Inc(start, 6);
        var index: integer := FindFunction(aStored, start, token.Finish);
        if (index >= 0) and ((start > token.Start) or
          not CompareMem(@aStored[start], Pointer(cFunctions[index].Name), (token.Finish - start) * SizeOf(Char))) then
          output.Replace(token.Start, token.Finish, cFunctions[index].Name);
      end;
    if scanner.Error <> '' then
      Exit(aStored);
    Result := output.Done;
  finally
    output.Builder.Free;
  end;
end;


function ShiftMap(const aFormulaSheet, aSheet: string; aByRows: boolean; aFirst, aCount: integer): TReferenceMap;
begin
  if aCount < 0 then
    Result := TReferenceMap.Deleted(aSheet, aByRows, aFirst, -aCount)
  else
    Result := TReferenceMap.Inserted(aSheet, aByRows, aFirst, aCount);
  Result.OnSheet := (aFormulaSheet <> '') and AnsiSameText(aFormulaSheet, aSheet);
  Result.InName := aFormulaSheet = '';
end;

end.
