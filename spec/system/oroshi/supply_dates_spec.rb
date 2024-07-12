require 'rails_helper'

RSpec.describe 'Oroshi Supply Date', type: :system, js: true do
  let(:admin) { create(:user, :admin) }

  before :each do
    sign_in admin
  end

  context 'interaction with empty fullcalendar' do
    it 'loads calendar' do
      visit oroshi_supplies_path

      # check if the calendar is loaded, the title should be in the format of yyyy年mm月
      expect(page).to have_css('.fc-toolbar-title', text: /\d{4}年\d{1,2}月/, visible: true)
    end
  end

  context 'basic interaction with full fullcalendar' do
    before :each do
      create_list(:oroshi_supplier, 5)
      create_list(:oroshi_supply_date, 3, :with_supplies)
    end

    it 'loads calendar events, dates are selectable for buttons, and buttons pop modals' do
      visit oroshi_supplies_path

      # we have no invoices, all links should be to supply_dates created above
      links = all('a[href^="/oroshi/supply_dates/"]')
      expect links.count == 5
      expect(links.all? { |link| link[:href] =~ %r{/oroshi/supply_dates/\d{4}-\d{2}-\d{2}} }).to be true
      # select all day grid numbers to simulate a selection
      day_grid_numbers = all('.fc-daygrid-day-number')
      day_grid_numbers.first.drag_to(day_grid_numbers.last)
      # check if all the buttons are activated now, '.fc-toolbar-chunk button'
      buttons = all('.fc-toolbar-chunk button')
      expect(buttons.all? { |button| button[:disabled] == 'false' }).to be true
      # click the fc-shikiriNew-button to pop modal
      find('.fc-shikiriNew-button').click
      # look for #new_invoice
      expect(page).to have_css('#new_invoice', visible: true)
      # exit the modal
      find('.btn-close').click
      # wait for animation to finish
      sleep 0.3
      # select again
      day_grid_numbers = all('.fc-daygrid-day-number')
      day_grid_numbers.first.drag_to(day_grid_numbers.last)
      # expect to find a enabled fc-tankaEntry-button to pop modal, click it
      expect(page).to have_css('.fc-tankaEntry-button', visible: true, wait: 5)
      start_time = Time.now
      # loop to click the button to prevent async js interaction issue
      loop do
          find('.fc-tankaEntry-button').click
          break # if click is successful, break out of the loop
      rescue Capybara::ElementNotInteractable
          # if click is not successful, wait a short time and try again
          sleep 0.1
          raise "Button not clickable after 10 seconds" if Time.now - start_time > 10
      end
      # look for #price_actions_container
      expect(page).to have_css('#price_actions_container', visible: true)
    end
  end
end
