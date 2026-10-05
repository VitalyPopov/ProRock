unit ProRock.Soapite;

interface

uses System.Classes, System.SysUtils,
  ProRock.Basite, ProRock.Xmlite, ProRock.Http, ProRock.Xmlite.Schema.Envelope;

const
  cSoapiteContentType11 = 'text/xml; charset=utf-8';

type
  TSoapiteXmlEvent = procedure(aSender: TObject; const aXml: string) of object;

  ESoapite = class(Exception);

  // no SOAP response could be read: network/HTTP problem or unexpected content
  ESoapiteTransport = class(ESoapite)
  private
    fStatus: integer;
    fResponse: string;
  public
    constructor Create(const aMessage: string; aStatus: integer; const aResponse: string);

    property Status: integer read fStatus;
    property Response: string read fResponse;
  end;

  // the service answered with a SOAP Fault
  ESoapiteFault = class(ESoapite)
  private
    fCode: string;
    fActor: string;
    fDetail: string;
  public
    constructor Create(const aCode, aMessage, aActor, aDetail: string);

    property Code: string read fCode;
    property Actor: string read fActor;
    property Detail: string read fDetail; // raw xml of the fault detail (registered elements only)
  end;

  TSoapiteClient = class
  private
    fEndpoint: string;
    fTransport: THttpTransport;
    fOnRequest: TSoapiteXmlEvent;
    fOnResponse: TSoapiteXmlEvent;

    procedure SetTransport(aValue: THttpTransport);
  protected
    // aRequest stays owned by the caller, the returned response is owned by the caller
    function Call(const aSoapAction: string; aRequest: TBasite; aResponseClass: TBasiteClass): TBasite;
  public
    constructor Create(const aEndpoint: string); virtual;
    destructor Destroy; override;

    property Endpoint: string read fEndpoint write fEndpoint;
    // owned by the client; assigning a new transport frees the previous one
    property Transport: THttpTransport read fTransport write SetTransport;

    // raw xml - for logging and debugging
    property OnRequest: TSoapiteXmlEvent read fOnRequest write fOnRequest;
    property OnResponse: TSoapiteXmlEvent read fOnResponse write fOnResponse;
  end;

implementation

uses System.StrUtils;

{ ESoapiteTransport }

constructor ESoapiteTransport.Create(const aMessage: string; aStatus: integer; const aResponse: string);
begin
  inherited Create(aMessage);
  fStatus := aStatus;
  fResponse := aResponse;
end;

{ ESoapiteFault }

constructor ESoapiteFault.Create(const aCode, aMessage, aActor, aDetail: string);
begin
  inherited Create(aMessage);
  fCode := aCode;
  fActor := aActor;
  fDetail := aDetail;
end;

{ TSoapiteClient }

function TSoapiteClient.Call(const aSoapAction: string; aRequest: TBasite; aResponseClass: TBasiteClass): TBasite;
begin
  var request: THttpRequest;
  request.Method := 'POST';
  request.Url := fEndpoint;
  request.AddHeader('Content-Type', cSoapiteContentType11);
  request.AddHeader('SOAPAction', '"' + aSoapAction + '"');

  var envelope: TEnvelopeE := TEnvelopeE.Create;
  try
    envelope.Body.XmlAny.Add(aRequest);
    try
      request.Body := envelope.ToXml;
    finally
      envelope.Body.XmlAny.Extract(aRequest); // the envelope must not free the caller's request
    end;
  finally
    envelope.Free;
  end;

  if Assigned(fOnRequest) then
    fOnRequest(Self, request.Body);

  var response: THttpResponse := fTransport.Execute(request);

  if Assigned(fOnResponse) then
    fOnResponse(Self, response.Body);

  // SOAP faults normally come with HTTP 500, so the body is examined before the status
  envelope := TEnvelopeE.Create;
  try
    if response.Body.IsEmpty or not envelope.FromXml(response.Body) then
      raise ESoapiteTransport.Create(Format('No SOAP response (HTTP %d)', [response.Status]), response.Status, response.Body);

    var responseObject: TBasite := nil;
    for var item: TBasite in envelope.Body.XmlAny do
      if item.InheritsFrom(TFaultCT) then
      begin
        var fault: TFaultCT := TFaultCT(item);
        var detail: string := '';
        if (fault.Detail.XmlAny.Count > 0) or not fault.Detail.XmlText.IsEmpty then
          detail := fault.Detail.ToXml('', False);
        raise ESoapiteFault.Create(fault.Faultcode, fault.Faultstring, fault.Faultactor, detail);
      end
      else if item.InheritsFrom(aResponseClass) then
      begin
        responseObject := item;
        break;
      end;

    if responseObject = nil then
    begin
      var found: string := '';
      for var item: TBasite in envelope.Body.XmlAny do
        found := found + IfThen(not found.IsEmpty, ', ') + item.ClassName;
      for var item: TBasite in envelope.XmlAny do
        found := found + IfThen(not found.IsEmpty, ', ') + 'Envelope:' + item.ClassName;

      raise ESoapiteTransport.Create(Format('SOAP response does not contain %s (HTTP %d), found: [%s]',
        [aResponseClass.ClassName, response.Status, found]), response.Status, response.Body);
    end;

    Result := envelope.Body.XmlAny.Extract(responseObject); // ownership goes to the caller
  finally
    envelope.Free;
  end;
end;

constructor TSoapiteClient.Create(const aEndpoint: string);
begin
  inherited Create;
  fEndpoint := aEndpoint;
  fTransport := THttpTransportNative.Create;
end;

destructor TSoapiteClient.Destroy;
begin
  fTransport.Free;
  inherited;
end;

procedure TSoapiteClient.SetTransport(aValue: THttpTransport);
begin
  if aValue = fTransport then
    Exit;

  fTransport.Free;
  fTransport := aValue;
end;

end.
