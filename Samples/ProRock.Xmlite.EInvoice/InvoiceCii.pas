unit InvoiceCii;

// The fields of an invoice in CII (CrossIndustryInvoice), the syntax of ZUGFeRD, Factur-X and one form of XRechnung. Most amounts
// are lists in this schema, read through First: a document normally has one of each

interface

uses ProRock.Xmlite.Schema.CrossIndustryInvoice100, InvoiceDocument;

procedure TakeFromCii(aRoot: TCrossIndustryInvoiceE; aInvoice: TInvoice);

implementation

uses ProRock.Xmlite.Schema.ReusableAggregateBusinessInformationEntity100, ProRock.Xmlite.Schema.UnqualifiedDataType100;

function First(aAmounts: TAmountCTList): Double;
begin
  if aAmounts.Count > 0 then
    Result := aAmounts[0].XmlValue
  else
    Result := 0;
end;

// format 102 is the one EN 16931 allows: 20130630
function DateText(aDate: TDateTimeCT): string;
begin
  Result := aDate.DateTimeString.XmlValue;
  if Length(Result) = 8 then
    Result := Copy(Result, 1, 4) + '-' + Copy(Result, 5, 2) + '-' + Copy(Result, 7, 2);
end;

function TakeParty(aParty: TTradePartyCT): TInvoiceParty;
begin
  Result.Name := aParty.Name.XmlValue;
  var address: TTradeAddressCT := aParty.PostalTradeAddress;
  Result.Address := JoinAddress([address.LineOne.XmlValue, address.LineTwo.XmlValue, address.PostcodeCode.XmlValue,
    address.CityName.XmlValue, address.CountryID.XmlValue]);
  Result.VatId := '';
  for var registration in aParty.SpecifiedTaxRegistration do
    if registration.Id.SchemeID = 'VA' then // VA: VAT, FC: a national tax number
      Result.VatId := registration.Id.XmlValue;
end;

procedure TakeFromCii(aRoot: TCrossIndustryInvoiceE; aInvoice: TInvoice);
begin
  aInvoice.Syntax := 'CII';
  aInvoice.Number := aRoot.ExchangedDocument.Id.XmlValue;
  aInvoice.Kind := InvoiceKind(aRoot.ExchangedDocument.TypeCode.XmlValue);
  aInvoice.IssueDate := DateText(aRoot.ExchangedDocument.IssueDateTime);

  var transaction: TSupplyChainTradeTransactionCT := aRoot.SupplyChainTradeTransaction;
  aInvoice.Seller := TakeParty(transaction.ApplicableHeaderTradeAgreement.SellerTradeParty);
  aInvoice.Buyer := TakeParty(transaction.ApplicableHeaderTradeAgreement.BuyerTradeParty);

  var settlement: THeaderTradeSettlementCT := transaction.ApplicableHeaderTradeSettlement;
  aInvoice.Currency := settlement.InvoiceCurrencyCode.XmlValue;

  if settlement.SpecifiedTradeSettlementPaymentMeans.Count > 0 then
    aInvoice.Iban := settlement.SpecifiedTradeSettlementPaymentMeans[0].PayeePartyCreditorFinancialAccount.Ibanid.XmlValue;
  if settlement.SpecifiedTradePaymentTerms.Count > 0 then
  begin
    var terms: TTradePaymentTermsCT := settlement.SpecifiedTradePaymentTerms[0];
    aInvoice.DueDate := DateText(terms.DueDateDateTime);
    if terms.Description.Count > 0 then
      aInvoice.PaymentTerms := terms.Description[0].XmlValue;
  end;

  var total: TTradeSettlementHeaderMonetarySummationCT := settlement.SpecifiedTradeSettlementHeaderMonetarySummation;
  aInvoice.LineTotal := First(total.LineTotalAmount);
  aInvoice.TaxBasisTotal := First(total.TaxBasisTotalAmount);
  aInvoice.GrandTotal := First(total.GrandTotalAmount);
  aInvoice.DuePayable := First(total.DuePayableAmount);

  // a second tax total, if any, is in the tax currency (BT-111); the currency attribute tells them apart
  for var amount in total.TaxTotalAmount do
    if amount.CurrencyID = aInvoice.Currency then
      aInvoice.TaxTotal := amount.XmlValue;

  for var tax in settlement.ApplicableTradeTax do
  begin
    var vat: TInvoiceVat;
    vat.Category := tax.CategoryCode.XmlValue;
    vat.Rate := tax.RateApplicablePercent.XmlValue;
    vat.Basis := First(tax.BasisAmount);
    vat.Amount := First(tax.CalculatedAmount);
    aInvoice.Vat.Add(vat);
  end;

  for var item in transaction.IncludedSupplyChainTradeLineItem do
  begin
    var line: TInvoiceLine;
    line.Id := item.AssociatedDocumentLineDocument.LineID.XmlValue;
    line.Name := '';
    if item.SpecifiedTradeProduct.Name.Count > 0 then
      line.Name := item.SpecifiedTradeProduct.Name[0].XmlValue;
    line.Quantity := item.SpecifiedLineTradeDelivery.BilledQuantity.XmlValue;
    line.UnitCode := item.SpecifiedLineTradeDelivery.BilledQuantity.UnitCode;
    line.Price := First(item.SpecifiedLineTradeAgreement.NetPriceProductTradePrice.ChargeAmount);
    line.VatRate := 0;
    if item.SpecifiedLineTradeSettlement.ApplicableTradeTax.Count > 0 then
      line.VatRate := item.SpecifiedLineTradeSettlement.ApplicableTradeTax[0].RateApplicablePercent.XmlValue;
    line.Amount := First(item.SpecifiedLineTradeSettlement.SpecifiedTradeSettlementLineMonetarySummation.LineTotalAmount);
    aInvoice.Lines.Add(line);
  end;
end;

end.
