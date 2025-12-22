# 📒 Offline Personal Accounting App – Roadmap

This roadmap describes a **step-by-step plan** to build an **offline-first personal accounting mobile app** using **Flutter**. The app helps users manage daily income & expenses (food, snacks, lending money to friends/family, etc.) with local storage and security.

---

## 🎯 App Vision

A **simple, fast, offline accounting app** for personal use:

* No internet required
* Secure with password / PIN
* Easy transaction logging
* Clear money flow (income vs expense)

---

## 🧱 Phase 0 – Planning & Foundation

### Goals

* Clear requirements
* Tech stack decision
* UX simplicity

### Decisions

* **Platform**: Mobile (Android / iOS)
* **Framework**: Flutter
* **State Management**: Riverpod or Bloc
* **Local Database**: SQLite (sqflite) or Hive
* **Security**: Local password + encryption
* **Offline-first**: No backend initially

### Deliverables

* App wireframe (paper / Figma)
* Folder structure design

---

## 🔐 Phase 1 – Authentication & Security (Offline)

### Features

* First launch → Create account
* Set:

  * Username
  * Password or PIN
* Login screen
* Lock app when backgrounded

### Technical Tasks

* Password hashing (bcrypt / crypto)
* Secure storage (flutter_secure_storage)
* Session handling (auto-lock after inactivity)

### Screens

* Welcome screen
* Create account
* Login screen

---

## 💾 Phase 2 – Local Database Design

### Core Tables

#### User Table

* id
* username
* password_hash
* created_at

#### Transaction Table

* id
* title ("Lunch", "Snack", "Paid to friend")
* amount
* type (income / expense)
* category
* date
* note (optional)
* related_person (optional)

#### Category Table

* id
* name (Food, Snack, Transport, Loan)
* icon

### Tasks

* Design SQLite schema
* Write CRUD helpers
* Migration support

---

## 💸 Phase 3 – Transaction Management (Core Feature)

### Features

* Add transaction
* Edit transaction
* Delete transaction
* View daily transactions

### Transaction Types

* Expense (buy food, snack)
* Income (salary, gift)
* Lending money (to mom, friend)
* Receiving money

### UI Screens

* Home dashboard
* Add transaction form
* Transaction detail view

---

## 📊 Phase 4 – Dashboard & Insights

### Features

* Total balance
* Daily / weekly / monthly summary
* Expense vs income chart
* Category-wise spending

### UI Components

* Balance card
* Bar / pie charts
* Recent transactions list

### Offline Analytics

* Compute summaries locally
* Cached calculations

---

## 🧾 Phase 5 – Lending & Borrowing Tracking

### Features

* Track money given to others
* Track money received from others
* Person-based balance

### Example

* Mom: +$50 (you gave)
* Friend Ali: -$20 (you received)

### Data Enhancements

* Person table
* Relationship to transactions

---

## ⚙️ Phase 6 – App Settings

### Features

* Change password / PIN
* Currency selection
* App lock timeout
* Data reset (local only)
* Dark / light mode

---

## 📤 Phase 7 – Data Backup & Export (Optional)

### Features

* Export to:

  * CSV
  * Excel
  * PDF summary
* Manual backup file
* Restore from backup

### Note

* Still offline
* User-controlled storage

---

## 🚀 Phase 8 – Performance & Polish

### Tasks

* Optimize database queries
* Smooth animations
* Empty states
* Error handling
* Input validation

---

## 🧪 Phase 9 – Testing

### Testing Types

* Unit tests (business logic)
* Widget tests (UI)
* Manual testing (real use)

### Scenarios

* App kill & restart
* Wrong password
* Large number of transactions

---

## 📦 Phase 10 – Build & Release

### Tasks

* App icon
* App name
* Build APK / IPA
* Local distribution or store publish

---

## 🛣️ Future Roadmap (Optional)

* Cloud sync (optional login)
* Multi-device sync
* AI spending insights
* Budget limits & alerts
* OCR receipt scanning

---

## 🧠 Recommended Learning Order (Flutter)

1. Dart basics
2. Flutter widgets
3. Navigation
4. State management
5. Local database (SQLite/Hive)
6. Secure storage
7. Charts & UI polish

---

## ✅ MVP Definition

The **minimum usable version**:

* Offline login
* Add income / expense
* View balance
* Transaction list

---

**End of Roadmap**
