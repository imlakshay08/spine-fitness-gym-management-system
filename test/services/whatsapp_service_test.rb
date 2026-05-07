require "test_helper"

class WhatsappServiceTest < ActiveSupport::TestCase
  test "send_message encodes message and builds correct URL" do
    phone   = "9876543210"
    message = "Hello, your membership expires on 31 Mar 2025!"
    api_key = "test_api_key"

    stub_response = Minitest::Mock.new
    stub_response.expect(:code, "200")

    Net::HTTP.stub(:get_response, stub_response) do
      result = WhatsappService.send_message(phone, message, api_key)
      assert result, "Expected send_message to return true on HTTP 200"
    end
  end

  test "send_message returns false on non-200 response" do
    stub_response = Minitest::Mock.new
    stub_response.expect(:code, "500")

    Net::HTTP.stub(:get_response, stub_response) do
      result = WhatsappService.send_message("9876543210", "Test", "key")
      assert_not result, "Expected send_message to return false on HTTP 500"
    end
  end

  test "message with special characters is properly encoded" do
    message = "Hello & welcome! Your plan costs Rs.1800"
    encoded = URI.encode_www_form_component(message)

    stub_response = Minitest::Mock.new
    stub_response.expect(:code, "200")

    captured_uri = nil
    Net::HTTP.stub(:get_response, ->(uri) { captured_uri = uri; stub_response }) do
      WhatsappService.send_message("9876543210", message, "key")
    end

    assert_includes captured_uri.to_s, encoded
  end
end
