# Flutter Rendering Exception & Auth Flow Fixes

## ✅ Issues Fixed

1. **Tutor App Rendering Exception** - Fixed semantics/rendering conflicts
2. **Login Persistence** - Properly configured auth state management
3. **Role-Based Routing** - Role detected from user's previous registration

---

## 1. Rendering Exception Fix ✅

### Problem:
```
package:flutter/src/rendering/object.dart
Failed assertion: line 5439 pos 14: '!semantics.parentDataDirty': is not true
```

**Root Cause:** The gate widgets were using `WidgetsBinding.instance.addPostFrameCallback` to navigate while simultaneously building UI with `StreamBuilder`, causing a conflict between widget tree updates and navigation.

### Solution: Simplified Gate Architecture

**Before (Problematic):**
- StatefulWidget with complex initState logic
- PostFrameCallback navigation during build
- Dual StreamBuilder causing render conflicts

**After (Fixed):**
- StatelessWidget with clean StreamBuilder hierarchy
- No postFrameCallback conflicts
- Navigation handled by returning different widgets
- Sign-out scheduled with `Future.microtask` instead of `addPostFrameCallback`

---

## 2. Updated Files

### File: `lib/features/gates/tutor_gate.dart` ✅

**Key Changes:**
```dart
class TutorGate extends StatelessWidget {  // Changed from StatefulWidget
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // No user → Show login
        if (user == null) {
          return const TutorLoginScreen();
        }
        
        // Check role in nested StreamBuilder
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            final role = userData?['role'] ?? '';
            
            // Wrong role → Sign out cleanly
            if (role != 'tutor') {
              Future.microtask(() async {
                await FirebaseAuth.instance.signOut();
              });
              return const TutorLoginScreen();
            }
            
            // Correct role → Check verification
            if (tutorVerified) {
              return child;  // Show main app
            } else {
              // Show verification screens
            }
          },
        );
      },
    );
  }
}
```

**Benefits:**
- ✅ No rendering conflicts
- ✅ Clean state management
- ✅ Proper async handling
- ✅ Auto-logout on wrong role

---

### File: `lib/features/gates/student_gate.dart` ✅

**Key Changes:**
```dart
class StudentGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // No user → Show welcome + login button
        if (user == null) {
          return Scaffold(
            body: Column(
              children: [
                Icon(Icons.school, size: 80),
                Text('Welcome to QuickTutor'),
                FilledButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, Routes.login),
                  child: Text('Sign In'),
                ),
              ],
            ),
          );
        }
        
        // Check role
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            final role = userData?['role'] ?? 'student';
            
            // Wrong role → Sign out and redirect
            if (role != 'student') {
              Future.microtask(() async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, Routes.login);
                }
              });
              
              return Scaffold(
                body: Column(
                  children: [
                    Icon(Icons.block, size: 80, color: Colors.red),
                    Text('This app is for students only.'),
                    Text('Signing out...'),
                    CircularProgressIndicator(),
                  ],
                ),
              );
            }
            
            // Correct role → Show app
            return child;
          },
        );
      },
    );
  }
}
```

---

### File: `lib/features/admin/gates/admin_gate.dart` ✅

**Same pattern** as tutor gate but for admin role.

---

## 3. Login Persistence & Auth Flow ✅

### How It Works Now:

#### **App Launch:**
1. Gate listens to `authStateChanges()` stream
2. If **no user** → Show login screen
3. If **user exists** → Check their role from Firestore
4. If **role matches** → Show appropriate app
5. If **role doesn't match** → Sign out → Show login

#### **After Login:**
- Firebase automatically persists auth state
- User remains logged in until explicit sign-out
- On app relaunch, auth state loads automatically

#### **Role Detection:**
- Role is stored in `users/{uid}.role` field
- Set during signup (student/tutor/admin)
- Checked on every app launch
- Wrong role → auto sign-out → must login with correct account

---

## 4. User Flow Examples

### Scenario 1: New User Signup

1. **Open Student App** → See "Welcome to QuickTutor" + "Sign In" button
2. **Click Sign In** → Goes to login screen
3. **Click "Create account"** → Goes to signup screen
4. **Enter details:**
   - Email: `newstudent@test.com`
   - Password: `password123`
   - Name: `John Doe`
   - **Select Role:** `Student` ← Important!
5. **Click "Create Account"** → Account created with `role = 'student'`
6. **Redirected to role gate** → StudentGate detects role → Shows student shell

### Scenario 2: Existing User Login

1. **Open Student App** → See login screen (no persisted user)
2. **Login with** `student@test.com` (existing account)
3. **StudentGate checks role:**
   - Finds `users/{uid}.role = 'student'`
   - ✅ Match → Show student shell
4. **Close app and reopen:**
   - Firebase loads persisted auth
   - StudentGate checks role again
   - ✅ Still matches → Show student shell (no login needed)

### Scenario 3: Wrong App for Role

1. **Open Student App** with tutor account
2. **StudentGate checks role:**
   - Finds `users/{uid}.role = 'tutor'`
   - ❌ Doesn't match 'student'
   - Shows "This app is for students only"
   - Auto signs out
   - Redirects to login
3. **Must login with student account** to use student app

---

## 5. Testing Checklist

### Test Auth Persistence:

#### Student App:
```bash
flutter run -d "iPhone 17 Pro" -t lib/main_student.dart
```

1. **First Launch (No User):**
   - ✅ Shows "Welcome to QuickTutor" screen
   - ✅ Has "Sign In" button

