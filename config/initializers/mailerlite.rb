MailerLite.configure do |config|
  config.api_key = Rails.application.credentials.dig(:mailerlite,:api_key) if Rails.env.production?
  # config.timeout = 10
end
