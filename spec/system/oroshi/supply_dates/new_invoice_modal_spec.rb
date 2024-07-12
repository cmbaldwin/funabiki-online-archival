require 'rails_helper'

RSpec.describe 'Oroshi Supply Date - New Invoice Modal', type: :system, js: true do
  include ActiveJob::TestHelper

  let(:admin) { create(:user, :admin) }

  before :each do
    sign_in admin
  end

  context 'within the modal frame' do
    before :each do
      create_list(:oroshi_supplier, 5)
      create_list(:oroshi_supply_date, 3, :with_supplies)
    end

    it 'loads invoice form, creates invoices, displays invoices, and sends mailers' do
      # complete all incomplete supplies
      Oroshi::Supply.incomplete.each do |supply|
        supply.update(price: 1)
      end

      visit oroshi_supplies_path

      # we have no invoices, all links should be to supply_dates created above
      # select all day grid numbers to simulate a selection
      day_grid_numbers = all('.fc-daygrid-day-number')
      day_grid_numbers.first.drag_to(day_grid_numbers.last)
      # click the fc-shikiriNew-button to pop modal
      find('.fc-shikiriNew-button').click
      # look for #new_invoice
      expect(page).to have_css('#new_invoice', visible: true)
      # there should be no visible .list-group-item-warning for incomplete supply warnings
      expect(page).not_to have_css('.list-group-item-warning')
      # within #invoice-form find the select#oroshi_invoice_supplier_organization_ids and select the first option
      option = find('#oroshi_invoice_supplier_organization_ids').all('option').first
      option.select_option
      # check that the list-group within #invoice-form has the text from the selected option
      expect(find('.invoice-form .list-group').text).to include(option.text)
      # click the submit button within #invoice-form
      find('input[type="submit"]').click
      # new invoice should be created, there's only one in the db so get the idea and find #oroshi_invoice_#id
      invoice = nil
      10.times do
        invoice = Oroshi::Invoice.last
        break if invoice.present?

        sleep 1
      end
      expect(page).to have_css("#oroshi_invoice_#{invoice.id}", wait: 5)
      # close the modal and reopen it it has data-bs-dismiss="modal"
      all('button[data-bs-dismiss="modal"]').last.click
      # calendar should refresh on close, expect an .invoice_event to appear (will be multiple, split across weeks)
      expect(page).to have_css('.invoice_event', wait: 5)
      # Check to see if the invoice is present on the invoices page
      visit oroshi_invoices_path(invoice)
      expect(page).to have_css("#oroshi_invoice_#{invoice.id}", wait: 5)
      # go back to the supply calendar page and delete the invoice
      visit oroshi_supplies_path
      # click the .invoice_event to open the modal
      expect(page).to have_css('.invoice_event', wait: 5)
      all('.invoice_event').first.click
      # wait for the modal to load
      expect(page).to have_css("#oroshi_invoice_#{invoice.id}", wait: 5)
      # click the delete button, should be the only btn-danger within the above turbo frame
      accept_alert do
        find("#oroshi_invoice_#{invoice.id} .btn-danger").click
      end
      all('button[data-bs-dismiss="modal"]').last.click
      # modal should be closed, expect .event to be present but no .invoice_event
      expect(page).to have_css('.fc-event', wait: 5)
      expect(page).not_to have_css('.invoice_event')
    end
  end
end
