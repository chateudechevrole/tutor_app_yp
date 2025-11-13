# AppBar Visibility Fix - Student App

## Issue
The AppBar in the student app was not visible because:
- `backgroundColor: kStudentBg` (almond cream) matched the scaffold background
- `elevation: 0` meant no shadow to distinguish the AppBar from the background
- Text color was correct but the AppBar blended into the background

## Solution
Changed all student screen AppBars to have:
- **White background** instead of kStudentBg
- **elevation: 1** with subtle shadow
- **Larger, bolder text** (fontSize: 20)

## Files Fixed

### 1. StudentHomeScreen
**File:** `lib/features/student/student_home_screen.dart`

**Changes:**
```dart
appBar: AppBar(
  title: Text(
    'Find Tutor Now ✨',
    style: TextStyle(
      color: kStudentDeep,
      fontWeight: FontWeight.w600,
      fontSize: 20,  // Added
    ),
  ),
  backgroundColor: Colors.white,  // Changed from kStudentBg
  elevation: 1,  // Changed from 0
  shadowColor: Colors.black12,  // Added
),
```

### 2. StudentMessagesScreen
**File:** `lib/features/student/messages/student_messages_screen.dart`

**Changes:**
```dart
appBar: AppBar(
  title: Text(
    'Messages',
    style: TextStyle(
      color: kStudentDeep,
      fontWeight: FontWeight.w600,
      fontSize: 20,  // Added
    ),
  ),
  backgroundColor: Colors.white,  // Changed from kStudentBg
  elevation: 1,  // Changed from 0
  shadowColor: Colors.black12,  // Added
),
```

### 3. StudentProfileScreen
**File:** `lib/features/student/profile/student_profile_screen.dart`

**Changes:**
```dart
appBar: AppBar(
  title: const Text(
    'My Profile',
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 20,  // Added
    ),
  ),
  backgroundColor: Colors.white,  // Added
  elevation: 1,  // Changed from 0
  shadowColor: Colors.black12,  // Added
),
```

## Visual Result

**Before:**
```
┌──────────────────────────┐
│                          │ ← AppBar invisible (same color as bg)
│  Find Tutor Now ✨       │
│                          │
└──────────────────────────┘
```

**After:**
```
┌──────────────────────────┐
│  Find Tutor Now ✨       │ ← White AppBar with subtle shadow
├──────────────────────────┤ ← Visible separation
│                          │
│  (Content)               │
└──────────────────────────┘
```

## Design Rationale

1. **White background**: Provides clear contrast against the almond cream body
2. **Subtle shadow (elevation: 1)**: Creates depth without being overwhelming
3. **Larger text (fontSize: 20)**: Improves readability and hierarchy
4. **Consistent styling**: All 3 student screens now have matching AppBars

## Testing

Run the student app and verify:
```bash
flutter run -d 'iPhone 17 Pro' -t lib/main_student.dart
```

- ✅ Home screen AppBar is visible with white background
- ✅ Messages screen AppBar is visible with white background  
- ✅ Profile screen AppBar is visible with white background
- ✅ Navigation between tabs shows consistent AppBar style

---

**Status:** ✅ Fixed  
**Impact:** Visual only, no functional changes  
**Breaking Changes:** None
