require 'rails_helper'

RSpec.describe 'Oroshi Dashboard - Material settings', type: :system, js: true do
  let(:admin) { create(:user, :admin) }

  before :each do
    sign_in admin
  end

  context 'empty settings panel' do
    it 'loads empty Material turbo frames' do
      visit oroshi_dashboard_materials_path

      # within #dashboard_materials there should be three .nav-tabs a.nav-link
      expect(find('#dashboard_materials')).to be_truthy
      expect(find_all('.nav-tabs a.nav-link').count).to eq(3)
      # should be .material-navigation.card with two turbo frames #materials and #material_categories
    end
  end

  context 'during interaction with the panel' do
    before :each do
      create_list(:oroshi_shipping_receptacle, 10)
      create_list(:oroshi_packaging, 10)
      create_list(:oroshi_material_category, 5)
      create_list(:oroshi_material, 20)
    end

    it 'loads proper turbo frames for each section' do
      visit oroshi_dashboard_materials_path

      expect(page).to have_css('#dashboard_materials', text: '製造材料', visible: true, wait: 5)
      # find tabs links within .nav-tabs (should be only one since not loading from dashboard)
      links = find('.nav-tabs').all('a.nav-link')
      # visit each link and confirm turbo frame loads
      links.each do |link|
        link.click
        expect(page).to have_css('h6', text: link.text, visible: true, wait: 5)
      end
      links.first.click

      # first link should load #shipping_receptacles and #shipping_receptacle turbo frames within .material-navigation
      expect(page).to have_css('#shipping_receptacles', visible: true, wait: 5)
      expect(find('#shipping_receptacle')).to be_truthy

      # second link should load #packagings and #packaging turbo frames within .material-navigation
      links[1].click
      expect(page).to have_css('#packagings', visible: true, wait: 5)
      expect(find('#packagings')).to be_truthy

      # third link should load #material_categories and #material_category
      # and #material turbo frames within .material-navigation
      links[2].click
      expect(page).to have_css('#material_categories', visible: true, wait: 5)
      expect(find('#oroshi_material_category_materials')).to be_truthy
      expect(find('#material')).to be_truthy
      expect(find('#material_category')).to be_truthy
    end
  end
end
