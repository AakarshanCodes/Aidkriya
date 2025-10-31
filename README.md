# AIDkriya - Walking Companion App

A Flutter app connecting "Walkers" (walking companions) with "Wanderers" (people looking for walking companions).

## 🚀 Features

- ✅ **Authentication**: Email/Password & Google Sign-In
- ✅ **User Roles**: Walker or Wanderer selection
- ✅ **Walk Requests**: Request walks now or schedule later
- ✅ **Matching System**: Walkers can find and accept requests
- ✅ **Rating & Reviews**: Post-walk feedback system
- ✅ **Beautiful UI**: Modern Material Design 3
- ✅ **Firebase Backend**: Secure data storage

## 📁 Project Structure

```
lib/
├── models/
│   ├── user_profile.dart      # User data model
│   └── walk.dart              # Walk request model
├── services/
│   ├── auth_service.dart       # Authentication
│   ├── firestore_service.dart  # User profiles
│   └── walk_service.dart      # Walk requests
├── screens/
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── home_screen.dart
│   ├── profile_screen.dart
│   ├── request_walk_screen.dart
│   ├── walk_requests_screen.dart
│   └── review_screen.dart
└── main.dart
```

## 🛠️ Setup

### 1. Firebase Setup

**Enable Authentication:**
1. Go to Firebase Console: https://console.firebase.google.com/project/aidkriya-294dc
2. Click "Authentication" → "Sign-in method"
3. Enable "Email/Password"
4. (Optional) Enable "Google"

### 2. Install Dependencies

```bash
cd flutter_application_1
flutter pub get
```

### 3. Run the App

```bash
flutter run
```

## 📱 Usage

### As a Wanderer:
1. Sign up and choose "Wanderer" role
2. Request a walk (Walk Now or Schedule)
3. Enter location and preferences
4. Wait for Walker to accept

### As a Walker:
1. Sign up and choose "Walker" role
2. View available walk requests
3. Accept walk requests
4. Complete walks and get reviewed

## 🎨 UI Design

- **Modern gradient headers** with purple theme
- **Card-based layouts** with rounded corners
- **Smooth animations** and transitions
- **Loading states** and error handling
- **Role-based UI** differences

## 📚 Documentation

- `COMPLETE_FEATURES.md` - Full feature list
- `IMPLEMENTATION_GUIDE.md` - Development guide
- `FIREBASE_SETUP.md` - Firebase configuration
- `QUICK_START.md` - Quick start guide

## 🏆 Competition Status

**Ready for Submission!**

- ✅ Fully functional app
- ✅ Beautiful UI
- ✅ Complete features
- ✅ Firebase integration
- ✅ Role-based system
- ✅ Walk request & matching
- ✅ Rating system

## 📝 License

Created for AI/ML competition submission.

---

**Built with Flutter & Firebase** 🚀
