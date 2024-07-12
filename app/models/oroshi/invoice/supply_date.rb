class Oroshi::Invoice::SupplyDate < ApplicationRecord
  # Callbacks
  after_create :lock_supplies
  before_destroy :unlock_supplies

  # Associations
  belongs_to :invoice, class_name: 'Oroshi::Invoice'
  belongs_to :supply_date, class_name: 'Oroshi::SupplyDate'

  def supplies_with_invoice_supplier_organizations
    supply_date.supplies.joins(:supplier)
               .where(oroshi_suppliers: { supplier_organization_id: invoice.supplier_organization_ids })
  end

  private

  def lock_supplies
    supplies_with_invoice_supplier_organizations.update_all(locked: true)
  end

  def unlock_supplies
    supplies_with_invoice_supplier_organizations.update_all(locked: false)
  end
end
