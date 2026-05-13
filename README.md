# Spine Fitness — Production Gym Management System

A full-stack gym management platform built with Ruby on Rails, deployed in production and actively used by a real gym in Dwarka, New Delhi. Replaced physical notebooks with a centralized digital platform managing 200+ members, biometric attendance, automated WhatsApp notifications, and gate access control.

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
| **Database** | MySQL (CleverCloud) |
| **Frontend** | Hotwire (Turbo + Stimulus), jQuery, Bootstrap |
| **Hosting** | Render |
| **Biometric Bridge** | Python 3 (pyzk + Flask) — runs on gym laptop |
| **WhatsApp API** | Meta WhatsApp Cloud API (direct integration) |
| **PDF Reports** | Prawn |
| **Scheduling** | cron-job.com |
| **Hardware** | ZKTeco fingerprint biometric device |

---

## Architecture

```
Gym Admin (Browser)
   │
   ▼
Ruby on Rails Application (Render)
   │
   ├── MySQL Database (CleverCloud)
   │
   ├── WhatsApp Messaging (Meta Cloud API)
   │
   ├── Scheduled Jobs (cron-job.com)
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
                         │  (192.168.1.201)     │
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
trn_whatsapp_logs
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
├── bridge.py           # Main attendance polling loop
├── sync_access.py      # Nightly gate access sync (delete/restore templates)
├── enroll_api.py       # Flask API for web-triggered fingerprint enrollment
├── config.py           # Device IP, Rails URL, company code
├── requirements.txt    # pyzk, requests, flask, flask-cors
└── start_bridge.vbs    # Silent auto-start on Windows boot (no terminal window)
```

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

- 200+ registered members
- 100+ active members
- Biometric attendance running daily
- Automated WhatsApp reminders sent every morning at 10 AM
- Expired members physically blocked at the gate
- Zero notebooks in use

---

## Blog Posts

- [Building a Production Gym Management System with Ruby on Rails](https://imlakshay08-complete-ruby-on-rails.hashnode.dev/gym-management-system-with-ruby-on-rails)
- [Connecting a Biometric Fingerprint Device to a Rails App Using Python](https://imlakshay08-complete-ruby-on-rails.hashnode.dev/connecting-a-biometric-fingerprint-device-to-a-rails-web-app-using-python)
- [How I Ditched Interakt and Built a Direct WhatsApp Pipeline with Meta Cloud API](https://imlakshay08-complete-ruby-on-rails.hashnode.dev/how-i-ditched-interakt-and-built-a-direct-whatsapp-automation-pipeline-with-meta-cloud-api)

---

## Developer

**Lakshay Tyagi** — Ruby on Rails Developer
- GitHub: [imlakshay08](https://github.com/imlakshay08)
- Blog: [Complete Ruby on Rails on Hashnode](https://imlakshay08-complete-ruby-on-rails.hashnode.dev)

---

## License

MIT License
