require 'test_helper'
require 'json'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:bob)
    @session = writing_sessions(:one)
    
  end

  test "should get index" do
    get writing_sessions_url
    assert_response :success
  end

  test "should get new" do
    get new_writing_session_url
    assert_response :success
  end

  test "should create session" do
    assert_difference('WritingSession.count') do
      post writing_sessions_url, params: { session: { text: @session.text, word_count: @session.word_count } }
    end

    assert_redirected_to edit_writing_session_url(WritingSession.last)
  end

  test "should show session" do
    get writing_session_url(@session)
    assert_response :success
  end

  test "should get edit" do
    get edit_writing_session_url(@session)
    assert_response :success
  end

  test "should update session" do
    patch writing_session_url(@session), params: { session: { text: @session.text, word_count: @session.word_count } }
    assert_response :success
  end

  test "should destroy session" do
    assert_difference('WritingSession.count', -1) do
      delete writing_session_url(@session)
    end

    assert_redirected_to archive_writing_sessions_url
  end

  test "should show sessions archive" do
    get archive_writing_sessions_url
    assert_response :success
  end

  test "should limit archive sessions to users" do
    get archive_writing_sessions_url

    assert_select "tbody tr", count: users(:bob).writing_sessions.count
  end

  test "should get word count" do
    get word_count_writing_sessions_url, xhr: true

    assert_response :ok
    assert_equal 102, JSON.parse(@response.body)["word_count"]
  end

  test "should protect viewing writing sessions from other users" do
    sign_in users(:jane)

    get writing_session_url(@session)
    assert_redirected_to root_path
  end

  test "should protect edit writing sessions from other users" do
    sign_in users(:jane)

    get edit_writing_session_url(@session)
    assert_redirected_to root_path
  end

  test "should allow admin to view writing sessions from other users" do
    sign_in users(:admin)

    get writing_session_url(@session)
    assert_response :success
  end

  test "should allow admin to edit writing sessions from other users" do
    sign_in users(:admin)

    get edit_writing_session_url(@session)
    assert_response :success
  end

end
