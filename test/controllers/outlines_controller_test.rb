require "test_helper"

class OutlinesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @story = stories(:one)
    act_as users(:bob)
  end

  test 'outline rows carry each item id for drag-reorder' do
    get story_outline_path(@story)
    assert_response :success
    @story.outline_items.each do |item|
      assert_select "ol[data-controller=outline-items] > li[data-id='#{item.id}']", 1
    end
  end
end
