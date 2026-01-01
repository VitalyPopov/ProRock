unit ProRock.Xmlite.Schema.Xml;

(*
    This unit was automatically generated using ProRocket 1.0.0 Lite (ProRock 1.0.0)
    Generated (UTC): 2026-01-01T11:38:37.662Z
    Namespace: http://www.w3.org/XML/1998/namespace
    
    ProRock is a free and open-source Delphi library. Feedback and contributions are welcome.
    https://github.com/VitalyPopov/ProRock
*)


interface

uses
  ProRock.Xmlite;

type
  TSpaceA = (sDefault, sPreserve);

  TBaseA = type string;
  TIdA = type string;
  TLangA = type string;

  TSpecialAttrsAG = class;


  TSpecialAttrsAG = class(TXmliteAttributeGroup)
  private
    fBase: TBaseA;
    fLang: TLangA;
    fSpace: TSpaceA;
    fId: TIdA;
  published
    property Base: TBaseA read fBase write fBase;
    property Lang: TLangA read fLang write fLang;
    property Space: TSpaceA read fSpace write fSpace;
    property Id: TIdA read fId write fId;
  end;


implementation

initialization

TMetaBankXmlite.RegisterNamespace('http://www.w3.org/XML/1998/namespace', [], [], [TypeInfo(TSpaceA), TypeInfo(TLangA), TypeInfo(TBaseA),
  TypeInfo(TIdA)], [TSpecialAttrsAG], [], [], 'xml');

end.
