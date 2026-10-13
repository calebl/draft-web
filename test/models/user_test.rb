require 'test_helper'

class UserTest < ActiveSupport::TestCase
  context "associations" do
    should have_many(:stories)
    should have_many(:writing_sessions)
  end

  context ".local" do
    should "return the oldest existing user" do
      assert_equal User.order(:id).first, User.local
    end

    should "create the local user when there are no users" do
      User.destroy_all

      assert_difference('User.count', 1) { User.local }
      assert_equal User::LOCAL_EMAIL, User.local.email
      assert_equal 1, User.count
    end
  end
end
