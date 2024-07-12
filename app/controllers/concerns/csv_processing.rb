module CsvProcessing
  extend ActiveSupport::Concern

  def process_csv_file(document, option)
    if document.present?
      process_by_option(document, option)
      flash[:notice] = "CSV処理は成功しました。"
    else
      csv_error
    end
  end

  private

  def process_by_option(document, option)
    case option
    when 'ふるさと納税の支払い明細を取り込む'
      intake_furusato_sales_data(document)
    else
      csv_error
    end
  end

  def intake_furusato_sales_data(document)
    csv = read_csv_with_encoding(document.tempfile, 'Shift_JIS')
    csv.each do |row|
      save_furusato_sales_data(row)
    end
  end

  def save_furusato_sales_data(row)
    FurusatoOrder.find_or_create_by(furusato_id: row['配送NO']) do |order|
      order.ssys_id = row['配送ID']
      order.shipped_date = Date.parse(row['出荷日'])
      order.product_code = row['TRV商品コード']
      order.product_name = row['TRV商品名']
    end
  end

  def brute_open_csv(file_path)
    encodings = ['UTF-8', 'ISO-8859-1', 'Shift_JIS', 'EUC-JP', 'Windows-1252', 'ASCII-8BIT']
    csv = nil
    encodings.each do |encoding|
      csv = read_csv_with_encoding(file_path, encoding)
      break if csv
    end

    csv.nil? ? csv_error : csv
  end

  def read_csv_with_encoding(file_path, encoding)
    content = File.read(file_path, encoding: encoding)
    lines = content.lines
    headers = lines[2]
    body = lines[3..-1].join
    CSV.parse(body, headers: true)
  rescue StandardError
    csv_error
  end

  def csv_error
    flash[:alert] = "CSV処理は失敗しました。"
  end
end
