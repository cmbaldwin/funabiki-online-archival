module Oroshi
  class Invoice < ApplicationRecord
    # Callbacks
    before_destroy :ensure_not_sent

    # Associations
    has_many :invoice_supply_dates, class_name: 'Oroshi::Invoice::SupplyDate', dependent: :destroy
    has_many :supply_dates, through: :invoice_supply_dates
    has_many :supplies, through: :supply_dates
    has_many :invoice_supplier_organizations, class_name: 'Oroshi::Invoice::SupplierOrganization', dependent: :destroy
    has_many :supplier_organizations, through: :invoice_supplier_organizations

    # Validations
    validates :start_date, :end_date, :invoice_layout, presence: true
    validates :send_email, inclusion: { in: [true, false] }
    validates :send_at, presence: true, if: :send_email?
    validate :at_least_one_supplier_organization

    # Enums
    enum invoice_layout: { standard: 1, simple: 2 }

    # Broadcasts
    broadcasts :invoice, inserts_by: :replace

    # Scopes
    scope :unsent, -> { where(send_email: true, sent_at: nil).where('send_at <= ?', Time.zone.now) }

    private

    def at_least_one_supplier_organization
      errors.add(:supplier_organizations, "少なくとも1つ必要です") if supplier_organizations.empty?
    end

    def ensure_not_sent
      return unless sent_at.present?

      errors.add(:base, "送信済みの仕切り書を削除できません。")
      throw(:abort)
    end
  end
end
