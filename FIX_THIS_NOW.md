# 🔴 "Failed to load user profile" Error - Fix NOW!

## The Problem
```
Exception: Failed to get user profile: 
[cloud_firestore/permission-denied] Missing or insufficient permissions.
```

## ✅ Quick Fix (2 Minutes)

### Step 1: Open Firestore Rules
Click this link: **https://console.firebase.google.com/project/aidkriya-294dc/firestore/rules**

### Step 2: You'll See This:

```
Rules version: '2'
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if false;  ← This is the problem!
    }
  }
}
```

### Step 3: DELETE ALL and Paste THIS:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /walks/{walkId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Step 4: Click "PUBLISH" Button (top right)

### Step 5: Reload App
Press **`r`** in terminal (lowercase r)

---

## ✅ That's It!

Your app will now work perfectly! 

Try signing up again - it should work now! 🎉

