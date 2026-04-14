require "test_helper"

class Webhooks::InteraktControllerTest < ActionDispatch::IntegrationTest
  test "returns ok when message id not found in logs" do
    post "/webhooks/interakt", params: { id: "nonexistent_id", event: "message_sent" }.to_json,
         headers: { "Content-Type" => "application/json" }
    assert_response :ok
  end
end
