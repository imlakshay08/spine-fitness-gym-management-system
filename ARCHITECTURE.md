# Spine Fitness — Architecture Document

A production gym management system used by a real gym in Dwarka, New Delhi. Manages 200+ members, biometric attendance, automated WhatsApp reminders, payments, and physical gate access via a fingerprint device.

This document is the on-ramp for anyone touching the codebase for the first time. It covers stack, database, code conventions, the modules in play, and the (many) places this codebase intentionally deviates from textbook Rails.

---

## 1. System Architecture Overview

### 1.1 Tech Stack

| Layer | Technology / Version |
|---|---|
| Language | Ruby **3.1.4** |
| Web framework | Rails **7.1.3+** (`config.load_defaults 5.1` — kept on Rails 5.1 defaults) |
| Database | **MySQL 9.4** (Railway `mysql:9.4` image) via `mysql2 ~> 0.5` |
| App server | **Puma** (>= 5.0) |
| Frontend templating | ERB |
| JS framework | **jQuery + Bootstrap 5** (Hotwire gems present but not used in views) |
| JS delivery | Sprockets + Importmap (legacy `public/assets/...` files in practice) |
| AJAX | `$.ajax` (per-page JS files in [public/assets/js/package/](public/assets/js/package/)) |
| PDF | `prawn ~> 1.2.1` + `prawn-table ~> 0.1.0` |
| Sessions | Cookie store (`_ihm_session`, 30-day TTL) + `activerecord-session_store` gem available |
| HTTP client | `rest-client`, `faraday`, `Net::HTTP` (mixed) |
| Background jobs | `ActiveJob` with **`:async` adapter** (in-process, no Redis/Sidekiq) |
| Pagination | `will_paginate ~> 3.3` |
| Biometric bridge | Python 3 + `pyzk` + Flask (separate repo dir [biometric_bridge/](biometric_bridge/)) |
| WhatsApp | Meta WhatsApp Cloud API (direct HTTPS, no SDK) |

### 1.2 Hosting & Infrastructure

```
┌────────────────────────────────────────────────────────────────────────┐
│                      Public internet (HTTPS)                            │
└────────────────────────────────────────────────────────────────────────┘
              │                                       │
              ▼                                       ▼
       ┌──────────────┐                       ┌──────────────────┐
       │  Cloudflare  │                       │   cron-job.org   │
       │      ↓       │                       │  6 schedules,    │
       │   Railway    │◄──── hits /cron/* ────│  every 15 min →  │
       │ (Rails app)  │                       │  monthly         │
       │  Puma + Ruby │                       └──────────────────┘
       └──────┬───────┘
              │ mysql2 (private network, same Railway project)
              ▼
       ┌──────────────┐         ┌────────────────────────────┐
       │   Railway    │         │ Meta WhatsApp Cloud API     │
       │    MySQL     │         │ graph.facebook.com/v19.0    │
       │ mysql-volume │         └──────────────┬──────────────┘
       └──────────────┘
                                               │ webhook
              ▲                                ▼
              │                       /webhooks/meta (Rails)
              │ POST /api/biometric_attendances
              │
       ┌──────┴────────────────────────┐
       │  Python bridge (gym laptop)    │
       │  bridge.py + enroll_api.py     │
       │  sync_access.py (nightly)      │
       └──────┬─────────────────────────┘
              │ pyzk over LAN
              ▼
       ┌──────────────────────┐
       │ ZKTeco fingerprint   │
       │ device <LAN address> │
       │ + door relay         │
       └──────────────────────┘
```

- **Web tier:** single Puma process on **Railway** (built by Nixpacks — see [nixpacks.toml](nixpacks.toml)), served through **Cloudflare**. Because Cloudflare and Railway both sit in front of Rails, `request.remote_ip` is the real client IP for external callers but the gym bridge appears on a rotating set of addresses in one `/24`.
- **Database:** **MySQL 9.4 running as a second Railway service** in the same project, backed by a persistent `mysql-volume`. Two ways in:
  - **Private:** `mysql.railway.internal` (IPv4 + IPv6) — how the Rails service connects, over Railway's internal network.
  - **Public TCP proxy:** `zephyr.proxy.rlwy.net:31443 → 3306` — how TablePlus connects from a laptop. This means **the database is reachable from the public internet**, with the MySQL credentials as the only thing in front of it. Convenient for the hand-run SQL in [db/manual/](db/manual/); worth deleting from the service's Networking settings when it is not actively needed.

  The app's own connection env vars are still named `MYSQL_ADDON_HOST` / `PORT` / `USER` / `PASSWORD` / `DB` — that prefix is CleverCloud's convention, left over from an earlier host. The names are legacy; the values point at Railway. Railway also injects `MYSQLHOST` / `MYSQLUSER` / `MYSQLPASSWORD` / `MYSQLPORT` / `MYSQLDATABASE` and `MYSQL_URL`, which the app does not read.
