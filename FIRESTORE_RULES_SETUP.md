# Fix Firestore Permission Denied Error

## The Error
```
DartError: Exception: Failed to get user profile: 
[cloud_firestore/permission-denied] Missing or insufficient permissions.
```

## What This Means
Firestore has security rules that prevent unauthorized access. You need to update them.

## 🔧 Quick Fix (2 Minutes)

### Step 1: Open Firestore Rules
Go to: https://console.firebase.google.com/project/aidkriya-294dc/firestore/rules

Or manually:
1. Firebase Console → Firestore Database
2. Click "Rules" tab

### Step 2: Replace the Rules
Copy and paste this into the editor:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - authenticated users can read/write their own data
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Walks collection - authenticated users can read and write
    match /walks/{walkId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### Step 3: Publish
Click **"Publish"** button (top right)

### Step 4: Reload App
Press **`r`** in terminal (hot reload)

That's it! ✅

---

## What These Rules Do

- ✅ Authenticated users can read any profile
- ✅ Users can only write their own profile
- ✅ Users can read and write walks

---

## For Development/Demo (Alternative Loose Rules)

If you want even more open access for testing:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

⚠️ **Note**: This is very permissive - only use for development/demo, not production!

---

## After Setting Rules

1. **Publish the rules**
2. **Press `r` in terminal** to reload
3. **Try signing up again**
4. **Everything should work!**

