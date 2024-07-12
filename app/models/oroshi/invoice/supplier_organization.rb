class Oroshi::Invoice::SupplierOrganization < ApplicationRecord
  # Associations
  belongs_to :invoice, class_name: 'Oroshi::Invoice'
  belongs_to :supplier_organization, class_name: 'Oroshi::SupplierOrganization'

  # Attachments
  has_many_attached :invoices

  # Callbacks
  after_destroy :purge_invoices

  private

  def purge_invoices
    invoices.purge
  end
end
