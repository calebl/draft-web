require 'test_helper'
require 'json'

class WritingSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    act_as users(:bob)
    @writing_session = writing_sessions(:one)
    @story = stories(:one)
  end

  test 'should get index' do
    get story_writing_sessions_url(@story)
    assert_response :success
  end

  test 'should get new' do
    assert_difference('WritingSession.count') do
      get new_story_writing_session_url(@story)
    end
    assert_redirected_to edit_story_writing_session_url(@story, WritingSession.last)
  end

  test 'should create session' do
    assert_difference('WritingSession.count') do
      post story_writing_sessions_url(@story), params: { writing_session: { text: @writing_session.text } }
    end

    assert_response :see_other
    assert_redirected_to edit_story_writing_session_url(@story, WritingSession.last)
  end

  test 'should show session' do
    get story_writing_session_url(@story, @writing_session)
    assert_response :success
  end

  test 'should get edit' do
    get edit_story_writing_session_url(@story, @writing_session)
    assert_response :success
  end

  test 'should update session' do
    patch story_writing_session_url(@story, @writing_session),
          params: { writing_session: { text: @writing_session.text }, story_id: @story.id }
    assert_response :see_other
  end

  test 'should destroy session' do
    assert_difference('WritingSession.count', -1) do
      delete story_writing_session_url(@story, @writing_session)
    end

    assert_redirected_to story_url(@story)
  end

  test 'should move session to another story' do
    target = stories(:two)
    source_updated_at = @story.updated_at
    target_updated_at = target.updated_at

    travel 1.second do
      patch move_story_writing_session_url(@story, @writing_session), params: { target_story_id: target.id }
    end

    assert_redirected_to story_writing_session_url(target, @writing_session)
    assert_equal target, @writing_session.reload.story
    assert_operator @story.reload.updated_at, :>, source_updated_at
    assert_operator target.reload.updated_at, :>, target_updated_at
    assert_equal 'Session moved to Second story.', flash[:notice]
  end

  test 'should not move session to a story belonging to another user' do
    source_updated_at = @story.updated_at
    other_story = stories(:three)
    other_updated_at = other_story.updated_at

    patch move_story_writing_session_url(@story, @writing_session), params: { target_story_id: other_story.id }

    assert_redirected_to story_writing_session_url(@story, @writing_session)
    assert_equal @story, @writing_session.reload.story
    assert_equal source_updated_at, @story.reload.updated_at
    assert_equal other_updated_at, other_story.reload.updated_at
    assert_not_nil flash[:alert]
  end

  test 'should leave session and story untouched when moved to its current story' do
    source_updated_at = @story.updated_at

    patch move_story_writing_session_url(@story, @writing_session), params: { target_story_id: @story.id }

    assert_redirected_to story_writing_session_url(@story, @writing_session)
    assert_equal @story, @writing_session.reload.story
    assert_equal source_updated_at, @story.reload.updated_at
    assert_nil flash[:notice]
  end

  test 'should not allow other users to move a session' do
    act_as users(:jane)

    patch move_story_writing_session_url(@story, @writing_session), params: { target_story_id: stories(:three).id }

    assert_redirected_to root_path
    assert_equal @story, @writing_session.reload.story
  end

  test 'destroying from the all-sessions list returns to it' do
    delete story_writing_session_url(@story, @writing_session, show_all: true)

    assert_redirected_to story_writing_sessions_url(@story)
    follow_redirect!
    assert_select '.flash[role=status]', text: 'Session was successfully destroyed.'
  end

  test 'all-sessions list delete links keep the list' do
    get story_writing_sessions_url(@story)

    assert_select "a[data-turbo-method=delete][href=?]", story_writing_session_path(@story, @writing_session, show_all: true)
  end

  test 'story page delete link returns to the story page' do
    get story_url(@story)

    assert_select "a[data-turbo-method=delete][href=?]", story_writing_session_path(@story, @writing_session)
  end

  test 'shows the destroy notice as a note, not a script' do
    delete story_writing_session_url(@story, @writing_session)
    follow_redirect!

    assert_select '.flash[role=status]', text: 'Session was successfully destroyed.'
    assert_select 'script', text: /toastr/, count: 0
  end

  test 'should protect viewing writing sessions from other users' do
    act_as users(:jane)

    get story_writing_session_url(@story, @writing_session)
    assert_redirected_to root_path
  end

  test 'should protect edit writing sessions from other users' do
    act_as users(:jane)

    get edit_story_writing_session_url(@story, @writing_session)
    assert_redirected_to root_path
  end

  test 'should not allow admin to view writing sessions from other users' do
    act_as users(:admin)

    get story_writing_session_url(@story, @writing_session)
    assert_redirected_to root_path
  end

  test 'should not allow admin to edit writing sessions from other users' do
    act_as users(:admin)

    get edit_story_writing_session_url(@story, @writing_session)
    assert_redirected_to root_path
  end
end
