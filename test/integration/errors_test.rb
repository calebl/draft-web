require 'test_helper'

# pocket-kit error monitoring as Draft configures it in config/initializers/pocket_kit.rb.
class ErrorsTest < ActionDispatch::IntegrationTest
  setup do
    act_as users(:bob)
    PocketKit::Errors.reset!
    @dir = Dir.mktmpdir
    @script = File.join(@dir, 'fake-command')
    File.write(@script, <<~SH)
      #!/bin/sh
      printf '%s\\n' "$@" > "$(dirname "$0")/args"
      cat > "$(dirname "$0")/stdin"
    SH
    File.chmod(0o755, @script)
    @previous = ENV.fetch('DRAFT_ERRORS_COMMAND', nil)
    ENV['DRAFT_ERRORS_COMMAND'] = "#{@script} errors"
  end

  teardown do
    PocketKit::Errors.flush
    ENV['DRAFT_ERRORS_COMMAND'] = @previous
    FileUtils.remove_entry(@dir)
  end

  def recorded(name)
    path = File.join(@dir, name)
    File.read(path) if File.exist?(path)
  end

  # Renders the 500 page the way production does, instead of raising into the test.
  def request_broken_stories
    StoriesController.alias_method :original_index, :index
    StoriesController.define_method(:index) { raise 'stories exploded' }
    env_config = Rails.application.env_config
    previous = env_config.slice('action_dispatch.show_exceptions', 'action_dispatch.show_detailed_exceptions')
    env_config.merge!('action_dispatch.show_exceptions' => :all, 'action_dispatch.show_detailed_exceptions' => false)
    get stories_path
  ensure
    env_config.merge!(previous)
    StoriesController.alias_method :index, :original_index
    StoriesController.remove_method :original_index
    PocketKit::Errors.flush
  end

  test 'includes the errors tag in the page head' do
    get stories_path

    assert_select 'head meta[name="pocket-kit-errors"]'
    assert_select 'head meta[name="pocket-kit-screen"][content=?]', 'stories#index'
  end

  test 'runs DRAFT_ERRORS_COMMAND for an unhandled request exception' do
    request_broken_stories

    assert_response :internal_server_error
    assert_match(/\Aerrors\n--request-id\ndraft-errors-\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\n--json\n-\n\z/, recorded('args'))
    report = JSON.parse(recorded('stdin'))
    assert_equal 'request', report['source']
    assert_equal 'stories exploded', report.dig('error', 'message')
    assert report['text'].start_with?('Draft error (source: request)'), report['text']
  end

  test 'reports nothing when the command is unset' do
    ENV.delete('DRAFT_ERRORS_COMMAND')

    request_broken_stories

    assert_response :internal_server_error
    assert_nil recorded('args')
    assert_select 'head meta[name="pocket-kit-errors"]', count: 0
  end
end
