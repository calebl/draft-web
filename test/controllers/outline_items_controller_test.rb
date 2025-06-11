require 'test_helper'

class OutlineItemsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:bob)
    @story = stories(:one)
    @outline = outlines(:one)
    @outline_item = outline_items(:one)
    sign_in @user
  end

  test 'should get new' do
    get new_story_outline_outline_item_path(@story)
    assert_response :success
  end

  test 'should not get new if unauthorized' do
    sign_out @user
    get new_story_outline_outline_item_path(@story)
    assert_redirected_to '/user/sign_in'
  end

  test 'should show outline item' do
    get story_outline_outline_item_path(@story, @outline_item)
    assert_response :success
  end

  test 'should not show outline item if unauthorized' do
    sign_out @user
    get story_outline_outline_item_path(@story, @outline_item)
    assert_redirected_to '/user/sign_in'
  end

  test 'should create outline item' do
    assert_difference('OutlineItem.count') do
      post story_outline_outline_items_path(@story), params: {
        outline_item: { text: 'New outline item' }
      }
    end
    assert_redirected_to story_outline_path(@story)
  end

  test 'should create multiple outline items from multiline text' do
    assert_difference('OutlineItem.count', 3) do
      post story_outline_outline_items_path(@story), params: {
        outline_item: { text: "First item\nSecond item\nThird item" }
      }
    end
    assert_redirected_to story_outline_path(@story)
  end

  test 'should not create outline item if unauthorized' do
    sign_out @user
    assert_no_difference('OutlineItem.count') do
      post story_outline_outline_items_path(@story), params: {
        outline_item: { text: 'New outline item' }
      }
    end
    assert_redirected_to '/user/sign_in'
  end

  test 'should update outline item' do
    patch story_outline_outline_item_path(@story, @outline_item), params: {
      outline_item: { text: 'Updated text' }
    }
    assert_redirected_to story_outline_path(@story)
    @outline_item.reload
    assert_equal 'Updated text', @outline_item.text
  end

  test 'should update outline item position' do
    patch story_outline_outline_item_path(@story, @outline_item), params: {
      outline_item: { position: 2, text: @outline_item.text }
    }
    assert_redirected_to story_outline_path(@story)
    @outline_item.reload
    assert_equal 2, @outline_item.position
  end

  test 'should delete outline item when text is empty' do
    assert_difference('OutlineItem.count', -1) do
      patch story_outline_outline_item_path(@story, @outline_item), params: {
        outline_item: { text: '' }
      }
    end
    assert_redirected_to story_outline_path(@story)
  end

  test 'should not update outline item if unauthorized' do
    sign_out @user
    patch story_outline_outline_item_path(@story, @outline_item), params: {
      outline_item: { text: 'Updated text' }
    }
    assert_redirected_to '/user/sign_in'
    @outline_item.reload
    assert_not_equal 'Updated text', @outline_item.text
  end

  test 'should destroy outline item' do
    assert_difference('OutlineItem.count', -1) do
      delete story_outline_outline_item_path(@story, @outline_item)
    end
    assert_response :ok
  end

  test 'should not destroy outline item if unauthorized' do
    sign_out @user
    assert_no_difference('OutlineItem.count') do
      delete story_outline_outline_item_path(@story, @outline_item)
    end
    assert_redirected_to '/user/sign_in'
  end

  test 'should create outline if story has none' do
    story_without_outline = stories(:two)
    assert_difference('Outline.count') do
      get new_story_outline_outline_item_path(story_without_outline)
    end
    assert_response :success
  end
end
