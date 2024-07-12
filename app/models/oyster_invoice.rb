class OysterInvoice < ApplicationRecord
  has_many :oyster_invoices_supply
  has_many :oyster_supplies, through: :oyster_invoices_supply, validate: false

  after_destroy :destroy_message

  # Old Carrierwave format (prior to Ruby 3 and Rails6/ActiveStorage)
  mount_uploader :aioi_all_pdf, OysterInvoiceUploader
  mount_uploader :aioi_seperated_pdf, OysterInvoiceUploader
  mount_uploader :sakoshi_all_pdf, OysterInvoiceUploader
  mount_uploader :sakoshi_seperated_pdf, OysterInvoiceUploader

  has_one_attached :sakoshi_collected_invoice
  has_one_attached :sakoshi_individual_invoice
  has_one_attached :aioi_collected_invoice
  has_one_attached :aioi_individual_invoice

  validates :start_date, presence: true
  validates :end_date, presence: true

  serialize :data, type: Hash

  # Needed for carrierwave filename creation
  attr_accessor :location, :start_date_str, :end_date_str, :export_format, :emails, :regenerate

  def destroy_message
    msg_id = data[:message]
    return unless msg_id && Message.exists?(msg_id)

    Message.find(msg_id).destroy
  end

  def display_date
    "#{start_date} ~ #{Date.parse(end_date) - 1.day}"
  end

  def date_range
    Date.parse(start_date)..(Date.parse(end_date) - 1.day)
  end

  def self.search(id)
    if id
      where(id: id).order(start_date: :desc)
    else
      order(start_date: :desc)
    end
  end
end
