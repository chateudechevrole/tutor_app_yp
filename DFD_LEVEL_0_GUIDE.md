# QuickTutor - Data Flow Diagram (DFD) Level 0
## Context Diagram - Step-by-Step Guide

---

## 📚 What is DFD Level 0?

**DFD Level 0 (Context Diagram)** shows the **entire system as a single process** interacting with **external entities**. It's the highest-level view showing:
- The system boundary
- External entities (actors)
- Major data flows in/out of the system

---

## 🎯 Step-by-Step Guide to Draw DFD Level 0

### Step 1: Identify the System
**System Name:** QuickTutor Platform

**System Purpose:** Connect students with tutors for booking tutoring sessions

**Draw:** One large circle or rounded rectangle in the center labeled "QuickTutor System"

```
                    ┌─────────────────────┐
                    │                     │
                    │  QuickTutor System  │
                    │                     │
                    └─────────────────────┘
```

---

### Step 2: Identify External Entities
External entities are **people, systems, or organizations** that interact with your system but are **outside its boundary**.

For QuickTutor, identify:

#### Human Actors:
1. **Student** - Books tutoring sessions
2. **Tutor** - Provides tutoring services
3. **Admin** - Manages verification and system

#### External Systems:
4. **Firebase Authentication** - Handles user login
5. **Firebase Cloud Messaging (FCM)** - Sends push notifications
6. **Payment Gateway** - Processes payments (future)

**Draw:** Rectangles around your system circle

```
┌─────────┐                                         ┌─────────┐
│ Student │                                         │  Tutor  │
└─────────┘                                         └─────────┘

                    ┌─────────────────────┐
                    │                     │
                    │  QuickTutor System  │
                    │                     │
                    └─────────────────────┘

┌─────────┐         ┌──────────┐          ┌─────────────────┐
│  Admin  │         │ Firebase │          │      FCM        │
└─────────┘         │   Auth   │          │  (Push Notif)   │
                    └──────────┘          └─────────────────┘
```

---

### Step 3: Identify Data Flows FROM External Entities TO System

Ask: "What data does each entity SEND to the system?"

| From Entity | To System | Data Flow Name | Description |
|------------|-----------|----------------|-------------|
| Student | QuickTutor | Registration Data | Email, password, name |
| Student | QuickTutor | Login Credentials | Email, password |
| Student | QuickTutor | Booking Request | Session details, tutor selection |
| Student | QuickTutor | Search Criteria | Subject, grade level |
| Student | QuickTutor | Review | Rating, comment |
| Student | QuickTutor | Chat Message | Text message to tutor |
| Tutor | QuickTutor | Registration Data | Email, password, credentials |
| Tutor | QuickTutor | Profile Data | Bio, subjects, hourly rate |
| Tutor | QuickTutor | Verification Documents | ID, certificates |
| Tutor | QuickTutor | Booking Response | Accept/decline |
| Tutor | QuickTutor | Chat Message | Text message to student |
| Admin | QuickTutor | Verification Decision | Approve/reject tutor |
| Firebase Auth | QuickTutor | Auth Token | User authentication token |
| Firebase Auth | QuickTutor | User UID | Unique user identifier |

**Draw:** Arrows pointing FROM entity TO system with labels

---

### Step 4: Identify Data Flows FROM System TO External Entities

Ask: "What data does the system SEND to each entity?"

| From System | To Entity | Data Flow Name | Description |
|------------|-----------|----------------|-------------|
| QuickTutor | Student | Tutor List | Available tutors with profiles |
| QuickTutor | Student | Booking Confirmation | Session details, status |
| QuickTutor | Student | Chat Messages | Messages from tutor |
| QuickTutor | Student | Notifications | Booking updates |
| QuickTutor | Tutor | Booking Requests | New session requests |
| QuickTutor | Tutor | Profile Status | Verification status |
| QuickTutor | Tutor | Chat Messages | Messages from student |
| QuickTutor | Tutor | Notifications | New bookings, messages |
| QuickTutor | Admin | Verification Queue | Pending tutor verifications |
| QuickTutor | Admin | User List | All registered users |
| QuickTutor | Admin | Booking List | All bookings |
| QuickTutor | Firebase Auth | User Data | Email, role for account creation |
| QuickTutor | FCM | Push Notification | Notification payload |

**Draw:** Arrows pointing FROM system TO entity with labels

---

### Step 5: Arrange and Label Everything

#### Notation Guide:
- **Circle/Rounded Rectangle** = Process (the system)
- **Rectangle** = External Entity
- **Arrow** = Data Flow (labeled with data name)
- **Open Rectangle** = Data Store (not shown in Level 0, only in Level 1+)

#### Positioning Tips:
- Place primary users (Student, Tutor) at the top
- Place admin on the side
- Place external systems (Auth, FCM) at the bottom
- Balance the diagram for readability
- Group related data flows to reduce clutter

