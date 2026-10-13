require 'test_helper'

class HomeTest < ActionDispatch::IntegrationTest
  setup do
    act_as users(:bob)
  end

  test 'show main after sign in' do
    get root_path
    assert_equal 200, status
    assert_equal '/', path

    assert_template 'layouts/home'
    assert_select 'a[href=?]', stories_path, count: 1
  end

  test 'blazer route gives access denied for non admin' do
    act_as users(:bob)

    get blazer_path
    assert_equal 302, status

    follow_redirect!
    assert_equal '/', path
    assert_match(/action failed/i, flash[:error])
  end

  test 'blazer route gives success for admin' do
    act_as users(:admin)

    get blazer_path
    assert_equal 200, status
  end
end
