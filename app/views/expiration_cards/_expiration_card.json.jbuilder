json.extract! expiration_card, :id, :product_name, :manufacturer_address, :manufacturer, :ingredient_source, :consumption_restrictions, :manufactuered_date, :expiration_date, :created_at, :updated_at
json.url expiration_card_url(expiration_card, format: :json)
