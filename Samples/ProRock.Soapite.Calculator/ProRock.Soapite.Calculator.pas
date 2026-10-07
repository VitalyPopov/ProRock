unit ProRock.Soapite.Calculator;

(*
    This unit was automatically generated using ProRocket Lite 1.1.0 (ProRock 1.1.0)
    
    ProRock is a free and open-source Delphi library. Feedback and contributions are welcome.
    https://github.com/VitalyPopov/ProRock
    
    Generated (UTC): 2026-10-07T21:14:49.576Z
    Service: Calculator
*)


interface

uses
  ProRock.Soapite, ProRock.Xmlite.Schema.Calculator;

type
  ESoapiteFault = ProRock.Soapite.ESoapiteFault;
  ESoapiteTransport = ProRock.Soapite.ESoapiteTransport;
  TAddE = ProRock.Xmlite.Schema.Calculator.TAddE;
  TAddResponseE = ProRock.Xmlite.Schema.Calculator.TAddResponseE;
  TDivideE = ProRock.Xmlite.Schema.Calculator.TDivideE;
  TDivideResponseE = ProRock.Xmlite.Schema.Calculator.TDivideResponseE;
  TMultiplyE = ProRock.Xmlite.Schema.Calculator.TMultiplyE;
  TMultiplyResponseE = ProRock.Xmlite.Schema.Calculator.TMultiplyResponseE;
  TSoapiteError = ProRock.Soapite.TSoapiteError;
  TSubtractE = ProRock.Xmlite.Schema.Calculator.TSubtractE;
  TSubtractResponseE = ProRock.Xmlite.Schema.Calculator.TSubtractResponseE;

  TCalculator = class(TSoapiteClient)
  public
    constructor Create(const aEndpoint: string = 'http://www.dneonline.com/calculator.asmx'); reintroduce;
    function Add(aRequest: TAddE): TAddResponseE;
    function TryAdd(aRequest: TAddE; out aResponse: TAddResponseE; out aError: TSoapiteError): boolean;
    function Subtract(aRequest: TSubtractE): TSubtractResponseE;
    function TrySubtract(aRequest: TSubtractE; out aResponse: TSubtractResponseE; out aError: TSoapiteError): boolean;
    function Multiply(aRequest: TMultiplyE): TMultiplyResponseE;
    function TryMultiply(aRequest: TMultiplyE; out aResponse: TMultiplyResponseE; out aError: TSoapiteError): boolean;
    function Divide(aRequest: TDivideE): TDivideResponseE;
    function TryDivide(aRequest: TDivideE; out aResponse: TDivideResponseE; out aError: TSoapiteError): boolean;
  end;

implementation

uses
  ProRock.Basite;

{ TCalculator }

function TCalculator.Add(aRequest: TAddE): TAddResponseE;
begin
  Result := TAddResponseE(Call('http://tempuri.org/Add', aRequest, TAddResponseE));
end;

constructor TCalculator.Create(const aEndpoint: string);
begin
  inherited Create(aEndpoint, [sv11, sv12]);
end;

function TCalculator.Divide(aRequest: TDivideE): TDivideResponseE;
begin
  Result := TDivideResponseE(Call('http://tempuri.org/Divide', aRequest, TDivideResponseE));
end;

function TCalculator.Multiply(aRequest: TMultiplyE): TMultiplyResponseE;
begin
  Result := TMultiplyResponseE(Call('http://tempuri.org/Multiply', aRequest, TMultiplyResponseE));
end;

function TCalculator.Subtract(aRequest: TSubtractE): TSubtractResponseE;
begin
  Result := TSubtractResponseE(Call('http://tempuri.org/Subtract', aRequest, TSubtractResponseE));
end;

function TCalculator.TryAdd(aRequest: TAddE; out aResponse: TAddResponseE; out aError: TSoapiteError): boolean;
begin
  var response: TBasite;
  Result := TryCall('http://tempuri.org/Add', aRequest, TAddResponseE, response, aError);
  aResponse := TAddResponseE(response);
end;

function TCalculator.TryDivide(aRequest: TDivideE; out aResponse: TDivideResponseE; out aError: TSoapiteError): boolean;
begin
  var response: TBasite;
  Result := TryCall('http://tempuri.org/Divide', aRequest, TDivideResponseE, response, aError);
  aResponse := TDivideResponseE(response);
end;

function TCalculator.TryMultiply(aRequest: TMultiplyE; out aResponse: TMultiplyResponseE; out aError: TSoapiteError): boolean;
begin
  var response: TBasite;
  Result := TryCall('http://tempuri.org/Multiply', aRequest, TMultiplyResponseE, response, aError);
  aResponse := TMultiplyResponseE(response);
end;

function TCalculator.TrySubtract(aRequest: TSubtractE; out aResponse: TSubtractResponseE; out aError: TSoapiteError): boolean;
begin
  var response: TBasite;
  Result := TryCall('http://tempuri.org/Subtract', aRequest, TSubtractResponseE, response, aError);
  aResponse := TSubtractResponseE(response);
end;

end.
