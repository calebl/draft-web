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
        document.body.dataset.saveFrames = 'true';
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
    assert_no_selector '.unsaved'
    assert_selector 'body[data-save-frames=true]'

    frames = evaluate_script('window.submitFrames')
    assert_operator frames['headerTops'].length, :>, 0, 'frames were recorded after the save'
    assert_operator frames['maxGap'], :<=, 1, 'text never left the newest line'
    assert_equal [300], frames['headerTops'].uniq, 'header stayed at the top of the visible area'
    composer_bottom = evaluate_script("document.getElementById('composer').getBoundingClientRect().bottom")
    assert_operator composer_bottom, :<=, 700, 'composer sits above the keyboard'
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end

  test 'Submitting a short session with the keyboard open does not make the page jump' do
    session = writing_sessions(:one)
    session.update!(text: '<div>A short opening line.</div>')

    page.driver.browser.manage.window.resize_to(375, 667)
    visit edit_story_writing_session_path(stories(:one), session)
    assert_text 'A short opening line.'
    find('#composer').click

    # Stand in for the iPhone keyboard (a 346px visible area) and for how iOS reveals a
    # field focused while the keyboard is open: unless the focus asks not to scroll, it
    # scrolls the page to centre the field in the visible area and only reports that
    # scroll about 100ms later. Every frame records where the header sits in the visible
    # area, so a jump that later settles still fails.
    execute_script(<<~JS)
      const fake = new EventTarget();
      Object.assign(fake, {height: 346, pageTop: 0, offsetTop: 0});
      Object.defineProperty(window, 'visualViewport', {configurable: true, get: () => fake});
      const page = document.querySelector('[data-controller="compose"]');
      const controller = window.Stimulus.getControllerForElementAndIdentifier(page, 'compose');
      controller.disconnect();
      controller.connect();

      window.revealScrolls = 0;
      const focus = HTMLElement.prototype.focus;
      HTMLElement.prototype.focus = function(options) {
        focus.call(this, options);
        if (this.id !== 'composer' || options?.preventScroll) return;
        const rect = this.getBoundingClientRect();
        const target = Math.round(rect.top + window.scrollY - (fake.height - rect.height) / 2);
        if (target === fake.pageTop) return;
        window.revealScrolls += 1;
        fake.pageTop = target;
        setTimeout(() => fake.dispatchEvent(new Event('scroll')), 100);
      };

      window.headerTops = [];
      const record = () => {
        const header = document.querySelector('.edit-page .header');
        window.headerTops.push(Math.round(header.getBoundingClientRect().top + window.scrollY - fake.pageTop));
        requestAnimationFrame(record);
      };
      record();
      document.addEventListener('turbo:load', () => {
        setTimeout(() => document.documentElement.setAttribute('data-settled', ''), 400);
      }, {once: true});
    JS

    find('#composer').send_keys('A second line', :enter)
    within '.text-container' do
      assert_text 'A second line'
    end
    assert_selector 'html[data-settled]', visible: :all

    assert_equal [0], evaluate_script('window.headerTops').uniq, 'header stayed at the top of the visible area'
    assert_equal 0, evaluate_script('window.revealScrolls'), 'the new composer was focused without scrolling'
    assert evaluate_script("document.activeElement.id === 'composer'"), 'the new composer has focus'
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end

  test 'Saving lines one after another in a short session only ever moves the text up' do
    session = writing_sessions(:one)
    session.update!(text: '<div>A short opening line.</div><div>A second short line.</div>')

    page.driver.browser.manage.window.resize_to(375, 520)
    visit edit_story_writing_session_path(stories(:one), session)
    assert_text 'A second short line.'
    find('#composer').click

    # The keyboard leaves a 346px visible area. The text sits just above the composer, so
    # each saved line pushes it up. Every frame records where the first line sits in the
    # visible area: it must never come back down, including once a save comes straight
    # back and the page is refreshed.
    execute_script(<<~JS)
      const fake = new EventTarget();
      Object.assign(fake, {height: 346, pageTop: 0, offsetTop: 0});
      Object.defineProperty(window, 'visualViewport', {configurable: true, get: () => fake});
      const page = document.querySelector('[data-controller="compose"]');
      const controller = window.Stimulus.getControllerForElementAndIdentifier(page, 'compose');
      controller.disconnect();
      controller.connect();

      window.firstLineTops = [];
      const record = () => {
        const first = document.querySelector('#session-text div');
        window.firstLineTops.push(Math.round(first.getBoundingClientRect().top + window.scrollY - fake.pageTop));
        requestAnimationFrame(record);
      };
      record();
      window.loads = 0;
      document.addEventListener('turbo:load', () => { document.documentElement.dataset.loads = ++window.loads; });
    JS

    ['A third line', 'A fourth line', 'A fifth line that is long enough to wrap onto another row'].each_with_index do |line, index|
      find('#composer').send_keys(line, :enter)
      assert_selector "html[data-loads='#{index + 1}']", visible: :all
      within('#session-text') { assert_text line }
    end
    sleep 0.7

    tops = evaluate_script('window.firstLineTops')
    drops = tops.each_cons(2).map { |before, after| after - before }.select(&:positive?)
    assert_empty drops, 'the text never moved back down'
    assert_operator tops.first - tops.last, :>, 0, 'saved lines pushed the text up'
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end
end
