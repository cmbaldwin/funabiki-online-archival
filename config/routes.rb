require 'sidekiq/web'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  # SIDEKIQ
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  # WELCOME/INDEX
  root 'welcome#index'

  # OROSHI
  namespace :oroshi do
    root to: 'dashboard#index'

    namespace :dashboard do
      %w[home suppliers_organizations supply_types
         shipping buyers materials products stats company].each do |tab|
        get tab
      end
      get 'subregions'
      post 'company_settings'
    end

    resources :supply_reception_times, except: %i[destroy show]

    resources :supplier_organizations, except: %i[show destroy] do
      get 'load', on: :collection
      get 'load', on: :member
      resources :suppliers, only: %i[new index]
    end

    resources :suppliers, except: %i[destroy show]

    resources :supply_types, except: %i[destroy show] do
      get 'load', on: :collection
      get 'load', on: :member
      resources :supply_type_variations, only: %i[new index]
    end

    resources :supply_type_variations, except: %i[destroy show]

    resources :supply_dates, param: :date, except: :destroy do
      post 'entry/:supplier_organization_id/:supply_reception_time_id',
           on: :member, to: 'supply_dates#entry', as: :entry
      get 'checklist/:subregion_ids/:supply_reception_time_ids',
          on: :member, to: 'supply_dates#checklist', as: :checklist
      get 'supply_invoice_actions', on: :collection
      get 'supply_price_actions', on: :collection
      post 'set_supply_prices', on: :collection
    end

    resources :supplies, only: %i[index show update] # new and create are handled by supply_dates
    get 'supplies/entry', to: 'supplies#new', as: :supply_entry

    get 'invoices/preview', as: :invoice_preview, to: 'invoices#preview'
    resources :invoices do
      get :send_mail_now, on: :member
      get :mail_notification_preview, on: :member
    end

    resources :shipping_organizations, except: :destroy do
      get 'load', on: :collection
      get 'load', on: :member
      resources :shipping_methods, only: %i[new index]
    end

    resources :shipping_methods, except: %i[destroy show]

    resources :buyers, except: %i[destroy show] do
      get 'orders/:date', on: :member, to: 'buyers#bundlable_orders', as: :bundlable_orders
    end

    resources :shipping_receptacles, except: %i[destroy show] do
      get 'image', on: :member
      get 'estimate_per_box_quantity/:product_variation_id',
          to: 'shipping_receptacles#estimate_per_box_quantity',
          on: :member
    end

    resources :packagings, except: %i[destroy show] do
      get 'image', on: :member
      get 'images', on: :collection
    end

    resources :material_categories, except: %i[destroy show] do
      resources :materials, only: %i[index]
    end

    resources :materials, except: %i[index destroy show] do
      get 'image', on: :member
      get 'images', on: :collection
    end

    resources :products, except: %i[destroy show] do
      get 'load', on: :collection
      get 'load', on: :member
      resources :product_variations, only: %i[new index]
      get 'material_cost/:shipping_receptacle_id/:item_quantity/:receptacle_quantity/:freight_quantity',
          on: :member,
          to: 'products#material_cost'
      patch 'update_positions', on: :collection
    end

    resources :product_variations, except: %i[destroy show] do
      get 'load', on: :collection
      get 'load', on: :member
      get 'image', on: :member
      get 'cost', on: :member
    end

    resources :production_zones, except: %i[destroy show]

    get 'orders/calendar', to: 'orders#calendar', as: :orders_calendar
    get 'orders/calendar/orders', to: 'orders#calendar_orders', as: :calendar_orders
    get 'orders(/:date)', to: 'orders#index', as: :orders
    get 'orders(/:date)/new', to: 'orders#new', as: :new_order
    post 'orders/from_template/:template_id', to: 'orders#new_order_from_template', as: :new_order_from_template
    delete 'orders/templates/:template_id', to: 'orders#destroy_template', as: :delete_template
    patch 'orders/:id/quantity_update', to: 'orders#quantity_update', as: :quantity_update_order
    patch 'orders/:id/price_update', to: 'orders#price_update', as: :price_update_order

    scope 'orders/:date', as: :orders do
      %w[orders templates production shipping sales revenue].each do |route|
        get "/#{route}", to: "orders##{route}", as: route.to_sym
      end
      get '/buyer_sales/:buyer_id', to: 'orders#buyer_sales', as: :buyer_sales
      get '/supply_volumes', to: 'orders#supply_volumes', as: :order_supply_volumes
      get '/product_inventories', to: 'orders#product_inventories', as: :order_product_inventories
      get '/production_view/:production_view', to: 'orders#production_view', as: :order_production_view
    end

    resources :orders, except: %i[index new show] do
      get 'show', to: 'orders#show', as: :show
    end

    resources :product_inventories, except: %i[destroy] do
      resources :production_requests, only: %i[index]
    end

    resources :production_requests, except: %i[index] do
      get 'convert/:date(/:product_id)', on: :collection, to: 'production_requests#convert', as: :convert
    end
  end

  # ASYNC AND JS
  get '/load_rakuten_orders/:date' => 'welcome#load_rakuten_orders', as: 'load_rakuten_orders'
  get '/load_funabiki_order/:date' => 'welcome#load_funabiki_orders', as: 'load_funabiki_orders'
  get '/load_yahoo_orders/:date' => 'welcome#load_yahoo_orders', as: 'load_yahoo_orders'
  get '/load_infomart_orders/:date' => 'welcome#load_infomart_orders', as: 'load_infomart_orders'
  get '/reciept/', as: 'reciept', to: 'welcome#reciept'
  get '/insert_receipt_data' => 'welcome#insert_receipt_data', as: 'insert_receipt_data'

  # WELCOME WIDGETS
  get :daily_expiration_cards, controller: :welcome
  get :rakuten_orders_fp, controller: :welcome
  get :receipt_partial, controller: :welcome
  get :front_infomart_orders, controller: :welcome
  get :infomart_shinki_modal, controller: :welcome
  get :funabiki_orders_partial, controller: :welcome
  get :funabiki_orders_modal, controller: :welcome
  get :yahoo_orders_partial, controller: :welcome
  get :new_yahoo_orders_modal, controller: :welcome
  get :rakuten_shinki_modal, controller: :welcome
  get :charts_partial, controller: :welcome
  get :printables, controller: :welcome

  # FORCAST
  get 'forcasts(/:date)' => 'forcasts#index', as: 'forcasts'
  get 'fetch_week_forcast/:date' => 'forcasts#fetch_week_forcast', as: 'fetch_week_forcast'
  get :week_forcast, controller: :forcasts
  get 'fetch_forcast_calendar_counts(/:date)', as: :fetch_forcast_calendar_counts,
                                               to: 'forcasts#fetch_forcast_calendar_counts', defaults: { format: 'js' }
  get 'fetch_forcast_calendar_forcasts(/:date)', as: :fetch_cforcast_alendar_forcasts,
                                                 to: 'forcasts#fetch_forcast_calendar_forcasts', defaults: { format: 'js' }
  get 'forcast_calendar_event_tippy/:date', as: :forcast_calendar_event_tippy,
                                            to: 'forcasts#forcast_calendar_event_tippy'
  get 'count_calendar_event_tippy/:date', as: :count_calendar_event_tippy, to: 'forcasts#count_calendar_event_tippy'

  # ANALYSIS
  get 'analysis' => 'analysis#index', as: 'analysis'
  get '/fetch_analysis' => 'analysis#fetch_analysis', as: 'fetch_analysis'
  get :total_profit_estimate_analysis_chart_partial, controller: :analysis
  get :market_profit_analysis_chart_partial, controller: :analysis
  get :oyster_sales_kilo_price_analysis_chart_partial, controller: :analysis
  get :oyster_market_kilo_price_analysis_chart_partial, controller: :analysis
  get :oyster_volume_analysis_chart_partial, controller: :analysis
  get :online_shop_order_count_chart_partial, controller: :analysis
  get :online_shop_order_sales_chart_partial, controller: :analysis
  get :furusato_order_count_chart_partial, controller: :analysis

  # ANALYSIS CHARTS
  get '/fetch_chart/:chart_params' => 'analysis#fetch_chart', as: 'fetch_chart'
  get '/market_profit_analysis_chart' => 'analysis#market_profit_analysis_chart', as: 'market_profit_analysis_chart'
  get '/total_profit_estimate_analysis_chart' => 'analysis#total_profit_estimate_analysis_chart',
      as: 'total_profit_estimate_analysis_chart'
  get '/oyster_sales_kilo_price_analysis_chart' => 'analysis#oyster_sales_kilo_price_analysis_chart',
      as: 'oyster_sales_kilo_price_analysis_chart'
  get '/oyster_market_kilo_price_analysis_chart' => 'analysis#oyster_market_kilo_price_analysis_chart',
      as: 'oyster_market_kilo_price_analysis_chart'
  get '/oyster_volume_analysis_chart' => 'analysis#oyster_volume_analysis_chart', as: 'oyster_volume_analysis_chart'
  get '/online_shop_order_count_chart' => 'analysis#online_shop_order_count_chart', as: 'online_shop_order_count_chart'
  get '/online_shop_order_sales_chart' => 'analysis#online_shop_order_sales_chart', as: 'online_shop_order_sales_chart'
  get '/furusato_order_count_chart' => 'analysis#furusato_order_count_chart', as: 'furusato_order_count_chart'

  # MESSAGES
  get '/messages/:id/download(/:file_name)', to: 'messages#download', as: 'download_message'
  get '/messages' => 'messages#index', as: 'messages'
  get '/messages/:id/:turbo_action' => 'messages#show', as: 'message'
  delete '/messages/:id' => 'messages#destroy', as: 'destroy_message'
  get '/message/:id', to: 'messages#content', as: 'message_content'
  get '/message/refresh/:id', to: 'messages#refresh', as: 'refresh_message'

  # FROZEN OYSTERS
  resources :frozen_oysters
  get '/insert_frozen_data' => 'frozen_oysters#insert_frozen_data', as: 'insert_frozen_data'

  # EXPIRATION CARDS
  resources :expiration_cards do
    get 'download/:file_name', on: :member, constraints: { format: 'pdf' },
                               to: 'expiration_cards#download', as: 'download'
  end
  get 'expiration_cards/new/:product_name/:ingredient_source/:consumption_restrictions/:manufactuered_date/:expiration_date/:made_on/:shomiorhi',
      as: 'new', to: 'expiration_cards#new'
  get 'regenerate_expiration_cards', as: 'regenerate_expiration_cards', to: 'expiration_cards#regenerate'

  # OYSTER SUPPLIES
  resources :oyster_supplies
  get '/oyster_supplies/invoice_preview/:invoice_format/:layout/:start_date/:end_date/:location',
      as: :invoice_preview,
      to: 'oyster_supplies#invoice_preview'
  get '/oyster_supplies/new_by/:supply_date(.:format)', as: :new_by, to: 'oyster_supplies#new_by'
  get '/oyster_supplies/supply_check/:id(.:format)', as: :supply_check, to: 'oyster_supplies#supply_check'
  get '/oyster_supplies/fetch_supplies/:start/:end(.:format)', as: :fetch_supplies, to: 'oyster_supplies#fetch_supplies'
  get '/oyster_supplies/fetch_invoice/:id(.:format)', as: 'fetch_invoice', to: 'oyster_supplies#fetch_invoice'
  get '/oyster_supplies/tippy_stats/:id/:stat', as: 'tippy_supply_stats', to: 'oyster_supplies#tippy_stats'
  get '/oyster_supplies/supply_action_nav/:start_date/:end_date', to: 'oyster_supplies#supply_action_nav'
  get '/oyster_supplies/new_invoice/:start_date/:end_date(.:format)', as: 'new_invoice',
                                                                      to: 'oyster_supplies#new_invoice'
  get '/oyster_supplies/supply_invoice_actions/:start_date/:end_date', as: 'supply_invoice_actions',
                                                                       to: 'oyster_supplies#supply_invoice_actions'
  get '/oyster_supplies/supply_price_actions/:start_date/:end_date', as: 'supply_price_actions',
                                                                     to: 'oyster_supplies#supply_price_actions'
  get '/oyster_supplies/supply_stats_partial/:start_date/:end_date', as: 'supply_stats_partial',
                                                                     to: 'oyster_supplies#supply_stats'
  post '/oyster_supplies/set_prices/:start_date/:end_date/', as: 'set_prices', to: 'oyster_supplies#set_prices'

  # OYSTER INVOICES
  resources :oyster_invoices do
    get :force_send_mail, on: :member
  end
  get '/oyster_invoices/search/:id(.:format)', as: :oyster_invoice_search, to: 'oyster_invoices#index'
  get '/oyster_invoices/create/:start_date/:end_date(.:format)', as: :create, to: 'oyster_invoices#create'

  # SUPPLIERS
  resources :suppliers
  get '/login', to: 'sessions#new'

  # USERS
  devise_for :users, controllers: { sessions: 'users/sessions', registrations: 'users/registrations' }
  match '/users/approveUser', to: 'users#approveUser', via: 'get'
  match '/users/unapproveUser', to: 'users#unapproveUser',  via: 'get'
  match 'users/:id' => 'users#destroy', :via => :delete, :as => :admin_destroy_user
  match 'users/:id' => 'users#show', via: 'get', as: :user
  resources :users

  # PROFITS
  resources :profits do
    resources :markets do
      get :edit_market, to: 'profits#edit_market', on: :member
    end
    resources :products
    collection do
      get 'new_by_product_type'
      get 'new_tabs'
    end
    member do
      get 'index_profit', as: :index_profit
    end
  end
  get 'profits/new/:sales_date' => 'profits#new_by_date', as: 'new_by_date'
  get 'profits/:id/profits/new/:sales_date' => 'profits#new_by_date', as: 'new_by_date_from_profit'
  get '/profits/:id/tab_edit' => 'profits#tab_edit', as: 'tab_edit'
  get '/fetch_market' => 'profits#fetch_market', as: 'fetch_market'
  get '/profits/:id/next_market/:mjsnumber' => 'profits#next_market', as: 'next_market'
  get '/profits/:id/update_completion' => 'profits#update_completion', as: 'update_completion'
  patch 'profits/:id/autosave', as: :autosave, to: 'profits#autosave'
  patch 'profits/:id/tab_keisan' => 'profits#tab_keisan', as: 'tab_keisan'
  get 'profits/:id/fetch_volumes' => 'profits#fetch_volumes', as: 'fetch_volumes'

  # PRODUCTS
  resources :products do
    resources :markets
    resources :materials
    get :index_product
    post :update_index_product
  end
  post '/fetch_products_by_type' => 'products#fetch_products_by_type', as: 'fetch_products_by_type'
  get '/insert_product_data/:id' => 'products#insert_product_data', as: 'insert_product_data'

  # MARKETS
  resources :markets do
    resources :products
    get :index_market
    patch :update_index_market
  end
  get 'markets_index_markets', to: 'markets#index_markets'

  # MATERIALS
  resources :materials do
    resources :products
  end
  post 'materials/:id(.:format)' => 'materials#update'
  get '/insert_material' => 'materials#insert_material', as: 'insert_material'

  # RAKUTEN ORDERS
  resources :rakuten_orders, only: [:index]
  get '/fetch_rakuten_orders_list/:date', as: :fetch_rakuten_orders_list,
                                          to: 'rakuten_orders#fetch_rakuten_orders_list', defaults: { format: 'js' }
  get '/rakuten_orders_list/:date', as: :rakuten_orders_list, to: 'rakuten_orders#rakuten_orders_list'
  get '/rakuten_orders/refresh/:date', as: :refresh_rakuten_orders, to: 'rakuten_orders#refresh'
  get '/rakuten_orders/refresh_month', as: :refresh_month_rakuten_orders, to: 'rakuten_orders#refresh_month'
  get '/rakuten_orders/process', as: :process_rakuten_orders, to: 'rakuten_orders#jidou_syori'
  get '/rakuten_orders/shipping_list/:date', as: :rakuten_shipping_list, to: 'rakuten_orders#shipping_list'

  # INFOMART
  resources :infomart_orders, only: [:index]
  get '/fetch_infomart_list/:date', as: :fetch_infomart_list, to: 'infomart_orders#fetch_infomart_list'
  get 'refresh_infomart', as: :refresh_infomart, to: 'infomart_orders#refresh'
  get 'infomart_csv/:ship_date', as: :infomart_csv, to: 'infomart_orders#infomart_csv'
  get 'infomart_shipping_list/:ship_date/:blank', as: :infomart_shipping_list,
                                                  to: 'infomart_orders#infomart_shipping_list'
  post '/infomart_orders/csv_upload/(.:format)', as: :infomart_csv_upload, to: 'infomart_orders#csv_upload'

  # YAHOO ORDERS
  resources :yahoo_orders, only: [:index]
  get 'yahoo/(.:test)', as: :yahoo_response_auth_code, to: 'yahoo_orders#yahoo_response_auth_code'
  get '/fetch_yahoo_list/:date', as: :fetch_yahoo_list, to: 'yahoo_orders#fetch_yahoo_list'
  get 'refresh_yahoo', as: :refresh_yahoo, to: 'yahoo_orders#refresh'
  get 'yahoo_spreadsheet/:ship_date', as: :yahoo_spreadsheet, to: 'yahoo_orders#yahoo_spreadsheet',
                                      defaults: { format: :xls }
  get 'yahoo_csv/:ship_date', as: :yahoo_csv, to: 'yahoo_orders#yahoo_csv', defaults: { format: :csv }
  get 'yahoo_shipping_list/:ship_date', as: :yahoo_shipping_list, to: 'yahoo_orders#yahoo_shipping_list'
  post 'yahoo_token_update', as: :yahoo_token_update, to: 'yahoo_orders#yahoo_token_update'

  # FUNABIKI ORDERS
  resources :funabiki_orders, only: [:index]
  get '/fetch_funabiki_list/:date', as: :fetch_funabiki_list, to: 'funabiki_orders#fetch_funabiki_list'
  get '/funabiki_orders/refresh', as: :refresh_funabiki_orders, to: 'funabiki_orders#refresh'
  get '/funabiki_orders/shipping_list/:date', as: :funabiki_shipping_list, to: 'funabiki_orders#shipping_list'

  # PACKING LIST SETTINGS
  resources :ec_product_types
  resources :ec_products
  get 'ec_product_tab/:tab', as: :ec_product_tab, to: 'ec_products#ec_product_tab'
  post '/update_ec_products', as: :update_ec_products, to: 'ec_products#update_ec_products'
  post '/update_ec_product_types', as: :update_ec_product_types, to: 'ec_product_types#update_ec_product_types'
  post '/update_rakuten_processing_settings', as: :update_rakuten_processing_settings,
                                              to: 'ec_products#update_rakuten_processing_settings'
  post 'ec_section_headers', as: :ec_section_headers, to: 'ec_products#ec_section_headers'
  post 'restaurant_raw_headers', as: :restaurant_raw_headers,
                                 to: 'ec_products#restaurant_raw_headers'
  post 'restaurant_frozen_headers', as: :restaurant_frozen_headers,
                                    to: 'ec_products#restaurant_frozen_headers'

  # CSV PROCESSING
  get '/csv_processing' => 'application#csv_processing', as: 'csv_processing'
  post '/process_csv' => 'application#process_csv', as: 'process_csv'
end
