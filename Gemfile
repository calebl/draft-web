source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.8'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 8.0.0'
# Use Puma as the app server
gem 'puma', '~> 6.4'
# Use SCSS for stylesheets
gem 'sassc-rails'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker

gem 'acts_as_list'
gem 'blazer'
gem 'cancancan', '~> 3.2'
gem 'devise', '~> 4.9'
gem 'importmap-rails', '~> 1.2'
gem 'jbuilder', '~> 2.11'
gem 'mail', '~> 2.7'
gem 'mailerlite'
gem 'redis', '~> 5.0'
gem 'solid_queue', '~> 1.1'
gem 'sprockets-rails'
gem 'stimulus-rails', '~> 1.3'
gem 'turbo-rails', '~> 1.5'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.16.0', require: false
gem 'net-imap', require: false
gem 'net-pop', require: false
gem 'net-smtp', require: false

group :development, :test do
  # Use sqlite3 as the database for Active Record
  gem 'sqlite3'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'htmlbeautifier'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'dockerfile-rails', '>= 1.7'
  gem 'foreman'
  gem 'guard'
  gem 'guard-livereload', '~> 2.5', require: false
  gem 'guard-minitest'
  gem 'listen', '~> 3.8'
  gem 'rubocop'
  gem 'rubocop-rails', require: false
  gem 'solargraph'
  gem 'web-console', '>= 4.2.0'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 3.39'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'rails-controller-testing'
  gem 'shoulda', '~> 4.0'
  gem 'simplecov', require: false
end

group :production do
  # gem 'pg', '~> 1.5'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
