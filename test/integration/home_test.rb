require 'test_helper'

class HomeTest < ActionDispatch::IntegrationTest
  setup do
    act_as users(:bob)
    @feedback_command = ENV.fetch('DRAFT_FEEDBACK_COMMAND', nil)
    ENV['DRAFT_FEEDBACK_COMMAND'] = 'true'
  end

  teardown do
    ENV['DRAFT_FEEDBACK_COMMAND'] = @feedback_command
  end

  test 'show main after sign in' do
    get root_path
    assert_equal 200, status
    assert_equal '/', path

    assert_template 'layouts/home'
    assert_select 'a[href=?]', stories_path, count: 1
    assert_select 'meta[name="pocket-kit-replay"][data-show-typed-text="false"]', count: 1
  end

  test 'home page draws its icons inline instead of loading an icon script' do
    get root_path

    assert_select '[data-theme-icon] svg.icon', count: 3
    assert_select 'script[src*="fontawesome"]', count: 0
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
