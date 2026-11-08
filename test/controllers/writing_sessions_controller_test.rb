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

  test 'get new creates no session' do
    assert_no_difference('WritingSession.count') do
      get new_story_writing_session_url(@story), headers: { 'X-Sec-Purpose' => 'prefetch' }
    end
    assert_redirected_to story_url(@story)
  end

  test 'create without text starts an empty session' do
    assert_difference('WritingSession.count') do
      post story_writing_sessions_url(@story)
    end
    assert_redirected_to edit_story_writing_session_url(@story, WritingSession.last)
    assert_equal '', WritingSession.last.text
    assert_nil flash[:notice]
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

  test 'a paragraph sent again with the same id is saved once' do
    paragraph = { writing_session: { text: 'Sent from the phone' }, paragraph_id: 'para-1' }

    2.times do
      patch story_writing_session_url(@story, @writing_session, format: :json), params: paragraph, as: :json
      assert_response :ok
      assert_equal @writing_session.id, response.parsed_body['id']
    end

    assert_equal 'MyText<div>Sent from the phone</div>', @writing_session.reload.text
    assert_equal 1, SavedParagraph.where(paragraph_id: 'para-1').count
  end

  test 'a paragraph for a session deleted elsewhere starts a new session in the story, once' do
    @writing_session.destroy
    paragraph = { writing_session: { text: 'Written before the delete' }, paragraph_id: 'para-2' }

    patch story_writing_session_url(@story, @writing_session, format: :json), params: paragraph, as: :json
    assert_response :not_found

    assert_difference('@story.writing_sessions.count', 1) do
      2.times do
        post story_writing_sessions_url(@story, format: :json), params: paragraph, as: :json
        assert_response :ok
      end
    end
    created = @story.writing_sessions.last
    assert_equal '<div>Written before the delete</div>', created.text
    assert_equal created.id, response.parsed_body['id']
  end

  test 'update without session parameters is rejected' do
    original_text = @writing_session.text

    patch story_writing_session_url(@story, @writing_session)

    assert_response :bad_request
    assert_equal original_text, @writing_session.reload.text
  end

  test 'should destroy session' do
    assert_difference('WritingSession.count', -1) do
      delete story_writing_session_url(@story, @writing_session)
    end

    assert_redirected_to story_url(@story)
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
