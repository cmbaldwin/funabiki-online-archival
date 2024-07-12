class OroshiInvoiceMailerPreview < ActionMailer::Preview
  def invoice_notification_email
    invoice_supplier_organization = Oroshi::Invoice.last.invoice_supplier_organizations.first
    Oroshi::InvoiceMailer.invoice_notification(invoice_supplier_organization.id)
  end
end
