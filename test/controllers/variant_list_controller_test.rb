require "test_helper"

class VariantListControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get variant_list_index_url
    assert_response :success
  end

  test "should get add_variant" do
    get variant_list_add_variant_url
    assert_response :success
  end
end
