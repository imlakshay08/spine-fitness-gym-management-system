# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_08_25_140000) do
  create_table "biometric_id_allocations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "allocation_compcode", limit: 12, default: "", null: false
    t.string "allocation_device_sn", limit: 50, default: "", null: false
    t.integer "allocation_next_uid", null: false
    t.integer "allocation_next_device_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mst_category_lists", charset: "latin1", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "cat_compcode", limit: 12, default: "", null: false
    t.string "cat_code", limit: 10, default: "", null: false
    t.string "cat_descp", limit: 100, default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mst_companies", charset: "latin1", force: :cascade do |t|
    t.string "cmp_companycode", limit: 20, null: false
    t.string "cmp_companyname", limit: 60, null: false
    t.string "cmp_tradename", limit: 60, null: false
    t.string "cmp_gstname", limit: 30, null: false
    t.string "cmp_typeofbussiness", limit: 250, null: false
    t.string "cmp_addressline1", limit: 225, null: false
    t.string "cmp_addressline2", limit: 225, null: false
    t.string "cmp_addressline3", limit: 225, null: false
    t.string "cmp_telephonenumber", limit: 12, default: "0", null: false
    t.string "cmp_cell_number", limit: 11, default: "0", null: false
    t.integer "cmp_countrycode", default: 0, null: false
    t.integer "cmp_stateandcode", default: 0, null: false
    t.string "cmp_email", limit: 100, null: false
    t.string "cmp_bankname", limit: 60, null: false
    t.string "cmp_bankbranch", limit: 100, null: false
    t.string "cmp_accountnumber", limit: 30, null: false
    t.string "cmp_pannumber", limit: 25, null: false
    t.string "cmp_adharnumber", limit: 25, null: false
    t.string "cmp_termandcondition", null: false
    t.string "cmp_declaration", limit: 200, null: false
    t.string "cmp_logos", limit: 100, null: false
    t.string "cmp_bankifsccode", limit: 20, null: false
    t.string "cmp_compidentity_no", limit: 36, null: false
    t.string "cmp_otp", limit: 10, null: false
    t.string "cmp_signs", limit: 100, null: false
    t.column "cmp_show_logo", "enum('Y','N')", default: "N", null: false
    t.column "cmp_show_pay_pop", "enum('Y','N')", default: "N", null: false
    t.string "cmp_credit_debit_sgn", limit: 1, default: "N", null: false
    t.column "cmp_proddup_allowed", "enum('Y','N')", default: "N", null: false
    t.column "cmp_raw_material", "enum('Y','N')", default: "Y", null: false
    t.column "cmp_multi_loc", "enum('Y','N')", default: "N", null: false
    t.string "cmp_status", limit: 1, null: false
    t.string "cmp_unitname", limit: 62, null: false
    t.column "cmp_gst_registered", "enum('Y','N')", default: "N", null: false
    t.column "cmp_godam_allowed", "enum('Y','N')", default: "N", null: false
    t.column "cmp_negative_stock", "enum('Y','N')", default: "N", null: false
    t.column "cmp_show_unbilled", "enum('Y','N')", default: "N", null: false
    t.string "comp_ad_code", limit: 60, default: "", null: false
    t.string "comp_use_code", limit: 30, default: "", null: false
    t.integer "comp_redeemscale", default: 0, null: false
    t.float "cmp_memb_purlimit", limit: 53, default: 0.0, null: false
    t.string "cmp_max_workdays", limit: 3, default: "", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["cmp_companycode"], name: "cmp_companycode", unique: true
  end

  create_table "mst_faculties", charset: "latin1", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "fclty_compcode", limit: 12, default: "", null: false
    t.string "fclty_code", limit: 10, default: "", null: false
    t.string "fclty_name", limit: 50, null: false
    t.string "fclty_gender", limit: 5, null: false
    t.date "fclty_dob"
    t.date "fclty_join_date"
    t.date "fclty_leave_date"
    t.string "fclty_mrtl_stats", limit: 20, null: false
    t.string "fclty_aadhaar", limit: 12, default: "", null: false
    t.string "fclty_pan", limit: 10, default: "", null: false
    t.string "fclty_addr1", limit: 150, default: "", null: false
    t.string "fclty_addr2", limit: 150, default: "", null: false
    t.string "fclty_city", limit: 50, default: "", null: false
    t.string "fclty_email", limit: 50, default: "", null: false
    t.string "fclty_contact", limit: 10, default: "", null: false
    t.string "fclty_father", limit: 50, default: "", null: false
    t.string "fclty_mother", limit: 50, default: "", null: false
    t.string "fclty_qlf", limit: 50, default: "", null: false
    t.string "fclty_desig", limit: 50, default: "", null: false
    t.string "fclty_spouse", limit: 50, default: "", null: false
    t.string "fclty_img", limit: 150, default: "", null: false
    t.string "fclty_aebas_id", limit: 25, default: "", null: false
    t.string "fclty_employee_code", limit: 25, default: "", null: false
    t.string "fclty_blood_group", limit: 10, default: "", null: false
    t.string "fclty_cghs_id", limit: 25, default: "", null: false
    t.string "fclty_emergency_no", limit: 13, default: "", null: false
    t.date "fclty_valid_upto", null: false
    t.string "fclty_signature", limit: 80, default: "", null: false
    t.string "fclty_paylevel", limit: 80, default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mst_list_modules", charset: "latin1", force: :cascade do |t|
    t.string "lm_compcode", limit: 30, null: false
    t.string "lm_modulecode", limit: 30, null: false
    t.string "lm_module_category", limit: 25, default: "", null: false
    t.string "lm_modules", limit: 120, null: false
    t.string "lm_departcode", limit: 50, default: "", null: false
    t.string "lm_status", limit: 1, default: "Y", null: false
    t.string "lm_url", limit: 500, default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mst_members_lists", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "mmbr_compcode", limit: 12, default: "", null: false
    t.string "mmbr_code", limit: 10, default: "", null: false
    t.string "mmbr_name", limit: 50, null: false
    t.string "mmbr_gender", limit: 5, null: false
    t.date "mmbr_dob"
    t.date "mmbr_join_date"
    t.date "mmbr_leave_date"
    t.string "mmbr_mrtl_stats", limit: 20, null: false
    t.string "mmbr_aadhaar", limit: 12, default: "", null: false
    t.string "mmbr_addr1", limit: 150, default: "", null: false
    t.string "mmbr_addr2", limit: 150, default: "", null: false
    t.string "mmbr_city", limit: 50, default: "", null: false
    t.string "mmbr_email", limit: 50, default: "", null: false
    t.string "mmbr_contact", limit: 10, default: "", null: false
    t.string "mmbr_father", limit: 50, default: "", null: false
    t.string "mmbr_mother", limit: 50, default: "", null: false
    t.date "mmbr_entry_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "mmbr_status", limit: 1, default: "A", null: false
    t.datetime "mmbr_removed_at", precision: nil
    t.string "mmbr_removed_by", limit: 50
    t.string "mmbr_remove_reason", limit: 250
    t.index ["mmbr_compcode", "mmbr_status"], name: "idx_members_compcode_status"
  end

  create_table "mst_membership_plans", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "plan_compcode", limit: 12, default: "", null: false
    t.string "plan_name", limit: 25, default: "", null: false
    t.string "plan_duration_months", limit: 3, null: false
    t.string "plan_amount", limit: 8, default: "", null: false
    t.string "plan_description", limit: 50, default: "", null: false
    t.string "plan_mrp_amount", limit: 9, default: "", null: false
    t.string "plan_final_amount", limit: 9, default: "", null: false
    t.integer "plan_is_open", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mst_menu_entries", charset: "latin1", force: :cascade do |t|
    t.string "me_compcode", limit: 30, null: false
    t.string "me_menuname", limit: 120, default: "", null: false
    t.string "me_controller_name", limit: 120, default: "", null: false
    t.string "me_action_name", limit: 120, default: "", null: false
    t.string "me_heading", limit: 60, default: "", null: false
    t.string "me_menubar", limit: 50, default: "", null: false
    t.string "me_access", limit: 50, default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mst_staff_lists", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "stf_compcode", limit: 12, default: "", null: false
    t.string "stf_code", limit: 10, default: "", null: false
    t.string "stf_name", limit: 250, default: "", null: false
    t.string "stf_gender", limit: 6, default: "", null: false
    t.date "stf_dob", null: false
    t.string "stf_designation", limit: 100, default: "", null: false
    t.date "stf_join_date"
    t.date "stf_leave_date"
    t.string "stf_contact", limit: 10, default: "", null: false
    t.string "stf_email", limit: 150, default: "", null: false
    t.string "stf_address1", default: "", null: false
    t.string "stf_address2", default: "", null: false
    t.string "stf_aadhaar", limit: 12, default: "", null: false
    t.string "stf_status", limit: 20, default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mst_stock_lists", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sl_compcode", limit: 12, default: "", null: false
    t.string "sl_name", limit: 25, default: "", null: false
    t.string "sl_descp", limit: 75, default: "", null: false
  end

  create_table "mst_trainer_lists", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "trn_compcode", limit: 12, default: "", null: false
    t.string "trn_code", limit: 10, default: "", null: false
    t.string "trn_name", limit: 150, default: "", null: false
    t.string "trn_gender", limit: 6, default: "", null: false
    t.date "trn_dob", null: false
    t.string "trn_speciality", limit: 200, default: "", null: false
    t.string "trn_certification", limit: 200, default: "", null: false
    t.string "trn_experience_years", limit: 3, default: "", null: false
    t.string "trn_contact", limit: 10, default: "", null: false
    t.string "trn_email", limit: 50, default: "", null: false
    t.string "trn_salary_type", limit: 75, default: "", null: false
    t.string "trn_salary_amount", limit: 8, default: "", null: false
    t.string "trn_status", limit: 10, default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", charset: "latin1", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "trn_audit_trials", charset: "latin1", force: :cascade do |t|
    t.string "ad_compcode", limit: 30, null: false
    t.string "ad_event", limit: 50, null: false
    t.string "ad_module", limit: 100, default: "", null: false
    t.string "ad_description", limit: 1000, null: false
    t.date "ad_date", null: false
    t.string "ad_time", limit: 30, default: "", null: false
    t.string "ad_user", limit: 50, null: false
    t.string "ad_ip", limit: 55, null: false
    t.string "ad_path", limit: 150, null: false
    t.string "ad_device_id", limit: 150, default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trn_bridge_heartbeats", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "bh_compcode", limit: 12, default: "", null: false
    t.string "bh_device_sn", limit: 50, default: "", null: false
    t.datetime "bh_last_seen", precision: nil, null: false
    t.string "bh_bridge_version", limit: 20, default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trn_issue_amounts", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ia_compcode", limit: 12, default: "", null: false
    t.string "ia_code", limit: 10, default: "", null: false
    t.string "ia_staff_id", limit: 3, default: "", null: false
    t.date "ia_date", null: false
    t.string "ia_amount", limit: 10, default: "", null: false
    t.string "ia_type", limit: 3, default: "", null: false
    t.string "ia_remarks", limit: 50, default: "", null: false
  end

  create_table "trn_login_data", charset: "latin1", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "ad_compcode", limit: 30, null: false
    t.string "ad_event", limit: 50, null: false
    t.string "ad_module", limit: 100, default: "", null: false
    t.string "ad_description", limit: 100, null: false
    t.date "ad_date", null: false
    t.string "ad_time", limit: 30, default: "", null: false
    t.string "ad_user", limit: 50, null: false
    t.string "ad_ip", limit: 55, null: false
    t.string "ad_device_id", limit: 150, default: "", null: false
    t.string "ad_path", limit: 150, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trn_member_attendances", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "att_compcode", limit: 12, default: "", null: false
    t.string "att_member_id", limit: 4, default: "", null: false
    t.string "att_device_user_id", limit: 4, default: "", null: false
    t.string "att_device_sn", limit: 50, default: "", null: false
    t.datetime "att_punch_time", precision: nil, null: false
    t.date "att_punch_date", null: false
    t.string "att_status", limit: 25, default: "", null: false
    t.string "att_reason", limit: 50, default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trn_member_biometric_mappings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "mbm_compcode", limit: 12, default: "", null: false
    t.string "mbm_member_id", limit: 4, default: "", null: false
    t.string "mbm_device_user_id", limit: 4, default: "", null: false
    t.string "mbm_device_sn", limit: 50, default: "", null: false
    t.string "mbm_is_active", limit: 3, default: "", null: false
    t.text "mbm_finger_template", size: :long
    t.integer "mbm_uid"
  end

  create_table "trn_member_subscriptions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "ms_compcode", limit: 12, default: "", null: false
    t.string "ms_sbscrptn_no", limit: 8, default: "", null: false
    t.string "ms_member_id", limit: 5, default: "", null: false
    t.string "ms_plan_id", limit: 5, default: "", null: false
    t.date "ms_start_date", null: false
    t.date "ms_end_date", null: false
    t.string "ms_amount_paid", limit: 10, default: "", null: false
    t.string "ms_payment_mode", limit: 25, default: "", null: false
    t.string "ms_status", limit: 10, default: "", null: false
    t.string "ms_remarks", limit: 25, default: "", null: false
    t.string "ms_plan_amount", limit: 9, default: "", null: false
    t.string "ms_discount_amount", limit: 9, default: "", null: false
    t.string "ms_final_amount", limit: 9, default: "", null: false
    t.decimal "ms_open_amount", precision: 10, scale: 2
    t.date "ms_open_end_date"
    t.integer "ms_open_duration_days"
    t.integer "ms_skip_due_check", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trn_payments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "pay_compcode", limit: 12, default: "", null: false
    t.string "pay_no", limit: 10, default: "", null: false
    t.string "pay_ref_type", limit: 20, default: "", null: false
    t.string "pay_ref_id", limit: 5, default: "", null: false
    t.date "pay_date", null: false
    t.string "pay_amount", limit: 10, default: "", null: false
    t.string "pay_mode", limit: 10, default: "", null: false
    t.string "pay_remarks", limit: 50, default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trn_reminder_logs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "rl_compcode", limit: 12, default: "", null: false
    t.integer "rl_member_id", null: false
    t.integer "rl_subscription_id", null: false
    t.date "rl_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trn_renewal_requests", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "rr_compcode", limit: 12, default: "", null: false
    t.string "rr_member_id", limit: 5, null: false
    t.string "rr_plan_id", limit: 5, null: false
    t.string "rr_status", limit: 15, default: "PENDING", null: false
    t.decimal "rr_amount", precision: 10, scale: 2
    t.string "rr_channel", limit: 20, default: "MOBILE_APP", null: false
    t.string "rr_payment_provider", limit: 20
    t.string "rr_provider_order_id", limit: 64
    t.string "rr_provider_payment_id", limit: 64
    t.datetime "rr_requested_at", null: false
    t.datetime "rr_resolved_at"
    t.string "rr_resolved_by", limit: 10
    t.string "rr_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rr_compcode", "rr_member_id"], name: "index_trn_renewal_requests_on_rr_compcode_and_rr_member_id"
    t.index ["rr_status"], name: "index_trn_renewal_requests_on_rr_status"
  end

  create_table "trn_stock_inventories", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "si_compcode", limit: 12, default: "", null: false
    t.string "si_entry_no", limit: 8, default: "", null: false
    t.date "si_entry_date", null: false
    t.string "si_stock_id", limit: 3, default: "", null: false
    t.string "si_trans_type", limit: 3, default: "", null: false
    t.string "si_quantity", limit: 10, default: "", null: false
    t.string "si_remarks", limit: 50, default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trn_user_accesses", charset: "latin1", force: :cascade do |t|
    t.integer "ua_userid", null: false
    t.string "ua_compcode", limit: 30, null: false
    t.string "ua_heading", limit: 120, default: "", null: false
    t.string "ua_subheading", limit: 120, default: "", null: false
    t.string "ua_formname", limit: 120, null: false
    t.string "ua_action", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trn_user_rights", charset: "latin1", force: :cascade do |t|
    t.string "ur_compcode", limit: 30, null: false
    t.string "ur_formname", null: false
    t.string "ur_controller", null: false
    t.integer "ur_user", null: false
    t.string "ur_rights", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "trn_verify_otps", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "vo_compcode", limit: 12, default: "", null: false
    t.string "vo_phone", limit: 15, null: false
    t.string "vo_code_digest", null: false
    t.string "vo_purpose", limit: 20, default: "login", null: false
    t.datetime "vo_expires_at", null: false
    t.integer "vo_attempts", default: 0, null: false
    t.datetime "vo_consumed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vo_expires_at"], name: "index_trn_verify_otps_on_vo_expires_at"
    t.index ["vo_phone", "vo_purpose"], name: "index_trn_verify_otps_on_vo_phone_and_vo_purpose"
  end

  create_table "trn_whatsapp_inbox", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "wi_compcode", limit: 12, default: "SF", null: false
    t.string "wi_from_number", limit: 15, null: false
    t.string "wi_member_name", limit: 100
    t.string "wi_message_type", limit: 20, default: "text"
    t.text "wi_body"
    t.string "wi_media_url", limit: 500
    t.string "wi_wamid", limit: 200
    t.datetime "wi_received_at", precision: nil, null: false
    t.integer "wi_replied", limit: 1, default: 0
    t.datetime "wi_replied_at", precision: nil
    t.string "wi_replied_by", limit: 50
    t.text "wi_reply_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "wi_direction", limit: 3, default: "IN", null: false
    t.string "wi_status", limit: 20
    t.datetime "wi_seen_at", precision: nil
    t.string "wi_error", limit: 250
    t.string "wi_reaction_to", limit: 200
    t.index ["wi_from_number"], name: "idx_from_number"
    t.index ["wi_reaction_to"], name: "idx_wa_inbox_reaction_to"
    t.index ["wi_received_at"], name: "idx_received_at"
  end

  create_table "trn_whatsapp_logs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "wl_compcode", limit: 12, default: "", null: false
    t.string "wl_member_id", limit: 4
    t.string "wl_subscription_id", limit: 4
    t.string "wl_template_name", limit: 100
    t.datetime "wl_sent_at", precision: nil
    t.string "wl_status", limit: 20
    t.text "wl_api_response"
    t.string "wl_interakt_msg_id", limit: 128
    t.datetime "wl_delivered_at", precision: nil
    t.datetime "wl_read_at", precision: nil
    t.string "wl_failed_reason", limit: 250
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "wl_message_body"
  end

  create_table "users", charset: "latin1", force: :cascade do |t|
    t.string "username", limit: 50, null: false
    t.string "userpassword", limit: 500, null: false
    t.string "firstname", limit: 60, default: "", null: false
    t.date "userdate", null: false
    t.string "lastname", limit: 60, default: "", null: false
    t.string "usercompcode", limit: 60, null: false
    t.string "userlocation", limit: 30, default: "", null: false
    t.string "userimage", limit: 100, default: "", null: false
    t.string "usertype", limit: 30, default: "", null: false
    t.string "designation", null: false
    t.string "useraadhar", limit: 20, default: "", null: false
    t.string "listmodule", limit: 400, default: "", null: false
    t.string "phonenumber", limit: 11, default: "0", null: false
    t.string "email", limit: 80, default: "0", null: false
    t.string "userstatus", limit: 1, default: "Y", null: false
    t.string "userotpnumber", limit: 7, default: "", null: false
    t.string "sewadarcode", limit: 30, default: "", null: false
    t.string "sewdepart", null: false
    t.string "zonecode", limit: 50, default: "", null: false
    t.string "branchcode", limit: 50, default: "", null: false
    t.string "userdashboard", limit: 50, default: "", null: false
    t.integer "ecmember", default: 0, null: false
    t.string "suportstfdeparment", limit: 50, default: "", null: false
    t.string "approvalby", limit: 20, default: "", null: false
    t.string "managetype", default: "", null: false
    t.string "loginfirsttime", limit: 1, default: "N", null: false
    t.string "specialpermission", default: "", null: false
    t.string "profileid", limit: 5, default: "", null: false
    t.string "landing_pagemodule", limit: 12, default: "", null: false
    t.string "allowhrparameter", limit: 30, default: "", null: false
    t.integer "faculty", null: false
    t.float "petty_cash_ob", limit: 53, default: 0.0, null: false
    t.float "petty_cash_cb", limit: 53, default: 0.0, null: false
    t.date "ob_with_effective_from", null: false
    t.string "departCode", limit: 25, default: "", null: false
    t.string "appversion", limit: 10, default: "1.0.0", null: false
    t.string "userlanguage", limit: 50, default: "", null: false
    t.string "exp_department", limit: 200, default: "", null: false
    t.string "exp_venue", limit: 150, default: "", null: false
    t.string "usercategory", default: "", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

end
