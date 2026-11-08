require 'test_helper'

class UnsavedParagraphsSystemTest < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome

  setup do
    act_as users(:bob)
  end

  teardown do
    go_online
  end

  test 'A paragraph written while home is out of reach waits on the phone and is saved once on reconnect' do
    session = writing_sessions(:one)
    session.update!(text: '<div>An opening line.</div>', word_count: 3)
    visit edit_story_writing_session_path(stories(:one), session)
    assert_text 'An opening line.'

    go_offline
    find('#composer').send_keys('Written on the train', :enter)

    assert_selector '.text .unsaved', text: 'Written on the train'
    assert_selector '.unsaved-note', text: 'Not saved yet. Will send when Draft can reach home.'
    assert_equal '', find('#composer').value
    assert_selector '.word-count', text: '7'
    assert_equal '<div>An opening line.</div>', session.reload.text

    # It is kept on the phone, so closing Draft does not lose it.
    stored = evaluate_script("localStorage.getItem('draft.unsaved.#{session.id}')")
    assert_includes stored, 'Written on the train'

    go_online
    assert_no_selector '.unsaved'
    assert_no_selector '.unsaved-note'
    within('.text-container') { assert_text 'Written on the train' }
    assert_equal '<div>An opening line.</div><div>Written on the train</div>', session.reload.text
    assert_equal 1, SavedParagraph.where(writing_session: session).count
  end

  test 'A storage failure keeps the paragraph visible and sends it once with an id' do
    session = writing_sessions(:one)
    visit edit_story_writing_session_path(stories(:one), session)

    execute_script <<~JS
      window.originalSetItem = Storage.prototype.setItem;
      Storage.prototype.setItem = function() { throw new DOMException("Storage unavailable"); };
      window.originalFetch = window.fetch;
      window.paragraphRequests = [];
      window.fetch = function(url, options) {
        window.paragraphRequests.push({url: String(url), options: options});
        return new Promise(function(resolve) {
          window.releaseParagraphRequest = function() {
            window.fetch = window.originalFetch;
            resolve(window.originalFetch(url, options));
          };
        });
      };
    JS

    find('#composer').send_keys('Held in memory', :enter)

    assert_selector '.text .unsaved', text: 'Held in memory'
    assert_selector '.unsaved-note', text: 'Not saved yet. Will send when Draft can reach home.'
    assert_equal 1, evaluate_script('window.paragraphRequests.length')
    request_body = JSON.parse(evaluate_script('window.paragraphRequests[0].options.body'))
    assert_equal 'Held in memory', request_body.dig('writing_session', 'text')
    assert_predicate request_body['paragraph_id'], :present?

    execute_script <<~JS
      Storage.prototype.setItem = window.originalSetItem;
      window.releaseParagraphRequest();
    JS

    assert_no_selector '.unsaved'
    assert_equal '<div>Held in memory</div>', session.reload.text
    assert_equal 1, SavedParagraph.where(writing_session: session, paragraph_id: request_body['paragraph_id']).count
  end

  test 'Paragraphs queued for a session deleted elsewhere land in a new session in the same story' do
    story = stories(:one)
    session = writing_sessions(:one)
    visit edit_story_writing_session_path(story, session)

    go_offline
    find('#composer').send_keys('Kept after the delete', :enter)
    assert_selector '.text .unsaved', text: 'Kept after the delete'
    session.destroy

    assert_difference('story.writing_sessions.count', 1) do
      go_online
      execute_script('window.dispatchEvent(new Event("online"))')
      assert_no_selector '.unsaved'
      within('.text-container') { assert_text 'Kept after the delete' }
    end
    assert_equal '<div>Kept after the delete</div>', story.writing_sessions.last.text
  end

  private

  def go_offline
    page.driver.browser.network_conditions = { offline: true, latency: 0, throughput: -1 }
  end

  def go_online
    page.driver.browser.network_conditions = { offline: false, latency: 0, throughput: -1 }
  end
end
