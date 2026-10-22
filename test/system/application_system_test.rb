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

  test 'A long session fills the screen under the header and starts at the newest line' do
    session = writing_sessions(:one)
    session.update!(text: (1..80).map { |n| "<div>Sample line #{n} of placeholder text.</div>" }.join)

    [[1280, 800], [390, 844]].each do |width, height|
      page.driver.browser.manage.window.resize_to(width, height)
      visit edit_story_writing_session_path(stories(:one), session)
      assert_text 'Sample line 80'

      layout = evaluate_script(<<~JS)
        (() => {
          const header = document.querySelector('.edit-page .header').getBoundingClientRect();
          const text = document.querySelector('.edit-page .text');
          const composer = document.getElementById('composer').getBoundingClientRect();
          return {
            headerBottom: header.bottom,
            headerHeight: header.height,
            textTop: text.getBoundingClientRect().top,
            textBottom: text.getBoundingClientRect().bottom,
            composerTop: composer.top,
            composerBottom: composer.bottom,
            viewportHeight: window.innerHeight,
            gapToBottom: text.scrollHeight - text.clientHeight - text.scrollTop,
            scrolls: text.scrollHeight > text.clientHeight
          };
        })()
      JS

      # The text starts about half a header's height below the header.
      gap = layout['textTop'] - layout['headerBottom']
      assert_in_delta layout['headerHeight'] / 2, gap, 4, "#{width}px: text starts just under the header"
      assert_operator layout['textBottom'], :<=, layout['composerTop'], "#{width}px: text ends above the composer"
      assert_operator layout['composerBottom'], :<=, layout['viewportHeight'], "#{width}px: composer is on screen"
      assert layout['scrolls'], "#{width}px: long text scrolls"
      assert_operator layout['gapToBottom'], :<=, 1, "#{width}px: text starts scrolled to the bottom"
    end
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
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
