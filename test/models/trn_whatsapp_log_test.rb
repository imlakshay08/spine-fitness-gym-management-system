require "test_helper"

class TrnWhatsappLogTest < ActiveSupport::TestCase
  test "valid statuses are accepted" do
    %w[QUEUED SENT DELIVERED READ FAILED].each do |status|
      log = TrnWhatsappLog.new(
        wl_template_name: "membership_expiry_reminder",
        wl_status: status
      )
      assert log.valid?, "Expected #{status} to be a valid status"
    end
  end

  test "invalid status is rejected" do
    log = TrnWhatsappLog.new(
      wl_template_name: "membership_expiry_reminder",
      wl_status: "UNKNOWN"
    )
    assert_not log.valid?
  end

  test "template name is required" do
    log = TrnWhatsappLog.new(wl_status: "QUEUED")
    assert_not log.valid?
    assert_includes log.errors[:wl_template_name], "can't be blank"
  end

  test "can find log by interakt message id" do
    log = trn_whatsapp_logs(:one)
    found = TrnWhatsappLog.find_by(wl_interakt_msg_id: "msg_abc123")
    assert_equal log, found
  end
end
