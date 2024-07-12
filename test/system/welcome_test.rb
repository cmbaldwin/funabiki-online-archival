require "application_system_test_case"
require 'sidekiq/testing'
Sidekiq::Testing.inline!

class WelcomeTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
    @office = users(:office)
    @unapproved = users(:unapproved)

    @admin.confirm
    @office.confirm

    sign_in @admin
  end

  test 'visiting the index' do
    # Index only test
    assert_nothing_raised do
      visit root_path
      sleep 1
      # Wait for the page to load, sometimes Rakuten takes awhile, so use that as a proxy
      find('#rakuten_partial')
      # Refresh Rakuten
      find('#rakuten_partial [data-tippy-content="データ更新"]').click
      # Toggle oysis receipt image
      find('#reciept_options_oysis').click
      # Generate a Receipt
      find('#receipt_form .btn').click
      # Regenerate Expiration cards link
      find('#regen_expiration_cards').click
      # Should be three messages, should be 3 elements in #messages-container
      assert page.has_css?('#messages-container .message', count: 3, wait: 15)
      assert_equal 3, all('#messages-container .message').count
      # Can delete a message, race conditions here
      all('#messages-container .message a[data-turbo-method="delete"]').first.click
      assert page.has_css?('#messages-container .message', count: 2, wait: 15)
      assert_equal 2, all('#messages-container .message').count
      assert_equal 2, Message.count
      # Rakuten Shinki window
      shinki_modal_btn = find('[data-bs-target="#rakuten_shinki_modal"]')
      if shinki_modal_btn.visible?
        shinki_modal_btn.click # Open the modal
        sleep 3 # Wait for the modal to open
        find("#rakuten_shinki_modal .btn-close").click # Close the modal
        sleep 3 # Wait for the modal to close
      end
      # Rakuten Data Loaded?
      first_message = all('#messages-container .message').first
      first_message.click
      # Assert Message Tippy
      tippy_box = find('.tippy-box')
      assert tippy_box.visible?
    end
  end

  test 'move to each subpage from index' do
    assert_nothing_raised do
      visit root_path
      # Wait for the page to load
      nav_links = all('.nav-link').map { |link| link[:href] }
      nav_links.each do |link|
        visit link
      end
      dropdowns = all('.dropdown')
      dropdown_urls = []
      dropdowns.each do |dropdown|
        within(dropdown) do
          find('.dropdown-toggle').click
          assert find('.dropdown-menu').visible?
          items = all('.dropdown-item')
          items.each do |item|
            dropdown_urls << item[:href]
          end
        end
      end
      dropdown_urls.each do |url|
        next if url == "https://noshi.onrender.com/"

        visit url
      end
      visit edit_user_registration_path
      find('#sign_out').click
    end
  end

  test 'receipt generation' do
    assert_nothing_raised do
      visit root_path
      sleep 2
      # Wait for the page to load, sometimes Rakuten takes awhile, so use that as a proxy
      find('#receipt_form')
      # Toggle oysis receipt image
      receipt_logo = find('#receipt_partial .receipt_img:not(.d-none)')
      receipt_text = find('#receipt_partial .receipt_text:not(.d-none)')
      find('#receipt_form #reciept_options_oysis').click
      # Generate a Receipt
      find('#receipt_form .btn').click
      sleep 1
      # Should be a message now
      assert_equal 1, all('#messages-container .message').count
    end
  end
end
