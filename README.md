# Spine Fitness — Production Gym Management System

A full-stack gym management platform built with Ruby on Rails, deployed in production and actively used by a real gym in Dwarka, New Delhi. Replaced physical notebooks with a centralized digital platform managing 250+ members, biometric attendance, two-way WhatsApp messaging, automated owner reporting, and gate access control.

**🔗 Live:** [spine-fitness.com](https://spine-fitness.com)

---

## The Problem

Spine Fitness Gym was managing 200+ members using physical registers and notebooks.

- Membership renewals were missed — lost revenue
- Attendance tracked inconsistently or not at all
- Payment history scattered across different books
- Expired members could still walk in — no enforcement
- Member communication required manual phone calls
- Inventory completely untracked

**Result:** Human errors, missed renewals, zero operational visibility, hours of admin work daily.

---

## The Solution

A centralized web platform where gym administrators manage everything digitally — from member onboarding to automated WhatsApp expiry reminders and biometric gate control.

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Backend** | Ruby on Rails 7.1, Ruby 3.1.4 |
| **Database** | MySQL — a Railway service with a persistent volume (env vars still carry the legacy `MYSQL_ADDON_*` names from a previous host) |
| **Frontend** | jQuery + Bootstrap 5, ERB, per-page AJAX (Hotwire gems present but unused) |
| **Hosting** | Railway (Nixpacks), behind Cloudflare |
| **Biometric Bridge** | Python 3 (pyzk + Flask) — runs on gym laptop |
| **WhatsApp API** | Meta WhatsApp Cloud API (direct integration, two-way) |
| **PDF Reports** | Prawn 1.2.1 + prawn-table |
| **Scheduling** | cron-job.org (six endpoints) |
| **Hardware** | ZKTeco fingerprint biometric device |

---

## Architecture

```
Gym Admin (Browser)
   │
   ▼  Cloudflare
Ruby on Rails Application (Railway)
   │
   ├── MySQL (Railway service, mysql-volume)
   │
   ├── WhatsApp Messaging (Meta Cloud API) ──► members, owner, staff
   │      ▲
   │      └── webhook: delivery receipts + inbound replies
   │
   ├── Scheduled Jobs (cron-job.org — 6 endpoints)
   │
   └── REST API: POST /api/biometric_attendances
                    ▲
                    │ HTTP POST (every 20 seconds)
                    │
         ┌──────────┴──────────┐
         │   Python Bridge      │         ┌─────────────────────┐
         │   bridge.py          │         │  Android Phone       │
         │   (gym laptop)       │         │  (Termux backup)     │
         │   + sync_access.py   │         └──────────┬──────────┘
         │   + enroll_api.py    │                    │
         └──────────┬──────────┘                    │
                    │ pyzk SDK (TCP)                 │
                    └───────────────┬────────────────┘
                                    ▼
                         ┌─────────────────────┐
                         │  ZKTeco Fingerprint  │
                         │  Biometric Device    │
                         │  (LAN address)       │
                         │  Door relay control  │
                         └─────────────────────┘
```

---

## Key Features

### Member Management
- Add and manage 200+ member profiles
- Auto-generated member codes
- Track active, expiring, and expired memberships
- Partial payment support — real-world billing requirement

### Biometric Attendance + Gate Control

The most technically complex feature. The ZKTeco fingerprint device sits on the gym's local network and cannot reach cloud APIs directly.

**Solution:** A Python bridge script running on the gym's Windows laptop:

1. Connects to the ZK device over local LAN via `pyzk` SDK
2. Polls attendance logs every 20 seconds
3. Deduplicates locally using an in-memory set
4. Forwards each new punch to the Rails API via HTTP POST

**Gate Control via Template Management:**

Expired members are blocked at the physical door — not just logged. When a subscription expires, the member's fingerprint template is deleted from the device. No template = device shows red ✗ = door relay does not fire. When a member renews, their saved template is restored from the database automatically at the next midnight sync.

**Two-layer deduplication:**

| Layer | Where | How |
|---|---|---|
| Layer 1 | Python bridge | In-memory set of `{user_id}-{timestamp}` keys |
| Layer 2 | Rails API | DB check: same member + same minute |

**Fingerprint Enrollment from Web UI:**

A Flask API (`enroll_api.py`) runs on the gym laptop alongside the bridge. Staff click "Enroll Fingerprint" on the member profile page — the browser pings `localhost:5000/enroll`, which creates the device user and triggers the enrollment screen on the biometric device. Single button click, under 30 seconds.

**Dual Bridge for Reliability:**

Primary bridge on the gym laptop + backup bridge on an Android phone running Termux. If the laptop is off, attendance continues via the phone. Both can run simultaneously — Rails deduplication silently ignores double-sends.

### WhatsApp Automation

Replaced the original third-party provider (Interakt) with a direct **Meta WhatsApp Cloud API** integration after 0% delivery rate due to app being in development mode.

**Pipeline:**
```
cron-job.org (daily 10:00 AM IST)
    ↓
MembershipExpiryWhatsappJob
    ↓
Meta WhatsApp Cloud API
    ↓
Member's WhatsApp
    ↓
Webhook → trn_whatsapp_logs updated: QUEUED → DELIVERED → READ
```

Full delivery tracking via webhook — messages are tracked through their complete lifecycle.

**Six scheduled endpoints**, all token-gated (`?token=…` against `CRON_SECRET`):

| Endpoint | Schedule (IST) | What it does |
|---|---|---|
| `/cron/send_expiry_whatsapp` | daily 10:00 | "expiring in 3 days" + "expired" reminders |
| `/cron/send_owner_daily_report` | daily 22:30 | Owner's day summary + PDF |
| `/cron/send_owner_monthly_report` | 1st of month | Owner's month summary + PDF |
| `/cron/check_biometric` | every 15 min | Biometric outage watchdog |
| `/cron/send_staff_weekly` | Mon 12:00 | Staff follow-up list + PDF |
| `/cron/sync_subscription_status` | *not scheduled* | Flips `ms_status` to EXPIRED — deliberately unscheduled, see note below |

The report and alert endpoints run **synchronously** and return their outcome in the response body (`OK - biometric alert: 5/5 sent`), so the cron service's own execution log shows whether the message actually went out.

> **Note on `sync_subscription_status`:** it is intentionally not scheduled. The "expired" reminder searches for subscriptions that are still `ACTIVE` but past their end date — exactly the rows this job rewrites — so running it would silently stop renewal reminders. Nothing else reads `ms_status`; gate access, list filters and reports all derive from `ms_end_date`.

### Two-Way WhatsApp Inbox

A full conversation view at `/whatsapp_inbox` — inbound member messages, staff replies, and automated sends merged into one timeline in IST order, polled every 5 seconds. Handles images, video, audio, documents, stickers and emoji reactions, with Meta's 24-hour customer service window enforced before a free-form reply is allowed.

### Subscription Receipts

The moment a subscription is created or renewed, the member gets a formatted WhatsApp confirmation **and** a Prawn-generated PDF receipt attached.

### Owner Reports

Daily (22:30) and monthly (1st) business summaries delivered to the owner as WhatsApp text plus a PDF — collections, new subscriptions, visits with member names and entry times, expiring memberships. Written in deliberately plain language with no technical terms. Kept out of the WhatsApp Logs screen, which is a member-communication history.

### Staff Alerts & Biometric Watchdog

The Python bridge posts a heartbeat; `Alerts::BiometricWatch` raises an alert when it goes quiet for 20 minutes **while the gym is open**, throttled to one message per two hours. Staff get instructions to fix it themselves; the owner gets a version telling her who to call. A Monday list of members absent 14+ days ships as a PDF of names and numbers.

Opening hours live in `Alerts::GymClock` and are the only gate on whether an alert fires:

| | Morning | Evening |
|---|---|---|
| Mon–Sat | 06:30–11:30 IST | 17:00–21:30 IST |
| **Sunday** | 06:30–11:30 IST | **closed** |

Everything is evaluated in IST regardless of the caller's zone, so a UTC timestamp gives the same answer as its IST equivalent — including which day of the week it is.

### Member Removal (Soft Delete)

Staff can remove a member without destroying history. `mmbr_status` flips `A` → `R`, biometric mappings are deactivated, and gate access is revoked at all four decision points — while subscriptions, payments and attendance stay intact and resolvable. Reversible via restore.

### Admin Dashboard

Single-screen overview: active/expiring/expired member counts, today's collections, due payments, attendance feed, inventory status. Bulk preloading with hash maps to avoid N+1 queries with 200+ members.

### Subscription & Payment Tracking
- Membership plan management
- Partial payment support
- Payment history per member
- Auto-calculated due balances on dashboard

### Inventory Management
- Track gym equipment and supplements
- Stock issuance and usage records

### Staff & Trainer Management
- Staff records with role-based access
- Module-level permission system per department

---

## Database Design

**Master Tables** (static business data):
```
mst_members_lists
mst_membership_plans
mst_staff_lists
mst_trainer_lists
mst_stock_lists
```

**Transaction Tables** (operational data):
```
trn_member_subscriptions
trn_member_attendances
trn_member_biometric_mappings   ← includes finger template backup (LONGTEXT)
trn_payments
trn_whatsapp_logs               ← outbound message lifecycle
trn_whatsapp_inbox              ← inbound messages, replies, media, reactions
trn_bridge_heartbeats           ← last-seen ping from the gym laptop
trn_audit_trials
```

**System Tables:**
```
users
trn_user_accesses
trn_user_rights
```

---

## Python Bridge Components

```
biometric_bridge/
├── bridge.py             # Main attendance polling loop + heartbeat POST
├── sync_access.py        # Nightly gate access sync (delete/restore templates)
├── enroll_api.py         # Flask API for web-triggered fingerprint enrollment
├── config.py             # Device IP, Rails URL, company code
├── config.example.py     # Template — copy to config_local.py on the gym laptop
├── requirements.txt      # pyzk, requests, flask, flask-cors
└── start_bridge.vbs      # Silent auto-start on Windows boot (no terminal window)
```

The bridge authenticates to `/api/*` with a bearer token (`BIOMETRIC_API_TOKEN`). Rails currently runs this in **soft mode** — unauthenticated calls are allowed and logged — until the gym laptop is updated in person. See `SECURITY_FIXES.md` step 5.

---

## Local Development Setup

```bash
git clone https://github.com/imlakshay08/spine-fitness-gym-management-system
cd spine-fitness-gym-management-system
bundle install
rails db:create db:migrate
rails server
```

For the Python bridge:
```bash
cd biometric_bridge
pip install -r requirements.txt
python bridge.py
```

---

## Real-World Usage

**Spine Fitness Gym** — Dwarka Sector 22, New Delhi

- 250+ registered members
- Biometric attendance running daily
- Automated WhatsApp reminders every morning at 10 AM
- Nightly owner report and Monday staff follow-up list, both as PDFs
- Biometric outages detected within 20 minutes and messaged to staff
- Expired members physically blocked at the gate
- Zero notebooks in use

---

## Blog Posts

- [Building a Production Gym Management System with Ruby on Rails](https://imlakshay08-complete-ruby-on-rails.hashnode.dev/gym-management-system-with-ruby-on-rails)
- [Connecting a Biometric Fingerprint Device to a Rails App Using Python](https://imlakshay08-complete-ruby-on-rails.hashnode.dev/connecting-a-biometric-fingerprint-device-to-a-rails-web-app-using-python)
- [How I Ditched Interakt and Built a Direct WhatsApp Pipeline with Meta Cloud API](https://imlakshay08-complete-ruby-on-rails.hashnode.dev/how-i-ditched-interakt-and-built-a-direct-whatsapp-automation-pipeline-with-meta-cloud-api)
- [From Polling to Production: How I Upgraded My Biometric Integration with Gate Control, Auto-Enrollment, and 24/7 Reliability](https://imlakshay08-complete-ruby-on-rails.hashnode.dev/from-polling-to-production-how-i-upgraded-my-biometric-integration-with-gate-control-auto-enrollment-and-24-7-reliability)

---

## Developer

**Lakshay Tyagi** — Ruby on Rails Developer
- GitHub: [imlakshay08](https://github.com/imlakshay08)
- Blog: [Complete Ruby on Rails on Hashnode](https://imlakshay08-complete-ruby-on-rails.hashnode.dev)

---

## License

MIT License
