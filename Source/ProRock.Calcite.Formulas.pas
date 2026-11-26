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

// whether aText[aStart .. aFinish - 1] is aWord exactly
function IsExactly(const aText: string; aStart, aFinish: integer; const aWord: string): boolean;
begin
  Result := (aFinish - aStart = aWord.Length) and ((aWord = '') or CompareMem(@aText[aStart], Pointer(aWord),
    aWord.Length * SizeOf(Char)));
end;

// whether aText[aStart .. aFinish - 1] and aText[aOther .. aOtherFinish - 1] are one word, ASCII letters in either case
function SameSpans(const aText: string; aStart, aFinish, aOther, aOtherFinish: integer): boolean;
begin
  if aFinish - aStart <> aOtherFinish - aOther then
    Exit(False);
  for var i := 0 to aFinish - aStart - 1 do
  begin
    var one: Char := aText[aStart + i];
    var other: Char := aText[aOther + i];
    if (one <> other) and ((Ord(one) xor Ord(other) <> 32) or not CharInSet(Char(Ord(one) or 32), ['a' .. 'z'])) then
      Exit(False);
  end;
  Result := True;
end;

const
  cMaxArguments = 255;
  cUnknown = -1; // a function Excel does not have
  cResult = -2; // a LAMBDA's result or a parameter called: LAMBDA(x,x+1)(5), f(5)
  cNoCall = -3;

type
  // a parameter's name in the formula, without its _xlpm.
  TFormulaSpan = record
    Start, Finish: integer;
  end;

  // a bracket open: a function's ( (f), a group's ( (g), an array constant's { ({)
  TFormulaOpen = record
    Kind: Char;
    Called: integer; // a function's: cFunctions' index, cUnknown, cResult
    Commas: integer;
    Scope: integer; // the parameters declared before it: those after it end at its )
    // its argument so far may be a reference (A1, a name, (A1), A1:INDEX(...)): a constant, another operator or a call of a
    // function giving a value spoils it, and Excel refuses a file with it where one must stand
    ReferenceLike: boolean;
  end;

  // StoredFormula's walk: Excel's grammar over the scanner's tokens, the stored form written (prefixes, Excel's names)
  TFormulaGrammar = record
    Text: string;
    Why, Unknown: string;
    Output: TTextCopy;
    // what comes next: a value (at the start, after an operator, an opening bracket, a comma) or an operator
    ExpectValue: boolean;
    // the value before was a constant (a number, a text, TRUE, an error, an array): no range or intersection with it
    Constant: boolean;
    Spaced: boolean; // spaces after a value: an intersection when another value follows
    Ranged: boolean; // after a : the next value is a reference too
    Arguments: boolean; // just after a function's ( or a comma between its arguments: an argument may be left out
    Callable: boolean; // just after a LAMBDA's ) or a call's: a ( calls its result
    Call: integer; // after a function's name: what its ( opens; cNoCall otherwise
    Opened: TArray<TFormulaOpen>;
    Depth: integer;
    Parameters: TArray<TFormulaSpan>; // LET's and LAMBDA's in scope
    ParameterCount: integer;
    procedure Start(const aFormula: string);
    function Fail(const aWhy: string): boolean;
    function Inside: Char;
    function NextChar(aFrom: integer): Char;
    procedure NotAReference;
    function Value(aConstant, aPrefixed: boolean): boolean;
    function NotAValue: boolean;
    function CheckReference(aPosition: integer): boolean;
    procedure Push(aKind: Char; aCalled: integer);
    function CloseFunction: boolean;
    function Declares(aEnd: integer): boolean;
    function Declared(aStart, aFinish: integer): integer;
    function Parameter(const aToken: TFormulaToken; aStart: integer): boolean;
    function FunctionName(const aToken: TFormulaToken): boolean;
    function Constants(const aToken: TFormulaToken): boolean;
    function Bracket(const aToken: TFormulaToken; aWasCallable: boolean): boolean;
    function Separator(const aToken: TFormulaToken): boolean;
    function Operator(const aToken: TFormulaToken): boolean;
    function Token(const aToken: TFormulaToken): boolean;
    function Ended: boolean;
  end;

