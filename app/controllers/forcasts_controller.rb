# frozen_string_literal: true

# Forcasts Controller
class ForcastsController < ApplicationController
  include Forcasts

  def index; end

  def week_forcast
    week_data

    render partial: 'week_forcast'
  end

  def week_data
    @date = Date.parse(params[:date]) if params[:date]
    @date ||= Time.zone.today
    @range = @date.all_week
    @models = %w[rakuten_orders yahoo_orders funabiki_orders infomart_orders]
    @types = [['殻付き', 'セット(殻付き)', 'セル（飲食店）'], ['500g', '500g（飲食店）'], ['殻付き 小牡蠣'], ['三倍体 殻付き 牡蠣']]
    @data = accumulate_forcast_data
  end

  def fetch_week_forcast
    week_data

    render partial: 'week_forcast'
  end

  def fetch_forcast_calendar_counts
    @range = Date.parse(calendar_params[:start])..Date.parse(calendar_params[:end])
    @holidays = japanese_holiday_background_events(@range)
  end

  def count_calendar_event_tippy
    date = Date.strptime(params[:date], '%Y_%m_%d')
    fetch_forcast_tippy_data(date)
  end

  private

  def calendar_params
    params.permit(:date, :_, :start, :end, :format)
  end
end
