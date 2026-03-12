require "test_helper"

class InteraktSendWhatsappTest < ActiveSupport::TestCase
  test "strips non-digit characters from phone number" do
    phone = "+91-98765-43210"
    sanitized = phone.to_s.gsub(/\D/, "").last(10)
    assert_equal "9876543210", sanitized
  end

  test "returns error hash for phone numbers shorter than 10 digits" do
    result = Interakt::SendWhatsapp.send_template(
      phone:       "12345",
      template:    "membership_expiry_reminder",
      body_values: ["John", "31 Mar 2025"]
    )
    assert_equal 0,             result[:http_code]
    assert_equal "Invalid phone", result[:raw]
  end

  test "builds correct JSON payload" do
    expected_phone = "9876543210"

    stub_http   = Minitest::Mock.new
    stub_req    = Minitest::Mock.new
    stub_resp   = Minitest::Mock.new

    stub_resp.expect(:code, "200")
    stub_resp.expect(:body, '{"result":true,"id":"msg123"}')

    stub_http.expect(:use_ssl=, nil, [true])
    stub_http.expect(:request, stub_resp, [stub_req])

    stub_req.expect(:[]=, nil, ["Authorization", anything])
    stub_req.expect(:[]=, nil, ["Content-Type", "application/json"])
    stub_req.expect(:body=, nil, [anything])

    Net::HTTP.stub(:new, stub_http) do
      Net::HTTP::Post.stub(:new, stub_req) do
        result = Interakt::SendWhatsapp.send_template(
          phone:       "+91 #{expected_phone}",
          template:    "membership_expiry_reminder",
          body_values: ["John", "31 Mar 2025"]
        )
        assert_equal 200, result[:http_code]
      end
    end
  end
end
