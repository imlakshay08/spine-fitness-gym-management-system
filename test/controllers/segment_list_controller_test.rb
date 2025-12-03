require "test_helper"

class SegmentListControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get segment_list_index_url
    assert_response :success
  end

  test "should get add_segment" do
    get segment_list_add_segment_url
    assert_response :success
  end
end
