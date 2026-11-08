# frozen_string_literal: true

if ENV['SIMPLECOV']
  require 'simplecov'

  SimpleCov.start 'rails' do
    add_group 'Components', 'app/components'
    add_group 'Services', 'app/services'
    add_filter 'lib/generators'
  end
end

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

# The app always acts as User.local; tests pick which fixture user that is.
module LocalUserOverride
  mattr_accessor :user

  def local
    LocalUserOverride.user || super
  end
end
User.singleton_class.prepend(LocalUserOverride)

# Lets a system test cut the browser off from home entirely: while it is on, every request,
# including those from the service worker, has its connection dropped without a reply.
class HomeOutOfReach
  mattr_accessor :on, default: false

  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless on && env['rack.hijack']

    env['rack.hijack'].call
    env['rack.hijack_io'].close
    [200, {}, []]
  end
end

# Loading system tests sets the app the test server runs; wrap it afterwards.
require 'action_dispatch/system_test_case'
Capybara.app = HomeOutOfReach.new(Capybara.app)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    if ENV['SIMPLECOV']
      parallelize_setup do |worker|
        SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"
      end

      parallelize_teardown do
        SimpleCov.result
      end
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    teardown { LocalUserOverride.user = nil }

    def act_as(user)
      LocalUserOverride.user = user
    end

    Shoulda::Matchers.configure do |config|
      config.integrate do |with|
        with.test_framework :minitest
        with.library :rails
      end
    end

    def pause
      $stderr.write 'Press enter to continue'
      $stdin.gets
    end
  end
end
