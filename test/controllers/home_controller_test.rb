require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test 'links to resume the most recently updated writing session' do
    act_as users(:bob)
    writing_sessions(:one).update!(updated_at: 1.minute.ago)
    writing_sessions(:two).update!(updated_at: 1.hour.ago)

    get root_url

    assert_select 'a.resume-session-link[href=?]',
                  edit_story_writing_session_path(stories(:one), writing_sessions(:one)),
                  text: 'Resume writing: Story title'
  end

  test 'omits the resume link when the user has no writing sessions' do
    act_as users(:bob)
    users(:bob).writing_sessions.destroy_all

    get root_url

    assert_select 'a.resume-session-link', count: 0
  end
end
