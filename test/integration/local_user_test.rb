require 'test_helper'

class LocalUserTest < ActionDispatch::IntegrationTest
  test 'opens the app without signing in' do
    get root_path
    assert_response :success
    assert_template 'home/index'
  end

  test 'creates the local user on first visit to an empty database' do
    User.destroy_all

    assert_difference('User.count', 1) { get root_path }
    assert_response :success
    assert_equal User::LOCAL_EMAIL, User.first.email
  end

  test 'has no sign up or log in pages' do
    get '/user/sign_in'
    assert_response :not_found

    get '/user/sign_up'
    assert_response :not_found
  end
end
