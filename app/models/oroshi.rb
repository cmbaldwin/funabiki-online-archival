# Module: Oroshi (Oroshi, or 卸し, means "wholesale" in Japanese)
# This module is used to store all the classes and modules for the Oroshi application
# To get a list of constants for use with erd (domain name mapping graphics), use:
# Oroshi.constants.map{|c| "Oroshi::#{c.to_s}" unless c.to_s.include?('Controller') || c.to_s.include?('Helper') || c.to_s.include?('Worker') }.compact.join(', ')
# e.g. (in the terminal):
# rails erd only="Oroshi::SupplyType, Oroshi::Invoice, Oroshi::SupplyReceptionTime, Oroshi::Product, Oroshi::Material, Oroshi::Supplier, Oroshi::Address, Oroshi::Buyer, Oroshi::Order, Oroshi::OrderTemplate, Oroshi::Packaging, Oroshi::ProductInventory, Oroshi::ProductVariation, Oroshi::ProductionRequest, Oroshi::ProductionZone, Oroshi::ShippingMethod, Oroshi::ShippingOrganization, Oroshi::ShippingReceptacle, Oroshi::Supply, Oroshi::SupplierOrganization, Oroshi::SupplyTypeVariation, Oroshi::SupplyDate, Oroshi::Invoice::SupplierOrganization, Oroshi::Invoice::SupplyDate, Oroshi::SupplyDate::SupplyTypeVariation, Oroshi::SupplyDate::SupplyType"
# optional additions: "ActiveStorage::VariantRecord, ActiveStorage::Blob, ActiveStorage::Attachment, Message"

module Oroshi
  def self.table_name_prefix
    'oroshi_'
  end
end
