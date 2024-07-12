module AnalysisHelper

  def get_season_dates(year)
    year = year.to_i
    @season_start = DateTime.new((year - 1), 10, 1)
    @season_end = DateTime.new(year, 10, 1)
    (@season_start..@season_end).map { |d| to_nengapi(d)}
  end

  def get_last_frozen_of_season(nengapi_dates_array)
    FrozenOyster.where(manufacture_date: nengapi_dates_array).order(:manufacture_date).last
  end

  def get_ytd(year)
    if get_last_frozen_of_season(get_season_dates(year))
      ytd = get_last_frozen_of_season(get_season_dates(year)).year_to_date
    else
      ytd = nil
    end
  end

end
