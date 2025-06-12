require 'test_helper'
require 'json'

class WritingSessionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:bob)
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

  test 'should protect viewing writing sessions from other users' do
    sign_in users(:jane)

    get story_writing_session_url(@story, @writing_session)
    assert_redirected_to root_path
  end

  test 'should protect edit writing sessions from other users' do
    sign_in users(:jane)

    get edit_story_writing_session_url(@story, @writing_session)
    assert_redirected_to root_path
  end

  test 'should not allow admin to view writing sessions from other users' do
    sign_in users(:admin)

    get story_writing_session_url(@story, @writing_session)
    assert_redirected_to root_path
  end

  test 'should not allow admin to edit writing sessions from other users' do
    sign_in users(:admin)

    get edit_story_writing_session_url(@story, @writing_session)
    assert_redirected_to root_path
  end
end
