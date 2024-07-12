require 'rails_helper'

RSpec.describe 'Oroshi Supply Date - Show action', type: :system, js: true do
  let(:admin) { create(:user, :admin) }

  before :each do
    sign_in admin
  end

  context 'interaction with calendar' do
    it 'creates and shows empty Supply Date from calendar' do
      visit oroshi_supplies_path

      # find a .fc-daygrid-day-frame and click it (fullcalendar responds to interaction on this node)
      find('.fc-daygrid-day-frame', match: :first).click
      # page should have text '牡蠣供給記載表'
      expect(page).to have_content('牡蠣供給記載表')
    end
  end

  context 'interaction with full fullcalendar' do
    before :each do
      create_list(:oroshi_supplier, 5)
      create_list(:oroshi_supply_date, 3, :with_supplies)
      visit oroshi_supplies_path
    end

    it 'loads existing Supply Date supply data' do
      # find the first .fc-event and click it
      find('.fc-event', match: :first).click
      # check that the page has .input-group input.quantity elements
      expect(page).to have_css('.supplier-column')
      expect(page).to have_css('.input-group input.quantity', minimum: 3)
      quantity_inputs = all('.input-group input.quantity')
      expect(quantity_inputs.size).to be > 0
    end

    it 'creates and shows and updates Supply Date from calendar' do
      # find a .fc-daygrid-day-frame and click it (fullcalendar responds to interaction on this node)
      expect(page).to have_css('.fc-daygrid-day-frame', minimum: 1, wait: 5)
      find('.fc-daygrid-day-frame', match: :first).click
      # page should have many oroshi_supply_### turbo-frames
      expect(page).to have_css('.input-group input.quantity', minimum: 3)
      # find one of the inputs, get the id, and fill it with 100, and simulate 'tab' keypress to save
      input = find('.input-group input.quantity', match: :first)
      supply_id = input[:id].split('_').last
      input.set('100')
      input.send_keys(:tab)
      # check that the supply turbo_frame was updated turbo-frame#oroshi_supply_###"
      supply_frame = find("#oroshi_supply_#{supply_id}")
      expect(supply_frame).to have_css('.handle.bg-success')
      # check that the database entry was updated
      supply = Oroshi::Supply.find(supply_id)
      expect(supply.quantity).to eq(100)
    end
  end
end
