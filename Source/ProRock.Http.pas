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

  // protocol-agnostic HTTP exchange; default headers (authentication, API keys) go with every request and never reach the
  // protocol layers' events or error texts. Configure them before concurrent use
  THttpTransport = class abstract
  private
    fHeaders: THttpHeaders;
  protected
    // the real exchange of a request that already carries the default headers; raises on network failures
    function Send(const aRequest: THttpRequest): THttpResponse; virtual; abstract;
  public
    // sent with every request; a header the request already has wins over a default one
    property Headers: THttpHeaders read fHeaders;

    function Execute(const aRequest: THttpRequest): THttpResponse;

    // adds or replaces a default header (names are case-insensitive); an empty value removes it
    procedure SetHeader(const aName, aValue: string);
    // HTTP Basic authentication (RFC 7617): user and password as UTF-8, sent with every request - use https
    procedure SetBasicAuth(const aUserName, aPassword: string);
    // OAuth 2.0 bearer token (RFC 6750), sent with every request; an empty token removes it
    procedure SetBearerToken(const aToken: string);
  end;

  // System.Net based transport; a new THTTPClient per request, so one instance may be used from several threads
  THttpTransportNative = class(THttpTransport)
  private
    fConnectionTimeout: integer;
    fResponseTimeout: integer;
    fUserName: string;
    fPassword: string;
    fClientCertificate: string;
    fClientCertificateData: TBytes;
    fClientCertificatePassword: string;
  protected
    function Send(const aRequest: THttpRequest): THttpResponse; override;
  public
    property ConnectionTimeout: integer read fConnectionTimeout write fConnectionTimeout; // ms, 0 - System.Net default
    property ResponseTimeout: integer read fResponseTimeout write fResponseTimeout; // ms, 0 - System.Net default

    // credentials for a server that asks for them (HTTP 401 challenge): Basic, Digest, NTLM, Negotiate - the scheme is agreed by
    // System.Net and the operating system; 'DOMAIN\user' for a Windows domain account
    property UserName: string read fUserName write fUserName;
    property Password: string read fPassword write fPassword;

    // mutual TLS: a PFX/P12 file with the client certificate (Android: an installed one's name), opened by every call - a
    // missing file or a wrong password fails it. Delphi 12 or later; before, a call fails with ENotSupportedException
    property ClientCertificate: string read fClientCertificate write fClientCertificate;
    // the same certificate from memory (PFX/P12 or PEM bytes: a database, a key vault); either this or ClientCertificate
    // (both: EInvalidOpException). Not on Android (ENotSupportedException - use an installed one's name)
    property ClientCertificateData: TBytes read fClientCertificateData write fClientCertificateData;
    property ClientCertificatePassword: string read fClientCertificatePassword write fClientCertificatePassword;
  end;

implementation

uses System.Net.HttpClient, System.Net.URLClient, System.NetEncoding;

const
  cHeaderAuthorization = 'Authorization';

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

{ THttpTransport }

function THttpTransport.Execute(const aRequest: THttpRequest): THttpResponse;
begin
  var request: THttpRequest := aRequest;
  for var header: THttpHeader in fHeaders do
    if request.Header(header.Name).IsEmpty then
      request.AddHeader(header.Name, header.Value);

  Result := Send(request);
end;

procedure THttpTransport.SetBasicAuth(const aUserName, aPassword: string);
begin
  // no line breaks: the default Base64 encoder wraps at 76 characters, which would break the header
  var base64: TBase64Encoding := TBase64Encoding.Create(0);
  try
    SetHeader(cHeaderAuthorization, 'Basic ' + base64.EncodeBytesToString(TEncoding.UTF8.GetBytes(aUserName + ':' + aPassword)));
  finally
    base64.Free;
  end;
end;

procedure THttpTransport.SetBearerToken(const aToken: string);
begin
  if aToken.IsEmpty then
    SetHeader(cHeaderAuthorization, '')
  else
    SetHeader(cHeaderAuthorization, 'Bearer ' + aToken);
end;

procedure THttpTransport.SetHeader(const aName, aValue: string);
begin
  for var i: integer := High(fHeaders) downto 0 do
    if SameText(fHeaders[i].Name, aName) then
      Delete(fHeaders, i, 1);

  if not aValue.IsEmpty then
    fHeaders := fHeaders + [THttpHeader.Create(aName, aValue)];
end;

{ THttpTransportNative }

function THttpTransportNative.Send(const aRequest: THttpRequest): THttpResponse;
begin
  if not fClientCertificate.IsEmpty and (Length(fClientCertificateData) > 0) then
    raise EInvalidOpException.Create('Set either ClientCertificate or ClientCertificateData, not both');

  var client: THTTPClient := THTTPClient.Create;
  var source: TStringStream := TStringStream.Create(aRequest.Body, TEncoding.UTF8);
  var certificate: TBytesStream := nil; // System.Net keeps only a weak reference: it must live until the call ends
  try
    if fConnectionTimeout > 0 then
      client.ConnectionTimeout := fConnectionTimeout;
    if fResponseTimeout > 0 then
      client.ResponseTimeout := fResponseTimeout;
    if not fUserName.IsEmpty then // used only when the server answers with a challenge
      client.CredentialsStorage.AddCredential(TCredentialsStorage.TCredential.Create(TAuthTargetType.Server, '', '', fUserName,
        fPassword));

    var headers: TNetHeaders := [];
    for var header: THttpHeader in aRequest.Headers do
      headers := headers + [TNetHeader.Create(header.Name, header.Value)];

    // THTTPClient.Execute(method, url, ...) is inherited from TURLClient and gives IURLResponse only - IHTTPRequest is needed
    var httpRequest: IHTTPRequest := client.GetRequest(aRequest.Method, aRequest.Url);
    httpRequest.SourceStream := source;
    if not fClientCertificate.IsEmpty then
      {$IF CompilerVersion >= 36} // Delphi 12
      httpRequest.SetClientCertificate(fClientCertificate, fClientCertificatePassword);
      {$ELSE}
      raise ENotSupportedException.Create('Client certificates need Delphi 12 or later (System.Net of this version cannot use them)');
      {$IFEND}
    if Length(fClientCertificateData) > 0 then
    begin
      {$IF CompilerVersion < 36}
      raise ENotSupportedException.Create('Client certificates need Delphi 12 or later (System.Net of this version cannot use them)');
      {$ELSEIF Defined(ANDROID)}
      raise ENotSupportedException.Create('Client certificates from memory are not supported on Android (System.Net uses ' +
        'certificates installed on the device - set ClientCertificate to its name)');
      {$ELSE}
      certificate := TBytesStream.Create(fClientCertificateData);
      httpRequest.SetClientCertificate(certificate, fClientCertificatePassword);
      {$IFEND}
    end;
    var response: IHTTPResponse := client.Execute(httpRequest, nil, headers);

    Result.Status := response.StatusCode;
    Result.Headers := [];
    for var header: TNetHeader in response.Headers do
      Result.Headers := Result.Headers + [THttpHeader.Create(header.Name, header.Value)];
    Result.Body := response.ContentAsString(TEncoding.UTF8);
  finally
    certificate.Free;
    source.Free;
    client.Free;
  end;
end;

end.
