import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // For web platforms, this will use the meta tag in index.html
    // For Android, this should match the SHA-1 configured in Firebase Console
  );
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String userRole, // 'walker' or 'wanderer'
  }) async {
    try {
      // Create user account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();

      // Create user profile in Firestore
      UserProfile profile = UserProfile(
        uid: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        userRole: userRole,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createUserProfile(profile);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with the credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Check if user profile exists, if not create one
      UserProfile? existingProfile = await _firestoreService.getUserProfile(userCredential.user!.uid);
      
      if (existingProfile == null) {
        // Create user profile in Firestore
        UserProfile profile = UserProfile(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          displayName: userCredential.user!.displayName ?? '',
          userRole: 'wanderer', // Default role, user can change later
          photoUrl: userCredential.user!.photoURL,
          createdAt: DateTime.now(),
        );
        await _firestoreService.createUserProfile(profile);
      }

      return userCredential;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Try to sign out from Google Sign-In, but don't fail if it errors
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignore Google Sign-In errors
      }
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      if (currentUser != null) {
        // Delete user profile from Firestore
        await _firestoreService.deleteUserProfile(currentUser!.uid);
        
        // Delete user account
        await currentUser!.delete();
      }
    } catch (e) {
      throw Exception('Account deletion failed: $e');
    }
  }

  // Get user profile
  Future<UserProfile?> getUserProfile() async {
    if (currentUser == null) return null;
    return await _firestoreService.getUserProfile(currentUser!.uid);
  }

  // Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    await _firestoreService.updateUserProfile(profile);
  }

  // Handle authentication exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}

