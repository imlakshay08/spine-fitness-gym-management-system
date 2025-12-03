require "test_helper"

class LogAuditControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get log_audit_index_url
    assert_response :success
  end
end