---

## 📐 Complete DFD Level 0 for QuickTutor

```
┌─────────────────┐                                    ┌─────────────────┐
│                 │                                    │                 │
│    STUDENT      │                                    │     TUTOR       │
│                 │                                    │                 │
└────────┬────────┘                                    └────────┬────────┘
         │                                                      │
         │ Registration Data                   Registration Data│
         │ Login Credentials                   Profile Data     │
         │ Booking Request                     Verification Docs│
         │ Search Criteria                     Booking Response │
         │ Review                              Chat Message     │
         │ Chat Message                                         │
         ↓                                                      ↓
         │                                                      │
         │ Tutor List                          Booking Requests │
         │ Booking Confirmation                Profile Status   │
         │ Chat Messages                       Chat Messages    │
         │ Notifications                       Notifications    │
         ↑                                                      ↑
         │                                                      │
         └──────────────────────┐       ┌─────────────────────┘
                                │       │
                    ┌───────────▼───────▼───────────┐
                    │                               │
                    │                               │
                    │     QuickTutor System         │
                    │   (Main Process - P0)         │
                    │                               │
                    │  Manages tutoring sessions,   │
                    │  user profiles, bookings,     │
                    │  verification, and messaging  │
                    │                               │
                    └───────┬───────────────┬───────┘
                            │               │
         ┌──────────────────┘               └──────────────────┐
         │                                                      │
         │ Verification Queue                      User Data   │
         │ User List                               Push Notif  │
         │ Booking List                                        │
         ↓                                                      ↓
         │                                                      │
         │ Verification Decision                    Auth Token │
         │                                          User UID   │
         ↑                                                      ↑
┌────────┴────────┐                              ┌─────────────┴─────────┐
│                 │                              │                       │
│     ADMIN       │                              │   External Systems    │
│                 │                              │                       │
└─────────────────┘                              │ • Firebase Auth       │
                                                 │ • Firebase FCM        │
                                                 │ • Payment Gateway*    │
                                                 │   (*future)           │
                                                 └───────────────────────┘


Legend:
───────► Data Flow (arrow shows direction)
┌─────┐  External Entity (source/destination)
  ⃝      Process (the system)
```

---

## 🎨 Professional ASCII Art Version

```
                        QUICKTUTOR DFD LEVEL 0
                          (Context Diagram)
    
    ╔═════════════════╗                            ╔═════════════════╗
    ║                 ║                            ║                 ║
    ║    STUDENT      ║                            ║     TUTOR       ║
    ║   (External)    ║                            ║   (External)    ║
    ║                 ║                            ║                 ║
    ╚════════╤════════╝                            ╚════════╤════════╝
             │                                              │
             │                                              │
    ┌────────▼──────────┐                        ┌─────────▼─────────┐
    │ • Registration    │                        │ • Registration    │
    │ • Login           │                        │ • Profile Data    │
    │ • Booking Request │                        │ • Documents       │
    │ • Search          │                        │ • Booking Actions │
    │ • Reviews         │                        │ • Messages        │
    │ • Messages        │                        │                   │
    └────────┬──────────┘                        └─────────┬─────────┘
             │                                              │
             │                                              │
             ▼                                              ▼
    ╔════════════════════════════════════════════════════════════════╗
    ║                                                                ║
    ║                                                                ║
    ║                    ◯   QuickTutor System                      ║
    ║                       (Process P0)                            ║
    ║                                                                ║
    ║    Core Functions:                                            ║
    ║    • User Authentication & Authorization                      ║
    ║    • Tutor Profile Management                                 ║
    ║    • Booking & Session Management                             ║
    ║    • Tutor Verification Workflow                              ║
    ║    • Chat & Messaging                                         ║
    ║    • Review & Rating System                                   ║
    ║    • Push Notifications                                       ║
    ║                                                                ║
    ╚════════╤════════════════════════════════════╤════════════════╝
             │                                     │
             │                                     │
    ┌────────▼──────────┐                ┌────────▼────────────┐
    │ • Tutor Lists     │                │ • Booking Requests  │
    │ • Confirmations   │                │ • Profile Status    │
    │ • Messages        │                │ • Messages          │
    │ • Notifications   │                │ • Notifications     │
    └────────┬──────────┘                └────────┬────────────┘
             │                                     │
             ▲                                     ▲
    ╔════════╧════════╗                  ╔════════╧════════════╗
    ║                 ║                  ║                     ║
    ║     ADMIN       ║                  ║  External Systems   ║
    ║   (External)    ║                  ║                     ║
    ║                 ║                  ║ • Firebase Auth     ║
    ╚═════════════════╝                  ║ • Firebase FCM      ║
             ▲                           ║ • Firebase Storage  ║
             │                           ║ • Cloud Functions   ║
    ┌────────┴──────────┐                ║                     ║
    │ • Verify Queue    │                ╚═════════════════════╝
    │ • User Management │                          ▲
    │ • Booking Logs    │                          │
    └───────────────────┘                 ┌────────┴─────────┐
             │                            │ • Auth Tokens    │
             ▼                            │ • User IDs       │
    ┌────────────────────┐                │ • Push Payloads  │
    │ • Approve/Reject   │                │ • File URLs      │
    │ • Role Changes     │                └──────────────────┘
    └────────────────────┘
```

