class CarrierStringInvoiceIO < StringIO
  def original_filename
    "仕切り.pdf"
  end

  def content_type
    "application/pdf"
  end
end

class OysterInvoiceUploader < CarrierWave::Uploader::Base
  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  # include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage :gcloud
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url(*args)
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process scale: [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process resize_to_fit: [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # def extension_whitelist
  #   %w(jpg jpeg gif png)
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    mounted_as.to_s.include?('aioi') ? (locale = '相生') : (locale = '坂越')
    mounted_as.to_s.include?('all') ? (export_format = '生産者まとめ') : (export_format = '各生産者')
    start_date = Date.parse(model.start_date).strftime('%Y年%m月%d日')
    end_date = (Date.parse(model.end_date) - 1.day).strftime('%Y年%m月%d日')
    "#{locale} (#{start_date} ~ #{end_date}) - #{export_format}.pdf"
  end
end
 
