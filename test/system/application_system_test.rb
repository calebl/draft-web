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

  test 'Move a session to another story' do
    visit story_path(stories(:one))
    click_on 'Move'
    select 'Second story', from: 'Move to story'
    click_on 'Move'
    assert_text 'Session moved to Second story.'
    assert_current_path story_writing_session_path(stories(:two), writing_sessions(:one))

    visit story_path(stories(:one))
    assert_no_text 'MyText'
  end

  test 'Move form offers only the other stories of the same user' do
    visit story_writing_session_path(stories(:one), writing_sessions(:one))
    within '.move-session-form' do
      assert_selector 'option', text: 'Second story'
      assert_no_selector 'option', text: 'Story title'
      assert_no_selector 'option', text: "Jane's Opus"
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
