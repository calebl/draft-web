require 'test_helper'

class WritingViewportSystemTest < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome

  setup do
    act_as users(:bob)
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

  test 'A viewport resize keeps a long session anchored to the newest line' do
    session = writing_sessions(:one)
    session.update!(text: (1..80).map { |n| "<div>Sample line #{n} of placeholder text.</div>" }.join)

    page.driver.browser.manage.window.resize_to(390, 844)
    visit edit_story_writing_session_path(stories(:one), session)
    assert_text 'Sample line 80'
    assert_operator gap_to_bottom, :<=, 1

    find('#composer').click
    page.driver.browser.manage.window.resize_to(390, 500)
    assert_operator gap_to_bottom, :<=, 1

    page.driver.browser.manage.window.resize_to(390, 844)
    execute_script(<<~JS)
      const text = document.querySelector('.edit-page .text');
      text.scrollTop = 0;
      text.dispatchEvent(new Event('scroll'));
    JS
    assert_equal 0, evaluate_script("document.querySelector('.edit-page .text').scrollTop")
    page.driver.browser.manage.window.resize_to(390, 500)
    assert_equal 0, evaluate_script("document.querySelector('.edit-page .text').scrollTop")
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end

  private

  def gap_to_bottom
    evaluate_script(<<~JS)
      (() => {
        const text = document.querySelector('.edit-page .text');
        return text.scrollHeight - text.clientHeight - text.scrollTop;
      })()
    JS
  end
end
