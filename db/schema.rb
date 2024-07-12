# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_07_11_043705) do
  create_schema "heroku_ext"

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ec_product_types", force: :cascade do |t|
    t.string "name"
    t.string "counter"
    t.integer "section"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "restaurant_raw_section"
    t.integer "restaurant_frozen_section"
  end

  create_table "ec_products", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "ec_product_type_id", null: false
    t.string "cross_reference_ids", default: [], null: false, array: true
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "frozen_item"
    t.string "memo_name"
    t.integer "extra_shipping_cost"
    t.index ["ec_product_type_id"], name: "index_ec_products_on_ec_product_type_id"
  end

  create_table "expiration_cards", force: :cascade do |t|
    t.string "product_name"
    t.string "manufacturer_address"
    t.string "manufacturer"
    t.string "ingredient_source"
    t.string "consumption_restrictions"
    t.string "manufactuered_date"
    t.string "expiration_date"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "download"
    t.string "storage_recommendation"
    t.boolean "made_on"
    t.boolean "shomiorhi"
  end

  create_table "funabiki_orders", force: :cascade do |t|
    t.string "order_id"
    t.datetime "order_time", precision: nil
    t.date "ship_date"
    t.date "arrival_date"
    t.string "ship_status"
    t.json "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "stat_id"
    t.index ["stat_id"], name: "index_funabiki_orders_on_stat_id"
  end

  create_table "furusato_orders", force: :cascade do |t|
    t.integer "ssys_id"
    t.string "furusato_id"
    t.string "katakana_name"
    t.string "kanji_name"
    t.string "title"
    t.string "product_code"
    t.string "product_name"
    t.string "order_status"
    t.date "system_entry_date"
    t.date "shipped_date"
    t.date "est_arrival_date"
    t.date "est_shipping_date"
    t.string "arrival_time"
    t.string "shipping_company"
    t.string "shipping_number"
    t.string "details_url"
    t.string "address"
    t.string "phone"
    t.string "sale_memo"
    t.string "mail_memo"
    t.string "lead_time"
    t.string "noshi"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "stat_id"
    t.index ["shipped_date"], name: "index_furusato_orders_on_shipped_date"
    t.index ["stat_id"], name: "index_furusato_orders_on_stat_id"
  end

  create_table "infomart_orders", force: :cascade do |t|
    t.bigint "order_id"
    t.string "status"
    t.string "destination"
    t.datetime "order_time", precision: nil
    t.date "ship_date"
    t.date "arrival_date"
    t.text "items"
    t.string "address"
    t.text "csv_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "stat_id"
    t.index ["ship_date"], name: "index_infomart_orders_on_ship_date"
    t.index ["stat_id"], name: "index_infomart_orders_on_stat_id"
  end

  create_table "markets", force: :cascade do |t|
    t.string "namae"
    t.string "address"
    t.string "phone"
    t.string "repphone"
    t.string "fax"
    t.decimal "cost"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "mjsnumber"
    t.string "zip"
    t.string "nick"
    t.decimal "one_time_cost"
    t.decimal "optional_cost"
    t.string "one_time_cost_description"
    t.string "optional_cost_description"
    t.decimal "block_cost"
    t.string "color"
    t.decimal "handling"
    t.boolean "brokerage", default: true
    t.boolean "active", default: true
    t.index ["id"], name: "index_markets_on_id"
    t.index ["mjsnumber"], name: "index_markets_on_mjsnumber"
  end

  create_table "materials", force: :cascade do |t|
    t.string "namae"
    t.string "zairyou"
    t.decimal "cost"
    t.text "history"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "divisor"
    t.boolean "per_product"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "user"
    t.string "model"
    t.string "message"
    t.boolean "state"
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "document"
  end

  create_table "online_orders", force: :cascade do |t|
    t.bigint "order_id"
    t.datetime "order_time", precision: nil
    t.datetime "date_modified", precision: nil
    t.string "status"
    t.date "ship_date"
    t.date "arrival_date"
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "stat_id"
    t.index ["ship_date"], name: "index_online_orders_on_ship_date"
    t.index ["stat_id"], name: "index_online_orders_on_stat_id"
  end

  create_table "oroshi_addresses", force: :cascade do |t|
    t.string "name"
    t.string "company"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "postal_code"
    t.string "phone"
    t.string "alternative_phone"
    t.integer "subregion_id"
    t.integer "country_id"
    t.boolean "default", default: false
    t.boolean "active", default: true
    t.string "addressable_type", null: false
    t.bigint "addressable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["addressable_type", "addressable_id"], name: "index_oroshi_addresses_on_addressable"
  end

  create_table "oroshi_buyers", force: :cascade do |t|
    t.string "name", null: false
    t.integer "entity_type", null: false
    t.string "handle", null: false
    t.string "representative_phone"
    t.string "fax"
    t.string "associated_system_id"
    t.string "color"
    t.float "handling_cost", null: false
    t.string "handling_cost_notes"
    t.float "daily_cost", null: false
    t.string "daily_cost_notes"
    t.float "optional_cost", null: false
    t.string "optional_cost_notes"
    t.decimal "commission_percentage", null: false
    t.boolean "brokerage", default: true
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oroshi_buyers_shipping_methods", force: :cascade do |t|
    t.bigint "buyer_id", null: false
    t.bigint "shipping_method_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_oroshi_buyers_shipping_methods_on_buyer_id"
    t.index ["shipping_method_id"], name: "index_oroshi_buyers_shipping_methods_on_shipping_method_id"
  end

  create_table "oroshi_invoice_supplier_organizations", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.bigint "supplier_organization_id", null: false
    t.jsonb "passwords", default: {}
    t.boolean "completed", default: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_oroshi_invoice_supplier_organizations_on_invoice_id"
    t.index ["supplier_organization_id"], name: "idx_on_supplier_organization_id_85375e363b"
  end

  create_table "oroshi_invoice_supply_dates", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.bigint "supply_date_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_oroshi_invoice_supply_dates_on_invoice_id"
    t.index ["supply_date_id"], name: "index_oroshi_invoice_supply_dates_on_supply_date_id"
  end

  create_table "oroshi_invoices", force: :cascade do |t|
    t.date "start_date"
    t.date "end_date"
    t.boolean "send_email"
    t.datetime "send_at"
    t.datetime "sent_at"
    t.integer "invoice_layout"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oroshi_material_categories", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oroshi_materials", force: :cascade do |t|
    t.string "name", null: false
    t.float "cost", null: false
    t.integer "per", null: false
    t.boolean "active", default: true
    t.bigint "material_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["material_category_id"], name: "index_oroshi_materials_on_material_category_id"
  end

  create_table "oroshi_order_templates", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.text "notes"
    t.string "identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_oroshi_order_templates_on_order_id"
  end

  create_table "oroshi_orders", force: :cascade do |t|
    t.bigint "buyer_id", null: false
    t.bigint "product_variation_id", null: false
    t.bigint "product_inventory_id", null: false
    t.bigint "shipping_receptacle_id", null: false
    t.bigint "shipping_method_id", null: false
    t.integer "item_quantity", default: 0, null: false
    t.integer "receptacle_quantity", default: 0, null: false
    t.integer "freight_quantity", default: 0, null: false
    t.float "shipping_cost", default: 0.0, null: false
    t.float "materials_cost", default: 0.0, null: false
    t.float "sale_price_per_item", default: 0.0, null: false
    t.float "adjustment", default: 0.0, null: false
    t.string "note"
    t.integer "status"
    t.bigint "bundled_with_order_id"
    t.boolean "bundled_shipping_receptacle", default: false
    t.boolean "add_buyer_optional_cost", default: false
    t.date "shipping_date"
    t.date "arrival_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bundled_with_order_id"], name: "index_oroshi_orders_on_bundled_with_order_id"
    t.index ["buyer_id"], name: "index_oroshi_orders_on_buyer_id"
    t.index ["product_inventory_id"], name: "index_oroshi_orders_on_product_inventory_id"
    t.index ["product_variation_id"], name: "index_oroshi_orders_on_product_variation_id"
    t.index ["shipping_method_id"], name: "index_oroshi_orders_on_shipping_method_id"
    t.index ["shipping_receptacle_id"], name: "index_oroshi_orders_on_shipping_receptacle_id"
  end

  create_table "oroshi_packagings", force: :cascade do |t|
    t.string "name", null: false
    t.float "cost", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "product_id"
    t.index ["product_id"], name: "index_oroshi_packagings_on_product_id"
  end

  create_table "oroshi_product_inventories", force: :cascade do |t|
    t.bigint "product_variation_id", null: false
    t.date "manufacture_date", null: false
    t.date "expiration_date", null: false
    t.integer "quantity", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_variation_id"], name: "index_oroshi_product_inventories_on_product_variation_id"
  end

  create_table "oroshi_product_materials", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "material_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["material_id"], name: "index_oroshi_product_materials_on_material_id"
    t.index ["product_id"], name: "index_oroshi_product_materials_on_product_id"
  end

  create_table "oroshi_product_variation_packagings", force: :cascade do |t|
    t.bigint "product_variation_id", null: false
    t.bigint "packaging_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["packaging_id"], name: "index_oroshi_product_variation_packagings_on_packaging_id"
    t.index ["product_variation_id"], name: "idx_on_product_variation_id_9188fea723"
  end

  create_table "oroshi_product_variation_production_zones", force: :cascade do |t|
    t.bigint "product_variation_id", null: false
    t.bigint "production_zone_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_variation_id"], name: "idx_on_product_variation_id_d080048cfb"
    t.index ["production_zone_id"], name: "idx_on_production_zone_id_cc4cc5a5ab"
  end

  create_table "oroshi_product_variation_supply_type_variations", force: :cascade do |t|
    t.bigint "product_variation_id", null: false
    t.bigint "supply_type_variation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_variation_id"], name: "idx_on_product_variation_id_0daf74b3b8"
    t.index ["supply_type_variation_id"], name: "idx_on_supply_type_variation_id_8cd5e1bc89"
  end

  create_table "oroshi_product_variations", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "default_shipping_receptacle_id"
    t.string "name", null: false
    t.string "handle", null: false
    t.float "primary_content_volume", null: false
    t.integer "primary_content_country_id"
    t.integer "primary_content_subregion_id"
    t.integer "shelf_life"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "spacing_volume_adjustment", precision: 5, scale: 2, default: "1.0"
    t.integer "default_per_box"
    t.index ["default_shipping_receptacle_id"], name: "idx_on_default_shipping_receptacle_id_8db7516e01"
    t.index ["product_id"], name: "index_oroshi_product_variations_on_product_id"
  end

  create_table "oroshi_production_requests", force: :cascade do |t|
    t.bigint "product_variation_id", null: false
    t.bigint "product_inventory_id"
    t.bigint "production_zone_id", null: false
    t.bigint "shipping_receptacle_id"
    t.integer "request_quantity", null: false
    t.integer "fulfilled_quantity", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_inventory_id"], name: "index_oroshi_production_requests_on_product_inventory_id"
    t.index ["product_variation_id"], name: "index_oroshi_production_requests_on_product_variation_id"
    t.index ["production_zone_id"], name: "index_oroshi_production_requests_on_production_zone_id"
    t.index ["shipping_receptacle_id"], name: "index_oroshi_production_requests_on_shipping_receptacle_id"
  end

  create_table "oroshi_production_zones", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oroshi_products", force: :cascade do |t|
    t.string "name", null: false
    t.string "units", null: false
    t.decimal "exterior_height"
    t.decimal "exterior_width"
    t.decimal "exterior_depth"
    t.bigint "supply_type_id", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "tax_rate", precision: 5, scale: 2, default: "0.0"
    t.decimal "supply_loss_adjustment", precision: 5, scale: 2, default: "1.0"
    t.integer "position"
    t.index ["supply_type_id"], name: "index_oroshi_products_on_supply_type_id"
  end

  create_table "oroshi_shipping_methods", force: :cascade do |t|
    t.string "name", null: false
    t.string "handle", null: false
    t.bigint "shipping_organization_id", null: false
    t.string "departure_times", default: [], array: true
    t.float "daily_cost", default: 0.0, null: false
    t.float "per_shipping_receptacle_cost", default: 0.0, null: false
    t.float "per_freight_unit_cost", default: 0.0, null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shipping_organization_id"], name: "index_oroshi_shipping_methods_on_shipping_organization_id"
  end

  create_table "oroshi_shipping_organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "handle", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oroshi_shipping_receptacles", force: :cascade do |t|
    t.string "name", null: false
    t.string "handle", null: false
    t.float "cost", null: false
    t.integer "default_freight_bundle_quantity", default: 1
    t.decimal "interior_height"
    t.decimal "interior_width"
    t.decimal "interior_depth"
    t.decimal "exterior_height"
    t.decimal "exterior_width"
    t.decimal "exterior_depth"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oroshi_supplier_organizations", force: :cascade do |t|
    t.integer "entity_type", null: false
    t.string "entity_name", null: false
    t.string "micro_region"
    t.integer "subregion_id", null: false
    t.integer "country_id", null: false
    t.string "invoice_number"
    t.string "invoice_name"
    t.string "honorific_title"
    t.string "phone"
    t.string "fax"
    t.string "email"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oroshi_supplier_organizations_oroshi_supply_reception_times", force: :cascade do |t|
    t.bigint "supplier_organization_id", null: false
    t.bigint "supply_reception_time_id", null: false
    t.index ["supplier_organization_id"], name: "idx_on_supplier_organization_id_cecc289244"
    t.index ["supply_reception_time_id"], name: "idx_on_supply_reception_time_id_bd1921216d"
  end

  create_table "oroshi_suppliers", force: :cascade do |t|
    t.string "company_name"
    t.string "short_name"
    t.integer "supplier_number"
    t.bigint "user_id"
    t.text "representatives", default: [], array: true
    t.string "phone"
    t.string "invoice_number"
    t.string "invoice_name"
    t.string "honorific_title"
    t.boolean "active"
    t.bigint "supplier_organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["supplier_organization_id"], name: "index_oroshi_suppliers_on_supplier_organization_id"
  end

  create_table "oroshi_suppliers_oroshi_supply_type_variations", force: :cascade do |t|
    t.bigint "supplier_id", null: false
    t.bigint "supply_type_variation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["supplier_id"], name: "idx_on_supplier_id_78ea5376f0"
    t.index ["supply_type_variation_id"], name: "idx_on_supply_type_variation_id_ed73826397"
  end

  create_table "oroshi_supplies", force: :cascade do |t|
    t.bigint "supply_type_variation_id", null: false
    t.bigint "supply_reception_time_id", null: false
    t.bigint "supplier_id", null: false
    t.bigint "supply_date_id", null: false
    t.boolean "locked", default: false
    t.float "quantity", default: 0.0, null: false
    t.float "price", default: 0.0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["supplier_id"], name: "index_oroshi_supplies_on_supplier_id"
    t.index ["supply_date_id"], name: "index_oroshi_supplies_on_supply_date_id"
    t.index ["supply_reception_time_id"], name: "index_oroshi_supplies_on_supply_reception_time_id"
    t.index ["supply_type_variation_id"], name: "index_oroshi_supplies_on_supply_type_variation_id"
  end

  create_table "oroshi_supply_date_supplier_organizations", force: :cascade do |t|
    t.bigint "supply_date_id", null: false
    t.bigint "supplier_organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["supplier_organization_id", "supply_date_id"], name: "index_supplier_organizations_supply_dates_on_ids"
    t.index ["supplier_organization_id"], name: "idx_on_supplier_organization_id_a9291c6a52"
    t.index ["supply_date_id", "supplier_organization_id"], name: "index_supply_date_supplier_organizations_on_ids", unique: true
    t.index ["supply_date_id"], name: "idx_on_supply_date_id_c5793d363e"
  end

  create_table "oroshi_supply_date_suppliers", force: :cascade do |t|
    t.bigint "supply_date_id", null: false
    t.bigint "supplier_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["supplier_id", "supply_date_id"], name: "index_suppliers_supply_dates_on_ids"
    t.index ["supplier_id"], name: "index_oroshi_supply_date_suppliers_on_supplier_id"
    t.index ["supply_date_id", "supplier_id"], name: "index_supply_date_suppliers_on_ids", unique: true
    t.index ["supply_date_id"], name: "index_oroshi_supply_date_suppliers_on_supply_date_id"
  end

  create_table "oroshi_supply_date_supply_type_variations", force: :cascade do |t|
    t.bigint "supply_date_id", null: false
    t.bigint "supply_type_variation_id", null: false
    t.integer "total", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["supply_date_id", "supply_type_variation_id"], name: "index_supply_date_supply_type_variations_on_ids", unique: true
    t.index ["supply_date_id"], name: "idx_on_supply_date_id_2fa23a9b0e"
    t.index ["supply_type_variation_id", "supply_date_id"], name: "index_supply_type_variations_supply_dates_on_ids"
    t.index ["supply_type_variation_id"], name: "idx_on_supply_type_variation_id_87a1480921"
  end

  create_table "oroshi_supply_date_supply_types", force: :cascade do |t|
    t.bigint "supply_date_id", null: false
    t.bigint "supply_type_id", null: false
    t.integer "total", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["supply_date_id", "supply_type_id"], name: "index_supply_date_supply_types_on_ids", unique: true
    t.index ["supply_date_id"], name: "index_oroshi_supply_date_supply_types_on_supply_date_id"
    t.index ["supply_type_id", "supply_date_id"], name: "index_supply_types_supply_dates_on_ids"
    t.index ["supply_type_id"], name: "index_oroshi_supply_date_supply_types_on_supply_type_id"
  end

  create_table "oroshi_supply_dates", force: :cascade do |t|
    t.date "date", null: false
    t.jsonb "totals", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_oroshi_supply_dates_on_date", unique: true
  end

  create_table "oroshi_supply_reception_times", force: :cascade do |t|
    t.integer "hour"
    t.string "time_qualifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oroshi_supply_type_variations", force: :cascade do |t|
    t.string "name"
    t.string "handle"
    t.integer "default_container_count"
    t.boolean "active"
    t.bigint "supply_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["supply_type_id"], name: "index_oroshi_supply_type_variations_on_supply_type_id"
  end

  create_table "oroshi_supply_types", force: :cascade do |t|
    t.string "name"
    t.string "handle"
    t.string "units"
    t.boolean "active"
    t.boolean "liquid", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oyster_invoices", force: :cascade do |t|
    t.string "start_date"
    t.string "end_date"
    t.string "aioi_all_pdf"
    t.string "aioi_seperated_pdf"
    t.string "sakoshi_all_pdf"
    t.string "sakoshi_seperated_pdf"
    t.boolean "completed"
    t.string "aioi_emails"
    t.string "sakoshi_emails"
    t.datetime "send_at", precision: 0
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oyster_invoices_supplies", id: false, force: :cascade do |t|
    t.bigint "oyster_supply_id", null: false
    t.bigint "oyster_invoice_id", null: false
    t.index ["oyster_invoice_id", "oyster_supply_id"], name: "supply_invoice_index"
  end

  create_table "oyster_supplies", force: :cascade do |t|
    t.text "oysters"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "supply_date"
    t.datetime "oysters_last_update", precision: nil
    t.text "totals"
    t.bigint "stat_id"
    t.date "date"
    t.integer "frozen_mukimi_weight"
    t.index ["date"], name: "index_oyster_supplies_on_date", unique: true
    t.index ["stat_id"], name: "index_oyster_supplies_on_stat_id"
  end

  create_table "product_and_market_joins", force: :cascade do |t|
    t.integer "product_id"
    t.integer "market_id"
    t.datetime "last_activity_at"
  end

  create_table "product_and_material_joins", force: :cascade do |t|
    t.integer "product_id"
    t.integer "material_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "namae"
    t.decimal "grams"
    t.decimal "cost"
    t.decimal "count"
    t.decimal "multiplier"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "product_type"
    t.decimal "extra_expense"
    t.boolean "profitable"
    t.decimal "average_price"
    t.boolean "associated", default: false
    t.boolean "active", default: true
    t.index ["namae"], name: "index_products_on_namae"
  end

  create_table "profit_and_market_joins", force: :cascade do |t|
    t.integer "profit_id"
    t.integer "market_id"
  end

  create_table "profit_and_product_joins", force: :cascade do |t|
    t.integer "profit_id"
    t.integer "product_id"
  end

  create_table "profits", force: :cascade do |t|
    t.string "sales_date"
    t.text "figures"
    t.text "totals"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "notes"
    t.text "debug_figures"
    t.boolean "split"
    t.boolean "ampm"
    t.text "subtotals"
    t.text "volumes"
    t.bigint "stat_id"
    t.date "date"
    t.index ["date"], name: "index_profits_on_date"
    t.index ["id"], name: "index_profits_on_id"
    t.index ["stat_id"], name: "index_profits_on_stat_id"
  end

  create_table "rakuten_orders", force: :cascade do |t|
    t.string "order_id"
    t.datetime "order_time", precision: nil
    t.date "arrival_date"
    t.text "ship_dates", default: [], array: true
    t.integer "status"
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "stat_id"
    t.index ["ship_dates"], name: "index_rakuten_orders_on_ship_dates"
    t.index ["stat_id"], name: "index_rakuten_orders_on_stat_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "name", null: false
    t.json "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_settings_on_name", unique: true
  end

  create_table "stats", force: :cascade do |t|
    t.date "date"
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "weather"
    t.index ["date"], name: "index_stats_on_date", unique: true
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "company_name"
    t.integer "supplier_number"
    t.string "address"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "location"
    t.text "representatives", default: [], array: true
    t.string "home_address"
    t.integer "phone"
    t.string "invoice_number"
    t.index ["user_id"], name: "index_suppliers_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "admin", default: false
    t.boolean "approved", default: false, null: false
    t.integer "role"
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "username"
    t.text "data"
    t.index ["approved"], name: "index_users_on_approved"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "yahoo_orders", force: :cascade do |t|
    t.string "order_id"
    t.date "ship_date"
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "stat_id"
    t.string "order_status"
    t.string "shipping_status"
    t.datetime "order_time", precision: nil
    t.index ["ship_date"], name: "index_yahoo_orders_on_ship_date"
    t.index ["stat_id"], name: "index_yahoo_orders_on_stat_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "oroshi_buyers_shipping_methods", "oroshi_buyers", column: "buyer_id"
  add_foreign_key "oroshi_buyers_shipping_methods", "oroshi_shipping_methods", column: "shipping_method_id"
  add_foreign_key "oroshi_invoice_supplier_organizations", "oroshi_invoices", column: "invoice_id", on_delete: :cascade
  add_foreign_key "oroshi_invoice_supplier_organizations", "oroshi_supplier_organizations", column: "supplier_organization_id"
  add_foreign_key "oroshi_invoice_supply_dates", "oroshi_invoices", column: "invoice_id", on_delete: :cascade
  add_foreign_key "oroshi_invoice_supply_dates", "oroshi_supply_dates", column: "supply_date_id"
  add_foreign_key "oroshi_materials", "oroshi_material_categories", column: "material_category_id"
  add_foreign_key "oroshi_order_templates", "oroshi_orders", column: "order_id"
  add_foreign_key "oroshi_orders", "oroshi_buyers", column: "buyer_id"
  add_foreign_key "oroshi_orders", "oroshi_orders", column: "bundled_with_order_id"
  add_foreign_key "oroshi_orders", "oroshi_product_inventories", column: "product_inventory_id"
  add_foreign_key "oroshi_orders", "oroshi_product_variations", column: "product_variation_id"
  add_foreign_key "oroshi_orders", "oroshi_shipping_methods", column: "shipping_method_id"
  add_foreign_key "oroshi_orders", "oroshi_shipping_receptacles", column: "shipping_receptacle_id"
  add_foreign_key "oroshi_packagings", "oroshi_products", column: "product_id"
  add_foreign_key "oroshi_product_inventories", "oroshi_product_variations", column: "product_variation_id"
  add_foreign_key "oroshi_product_materials", "oroshi_materials", column: "material_id"
  add_foreign_key "oroshi_product_materials", "oroshi_products", column: "product_id"
  add_foreign_key "oroshi_product_variation_packagings", "oroshi_packagings", column: "packaging_id"
  add_foreign_key "oroshi_product_variation_packagings", "oroshi_product_variations", column: "product_variation_id"
  add_foreign_key "oroshi_product_variation_production_zones", "oroshi_product_variations", column: "product_variation_id"
  add_foreign_key "oroshi_product_variation_production_zones", "oroshi_production_zones", column: "production_zone_id"
  add_foreign_key "oroshi_product_variation_supply_type_variations", "oroshi_product_variations", column: "product_variation_id"
  add_foreign_key "oroshi_product_variation_supply_type_variations", "oroshi_supply_type_variations", column: "supply_type_variation_id"
  add_foreign_key "oroshi_product_variations", "oroshi_products", column: "product_id"
  add_foreign_key "oroshi_product_variations", "oroshi_shipping_receptacles", column: "default_shipping_receptacle_id"
  add_foreign_key "oroshi_production_requests", "oroshi_product_inventories", column: "product_inventory_id"
  add_foreign_key "oroshi_production_requests", "oroshi_product_variations", column: "product_variation_id"
  add_foreign_key "oroshi_production_requests", "oroshi_production_zones", column: "production_zone_id"
  add_foreign_key "oroshi_production_requests", "oroshi_shipping_receptacles", column: "shipping_receptacle_id"
  add_foreign_key "oroshi_products", "oroshi_supply_types", column: "supply_type_id"
  add_foreign_key "oroshi_shipping_methods", "oroshi_shipping_organizations", column: "shipping_organization_id"
  add_foreign_key "oroshi_supplier_organizations_oroshi_supply_reception_times", "oroshi_supplier_organizations", column: "supplier_organization_id"
  add_foreign_key "oroshi_supplier_organizations_oroshi_supply_reception_times", "oroshi_supply_reception_times", column: "supply_reception_time_id"
  add_foreign_key "oroshi_suppliers", "oroshi_supplier_organizations", column: "supplier_organization_id"
  add_foreign_key "oroshi_suppliers_oroshi_supply_type_variations", "oroshi_suppliers", column: "supplier_id"
  add_foreign_key "oroshi_suppliers_oroshi_supply_type_variations", "oroshi_supply_type_variations", column: "supply_type_variation_id"
  add_foreign_key "oroshi_supplies", "oroshi_suppliers", column: "supplier_id"
  add_foreign_key "oroshi_supplies", "oroshi_supply_dates", column: "supply_date_id"
  add_foreign_key "oroshi_supplies", "oroshi_supply_reception_times", column: "supply_reception_time_id"
  add_foreign_key "oroshi_supplies", "oroshi_supply_type_variations", column: "supply_type_variation_id"
  add_foreign_key "oroshi_supply_date_supplier_organizations", "oroshi_supplier_organizations", column: "supplier_organization_id"
  add_foreign_key "oroshi_supply_date_supplier_organizations", "oroshi_supply_dates", column: "supply_date_id"
  add_foreign_key "oroshi_supply_date_suppliers", "oroshi_suppliers", column: "supplier_id"
  add_foreign_key "oroshi_supply_date_suppliers", "oroshi_supply_dates", column: "supply_date_id"
  add_foreign_key "oroshi_supply_date_supply_type_variations", "oroshi_supply_dates", column: "supply_date_id"
  add_foreign_key "oroshi_supply_date_supply_type_variations", "oroshi_supply_type_variations", column: "supply_type_variation_id"
  add_foreign_key "oroshi_supply_date_supply_types", "oroshi_supply_dates", column: "supply_date_id"
  add_foreign_key "oroshi_supply_date_supply_types", "oroshi_supply_types", column: "supply_type_id"
  add_foreign_key "oroshi_supply_type_variations", "oroshi_supply_types", column: "supply_type_id"
end