procedure TFormulaGrammar.Start(const aFormula: string);
begin
  Text := aFormula;
  Why := '';
  Unknown := '';
  Output.Start(aFormula);
  ExpectValue := True;
  Constant := False;
  Spaced := False;
  Ranged := False;
  Arguments := False;
  Callable := False;
  Call := cNoCall;
  Depth := 0;
  ParameterCount := 0;
end;

function TFormulaGrammar.Fail(const aWhy: string): boolean;
begin
  Why := aWhy;
  Result := False;
end;

function TFormulaGrammar.Inside: Char;
begin
  if Depth = 0 then
    Result := #0
  else
    Result := Opened[Depth - 1].Kind;
end;

// the first character from aFrom past spaces, #0 at the end
function TFormulaGrammar.NextChar(aFrom: integer): Char;
begin
  while (aFrom <= Text.Length) and IsFormulaSpace(Text[aFrom]) do
    Inc(aFrom);
  if aFrom > Text.Length then
    Result := #0
  else
    Result := Text[aFrom];
end;

// the innermost function's argument is no reference: a group's ( ) inside it is part of it, an array constant is not
procedure TFormulaGrammar.NotAReference;
begin
  for var index := Depth - 1 downto 0 do
    case Opened[index].Kind of
      'f':
        begin
          Opened[index].ReferenceLike := False;
          Exit;
        end;
      '{':
        Exit;
    end;
end;

// a value where one may stand: next to another only through spaces, both references (an intersection); aPrefixed - after
// Sheet1! or [1]!, a reference's place
function TFormulaGrammar.Value(aConstant, aPrefixed: boolean): boolean;
begin
  if not ExpectValue and not (Spaced and not Constant and not aConstant and (Inside <> '{')) then
    Exit(Fail('two values without an operator between them'));
  if (Inside = '{') and not aConstant then
    Exit(Fail('an array constant holds constants only'));
  if (Ranged or aPrefixed) and aConstant then
    Exit(Fail('a reference missing'));
  if aConstant then
    NotAReference;
  ExpectValue := False;
  Constant := aConstant;
  Spaced := False;
  Ranged := False;
  Arguments := False;
  Result := True;
end;

// anything but a value: not right after a :
function TFormulaGrammar.NotAValue: boolean;
begin
  Result := not Ranged or Fail('a reference missing');
  Spaced := False;
end;

// the argument ending here (aPosition, from 0) where Excel's function needs a reference: one or Excel refuses the file
function TFormulaGrammar.CheckReference(aPosition: integer): boolean;
begin
  Result := True;
  var called: integer := Opened[Depth - 1].Called;
  if (called < 0) or (cFunctions[called].References = '') then
    Exit;
  var pattern: string := cFunctions[called].References;
  var position: integer := aPosition;
  if position >= pattern.Length then
  begin // past its end the last one repeats, or the last two when paired
    var period: integer := 1;
    if cFunctions[called].Paired < cFunctions[called].Max then
      period := 2;
    position := pattern.Length - period + (position - pattern.Length) mod period;
  end;
  if (pattern[position + 1] = 'r') and (Arguments or not Opened[Depth - 1].ReferenceLike) then
    Result := Fail(Format('%s''s argument %d must be a reference (A1, a name, INDEX(...)), not a value or left out',
      [cFunctions[called].Name, aPosition + 1]));
  Opened[Depth - 1].ReferenceLike := True;
end;

procedure TFormulaGrammar.Push(aKind: Char; aCalled: integer);
begin
  if Depth = Length(Opened) then
    SetLength(Opened, Max(8, 2 * Depth));
  Opened[Depth].Kind := aKind;
  Opened[Depth].Called := aCalled;
  Opened[Depth].Commas := 0;
  Opened[Depth].Scope := ParameterCount;
  Opened[Depth].ReferenceLike := True;
  Inc(Depth);
  Call := cNoCall;
  ExpectValue := True;
  Arguments := aKind = 'f';
