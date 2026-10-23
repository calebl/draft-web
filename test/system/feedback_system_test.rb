require 'test_helper'

class FeedbackSystemTest < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome

  setup do
    act_as users(:bob)
    @dir = Dir.mktmpdir
    script = File.join(@dir, 'fake-command')
    File.write(script, "#!/bin/sh\ncat > \"$(dirname \"$0\")/stdin\"\n")
    File.chmod(0o755, script)
    @previous = ENV.fetch('DRAFT_FEEDBACK_COMMAND', nil)
    ENV['DRAFT_FEEDBACK_COMMAND'] = script
  end

  teardown do
    ENV['DRAFT_FEEDBACK_COMMAND'] = @previous
    FileUtils.remove_entry(@dir)
  end

  test 'Sending feedback from the header' do
    visit story_path(stories(:one))
    assert_no_selector 'dialog.feedback-dialog[open]'

    find('button[aria-label="Send feedback"]').click
    within 'dialog.feedback-dialog[open]' do
      fill_in 'feedback_text', with: 'Word counts could use a weekly view'
      click_on 'Send'
    end

    assert_selector '.flash', text: 'Sent'
    assert_no_selector 'dialog.feedback-dialog[open]'
    assert_equal "Draft feedback (screen: stories#show)\n\nWord counts could use a weekly view\n",
                 File.read(File.join(@dir, 'stdin'))
  end
end
