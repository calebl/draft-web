require 'test_helper'

class OfflineWriteSystemTest < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome

  setup do
    act_as users(:bob)
  end

  teardown do
    go_online
  end

  test 'Draft opens a writing page while home is out of reach' do
    visit root_path
    wait_for_offline_page_stored

    go_offline
    visit story_path(stories(:one))

    assert_text "Draft can't reach home."
    within('.stories-list') do
      assert_text 'Story title'
      assert_text 'Second story'
      assert_no_text "Jane's Opus"
    end
  end

  test 'A session started while away is created once and keeps every paragraph on reconnect' do
    story = stories(:one)
    visit root_path
    wait_for_offline_page_stored

    go_offline
    visit story_path(story)
    within('.story', text: 'Story title') { click_on 'Write' }

    composer = find('#composer')
    assert_equal true, evaluate_script('document.activeElement.id === "composer"')
    composer.send_keys('Written on the train', :enter)
    composer.send_keys('Then the tunnel', :enter)
    assert_selector '.text .unsaved', count: 2
    assert_selector '.unsaved-note', text: 'Not saved yet. Will send when Draft can reach home.'
    assert_selector '.word-count', text: '7'

    # Leaving the session keeps it waiting on the picker.
    click_on 'Done'
    within('.story', text: '2 paragraphs not saved yet') { click_on 'Keep writing' }
    assert_selector '.text .unsaved', count: 2

    assert_difference -> { story.writing_sessions.count }, 1 do
      go_online
      execute_script('window.dispatchEvent(new Event("online"))')
      assert_current_path(%r{/stories/#{story.id}/writing_sessions/\d+/edit})
      within('.text-container') { assert_text 'Then the tunnel' }
      assert_no_selector '.unsaved'
    end

    session = story.writing_sessions.order(:id).last
    assert_equal '<div>Written on the train</div><div>Then the tunnel</div>', session.text
    assert_equal 7, session.word_count
    assert_equal 2, SavedParagraph.where(writing_session: session).count

    # Sending again changes nothing.
    execute_script('window.dispatchEvent(new Event("online"))')
    assert_no_difference -> { WritingSession.count } do
      visit root_path
    end
    assert_equal '<div>Written on the train</div><div>Then the tunnel</div>', session.reload.text
  end

  test 'Reconnect keeps memory queued paragraphs and text still being typed' do
    story = stories(:one)
    visit root_path
    wait_for_offline_page_stored

    go_offline
    visit story_path(story)
    within('.story', text: 'Story title') { click_on 'Write' }

    execute_script <<~JS
      window.originalSetItem = Storage.prototype.setItem;
      Storage.prototype.setItem = function() { throw new DOMException("Storage unavailable"); };
    JS

    composer = find('#composer')
    composer.send_keys('Held only in memory', :enter)
    composer.send_keys('Also held in memory', :enter)
    composer.send_keys('Still being typed')

    execute_script <<~JS
      window.originalFetch = window.fetch;
      window.fetch = function(url, options) {
        document.body.dataset.offlinePostStarted = "true";
        return new Promise(function(resolve) {
          window.releaseOfflinePost = function() {
            window.fetch = window.originalFetch;
            resolve(window.originalFetch(url, options));
          };
        });
      };
    JS

    go_online
    execute_script('window.dispatchEvent(new Event("online"))')
    assert_selector 'body[data-offline-post-started=true]', visible: :all
    assert_equal 'Still being typed', composer.value
    assert_equal true, evaluate_script('document.activeElement.id === "composer"')

    assert_difference -> { story.writing_sessions.count }, 1 do
      execute_script('window.releaseOfflinePost()')
      assert_no_selector '.text .unsaved'
    end

    assert_equal 'Still being typed', composer.value
    assert_equal true, evaluate_script('document.activeElement.id === "composer"')
    within('.text-container') do
      assert_text 'Held only in memory'
      assert_text 'Also held in memory'
    end

    execute_script('Storage.prototype.setItem = window.originalSetItem')
    composer.send_keys(:enter)
    assert_current_path(%r{/stories/#{story.id}/writing_sessions/\d+/edit})

    session = story.writing_sessions.order(:id).last
    assert_equal '<div>Held only in memory</div><div>Also held in memory</div><div>Still being typed</div>', session.text
    assert_equal 3, SavedParagraph.where(writing_session: session).count
  end

  test 'Words written for a story deleted while away stay on the phone' do
    story = stories(:two)
    visit root_path
    wait_for_offline_page_stored

    go_offline
    visit root_path
    within('.story', text: 'Second story') { click_on 'Write' }
    find('#composer').send_keys('Nowhere to go', :enter)
    assert_selector '.text .unsaved', text: 'Nowhere to go'
    story.destroy

    go_online
    execute_script('window.dispatchEvent(new Event("online"))')
    assert_selector '.text .unsaved', text: 'Nowhere to go'
    stored = evaluate_script(<<~JS)
      Object.keys(localStorage).filter((key) => key.startsWith('draft.unsaved.offline-')).map((key) => localStorage.getItem(key)).join()
    JS
    assert_includes stored, 'Nowhere to go'
  end

  test 'Pages and the offline writing page load nothing from outside sites' do
    visit root_path
    wait_for_offline_page_stored
    visit edit_story_writing_session_path(stories(:one), writing_sessions(:one))
    assert_selector '#composer'
    assert_empty outside_requests

    go_offline
    visit root_path
    assert_text "Draft can't reach home."
    assert_empty outside_requests
  end

  private

  def wait_for_offline_page_stored
    assert_equal true, evaluate_async_script(<<~JS)
      const done = arguments[0];
      const check = () => caches.match('/offline-write').then((page) => page ? done(true) : setTimeout(check, 100));
      navigator.serviceWorker.ready.then(check);
    JS
  end

  def outside_requests
    evaluate_script(<<~JS)
      performance.getEntriesByType('resource').map((entry) => entry.name)
        .filter((url) => new URL(url).origin !== location.origin)
    JS
  end

  # Chrome's offline mode does not reach the service worker, so home also drops every
  # connection, as it does when the phone cannot reach it.
  def go_offline
    HomeOutOfReach.on = true
    page.driver.browser.network_conditions = { offline: true, latency: 0, throughput: -1 }
  end

  def go_online
    HomeOutOfReach.on = false
    page.driver.browser.network_conditions = { offline: false, latency: 0, throughput: -1 }
  end
end
