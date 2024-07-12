class ApplicationMailer < ActionMailer::Base
  require 'sendgrid-ruby'
  include SendGrid

  default from: ENV['MAIL_SENDER']
  layout 'mailer'

  def to_nengapi(date)
    date&.strftime('%Y年%m月%d日')
  end
end
