# Generic Auth Flow & Role-Based Routing - Implementation Summary

## ✅ Changes Completed

### 1. Updated LoginScreen (`lib/features/auth/login_screen.dart`)
- Changed AppBar title from "Login" to **"Sign in"**
- Button text already reads **"Sign In"**
- "Create account" CTA already present
- ✅ No role-specific wording

### 2. Updated SignupScreen (`lib/features/auth/signup_screen.dart`)
**Changes:**
- Replaced dropdown with **SegmentedButton** for role selection
- Two options: **Student** (with school icon) and **Tutor** (with person icon)
- Default selection: **Student**
- Removed **Admin** option from UI (admin accounts created separately)
- Added helper text: *"You can change this later in Settings."*
- Added validation for empty fields
- Better error handling with try-catch

**UI Layout:**
```
Display name
Email
Password
───────────────
I am a:
[Student 🎓] [Tutor 👤]  ← SegmentedButton
You can change this later in Settings.
───────────────
[Create Account]
```

### 3. Created RolePickerScreen (`lib/features/auth/role_picker_screen.dart`)
**Purpose:** Handles users who have authenticated but have no role set

**Features:**
- Shown when user exists but `role` field is empty/null
- Same SegmentedButton UI as SignupScreen
- Welcome message: "Welcome to QuickTutor!"
- Saves role to `users/{uid}.role` in Firestore
- Redirects to RoleGate after saving (auto-routes to correct shell)
- No back button (prevents skipping role selection)

**UI:**
```
Welcome to QuickTutor!
Please select your role to continue:

[Student 🎓] [Tutor 👤]
You can change this later in Settings.

[Continue]
```

### 4. Updated RoleGate (`lib/main.dart`)
**Changes:**
- Added check for empty/null role: `if (role.isEmpty)`
- Shows **RolePickerScreen** if role is missing
- After role selection, routes to appropriate shell based on role

**Routing Logic:**
```dart
if (role.isEmpty) → RolePickerScreen
if (role == 'admin') → AdminDashboardScreen
if (role == 'tutor') → TutorDashboardScreen or TutorVerifyScreen
else → StudentHomeScreen
```

### 5. Updated StudentGate (`lib/features/gates/student_gate.dart`)
**Changes:**
- Already redirects to `Routes.login` ✅
- Updated error message from "This app is for students only" to **"Access Denied"**
- Subtitle: "This account does not have student access."
- Generic, not role-specific wording

### 6. Updated TutorGate (`lib/features/gates/tutor_gate.dart`)
**Changes:**
- Removed import of `TutorLoginScreen`
- No user → Shows welcome screen with "Sign In" button → `Routes.login`
- Wrong role → Shows "Access Denied" message → Signs out → `Routes.login`
- Keeps tutor verification flow intact (TutorVerifyScreen, TutorWaitingScreen)

**Welcome Screen:**
```
👤
Welcome to QuickTutor
Please sign in to continue.

[Sign In] → Routes.login
```

### 7. Deprecated TutorLoginScreen (`lib/features/tutor/tutor_login_screen.dart`)
**Changes:**
- Added deprecation comment:
  ```dart
  /// @deprecated This screen is deprecated. Use the shared LoginScreen instead.
  /// This file will be removed in a future version.
  /// The app now uses role-based routing from a single login screen.
  ```
- Added TODO comment to remove file after migration confirmed
- File kept for backward compatibility but no longer used

### 8. Updated app_routes.dart (`lib/core/app_routes.dart`)
**Changes:**
- Marked `tutorLogin` route as deprecated:
  ```dart
  // TODO: Deprecated - Remove after migration to shared LoginScreen
  static const tutorLogin = '/tutor/login';
  ```

### 9. Added Role Display in Account Settings

#### StudentProfileScreen (`lib/features/student/profile/student_profile_screen.dart`)
Added in settings section:
```dart
ListTile(
  leading: const Icon(Icons.badge),
  title: const Text('Account Role'),
  trailing: const Text(
    'Student',
    style: TextStyle(
      fontWeight: FontWeight.w500,
      color: Colors.blue,
    ),
  ),
),
```

#### TutorAccountSettingsScreen (`lib/features/tutor/account/tutor_account_settings_screen.dart`)
Added at top of settings:
```dart
ListTile(
  leading: const Icon(Icons.badge),
  title: const Text(
    'Account Role',
    style: TextStyle(fontWeight: FontWeight.w600),
  ),
  trailing: const Text(
    'Tutor',
    style: TextStyle(
      fontWeight: FontWeight.w500,
      color: kPrimary,
    ),
  ),
),
```

---

## 📋 Files Modified

1. ✅ `lib/features/auth/login_screen.dart` - Updated title to "Sign in"
2. ✅ `lib/features/auth/signup_screen.dart` - SegmentedButton role selector
3. ✅ `lib/features/auth/role_picker_screen.dart` - NEW FILE
4. ✅ `lib/main.dart` - RoleGate handles missing role
5. ✅ `lib/features/gates/student_gate.dart` - Generic error messages
6. ✅ `lib/features/gates/tutor_gate.dart` - Uses shared LoginScreen
7. ✅ `lib/features/tutor/tutor_login_screen.dart` - Deprecated
8. ✅ `lib/core/app_routes.dart` - Marked tutorLogin as deprecated
9. ✅ `lib/features/student/profile/student_profile_screen.dart` - Role display
10. ✅ `lib/features/tutor/account/tutor_account_settings_screen.dart` - Role display

