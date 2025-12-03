require "test_helper"

class PackSizeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get pack_size_index_url
    assert_response :success
  end

  test "should get add_packsize" do
    get pack_size_add_packsize_url
    assert_response :success
  end
end
