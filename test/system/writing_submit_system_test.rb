require 'test_helper'

class WritingSubmitSystemTest < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome

  setup do
    act_as users(:bob)
  end

  test 'Submitting text with the keyboard open keeps the header pinned and the newest line in view' do
    session = writing_sessions(:one)
    session.update!(text: (1..80).map { |n| "<div>Sample line #{n} of placeholder text.</div>" }.join)

    page.driver.browser.manage.window.resize_to(390, 844)
    visit edit_story_writing_session_path(stories(:one), session)
    assert_text 'Sample line 80'
    find('#composer').click

    # Headless Chrome has no on-screen keyboard: stand in a visual viewport that the
    # keyboard has shrunk to 400px and that the browser has panned 300px down the page.
    # It lives on window, so it is still open when the saved page comes back. Every
    # frame after the save records how far the text sits from its newest line and where
    # the header is, so a jump that later settles still fails.
    execute_script(<<~JS)
      const fake = new EventTarget();
      Object.assign(fake, {height: 400, pageTop: 300, offsetTop: 300});
      Object.defineProperty(window, 'visualViewport', {configurable: true, get: () => fake});
      const page = document.querySelector('[data-controller="compose"]');
      const controller = window.Stimulus.getControllerForElementAndIdentifier(page, 'compose');
      controller.disconnect();
      controller.connect();
      fake.dispatchEvent(new Event('resize'));

      window.submitFrames = {maxGap: 0, headerTops: []};
      const record = () => {
        const text = document.querySelector('.edit-page .text');
        const header = document.querySelector('.edit-page .header');
        const frames = window.submitFrames;
        frames.maxGap = Math.max(frames.maxGap, text.scrollHeight - text.clientHeight - text.scrollTop);
        frames.headerTops.push(Math.round(header.getBoundingClientRect().top + window.scrollY));
        requestAnimationFrame(record);
      };
      document.addEventListener('turbo:load', record, {once: true});
    JS

    find('#composer').send_keys('A freshly written line', :enter)
    within '.text-container' do
      assert_text 'A freshly written line'
    end

    frames = evaluate_script('window.submitFrames')
    assert_operator frames['headerTops'].length, :>, 0, 'frames were recorded after the save'
    assert_operator frames['maxGap'], :<=, 1, 'text never left the newest line'
    assert_equal [300], frames['headerTops'].uniq, 'header stayed at the top of the visible area'
    composer_bottom = evaluate_script("document.getElementById('composer').getBoundingClientRect().bottom")
    assert_operator composer_bottom, :<=, 700, 'composer sits above the keyboard'
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end
end
