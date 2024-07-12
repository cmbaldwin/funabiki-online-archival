FactoryBot.define do
  factory :oroshi_invoice, class: 'Oroshi::Invoice' do
    beginning_of_month = Time.zone.today.beginning_of_month
    one_week_later = beginning_of_month + 7.days
    two_weeks_later = beginning_of_month + 14.days

    start_date { Time.zone.today }
    end_date { Time.zone.today - 7.days }
    send_email { [true, false].sample }
    send_at { Time.zone.now + 1.hour }
    sent_at { Time.zone.now + 2.hours }
    invoice_layout { Oroshi::Invoice.invoice_layouts.keys.sample }
    supplier_organizations do
      if Oroshi::SupplierOrganization.any?
        Oroshi::SupplierOrganization.active.by_supplier_count.sample(rand(1..3))
      else
        create_list(:oroshi_supplier_organization, rand(1..3))
      end
    end

    trait :with_supply_dates do
      after(:create) do |invoice|
        (1..rand(1..3)).each do
          date = FFaker::Time.between(invoice.start_date, invoice.end_date)
          next if Oroshi::SupplyDate.exists?(date: date)

          supply_date = create(:oroshi_supply_date, :with_supplies, date: date)
          create_list(:oroshi_supply, rand(1..3), supply_date: supply_date)
          invoice.supply_dates << supply_date
        end
      end
    end
  end
end
