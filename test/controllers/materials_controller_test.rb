require 'test_helper'

class MaterialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @office = users(:office)
    @unapproved = users(:unapproved)

    @admin.confirm
    @office.confirm

    sign_in @admin

    @tape = materials(:tape)
  end

  test 'should load index' do
    get materials_url
    assert_response :success
  end

end
