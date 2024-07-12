json.extract! supplier, :id, :company_name, :supplier_number, :address, :representative_name, :created_at, :updated_at
json.url supplier_url(supplier, format: :json)
