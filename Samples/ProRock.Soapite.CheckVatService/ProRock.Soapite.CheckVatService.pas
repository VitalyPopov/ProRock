unit ProRock.Soapite.CheckVatService;

(*
    This unit was automatically generated using ProRocket Lite 1.1.0 (ProRock 1.1.0)
    
    ProRock is a free and open-source Delphi library. Feedback and contributions are welcome.
    https://github.com/VitalyPopov/ProRock
    
    Generated (UTC): 2026-10-07T21:14:49.576Z
    Service: checkVatService
*)


interface

uses
  ProRock.Soapite, ProRock.Xmlite.Schema.CheckVatService;

type
  ESoapiteFault = ProRock.Soapite.ESoapiteFault;
  ESoapiteTransport = ProRock.Soapite.ESoapiteTransport;
  TCheckVatApproxE = ProRock.Xmlite.Schema.CheckVatService.TCheckVatApproxE;
  TCheckVatApproxResponseE = ProRock.Xmlite.Schema.CheckVatService.TCheckVatApproxResponseE;
  TCheckVatE = ProRock.Xmlite.Schema.CheckVatService.TCheckVatE;
  TCheckVatResponseE = ProRock.Xmlite.Schema.CheckVatService.TCheckVatResponseE;
  TSoapiteError = ProRock.Soapite.TSoapiteError;

  TCheckVatService = class(TSoapiteClient)
  public
    constructor Create(const aEndpoint: string = 'http://ec.europa.eu/taxation_customs/vies/services/checkVatService'); reintroduce;
    function CheckVat(aRequest: TCheckVatE): TCheckVatResponseE;
    function TryCheckVat(aRequest: TCheckVatE; out aResponse: TCheckVatResponseE; out aError: TSoapiteError): boolean;
    function CheckVatApprox(aRequest: TCheckVatApproxE): TCheckVatApproxResponseE;
    function TryCheckVatApprox(aRequest: TCheckVatApproxE; out aResponse: TCheckVatApproxResponseE; out aError: TSoapiteError): boolean;
  end;

implementation

uses
  ProRock.Basite;

{ TCheckVatService }

function TCheckVatService.CheckVat(aRequest: TCheckVatE): TCheckVatResponseE;
begin
  Result := TCheckVatResponseE(Call('', aRequest, TCheckVatResponseE));
end;

function TCheckVatService.CheckVatApprox(aRequest: TCheckVatApproxE): TCheckVatApproxResponseE;
begin
  Result := TCheckVatApproxResponseE(Call('', aRequest, TCheckVatApproxResponseE));
end;

constructor TCheckVatService.Create(const aEndpoint: string);
begin
  inherited Create(aEndpoint, [sv11]);
end;

function TCheckVatService.TryCheckVat(aRequest: TCheckVatE; out aResponse: TCheckVatResponseE; out aError: TSoapiteError): boolean;
begin
  var response: TBasite;
  Result := TryCall('', aRequest, TCheckVatResponseE, response, aError);
  aResponse := TCheckVatResponseE(response);
end;

function TCheckVatService.TryCheckVatApprox(aRequest: TCheckVatApproxE; out aResponse: TCheckVatApproxResponseE; out aError: TSoapiteError):
  boolean;
begin
  var response: TBasite;
  Result := TryCall('', aRequest, TCheckVatApproxResponseE, response, aError);
  aResponse := TCheckVatApproxResponseE(response);
end;

end.
