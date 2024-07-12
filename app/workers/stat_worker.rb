class StatWorker
  include Sidekiq::Worker

  def perform(recompute: false)
    stat = Stat.get_most_recent
    stat = Stat.new(date: Time.zone.today) unless stat.date == Time.zone.today
    calc_stat(stat)

    recompute_stats if recompute
    GC.start
  end

  def calc_stat(stat)
    stat.set
    stat.save
  end

  def recompute_stats
    all_methods = Stat.get_most_recent.data.keys
    Stat.all.each do |stat|
      calc_stat(stat) if stat.data.nil? || stat.data.keys != all_methods
    end
  end
end
