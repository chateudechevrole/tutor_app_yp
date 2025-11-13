# Quick Reference: Generic Auth Flow

## Before & After

### Login Screen
**Before:**
```
AppBar: "Login"
Button: "Sign In" ✓
Link: "Create account" ✓
```

**After:**
```
AppBar: "Sign in" ← Changed
Button: "Sign In" ✓
Link: "Create account" ✓
```

---

### Sign Up Screen
**Before:**
```
Dropdown:
▼ Student
  Tutor
  Admin
```

**After:**
```
SegmentedButton:
[Student 🎓] [Tutor 👤]
Helper text: "You can change this later in Settings."
(Admin option removed from UI)
```

---

### Role-Based Routing

```
Login
  ↓
RoleGate
  ↓
Check role:
  ├─ role == 'student' → StudentHomeScreen
  ├─ role == 'tutor' → TutorDashboardScreen (or verify screens)
  ├─ role == 'admin' → AdminDashboardScreen
  └─ role == '' → RolePickerScreen (NEW)
```

---

### New: RolePickerScreen

Shown when user has no role set:

```
╔══════════════════════════════╗
║   👤                         ║
║   Welcome to QuickTutor!     ║
║   Please select your role:   ║
║                              ║
║   [Student 🎓] [Tutor 👤]   ║
║   You can change this later  ║
║                              ║
║   [Continue]                 ║
╚══════════════════════════════╝
```

---

### Gates (Student/Tutor Apps)

**StudentGate:**
- No user → Shows welcome + "Sign In" button → Routes.login
- Wrong role (tutor/admin) → "Access Denied" → Sign out → Routes.login ✓

**TutorGate:**
- No user → Shows welcome + "Sign In" button → Routes.login ← Changed
- Wrong role (student/admin) → "Access Denied" → Sign out → Routes.login ✓
- Correct role → Verification flow (verify/waiting/dashboard)

---

### Account Settings

**Student Profile:**
```
Settings Card:
┌─────────────────────────────┐
│ 🎖️ Account Role   Student  │
├─────────────────────────────┤
│ 🔔 Notifications  [toggle]  │
└─────────────────────────────┘
```

**Tutor Account:**
```
Settings:
┌─────────────────────────────┐
│ 🎖️ Account Role   Tutor    │
├─────────────────────────────┤
│ 📅 Accepting Bookings [✓]  │
├─────────────────────────────┤
│ 🔔 Notifications      [✓]  │
└─────────────────────────────┘
```

---

## User Flows

### 1. New User Sign Up
```
1. Open app
2. Tap "Create account"
3. Fill: Name, Email, Password
4. Select: [Student] or [Tutor]
5. Tap "Create Account"
6. → Auto-routes to StudentShell or TutorShell
```

### 2. Existing User Login
```
1. Open app
2. Enter credentials
3. Tap "Sign In"
4. → RoleGate reads users/{uid}.role
5. → Auto-routes based on role
```

### 3. User Without Role (Edge Case)
```
1. Login
2. → RoleGate detects role == ''
3. → Shows RolePickerScreen
4. User selects role
5. → Saves to Firestore
6. → Auto-routes to correct shell
```

---

## Testing Commands

```bash
# Test student app
flutter run -d 'iPhone 17 Pro' -t lib/main_student.dart

# Test tutor app
flutter run -d "iPhone 16e (Tutor)" -t lib/main_tutor.dart

# Test admin app
flutter run -d "iPhone 17 Pro" -t lib/main_admin.dart
```

---

## Firestore Data Structure

```json
{
  "users": {
    "{uid}": {
      "displayName": "John Doe",
      "email": "john@example.com",
      "role": "student",  // or "tutor", "admin"
      "tutorVerified": false  // only for tutors
    }
  }
}
```

---

## Migration Notes

**Deprecated:**
- ❌ `TutorLoginScreen` (use shared `LoginScreen`)
- ❌ Route `/tutor/login` (use `/login`)

**To Remove After Testing:**
1. `lib/features/tutor/tutor_login_screen.dart`
2. Route definition `tutorLogin` in `app_routes.dart`
3. Route mapping `tutorLogin: (_) => const TutorLoginScreen()`

---

## Quick Debug

**Check user role in Firestore:**
```
Firebase Console → Firestore → users → {uid} → role
```

**Test role picker:**
1. Set `role: ""` in Firestore
2. Login
3. Should see RolePickerScreen

**Test wrong role access:**
1. Login as student in tutor app
2. Should see "Access Denied"
3. Should sign out automatically
```
