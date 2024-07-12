require 'rails_helper'

RSpec.describe 'Oroshi Supply Date - Price Entry Modal', type: :system, js: true do
  let(:admin) { create(:user, :admin) }

  before :each do
    sign_in admin
  end

  context 'within the modal frame' do
    before :each do
      # testing the add section button and nav tabs require multiple suppliers with multiple suppliers each
      supplier_organization_one = create(:oroshi_supplier_organization)
      supplier_organization_two = create(:oroshi_supplier_organization)
      create_list(:oroshi_supplier, 3, supplier_organization: supplier_organization_one)
      create_list(:oroshi_supplier, 3, supplier_organization: supplier_organization_two)
      create_list(:oroshi_supply_date, 1, :with_supplies)
    end

    it 'loads price entry form, and price entry form functions' do
      # confirm that there are supplies, and there are supplies without prices
      expect(Oroshi::Supply.incomplete).not_to be_empty

      visit oroshi_supplies_path

      # select all day grid numbers to simulate a selection
      day_grid_numbers = all('.fc-daygrid-day-number')
      day_grid_numbers.first.drag_to(day_grid_numbers.last)
      # click the fc-shikiriNew-button to pop modal
      find('.fc-tankaEntry-button').click
      # look for #price_actions_container
      expect(page).to have_css('#price_actions_container', visible: true)
      # expect #price_actions_container .nav-tabs to have buttons for each button enter prices
      expect(find('#price_actions_container .nav-tabs').all('button').count).to be > 0
      tab_buttons = all('#price_actions_container .nav-tabs button')
      tab_buttons.each do |button|
        # only on first tab
        if button == tab_buttons.first
          # expect only one .price_card to be visible
          expect(page).to have_css('.price_card', visible: true)
          # click the button to add a price card (#add-section)
          find('#add-section').click
          # expect two .price_card to be visible
          expect(page).to have_css('.price_card', visible: true, count: 2)
        else
          button.click
          # expect the button text to be visible within .tab-content
          expect(find('.tab-content').text).to include(button.text)
          # add a section
          find('#add-section').click
        end
        # select the first option in the first price card
        price_cards = all('.price_card')
        price_cards.first.find('select').all('option').first.click
        # find .suppliers_prices within the first price card fill all inputs with 1
        first_suppliers_prices = price_cards.first.all('.suppliers_prices')
        first_suppliers_prices.first.all('input').first.set(1) # weird bug where first input is not set
        first_suppliers_prices.first.all('input').each do |input|
          input.set(1)
        end
        # within the second price card, select all the remaining options by clicking the first and dragging to the last
        select_box = price_cards.last.find('select')
        options = select_box.all('option')
        options.each do |option|
          select_box.select(option.text)
        end
        # find .suppliers_prices within the second price card fill all inputs with 1
        second_suppliers_prices = price_cards.last.all('.suppliers_prices')
        second_suppliers_prices.last.all('input').each do |input|
          input.set(1)
        end
      end
      # click the submit button within #price_actions_container
      find('input[type="submit"]').click
      # expect price_action_container to now have one nav-pill (we only created 1 supply date)
      expect(page).to have_css('#price_actions_container .nav-pills', count: 1)
      # there should no longer be any incomplete supplies in the database, and all records should have a price of 1
      expect(Oroshi::Supply.incomplete).to be_empty
      expect(Oroshi::Supply.all.all? { |supply| supply.price == 1 }).to be true
    end

    it 'loads invoice form and shows incomplete supplies warning' do
      # confirm that there are supplies, and there are supplies without prices
      expect(Oroshi::Supply.incomplete).not_to be_empty

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
      expect(page).to have_css('.list-group-item-warning')
    end

    it 'loads invoice form and creates previews' do
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
      # click the first preview button within #invoice-preview-area
      all('.invoice-preview-area a.btn').first.click
      # close the modal and check that a .message exists
      find('.modal-footer button').click
      expect(page).to have_css('.message', visible: true)
    end
  end
end
