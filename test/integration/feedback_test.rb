require 'test_helper'

# The pocket-kit feedback button as Draft configures it in config/initializers/pocket_kit.rb.
class FeedbackTest < ActionDispatch::IntegrationTest
  REQUEST_ID = '0b6f1c1e-6a51-4d6a-9d3e-3f3a0c2e9b11'.freeze

  setup do
    act_as users(:bob)
    PocketKit::FeedbackController::RATE_STORE.clear
    @dir = Dir.mktmpdir
    @script = File.join(@dir, 'fake-command')
    File.write(@script, <<~SH)
      #!/bin/sh
      printf '%s\\n' "$@" > "$(dirname "$0")/args"
      cat > "$(dirname "$0")/stdin"
      exit "${FAKE_EXIT:-0}"
    SH
    File.chmod(0o755, @script)
    @previous = ENV.fetch('DRAFT_FEEDBACK_COMMAND', nil)
    ENV['DRAFT_FEEDBACK_COMMAND'] = "#{@script} send"
  end

  teardown do
    ENV['DRAFT_FEEDBACK_COMMAND'] = @previous
    ENV.delete('FAKE_EXIT')
    FileUtils.remove_entry(@dir)
  end

  def send_feedback
    post '/feedback', params: { text: 'The outline button is hard to find', screen: 'stories#show', request_id: REQUEST_ID }, as: :turbo_stream
  end

  def recorded(name)
    path = File.join(@dir, name)
    File.read(path) if File.exist?(path)
  end

  test 'shows the button in the header with Draft wording' do
    get stories_path

    assert_select '.header .pk-feedback textarea[placeholder=?]', 'What would make Draft better?'
  end

  test 'hides the button and the endpoint when the command is unset' do
    ENV.delete('DRAFT_FEEDBACK_COMMAND')

    get stories_path
    assert_select '.pk-feedback', count: 0

    send_feedback
    assert_response :not_found
  end

  test 'runs DRAFT_FEEDBACK_COMMAND with the draft-feedback request id and the Draft heading' do
    send_feedback

    assert_response :success
    assert_includes response.body, 'Sent'
    assert_equal "send\n--request-id\ndraft-feedback-#{REQUEST_ID}\n--json\n-\n", recorded('args')
    assert_equal "Draft feedback (screen: stories#show)\n\nThe outline button is hard to find\n", recorded('stdin')
  end

  test 'counts exit 3 as sent' do
    ENV['FAKE_EXIT'] = '3'
    send_feedback

    assert_response :success
    assert_includes response.body, 'Sent'
  end

  test 'reports other exit statuses as not sent' do
    ENV['FAKE_EXIT'] = '1'
    send_feedback

    assert_response :unprocessable_content
  end
end
