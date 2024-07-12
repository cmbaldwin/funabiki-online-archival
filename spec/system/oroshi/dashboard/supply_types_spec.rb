require 'rails_helper'

RSpec.describe 'Oroshi Dashboard - Supply type settings', type: :system, js: true do
  let(:admin) { create(:user, :admin) }

  before :each do
    sign_in admin
  end

  context 'empty settings panel' do
    it 'loads empty Supply Type and Supply Type Variation turbo frames' do
      visit oroshi_dashboard_supply_types_path

      # should be #supply_types turbo frame and #supply_types_supplier_settings turbo frame
      expect(find('#supply_types')).to be_truthy
      expect(find('#supply_type_settings')).to be_truthy
    end
  end

  context 'during interaction with the panel' do
    before :each do
      create_list(:oroshi_supply_type, 3)
      create_list(:oroshi_supply_type_variation, 10)
    end

    it 'load supply_type and supply_type_variations in turbo_frames' do
      visit oroshi_dashboard_supply_types_path
      expect(page).to have_selector('#supply_types', visible: true, wait: 5)
      # find the second link within #supply_types a.list-group-item, click the link,
      # check that the supply_type is displayed
      expect(page).to have_selector('#supply_types a.list-group-item', visible: true, wait: 5)
      links = find_all('#supply_types a.list-group-item')
      links[1].click
      name = links[1].text.gsub(/\n\d/, '').gsub(/（.*?）/, '').strip
      # text from link[1] should be value of the input #oroshi_supply_type_name
      expect(find('#oroshi_supply_type_name').value).to eq(name)
      # within #supply_type_variations frame there should be a list of supply_type_variations with .list-group-item
      # equal to the number of supply_type_variations in the supply_type with the just found name
      supply_type = Oroshi::SupplyType.find_by(name: name)
      expect(find_all('#supply_type_variations .list-group-item').count).to eq(supply_type.supply_type_variations.count)
    end

    it 'should expand and collapse cards within subframe' do
      visit oroshi_root_path
      # find a with data-reload-target="dashboard_supply_types" and click it
      expect(page).to have_selector('a[data-reload-target="dashboard_supply_types"]', visible: true, wait: 5)
      find('a[data-reload-target="dashboard_supply_types"]').click
      # #supply_type .frame.collapse.show should exist
      expect(find('#supply_type .frame.collapse.show')).to be_truthy
      # click the collapse button within #supply_type_variations as .collapse-toggle
      find('#supply_type_variations .collapse-toggle').click
      # #supply_type .frame.collapse shouldn't be visible
      expect(page).not_to have_selector('#supply_type .frame.collapse', visible: false, wait: 5)
    end

    it 'should toggle active and inactive supply_types and supply_type_variations' do
      visit oroshi_dashboard_supply_types_path

      # within find_all('#supply_types a.list-group-item') count the links
      supply_type_links = find_all('#supply_types a.list-group-item').count
      # find #supply_type #oroshi_supply_type_active and uncheck it
      find('#oroshi_supply_type_active').uncheck
      # visit the page via dashboard to load controller and check that the number of supplier supply_types is less by 1
      visit oroshi_root_path
      # find link within .nav .nav-link with supply_types in the href, click it
      expect(page).to have_selector('a[data-reload-target="dashboard_supply_types"]', visible: true, wait: 5)
      find('a[data-reload-target="dashboard_supply_types"]').click
      expect(find_all('#supply_types a.list-group-item').count).to eq(supply_type_links - 1)
      # check the #supply_types #activeToggle
      find('#supply_types #activeToggle').click
      expect(find_all('#supply_types a.list-group-item').count).to eq(supply_type_links)
    end
  end
end
