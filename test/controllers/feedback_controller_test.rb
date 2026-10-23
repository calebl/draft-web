require 'test_helper'

class FeedbackControllerTest < ActionDispatch::IntegrationTest
  REQUEST_ID = '0b6f1c1e-6a51-4d6a-9d3e-3f3a0c2e9b11'.freeze

  setup do
    act_as users(:bob)
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

  def send_feedback(text: 'The outline button is hard to find', screen: 'stories#show', request_id: REQUEST_ID)
    post feedback_path, params: { text: text, screen: screen, request_id: request_id }, as: :turbo_stream
  end

  def recorded(name)
    path = File.join(@dir, name)
    File.read(path) if File.exist?(path)
  end

  test 'runs the command with the request id and the message on stdin' do
    send_feedback

    assert_response :success
    assert_includes response.body, 'Sent'
    assert_equal "send\n--request-id\ndraft-feedback-#{REQUEST_ID}\n--json\n-\n", recorded('args')
    assert_equal "Draft feedback (screen: stories#show)\n\nThe outline button is hard to find\n", recorded('stdin')
  end

  test 'treats exit code 3 as sent' do
    ENV['FAKE_EXIT'] = '3'
    send_feedback

    assert_response :success
    assert_includes response.body, 'Sent'
  end

  test 'reports a failing command' do
    ENV['FAKE_EXIT'] = '1'
    send_feedback

    assert_response :unprocessable_entity
    assert_includes response.body, 'Couldn&#39;t send'
  end

  test 'reports a missing command' do
    ENV['DRAFT_FEEDBACK_COMMAND'] = File.join(@dir, 'missing')
    send_feedback

    assert_response :unprocessable_entity
  end

  test 'is not found when no command is configured' do
    ENV.delete('DRAFT_FEEDBACK_COMMAND')
    send_feedback

    assert_response :not_found
    assert_nil recorded('stdin')
  end

  test 'rejects text over the length cap' do
    send_feedback(text: 'a' * (FeedbackController::MAX_LENGTH + 1))

    assert_response :unprocessable_entity
    assert_nil recorded('stdin')
  end

  test 'rejects an unknown screen' do
    send_feedback(screen: 'stories#secret')

    assert_response :unprocessable_entity
    assert_nil recorded('stdin')
  end

  test 'rejects a malformed request id' do
    send_feedback(request_id: 'not-a-uuid')

    assert_response :unprocessable_entity
    assert_nil recorded('stdin')
  end

  test 'shows the feedback button only when configured' do
    get root_path
    assert_select 'dialog.feedback-dialog'

    ENV.delete('DRAFT_FEEDBACK_COMMAND')
    get root_path
    assert_select 'dialog.feedback-dialog', count: 0
  end
end
