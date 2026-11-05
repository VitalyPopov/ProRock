program ProRock.Xmlite.EInvoiceSample;

// An electronic invoice under EN 16931 in either of its syntaxes, UN/CEFACT CII (ZUGFeRD, Factur-X, XRechnung) or OASIS UBL
// (Peppol, XRechnung), read into the classes ProRocket generates from the official schemas, shown in one window, and written back.
// invoice-cii.xml and invoice-ubl.xml are the same invoice. Usage: ProRock.Xmlite.EInvoiceSample [<file>] - or open / drop a file.
//
// XML only: no PDF (a ZUGFeRD or Factur-X file holds its XML inside a PDF), no check of a document against the rules of EN 16931.
//
// The schemas: Copyright (C) UN/CEFACT (2016), Copyright (c) OASIS Open 2024 - see THIRD-PARTY-NOTICES.md.
// The invoices: from KoSIT's xrechnung-testsuite, Apache License 2.0.

uses
  Vcl.Forms,
  Form.Main in 'Form.Main.pas' {MainForm},
  InvoiceDocument in 'InvoiceDocument.pas',
  InvoiceCii in 'InvoiceCii.pas',
  InvoiceUbl in 'InvoiceUbl.pas',
  ProRock.Xmlite.Schema.CrossIndustryInvoice100 in 'ProRock.Xmlite.Schema.CrossIndustryInvoice100.pas',
  ProRock.Xmlite.Schema.QualifiedDataType100 in 'ProRock.Xmlite.Schema.QualifiedDataType100.pas',
  ProRock.Xmlite.Schema.ReusableAggregateBusinessInformationEntity100 in 'ProRock.Xmlite.Schema.ReusableAggregateBusinessInformationEntity100.pas',
  ProRock.Xmlite.Schema.UnqualifiedDataType100 in 'ProRock.Xmlite.Schema.UnqualifiedDataType100.pas',
  ProRock.Xmlite.Schema.Invoice2 in 'ProRock.Xmlite.Schema.Invoice2.pas',
  ProRock.Xmlite.Schema.CreditNote2 in 'ProRock.Xmlite.Schema.CreditNote2.pas',
  ProRock.Xmlite.Schema.CommonAggregateComponents2 in 'ProRock.Xmlite.Schema.CommonAggregateComponents2.pas',
  ProRock.Xmlite.Schema.CommonBasicComponents2 in 'ProRock.Xmlite.Schema.CommonBasicComponents2.pas',
  ProRock.Xmlite.Schema.CommonExtensionComponents2 in 'ProRock.Xmlite.Schema.CommonExtensionComponents2.pas',
  ProRock.Xmlite.Schema.CommonSignatureComponents2 in 'ProRock.Xmlite.Schema.CommonSignatureComponents2.pas',
  ProRock.Xmlite.Schema.CoreComponentTypeSchemaModule2 in 'ProRock.Xmlite.Schema.CoreComponentTypeSchemaModule2.pas',
  ProRock.Xmlite.Schema.QualifiedDataTypes2 in 'ProRock.Xmlite.Schema.QualifiedDataTypes2.pas',
  ProRock.Xmlite.Schema.SignatureAggregateComponents2 in 'ProRock.Xmlite.Schema.SignatureAggregateComponents2.pas',
  ProRock.Xmlite.Schema.SignatureBasicComponents2 in 'ProRock.Xmlite.Schema.SignatureBasicComponents2.pas',
  ProRock.Xmlite.Schema.UnqualifiedDataTypes1 in 'ProRock.Xmlite.Schema.UnqualifiedDataTypes1.pas',
  ProRock.Xmlite.Schema.Xades in 'ProRock.Xmlite.Schema.Xades.pas',
  ProRock.Xmlite.Schema.Xades141 in 'ProRock.Xmlite.Schema.Xades141.pas',
  ProRock.Xmlite.Schema.Xmldsig in 'ProRock.Xmlite.Schema.Xmldsig.pas',
  ProRock.Xmlite.Schema.Xmldsig11 in 'ProRock.Xmlite.Schema.Xmldsig11.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
