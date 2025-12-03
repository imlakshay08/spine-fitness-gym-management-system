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

ActiveRecord::Schema[7.1].define(version: 2025_12_01_102313) do
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
  end

  create_table "mst_membership_plans", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "plan_compcode", limit: 12, default: "", null: false
    t.string "plan_name", limit: 25, default: "", null: false
    t.string "plan_duration_days", limit: 3, default: "", null: false
    t.string "plan_amount", limit: 8, default: "", null: false
    t.string "plan_description", limit: 50, default: "", null: false
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

  create_table "mst_stock_lists", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sl_compcode", limit: 12, default: "", null: false
    t.string "sl_name", limit: 25, default: "", null: false
    t.string "sl_descp", limit: 75, default: "", null: false
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

  create_table "trn_member_subscriptions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
