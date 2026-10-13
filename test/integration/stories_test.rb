require 'test_helper'

class StoriesTest < ActionDispatch::IntegrationTest
  setup do
    act_as users(:bob)
  end

  test 'show stories list' do
    get stories_path
    assert_equal 200, status
    assert_equal '/stories', path

    assert_template 'application'
    assert_match(/Story title/i, response.body)
  end

  test 'show story' do
    get story_path(stories(:one))

    assert_equal 200, status
    assert_match(%r{/stories/\d+}, path)
    assert_match(/Story title/i, response.body)
  end

  test 'create story' do
    get new_story_path
    assert_equal 200, status
    assert_equal '/stories/new', path

    assert_template 'stories/new'
    assert_select 'form[action=?]', stories_path, count: 1

    post stories_path, params: { story: { title: 'New story title' } }
    assert_equal 302, status

    follow_redirect!
    assert_match(%r{/stories/*}, path)
    assert_match(/New story title/i, response.body)
  end

  test 'edit story' do
    get edit_story_path(stories(:one))
    assert_equal 200, status
    assert_match %r{/stories/\d+/edit}, path

    assert_template 'stories/edit'
    assert_select 'form[action=?]', story_path(stories(:one)), count: 1

    patch story_path(stories(:one)), params: { story: { title: 'Updated story title' } }
    assert_equal 200, status

    assert_match(%r{/stories/*}, path)
    assert_match(/Updated story title/i, response.body)
  end


end
