unit ProRock.Xmlite.Schema.Instance;

(*
    This unit was automatically generated using ProRocket 1.0.4 Lite (ProRock 1.0.2)
    Generated (UTC): 2026-01-10T19:23:25.430Z
    Namespace: http://www.w3.org/2001/XMLSchema-instance
    
    ProRock is a free and open-source Delphi library. Feedback and contributions are welcome.
    https://github.com/VitalyPopov/ProRock
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

TMetaBankXmlite.RegisterNamespace('http://www.w3.org/2001/XMLSchema-instance', [], [], [TypeInfo(TNilA), TypeInfo(TTypeA),
  TypeInfo(TSchemaLocationA), TypeInfo(TNoNamespaceSchemaLocationA)], [], [], [], 'xsi');

end.
