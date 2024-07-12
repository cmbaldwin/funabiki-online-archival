module OysterSupplyTestHelper
  extend ActiveSupport::Concern

  included do
    # Modified methods for randomizing inputs
    def set_variables
      @sakoshi_suppliers = Supplier.where(location: '坂越').order(:supplier_number)
      @aioi_suppliers = Supplier.where(location: '相生').order(:supplier_number)
      @all_suppliers = @sakoshi_suppliers + @aioi_suppliers
      @receiving_times = %w[am pm]
      set_types
      @supplier_numbers = @sakoshi_suppliers.pluck(:id).map(&:to_s)
      @supplier_numbers += @aioi_suppliers.pluck(:id).map(&:to_s)
    end

    def set_types
      @types = %w[large small eggy damaged large_shells small_shells thin_shells
                  small_triploid_shells triploid_shells large_triploid_shells xl_triploid_shells]
    end

    def nengapi_date(i = 0)
      (Time.zone.today - i).strftime('%Y年%m月%d日')
    end

    def randomize_sakoshi(oysters)
      @receiving_times.each do |time|
        oysters[time] ||= {}
        @types.each do |type|
          oysters[time][type] ||= {}
          @supplier_numbers.each do |sup_id|
            oysters[time][type][sup_id] ||= {}
            randomize_oyster_inputs(oysters, time, type, sup_id)
          end
        end
      end
    end

    def randomize_oyster_inputs(oysters, time, type, sup_id)
      position = oysters[time][type][sup_id]
      if (type == 'large') || (type == 'small')
        position['subtotal'] = randomize_oyster_cells(oysters, time, type, sup_id, 6)
      else # kizu and ran
        volume = rand(10).to_s
        position['0'] = volume
        position['subtotal'] = volume
      end
      randomize_invoice_outputs(oysters, type, sup_id)
    end

    def randomize_oyster_cells(oysters, time, type, sup_id, cell_num)
      position = oysters[time][type][sup_id]
      subtotal = 0
      cell_num.times do |i|
        volume = rand(100)
        subtotal += volume
        position[i.to_s] = volume.to_s
      end
      subtotal.to_s
    end

    def get_subtotal(oysters, time, type, sup_id)
      position = oysters[time][type][sup_id]
      position.each_with_object(0){ |(key,val), cnt| cnt += val.to_i unless key == 'subtotal' }
    end

    def randomize_invoice_outputs(oysters, type, sup_id)
      position = oysters[type][sup_id]
      volume = @receiving_times.map{ |time| oysters[time][type][sup_id]['subtotal'].to_i }.sum
      price = rand(1000)
      position['volume'] = volume.to_s
      position['price'] = price.to_s
      position['invoice'] = (volume * price).to_s
    end

    def randomize_params(supply)
      set_variables
      rand_oysters = supply.oysters
      randomize_sakoshi(rand_oysters)
      { oysters: rand_oysters }
    end

    def setup_test_supplies
      5.times do |i|
        supply = OysterSupply.new(supply_date: nengapi_date(i))
        supply.do_setup
        if supply.save
          supply.update(randomize_params(supply))
        end
      end
    end
  end
end
