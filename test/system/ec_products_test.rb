require "application_system_test_case"

class EcProductsTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
    @office = users(:office)
    @unapproved = users(:unapproved)

    @admin.confirm
    @office.confirm

    sign_in @office
  end

  test 'visiting the index and clicking each tab turbo loads content and displays in the respective tab' do
    assert_nothing_raised do
      visit ec_products_path
      within find('#app') do
        tabs = all('[data-controller="online-shops--settings"] .nav-item')
        tabs.each do |tab|
          # find button child of tab li
          btn = tab.find('button')
          target = btn['data-target']
          btn.click
          sleep 1
          # assert #target is visible and does not container a spinner
          assert_selector "##{target}", visible: true
          assert_no_selector "#{target} .spinner-border"
        end
      end
    end
  end

  test 'can save a new product and edit it' do
    visit ec_products_path
    new_product_form = find('#new_ec_product')
    within new_product_form do
      fill_in 'ec_product[name]', with: 'New Product'
      select '500g', from: 'ec_product[ec_product_type_id]'
      fill_in 'ec_product[cross_reference_ids]', with: '10000018'
      fill_in 'ec_product[quantity]', with: '100'
      fill_in 'ec_product[memo_name]', with: '100'
      fill_in 'ec_product[extra_shipping_cost]', with: '100'
      select '冷蔵', from: 'ec_product[frozen_item]'
      find('[type="submit"]').native.send_keys(:return)
    end
    sleep 0.5
    new_product = EcProduct.last
    # should be turbo-frame with id #ec_product_#{new_product.id}
    new_product_frame = find("#ec_product_#{new_product.id}")
    assert new_product_frame.visible?
    within new_product_frame do
      name_input = find('#ec_product_name')
      assert name_input.value == 'New Product'
      # edit the product
      name_input = find('#ec_product_name')
      name_input.click
      name_input.fill_in(with: 'New Product Edited')
      name_input.native.send_keys(:return)
    end
  end

  test 'can save a new product type and edit it' do
    visit ec_products_path
    find('#types-tab').click
    new_product_type_form = find('#new_ec_product_type')
    within new_product_type_form do
      fill_in 'ec_product_type[name]', with: 'New Product Type'
      fill_in 'ec_product_type[counter]', with: 'p'
      find('[type="submit"]').native.send_keys(:return)
    end
    sleep 0.5
    new_product_type = EcProductType.last
    # should be turbo-frame with id #ec_product_type_#{new_product_type.id}
    new_product_type_frame = find("#ec_product_type_#{new_product_type.id}")
    assert new_product_type_frame.visible?
    within new_product_type_frame do
      name_input = find('#ec_product_type_name')
      assert name_input.value == 'New Product Type'
      # edit the product
      name_input = find('#ec_product_type_name')
      name_input.click
      name_input.fill_in(with: 'New Product Type Edited')
      name_input.native.send_keys(:return)
    end
  end

  test 'can edit rakuten automation settings tab settings' do
    visit ec_products_path
    find('#rakuten-automation-settings-tab').click
    within find('#rakuten_processing_settings') do
      # 選択したオプションのテキスト変換
      find('.card-header', text: '選択したオプションのテキスト変換')
      conversion_input_rows = all('.input-group .input-group')
      conversion_input_rows_length = conversion_input_rows.length
      inputs = conversion_input_rows.last.all('input')
      inputs.first.fill_in(with: 'Testacular')
      find('[type="submit"]').click
      sleep 0.5
      assert all('.input-group.mb-3').length == conversion_input_rows_length + 1
      # Change cutoff time to 5 on rakuten_processing_settings[ship_today_cutoff_hour]
      find('[name="rakuten_processing_settings[ship_today_cutoff_hour]"]').fill_in(with: '5')
      # Turn off automation
      select 'OFF', from: 'rakuten_processing_settings[automation_on]'
      # Rakuten processing control settings
      find('[name="rakuten_processing_settings[ship_wait_products]"]').fill_in(with: '1234567890')
      find('[name="rakuten_processing_settings[ship_skip_products]"]').fill_in(with: '1234567890')
      find('[type="submit"]').click
      sleep 0.5
      assert find('[name="rakuten_processing_settings[ship_today_cutoff_hour]"]').value == '5'
      assert find('[name="rakuten_processing_settings[automation_on]"]').value == 'false'
      assert find('[name="rakuten_processing_settings[ship_wait_products]"]').value == '1234567890'
      assert find('[name="rakuten_processing_settings[ship_skip_products]"]').value == '1234567890'
    end
  end
end
