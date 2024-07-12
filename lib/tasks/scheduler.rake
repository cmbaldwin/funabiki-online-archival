namespace :stats do
  # Don't need this anymore, moving to new system.
  # desc 'Calculate average prices for Products from all existing Profit records'
  # task product_averages: :environment do
  #   ProductAveragesWorker.perform_async
  # end

  desc 'Calculate and save statistics for today'
  task set_today: :environment do
    StatWorker.perform_async
  end
end

namespace :daily_shell_cards do
  desc "Create today's shell cards and delete all expiration cards with manufacturing dates from yesterday"
  task do_prep: :environment do
    ExpirationRegenerationWorker.perform_async
  end
end

namespace :order_automation do
  desc 'Process Rakuten Shinki'
  task process_rakuten_shinki: :environment do
    if Setting.find_by(name: 'rakuten_processing_settings')&.settings&.dig('automation_on') || true
      RakutenProcessWorker.perform_async
    end
  end

  desc 'Pull RakutenOrder data'
  task pull_rakuten_orders: :environment do
    puts 'Pulling two months of Rakuten data/records from API...'
    RakutenBigRefreshWorker.perform_async
  end

  desc 'Get Yahoo Orders List (default one week, takes a time period parameter)'
  task refresh_yahoo: :environment do
    YahooUpdateWorker.perform_async
  end

  desc 'Update exisiting and get new Funabiki Orders'
  task refresh_funabiki: :environment do
    SolidusApiWorker.perform_async
  end
end

desc 'Pull all recent order data for today and tomorrow'
task pull_recent_order_data: :environment do
  Rake::Task['order_automation:process_rakuten_shinki'].execute
  Rake::Task['order_automation:pull_rakuten_orders'].execute
  Rake::Task['order_automation:refresh_yahoo'].execute
  Rake::Task['order_automation:refresh_funabiki'].execute
  # Destroy all messages older than 10 minutes
  Message.where('created_at < ?', 10.minutes.ago).destroy_all
end

desc 'Check for mail that needs to be sent and send it'
task mail_check_and_send: :environment do
  MailerWorker.perform_async
  Oroshi::MailerWorker.perform_async
end
