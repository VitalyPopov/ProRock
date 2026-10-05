unit ProRock.Soapite;

interface

uses System.Classes, System.SysUtils,
  ProRock.Basite, ProRock.Xmlite, ProRock.Http, ProRock.Xmlite.Schema.Envelope;

type
  TSoapVersion = (sv11, sv12);
  TSoapVersions = set of TSoapVersion;

const
  cSoapiteContentType11 = 'text/xml; charset=utf-8';

  // versions the runtime can speak (SOAP 1.2 is to come)
  cSoapiteVersionsImplemented: TSoapVersions = [sv11];

type
  TSoapiteXmlEvent = procedure(aSender: TObject; const aXml: string) of object;

  TSoapiteErrorKind = (sekNone,
    sekNetwork, // no HTTP response at all (connection, timeout, ...)
    sekHttp,    // HTTP response without a SOAP envelope (e.g. 404, 502)
    sekContent, // SOAP envelope without the expected response element
    sekFault);  // the service answered with a SOAP Fault

  // why a call has no result - a plain record, nothing to free
  TSoapiteError = record
    Kind: TSoapiteErrorKind;
    Message: string;
    Code: string;       // SOAP Fault code, e.g. soap:Server
    Actor: string;      // SOAP Fault actor
    Detail: string;     // raw xml of the SOAP Fault detail (registered elements only)
    HttpStatus: integer;
    Response: string;   // raw response body - for diagnostics
  end;

  ESoapite = class(Exception)
  protected
    fError: TSoapiteError;
  public
    constructor Create(const aError: TSoapiteError);

    property Error: TSoapiteError read fError;
  end;

  // no SOAP response could be read: network/HTTP problem or unexpected content
  ESoapiteTransport = class(ESoapite)
  public
    property Status: integer read fError.HttpStatus;
    property Response: string read fError.Response;
  end;

  // the service answered with a SOAP Fault
  ESoapiteFault = class(ESoapite)
  public
    property Code: string read fError.Code;
    property Actor: string read fError.Actor;
    property Detail: string read fError.Detail;
  end;

  // Calls are independent (own envelope and HTTP client per call), so one client may be called from several threads at once.
  // Configure it (Endpoint, SoapVersion, Transport, events) before that - settings must not be changed while calls are running.
  TSoapiteClient = class
  private
    fEndpoint: string;
    fSoapVersion: TSoapVersion;
    fSupportedVersions: TSoapVersions;
    fTransport: THttpTransport;
    fOnRequest: TSoapiteXmlEvent;
    fOnResponse: TSoapiteXmlEvent;

    procedure SetSoapVersion(aValue: TSoapVersion);
    procedure SetTransport(aValue: THttpTransport);
  protected
    // never raises for a service or network failure: False and the reason in aError (aResponse is nil then);
    // aRequest stays owned by the caller, aResponse is owned by the caller
    function TryCall(const aSoapAction: string; aRequest: TBasite; aResponseClass: TBasiteClass; out aResponse: TBasite;
      out aError: TSoapiteError): boolean;
    // the same, but raises ESoapiteFault/ESoapiteTransport instead of returning False; the returned response is owned by the caller
    function Call(const aSoapAction: string; aRequest: TBasite; aResponseClass: TBasiteClass): TBasite;
  public
    // aSupportedVersions - SOAP versions the service declares (bindings in its WSDL)
    constructor Create(const aEndpoint: string; aSupportedVersions: TSoapVersions = [sv11]); virtual;
    destructor Destroy; override;

    property Endpoint: string read fEndpoint write fEndpoint;
    // the version really used: a version the service does not declare (or the runtime does not speak yet) falls back to 1.1
    property SoapVersion: TSoapVersion read fSoapVersion write SetSoapVersion;
    property SupportedVersions: TSoapVersions read fSupportedVersions;
    // owned by the client; assigning a new transport frees the previous one
    property Transport: THttpTransport read fTransport write SetTransport;

    // raw xml - for logging and debugging
    property OnRequest: TSoapiteXmlEvent read fOnRequest write fOnRequest;
    property OnResponse: TSoapiteXmlEvent read fOnResponse write fOnResponse;
  end;

implementation

uses System.StrUtils;

{ ESoapite }

