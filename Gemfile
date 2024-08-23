source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.1'

# Update Rails to 7.2
gem 'rails', '~> 7.2.0'
# Use Puma as the app server
gem 'puma', '~> 6.4'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker

gem 'acts_as_list'
gem 'blazer'
gem "bigdecimal", "~> 3.1"
gem 'cancancan', '~> 3.2'
gem 'devise', '~> 4.7'
gem 'jbuilder', '~> 2.11'
gem 'mail', '~> 2.7'
gem 'mailerlite'
gem 'rails_admin', '~> 3.0'
gem 'redis', '~> 4.7'
gem 'sqlite3', '~> 2.0', '>= 2.0.4'

gem 'delayed_job', '~>4.1'
gem 'delayed_job_active_record', '~>4.1'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.12.0', require: false
gem 'net-imap', require: false
gem 'net-pop', require: false
gem 'net-smtp', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'htmlbeautifier'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'foreman'
  gem 'guard'
  gem 'guard-livereload', '~> 2.5', require: false
  gem 'guard-minitest'
  gem 'listen', '~> 3.2'
  gem 'rubocop'
  gem 'solargraph'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 3.3'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'rails-controller-testing'
  gem 'shoulda', '~> 4.0'
  gem 'simplecov', require: false
end

group :production do
  gem 'pg', '~> 1.5'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
