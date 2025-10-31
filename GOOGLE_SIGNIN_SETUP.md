# Google Sign-In Setup Guide

## The Error You're Seeing

If you see: `"ClientID not set"` when trying to use Google Sign-In, you need to configure the OAuth client ID.

## How to Fix It

### Option 1: Setup for Web (Easiest)

1. **Go to Firebase Console**: https://console.firebase.google.com/project/aidkriya-294dc

2. **Navigate to Authentication**:
   - Click "Authentication" in the left menu
   - Click "Sign-in method" tab
   - Find "Google" and click to enable it
   - Add your project's domain to authorized domains

3. **Get the Web OAuth Client ID**:
   - Go to **Project Settings** (gear icon)
   - Scroll to "Your apps" section
   - Click on your **Web app**
   - Copy the value next to "OAuth client ID"

4. **Update `web/index.html`**:
   - Open `flutter_application_1/web/index.html`
   - Find the line: `<meta name="google-signin-client_id" content="">`
   - Replace the empty `content=""` with your client ID
   - Example: `<meta name="google-signin-client_id" content="123456789-abc.apps.googleusercontent.com" />`

### Option 2: Disable Google Sign-In Temporarily

If you want to focus on other features first, you can disable Google Sign-In:

1. **Comment out Google Sign-In button** in `lib/screens/login_screen.dart`:
   ```dart
   // Comment out the Google Sign-In button
   // const SizedBox(height: 16),
   // _buildGoogleSignInButton(),
   ```

2. **Or just test with email/password** - that works perfectly!

### Option 3: Setup for Android

If you're testing on Android:

1. Get your SHA-1 key:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   
2. Go to Firebase Console > Project Settings > Add fingerprint
3. Add the SHA-1 key
4. Download the updated `google-services.json`

## Why This Happens

Google Sign-In requires an OAuth client ID to identify your app to Google. Firebase generates this automatically, but you need to configure it in your app.

## Quick Test Without Google Sign-In

For now, you can test the app perfectly with just email/password:

1. Just use the email/password signup and login
2. Everything else works (profiles, database, etc.)
3. Set up Google Sign-In later when you have time

## Next Steps

1. **Test email/password authentication** - it works great!
2. **Test user profiles** - everything saves to Firestore
3. **Continue to Phase 2** - build the walk request system
4. **Setup Google Sign-In later** - it's optional for the MVP

## Need Help?

- Firebase Console: https://console.firebase.google.com/project/aidkriya-294dc
- Flutter Firebase Auth: https://firebase.google.com/docs/auth/flutter/firebaseui
- Google Sign-In Package: https://pub.dev/packages/google_sign_in

**For now, just use email/password authentication - it works perfectly!** ✅

