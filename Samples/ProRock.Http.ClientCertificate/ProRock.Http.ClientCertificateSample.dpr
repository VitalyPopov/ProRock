program ProRock.Http.ClientCertificateSample;

{$APPTYPE CONSOLE}

// Client certificates (mutual TLS) on THttpTransportNative - the same transport a generated Soapite client uses
// (service.Transport). https://client.badssl.com is a public test server that requires a client certificate: HTTP 400
// without one, 200 with its published test certificate. It is not a SOAP service, so this sample calls it through the
// transport directly; for a SOAP service, set the same properties on THttpTransportNative(service.Transport).
// The certificate may come from a file (ClientCertificate) or from memory (ClientCertificateData - bytes from a database,
// a resource, a key vault).
// Needs Delphi 12 or later (System.Net's client certificate support).
// Usage: ProRock.Http.ClientCertificateSample [<certificate.p12> <password>]
// Without arguments: badssl.com-client.p12 next to the exe, password badssl.com - download it from
// https://badssl.com/certs/badssl.com-client.p12 (badssl.com's public test certificate, not included here)

uses
  System.SysUtils, System.IOUtils,
  ProRock.Http;

const
  cUrl = 'https://client.badssl.com/';
  cBadsslCertificate = 'badssl.com-client.p12';
  cBadsslPassword = 'badssl.com';

procedure Call(const aTitle, aCertificate: string; const aCertificateData: TBytes; const aPassword: string);
begin
  var transport: THttpTransportNative := THttpTransportNative.Create;
  try
    transport.ClientCertificate := aCertificate;         // a file
    transport.ClientCertificateData := aCertificateData; // or its bytes - one of them
    transport.ClientCertificatePassword := aPassword;

    var request: THttpRequest;
    request.Method := 'GET';
    request.Url := cUrl;
    try
      var response: THttpResponse := transport.Execute(request);
      Writeln(Format('%-20s HTTP %d', [aTitle, response.Status]));
    except
      on e: Exception do // a missing file or a wrong password: the System.Net message, never the password
        Writeln(Format('%-20s failed: %s', [aTitle, e.Message]));
    end;
  finally
    transport.Free;
  end;
end;

begin
  var certificate: string := ExtractFilePath(ParamStr(0)) + cBadsslCertificate;
  var password: string := cBadsslPassword;
  if ParamCount >= 2 then
  begin
    certificate := ParamStr(1);
    password := ParamStr(2);
  end;

  if FileExists(certificate) then
  begin
    Writeln(cUrl);
    Call('without certificate', '', [], '');  // 400: "No required SSL certificate was sent"
    Call('with certificate', certificate, [], password); // 200
    Call('from memory', '', TFile.ReadAllBytes(certificate), password); // 200
  end
  else
  begin
    Writeln('Certificate not found: ', certificate);
    Writeln('Download badssl.com''s public test certificate and put it next to the exe:');
    Writeln('  https://badssl.com/certs/', cBadsslCertificate);
    Writeln('(the sample knows its password; your own certificate: run with <certificate.p12> <password>)');
    ExitCode := 1;
  end;

  Writeln;
  Write('Press <Enter> to quit.');
  Readln;
end.