end;

// a function's ): Excel refuses a file where its own one has another number of arguments
function TFormulaGrammar.CloseFunction: boolean;
begin
  var top: TFormulaOpen := Opened[Depth - 1];
  var count: integer := top.Commas + 1;
  if (top.Commas = 0) and ExpectValue then
    count := 0;
  ParameterCount := top.Scope;
  Callable := (top.Called = cLambdaFunction) or (top.Called = cResult);
  if top.Called < 0 then
    Exit(True);
  var known: TExcelFunction := cFunctions[top.Called];
  if known.Min > known.Max then
    Exit(Fail(Format('Excel takes %s in no cell''s formula', [known.Name])));
  if (count >= known.Min) and (count <= known.Max) and ((count <= known.Paired) or not Odd(count - known.Paired)) then
    Exit((count = 0) or CheckReference(top.Commas));
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

// a name ending before aEnd declares a parameter: LET's (each other argument, not its last), LAMBDA's (all but its last)
function TFormulaGrammar.Declares(aEnd: integer): boolean;
begin
  Result := (Inside = 'f') and Arguments and (NextChar(aEnd) = ',') and ((Opened[Depth - 1].Called = cLambdaFunction) or
    ((Opened[Depth - 1].Called = cLetFunction) and not Odd(Opened[Depth - 1].Commas)));
end;

// the parameter in scope named Text[aStart .. aFinish - 1] in any case (the last declared), -1 when there is none
function TFormulaGrammar.Declared(aStart, aFinish: integer): integer;
begin
  for var index := ParameterCount - 1 downto 0 do
    if SameSpans(Text, Parameters[index].Start, Parameters[index].Finish, aStart, aFinish) then
      Exit(index);
  Result := -1;
end;

// LET's or LAMBDA's parameter, its name from aStart (past _xlpm.), declared or used, written _xlpm. and as declared
// (LAMBDA(Total,TOTAL*2) as LAMBDA(Total,Total*2)); called when a function's token
function TFormulaGrammar.Parameter(const aToken: TFormulaToken; aStart: integer): boolean;
begin
  var declaring: boolean := (aToken.Kind = fkName) and Declares(aToken.Finish);
  if not Value(False, False) then
    Exit(False);
  var name: TFormulaSpan;
  if declaring then
  begin
    if ParameterCount = Length(Parameters) then
      SetLength(Parameters, Max(4, 2 * ParameterCount));
    name.Start := aStart;
    name.Finish := aToken.Finish;
    Parameters[ParameterCount] := name;
    Inc(ParameterCount);
  end
  else
    name := Parameters[Declared(aStart, aToken.Finish)];
  var count: integer := name.Finish - name.Start;
  if (aStart - aToken.Start <> cParameterPrefix.Length) or not IsExactly(Text, aToken.Start, aStart, cParameterPrefix) or
    (aToken.Finish - aStart <> count) or not CompareMem(@Text[aStart], @Text[name.Start], count * SizeOf(Char)) then
    Output.Replace(aToken.Start, aToken.Finish, cParameterPrefix + Copy(Text, name.Start, count));
  if aToken.Kind = fkFunction then
    Call := cResult;
  Result := True;
end;

