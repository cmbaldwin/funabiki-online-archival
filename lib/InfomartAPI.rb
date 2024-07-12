class InfomartAPI
  # require 'mechanize'
  require 'csv'

  # Acquire Data from the Infomart system
  # CSV Data Reference
  # [
  #     [ 0] "［データ区分］", #  H = Header, D = Data, F = Footer
  #     [ 1] "［伝票日付］",
  #     [ 2] "［伝票No］",
  #     [ 3] "［取引状態］",
  #     [ 4] "［自社コード］",
  #     [ 5] "［自社会員名］",
  #     [ 6] "［自社担当者］",
  #     [ 7] "［取引先コード］",
  #     [ 8] "［取引先名］",
  #     [ 9] "［納品場所コード］",
  #     [10] "［納品場所名］",
  #     [11] "［納品場所 住所］",
  #     [12] "［マイカタログID］",
  #     [13] "［自社管理商品コード］",
  #     [14] "［商品名］",
  #     [15] "［規格］",
  #     [16] "［入数］",
  #     [17] "［入数単位］",
  #     [18] "［単価］",
  #     [19] "［数量］",
  #     [20] "［単位］",
  #     [21] "［金額］",
  #     [22] "［消費税］",
  #     [23] "［小計］",
  #     [24] "［課税区分］",
  #     [25] "［税区分］",
  #     [26] "［合計 商品本体］",
  #     [27] "［合計 商品消費税］",
  #     [28] "［合計 送料本体］",
  #     [29] "［合計 送料消費税］",
  #     [30] "［合計 その他］",
  #     [31] "［総合計］",
  #     [32] "［発注日］",
  #     [33] "［発送日］",
  #     [34] "［納品日］",
  #     [35] "［受領日］",
  #     [36] "［取引ID_SYSTEM］",
  #     [37] "［伝票明細ID_SYSTEM］",
  #     [38] "［発注送信日］",
  #     [39] "［発注送信時間］",
  #     [40] "［送信日］",
  #     [41] "［送信時間］"
  # ]

  def initialize(date = Time.zone.today)
    @date = date
  end

  attr_reader :date

  def parse_csv_date(date_str)
    date_str.empty? ? nil : Date.strptime(date_str, '%Y/%m/%d')
  end

  def assign_order_attribues(order, row)
    order.csv_data[row[37]] = row.map(&:to_s)
    new_ship_date = parse_csv_date(row[33])
    # if it's a new ship date,
    #   or the ship date is the same for the item as the order,
    #     or the new ship date is today or after, prioritize and process
    unless order.ship_date.nil? ||
           order.ship_date == new_ship_date ||
           (!new_ship_date.nil? && new_ship_date >= Time.zone.today)
      return
    end

    # If the new ship date is greater than today
    #  and the ship date isn't nil, meaning this is a new order being created
    #   and the ship date dosen't equal the new ship date
    #    this means we are overwriting an old one and need to fix the items ist at the end of the commit.
    overwriting = !order.ship_date.nil? && (order.ship_date != new_ship_date)
    items_hash = order.items
    items_hash[row[37]] = {
      item_id: row[12],
      item_code: row[13],
      status: row[3],
      name: row[14],
      order_date: parse_csv_date(row[32]),
      ship_date: new_ship_date,
      settlement_date: parse_csv_date(row[34]),
      completion_date: parse_csv_date(row[35]),
      standard: row[15],
      in_box_quantity: row[16],
      in_box_counter: row[17],
      price: row[18],
      quantity: row[19],
      counter: row[20],
      item_subtotal: row[21],
      tax: row[22],
      subtotal: row[23],
      tax_rate: row[24],
      tax_category: row[25],
      all_item_total: row[26],
      all_item_tax: row[27],
      all_item_shipping: row[28],
      all_item_shipping_tax: row[29],
      other_total: row[30],
      order_total: row[31],
      transaction_id: row[36]
    }
    order.assign_attributes({
                              order_time: DateTime.parse("#{row[40]} #{row[41]} +0900"),
                              status: row[3],
                              destination: row[8],
                              ship_date: parse_csv_date(row[33]),
                              arrival_date: parse_csv_date(row[34]),
                              items: items_hash,
                              address: row[11]
                            })
    order.save
    order.fix_item_dates if overwriting
  end

  def process_csv(csv, existing_updated, newly_created)
    CSV.foreach(csv, encoding: 'Shift_JIS:UTF-8').with_index do |row, i|
      @csv_date = row[1] if i.zero?
      if (i >= 1) && (row[0] == 'D')
        order = InfomartOrder.find_by(order_id: row[2])
        if order
          existing_updated << order
        else
          order = InfomartOrder.new(
            order_id: row[2],
            items: {},
            csv_data: {}
          )
          newly_created << order
        end
        assign_order_attribues(order, row)
      end
    end
  end

  # def acquire_new_data(acquisition_method = :mechanize, _data = nil)
  #   if acquisition_method == :mechanize
  #     begin
  #       puts 'Attemping to download CSV data via Mechanize.'
  #       agent = Mechanize.new
  #       page = agent.get('https://www.infomart.co.jp/scripts/logon.asp?CS=1&URL=https%3A%2F%2Fwww2%2Einfomart%2Eco%2Ejp%2Ftrade%2Fdownload%2Fbat%5Fdetail%2Epagex')
  #       login_form = page.form
  #       # login first screen
  #       login_form.UID = ENV['INFOMART_LOGIN']
  #       login_form.PWD = ENV['INFOMART_PASS']
  #       page = agent.submit(login_form)
  #       # login second screen
  #       login_form = page.form('form01')
  #       login_form.UID = ENV['INFOMART_LOGIN']
  #       login_form.PWD = ENV['INFOMART_PASS']
  #       page = agent.submit(login_form)
  #       puts 'Login successful, downloading the latest CSV order data.'
  #       puts page.links_with(dom_class: 'ic ic-blu-dl')
  #       csv_id = page.links_with(dom_class: 'ic ic-blu-dl').first.href[/D\d*\.asp/]
  #       puts "CSV ID is #{csv_id}"
  #       csv_call_url = "https://ec.infomart.co.jp/trade/download/download_inside_caller.aspx?file_id= &call_file=#{csv_id}"
  #       puts "CSV call URL is #{csv_call_url}"
  #       csv = agent.get(csv_call_url)
  #       filename = csv.filename
  #       puts "Saving #{filename} for processing"
  #       csv.save
  #       existing_updated = Set.new
  #       newly_created = Set.new
  #       puts 'Processing data...'
  #       process_csv(filename, existing_updated, newly_created)
  #       puts "#{newly_created.length + existing_updated.length} Infomart order changes were made, #{newly_created.length} newly created and #{existing_updated.length} existing orders found and, if necessary, updated."
  #       File.delete(filename) if File.exist?(filename)
  #     rescue StandardError
  #       puts "Scheduled task appears to have triggered an error, please
  #         check Infomart's scheduled task area for more information."
  #       ap page if page
  #     end
  #   else
  #     puts 'Alternate acquisation methods are not yet supported, please use Mechanize'
  #   end
  # end

  # def scrape(time = 3.years, set_end_date = Time.zone.today) # Date.new(2020,4,29)
  #   # Maximum data retention is 3 years, so default to maximum
  #   if time <= 2.days
  #     ranges = [[(set_end_date - time), Time.zone.today]]
  #   else
  #     time = 3.years if time > 3.years
  #     ranges = []
  #     end_date = set_end_date
  #     while time >= 1.day
  #       ranges << [(end_date - 2.days), end_date]
  #       end_date -= 2.days
  #       time -= 2.days
  #     end
  #   end
  #   p "Scraping from #{Time.zone.today - time} to #{Time.zone.today}"
  #   p 'Logging in first...'
  #   agent = Mechanize.new
  #   ranges.each do |date_array|
  #     start_date = date_array[0].strftime('%Y/%m/%d')
  #     end_date = date_array[1].strftime('%Y/%m/%d')
  #     p "Working on #{start_date} to #{end_date}"
  #     # HTradeState is the status from which you want to view, '80' is 受領, '88' is 返品 (remove for all)
  #     begin
  #       agent.reset
  #       page = agent.get("https://www2.infomart.co.jp/employment/shipping_list_window.page?5&op=00&parent=0&selbuy=0&membersel=0&perusal=0&Infl=TC&pdate=2&TCalTradeState=0&TCalTradeState_2=0&TCalTradeState_4=0&TCalTradeState_5=0&TCalTradeState_6=0&f_date=#{start_date}&t_date=#{end_date}&LeaveCond=1")
  #       unless page.form('fsnform').nil?
  #         login_form = page.form
  #         # login first screen
  #         login_form.UID = ENV['INFOMART_LOGIN']
  #         login_form.PWD = ENV['INFOMART_PASS']
  #         page = agent.submit(login_form)
  #         # login second screen
  #         login_form = page.form('form01')
  #         login_form.UID = ENV['INFOMART_LOGIN']
  #         login_form.PWD = ENV['INFOMART_PASS']
  #         page = agent.submit(login_form)
  #         puts 'Login successful, proceeding with search.'
  #       end
  #       # 100 results at a time starts here:
  #       ids = []
  #       page.css('.data-list02-tbl').css('tbody.slip-summary-a').each do |row|
  #         ids << row.css('td.data-cm a').first.to_s[/(?<=tid=).*(?=',)/]
  #       end
  #       unless ids.empty?
  #         csv_call_url = "https://ec.infomart.co.jp/trade/download_set_exdload_f.aspx?encode=UTF-8&exe_mode=OFF&transFlg=1&f_date=#{start_date}&t_date=#{end_date}&tid=#{ids.join(',')}&target_d=5&membersel=0&dl_set=SV3QFToW,1&smail_op=&fnm_flg=0&IMReferer=/employment/trade_download_select.page"
  #         csv = agent.get(csv_call_url)
  #         if csv
  #           filename = csv.filename
  #           puts "Saving #{filename} for processing"
  #           csv.save
  #           existing_updated = Set.new
  #           newly_created = Set.new
  #           puts 'Processing data...'
  #           process_csv(filename, existing_updated, newly_created)
  #           puts "#{newly_created.length + existing_updated.length} Infomart order changes were made for orders between #{start_date} and #{end_date}, #{newly_created.length} newly created and #{existing_updated.length} existing orders found and, if necessary, updated."
  #           File.delete(filename) if File.exist?(filename)
  #         end
  #       end
  #     rescue StandardError => e
  #       ap e.backtrace
  #     end
  #   end
  # end
end
