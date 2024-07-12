require 'rails_helper'

RSpec.describe 'Oroshi Dashboard - Shipping settings', type: :system, js: true do
  let(:admin) { create(:user, :admin) }

  before :each do
    sign_in admin
  end

  context 'empty settings panel' do
    it 'loads empty Supply Type and Supply Type Variation turbo frames' do
      visit oroshi_dashboard_shipping_path

      # should be #supplier_organizations turbo frame and #supplier_organizations_supplier_settings turbo frame
      expect(find('#shipping_organizations')).to be_truthy
      expect(find('#shipping_organizations_shipping_settings')).to be_truthy
    end
  end

  context 'interaction with settings panel' do
    before :each do
      create_list(:oroshi_shipping_organization, 3)
      create_list(:oroshi_shipping_method, 10)
    end

    it 'loads Shipping Organization and Shipping Method turbo frames' do
      visit oroshi_dashboard_shipping_path

      # find the second link within #shipping_organizations a.list-group-item, click the link, check that the organization is displayed
      links = find_all('#shipping_organizations a.list-group-item')
      links[1].click
      name = links[1].text.gsub(/\n\d/, '').gsub(/（.*?）/, '').strip
      # text from link[1] should be value of the input #oroshi_shipping_organization_name
      expect(find('#oroshi_shipping_organization_name').value).to eq(name)
      # within #shipping_methods frame there should be a list of shipping_methods with .list-group-item
      # equal to the number of shipping_methods in the organization with the just found name
      shipping_organization = Oroshi::ShippingOrganization.find_by(name: name)
      expect(find_all('#shipping_methods .list-group-item').count).to eq(shipping_organization.shipping_methods.count)
    end

    it 'should expand and collapse cards within subframe' do
      visit oroshi_root_path
      # find a with data-reload-target="dashboard_shipping" and click it
      expect(page).to have_selector('a[data-reload-target="dashboard_shipping"]', visible: true, wait: 5)
      find('a[data-reload-target="dashboard_shipping"]').click
      # #shipping_organization .frame.collapse.show should exist
      expect(find('#shipping_organization .frame.collapse.show')).to be_truthy
      # click the collapse button within #shipping_methods as .collapse-toggle
      find('#shipping_methods .collapse-toggle').click
      # #shipping_organization .frame.collapse shouldn't be visible
      expect(page).not_to have_selector('#shipping_organization .frame.collapse', visible: false, wait: 5)
    end

    it 'should toggle active and inactive shipping_organizations and shipping_methods' do
      visit oroshi_dashboard_shipping_path

      # within find_all('#shipping_organizations a.list-group-item') count the links
      shipping_organization_links = find_all('#shipping_organizations a.list-group-item').count
      # find #shipping_organization #oroshi_shipping_organization_active and uncheck it
      find('#oroshi_shipping_organization_active').uncheck
      # visit the page via dashboard to load controller and check that the number of supplier shipping_organizations is less by 1
      visit oroshi_root_path
      # find link within .nav .nav-link with shipping_organizations in the href, click it
      expect(page).to have_selector('a[data-reload-target="dashboard_shipping"]', visible: true, wait: 5)
      find('a[data-reload-target="dashboard_shipping"]').click
      expect(find_all('#shipping_organizations a.list-group-item').count).to eq(shipping_organization_links - 1)
      # check the #shipping_organizations #activeToggle
      find('#shipping_organizations #activeToggle').click
      expect(find_all('#shipping_organizations a.list-group-item').count).to eq(shipping_organization_links)
    end
  end
end