// a function's name, its ( next: one of Excel's with its prefix, upper case; another as it is
function TFormulaGrammar.FunctionName(const aToken: TFormulaToken): boolean;
begin
  if not Value(False, False) then
    Exit(False);
  var start: integer := aToken.Start;
  while StartsWithWord(Text, start, aToken.Finish, '_xlfn.') or StartsWithWord(Text, start, aToken.Finish, '_xlws.') do
    Inc(start, 6);
  Call := FindFunction(Text, start, aToken.Finish);
  if Call >= 0 then
  begin
    if not cFunctions[Call].ReferenceResult then
      NotAReference;
    var written: string := cFunctionPrefixes[cFunctions[Call].Prefix] + cFunctions[Call].Name;
    if not IsExactly(Text, aToken.Start, aToken.Finish, written) then
      Output.Replace(aToken.Start, aToken.Finish, written);
  end
  else
  begin
    Call := cUnknown;
    if (Unknown = '') and not StartsWithWord(Text, aToken.Start, aToken.Finish, '_xl') then // _xludf.: a user's function
      Unknown := Copy(Text, aToken.Start, aToken.Finish - aToken.Start);
  end;
  Result := True;
end;

// a number, TRUE or FALSE, an error (Excel's in upper case)
function TFormulaGrammar.Constants(const aToken: TFormulaToken): boolean;
begin
  var prefixed: boolean := aToken.Prefix > 0;
  case aToken.Kind of
    fkNumber:
      begin
        var word: string := Copy(Text, aToken.Start, aToken.Finish - aToken.Start);
        var number: Double;
        if not TUtility.TryFloatFromText(word, number) then
          Exit(Fail('not a number: ' + word));
        Result := Value(True, prefixed);
      end;
    fkLogical:
      Result := Value(True, prefixed);
  else
    var error: integer := High(cErrors);
    while not IsWord(Text, aToken.Start, aToken.Finish, cErrors[error]) do
      Dec(error);
    Result := Value(cErrors[error] <> '#REF!', prefixed); // Sheet1!#REF! stands for a reference
    if not IsExactly(Text, aToken.Start, aToken.Finish, cErrors[error]) then
      Output.Replace(aToken.Start, aToken.Finish, cErrors[error]);
  end;
end;

// ( ) { }
function TFormulaGrammar.Bracket(const aToken: TFormulaToken; aWasCallable: boolean): boolean;
begin
  if not NotAValue then
    Exit(False);
  case aToken.Kind of
    fkOpen:
      if Call <> cNoCall then
        Push('f', Call)
      else if aWasCallable and not ExpectValue then
        Push('f', cResult)
      else if ExpectValue and (Inside <> '{') then
        Push('g', cNoCall)
      else
        Exit(Fail('a ( where an operator should be'));
    fkClose:
      begin
        case Inside of
          'f':
            if ExpectValue and not Arguments then
              Exit(Fail('an operator without the value after it'))
            else if not CloseFunction then
              Exit(False);
          'g':
            if ExpectValue then
              Exit(Fail('a ( ) without a value inside'));
        else
          Exit(Fail('a ) without its opening one'));
        end;
        Dec(Depth);
        ExpectValue := False;
        Constant := False;
        Arguments := False;
      end;
    fkArrayOpen:
      begin
        if not ExpectValue or (Inside = '{') then
          Exit(Fail('a { where it cannot stand'));
        Push('{', cNoCall);
      end;
  else
    if Inside <> '{' then
      Exit(Fail('a } without its opening one'));
    if ExpectValue then
      Exit(Fail('an array constant with a value missing'));
    Dec(Depth);
    ExpectValue := True; // the array is the value
    Exit(Value(True, False));
  end;
  Result := True;
end;

// , ; %
function TFormulaGrammar.Separator(const aToken: TFormulaToken): boolean;
begin
  if not NotAValue then
    Exit(False);
  case aToken.Kind of
    fkComma:
      case Inside of
        'f':
          begin
            if not CheckReference(Opened[Depth - 1].Commas) then
              Exit(False);
            Arguments := True; // an argument may be left out: IF(A1,,2)
            Inc(Opened[Depth - 1].Commas);
            if Opened[Depth - 1].Commas >= cMaxArguments then
              Exit(Fail(Format('more than %d arguments to a function', [cMaxArguments])));
          end;
        'g', '{':
          if ExpectValue then
            Exit(Fail('a comma without a value before it'));
      else
        Exit(Fail('a comma outside a function''s brackets'));
      end;
    fkSemicolon:
      if (Inside <> '{') or ExpectValue then
        Exit(Fail('a ; outside an array constant''s rows'));
  else
    if ExpectValue or (Inside = '{') then
      Exit(Fail('a % without a value before it'));
    NotAReference;
    Exit(True);
  end;
  ExpectValue := True;
  Result := True;