constructor ESoapite.Create(const aError: TSoapiteError);
begin
  inherited Create(aError.Message);
  fError := aError;
end;

{ TSoapiteClient }

function TSoapiteClient.Call(const aSoapAction: string; aRequest: TBasite; aResponseClass: TBasiteClass): TBasite;
begin
  var error: TSoapiteError;
  if not TryCall(aSoapAction, aRequest, aResponseClass, Result, error) then
    if error.Kind = sekFault then
      raise ESoapiteFault.Create(error)
    else
      raise ESoapiteTransport.Create(error);
end;

function TSoapiteClient.TryCall(const aSoapAction: string; aRequest: TBasite; aResponseClass: TBasiteClass; out aResponse: TBasite;
  out aError: TSoapiteError): boolean;
begin
  aResponse := nil;
  aError := Default(TSoapiteError);
  Result := False;

  // settings are read once - the whole call uses one consistent endpoint (and version: todo for SOAP 1.2 envelope, content type
  // and fault - only 1.1 can be set so far)
  var endpoint: string := fEndpoint;

  var request: THttpRequest;
  request.Method := 'POST';
  request.Url := endpoint;
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

  var response: THttpResponse;
  try
    response := fTransport.Execute(request);
  except
    on e: Exception do
    begin
      aError.Kind := sekNetwork;
      aError.Message := e.Message;
      Exit;
    end;
  end;

  if Assigned(fOnResponse) then
    fOnResponse(Self, response.Body);

  aError.HttpStatus := response.Status;
  aError.Response := response.Body;

  // the raw body stays intact for the error: being shared, it is parsed from a copy (see FromXml)
  var responseBody: string := response.Body;

  // SOAP faults normally come with HTTP 500, so the body is examined before the status
  envelope := TEnvelopeE.Create;
  try
    var parsed: boolean := False;
    if not responseBody.IsEmpty then
      try
        parsed := envelope.FromXml(responseBody);
      except
        parsed := False;
      end;

    if not parsed then
    begin
      aError.Kind := sekHttp;
      aError.Message := Format('No SOAP response (HTTP %d)', [response.Status]);
      Exit;
    end;

    var responseObject: TBasite := nil;
    for var item: TBasite in envelope.Body.XmlAny do
      if item.InheritsFrom(TFaultCT) then
      begin
        var fault: TFaultCT := TFaultCT(item);
        aError.Kind := sekFault;
        aError.Message := fault.Faultstring;
        aError.Code := fault.Faultcode;
        aError.Actor := fault.Faultactor;
        if (fault.Detail.XmlAny.Count > 0) or not fault.Detail.XmlText.IsEmpty then
          aError.Detail := fault.Detail.ToXml('', False);
        Exit;
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

      aError.Kind := sekContent;
      aError.Message := Format('SOAP response does not contain %s (HTTP %d), found: [%s]', [aResponseClass.ClassName, response.Status,
        found]);
      Exit;
    end;

    aResponse := envelope.Body.XmlAny.Extract(responseObject); // ownership goes to the caller
    aError := Default(TSoapiteError);
    Result := True;
  finally
    envelope.Free;
  end;
end;

constructor TSoapiteClient.Create(const aEndpoint: string; aSupportedVersions: TSoapVersions);
begin
  inherited Create;
  fEndpoint := aEndpoint;
  fSupportedVersions := aSupportedVersions;
  fTransport := THttpTransportNative.Create;

  // 1.1 is what (almost) every SOAP service supports; a service declaring 1.2 only starts with 1.2
  if sv11 in fSupportedVersions then
    SetSoapVersion(sv11)
  else
    SetSoapVersion(sv12);
end;

destructor TSoapiteClient.Destroy;
begin
  fTransport.Free;
  inherited;
end;

procedure TSoapiteClient.SetSoapVersion(aValue: TSoapVersion);
begin
  // the requested version if the service declares it and the runtime speaks it, otherwise 1.1 - the payload is the same anyway
  if aValue in fSupportedVersions * cSoapiteVersionsImplemented then
    fSoapVersion := aValue
  else
    fSoapVersion := sv11; // todo: log the fallback once logging exists
end;

procedure TSoapiteClient.SetTransport(aValue: THttpTransport);
begin
  if aValue = fTransport then
    Exit;

  fTransport.Free;
  fTransport := aValue;
end;

end.
