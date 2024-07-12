require 'rails_helper'

RSpec.describe 'Oroshi Dashboard - Product settings', type: :system, js: true do
  let(:admin) { create(:user, :admin) }

  before :each do
    sign_in admin
  end

  context 'empty settings panel' do
    it 'loads empty Supply Type and Supply Type Variation turbo frames' do
      visit oroshi_dashboard_products_path

      # should be #supplier_organizations turbo frame and #supplier_organizations_supplier_settings turbo frame
      expect(find('#products')).to be_truthy
      expect(find('#product_settings')).to be_truthy
    end
  end

  context 'interaction with settings panel' do
    before :each do
      create_list(:oroshi_product, 3, :with_materials, :with_product_variations)
    end

    it 'loads Product and Product Variation turbo frames' do
      visit oroshi_dashboard_products_path

      # find the second link within #products a.list-group-item, click the link, check that the organization is displayed
      links = find_all('#products a.list-group-item')
      links[1].click
      name = links[1].text.gsub(/\n\d/, '').gsub(/（.*?）/, '').strip
      # text from link[1] should be value of the input #oroshi_product_name
      expect(find('#oroshi_product_name').value).to eq(name)
      # within #product_variations frame there should be a list of product_variations with .list-group-item
      # equal to the number of product_variations in the organization with the just found name
      product = Oroshi::Product.find_by(name: name)
      expect(find_all('#product_variations .list-group-item').count).to eq(product.product_variations.count)
    end

    it 'should expand and collapse cards within subframe' do
      visit oroshi_root_path
      # find a with data-reload-target="dashboard_products" and click it
      expect(page).to have_selector('a[data-reload-target="dashboard_products"]', visible: true, wait: 5)
      find('a[data-reload-target="dashboard_products"]').click
      # #product .frame.collapse.show should exist
      expect(page).to have_selector('#product .frame.collapse.show', visible: true, wait: 5)
      # click the collapse button within #product_variations as .collapse-toggle
      find('#product_variations .collapse-toggle').click
      # #product .frame.collapse shouldn't be visible
      expect(page).not_to have_selector('#product .frame.collapse', visible: false, wait: 5)
    end

    it 'should toggle active and inactive products and product_variations' do
      visit oroshi_dashboard_products_path

      # within find_all('#products a.list-group-item') count the links
      product_links = find_all('#products a.list-group-item').count
      # find #product #oroshi_product_active and uncheck it
      find('#oroshi_product_active').uncheck
      # visit the page via dashboard to load controller and check that the number of supplier products is less by 1
      visit oroshi_root_path
      # find link within .nav .nav-link with products in the href, click it
      expect(page).to have_selector('a[data-reload-target="dashboard_products"]', visible: true, wait: 5)
      find('a[data-reload-target="dashboard_products"]').click
      expect(find_all('#products a.list-group-item').count).to eq(product_links - 1)
      # check the #products #activeToggle
      find('#products #activeToggle').click
      expect(find_all('#products a.list-group-item').count).to eq(product_links)
    end

    it 'should show product variation, shipping receptacle, packging and material images' do
      visit oroshi_root_path
      # find a with data-reload-target="dashboard_products" and click it
      expect(page).to have_selector('a[data-reload-target="dashboard_products"]', visible: true, wait: 5)
      find('a[data-reload-target="dashboard_products"]').click
      # confirm all the turbo frames have loaded
      expect(page).to have_selector('#products', visible: true, wait: 5)
      expect(page).to have_selector('#material_images', visible: true, wait: 5)
      expect(page).to have_selector('#product_variations', visible: true, wait: 5)
      expect(page).to have_selector('#packaging_images', visible: true, wait: 5)
      expect(page).to have_selector('#product_variations', visible: true, wait: 5)
      expect(page).to have_selector('#product_variations turbo-frame.list-group-item', visible: true, wait: 5)
      expect(page).to have_selector('#shipping_receptacle_image', visible: true, wait: 5)
      # find the number of material images within #product
      material_images = find_all('#product #material_images img').count
      # within product click an unchecked input[data-target="material_images"] and check it
      all('#product input[data-target="material_images"]:not(:checked)').first.click
      # the wait for materials to reload, and expect that inside #material_images there should be one more image
      expect(page).to have_selector('#material_images img', visible: true, wait: 5)
      expect(find_all('#product #material_images img').count).to eq(material_images + 1)
      # get the idea for the first #product_variations turbo-frame.list-group-item
      first_product_variation = all('#product_variations turbo-frame.list-group-item').first['id']
      # within first_product_variation find packaging_images img count
      packaging_images = find_all("##{first_product_variation} #packaging_images img").count
      # within first_product_variation click an unchecked input[data-target="packaging_images"] and check it
      all("##{first_product_variation} input[data-target='packaging_images']:not(:checked)").first.click
      # wait for packaging_images to reload, and expect that inside #packaging_images there should be one more image
      # and that the count of images should be packaging_images + 1
      expect(page).to have_selector("##{first_product_variation} #packaging_images img", visible: true, wait: 5)
      expect(find_all("##{first_product_variation} #packaging_images img").count).to eq(packaging_images + 1)
    end
  end
end
