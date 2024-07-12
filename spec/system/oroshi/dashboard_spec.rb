require 'rails_helper'

RSpec.describe 'Oroshi Dashboard', type: :system, js: true do
  let(:admin) { create(:user, :admin) }

  before :each do
    sign_in admin
  end

  context 'interaction with empty dashboard' do
    it 'loads empty dashboard' do
      visit oroshi_root_path

      expect(page).to have_content('ホーム')

      # #v-pills-tab .nav-link work Turbo links
      links = find('#dashboard-nav').all('a.nav-link')
      links.each do |link|
        link.click
        # text under card-title is displayed, same as link text, should be visible
        expect(page).to have_css('.card-title', text: link.text, visible: true)
      end
    end

    it 'modal pops' do
      visit oroshi_root_path

      # find the data-turbo-frame="oroshi_modal_content" within #supply_reception_times, click it
      find('#supply_reception_times').find('[data-turbo-frame="oroshi_modal_content"]').click
      # check if the #oroshiModal is visible
      expect(page).to have_css('#oroshiModal', visible: true)
      # close with #oroshiModal .btn-close
      find('#oroshiModal').find('.btn-close').click
    end

    it 'saves company settings' do
      visit oroshi_root_path

      # look for each input within #oroshi_dashboard_company , fill in with dummy data FFaker
      fill_in '_company_settings_name', with: FFaker::Company.name
      fill_in '_company_settings_postal_code', with: FFaker::AddressJA.postal_code
      fill_in '_company_settings_address', with: FFaker::AddressJA.address
      fill_in '_company_settings_phone', with: FFaker::PhoneNumberJA.phone_number
      fill_in '_company_settings_fax', with: FFaker::PhoneNumberJA.phone_number
      fill_in '_company_settings_mail', with: FFaker::Internet.email
      fill_in '_company_settings_web', with: FFaker::Internet.http_url
      fill_in '_company_settings_invoice_number',
              with: "T#{FFaker::Random.rand(1_000_000_000_000..9_999_999_999_999)}"

      # click elswhere to trigger save
      find('#dashboard-nav').all('a.nav-link').last.click
      find('#dashboard-nav').all('a.nav-link').first.click

      # check if the data is saved
      field_ids = %w[ _company_settings_name _company_settings_postal_code _company_settings_address
                      _company_settings_phone _company_settings_fax _company_settings_mail
                      _company_settings_web _company_settings_invoice_number]

      field_ids.each do |id|
        expect(find("##{id}").value).not_to be_empty
      end
    end
  end

  context 'interaction with full dashboard' do
    before do
      create_list(:oroshi_supplier, 5)
      create(:oroshi_supply_date, :with_supplies)
      create_list(:oroshi_order, 5)
    end

    it 'loads full dashboard' do
      visit oroshi_root_path

      expect(page).to have_content('ホーム')

      # Within #oroshi_dashboard_stats each .badge should have a non-zero value
      stats = find('#oroshi_dashboard_stats').all('.badge')
      sleep 0.5
      stats.each do |stat|
        expect(stat.text.to_i).to be > 0
      end

      # #v-pills-tab .nav-link work Turbo links
      links = find('#dashboard-nav').all('a.nav-link')
      links.each do |link|
        link.click
        # text under card-title is displayed, same as link text, should be visible
        expect(page).to have_css('.card-title', text: link.text, visible: true)
      end
    end

    it 'modal form submits and refreshes content for new record' do
      visit oroshi_root_path

      # find the new record modal button within the only model which can be controlled on the home page
      find('#supply_reception_times').find('[data-turbo-frame="oroshi_modal_content"]').click
      # there should be a form now, fill it in
      expect(find('form.new_oroshi_supply_reception_time')).to be_visible
      form = find('form.new_oroshi_supply_reception_time')
      expect(form).to have_selector('input#oroshi_supply_reception_time_time_qualifier')
      form.find('input#oroshi_supply_reception_time_time_qualifier').set('TEST')
      form.find('input#oroshi_supply_reception_time_hour').set('11')
      form.find('select#oroshi_supply_reception_time_supplier_organization_ids').all('option').first.select_option
      # submit form, the target should be refreshed and the modal closed
      refresh_target = find("##{form['data-refresh-target']}")
      form.find('input[type="submit"]').click

      # there should be a #oroshi_supply_reception_time_time_qualifier with text 'TEST' set above
      sleep 0.3 # wait for animation
      expect(refresh_target).to have_selector('input[value="TEST"]')
    end

    it 'activates and deactives list-group-items' do
      visit oroshi_root_path

      # this is a dashboard controller test, should work for any list-group with this action added
      # navigate to second link in #dashboard-nav, which is for '供給組織・生産者'
      find('#dashboard-nav').all('a.nav-link')[1].click
      expect(page).to have_css('h3', text: '供給組織・生産者', visible: true)
      # find the links within '#supplier_organizations .list-group'
      links = find('#supplier_organizations').all('a.list-group-item')
      expect(links.first[:class]).to include('active')
      # click the second link
      links[1].click
      # check if the first link does not have the active class
      expect(links.first[:class]).not_to include('active')
      # wait for a link to have the active class
      expect(find('#supplier_organizations')).to have_css('a.list-group-item.active', count: 1)
      # check if the second link has the active class
      expect(links[1][:class]).to include('active')
    end

    it 'does not show inactive record in list-group, and can be shown by toggle' do
      # create an inactive supplier_organization
      create(:oroshi_supplier_organization, active: false)
      supplier_organization_count = Oroshi::SupplierOrganization.count
      active_supplier_organization_count = Oroshi::SupplierOrganization.active.count
      visit oroshi_root_path

      # this is a dashboard controller test, should work for any list-group with this action added
      # navigate to second link in #dashboard-nav, which is for '供給組織・生産者'
      expect(page).to have_css('#dashboard-nav a.nav-link', wait: 10)
      find('#dashboard-nav').all('a.nav-link')[1].click
      expect(page).to have_css('h3', text: '供給組織・生産者', visible: true)
      # find the links within '#supplier_organizations .list-group'
      links = find('#supplier_organizations').all('a.list-group-item')
      # check if the count of links is the same as the active count
      expect(links.count).to eq(active_supplier_organization_count)
      # click the toggle button
      find('#supplier_organizations').find('#activeToggle').click
      # check if the count of links is the same as the total count
      expect(find('#supplier_organizations').all('a.list-group-item').count).to eq(supplier_organization_count)
    end
  end
end
