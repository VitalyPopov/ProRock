unit ProRock.Xmlite.Schema.Instance;

(*
    This unit was automatically generated using ProRocket Lite 1.0.6 (ProRock 1.0.3)
    
    ProRock is a free and open-source Delphi library. Feedback and contributions are welcome.
    https://github.com/VitalyPopov/ProRock
    
    Generated (UTC): 2026-10-05T13:58:04.415Z
    Namespace: http://www.w3.org/2001/XMLSchema-instance
*)


interface

uses
  ProRock.Xmlite;

type

  TNilA = type string;
  TNoNamespaceSchemaLocationA = type string;
  TSchemaLocationA = type string;
  TTypeA = type string;




implementation

initialization

TMetaBankXmlite.RegisterNamespace('http://www.w3.org/2001/XMLSchema-instance',
  { simpleTypes }
  [],
  { complexTypes }
  [],
  { attributes }
  [TypeInfo(TNilA), TypeInfo(TTypeA), TypeInfo(TSchemaLocationA), TypeInfo(TNoNamespaceSchemaLocationA)],
  { attributeGroups }
  [],
  { elements }
  [],
  { groups }
  [],
  'xsi');

end.
