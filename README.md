# Spine Fitness – Gym Management System

Spine Fitness is a **gym management platform** built to digitize and automate the daily operations of a real gym located in **Dwarka, New Delhi**.

The system replaces manual record-keeping (previously done using notebooks) with a centralized digital platform for managing **members, subscriptions, payments, attendance, and inventory**.

The software is currently **deployed in production and actively used** by Spine Fitness Gym, which has:

* **200+ registered members**
* **100+ active members**
* **Biometric attendance tracking**

---

# Live Application

https://spine-fitness.com

---

# Problem

The gym previously managed operations manually using notebooks and physical registers.

This created several issues:

* Member registrations recorded manually
* Membership renewals difficult to track
* Attendance monitoring inconsistent
* Payment history not centralized
* Inventory tracking unreliable
* Member communication required manual effort

This led to:

* Human errors
* Missed membership renewals
* Lack of operational visibility
* Time-consuming administrative work

---

# Solution

Spine Fitness provides a **web-based management platform** that allows gym administrators to manage all operations digitally.

The system centralizes data and automates several workflows such as attendance tracking and member notifications.

Gym administrators can now:

* Manage member records
* Track membership plans and renewals
* Record and track payments
* Monitor attendance through biometric devices
* Manage inventory and staff
* Send automated WhatsApp notifications

---

# Key Features

## Member Management

* Add and manage gym members
* Maintain detailed member profiles
* Track active and expired memberships

## Membership Plans

* Create and manage membership plans
* Assign plans to members
* Track subscription periods and renewal status

## Payment Tracking

* Record membership payments
* Maintain payment history for each member

## Biometric Attendance Integration

* Integrated with fingerprint biometric device
* Automatic attendance recording
* Biometric ID mapped to gym members

## WhatsApp Automation

Automated WhatsApp messaging system used for:

* Membership expiry reminders
* Important notifications
* Promotional offers
* General communication with members

## Inventory Management

* Track gym equipment and stock
* Manage stock issuance and usage

## Staff & Trainer Management

* Maintain records of trainers and staff members

## Admin Dashboard

Centralized dashboard for monitoring gym operations.

---

# Real-World Usage

The system is actively used by a real business:

**Spine Fitness Gym**
Dwarka Sector 22 Market
New Delhi, India

Current system usage includes:

* 200+ registered members
* 100+ active members
* Biometric attendance tracking
* Automated WhatsApp notifications

This project demonstrates the development and deployment of **production software used by a real business environment**.

---

# Architecture Overview

```
Gym Admin
   │
   ▼
Web Application (Ruby on Rails)
   │
   ├── MySQL Database (CleverCloud)
   │
   ├── WhatsApp Messaging (Interakt API)
   │
   ├── Biometric Attendance Device API
   │
   └── Scheduled Jobs (cron-job.com)
```

The Rails application acts as the central system that integrates all services and manages gym operations.

---

# Tech Stack

Backend
Ruby on Rails

Database
MySQL (CleverCloud)

Hosting
Render

Domain
Namecheap

Messaging Integration
Interakt WhatsApp API

Scheduling
cron-job.com (for automated daily tasks)

Hardware Integration
Biometric fingerprint attendance device

---

# Database Design

The database is organized into **Master tables** and **Transaction tables**.

## Master Tables

```
mst_members_lists
mst_membership_plans
mst_staff_lists
mst_trainer_lists
mst_stock_lists
mst_category_lists
```

These tables store static business data.

## Transaction Tables

```
trn_member_subscriptions
trn_member_attendances
trn_payments
trn_stock_inventories
trn_issue_amounts
trn_reminder_logs
trn_whatsapp_logs
```

These tables store dynamic operational data.

## System Tables

```
users
sessions
trn_user_accesses
trn_user_rights
trn_audit_trials
```

These tables manage authentication, authorization, and audit logging.

---

# Local Development Setup

Clone the repository

```
git clone https://github.com/your-username/spinefitness.git
cd spinefitness
```

Install dependencies

```
bundle install
```

Create database

```
rails db:create
```

Run migrations

```
rails db:migrate
```

Start the server

```
rails server
```

Application will run at:

```
http://localhost:3000
```

---

# Technical Challenges

## Biometric Device Integration

Integrating the biometric fingerprint device required mapping biometric IDs with gym members and synchronizing attendance records through an API.

## WhatsApp API Integration

Integrating the Interakt WhatsApp API required designing automated workflows for sending notifications and reminders.

## Real Business Workflow Modeling

The system needed to replicate real gym operations including membership management, attendance tracking, and payment recording.

---

# Key Learnings

Building Spine Fitness provided experience with:

* Designing software for a real-world business workflow
* API integration with third-party services
* Hardware integration with biometric attendance devices
* Database design for subscription-based systems
* Deploying and maintaining production Rails applications
* Handling real user data and operational processes

---

# Future Improvements

Planned improvements include:

* Online payment gateway integration
* Member self-service portal
* Mobile application for members
* Advanced analytics dashboard
* Automated membership renewal system
* Enhanced reporting tools

---

# Developer

Lakshay Tyagi
Ruby on Rails Developer

This project was developed independently as a real-world software solution for a local gym business.

---

# License

MIT License