end;

function TFormulaGrammar.Operator(const aToken: TFormulaToken): boolean;
begin
  if not NotAValue then
    Exit(False);
  var letter: Char := Text[aToken.Start];
  if CharInSet(letter, ['+', '-']) and ExpectValue then
  begin // a sign
    Arguments := False;
    NotAReference;
    Exit(True);
  end;
  if ExpectValue or (Inside = '{') then
    Exit(Fail('an operator without the value before it'));
  if (letter = ':') and Constant then
    Exit(Fail('a range of a constant'));
  Ranged := letter = ':';
  if not Ranged then
    NotAReference;
  ExpectValue := True;
  Result := True;
end;

function TFormulaGrammar.Token(const aToken: TFormulaToken): boolean;
begin
  var wasCallable: boolean := Callable;
  Callable := False;
  case aToken.Kind of
    fkSpace:
      begin
        if not ExpectValue then
          Spaced := True;
        Result := True;
      end;
    fkText:
      Result := Value(True, False);
    fkNumber, fkLogical, fkError:
      Result := Constants(aToken);
    fkReference, fkTable:
      Result := Value(False, False);
    fkName, fkFunction:
      begin
        var start: integer := aToken.Start;
        if StartsWithWord(Text, start, aToken.Finish, cParameterPrefix) then
          Inc(start, cParameterPrefix.Length);
        if (aToken.Prefix = 0) and (((aToken.Kind = fkName) and Declares(aToken.Finish)) or
          (Declared(start, aToken.Finish) >= 0)) then
          Result := Parameter(aToken, start)
        else if aToken.Kind = fkFunction then
          Result := FunctionName(aToken)
        else
          Result := Value(False, False);
      end;
    fkOpen, fkClose, fkArrayOpen, fkArrayClose:
      Result := Bracket(aToken, wasCallable);
    fkComma, fkSemicolon, fkPercent:
      Result := Separator(aToken);
  else
    Result := Operator(aToken);
  end;
end;

// the checks at the formula's end
function TFormulaGrammar.Ended: boolean;
begin
  if Inside = '{' then
    Exit(Fail('a { without its closing one'));
  if Depth > 0 then
    Exit(Fail('a ( without its closing one'));
  if Ranged then
    Exit(Fail('a reference missing'));
  if ExpectValue then
    if Text.Trim = '' then
      Exit(Fail('an empty formula'))
    else
      Exit(Fail('an operator without the value after it'));
  Result := True;
end;

function StoredFormula(const aFormula: string; out aResult, aWhy, aUnknown: string): boolean;
var
  scanner: TFormulaScanner;
  token: TFormulaToken;
  grammar: TFormulaGrammar;
begin
  scanner := TFormulaScanner.Create(aFormula);
  grammar.Start(aFormula);
  try
    Result := True;
    while Result and scanner.Next(token) do
      Result := grammar.Token(token);
    if Result and (scanner.Error <> '') then
      Result := grammar.Fail(scanner.Error);
    Result := Result and grammar.Ended;
    aWhy := grammar.Why;
    aUnknown := grammar.Unknown;
    if Result then
      aResult := grammar.Output.Done
    else
      aResult := '';
  finally
    grammar.Output.Builder.Free;
  end;
end;

function ShiftFormula(const aFormula: string; const aMap: TReferenceMap; out aResult, aWhy: string): boolean;
var
  scanner: TFormulaScanner;
  token: TFormulaToken;
  output: TTextCopy;
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
  output: TTextCopy;
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
