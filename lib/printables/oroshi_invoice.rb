# frozen_string_literal: true

# Restaurant Order Packing Lists PDF Generator
class OroshiInvoice < Printable
  include ActionView::Helpers::TranslationHelper
  include Shared
  include OrganizationInvoice
  include SupplierInvoice
  include SupplyIterators
  include InvoiceLayoutOne
  include InvoiceLayoutTwo
  include SupplierYearToDateTable

  # @param [Date] start_date
  # @param [Date] end_date
  # @param [String] supplier_organization
  # @param [String] format -> 'organization' or 'supplier'
  # @param [String] layout -> 'simple' or 'standard' for now
  # @param [String] password
  def initialize(start_date, end_date, supplier_organization: '1', invoice_format: 'organization', layout: 'simple', password: nil, invoice_date: nil)
    super(margin: [15, 15, 30, 15])
    @date_range = start_date..end_date
    @supplier_organization = Oroshi::SupplierOrganization.find(supplier_organization)
    @password = password
    @invoice_format = invoice_format
    @layout = layout_number(layout)
    @invoice_date = invoice_date
    set_password unless set_password.empty?
    init_vars
    send("generate_#{@invoice_format}_invoice")
  end

  private

  def layout_number(layout)
    %w[standard simple].index(layout) + 1
  end

  def set_password
    encrypt_document(user_password: @password, owner_password: @password)
  end

  def init_vars
    supply_dates
    supplies
    suppliers
  end

  # Initialize instance variables
  def supply_dates
    @supply_dates = Oroshi::SupplyDate.includes(:supplies, :suppliers, :supplier_organizations)
                                      .where(date: @date_range)
                                      .order(:date).to_a
    @supply_dates
  end

  def supplies
    @supplies = @supply_dates.flat_map(&:supply).select do |supply|
      supply if supply.supplier_organization == @supplier_organization
    end
    @supplies
  end

  def suppliers
    @suppliers = @supply_dates.flat_map(&:suppliers).uniq.select do |supplier|
      supplier if supplier.supplier_organization == @supplier_organization
    end.sort_by!(&:supplier_number)
    @suppliers
  end
end
