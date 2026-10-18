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
end
