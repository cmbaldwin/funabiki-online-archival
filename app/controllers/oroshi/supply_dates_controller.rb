module Oroshi
  class SupplyDatesController < ApplicationController
    include SupplyPriceAssignment

    before_action :set_supply_dates
    before_action :set_supplier_organizations
    before_action :set_entry_vars, only: %i[entry]
    before_action :set_message, only: %i[checklist]

    # GET /oroshi/supply_dates/:date
    def show; end

    # GET /oroshi/supply_dates/:date/entry/:supplier_organization_id/:supply_reception_time_id
    def entry; end

    # GET /oroshi/supply_dates/:date/checklist/:region_id/:supply_reception_time_ids
    def checklist
      Oroshi::SupplyCheckWorker.perform_async(params[:date], @message.id,
                                              [params[:subregion_ids]], params[:supply_reception_time_ids])
      head :ok
    end

    def supply_price_actions
      render_modal('oroshi/supplies/modal/supply_price_actions')
    end

    def supply_invoice_actions
      @invoice = Oroshi::Invoice.new(
        start_date: @dates.first, end_date: @dates.last, supply_dates: @supply_dates, send_email: true
      )
      render_modal('oroshi/supplies/modal/supply_invoice_actions')
    end

    def set_supply_prices
      process_price_assignments
      render_modal('oroshi/supplies/modal/supply_price_results')
    end

    private

    # Only allow a list of trusted parameters through.

    def entry_params
      params.permit(:date, :supplier_organization_id, :supply_reception_time_id)
    end

    def supply_date_params
      params.require(:oroshi_supply_date)
            .permit(:date)
    end

    def supply_prices_params
      params.permit!
    end

    # Use callbacks to share common setup or constraints between actions.

    def set_supply_dates
      date = params[:date]
      @dates = params[:supply_dates]
      if date
        @supply_date = SupplyDate.find_or_create_by(date: params[:date])
      elsif @dates
        @supply_dates = SupplyDate.where(date: @dates).order(:date)
        @supplier_organizations = @supply_dates.map(&:supplier_organizations).flatten.uniq
      end
    end

    def set_supplier_organizations
      @supplier_organizations = SupplierOrganization.active.by_subregion.by_supplier_count
    end

    def set_entry_vars
      @supplier_organization = Oroshi::SupplierOrganization.find(params[:supplier_organization_id])
      @supply_reception_time = Oroshi::SupplyReceptionTime.find(params[:supply_reception_time_id])
      @supplies = set_supplies
    end

    def set_supplies
      @supplier_organization.suppliers.active.map do |supplier|
        supply_type_variations.map do |supply_type_variation|
          Array.new(supply_type_variation.default_container_count) do |index|
            find_or_initialize_supply(supplier, supply_type_variation, index)
          end
        end
      end.flatten
    end

    def supply_type_variations
      # Used to create supplies for inactive variations for suppliers
      # (this is also a helper method in app/helpers/oroshi/supply_date_helper.rb)
      @supplier_organization.suppliers.map(&:supply_type_variations).flatten.uniq.sort do |a, b|
        [a.supply_type.supply_type_variations.length, a.supply_type.name] <=>
          [b.supply_type.supply_type_variations.length, b.supply_type.name]
      end
    end

    def find_or_initialize_supply(supplier, supply_type_variation, index)
      return unless supplier.supply_type_variations.include?(supply_type_variation)

      supply_params = {
        supply_date: @supply_date,
        supplier: supplier,
        supply_type_variation: supply_type_variation,
        supply_reception_time: @supply_reception_time
      }

      supply = Oroshi::Supply.where(supply_params).offset(index).first
      supply || Oroshi::Supply.create(supply_params)
    end

    def set_message
      @filename = "供給チェック表 #{params.values[2..].join}.pdf"
      @message = Message.new(
        user: current_user.id,
        model: 'supply_check',
        state: false,
        message: "#{params[:date]}供給受入れチェック表を作成中…",
        data: {
          supply_date: params[:date],
          filename: @filename,
          expiration: (DateTime.now + 1.day)
        }
      )
      @message.save
    end

    def render_modal(path)
      respond_to do |format|
        format.turbo_stream do
          render 'oroshi/supplies/modal/replace_supply_modal', locals: { path: path }
        end
      end
    end
  end
end
