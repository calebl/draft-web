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
      @device = page.evaluate_script(<<~JS)
        ({
          userAgent: navigator.userAgent,
          width: window.innerWidth,
          height: window.innerHeight,
          visibleWidth: window.visualViewport ? Math.round(window.visualViewport.width) : null,
          visibleHeight: window.visualViewport ? Math.round(window.visualViewport.height) : null,
          pixelRatio: window.devicePixelRatio,
          standalone: window.matchMedia("(display-mode: standalone)").matches || navigator.standalone === true
        })
      JS
      click_on 'Send'
    end

    assert_selector '.flash', text: 'Sent'
    assert_no_selector 'dialog.feedback-dialog[open]'
    viewport = "#{@device['width']}x#{@device['height']}"
    visible = "#{@device['visibleWidth']}x#{@device['visibleHeight']}"
    viewport += " (visible #{visible})" if visible != viewport
    viewport += " @#{@device['pixelRatio']}x, standalone: #{@device['standalone'] ? 'yes' : 'no'}"
    assert_equal "Draft feedback (screen: stories#show)\nDevice: #{@device['userAgent']}\n" \
                 "Viewport: #{viewport}\n\nWord counts could use a weekly view\n",
                 File.read(File.join(@dir, 'stdin'))
  end
end
