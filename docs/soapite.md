# Soapite

Soapite is the SOAP client: typed requests, typed responses and typed faults, through a client class generated from the WSDL.
SOAP 1.1 and 1.2 are both supported.

## The generated client

[ProRocket Lite](prorocket-lite.md) makes one client unit per `wsdl:service` (`ProRock.Soapite.<Service>`), next to the units
of its types. The client unit re-exports the request and response types, `TSoapiteError` and the exceptions, so for plain calls
it is the only unit to use.

```pascal
uses ProRock.Soapite.CheckVatService;

// pass the real endpoint: the default is the WSDL's soap:address, which may be outdated (VIES still declares http://)
var service := TCheckVatService.Create('https://ec.europa.eu/taxation_customs/vies/services/checkVatService');
```

## Two forms of every operation

| Call | On a SOAP Fault or a network failure |
|---|---|
| `TryCheckVat(request, response, error)` | returns `False`, the reason in `error: TSoapiteError`; never raises for them |
| `CheckVat(request)` | raises `ESoapiteFault` / `ESoapiteTransport` |

The response is yours to free.

```pascal
uses ProRock.Soapite, ProRock.Soapite.CheckVatService; // ProRock.Soapite: TSoapiteErrorKind

var response: TCheckVatResponseE;
var error: TSoapiteError;
if service.TryCheckVat(request, response, error) then
  try
    Writeln(response.Name, ' - valid: ', response.Valid);
  finally
    response.Free;
  end
else if error.Kind = sekFault then
  Writeln('the service refused: ', error.Code)
else
  Writeln('failed: ', error.Message);
```

`TSoapiteError.Kind` is one of `sekNetwork`, `sekHttp`, `sekContent`, `sekFault`. SOAP Faults of both versions are mapped to it
(code, 1.2 subcode, reason, actor/node, detail), also when a service answers a fault with HTTP 200.

!!! warning "Server text"
    `TSoapiteError.Message`, `Detail` and `Response` are text controlled by the server and may contain its internals (stack
    traces, paths). Log them, and show your own message to end users.

## Transport: timeouts, authentication, certificates

The HTTP transport is `THttpTransportNative` from `ProRock.Http`, based on System.Net. HTTPS works out of the box (the operating
system's TLS, no extra DLLs). Settings are made once on the transport and used for every call; credentials never appear in
`OnRequest` / `OnResponse` or in error texts.

```pascal
uses ProRock.Http; // THttpTransportNative

var transport := service.Transport as THttpTransportNative;
transport.ConnectionTimeout := 10000;          // ms
transport.ResponseTimeout := 30000;
transport.SetBasicAuth('user', 'password');   // HTTP Basic (use https)
transport.SetBearerToken(token);              // OAuth 2.0 bearer token
transport.SetHeader('X-API-Key', key);        // any header, e.g. an API key
transport.UserName := 'DOMAIN\user';          // or answer the server's challenge: Basic, Digest, NTLM, Negotiate
transport.Password := 'password';
```

Client certificates (mutual TLS), Delphi 12 or later:

```pascal
transport.ClientCertificate := 'client.pfx';  // a PFX/P12 file (Android: the name of an installed certificate)
transport.ClientCertificateData := bytes;     // or the bytes of a PFX/P12 or PEM file, from memory (not on Android)
transport.ClientCertificatePassword := 'pfx password';
```

One of the two, not both. The sample [`ProRock.Http.ClientCertificate`](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Http.ClientCertificate) makes the call both ways.

### A custom transport

A different HTTP library, request signing, a fake for tests: a custom transport is a `THttpTransport` descendant that
implements `Send`. The default headers (`SetHeader`, `SetBasicAuth`, ...) are already in the request when `Send` gets it.
For example, a fake that answers every call with a prepared response:

```pascal
uses ProRock.Http;

type
  TFakeTransport = class(THttpTransport)
  public
    LastRequest: THttpRequest;
    ResponseBody: string;
  protected
    function Send(const aRequest: THttpRequest): THttpResponse; override;
  end;

function TFakeTransport.Send(const aRequest: THttpRequest): THttpResponse;
begin
  LastRequest := aRequest;          // Method, Url, Headers, Body - the SOAP envelope
  Result.Status := 200;
  Result.Headers := [THttpHeader.Create('Content-Type', 'text/xml; charset=utf-8')];
  Result.Body := ResponseBody;      // a network failure: raise an exception here, as System.Net does
end;
```

```pascal
var fake := TFakeTransport.Create;
fake.ResponseBody := TFile.ReadAllText('checkVatResponse.xml', TEncoding.UTF8);
service.Transport := fake; // the client owns its transport: the previous one is freed, this one is freed with the client
```

To change requests on their way out and keep System.Net (signing, for example), derive from `THttpTransportNative` instead:

```pascal
function TSigningTransport.Send(const aRequest: THttpRequest): THttpResponse;
begin
  var request := aRequest; // a copy: aRequest is const
  request.AddHeader('X-Signature', Sign(request.Body));
  Result := inherited Send(request);
end;
```

## SOAP headers

Header blocks (WS-Addressing, WS-Security tokens, a service's own headers) are added in `OnRequestHeader` and read in
`OnResponseHeader`. Header blocks are Xmlite objects, so generate them from their schema like any other type. The sample
[`ProRock.Soapite.WsSecurity`](https://github.com/VitalyPopov/ProRock/tree/main/Samples/ProRock.Soapite.WsSecurity) adds a WS-Security UsernameToken this way, from units generated from the OASIS schemas.

## Logging

`OnRequest` and `OnResponse` give the raw XML of every call - the envelope only, without the transport's credentials.
