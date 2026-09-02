class WhatsappLogsController < ApplicationController
  before_action :require_login
  before_action :get_user_access_permissions
  include SoftCsrfProtection

  def index
    @compcodes = session[:loggedUserCompCode]

    load_filters
    @logs = fetch_logs

    # Preload the members and subscriptions referenced by these logs so the
    # view never fires a query per row. Keyed by string id because the log
    # foreign keys are stored as short strings ("11", "359").
    member_ids = @logs.map(&:wl_member_id).compact.uniq
    sub_ids    = @logs.map(&:wl_subscription_id).compact.uniq

    @members_hash = MstMembersList
                      .where("mmbr_compcode = ? AND id IN (?)", @compcodes, member_ids.presence || [0])
                      .index_by { |m| m.id.to_s }
    @subs_hash    = TrnMemberSubscription
                      .where("ms_compcode = ? AND id IN (?)", @compcodes, sub_ids.presence || [0])
                      .index_by { |s| s.id.to_s }

    @templates = WhatsappTemplates.member_facing
    @stats     = build_stats
  end

  private

  # Filters persist in the session (same pattern as Member Subscriptions) so a
  # staff member's view survives a page refresh. Reset clears them.
  def load_filters
    is_search = params[:server_request].to_s == "Y"

    if is_search
      @status_filter   = params[:status_filter].to_s.strip
      @template_filter = params[:template_filter].to_s.strip
      @search          = params[:log_search].to_s.strip
      session[:req_wl_status]   = @status_filter
      session[:req_wl_template] = @template_filter
      session[:req_wl_search]   = @search
    else
      @status_filter   = session[:req_wl_status].to_s.strip
      @template_filter = session[:req_wl_template].to_s.strip
      @search          = session[:req_wl_search].to_s.strip
    end
  end

  def fetch_logs
    scope = member_facing_logs

    scope = scope.where(wl_status: @status_filter)       if @status_filter.present?
    scope = scope.where(wl_template_name: @template_filter) if @template_filter.present?

    if @search.present?
      like = "%#{@search}%"
      member_ids = MstMembersList
                     .where("mmbr_compcode = ? AND (mmbr_name LIKE ? OR mmbr_contact LIKE ? OR mmbr_code LIKE ?)",
                            @compcodes, like, like, like)
                     .pluck(:id)
                     .map(&:to_s)

      if member_ids.present?
        scope = scope.where("wl_member_id IN (?) OR wl_interakt_msg_id LIKE ?", member_ids, like)
      else
        scope = scope.where("wl_interakt_msg_id LIKE ?", like)
      end
    end

    scope.order(Arel.sql("wl_sent_at DESC, id DESC"))
  end

  # Owner reports and staff alerts go to the owner or to a trainer, not to a
  # member, so they would show up here as "Deleted member" noise. Excluded from
  # both the table and the totals so the two always agree.
  #
  # Two guards, deliberately. The template list is the readable one, but it is
  # a list of names and a name can change — renaming the staff alert once
  # already let a batch of alerts through. The member-id check is structural:
  # every message to a member records that member's id, and nothing internal
  # ever does, so anything without one is not member correspondence whatever
  # its template ends up being called.
  def member_facing_logs
    TrnWhatsappLog
      .where(wl_compcode: @compcodes)
      .where.not(wl_template_name: WhatsappTemplates::INTERNAL)
      .where("wl_member_id IS NOT NULL AND wl_member_id <> ''")
  end

  def reset_filters
    session[:req_wl_status]   = nil
    session[:req_wl_template] = nil
    session[:req_wl_search]   = nil
  end

  # Company-wide totals for the summary cards — always the full picture, not
  # the filtered subset, so staff see overall deliverability at a glance.
  def build_stats
    base = member_facing_logs
    counts = base.group(:wl_status).count   # { "READ" => 12, "DELIVERED" => 3, ... }

    total     = counts.values.sum
    read      = counts["READ"].to_i
    delivered = read + counts["DELIVERED"].to_i    # a read message was also delivered
    failed    = counts["FAILED"].to_i
    pending   = total - delivered - failed         # QUEUED / SENT / ACCEPTED

    {
      total:     total,
      delivered: delivered,
      read:      read,
      failed:    failed,
      pending:   pending,
      read_rate: total.zero? ? 0 : ((read.to_f / total) * 100).round
    }
  end

  public

  def refresh
    reset_filters
    redirect_to "#{root_url}whatsapp_logs"
  end
end