- **Backups:** Railway's Backups tab on the MySQL service. This is the only backup mechanism — there is no application-level dump.
- **Local development:** uses `127.0.0.1:3306` MySQL, `database: spinefitness_bckup5` for both dev and test ([config/database.yml](config/database.yml)). Both dev and production connect with `encoding: utf8mb4` — `utf8` maps to utf8mb3 and silently drops 4-byte emoji arriving from WhatsApp.
- **Cron:** external service [cron-job.org](https://cron-job.org) hits six endpoints with a `?token=…` URL parameter (validated against `ENV['CRON_SECRET']` in constant time):

  | Endpoint | Schedule (IST) |
  |---|---|
  | `/cron/send_expiry_whatsapp` | daily 10:00 |
  | `/cron/send_owner_daily_report` | daily 22:30 |
  | `/cron/send_owner_monthly_report` | 1st of month 09:00 |
  | `/cron/check_biometric` | every 15 minutes |
  | `/cron/send_staff_weekly` | Monday 12:00 |
  | `/cron/sync_subscription_status` | **not scheduled — see §5** |

  cron-job.org schedules are entered in **UTC**. The report and alert endpoints run their job with `perform_now` and return the outcome in the response body, so the cron service's execution log records whether the message was actually sent — an earlier version used `perform_later` and failed silently for a week.
- **Background jobs:** ActiveJob queue adapter is `:async`, so `perform_later` runs in-process on the Puma worker. There is **no Sidekiq/Redis** — see [config/application.rb:16](config/application.rb#L16).

### 1.3 External Integrations & APIs

| Integration | Direction | Where |
|---|---|---|
| **Meta WhatsApp Cloud API** | Outbound (Rails → Meta) | [app/services/meta/send_whatsapp.rb](app/services/meta/send_whatsapp.rb) |
| **Meta webhooks** | Inbound (Meta → Rails) | [app/controllers/webhooks/meta_controller.rb](app/controllers/webhooks/meta_controller.rb) — receives `DELIVERED`/`READ`/`FAILED` status updates |
| **Interakt API** (legacy) | Outbound | [app/services/interakt/send_whatsapp.rb](app/services/interakt/send_whatsapp.rb) — kept for reference, no longer used |
| **Interakt webhooks** (legacy) | Inbound | [app/controllers/webhooks/interakt_controller.rb](app/controllers/webhooks/interakt_controller.rb) |
| **CallMeBot** (legacy) | Outbound | [app/services/whatsapp_service.rb](app/services/whatsapp_service.rb) — early prototype, unused |
| **cron-job.org** | Inbound | `/cron/send_expiry_whatsapp`, `/cron/sync_subscription_status` |
| **Python bridge (LAN)** | Inbound | `/api/biometric_attendances`, `/api/biometric_mappings`, `/api/access_status` |
| **ZKTeco ADMS protocol** | Inbound | `/iclock/cdata`, `/iclock/getrequest` — alternative ingestion path if the device is configured to push directly. See [app/controllers/api/adms_controller.rb](app/controllers/api/adms_controller.rb). |
| ~~**Bunny.net storage**~~ (removed) | — | Was referenced by dead upload helpers with a hard-coded key. Deleted 2026-08-30; the gym product stores no photos. |

### 1.4 Environment Variables

Required for production:
- `MYSQL_ADDON_HOST`, `MYSQL_ADDON_PORT`, `MYSQL_ADDON_USER`, `MYSQL_ADDON_PASSWORD`, `MYSQL_ADDON_DB`
- `SECRET_KEY_BASE`
- `WHATSAPP_TOKEN`, `WHATSAPP_PHONE_ID`, `WHATSAPP_WEBHOOK_TOKEN`
- `CRON_SECRET`

Messaging (all have working defaults in code, so the app runs without them):
- `OWNER_WHATSAPP_NUMBERS` — comma list of `number:Name` pairs for the owner report
- `STAFF_ALERT_IDS` — `mst_staff_lists` ids that receive staff alerts (default `4,2`)
- `STAFF_ALERT_EXTRA` — comma list of `number:Name:role` for people not in the staff table. `role` is `staff` or `owner` and picks which set of recovery instructions the biometric alert carries; a number may appear once per role, so one person can receive both wordings.

Security switches — every one defaults to the permissive setting, so unsetting it is the rollback (see SECURITY_FIXES.md):
- `BIOMETRIC_API_TOKEN`, `BIOMETRIC_AUTH_ENFORCE`
- `CSRF_ENFORCE`
- `WHATSAPP_APP_SECRET` (enables Meta webhook signature checking)
- `FORCE_SSL`, `SECURE_COOKIES`, `CSP_ENFORCE`
- `DEVICE_SERIAL`, `DEVICE_SERIALS`

Legacy / optional:
- `INTERAKT_API_KEY`, `INTERAKT_WEBHOOK_ENABLED` (legacy, not required at runtime)
- `SESSION_CLEANUP_ON_BOOT` (set to `"true"` once after deploy to prune stale `sessions` rows)

---

## 2. Database Architecture

### 2.1 Naming Conventions

This is the **single most important convention** to learn — it touches every controller, every model, and every SQL statement.

**Tables are prefixed by purpose:**

| Prefix | Meaning | Examples |
|---|---|---|
| `mst_*` | **Master** — relatively static reference data | `mst_members_lists`, `mst_membership_plans`, `mst_staff_lists`, `mst_companies` |
| `trn_*` | **Transaction** — operational/event data | `trn_member_subscriptions`, `trn_member_attendances`, `trn_payments`, `trn_whatsapp_logs`, `trn_audit_trials` |
| (no prefix) | **System / framework** tables | `users`, `sessions`, `schema_migrations`, `ar_internal_metadata` |

**Columns are prefixed by a per-table short code**, not by Rails convention:

| Table | Column prefix | Example columns |
|---|---|---|
| `mst_members_lists` | `mmbr_` | `mmbr_code`, `mmbr_name`, `mmbr_contact`, `mmbr_compcode` |
| `mst_membership_plans` | `plan_` | `plan_name`, `plan_duration_months`, `plan_final_amount`, `plan_is_open` |
| `mst_staff_lists` | `stf_` | `stf_code`, `stf_name`, `stf_designation` |
| `mst_trainer_lists` | `trn_` | `trn_name`, `trn_speciality`, `trn_salary_amount` ⚠️ |
| `mst_stock_lists` | `sl_` | `sl_name`, `sl_descp` |
| `mst_companies` | `cmp_` | `cmp_companycode`, `cmp_companyname` |
| `trn_member_subscriptions` | `ms_` | `ms_sbscrptn_no`, `ms_member_id`, `ms_plan_id`, `ms_start_date`, `ms_end_date` |
| `trn_member_attendances` | `att_` | `att_member_id`, `att_punch_time`, `att_status` |
| `trn_member_biometric_mappings` | `mbm_` | `mbm_member_id`, `mbm_device_user_id`, `mbm_finger_template` |
| `trn_payments` | `pay_` | `pay_no`, `pay_ref_type`, `pay_ref_id`, `pay_amount`, `pay_mode` |
| `trn_whatsapp_logs` | `wl_` | `wl_member_id`, `wl_template_name`, `wl_status` |
| `trn_audit_trials` | `ad_` | `ad_event`, `ad_module`, `ad_description` |
| `trn_user_accesses` | `ua_` | `ua_userid`, `ua_compcode`, `ua_formname`, `ua_action` |
| `trn_issue_amounts` | `ia_` | `ia_staff_id`, `ia_amount`, `ia_type` |
| `trn_stock_inventories` | `si_` | `si_stock_id`, `si_trans_type`, `si_quantity` |

⚠️ Heads-up: `mst_trainer_lists` uses the `trn_` column prefix, which collides visually with the `trn_*` *table* prefix. The prefix here means "trainer", not "transaction".

**Why prefixes?** This is a legacy convention inherited from an earlier ERP product (`ErpModule::Common`, originally written for "IHM"). It predates Rails conventions in the codebase. The benefit: every column reveals its table at a glance in raw SQL, which is useful given the heavy use of hand-built `where(...)` strings.

### 2.2 Multi-Tenancy

This codebase is built as **multi-tenant by company code**, even though the production deployment hosts only one tenant (Spine Fitness, `compcode = "SF"`).

- Almost every table has a `*_compcode` column.
- Every query in every controller filters by `session[:loggedUserCompCode]`.
- There are **no foreign keys** in the database. Tenancy and joins are enforced **in application code only**.
- The `mst_companies` row defines a tenant. `users.usercompcode` ties a user to a tenant; on login the value is stored in `session[:loggedUserCompCode]` ([app/controllers/login_controller.rb:33](app/controllers/login_controller.rb#L33)).

### 2.3 Tables

#### Master tables (`mst_*`)

| Table | Purpose | Key columns |
|---|---|---|
| `mst_companies` | Tenants (one row per gym/company). Holds branding, GST, address, signature, settings flags. | `cmp_companycode` (unique), `cmp_companyname`, many `enum('Y','N')` flags |
| `mst_members_lists` | Gym members (the primary "customer" entity). | `mmbr_compcode`, `mmbr_code` (M00001…), `mmbr_name`, `mmbr_contact`, plus soft-delete columns `mmbr_status` (`A` on roll / `R` removed), `mmbr_removed_at`, `mmbr_removed_by`, `mmbr_remove_reason` |
| `mst_membership_plans` | Plan catalog (Monthly, Quarterly, Half-yearly, Yearly, Open). | `plan_name`, `plan_duration_months`, `plan_final_amount`, `plan_mrp_amount`, `plan_is_open` |
| `mst_staff_lists` | Gym staff (front desk, cleaners, etc). | `stf_code`, `stf_name`, `stf_designation` |
| `mst_trainer_lists` | Trainers (separated from staff because they have specialities & salary type). | `trn_name`, `trn_speciality`, `trn_salary_amount` |
| `mst_stock_lists` | Inventory items (equipment, supplements). | `sl_name`, `sl_descp` |
| `mst_list_modules` | Module registry — drives sidebar visibility per company. | `lm_modulecode`, `lm_modules`, `lm_status` |
| `mst_menu_entries` | Menu entry definitions for the user-rights system. | `me_menuname`, `me_controller_name`, `me_action_name` |
| `mst_category_lists`, `mst_faculties` | Inherited from the ERP base, **unused** in the gym product. |

#### Transaction tables (`trn_*`)

| Table | Purpose | Key columns |
|---|---|---|
| `trn_member_subscriptions` | A member's subscription period (start → end, plan, amount). One row per renewal. | `ms_sbscrptn_no` (SUB00001…), `ms_member_id`, `ms_plan_id`, `ms_start_date`, `ms_end_date`, `ms_status`, `ms_final_amount`, `ms_open_amount` (open-ended plans), `ms_skip_due_check` |
| `trn_payments` | Polymorphic payment ledger. | `pay_no` (PAY00001…), `pay_ref_type` (currently only `MEMBER_SUBSCRIPTION`), `pay_ref_id`, `pay_amount`, `pay_mode` (`cash`/`upi`/…) |
| `trn_member_attendances` | One row per gym entry/punch. | `att_member_id`, `att_device_user_id`, `att_punch_time`, `att_status` (`ALLOWED`/`DENIED`), `att_reason` |
| `trn_member_biometric_mappings` | Mapping between a member and a fingerprint device user, **plus** a backup of the finger template. | `mbm_member_id`, `mbm_device_user_id`, `mbm_device_sn`, `mbm_uid`, `mbm_finger_template` (`LONGTEXT` — JSON-encoded template), `mbm_is_active` |
| `trn_whatsapp_logs` | Full lifecycle log of every WhatsApp message sent. | `wl_member_id`, `wl_template_name`, `wl_status` (`QUEUED`→`DELIVERED`→`READ` or `FAILED`), `wl_interakt_msg_id` (re-used to hold the Meta `wamid`), `wl_sent_at`, `wl_delivered_at`, `wl_read_at`, `wl_failed_reason` |
| `trn_audit_trials` | Audit log for every save/update/delete across the app. | `ad_event`, `ad_module`, `ad_description`, `ad_user`, `ad_ip`, `ad_device_id`, `ad_path` |
| `trn_login_data` | Login audit (same shape as `trn_audit_trials`). |  |
| `trn_user_accesses` | Per-user, per-form action grants (`AD`/`ED`/`DL`/`PR`/`CL`/`VW`). | `ua_userid`, `ua_compcode`, `ua_formname`, `ua_action` (comma-list) |
| `trn_user_rights` | Companion to `trn_user_accesses` for finer-grained controls (defined but lightly used). |  |
| `trn_issue_amounts` | Cash/UPI issued **to staff** (treated like petty cash advance). | `ia_staff_id`, `ia_date`, `ia_amount`, `ia_type` |
| `trn_stock_inventories` | Stock in/out ledger. | `si_stock_id`, `si_trans_type` (`IN`/`OUT`), `si_quantity` |
| `trn_whatsapp_inbox` | Inbound WhatsApp messages, staff replies, media and emoji reactions — the data behind the `/whatsapp_inbox` conversation view. | `wi_direction` (`IN`/`OUT`), `wi_from`, `wi_body`, `wi_wamid`, `wi_reaction_to`, `wi_media_id`, `wi_media_mime`, `wi_reply_text`, `wi_seen_at`, `wi_removed_at` |
| `trn_bridge_heartbeats` | Last-seen ping from the Python bridge on the gym laptop. One row per device; drives the dashboard status pill and the outage watchdog. | `bh_compcode`, `bh_device_sn`, `bh_last_seen`, `bh_bridge_version` |
| `trn_renewal_requests` | **Unused.** Columns are shaped for an online renewal + payment-gateway flow (`rr_provider_order_id`, `rr_provider_payment_id`) that was never wired up — no model, no controller, no route references it. | — |
| `biometric_id_allocations` | Reserves device user ids so two enrollments cannot claim the same slot. | |
| `trn_reminder_logs` | Per-subscription reminder log (legacy; superseded by `trn_whatsapp_logs`). |  |

#### System tables

| Table | Purpose |
|---|---|
| `users` | Authenticated users (admin/staff). Passwords are **bcrypt** in `password_digest`, with the legacy MD5 `userpassword` column kept as the rollback path — each account upgrades on its next successful login (`using_bcrypt` flags which have). All password logic lives in `app/models/user.rb`. Includes `usercompcode` (tenant), `usertype`, `listmodule` (CSV of allowed modules), `landing_pagemodule`, plus dozens of fields inherited from the ERP base. |
| `sessions` | DB-backed session table from `activerecord-session_store`. Active session storage is the cookie store; this table is the older backup. The boot-time cleaner in [config/initializers/session_cleanup.rb](config/initializers/session_cleanup.rb) prunes rows older than 2 days when `SESSION_CLEANUP_ON_BOOT=true`. |
| `schema_migrations`, `ar_internal_metadata` | Rails internals. |

### 2.4 Relationships (Conceptual)

There are **no DB-level foreign keys**. Relationships exist only in queries. Conceptually:

```
mst_companies (cmp_companycode)
    ▲
    │ (compcode) every row, every table
    │
    ├── mst_members_lists ─┐
    │                       ├── trn_member_subscriptions ── trn_payments (pay_ref_type='MEMBER_SUBSCRIPTION')
    │                       ├── trn_member_attendances
    │                       ├── trn_member_biometric_mappings
    │                       ├── trn_whatsapp_logs
    │                       └── trn_reminder_logs
    │
    ├── mst_membership_plans ← trn_member_subscriptions.ms_plan_id
    ├── mst_staff_lists      ← trn_issue_amounts.ia_staff_id
    ├── mst_stock_lists      ← trn_stock_inventories.si_stock_id
    ├── mst_trainer_lists
    └── users (usercompcode) ← trn_audit_trials.ad_user, trn_user_accesses.ua_userid
```

All "foreign keys" are stored as `varchar(4)`/`varchar(5)` strings, **not integers**. The application casts them with `.to_i` / `.to_s` at join time.

### 2.5 Storage Engine

Most tables use **`ENGINE=MyISAM`** (not InnoDB). This is intentional and inherited from the ERP base. Consequences:
- No transactions across these tables.
- No row-level locking.
- No FK constraints (which is fine, because they aren't defined anywhere anyway).

`mst_companies`, `mst_list_modules`, `mst_menu_entries`, `sessions`, `trn_audit_trials`, `trn_user_accesses`, `trn_user_rights`, `users` use the default engine (InnoDB).

### 2.6 Code Generation Pattern

Business codes (`M00001`, `SUB00001`, `PAY00001`, `STF00001`, etc.) are **string-typed, zero-padded, generated in Ruby** — not by DB auto-increment. The shared helper:

```ruby
# app/helpers/global_code_generator.rb
include GlobalCodeGenerator
generate_code(table: MstMembersList, column: "mmbr_code", prefix: "M", compcode: "SF")
# => "M00042"
```

It finds the highest existing code for the tenant, increments, zero-pads to 5 digits. This is called inside the controller at save time. **It is not race-safe** — two simultaneous adds can produce the same code. In practice the app is single-tenant and single-admin, so collisions don't happen.

---

## 3. Code Structure & Conventions

### 3.1 Directory Layout

```
app/
├── controllers/
│   ├── application_controller.rb     # Giant base controller (~1100 lines)
│   ├── login_controller.rb           # Session create on POST /login
│   ├── logout_controller.rb
│   ├── dashboard_controller.rb       # Home screen — bulk-preload pattern
│   ├── member_list_controller.rb     # CRUD + profile + biometric mapping
│   ├── member_subscriptions_controller.rb
│   ├── membership_plan_controller.rb
│   ├── trn_payments_controller.rb    # Payment report
│   ├── staff_list_controller.rb
│   ├── trainer_list_controller.rb
│   ├── stock_list_controller.rb
│   ├── stock_inventory_controller.rb
│   ├── issue_amount_controller.rb    # Staff cash advance
│   ├── create_user_controller.rb     # User management
│   ├── change_password_controller.rb
│   ├── log_audit_controller.rb       # Audit-trail viewer
│   ├── company_controller.rb
│   ├── holiday_controller.rb
│   ├── house_list_controller.rb      # (legacy, unused)
│   ├── common_process_controller.rb  # Catch-all for misc AJAX
│   ├── cron_controller.rb            # Six endpoints called by cron-job.org
│   ├── whatsapp_logs_controller.rb   # Member message history + delivery stats
│   ├── whatsapp_inbox_controller.rb  # Two-way conversation view
│   ├── pages_controller.rb           # Privacy page
│   ├── concerns/
│   │   ├── bridge_authentication.rb  # Bearer token for /api/*, staged by env var
│   │   └── soft_csrf_protection.rb   # Staged CSRF
│   ├── api/
│   │   ├── biometric_attendances_controller.rb   # POST /api/biometric_attendances
│   │   ├── biometric_mappings_controller.rb      # POST /api/biometric_mappings (+ save_template)
│   │   ├── member_mappings_controller.rb         # GET /api/sync_needed, /api/device_audit
│   │   ├── bridge_heartbeats_controller.rb       # POST /api/bridge_heartbeat
│   │   ├── access_status_controller.rb           # GET /api/access_status
│   │   └── adms_controller.rb                    # /iclock/* for native ZK ADMS protocol
│   └── webhooks/
│       ├── meta_controller.rb        # Meta status webhook + inbound messages/media/reactions
│       └── interakt_controller.rb    # Legacy Interakt webhook
│
├── models/                           # Almost all are EMPTY class bodies
│   ├── application_record.rb
│   ├── mst_members_list.rb           # class MstMembersList < ApplicationRecord; end
│   ├── trn_member_subscription.rb
│   └── ... (mostly two-line stubs)
│
├── views/
│   ├── layouts/
│   │   ├── application.html.erb      # Master layout — loads all CSS/JS
│   │   ├── _header.html.erb
│   │   ├── _sidebar.html.erb         # Module navigation
│   │   ├── _breadcrumbs.html.erb
│   │   └── _footer.html.erb
│   ├── dashboard/index.html.erb      # Single screen with all KPIs
│   ├── member_list/{index, add_member, profile}.html.erb
│   ├── member_subscriptions/{index, add_member_subscriptions}.html.erb
│   └── ... (one folder per controller; usually index + an add_X form)
│
├── helpers/
│   ├── application_helper.rb         # Tiny — just plan_badge_color
│   ├── global_code_generator.rb      # ★ The code-generation module
│   ├── access_status_helper.rb
│   └── 100+ inherited stub helpers   # Most are empty placeholders from the ERP base
│
├── jobs/
│   ├── application_job.rb
│   ├── membership_expiry_whatsapp_job.rb   # Expiring / expired reminders
│   ├── subscription_receipt_whatsapp_job.rb # Receipt text + PDF on renewal
│   ├── owner_report_whatsapp_job.rb        # Daily + monthly owner report
│   ├── staff_alert_whatsapp_job.rb         # Biometric alert + Monday list
│   └── sync_subscription_status_job.rb     # ⚠ deliberately unscheduled — see §5
│
├── services/
│   ├── whatsapp_templates.rb         # ★ Single source of truth for all templates
│   ├── meta/send_whatsapp.rb         # ★ Active WhatsApp sender (Meta Cloud API)
│   ├── alerts/
│   │   ├── gym_clock.rb              # Opening hours — alerts only fire when open
│   │   ├── biometric_watch.rb        # Bridge liveness + per-audience instructions
│   │   └── staff_digest.rb           # Monday absentee / data-quality split
│   ├── reports/
│   │   ├── gym_report_base.rb        # Shared IST date maths and member sets
│   │   ├── daily_gym_report.rb
│   │   ├── monthly_gym_report.rb
│   │   ├── gym_report_pdf.rb
│   │   └── staff_followup_pdf.rb
│   ├── receipts/subscription_receipt_pdf.rb
│   ├── interakt/send_whatsapp.rb     # Legacy Interakt sender
│   ├── subscription_reminder.rb      # Legacy reminder service (CallMeBot)
│   └── whatsapp_service.rb           # Legacy (CallMeBot)
│
└── pdfs/                             # Empty — Prawn classes live in services/reports and services/receipts

db/
└── manual/                           # Hand-run SQL for production, applied via TablePlus.
                                      # Schema changes are NOT applied by `rails db:migrate`
                                      # on the server; each file here has been run by hand.

lib/
└── erp_module/
    └── common.rb                     # Mixed-in to ApplicationController; ~320 lines of getters

config/
├── routes.rb                         # 17 sequential Rails.application.routes.draw blocks
├── application.rb                    # Sets queue_adapter = :async
├── database.yml
└── initializers/
    ├── session_store.rb              # cookie store, _ihm_session
    └── session_cleanup.rb            # boot-time prune

biometric_bridge/                     # Python — runs on the gym laptop
├── bridge.py
├── config.py
└── requirements.txt

public/assets/                        # All third-party CSS/JS lives here, not in app/assets
├── css/
├── js/
│   └── package/                      # One JS file per controller (page-scoped)
└── plugins/                          # jQuery, Bootstrap, DataTables, Select2, Croppie, Flatpickr, …
```

### 3.2 Controller Pattern

Every CRUD controller follows the **same template**:

```ruby
include GlobalCodeGenerator

class XListController < ApplicationController
  before_action      :require_login
  before_action      :get_user_access_permissions
  skip_before_action :verify_authenticity_token       # ★ CSRF disabled

  def index               # list page
    @compcodes = session[:loggedUserCompCode]
    @x_list    = get_x_list
    # ...
  end

  def add_x              # the new/edit form (singular)
    @compcodes = session[:loggedUserCompCode]
    @Lastcode  = generate_code(table: MstX, column: "x_code", prefix: "X", compcode: @compcodes)
    @x = params[:id].to_i > 0 ? MstX.where("x_compcode=? AND id=?", @compcodes, params[:id]).first : nil
  end

  def ajax_process       # ★ Dispatcher for all AJAX calls
    if params[:identity] == 'SAVEX'
      create; return
    elsif params[:identity] == 'BIRTHCALC'
      get_birth_date_calculation; return
    end
  end

  def create             # called from ajax_process — renders JSON
    # validations as if/elsif chains writing to `message` and `isFlags`
    # success → ModelClass.new(x_params).save / .update
    # both paths: respond_to { |f| f.json { render json: { message:, status: isFlags } } }
  end

  def destroy
    obj = MstX.where("x_compcode=? AND id=?", @compcodes, params[:id]).first
    obj.destroy if obj
    redirect_to "#{root_url}x_list"
  end

  def referesh_x_list    # ★ Typo "referesh" is intentional & used throughout
    session[:req_x_list] = nil
    redirect_to "#{root_url}x_list"
  end

  private
  def x_params
    params[:x_compcode] = session[:loggedUserCompCode]
    params.permit(:x_compcode, :x_code, :x_name, ...)
  end
end
```

Things to notice:
- **`ajax_process` action** receives every AJAX call, dispatched by a `params[:identity]` string code (`'SAVEX'`, `'BIRTHCALC'`, `'FILLENDDATE'`, …). It's a hand-rolled action router.
- **JSON responses are hand-built** as plain hashes — no Jbuilder, no serializers.
- **Validations are if/elsif chains** in the controller, writing to a `message` string and an `isFlags` boolean. There is no `validates :name, presence: true` anywhere.
- **No `where(field: value)` style for filters** — most lookups build raw SQL fragments: `iswhere = "x_compcode='#{@compcodes}'"` then `Model.where(iswhere)`. **Search filters are string-interpolated into SQL.** (See `Non-Standard Conventions`.)
- The **`referesh_x_list`** action clears search session keys. It's spelled "referesh" everywhere; treat it as a project word.
- Controllers re-read `session[:loggedUserCompCode]` into `@compcodes` at the top of every action. There is no `current_company` / `set_compcode` before-action.

### 3.3 Model Pattern

Almost every model is **a two-line stub**:

```ruby
# app/models/mst_members_list.rb
class MstMembersList < ApplicationRecord
end
```

- **No associations** (`has_many`, `belongs_to`) are declared anywhere.
- **No validations.**
- **No scopes.**
- **No callbacks.**

Joins, scoping, and business rules all live in controllers. The model files exist primarily to map Rails class names (`MstMembersList`) to legacy table names (`mst_members_lists`) by virtue of Rails' standard pluralization (which happens to work here).

### 3.4 Business Logic Organisation

Business logic is split unevenly:

1. **`ApplicationController` ([app/controllers/application_controller.rb](app/controllers/application_controller.rb)) — ~1100 lines.** Holds:
   - `current_user`, `require_login`, `menu_access_allowed`, `global_user_access_list` (permissions)
   - Audit logging: `process_request_log_data`, `process_login_log_data`
   - Date/time helpers: `get_local_dated`, `get_local_time`, `formatted_date`, `check_global_date_difference`, `get_total_days_of_month`
   - File handling: `process_files`, `process_files_pos`, `process_storage_to_bunny`, `bunny_delete_storage_file`
   - Dozens of `get_X_detail(id)` lookup helpers (`get_member_detail`, `get_plan_detail`, `get_stock_detail`, `get_latest_subscription`, …) — all exposed via `helper_method`

2. **`ErpModule::Common` ([lib/erp_module/common.rb](lib/erp_module/common.rb)) — ~320 lines.** Included into `ApplicationController`. Inherited from the legacy ERP product. Most methods reference tables/models that **don't exist in this app** (`MstStdntFamily`, `MstFeeList`, `MstQualification`, …). Treated as dead code but kept for the few methods that *are* used.

3. **Controller actions.** All actual gym logic — subscription end-date calculation, partial-payment due tracking, biometric attendance acceptance — lives in the per-controller `create` / `index` actions and small private methods within them.

4. **Service objects.** Originally only for outbound integrations; since the 2026-08 messaging work they also hold the report and alert logic, which is the one part of the app written in a modern idiom.
   - [app/services/meta/send_whatsapp.rb](app/services/meta/send_whatsapp.rb) — `send_template(phone:, template:, body_values:, document:)`, `upload_media`
   - [app/services/whatsapp_templates.rb](app/services/whatsapp_templates.rb) — **single source of truth** for all six templates: wording, label, icon, parameter order. The sender and the WhatsApp Logs screen both read from it so they cannot drift. `INTERNAL` lists the templates that are not member correspondence (owner reports, staff alerts) and are therefore hidden from the logs screen.
   - `app/services/reports/` — `GymReportBase` (shared IST date maths and member sets), `DailyGymReport`, `MonthlyGymReport`, `GymReportPdf`, `StaffFollowupPdf`
   - `app/services/alerts/` — `GymClock` (when the gym is open: 06:30–11:30 and 17:00–21:30 IST, **mornings only on Sunday**; it is the sole gate on whether an outage alert fires, and it resolves everything in IST so the day-of-week is never decided by the caller's zone), `BiometricWatch` (is the bridge alive, and what should each audience do about it), `StaffDigest` (the Monday absentee/data-quality split)
   - [app/services/receipts/subscription_receipt_pdf.rb](app/services/receipts/subscription_receipt_pdf.rb)
   - Legacy, unused: `interakt/send_whatsapp.rb`, `whatsapp_service.rb`, `subscription_reminder.rb` (CallMeBot era)

5. **Jobs (scheduled batch work).** All are invoked with `perform_now` from `CronController` so the outcome reaches the cron service's log.
   - [app/jobs/membership_expiry_whatsapp_job.rb](app/jobs/membership_expiry_whatsapp_job.rb) — "expiring in 3 days" and "expired" reminders
   - [app/jobs/subscription_receipt_whatsapp_job.rb](app/jobs/subscription_receipt_whatsapp_job.rb) — receipt text + PDF, fired on subscription create/renew
   - [app/jobs/owner_report_whatsapp_job.rb](app/jobs/owner_report_whatsapp_job.rb) — daily and monthly owner reports
   - [app/jobs/staff_alert_whatsapp_job.rb](app/jobs/staff_alert_whatsapp_job.rb) — biometric outage alert and the Monday list; resolves recipients from `mst_staff_lists` plus `STAFF_ALERT_EXTRA`
   - [app/jobs/sync_subscription_status_job.rb](app/jobs/sync_subscription_status_job.rb) — flips `ms_status` `ACTIVE` → `EXPIRED`. **Not scheduled on purpose** — see §5.

**Prawn 1.2.1 caveat:** only the built-in AFM fonts are available, and `normalize_encoding` silently rewrites any character outside WinAnsi to `_`. The rupee sign `₹` is one of them, so every PDF and message writes `Rs.` instead. `·`, `—` and `•` are safe.

### 3.5 Frontend Stack & Patterns

**No Webpacker, no JS bundler in active use.** All assets are pre-built and served from [public/assets/](public/assets/).

- **CSS:** Bootstrap 5 + a custom "spine-dark" theme overlay ([public/assets/css/dark-theme.css](public/assets/css/dark-theme.css)). Material Design Lite is also loaded but mostly unused.
- **JS plugins:** jQuery, Bootstrap, DataTables, Select2, Flatpickr, Croppie, Summernote, Morris, ApexCharts, FullCalendar, Toastr, jquery-toast, jquery-blockUI. All loaded globally on every page that isn't `/login`.
- **Per-page JS:** [public/assets/js/package/](public/assets/js/package/) has one file per controller (`member_list.js`, `member_subscriptions.js`, `dashboard_liv.js`, …). The layout auto-loads it by controller name via:
  ```erb
  <script src="<%=root_url%>assets/js/package/<%=page_linked%>.js?v=<%= Time.now.to_i %>"></script>
  ```
  where `page_linked` returns the controller name (with one rename: `dashboard` → `dashboard_liv`). The cache-buster query string means **JS is re-downloaded on every page load**.
- **AJAX style:** Form submissions go through `ajax_process` with `identity: '…'` markers. Responses are JSON; client-side JS updates the DOM and shows a Toastr/jquery-toast notification.

---

## 4. Feature Modules

Modules roughly map 1-to-1 with controllers and sidebar items.

| Module | Controller | Purpose |
|---|---|---|
| **Dashboard** | `dashboard` | Single-screen home: active/expiring/expired counts, today's collection, due-payments list, live attendance feed (refreshed via `ajax_process?identity=GET_LIVE_ATTENDANCE` every few seconds). |
| **Members List** | `member_list` | Member CRUD. The `profile` action is the per-member view: subscription history, payments, biometric mapping status, attendance counters, "Add subscription" / "Edit member" / "Enroll fingerprint" actions. |
| **Membership Plans** | `membership_plan` | Plan catalog. Supports **open plans** (`plan_is_open=1`) where the end date and amount are entered per subscription rather than computed from duration. |
| **Member Subscriptions** | `member_subscriptions` | Subscription CRUD. On save, creates a paired row in `trn_payments` for the initial payment. End date is calculated from the plan duration (`start.advance(months: plan_duration_months) - 1.day`) unless the plan is open. Has a "renew" mode that prefills the form from the latest subscription. |
| **Member Payments** | `trn_payments` | Payment reports — date range, plan filter, mode filter (cash/UPI/other), plan-wise breakdown, summary cards. View-only. |
| **Staff List** | `staff_list` | Staff CRUD. |
| **Trainers List** | `trainer_list` | Trainer CRUD with speciality, certification, salary type. |
| **Stock List** | `stock_list` | Inventory item master. |
| **Stock Inventory** | `stock_inventory` | Stock IN/OUT transactions. Current stock per item = `Σ IN − Σ OUT`, computed in `ApplicationController#get_current_stock`. |
| **Issue Amount** | `issue_amount` | Cash/UPI issued **to staff** with a running staff-balance ledger (`/issue_amount/staff_balance`). |
| **Holiday** | `holiday` | Holiday calendar (lightly used). |
| **Create User / Change Password** | `create_user`, `change_password` | User admin. |
| **Log Audit** | `log_audit` | Browse `trn_audit_trials`. |
| **Company** | `company` | Tenant settings (logo, signature, declaration text). |
| **WhatsApp Logs** | `whatsapp_logs` | Member communication history with delivery status, filters and summary cards. Two guards keep internal traffic out: the `WhatsappTemplates::INTERNAL` name list, and a structural `wl_member_id IS NOT NULL` check — every member message records a member id and nothing internal does, so a template rename cannot leak owner reports or staff alerts onto the screen again. |
| **WhatsApp Inbox** | `whatsapp_inbox` | Two-way conversation view. Merges inbound messages, staff replies and automated sends into one IST-ordered timeline; polls every 5s; renders images, video, audio, documents, stickers and reactions; enforces Meta's 24-hour customer service window before allowing a free-form reply. |
| **Cron endpoints** | `cron` | Six token-gated endpoints — see §1.2 for the schedule table. |
| **Biometric API** | `api/biometric_attendances`, `api/biometric_mappings`, `api/access_status` | The contract with the Python bridge. |
| **ADMS endpoint** | `api/adms` | Native ZKTeco "ADMS" push protocol fallback at `/iclock/cdata`. |
| **Webhooks** | `webhooks/meta`, `webhooks/interakt` | Inbound WhatsApp delivery-status events. |

### Connections between modules

```
                            ┌────────────────┐
                            │ Membership     │
                            │ Plans          │
                            └────────┬───────┘
                                     │ ms_plan_id
                                     ▼
   ┌──────────────┐         ┌──────────────────┐         ┌──────────────┐
   │ Members List ├────────►│ Subscriptions    ├────────►│  Payments    │
   └──────┬───────┘         │ (renewal cycle)  │         │ (ledger)     │
          │                 └────────┬─────────┘         └──────────────┘
          │                          │ ms_end_date trigger
          │                          ▼
          │                 ┌──────────────────┐
          │                 │ WhatsApp Job     │
          │                 │ (expiring/expired│──► trn_whatsapp_logs ◄── /webhooks/meta
          │                 └──────────────────┘
          │
          │ mbm_member_id
          ▼
   ┌──────────────────────────┐         ┌──────────────────────┐
   │ Biometric Mapping        │◄────────│ Python bridge        │
   │ (templates, device IDs)  │         │ (POST + GET sync)    │
   └──────────────┬───────────┘         └──────────┬───────────┘
                  │                                │ pyzk
                  ▼                                ▼
          ┌──────────────────┐            ┌──────────────────┐
          │ Attendances      │◄───────────│ ZKTeco device    │
          │ (ALLOWED/DENIED) │            │ (door relay)     │
          └──────────────────┘            └──────────────────┘
```

### Biometric flow in detail

1. **Enrollment:** Staff clicks "Enroll Fingerprint" on the member profile. The browser calls `localhost:5000/enroll` (Flask running on the gym laptop). Flask creates a device user via `pyzk`, the device prompts for finger scan, then Flask POSTs to `/api/biometric_mappings` to create the mapping, and `/api/biometric_mappings/save_template` to back up the template as JSON in `mbm_finger_template`.
2. **Punch:** [bridge.py](biometric_bridge/bridge.py) polls every 20s, dedupes locally (in-memory + `last_sent_keys.txt`), then POSTs each new punch to `/api/biometric_attendances`. Rails looks up the mapping → member → latest subscription, decides `ALLOWED` vs `DENIED`, and records `trn_member_attendances`. A second dedup layer (one punch per member per day) lives in [biometric_attendances_controller.rb:79](app/controllers/api/biometric_attendances_controller.rb#L79).
3. **Gate enforcement:** A nightly `sync_access.py` (referenced but not in this repo's source tree) calls `GET /api/access_status?compcode=SF&device_sn=...`. Rails returns each mapped user with `access: ALLOW|DENY` and (for restores) the saved template. The Python side deletes templates for `DENY` users on the device → device flashes red ✗ → door relay does not fire. When a member renews, the saved template is restored from the DB.
4. **ADMS alternative:** If the device is configured to push directly to `/iclock/cdata` (ZK's ADMS protocol), [adms_controller.rb](app/controllers/api/adms_controller.rb) parses the tab-delimited payload and does the same mapping/subscription/attendance logic. This path runs in parallel; deduplication in `process_attendance` prevents double records.

### WhatsApp flow in detail

```
cron-job.org  ─── GET /cron/send_expiry_whatsapp?token=... ──►  CronController
                                                                    │
                                                                    ▼
                              MembershipExpiryWhatsappJob.perform_later(:expiring)
                              MembershipExpiryWhatsappJob.perform_later(:expired)
                                                                    │
                                                  Selects subs with ms_end_date == today+3 (expiring)
                                                  or in [today-7, today-1]  (expired)
                                                                    │
                                                                    ▼
                                       Meta::SendWhatsapp.send_template(phone, template, body_values)
                                                                    │
                                                                    ▼
                                       trn_whatsapp_logs row: status=QUEUED, wl_interakt_msg_id=<wamid>
                                                                    │
                  POST /webhooks/meta   ◄────── Meta delivery events ──────
                                                                    │
                              status=DELIVERED → wl_delivered_at = NOW
                              status=READ      → wl_read_at      = NOW
                              status=FAILED    → wl_failed_reason = err
```

Deduplication: the job skips any sub for which a `(template_name, wl_status IN [DELIVERED, READ])` row already exists, so re-running the cron the same day is safe.

---

## 5. Non-Standard Conventions (and Why)

This is the section to read **before** trying to "fix" anything.

| Convention | Standard Rails | This codebase | Why |
|---|---|---|---|
| **Table prefixes** (`mst_`, `trn_`) | Plural lowercase | `mst_members_lists`, `trn_payments` | Inherited from the parent ERP product (`ErpModule`). Keeps tables grouped by role in DB tooling. |
| **Column prefixes** (`mmbr_`, `ms_`, `pay_`) | `name`, `email`, `amount` | `mmbr_name`, `ms_start_date`, `pay_amount` | Same heritage. Self-identifies tables in hand-written SQL. |
| **Class names that don't match table prefixes** | `Member` ↔ `members` | `MstMembersList` ↔ `mst_members_lists` | Class is named after the table verbatim, then Rails inflection makes it work. |
| **Empty model classes** | `has_many`, `validates`, scopes | Two-line stubs | Business logic was historically procedural in the ERP base; the gym product never reorganised. |
| **String foreign keys** (`varchar(4)`) | `bigint`, `belongs_to` | `ms_member_id varchar(5)`, `att_member_id varchar(4)` | Inherited column types; never migrated. Joins use `.to_s` / `.to_i` casts in Ruby. |
| **No DB foreign keys / no constraints** | `add_foreign_key`, NOT NULL FKs | None | Speed, MyISAM, and tolerance for partial data from the legacy import. |
| **MyISAM engine** | InnoDB | `mst_members_lists`, `trn_member_subscriptions`, etc. on MyISAM | Inherited; never changed. No transactions anyway since logic is procedural. |
| **MD5 password hashing** | `has_secure_password` (bcrypt) | `Digest::MD5.hexdigest(params[:userPassword])` ([login_controller.rb:17](app/controllers/login_controller.rb#L17)) | Inherited. **Should be migrated to bcrypt.** Treat the existing `users.userpassword` field as legacy. |
| **CSRF disabled site-wide** | `protect_from_forgery` on | Every controller has `skip_before_action :verify_authenticity_token` | Because the same controllers serve both `.html.erb` forms and AJAX/JSON endpoints, and `ajax_process` doesn't include a CSRF token. |
| **String-interpolated SQL filters** | `where(field: value)` | `iswhere = "mmbr_code LIKE '%#{filter}%'"` then `Model.where(iswhere)` | Quick-and-dirty filter building. **This is SQL-injection-shaped** if user input ever lands directly in `iswhere`. Most filters are bounded (admin-only UI, integer params, etc.) but anything coming from `params[:search]` should be reviewed. |
| **`ajax_process` action router** | RESTful `create` / `update` / etc. | Single action dispatching on `params[:identity]` | Lets multiple AJAX endpoints share one route per controller without expanding `routes.rb`. |
| **`add_X` instead of `new` + `edit`** | `GET /resource/new`, `GET /resource/:id/edit` | `GET /x_list/add_x` (both new and edit, distinguished by `params[:id]`) | One form template covers both modes. |
| ~~**`/x_list/:id/deletes` (GET) for destroy**~~ | `DELETE /resource/:id` | Resolved 2026-08-30 | Those routes are now `delete` and `alertChecked()` submits a real form with `_method=delete`. Kept here so the old pattern is not reintroduced by copying an older controller. |
| **Spelled "referesh"** | `refresh` | `referesh_member_list`, etc. | Typo in the original ERP base; copied verbatim throughout. Don't "fix" without grepping — it's in route paths, action names, and JS. |
| **17 `Rails.application.routes.draw` blocks** | One block | One per module in [config/routes.rb](config/routes.rb) | Visually groups routes by module. Functionally equivalent to one block. |
| **Session-based search persistence** | URL params / Turbo | `session[:req_member_list]`, `session[:req_member_search]`, … | Filters survive across navigation without query strings. Reset by hitting the `referesh_*` action. |
| **`session[:sess_X]` form repopulation** | `f.text_field` with model binding | Controller saves every param to `session[:sess_X]` on validation failure | Avoids re-passing failed-form data through redirects. Cleared on success. |
| **`get_*_detail(id)` helper methods on `ApplicationController`** | Active Record associations | `get_member_detail(id)`, `get_plan_detail(id)` in views | Stand-ins for missing model associations. They're exposed via `helper_method`. |
| **Dashboard preloads & in-memory hash maps** | Active Record's `includes(...)` | Manually-built `@members_map`, `@plans_map`, `@payments_map` keyed by string id | Without associations, this is the working pattern to avoid N+1 queries — see `DashboardController#preload_members/plans/payments`. |
| **ActiveJob async adapter in production** | Sidekiq / GoodJob | `config.active_job.queue_adapter = :async` | One Puma worker, low job volume (≤2 batches/day). No external broker needed. ⚠️ Jobs are lost on deploy/restart while in-flight. |
| **Cron via `cron-job.org` + plain HTTP** | `whenever` gem / Sidekiq-cron | External HTTPS GET with `?token=` shared secret | There is no scheduler in the Railway service; external cron is the simplest fit, and its execution log doubles as the delivery record. |
| **No bundler for JS** | esbuild / importmap / webpacker | Pre-built `public/assets/js/...` files | Carried forward; no build pipeline runs in CI. |
| **Per-page JS file auto-loaded by controller name** | Sprockets `javascript_include_tag` per page | `<script src="…/package/<%=page_linked%>.js">` | Convention-over-configuration shortcut: `member_list_controller` ↔ `member_list.js`. |
| **`page_linked` rename**: dashboard → `dashboard_liv` | n/a | One-off rename in `ApplicationController#page_linked` | Likely historical from a "live dashboard" rename; left in. |
| **MD5 `app.js` cache buster `?v=<%= Time.now.to_i %>`** | Asset fingerprinting | Append timestamp on every render | Asset pipeline isn't running, so this is the manual cache buster. Forces re-download every page load. |
| **The Interakt → Meta migration is half-undone** | n/a | `wl_interakt_msg_id` now stores Meta `wamid`, the Interakt controller still exists | Column was kept to avoid an ALTER on a busy table. Treat it as "wa_message_id" semantically. |
| **`ENGINE=MyISAM` mixed with InnoDB** | Pick one | System tables InnoDB, business tables MyISAM | Inherited base used MyISAM; new system tables created later defaulted to InnoDB. |
| **`mbm_finger_template` as JSON-in-LONGTEXT** | Active Storage / dedicated blob | `mapping.update(mbm_finger_template: params[:templates].to_json)` | Keeps the entire stack stateful in MySQL — no S3/Active Storage dependency. Acceptable because templates are small (a few KB) and only ~200 of them exist. |
| **A cron endpoint that must never be scheduled** | Run every job you write | `/cron/sync_subscription_status` exists and is deliberately left off the schedule | See below. |

### Why `sync_subscription_status` is not scheduled

It rewrites every subscription whose `ms_end_date` has passed from `ACTIVE` to
`EXPIRED`. That sounds like housekeeping, and it would break renewals.

`MembershipExpiryWhatsappJob`'s `:expired` branch looks for subscriptions that
are **still `ACTIVE` but already past their end date** — that combination is
the definition of someone who needs a renewal nudge. The sync job overwrites
exactly that set, so running it would leave the 10:00 job finding nothing, with
no error and no log line.

Nothing else depends on the flag. Gate access
([api/access_status_controller.rb](app/controllers/api/access_status_controller.rb)),
the subscription list filter, and every report compute from `ms_end_date`
directly, which is self-correcting at midnight. Treat `ms_status` as accurate
only at the moment a row is written, and never query on it.

---

## 6. UI/UX Patterns

### 6.1 Page Skeleton

Every authenticated page renders into the same wrapper:

```erb
<div class="page-wrapper">
  <%= render "layouts/header" %>            <!-- top bar: logo, user, logout -->
  <div class="page-container">
    <%= render "layouts/sidebar" %>         <!-- left vertical nav -->
    <div class="page-content-wrapper">
      <div class="page-content">
        <div class="page-bar">
          <div class="page-title-breadcrumb">
            <div class="pull-left"><div class="page-title">…</div></div>
            <%= render "layouts/breadcrumbs" %>
          </div>
        </div>
        <!-- page-specific content -->
      </div>
    </div>
  </div>
</div>
```

The master layout ([app/views/layouts/application.html.erb](app/views/layouts/application.html.erb)) gates which CSS/JS files load based on `controller.controller_name` — for example, `dashboard` additionally loads FullCalendar; `login` loads a minimal subset with a special login CSS.

The body carries a fixed set of classes that lock in the look-and-feel:
```html
<body class="page-header-fixed sidemenu-closed-hidelogo page-content-white page-md
             header-white white-sidebar-color logo-indigo spine-dark">
```

There is a **full-page loading overlay** (`#page-loader`) that fades in on every link click and is hidden on `window.load` (with a 12-second safety timeout). The overlay is suppressed by adding `data-no-loader` to a link or by anchors / `javascript:` URLs.

### 6.2 Common UI Components

| Component | Library | Used for |
|---|---|---|
| Tables with pagination/search | DataTables (bootstrap5 styled) | Every list page (`#example4` is the convention) |
| Dropdowns / typeahead | Select2 (`bootstrap` theme) | Member/plan/staff pickers |
| Date pickers | Flatpickr | Every date field |
| Toast notifications | `jquery-toast` (`$.toast(...)`) and Toastr | After every AJAX save (`showToast('success'|'error'|...)` global function in the layout) |
| Modals | Bootstrap 5 native | Renew prompts, confirm-delete |
| Image upload/crop | Croppie + Dropzone | Member/staff profile pictures (legacy) |
| WYSIWYG | Summernote | Loaded but not actively used |
| Charts | Morris + ApexCharts | Dashboard widgets |
| Calendar | FullCalendar | Dashboard (holiday/availability) |
| Buttons | Bootstrap `.btn .btn-circle .btn-success` etc. | Primary actions usually green, view/back blue, delete red |
| KPI cards | Custom `.card .stat-accent` with coloured left border (`#26a69a`, `#42a5f5`, `#ab47bc`, `#ef5350`, `#ffa726`) | Dashboard summary, payment summary |

A small helper in [app/helpers/application_helper.rb](app/helpers/application_helper.rb) maps plan names to badge colours (`monthly`→ blue, `quarterly`→ purple, `half-yearly`→ orange, `yearly`→ teal, `open`→ grey).

### 6.3 Page Organisation

A typical module ships **two views**:

1. **`index.html.erb`** — list page
   - Filter bar at the top (search input + filter dropdowns) submitting GET with `server_request=Y`
   - Action buttons row (typically "Add X" green button)
   - DataTable with rows and an inline action column (Edit / Delete / View)
   - Pagination via `will_paginate` (when present)

2. **`add_X.html.erb`** — combined new/edit form
   - Single `<form id="myForms">` with `id="hidden mid"` for edit vs create distinguishing
   - Field grid in two/three columns
   - Submit button calls JS in `public/assets/js/package/<controller>.js` which fires `$.ajax` to `<controller>/ajax_process` with `identity: 'SAVEX'`
   - On JSON response, show toast and redirect to the list

The Members module additionally has `profile.html.erb` — a deeper one-off view that aggregates subscription history, payment ledger, biometric status, and attendance counts into a single page (the most-used screen day-to-day).

### 6.4 Dashboard Layout

[app/views/dashboard/index.html.erb](app/views/dashboard/index.html.erb) is the operational nerve centre:

```
WELCOME BACK, <ADMIN NAME>.

[ Live Attendance feed (polled JSON, last 50 punches today) ]

[ Active subs ][ Expiring (7d) ][ Expired ][ Today's collection ]
    └ stat cards with coloured accent borders

[ Expired list ] [ Expiring list ] [ Due-payments list ]
    └ scrollable .list-group inside .card, each row linking to /member_subscriptions/...
```

Every list relies on the bulk-preload pattern in `DashboardController` — one query per related table, results indexed into hashes keyed by stringified id — to render all 200+ members without N+1 queries.

---

## 7. Quick Reference: Where to Look

| You want to... | Look at |
|---|---|
| Add a new module (CRUD) | Copy `staff_list_controller.rb` + its views + a JS package file; add a routes block; add a sidebar `<li>`. |
| Change subscription end-date math | [member_subscriptions_controller.rb#calculate_end_date](app/controllers/member_subscriptions_controller.rb) |
| Tweak biometric accept/reject | [api/biometric_attendances_controller.rb](app/controllers/api/biometric_attendances_controller.rb) and [api/adms_controller.rb](app/controllers/api/adms_controller.rb) — keep them in sync |
| Change a WhatsApp template | Update template name in [membership_expiry_whatsapp_job.rb](app/jobs/membership_expiry_whatsapp_job.rb); the template itself is managed in Meta Business Manager |
| Add a new permission action | Insert a row into `trn_user_accesses` and add a branch in `ApplicationController#menu_access_allowed` (it's a long if/elsif chain) |
| Add an audit-logged event | Call `process_request_log_data("EVENT_NAME", "Module", "Description")` from the controller after a save |
| Generate a unique business code | `generate_code(table: ModelClass, column: "x_code", prefix: "X", compcode: session[:loggedUserCompCode])` |
| Re-prefill a failed form | Read/write `session[:sess_X]` keys in the controller's `create` action |
| Reset a list page's stuck filter | Visit `/<controller>/referesh_<controller>` |

---

## 8. Known Risks & Tech Debt

These are flagged so a new contributor doesn't unknowingly amplify them.
Items struck through were fixed in the 2026-08-30 security pass; they are kept
here so the pattern is not reintroduced.

1. ~~**MD5 passwords.**~~ Resolved 2026-08-30: bcrypt sits alongside the legacy column and each account upgrades on next login. All password logic is in `app/models/user.rb`.
2. ~~**CSRF disabled everywhere.**~~ Resolved 2026-08-30: `SoftCsrfProtection` on the HTML controllers, `api/*` and `webhooks/*` still skip it by design.
3. ~~**String-interpolated SQL in filters.**~~ Resolved 2026-08-30: every `iswhere` filter now uses bound parameters. If you add a search box, chain `.where("col LIKE ?", ...)` — never interpolate.
4. ~~**GET `/x_list/:id/deletes`.**~~ Resolved 2026-08-30: those routes are `delete` and `alertChecked()` submits a real form.
5. **`generate_code` race condition.** Two simultaneous saves can produce duplicate codes. Add a unique index + retry, or use a sequence table.
6. **`:async` ActiveJob adapter.** In-flight WhatsApp sends are lost on deploy/restart. Acceptable for the expiry job, which idempotently re-checks `trn_whatsapp_logs` on the next run; **less acceptable** for receipts, which fire once on subscription creation and have no retry.
6a. **No test suite.** `test/` holds only the generated scaffolding. Everything in the 2026-08 messaging work was verified with throwaway `rails runner` scripts against the dev database. This is the single largest risk to changing the app safely.
6b. **MyISAM under money.** A subscription and its `trn_payments` row are two writes with no transaction between them (§2.5). If the process dies in between, the subscription exists and the payment does not, silently. Converting the `trn_*` tables to InnoDB is mostly mechanical and worth doing.
6c. **Timezone discipline.** Never assign `Time.zone = …` in a request. It is thread-local and Puma reuses threads, so it leaks into whichever request runs next on that thread — this corrupted 146 attendance rows by +5:30 before it was found. Use `Time.current.in_time_zone(IST_ZONE)` and parse device timestamps explicitly with `ActiveSupport::TimeZone['Asia/Kolkata']`.
6d. **`sql_mode` differs between dev and production.** Local WAMP runs with an empty `sql_mode`; production is strict. A migration that passes locally can fail on production with `Incorrect datetime value: '0000-00-00'`. Test schema changes against a strict session, and keep the hand-run SQL in [db/manual/](db/manual/).
7. **`ErpModule::Common` references non-existent models.** Some methods will `NameError` if accidentally called. Treat the module as dead code except for the few methods (`get_local_dated`, `formatted_times`) actually in use.
8. ~~**Hard-coded Bunny.net access key.**~~ Resolved 2026-08-30: the Bunny methods had no callers and were deleted along with the key. See SECURITY_FIXES.md.
9. ~~**Hard-coded device serial**~~ in `MemberListController#save_manual_mapping` and `Api::AdmsController#process_attendance`. Resolved 2026-08-30: it now comes from `ENV['DEVICE_SERIAL']`, falling back to the serial the bridge last reported (`ApplicationController#primary_device_sn`).
10. **`CRON_SECRET` is still a guessable word.** Every scheduled endpoint is protected by it alone. Rotating it means editing six URLs in cron-job.org and one Railway variable.
11. **Bridge authentication is still in soft mode.** `BIOMETRIC_API_TOKEN` is set, but the gym laptop does not send it, so `BIOMETRIC_AUTH_ENFORCE` cannot be turned on without stopping attendance. Requires an in-person visit — see SECURITY_FIXES.md step 5.
12. **`ms_status` is unreliable and has one consumer.** 270 rows read `ACTIVE` while already past `ms_end_date`. Nothing that matters trusts it: gate access, list filters and reports all compute from `ms_end_date`. Only the "expired" reminder reads it, and it does so deliberately — see §5.
13. **`escape_data_string` in `application_controller.rb`** contains `if type == 'DT' || 'NB'`, which is always true. Dead code with no callers, but it produces a Ruby warning on every boot.

---

*Last updated: 2026-09-02 — verified against the live schema, the Railway
deployment, and the running cron schedule.*
