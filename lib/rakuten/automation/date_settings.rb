module Rakuten
  module Automation
    module DateSettings
      # This module is for automated calculation of package shipping and order arrival dates

      def shipping_base_date
        cutoff_hour = get_setting('ship_today_cutoff_hour') || 6
        # date today at 00:00
        cutoff = Time.zone.parse("#{Time.zone.today} 00:00:00") + cutoff_hour.hours
        Time.zone.now > cutoff ? Time.zone.tomorrow : Time.zone.today
      end

      def calculate_shipping_date(package)
        arrival_prefecture = package['SenderModel']['prefecture']

        @memo_set_time = @order['remarks'][/[0-9]{2}:[0-9]{2}-[0-9]{2}:[0-9]{2}/]
        @memo_set_time ||= @order['remarks'][/午前中/] || @order['shippingTerm']

        @earliest_arrival_days, @earliest_arrival_hours = earliest_arrival(arrival_prefecture,
                                                                           package['SenderModel']['city'])
        @earliest_possible_arrival = shipping_base_date.to_time + @earliest_arrival_days + add_hours_enum(@earliest_arrival_hours)

        if @arrival_date.nil?
          shipping_date_for_unspecified_arrival
        elsif @arrival_date && @memo_set_time.nil?
          shipping_date_for_specified_date
        elsif @arrival_date && @memo_set_time
          shipping_date_for_specified_datetime
        end.to_s
      end

      def shipping_date_for_unspecified_arrival
        # Set to base date, today if order time is before 6am, tomorrow if later
        shipping_date = shipping_base_date
        # Add time necessary to find earliest arrival
        @arrival_date = shipping_base_date + @earliest_arrival_days
        # Now that we have a desired estimated arrival time, let's check if it matches their desired arrival time
        if @memo_set_time && (@memo_set_time != 0)
          set_time_arrival = @arrival_date.to_time + add_hours_string(@memo_set_time)
          # If the arrival time they set isn't possible, then we need to add a day to our arrival time setting
          @arrival_date += 1.day if set_time_arrival < @earliest_possible_arrival
        end
        shipping_date
      end

      def shipping_date_for_specified_date
        @arrival_date = Date.parse(@arrival_date) unless @arrival_date.is_a?(Date)
        shipping_date = @arrival_date - @earliest_arrival_days
      end

      def shipping_date_for_specified_datetime
        @arrival_date = Date.parse(@arrival_date) unless @arrival_date.is_a?(Date)
        set_time_arrival = @arrival_date.to_time + add_hours_string(@memo_set_time)

        destination_min_arrival_time_hours = add_hours_enum(@earliest_arrival_hours)
        set_arrival_time_hours = add_hours_string(@memo_set_time)

        # Check if setting possible
        if set_time_arrival < @earliest_possible_arrival # impossible setting
          # Discrepancy/conflict with customer set time
          # When the customer set time is not possible to arrive in time
          @impossible_delivery_time = true
          # Have to add a day to the set arrival day so it can arrive at the desired set time
          @arrival_date += 1.day
        end
        shipping_date = @arrival_date - @earliest_arrival_days
        return shipping_date unless destination_min_arrival_time_hours > set_arrival_time_hours

        shipping_date -= 1.day
      end
    end
  end
end