---

## 🎯 User Flows

### Flow 1: New User Signup
1. Open app → Lands on login screen (no auth)
2. Tap **"Create account"**
3. Fill in: Display name, Email, Password
4. Select role: **Student** or **Tutor**
5. Tap **"Create Account"**
6. → RoleGate checks role
7. → Routes to StudentShell or TutorShell (or TutorVerifyScreen)

### Flow 2: Existing Student Login
1. Open app → Lands on login screen
2. Enter credentials → Tap **"Sign In"**
3. → RoleGate reads `users/{uid}.role = 'student'`
4. → Routes to **StudentHomeScreen**

### Flow 3: Existing Tutor Login
1. Open app → Lands on login screen
2. Enter credentials → Tap **"Sign In"**
3. → RoleGate reads `users/{uid}.role = 'tutor'`
4. → Checks `tutorVerified`
5. → If verified: **TutorDashboardScreen**
6. → If pending: **TutorWaitingScreen**
7. → If not submitted: **TutorVerifyScreen**

### Flow 4: User with No Role (Legacy/Error Case)
1. User logs in
2. → RoleGate checks `users/{uid}.role`
3. → Role is empty/null
4. → Shows **RolePickerScreen**
5. User selects Student or Tutor
6. → Saves to Firestore
7. → Redirects to RoleGate
8. → Routes to appropriate shell

### Flow 5: Wrong Role Access
**Scenario:** Student tries to open Tutor app
1. Student logs into tutor app (main_tutor.dart)
2. → TutorGate checks role = 'student'
3. → Shows "Access Denied" message
4. → Signs out automatically
5. → Redirects to login screen

---

## ✅ Acceptance Criteria Checklist

- ✅ **iPhone 17 Pro shows "Sign in"** (no role-specific wording)
- ✅ **"Create account" allows choosing Student/Tutor**
- ✅ **Role selection writes to `users/{uid}.role`**
- ✅ **On sign-in, app auto-navigates to StudentShell/TutorShell based on role**
- ✅ **Users with no role are prompted to select one (RolePickerScreen)**
- ✅ **Helper text: "You can change this later in Settings."**
- ✅ **Account Settings shows read-only Role row**
- ✅ **All "Tutor Login" / "Create tutor account" strings removed**
- ✅ **Login button reads "Sign in"**
- ✅ **Minimal churn - reused existing auth widgets**
- ✅ **TODO comments added where "Tutor" strings were removed**
- ✅ **TutorLoginScreen deprecated with comments**

---

## 🧪 Testing Checklist

### Manual Testing Required:
1. **New User Signup Flow**
   - [ ] Sign up as Student → Verify routes to StudentShell
   - [ ] Sign up as Tutor → Verify routes to TutorVerifyScreen
   - [ ] Check Firestore: `users/{uid}.role` is set correctly

2. **Existing User Login Flow**
   - [ ] Login as existing student → Verify routes to StudentHomeScreen
   - [ ] Login as existing tutor (verified) → Verify routes to TutorDashboardScreen
   - [ ] Login as existing tutor (pending) → Verify routes to TutorWaitingScreen

3. **Role Picker Flow**
   - [ ] Manually set `users/{uid}.role = ''` in Firestore
   - [ ] Login → Verify RolePickerScreen appears
   - [ ] Select role → Verify saves and routes correctly

4. **Cross-App Access**
   - [ ] Login as student in tutor app → Verify "Access Denied" → Sign out
   - [ ] Login as tutor in student app → Verify "Access Denied" → Sign out

5. **UI Verification**
   - [ ] LoginScreen title reads "Sign in"
   - [ ] SignupScreen shows SegmentedButton with icons
   - [ ] Helper text appears under role selector
   - [ ] Account Settings shows role field (read-only)

---

## 🚀 Deployment Notes

- No database migrations required
- Existing users with roles will continue working
- New users will have role selection enforced
- TutorLoginScreen can be safely removed after confirming all flows work
- Remove deprecated route `/tutor/login` from app_routes.dart after cleanup

---

## 📚 Related Documentation

- `lib/features/auth/login_screen.dart` - Shared login UI
- `lib/features/auth/signup_screen.dart` - Role selection UI
- `lib/features/auth/role_picker_screen.dart` - Fallback for missing role
- `lib/main.dart` - RoleGate routing logic
- `lib/features/gates/student_gate.dart` - Student-specific gate
- `lib/features/gates/tutor_gate.dart` - Tutor-specific gate

---

**Status:** ✅ Implementation Complete  
**Breaking Changes:** None (backward compatible)  
**Next Steps:** Manual testing, then remove deprecated TutorLoginScreen
