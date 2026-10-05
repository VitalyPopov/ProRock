unit ProRock.Http;

interface

uses System.Classes, System.SysUtils;

type
  THttpHeader = record
    Name, Value: string;

    constructor Create(const aName, aValue: string);
  end;

  THttpHeaders = TArray<THttpHeader>;

  THttpRequest = record
    Method: string;
    Url: string;
    Headers: THttpHeaders;
    Body: string;

    procedure AddHeader(const aName, aValue: string);
    function Header(const aName: string): string;
  end;

  THttpResponse = record
    Status: integer;
    Headers: THttpHeaders;
    Body: string;

    function Header(const aName: string): string;
  end;

  // protocol-agnostic HTTP exchange - protocol layers (SOAP, REST, ...) build requests and read responses on top of it
  THttpTransport = class abstract
  public
    function Execute(const aRequest: THttpRequest): THttpResponse; virtual; abstract;
  end;

  // System.Net based transport; a new THTTPClient per request, so one instance may be used from several threads
  THttpTransportNative = class(THttpTransport)
  private
    fConnectionTimeout: integer;
    fResponseTimeout: integer;
  public
    property ConnectionTimeout: integer read fConnectionTimeout write fConnectionTimeout; // ms, 0 - System.Net default
    property ResponseTimeout: integer read fResponseTimeout write fResponseTimeout; // ms, 0 - System.Net default

    function Execute(const aRequest: THttpRequest): THttpResponse; override;
  end;

implementation

uses System.Net.HttpClient, System.Net.URLClient;

function HeaderValue(const aHeaders: THttpHeaders; const aName: string): string;
begin
  for var header: THttpHeader in aHeaders do
    if SameText(header.Name, aName) then
      Exit(header.Value);

  Result := '';
end;

{ THttpHeader }

constructor THttpHeader.Create(const aName, aValue: string);
begin
  Name := aName;
  Value := aValue;
end;

{ THttpRequest }

procedure THttpRequest.AddHeader(const aName, aValue: string);
begin
  Headers := Headers + [THttpHeader.Create(aName, aValue)];
end;

function THttpRequest.Header(const aName: string): string;
begin
  Result := HeaderValue(Headers, aName);
end;

{ THttpResponse }

function THttpResponse.Header(const aName: string): string;
begin
  Result := HeaderValue(Headers, aName);
end;

{ THttpTransportNative }

function THttpTransportNative.Execute(const aRequest: THttpRequest): THttpResponse;
begin
  var client: THTTPClient := THTTPClient.Create;
  var source: TStringStream := TStringStream.Create(aRequest.Body, TEncoding.UTF8);
  try
    if fConnectionTimeout > 0 then
      client.ConnectionTimeout := fConnectionTimeout;
    if fResponseTimeout > 0 then
      client.ResponseTimeout := fResponseTimeout;

    var headers: TNetHeaders := [];
    for var header: THttpHeader in aRequest.Headers do
      headers := headers + [TNetHeader.Create(header.Name, header.Value)];

    // THTTPClient.Execute(method, url, ...) is inherited from TURLClient and gives IURLResponse only - IHTTPRequest is needed
    var httpRequest: IHTTPRequest := client.GetRequest(aRequest.Method, aRequest.Url);
    httpRequest.SourceStream := source;
    var response: IHTTPResponse := client.Execute(httpRequest, nil, headers);

    Result.Status := response.StatusCode;
    Result.Headers := [];
    for var header: TNetHeader in response.Headers do
      Result.Headers := Result.Headers + [THttpHeader.Create(header.Name, header.Value)];
    Result.Body := response.ContentAsString(TEncoding.UTF8);
  finally
    source.Free;
    client.Free;
  end;
end;

end.
