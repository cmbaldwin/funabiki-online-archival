json.extract! oyster_invoice, :id, :start_date, :end_date, :aioi_all_pdf, :aioi_seperated_pdf, :sakoshi_all_pdf, :sakoshi_seperated_pdf, :completed, :emails, :data, :created_at, :updated_at
json.url oyster_invoice_url(oyster_invoice, format: :json)
