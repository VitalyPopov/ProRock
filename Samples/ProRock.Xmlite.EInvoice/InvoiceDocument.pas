unit InvoiceDocument;

// An electronic invoice in either syntax of EN 16931 - UN/CEFACT CII or OASIS UBL - read into the classes generated from the
// official schemas, and the same few fields taken from it: InvoiceCii.pas and InvoiceUbl.pas are all that differs. The root
// element says which. Reading is not checking: nothing here validates a document or adds up its totals

interface

uses System.SysUtils, System.Generics.Collections, ProRock.Xmlite;

type
  TInvoiceParty = record
    Name, Address, VatId: string;
  end;

  TInvoiceLine = record
    Id, Name, UnitCode: string;
    Quantity, Price, VatRate, Amount: Double;
  end;

  TInvoiceVat = record
    Category: string;
    Rate, Basis, Amount: Double;
  end;

  // ProRock reads amounts as Double: exact up to 15 significant digits
  TInvoice = class
  public
    Syntax, Number, Kind, IssueDate, DueDate, Currency, Iban, PaymentTerms: string;
    Seller, Buyer: TInvoiceParty;
    LineTotal, TaxBasisTotal, TaxTotal, GrandTotal, DuePayable: Double;
    Lines: TList<TInvoiceLine>;
    Vat: TList<TInvoiceVat>;

    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  end;

  TInvoiceDocument = class
  private
    fRoot: TXmliteComplexType; // what the file holds: a TCrossIndustryInvoiceE, TInvoiceE or TCreditNoteE
    fInvoice: TInvoice;
    fReadMs: Double;
  public
    constructor Create;
    destructor Destroy; override;

    // raises EInvoiceDocument for a file that is neither
    procedure Load(const aFileName: string);
    procedure Save(const aFileName: string);

    property Invoice: TInvoice read fInvoice;
    property ReadMs: Double read fReadMs;
  end;

  EInvoiceDocument = class(Exception);

// the parts that are there, on one line
function JoinAddress(const aParts: array of string): string;

// BT-3, the code of the document's kind: the ones EN 16931 names most, else the code itself
function InvoiceKind(const aTypeCode: string): string;

implementation

uses System.IOUtils, System.Diagnostics, System.RegularExpressions,
  ProRock.Xmlite.Schema.CrossIndustryInvoice100, ProRock.Xmlite.Schema.Invoice2, ProRock.Xmlite.Schema.CreditNote2,
  InvoiceCii, InvoiceUbl;

function JoinAddress(const aParts: array of string): string;
begin
  Result := '';
  for var part in aParts do
    if part <> '' then
      if Result = '' then
        Result := part
      else
        Result := Result + ', ' + part;
end;

function InvoiceKind(const aTypeCode: string): string;
begin
  if aTypeCode = '380' then
    Result := 'Invoice'
  else if aTypeCode = '381' then
    Result := 'Credit note'
  else if aTypeCode = '384' then
    Result := 'Corrected invoice'
  else if aTypeCode = '389' then
    Result := 'Self-billed invoice'
  else
    Result := 'Document type ' + aTypeCode;
end;

{ TInvoice }

constructor TInvoice.Create;
begin
  inherited;
  Lines := TList<TInvoiceLine>.Create;
  Vat := TList<TInvoiceVat>.Create;
end;

destructor TInvoice.Destroy;
begin
  Vat.Free;
  Lines.Free;
  inherited;
end;

procedure TInvoice.Clear;
begin
  Syntax := '';
  Number := '';
  Kind := '';
  IssueDate := '';
  DueDate := '';
  Currency := '';
  Iban := '';
  PaymentTerms := '';
  Seller := Default(TInvoiceParty);
  Buyer := Default(TInvoiceParty);
  LineTotal := 0;
  TaxBasisTotal := 0;
  TaxTotal := 0;
  GrandTotal := 0;
  DuePayable := 0;
  Lines.Clear;
  Vat.Clear;
end;

{ TInvoiceDocument }

constructor TInvoiceDocument.Create;
begin
  inherited;
  fInvoice := TInvoice.Create;
end;

destructor TInvoiceDocument.Destroy;
begin
  fInvoice.Free;
  fRoot.Free;
  inherited;
end;

procedure TInvoiceDocument.Load(const aFileName: string);
begin
  var xml: string := TFile.ReadAllText(aFileName, TEncoding.UTF8);

  // the first element, past the declaration and comments: the example invoices open with a comment
  var root: TMatch := TRegEx.Match(xml, '^(?:\s|<\?.*?\?>|<!--.*?-->)*<(?:[\w.-]+:)?([\w.-]+)', [roSingleLine]);
  var name: string := '';
  if root.Success then
    name := root.Groups[1].Value;

  var read: TXmliteComplexType;
  if name = 'CrossIndustryInvoice' then
    read := TCrossIndustryInvoiceE.Create
  else if name = 'Invoice' then
    read := TInvoiceE.Create
  else if name = 'CreditNote' then
    read := TCreditNoteE.Create
  else
    raise EInvoiceDocument.Create('Neither a CII invoice nor a UBL invoice or credit note');

  // read without a copy of the text: xml is not needed afterwards
  var watch: TStopwatch := TStopwatch.StartNew;
  if not read.FromXmlInPlace(xml) then
  begin
    read.Free;
    raise EInvoiceDocument.Create('The file is not well-formed XML');
  end;
  fReadMs := watch.Elapsed.TotalMilliseconds;

  FreeAndNil(fRoot);
  fRoot := read;

  fInvoice.Clear;
  if name = 'CrossIndustryInvoice' then
    TakeFromCii(TCrossIndustryInvoiceE(fRoot), fInvoice)
  else if name = 'Invoice' then
    TakeFromUblInvoice(TInvoiceE(fRoot), fInvoice)
  else
    TakeFromUblCreditNote(TCreditNoteE(fRoot), fInvoice);
end;

procedure TInvoiceDocument.Save(const aFileName: string);
begin
  if fRoot <> nil then
    TFile.WriteAllText(aFileName, fRoot.ToXml, TEncoding.UTF8);
end;

end.
