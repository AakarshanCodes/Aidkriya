# Firebase Authentication Setup

## The Error
"Email/password accounts are not enabled."

## How to Fix (2 minutes)

### Step 1: Open Firebase Console
Go to: https://console.firebase.google.com/project/aidkriya-294dc

### Step 2: Enable Email/Password Authentication

1. **Click "Authentication"** in the left menu
2. **Click "Sign-in method"** tab (at the top)
3. **Find "Email/Password"** in the list
4. **Click on it**
5. **Toggle the "Enable" switch** to ON
6. **Click "Save"**

That's it! ✅

### Step 3: (Optional) Enable Google Sign-In

1. Still in the "Sign-in method" tab
2. **Find "Google"** in the list
3. **Click on it**
4. **Toggle the "Enable" switch** to ON
5. **Select your project support email**
6. **Click "Save"**

## Visual Guide

```
Firebase Console → Authentication → Sign-in method:
├── Email/Password → Click → Enable → Save ✅
├── Google → Click → Enable → Save ✅
└── Phone (optional, for later)
```

## After Enabling

### Test Email/Password
1. Run your app: `flutter run`
2. Click "Sign Up"
3. Enter email and password
4. It should work! ✅

### Test Google Sign-In
1. Also click "Sign in with Google"
2. It may still show the client ID error
3. That's okay - see `GOOGLE_SIGNIN_SETUP.md`

## Quick Checklist

- [ ] Go to Firebase Console
- [ ] Click Authentication
- [ ] Click Sign-in method tab
- [ ] Enable Email/Password
- [ ] Enable Google (optional)
- [ ] Click Save
- [ ] Test the app!

## Still Having Issues?

1. **Clear app data**: Uninstall and reinstall
2. **Check internet**: Make sure you're online
3. **Hot restart**: Press `R` in terminal (capital R)
4. **Check Firebase**: Verify sign-in methods are enabled

## Next Steps After Setup

1. ✅ Enable Email/Password authentication
2. ✅ Test signup and login
3. ✅ Verify profiles save to Firestore
4. 🚀 Ready for Phase 2!

---

**This should only take 2 minutes! Just enable email/password in Firebase Console.** ⚡

