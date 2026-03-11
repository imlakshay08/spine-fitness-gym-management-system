# Spine Fitness – Gym Management System

Spine Fitness is a gym management platform built to digitize and automate the daily operations of a real gym located in Dwarka, New Delhi.

The system replaces manual record-keeping (previously done using notebooks) with a centralized digital platform for managing members, subscriptions, payments, attendance, and inventory.

The software is currently deployed and actively used by **Spine Fitness Gym**, which has **200+ registered members and 100+ active members**.

---

## Live Application

[https://spine-fitness.com](https://spine-fitness.com)

---

# Problem

The gym previously managed all operations manually:

• Member registrations were written in notebooks
• Membership renewals were tracked manually
• Attendance was not automated
• Payment history was difficult to track
• Stock inventory was not organized
• Member communication (renewals, offers) required manual effort

This resulted in:

• Human errors
• Missed renewals
• Poor visibility of gym operations

The goal was to build a system that **automates and centralizes gym operations**.

---

# Solution

Spine Fitness provides a web-based management system that allows gym administrators to:

• Manage members and memberships
• Track payments and subscription renewals
• Monitor attendance through biometric devices
• Maintain gym inventory
• Send automated WhatsApp notifications to members

The system improves operational efficiency and provides real-time visibility into gym activities.

---

# Key Features

### Member Management

• Add and manage gym members
• Maintain member profiles
• Track active and expired memberships

### Membership Plans

• Create different subscription plans
• Assign plans to members
• Track subscription periods and renewals

### Payment Tracking

• Record membership payments
• Maintain payment history for each member

### Biometric Attendance Integration

• Integrated with a fingerprint biometric device
• Automatically records member attendance
• Maps biometric IDs with member profiles

### WhatsApp Automation

• Automated WhatsApp messages sent to members for:

* Membership reminders
* Notifications
* Offers and updates

### Inventory Management

• Track gym stock items
• Manage stock usage and issue records

### Staff & Trainer Management

• Maintain list of trainers and staff members

### Admin Dashboard

• Centralized dashboard to monitor gym operations

---

# Real-World Usage

The system is actively used by **Spine Fitness Gym (Dwarka, New Delhi)**.

Current usage statistics:

• 200+ registered members
• 100+ active members
• Biometric attendance tracking enabled
• Automated WhatsApp communication with members

This project demonstrates building **production software used by a real business**.

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
cron-job.com (daily automation tasks)

Hardware Integration
Biometric fingerprint attendance device

---

# System Architecture

The system follows a standard Ruby on Rails MVC architecture.

Components include:

• Web application for gym administrators
• MySQL database for persistent data storage
• API integration for biometric attendance devices
• WhatsApp API integration for automated messaging
• Scheduled cron jobs for automated reminders

---

# Database Design

The system uses structured master and transaction tables.

### Master Tables

mst_members_lists
mst_membership_plans
mst_staff_lists
mst_trainer_lists
mst_stock_lists
mst_category_lists

### Transaction Tables

trn_member_subscriptions
trn_member_attendances
trn_payments
trn_stock_inventories
trn_issue_amounts
trn_reminder_logs
trn_whatsapp_logs

### System Tables

users
sessions
trn_user_accesses
trn_user_rights
trn_audit_trials

---

# Technical Challenges

### Biometric Device Integration

Integrating the fingerprint biometric device required mapping biometric IDs to member profiles and synchronizing attendance data through an API.

### WhatsApp Automation

Integrating Interakt API for automated messaging required building workflows for sending reminders and notifications.

### Real-World Business Requirements

The system was designed around real operational workflows of a physical gym, requiring flexible membership management and payment tracking.

---

# Future Improvements

• Online payment gateway integration
• Member self-service portal
• Mobile application for gym members
• Advanced analytics dashboard
• Automated subscription renewal system

---

# Developer

Lakshay Tyagi
Ruby on Rails Developer

This project was developed independently as a real-world software solution for a local gym business.

