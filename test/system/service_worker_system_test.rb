require 'test_helper'

class ServiceWorkerSystemTest < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome

  setup do
    act_as users(:bob)
  end

  test 'A second New Session on a story starts a new session that gets the text' do
    story = stories(:one)
    visit story_path(story)
    # The test server is on localhost, a secure context, so the service worker runs
    # here as it does on the phone. Wait until it controls the page.
    assert_equal true, evaluate_async_script(<<~JS)
      const done = arguments[0];
      navigator.serviceWorker.ready.then(() => {
        if (navigator.serviceWorker.controller) return done(true);
        navigator.serviceWorker.addEventListener('controllerchange', () => done(true), { once: true });
      });
    JS

    click_on 'New Session'
    fill_in 'composer', with: 'First new session'
    send_keys :enter
    within('.text-container') { assert_text 'First new session' }
    first_path = current_path
    click_on 'Done'
    assert_current_path story_path(story)

    assert_difference -> { story.writing_sessions.count }, 1 do
      click_on 'New Session'
      assert_no_current_path first_path
      assert_selector '#composer'
    end
    fill_in 'composer', with: 'Second new session'
    send_keys :enter
    within('.text-container') { assert_text 'Second new session' }
    assert_no_text 'First new session'

    newest = story.writing_sessions.order(:id).last
    assert_includes newest.reload.text, 'Second new session'
    assert_not_includes story.writing_sessions.find(first_path[%r{/writing_sessions/(\d+)}, 1]).text.to_s, 'Second new session'
  end
end
