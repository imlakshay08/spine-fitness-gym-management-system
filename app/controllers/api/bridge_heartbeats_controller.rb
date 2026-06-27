class Api::BridgeHeartbeatsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    heartbeat = TrnBridgeHeartbeat.find_or_initialize_by(
      bh_compcode: params[:compcode],
      bh_device_sn: params[:device_sn]
    )
    heartbeat.update!(
      bh_last_seen: Time.current,
      bh_bridge_version: params[:bridge_version]
    )
    render json: { status: true }
  end
end