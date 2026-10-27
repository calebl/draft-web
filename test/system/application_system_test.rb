require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome

  setup do
    act_as users(:bob)
  end

  test 'Create a story and write' do
    visit stories_path
    click_on 'Add a New Story'
    fill_in 'story[title]', with: 'New story title'
    click_on 'Create Story'
    assert_text 'New story title'
    click_on 'New Session'
    fill_in 'composer', with: 'Here is some text'
    send_keys :enter
    within '.text-container' do
      assert_text 'Here is some text'
    end
    within '.word-count' do
      assert_text '4'
    end
    fill_in 'composer', with: 'Here is some more text'
    send_keys :enter
    within '.text-container' do
      assert_text 'Here is some more text'
    end
  end

  test 'Done returns to a story page that lists the session just written' do
    visit story_path(stories(:one))
    assert_text 'Writing Sessions: 1'
    # Keep a copy of the story page from before the session existed.
    execute_script('window.storyBeforeSession = document.documentElement.outerHTML')
    click_on 'New Session'
    fill_in 'composer', with: 'A brand new session'
    send_keys :enter
    within '.text-container' do
      assert_text 'A brand new session'
    end

    # Turbo can still be holding that earlier copy, as it was on the phone: Done must
    # not show it in place of the current story page.
    execute_script(<<~JS, story_path(stories(:one)))
      Turbo.session.view.snapshotCache.put(new URL(arguments[0], location.origin), Turbo.PageSnapshot.fromHTMLString(window.storyBeforeSession));
    JS
    click_on 'Done'

    assert_current_path story_path(stories(:one))
    assert_text 'Writing Sessions: 2'
    assert_selector '.session', text: 'A brand new session'
  end

  test 'Submitting text keeps the page scrolled where it was' do
    visit edit_story_writing_session_path(stories(:one), writing_sessions(:one))

    # Stand in for the iPhone keyboard, which scrolls the page to keep the composer
    # visible: make the page taller than the window and scroll it down a little,
    # keeping the composer on screen.
    execute_script <<~JS
      const style = document.createElement('style');
      style.textContent = 'body::after { content: ""; display: block; height: 200vh; }';
      document.head.appendChild(style);
      window.scrollTo(0, 100);
      const composer = document.getElementById('composer');
      composer.focus({ preventScroll: true });
      composer.value = 'Here is some more text';
      window.minimumScrollY = window.scrollY;
      window.addEventListener('scroll', () => {
        window.minimumScrollY = Math.min(window.minimumScrollY, window.scrollY);
      });
    JS
    offset = evaluate_script('window.scrollY')
    assert_operator offset, :>, 0

    page.driver.browser.action.send_keys(:enter).perform
    within '.text-container' do
      assert_text 'Here is some more text'
    end
    assert_equal offset, evaluate_script('window.scrollY')
    assert_equal offset, evaluate_script('window.minimumScrollY')
  end

  test 'Deleting a session refreshes the story counts and shows a notice' do
    visit story_path(stories(:one))
    assert_text 'Word Count Total: 100'
    assert_text 'Writing Sessions: 1'

    accept_confirm { click_on 'Delete' }

    assert_selector '.flash', text: 'Session was successfully destroyed.'
    assert_text 'Word Count Total: 0'
    assert_text 'Writing Sessions: 0'
    assert_selector '.empty-state', text: 'Nothing yet.'
  end

  test 'Outline item height follows edited text' do
    item = outline_items(:one)
    item.update!(text: "First line\nSecond line\nThird line")
    visit story_outline_path(stories(:one))

    selector = "#outline-items #outline_item_#{item.id} textarea"
    initial_height = evaluate_script("document.querySelector(#{selector.to_json}).offsetHeight")

    execute_script(<<~JS, selector)
      const textarea = document.querySelector(arguments[0]);
      textarea.value = 'One line';
      textarea.dispatchEvent(new Event('input', { bubbles: true }));
    JS
    one_line_height = evaluate_script("document.querySelector(#{selector.to_json}).offsetHeight")
    assert_operator one_line_height, :<, initial_height

    execute_script(<<~JS, selector)
      const textarea = document.querySelector(arguments[0]);
      textarea.value = 'First line\\nSecond line\\nThird line\\nFourth line';
      textarea.dispatchEvent(new Event('input', { bubbles: true }));
    JS
    assert_operator evaluate_script("document.querySelector(#{selector.to_json}).offsetHeight"), :>, one_line_height
  end

  test 'Dragging an outline item persists its new position' do
    story = stories(:one)
    dragged_id = outline_items(:three).id.to_s
    original_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    visit story_outline_path(story)

    items = all('#outline-items li')
    items.last.find('.handle').drag_to(items.first)
    assert_equal dragged_id, first('#outline-items li')['data-id']

    visit story_outline_path(story)
    assert_equal dragged_id, first('#outline-items li')['data-id']
  ensure
    ActionController::Base.allow_forgery_protection = original_forgery_protection
  end

  test 'Stories list fits a phone screen' do
    stories(:one).update!(title: 'A Very Long Story Title That Keeps Going Past The Edge Of A Phone Screen')
    page.driver.browser.manage.window.resize_to(390, 844)
    visit stories_path
    assert_text 'Add a New Story'

    viewport_width = evaluate_script('document.documentElement.clientWidth')
    assert_operator evaluate_script('document.documentElement.scrollWidth'), :<=, viewport_width

    # Every row's actions, Delete included, sit inside the screen.
    rights = evaluate_script(<<~JS)
      [...document.querySelectorAll('.stories-grid .story-actions a')].map((a) => a.getBoundingClientRect().right)
    JS
    assert_not_empty rights
    rights.each { |right| assert_operator right, :<=, viewport_width }

    # The header button is not cut off at the top of the page.
    assert_operator evaluate_script("document.querySelector('.header-action').getBoundingClientRect().top"), :>=, 0
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end
end
