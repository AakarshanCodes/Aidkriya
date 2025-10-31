# Fix "Email/password accounts are not enabled" Error

## ✅ Your App is Running!

The app successfully launched on Chrome! The only thing left is to enable authentication.

## 🔧 Quick Fix (2 Minutes)

### Step 1: Open Firebase Console
Go to: https://console.firebase.google.com/project/aidkriya-294dc

### Step 2: Enable Email/Password
1. Click **"Authentication"** in the left menu (looks like a key 🔑 icon)
2. Click **"Sign-in method"** tab at the top
3. Find **"Email/Password"** in the list
4. Click on it
5. Toggle the **"Enable"** switch to **ON**
6. Click **"Save"**

### Step 3: Reload Your App
Press **`r`** in the terminal (hot reload) or close and restart Chrome

That's it! ✅

---

## Alternative: Restart the App

If hot reload doesn't work, press:
- **`R`** in terminal (capital R - hot restart)
- Or close Chrome and run `flutter run` again

---

## After Enabling

You can then:
- ✅ Sign up with email/password
- ✅ Login with email/password  
- ✅ Create user profiles
- ✅ Test all features!

---

## Why This Happens

Firebase doesn't enable email/password authentication by default for security reasons. You need to manually enable it once in the Firebase Console.

