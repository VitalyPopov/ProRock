unit ProRock.Xmlite.Schema.Xml;

(*
    This unit was automatically generated using ProRocket Lite 1.1.0 (ProRock 1.1.0)
    
    ProRock is a free and open-source Delphi library. Feedback and contributions are welcome.
    https://github.com/VitalyPopov/ProRock
    
    Generated (UTC): 2026-10-07T21:13:19.877Z
    Namespace: http://www.w3.org/XML/1998/namespace
*)


interface

uses
  ProRock.Xmlite;

type
  TSpaceA = (sDefault, sPreserve);

  TBaseA = type string;
  TIdA = type string;
  TLangA = type string;

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

TMetaBankXmlite.RegisterNamespace('http://www.w3.org/XML/1998/namespace',
  { simpleTypes }
  [],
  { complexTypes }
  [],
  { attributes }
  [TypeInfo(TLangA), TypeInfo(TSpaceA), TypeInfo(TBaseA), TypeInfo(TIdA)],
  { attributeGroups }
  [TSpecialAttrsAG],
  { elements }
  [],
  { groups }
  [],
  'xml');

end.