---

## 📋 Data Flow Summary Table

| # | From | To | Data Flow | Description |
|---|------|----|-----------| ------------|
| 1 | Student | System | Registration Data | Email, password, name |
| 2 | Student | System | Booking Request | Tutor ID, date, time, subject |
| 3 | System | Student | Tutor List | Available tutors with profiles |
| 4 | System | Student | Booking Status | Confirmation, updates |
| 5 | Tutor | System | Profile Information | Bio, subjects, rates, availability |
| 6 | Tutor | System | Verification Docs | ID, certificates |
| 7 | System | Tutor | Booking Notifications | New session requests |
| 8 | System | Tutor | Verification Status | Approved/pending/rejected |
| 9 | Admin | System | Verification Decision | Approve/reject tutor |
| 10 | System | Admin | Pending Verifications | Queue of tutors awaiting review |
| 11 | System | Firebase Auth | User Registration | Email, password, role |
| 12 | Firebase Auth | System | Auth Tokens | JWT tokens, UIDs |
| 13 | System | FCM | Push Notification | Notification payload |
| 14 | FCM | Student/Tutor | Push Message | Delivered notification |

---

## 🎓 Drawing Tips & Best Practices

### 1. **Keep It High-Level**
- Don't show internal processes (those go in Level 1)
- Don't show data stores (those go in Level 1)
- Focus only on external interactions

### 2. **Clear Labeling**
- Label every data flow clearly
- Use active voice ("Booking Request" not "Request")
- Be specific but concise

### 3. **Balanced Layout**
- Distribute external entities evenly
- Minimize crossing arrows
- Use curved arrows if needed

### 4. **Consistency**
- All external entities should be rectangles
- System should be a circle or rounded rectangle
- Arrows should be straight or gently curved

### 5. **Grouping**
- Group related data flows together
- You can use one arrow with multiple labels if flows are similar

---

## 🖼️ Simplified Version (For Presentation)

If the full diagram is too complex, create a simplified version:

```
              Student ──┬──► Search & Browse
                        ├──► Book Session      ┌───────────────┐
                        ├──► Chat & Review ───►│               │
                        │                      │  QuickTutor   │◄─── Verify & Approve ─── Admin
                        └──◄─ Confirmations ───│    System     │
                                               │               │
              Tutor ────┬──► Manage Profile    └───────────────┘
                        ├──► Upload Docs           │      ▲
                        ├──► Accept/Decline        │      │
                        │                          ▼      │
                        └──◄─ Notifications ── Firebase Services
```

---

## 📝 Textual Description (For Documentation)

**Process P0: QuickTutor System**

The QuickTutor System is an online platform that connects students with qualified tutors for personalized tutoring sessions.

**External Entities:**
1. **Student** - Searches for tutors, books sessions, submits reviews
2. **Tutor** - Creates profiles, manages availability, conducts sessions
3. **Admin** - Verifies tutor credentials, manages platform
4. **Firebase Authentication** - Provides user authentication services
5. **Firebase Cloud Messaging** - Delivers push notifications

**Primary Data Flows:**
- Students submit booking requests and receive tutor recommendations
- Tutors submit verification documents and receive booking notifications
- Admins review verification requests and manage user accounts
- System integrates with Firebase for authentication and notifications

---

## 🎯 Next Steps: Moving to DFD Level 1

Once Level 0 is complete, Level 1 will:
- Break "QuickTutor System" into **major processes**:
  - P1: User Management
  - P2: Tutor Profile Management
  - P3: Booking Management
  - P4: Verification System
  - P5: Messaging System
  - P6: Notification System

- Show **data stores**:
  - D1: Users
  - D2: Tutor Profiles
  - D3: Bookings
  - D4: Messages
  - D5: Verification Requests

---

## ✅ Checklist: Is Your DFD Level 0 Complete?

- [ ] System shown as single process
- [ ] All external entities identified
- [ ] All major data flows labeled
- [ ] Arrows show direction clearly
- [ ] No internal processes shown
- [ ] No data stores shown
- [ ] Diagram is balanced and readable
- [ ] All entities interact with system (no orphans)
- [ ] Data flows are bidirectional where appropriate

---

**Created:** October 27, 2025  
**For:** QuickTutor Platform  
**Diagram Type:** Data Flow Diagram Level 0 (Context Diagram)
