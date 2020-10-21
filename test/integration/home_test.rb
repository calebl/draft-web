require 'test_helper'

class HomeTest < ActionDispatch::IntegrationTest
  test "links" do
    get root_path

    assert_template 'layouts/application'
    assert_select "a[href=?]", new_session_path, count: 1
    assert_select "a[href=?]", archive_sessions_path, count: 1
  end

end
