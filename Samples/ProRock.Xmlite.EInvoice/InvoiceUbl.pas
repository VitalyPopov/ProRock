unit InvoiceUbl;

// The fields of an invoice or a credit note in UBL, the syntax of Peppol and the other form of XRechnung. The two documents have
// separate classes with the same members, but for the line and its quantity and the name of the type code

interface

uses ProRock.Xmlite.Schema.Invoice2, ProRock.Xmlite.Schema.CreditNote2, InvoiceDocument;

procedure TakeFromUblInvoice(aRoot: TInvoiceE; aInvoice: TInvoice);
procedure TakeFromUblCreditNote(aRoot: TCreditNoteE; aInvoice: TInvoice);

implementation

uses ProRock.Xmlite.Schema.CommonAggregateComponents2;

function TakeParty(aParty: TPartyE): TInvoiceParty;
begin
  // the legal name is what CII calls the name; PartyName is the trading name
  Result.Name := '';
  if aParty.PartyLegalEntity.Count > 0 then
    Result.Name := aParty.PartyLegalEntity[0].RegistrationName.XmlValue;
  if (Result.Name = '') and (aParty.PartyName.Count > 0) then
    Result.Name := aParty.PartyName[0].Name.XmlValue;

  var address: TPostalAddressE := aParty.PostalAddress;
  Result.Address := JoinAddress([address.StreetName.XmlValue, address.AdditionalStreetName.XmlValue, address.PostalZone.XmlValue,
    address.CityName.XmlValue, address.Country.IdentificationCode.XmlValue]);

  Result.VatId := '';
  for var scheme in aParty.PartyTaxScheme do
    if scheme.TaxScheme.Id.XmlValue = 'VAT' then
      Result.VatId := scheme.CompanyID.XmlValue;
end;

procedure TakePayment(aMeans: TPaymentMeansEList; aTerms: TPaymentTermsEList; aInvoice: TInvoice);
begin
  if aMeans.Count > 0 then
    aInvoice.Iban := aMeans[0].PayeeFinancialAccount.Id.XmlValue;
  if (aTerms.Count > 0) and (aTerms[0].Note.Count > 0) then
    aInvoice.PaymentTerms := aTerms[0].Note[0].XmlValue;
end;

procedure TakeTotals(aTotal: TLegalMonetaryTotalE; aTaxTotals: TTaxTotalEList; aInvoice: TInvoice);
begin
  aInvoice.LineTotal := aTotal.LineExtensionAmount.XmlValue;
  aInvoice.TaxBasisTotal := aTotal.TaxExclusiveAmount.XmlValue;
  aInvoice.GrandTotal := aTotal.TaxInclusiveAmount.XmlValue;
  aInvoice.DuePayable := aTotal.PayableAmount.XmlValue;

  // a second tax total, if any, is in the tax currency (BT-111) and has no subtotals
  for var taxTotal in aTaxTotals do
    if taxTotal.TaxAmount.CurrencyID = aInvoice.Currency then
    begin
      aInvoice.TaxTotal := taxTotal.TaxAmount.XmlValue;
      for var subtotal in taxTotal.TaxSubtotal do
      begin
        var vat: TInvoiceVat;
        vat.Category := subtotal.TaxCategory.Id.XmlValue;
        vat.Rate := subtotal.TaxCategory.Percent.XmlValue;
        vat.Basis := subtotal.TaxableAmount.XmlValue;
        vat.Amount := subtotal.TaxAmount.XmlValue;
        aInvoice.Vat.Add(vat);
      end;
    end;
end;

function LineVatRate(aItem: TItemE): Double;
begin
  Result := 0;
  if aItem.ClassifiedTaxCategory.Count > 0 then
    Result := aItem.ClassifiedTaxCategory[0].Percent.XmlValue;
end;

procedure TakeFromUblInvoice(aRoot: TInvoiceE; aInvoice: TInvoice);
begin
  aInvoice.Syntax := 'UBL';
  aInvoice.Number := aRoot.Id.XmlValue;
  aInvoice.Kind := InvoiceKind(aRoot.InvoiceTypeCode.XmlValue);
  aInvoice.IssueDate := aRoot.IssueDate.XmlValue;
  aInvoice.DueDate := aRoot.DueDate.XmlValue;
  aInvoice.Currency := aRoot.DocumentCurrencyCode.XmlValue;
  aInvoice.Seller := TakeParty(aRoot.AccountingSupplierParty.Party);
  aInvoice.Buyer := TakeParty(aRoot.AccountingCustomerParty.Party);
  TakePayment(aRoot.PaymentMeans, aRoot.PaymentTerms, aInvoice);
  TakeTotals(aRoot.LegalMonetaryTotal, aRoot.TaxTotal, aInvoice);

  for var item in aRoot.InvoiceLine do
  begin
    var line: TInvoiceLine;
    line.Id := item.Id.XmlValue;
    line.Name := item.Item.Name.XmlValue;
    line.Quantity := item.InvoicedQuantity.XmlValue;
    line.UnitCode := item.InvoicedQuantity.UnitCode;
    line.Price := item.Price.PriceAmount.XmlValue;
    line.VatRate := LineVatRate(item.Item);
    line.Amount := item.LineExtensionAmount.XmlValue;
    aInvoice.Lines.Add(line);
  end;
end;

procedure TakeFromUblCreditNote(aRoot: TCreditNoteE; aInvoice: TInvoice);
begin
  aInvoice.Syntax := 'UBL';
  aInvoice.Number := aRoot.Id.XmlValue;
  aInvoice.Kind := InvoiceKind(aRoot.CreditNoteTypeCode.XmlValue);
  aInvoice.IssueDate := aRoot.IssueDate.XmlValue;
  aInvoice.Currency := aRoot.DocumentCurrencyCode.XmlValue;
  aInvoice.Seller := TakeParty(aRoot.AccountingSupplierParty.Party);
  aInvoice.Buyer := TakeParty(aRoot.AccountingCustomerParty.Party);
  TakePayment(aRoot.PaymentMeans, aRoot.PaymentTerms, aInvoice);
  TakeTotals(aRoot.LegalMonetaryTotal, aRoot.TaxTotal, aInvoice);

  for var item in aRoot.CreditNoteLine do
  begin
    var line: TInvoiceLine;
    line.Id := item.Id.XmlValue;
    line.Name := item.Item.Name.XmlValue;
    line.Quantity := item.CreditedQuantity.XmlValue;
    line.UnitCode := item.CreditedQuantity.UnitCode;
    line.Price := item.Price.PriceAmount.XmlValue;
    line.VatRate := LineVatRate(item.Item);
    line.Amount := item.LineExtensionAmount.XmlValue;
    aInvoice.Lines.Add(line);
  end;
end;

end.
