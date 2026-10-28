require 'test_helper'

class NewSessionSystemTest < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome

  setup do
    act_as users(:bob)
    @story = stories(:one)
  end

  test 'Hovering New Session creates no session and pressing it creates exactly one' do
    visit story_path(@story)
    assert_difference('WritingSession.count', 0) do
      find('a', text: 'New Session').hover
      sleep 1 # give Turbo's hover prefetch time to fire
    end

    assert_difference('WritingSession.count', 1) do
      click_on 'New Session'
      assert_selector '#composer'
    end
    assert_current_path edit_story_writing_session_path(@story, WritingSession.last)
  end

  test 'Pressing Write on the stories list creates exactly one session' do
    visit stories_path
    assert_difference('WritingSession.count', 1) do
      within('.story', text: @story.title) do
        find('a', text: 'Write').hover
        sleep 1 # give Turbo's hover prefetch time to fire
        click_on 'Write'
      end
      assert_selector '#composer'
    end
    assert_current_path edit_story_writing_session_path(@story, WritingSession.last)
  end
end
