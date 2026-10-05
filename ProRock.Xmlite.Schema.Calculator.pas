unit ProRock.Xmlite.Schema.Calculator;

(*
    This unit was automatically generated using ProRocket Lite 1.0.6 (ProRock 1.0.3)
    
    ProRock is a free and open-source Delphi library. Feedback and contributions are welcome.
    https://github.com/VitalyPopov/ProRock
    
    Generated (UTC): 2026-10-05T20:48:57.370Z
    Namespace: http://tempuri.org/
*)


interface

uses
  ProRock.Xmlite, ProRock.Xmlite.Schema.Base;

type
  TAddE = class;
  TAddResponseE = class;
  TSubtractE = class;
  TSubtractResponseE = class;
  TMultiplyE = class;
  TMultiplyResponseE = class;
  TDivideE = class;
  TDivideResponseE = class;

  TAddEList = class;
  TAddResponseEList = class;
  TSubtractEList = class;
  TSubtractResponseEList = class;
  TMultiplyEList = class;
  TMultiplyResponseEList = class;
  TDivideEList = class;
  TDivideResponseEList = class;

  TAddE = class(TXmliteElement)
  private
    fIntA: ProRock.Xmlite.Schema.Base.TIntST;
    fIntB: ProRock.Xmlite.Schema.Base.TIntST;
  published
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nCamelCase)]
    property IntA: ProRock.Xmlite.Schema.Base.TIntST read fIntA write fIntA;
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nCamelCase)]
    property IntB: ProRock.Xmlite.Schema.Base.TIntST read fIntB write fIntB;
  end;

  TAddResponseE = class(TXmliteElement)
  private
    fAddResult: ProRock.Xmlite.Schema.Base.TIntST;
  published
    [TXmliteElement]
    [TRequired]
    property AddResult: ProRock.Xmlite.Schema.Base.TIntST read fAddResult write fAddResult;
  end;

  TSubtractE = class(TXmliteElement)
  private
    fIntA: ProRock.Xmlite.Schema.Base.TIntST;
    fIntB: ProRock.Xmlite.Schema.Base.TIntST;
  published
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nCamelCase)]
    property IntA: ProRock.Xmlite.Schema.Base.TIntST read fIntA write fIntA;
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nCamelCase)]
    property IntB: ProRock.Xmlite.Schema.Base.TIntST read fIntB write fIntB;
  end;

  TSubtractResponseE = class(TXmliteElement)
  private
    fSubtractResult: ProRock.Xmlite.Schema.Base.TIntST;
  published
    [TXmliteElement]
    [TRequired]
    property SubtractResult: ProRock.Xmlite.Schema.Base.TIntST read fSubtractResult write fSubtractResult;
  end;

  TMultiplyE = class(TXmliteElement)
  private
    fIntA: ProRock.Xmlite.Schema.Base.TIntST;
    fIntB: ProRock.Xmlite.Schema.Base.TIntST;
  published
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nCamelCase)]
    property IntA: ProRock.Xmlite.Schema.Base.TIntST read fIntA write fIntA;
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nCamelCase)]
    property IntB: ProRock.Xmlite.Schema.Base.TIntST read fIntB write fIntB;
  end;

  TMultiplyResponseE = class(TXmliteElement)
  private
    fMultiplyResult: ProRock.Xmlite.Schema.Base.TIntST;
  published
    [TXmliteElement]
    [TRequired]
    property MultiplyResult: ProRock.Xmlite.Schema.Base.TIntST read fMultiplyResult write fMultiplyResult;
  end;

  TDivideE = class(TXmliteElement)
  private
    fIntA: ProRock.Xmlite.Schema.Base.TIntST;
    fIntB: ProRock.Xmlite.Schema.Base.TIntST;
  published
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nCamelCase)]
    property IntA: ProRock.Xmlite.Schema.Base.TIntST read fIntA write fIntA;
    [TXmliteElement]
    [TRequired]
    [TNaming(TNaming.nCamelCase)]
    property IntB: ProRock.Xmlite.Schema.Base.TIntST read fIntB write fIntB;
  end;

  TDivideResponseE = class(TXmliteElement)
  private
    fDivideResult: ProRock.Xmlite.Schema.Base.TIntST;
  published
    [TXmliteElement]
    [TRequired]
    property DivideResult: ProRock.Xmlite.Schema.Base.TIntST read fDivideResult write fDivideResult;
  end;

  TAddEList = class(TXmliteList<TAddE>);
  TAddResponseEList = class(TXmliteList<TAddResponseE>);
  TSubtractEList = class(TXmliteList<TSubtractE>);
  TSubtractResponseEList = class(TXmliteList<TSubtractResponseE>);
  TMultiplyEList = class(TXmliteList<TMultiplyE>);
  TMultiplyResponseEList = class(TXmliteList<TMultiplyResponseE>);
  TDivideEList = class(TXmliteList<TDivideE>);
  TDivideResponseEList = class(TXmliteList<TDivideResponseE>);

implementation

initialization

TMetaBankXmlite.RegisterNamespace('http://tempuri.org/',
  { simpleTypes }
  [],
  { complexTypes }
  [],
  { attributes }
  [],
  { attributeGroups }
  [],
  { elements }
  [TAddE, TAddResponseE, TSubtractE, TSubtractResponseE, TMultiplyE, TMultiplyResponseE, TDivideE, TDivideResponseE],
  { groups }
  [],
  'tns', TNaming.nPascalCase);

end.
