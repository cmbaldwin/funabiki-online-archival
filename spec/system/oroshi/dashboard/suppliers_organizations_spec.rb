require 'rails_helper'

RSpec.describe 'Oroshi Dashboard - Suppliers organizations settings', type: :system, js: true do
  let(:admin) { create(:user, :admin) }
  let(:supplier_organizations) { create_list(:oroshi_supplier_organization, 3, :with_suppliers) }

  before :each do
    sign_in admin
  end

  context 'empty settings panel' do
    it 'loads empty Supply Type and Supply Type Variation turbo frames' do
      visit oroshi_dashboard_suppliers_organizations_path

      # should be #supplier_organizations turbo frame and #supplier_organizations_supplier_settings turbo frame
      expect(page).to have_selector('#supplier_organizations', visible: true, wait: 5)
      expect(page).to have_selector('#supplier_organizations_supplier_settings', visible: true, wait: 5)
    end
  end

  context 'during interaction with the panel' do
    before :each do
      supplier_organizations # create supplier organizations
    end

    it 'load organization and suppliers in turbo_frames' do
      visit oroshi_dashboard_suppliers_organizations_path

      # ensure turbo frames are loaded
      expect(find('#supplier_organization .frame.collapse.show')).to be_truthy
      # find the second link within #supplier_organizations a.list-group-item, click the link, check that the organization is displayed
      links = find_all('#supplier_organizations a.list-group-item')
      links[1].click
      entity_name = links[1].text.gsub(/\n\d/, '').strip
      # text from link[1] should be value of the input #oroshi_supplier_organization_entity_name
      expect(find('#oroshi_supplier_organization_entity_name').value).to eq(entity_name)
      # within #suppliers frame there should be a list of suppliers with .list-group-item
      # equal to the number of suppliers in the organization with the just found entity_name
      supplier_organization = Oroshi::SupplierOrganization.find_by(entity_name: entity_name)
      expect(find_all('#suppliers .list-group-item').count).to eq(supplier_organization.suppliers.count)
    end

    it 'should expand and collapse cards within subframe' do
      visit oroshi_root_path
      # find a with data-reload-target="dashboard_suppliers" and click it
      expect(page).to have_selector('a[data-reload-target="dashboard_suppliers"]', visible: true, wait: 5)
      find('a[data-reload-target="dashboard_suppliers"]').click
      # #supplier_organization .frame.collapse.show should exist
      expect(find('#supplier_organization .frame.collapse.show')).to be_truthy
      # click the collapse button within #suppliers as .collapse-toggle
      find('#suppliers .collapse-toggle').click
      # #supplier_organization .frame.collapse shouldn't be visible
      expect(page).not_to have_selector('#supplier_organization .frame.collapse', visible: false, wait: 5)
    end

    it 'should toggle active and inactive organizations and suppliers' do
      visit oroshi_dashboard_suppliers_organizations_path

      # within find_all('#supplier_organizations a.list-group-item') count the links
      supplier_organization_links = find_all('#supplier_organizations a.list-group-item').count
      # find #supplier_organization #oroshi_supplier_organization_active and uncheck it
      find('#oroshi_supplier_organization_active').uncheck
      # visit the page via dashboard to load controller and check that the number of supplier organizations is less by 1
      visit oroshi_root_path
      # find link within .nav .nav-link with suppliers_organizations in the href, click it
      expect(page).to have_selector('a[data-reload-target="dashboard_suppliers"]', visible: true, wait: 5)
      find('a[data-reload-target="dashboard_suppliers"]').click
      expect(find_all('#supplier_organizations a.list-group-item').count).to eq(supplier_organization_links - 1)
      # check the #supplier_organizations #activeToggle
      find('#supplier_organizations #activeToggle').click
      expect(page).to have_selector('#supplier_organizations a.list-group-item',
                                    count: supplier_organization_links, wait: 5)
    end

    it 'should toggle default address within organizations addresses' do
      visit oroshi_dashboard_suppliers_organizations_path

      # find all data-oroshi--addresses-target="defaultToggle" within #supplier_organization
      # find the one that isn't checked and check it
      default_toggles = find_all('#supplier_organization [data-oroshi--addresses-target="defaultToggle"]')
      unchecked_default_toggle = default_toggles.find { |toggle| !toggle.checked? }
      checked_default_toggle = default_toggles.find { |toggle| toggle.checked? }
      unchecked_default_toggle.click
      # confirm that the other defaultToggle is unchecked
      expect(checked_default_toggle.checked?).to be_falsey
    end

    it 'should add and remove supplier representatives' do
      visit oroshi_dashboard_suppliers_organizations_path

      # withing #suppliers find the first turbo_frame, and with that find #representatives
      supplier_frames = all('#suppliers turbo-frame')
      supplier_frame = supplier_frames.first
      representatives = supplier_frame.find('#representatives')
      number_of_reps = representatives.all('.representative').count
      # click the .add-representative button
      supplier_frame.find('.add-representative').click
      # check that the number of representatives is increased by 1
      expect(representatives.all('.representative').count).to eq(number_of_reps + 1)
      # click the .remove-representative button
      supplier_frame.find('.remove-representative').click
      # check that the number of representatives is decreased by 1
      expect(representatives.all('.representative').count).to eq(number_of_reps)
    end
  end
end
