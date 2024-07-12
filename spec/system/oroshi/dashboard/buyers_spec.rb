require 'rails_helper'

RSpec.describe 'Oroshi Dashboard - Buyer settings', type: :system, js: true do
  let(:admin) { create(:user, :admin) }

  before :each do
    sign_in admin
  end

  context 'empty settings panel' do
    it 'loads Buyer turbo frames' do
      visit oroshi_dashboard_buyers_path

      # should be empty #buyers turbo frame and #buyer turbo frame
      expect(find('#buyers')).to be_truthy
      expect(find('#buyer')).to be_truthy
    end
  end

  context 'interaction with settings panel' do
    before :each do
      create_list(:oroshi_buyer, 3)
    end

    it 'loads Buyers and buyer turbo frames' do
      visit oroshi_dashboard_buyers_path

      # find the second link within #buyers a.list-group-item, click the link, check that the organization is displayed
      links = find_all('#buyers a.list-group-item')
      links[1].click
      name = links[1].text.gsub(/\n\d/, '').gsub(/（.*?）/, '').strip
      # text from link[1] should be value of the input #oroshi_buyer_name
      expect(find('#oroshi_buyer_name').value).to eq(name)
    end

    it 'should toggle active and inactive buyers and shipping_methods' do
      visit oroshi_dashboard_buyers_path

      # within find_all('#buyers a.list-group-item') count the links
      buyer_links = find_all('#buyers a.list-group-item').count
      # find #buyer #oroshi_buyer_active and uncheck it
      find("input[name='oroshi_buyer[active]']").uncheck
      # visit the page via dashboard to load controller and check that the number of supplier buyers is less by 1
      visit oroshi_root_path
      # find link within .nav .nav-link with buyers in the href, click it
      expect(page).to have_selector('a[data-reload-target="dashboard_buyers"]', visible: true, wait: 5)
      find('a[data-reload-target="dashboard_buyers"]').click
      expect(find_all('#buyers a.list-group-item').count).to eq(buyer_links - 1)
      # check the #buyers #activeToggle
      find('#buyers #activeToggle').click
      expect(find_all('#buyers a.list-group-item').count).to eq(buyer_links)
    end
  end
end