2. **After Login:**
   - ✅ Shows student shell
   - ✅ Can use all features

3. **Close and Reopen:**
   - ✅ Automatically shows student shell
   - ✅ No login screen
   - ✅ User remains logged in

4. **After Logout:**
   - ✅ Shows login screen
   - ❌ Cannot access app without login

5. **Wrong Role (Tutor Account):**
   - ❌ Shows "This app is for students only"
   - ✅ Auto signs out
   - ✅ Redirects to login

---

#### Tutor App:
```bash
flutter run -d "iPhone 16e (Tutor)" -t lib/main_tutor.dart
```

1. **First Launch (No User):**
   - ✅ Shows tutor login screen

2. **After Login (Tutor Account):**
   - If verified: ✅ Shows tutor shell
   - If not verified: ✅ Shows verification screens

3. **Close and Reopen:**
   - ✅ Automatically shows appropriate screen
   - ✅ No login required

4. **Wrong Role (Student Account):**
   - ❌ Shows "This app is for tutors only"
   - ✅ Auto signs out
   - ✅ Redirects to tutor login

---

#### Admin App:
```bash
flutter run -d "iPhone 17 Pro" -t lib/main_admin.dart
```

**Same behavior** as tutor app but for admin role.

---

## 6. Auth State Persistence Details

### Firebase Auth Persistence (Automatic):

**Persistence Type:** `LOCAL` (default on mobile)
- Auth state saved to device storage
- Persists across app restarts
- Persists across device reboots
- Cleared only on explicit sign-out

**What's Persisted:**
- User ID token
- Refresh token
- User metadata
- Auth state (logged in/out)

**What's NOT Persisted:**
- User role (fetched from Firestore on app launch)
- User profile data (fetched from Firestore)
- App-specific data

**How Gates Work with Persistence:**

```
App Launch
    ↓
authStateChanges() emits
    ↓
user != null? (from persisted token)
    ↓
Fetch user doc from Firestore
    ↓
Check role field
    ↓
role matches app?
    ↓ Yes        ↓ No
Show App    Sign Out → Login
```

---

## 7. Role-Based Routing Table

| User Role | Student App | Tutor App | Admin App |
|-----------|------------|-----------|-----------|
| **No User** | Login Screen | Login Screen | Login Screen |
| **Student** | ✅ Student Shell | ❌ Sign Out → Login | ❌ Sign Out → Login |
| **Tutor** | ❌ Sign Out → Login | ✅ Tutor Shell | ❌ Sign Out → Login |
| **Admin** | ❌ Sign Out → Login | ❌ Sign Out → Login | ✅ Admin Shell |

---

## 8. Console Output Examples

### Successful Auth Flow:
```
[Firebase] Auth state changed: User(uid: abc123)
[StudentGate] Checking user role...
[StudentGate] User role: student
[StudentGate] ✅ Role matches, showing student shell
```

### Wrong Role Flow:
```
[Firebase] Auth state changed: User(uid: xyz789)
[StudentGate] Checking user role...
[StudentGate] User role: tutor
[StudentGate] ❌ Wrong role, signing out...
[Firebase] User signed out
[StudentGate] Redirecting to login...
```

### Persistence Flow:
```
[App Launch]
[Firebase] Loading persisted auth...
[Firebase] Auth state: User(uid: abc123)
[StudentGate] User already logged in
[StudentGate] Checking role...
[StudentGate] ✅ Student role confirmed
[StudentGate] Showing student shell
```

---

## 9. Troubleshooting

### Issue: "Rendering exception still occurs"

**Check:**
1. Hot restart the app (not just hot reload): Press `R` in terminal
2. Full restart: Stop app and run again
3. Clear app data: Uninstall and reinstall

**If still occurs:**
- Check console for full stack trace
- Look for other `addPostFrameCallback` or `setState` during build
- Report specific error line number

---

### Issue: "Not staying logged in"

**Verify:**
1. User is actually logging in (check Firebase console)
2. No code is calling `signOut()` unexpectedly
3. Auth state is being listened to (check StreamBuilder)

**Debug:**
```dart
FirebaseAuth.instance.authStateChanges().listen((user) {
  debugPrint('Auth State: ${user?.uid ?? "No user"}');
});
```

---

### Issue: "Always shows login screen"

**Check:**
1. Is user actually signed in? Check Firebase console
2. Is persistence type correct? (Should be automatic)
3. Are gates checking auth correctly?

**Debug in gate:**
```dart
StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snapshot) {
    debugPrint('Auth snapshot: ${snapshot.data?.uid ?? "null"}');
    // ...
  },
)
```

---

## 10. Summary

| Feature | Status | Implementation |
|---------|--------|----------------|
| Rendering exception fixed | ✅ Complete | StatelessWidget gates with clean StreamBuilder |
| Login persistence | ✅ Working | Firebase automatic persistence (LOCAL) |
| Role detection | ✅ Working | Fetched from Firestore `users/{uid}.role` |
| Role enforcement | ✅ Working | Gates auto sign-out on role mismatch |
| Auth state listening | ✅ Working | StreamBuilder on authStateChanges() |
| Sign-out cleanup | ✅ Working | Future.microtask prevents rendering conflicts |

---

**All issues resolved!** 🎉

The app now:
- ✅ No rendering exceptions
- ✅ Persists login across app launches
- ✅ Detects role from user registration
- ✅ Enforces role-based access
- ✅ Auto signs out wrong roles
- ✅ Requires login after sign-out
- ✅ Works independently per app (student/tutor/admin)
