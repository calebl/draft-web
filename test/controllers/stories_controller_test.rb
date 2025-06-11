require 'test_helper'
require 'json'

class StoriesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:bob)
  end

  context '#index' do
    should 'get index' do
      get stories_url
      assert_response :success

      assert_select '.story', count: users(:bob).stories.count + 1
    end

    should 'restrict admin to only their own stories' do
      sign_in users(:admin)

      get stories_url
      assert_response :success

      assert_select '.story', count: users(:admin).stories.count + 1
    end
  end

  context '#new' do
    should 'get new story form' do
      get new_story_url
      assert_response :success
    end
  end

  context '#create' do
    should 'create a new story' do
      assert_difference('Story.count') do
        post stories_url, params: { story: { title: 'New Story Title' } }
      end

      assert_response :redirect
      assert_redirected_to story_url(Story.last)
    end

    should 'not create story with invalid params' do
      assert_no_difference('Story.count') do
        post stories_url, params: { story: { title: '' } }
      end
      assert_response :unprocessable_entity
    end
  end

  context '#show' do
    setup do
      @story = users(:bob).stories.create({ title: 'New Story' })
      @writing_sessions = []
      3.times do
        @writing_sessions << @story.writing_sessions.create!(word_count: 100, user: users(:bob))
      end
      sign_in users(:bob)
    end

    should 'return story' do
      get story_url(@story.id)
      assert_response :success
    end

    should 'assign writing sessions' do
      get story_url(@story.id)
      assert_equal @writing_sessions.map(&:id).sort, assigns(:writing_sessions).map(&:id).sort
    end

    should 'calculate total word count' do
      get story_url(@story.id)
      assert_equal 300, assigns(:word_count_total)
    end

    should 'assign next outline item' do
      outline = Outline.create!(story: @story)
      outline_item = outline.outline_items.create!(text: 'Test Item')
      get story_url(@story.id)
      assert_equal outline_item, assigns(:next_outline_item)
    end

    should 'prevent access to other users stories' do
      other_story = users(:admin).stories.create({ title: 'Other Story' })
      get story_url(other_story.id)
      assert_redirected_to root_path
    end
  end

  context '#edit' do
    setup do
      @story = users(:bob).stories.create({ title: 'New Story' })
    end

    should 'get edit form' do
      get edit_story_url(@story.id)
      assert_response :success
    end

    should 'prevent editing other users stories' do
      other_story = users(:admin).stories.create({ title: 'Other Story' })
      get edit_story_url(other_story.id)
      assert_redirected_to root_path
    end
  end

  context '#update' do
    setup do
      @story = users(:bob).stories.create({ title: 'New Story' })
    end

    should 'update story with valid params' do
      patch story_url(@story.id), params: { story: { title: 'Updated Title' } }
      @story.reload
      assert_equal 'Updated Title', @story.title
      assert_response :success
    end

    should 'not update story with invalid params' do
      original_title = @story.title
      patch story_url(@story.id), params: { story: { title: '' } }
      @story.reload
      assert_equal original_title, @story.title
      assert_response :unprocessable_entity
    end

    should 'prevent updating other users stories' do
      other_story = users(:admin).stories.create({ title: 'Other Story' })
      patch story_url(other_story.id), params: { story: { title: 'Updated Title' } }
      assert_redirected_to root_path
    end
  end

  context '#destroy' do
    setup do
      @story = users(:bob).stories.create({ title: 'New Story' })
    end

    should 'destroy story' do
      assert_difference('Story.count', -1) do
        delete story_url(@story.id)
      end
      assert_redirected_to stories_url
    end

    should 'prevent destroying other users stories' do
      other_story = users(:admin).stories.create({ title: 'Other Story' })
      assert_no_difference('Story.count') do
        delete story_url(other_story.id)
      end
      assert_redirected_to root_path
    end
  end
end
