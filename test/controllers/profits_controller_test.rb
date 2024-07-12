require 'test_helper'

class ProfitsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @office = users(:office)
    @unapproved = users(:unapproved)

    @admin.confirm
    @office.confirm

    sign_in @admin

    @profit = profits(:one)
  end

  def market(id = :tokyo)
    markets(id)
  end

  def figures(this_market = market, order_count = 1, unit_price = 0)
    this_market.products.each_with_object({}) do |o, h|
      h[o.type.to_i] ||= {}
      h[o.type.to_i][o.id] ||= {}
      h[o.type.to_i][o.id][this_market.id] ||= { order_count:, unit_price:, combined: 0,
                                                 extra_cost: 0 }
    end
  end

  def params(figs = figures)
    {
      profit: {
        id: @profit.id,
        figures: figs
      }
    }
  end

  def autosave(new_figures)
    patch autosave_path(@profit.id),
          params: new_figures,
          headers: {
            'X-CSRF-Token' => session[:_csrf_token]
          }
  end

  test 'should redirect unless admin' do
    sign_out :user
    sign_in @office

    get profits_url
    assert_redirected_to root_url
  end

  test 'should load index' do
    get profits_url
    assert_response :success
  end

  test 'should load volumes' do
    get fetch_volumes_path(@profit.id), xhr: true
    assert_response :success
  end

  test 'should load edit' do
    @profit.setup
    @profit.save

    get edit_profit_path(@profit)
    assert_response :success
  end

  test 'should autosave profit' do
    assert_nothing_raised do
      get profits_url # Load index set controller
      # Initial autosave
      autosave(params)
      assert_response :success
      # Reload association to fetch updated data and assert updates.
      @profit.reload
      # Intitially empty, params should equal the figures as is
      assert_equal figures, @profit.figures

      # Test updating params
      yoshi_mura = market(:yoshi_mura)
      new_figures = figures(yoshi_mura, 2, 123)
      autosave(params(new_figures))
      assert_response :success
      # Reload association to fetch updated data and assert updates.
      @profit.reload
      # Note, numerical values are floating points
      # Do not need to be set for this estimated assertion
      estimated_new_figures = figures.deep_merge(new_figures)
      # Assert addition of new values into the figures hash
      assert_equal estimated_new_figures, @profit.figures

      # Test removing entries
      new_figures = figures(yoshi_mura, 0, 0)
      autosave(params(new_figures))
      assert_response :success
      # Reload association to fetch updated data and assert updates.
      @profit.reload
      # Assert the value has been removed from the figures hash
      test_product = yoshi_mura.products.first
      assert_nil @profit.figures.dig(test_product.type.to_i, test_product.id, yoshi_mura.id)
    end
  end

  test 'should update profit' do
    assert_nothing_raised do
      get profits_url # Load index set controller
      # Initial autosave
      autosave(params)
      assert_response :success
      # Reload association to fetch updated data and assert updates.
      @profit.reload
      patch(profit_path(@profit), params:, headers: { 'X-CSRF-Token' => session[:_csrf_token] })

      assert_redirected_to profit_path(@profit)
      @profit.reload
      assert_not_empty @profit.subtotals
      assert_not_empty @profit.totals
      assert_not_empty @profit.volumes
    end
  end

  test 'should save and load new empty profit' do
    get new_by_date_path(sales_date: Time.zone.today.strftime('%Y年%m月%d日'))

    assert_response :redirect
    assert_not_nil assigns(:profit)
    profit = assigns(:profit)

    get profits_path
    assert_response :success

    get fetch_volumes_path(profit.id), xhr: true
    assert_response :success

    get profit_path(profit.id)
    assert_response :success
  end

  test 'should load calendar json' do
    get '/profits.json'
    assert_response :success
  end
end
