import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String address = '',
    String ward = '',
  }) async {
    // Restricted: No admin creation via signup
    if (role == 'admin') {
      throw 'Admin accounts cannot be created via Signup.';
    }
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        UserModel userModel = UserModel(
          id: user.uid,
          email: email,
          name: name,
          phone: phone,
          role: role,
          address: address,
          ward: ward,
          createdAt: DateTime.now(),
        );

        // Save user data to Firestore
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set(userModel.toJson());

        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AppConstants.errorGeneric;
    }
    return null;
  }

  // Sign in with email and password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Get user data from Firestore
        DocumentSnapshot doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          return UserModel.fromJson(doc.data() as Map<String, dynamic>);
        } else {
          // Firestore doc is missing — create a fallback profile
          // Determine role from email for demo users
          String role = 'resident';
          String name = user.displayName ?? email.split('@').first;
          if (email.contains('admin')) role = 'admin';
          if (email.contains('driver')) role = 'driver';

          UserModel fallback = UserModel(
            id: user.uid,
            email: email,
            name: name,
            phone: '',
            role: role,
            createdAt: DateTime.now(),
          );

          // Save the fallback profile to Firestore
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(user.uid)
              .set(fallback.toJson());

          return fallback;
        }
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AppConstants.errorGeneric;
    }
    return null;
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignIn googleSignIn = GoogleSignIn();
      
      // Attempt to sign in
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        // Get user data from Firestore or create new profile
        DocumentSnapshot doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          return UserModel.fromJson(doc.data() as Map<String, dynamic>);
        } else {
          // New Google User - create profile
          UserModel newUser = UserModel(
            id: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? 'Resident',
            phone: '',
            role: 'resident', // Default role for Google Sign-in
            createdAt: DateTime.now(),
          );

          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(user.uid)
              .set(newUser.toJson());

          return newUser;
        }
      }
    } catch (e) {
      String errorMessage = 'Google Sign-In failed.';
      if (e.toString().contains('idToken') || e.toString().contains('null')) {
        errorMessage = 'Firebase Configuration Missing: Please add the SHA-1 key and Google Client ID to your Firebase Console.';
      } else if (e.toString().contains('popup_closed_by_user')) {
        errorMessage = 'Sign-in window was closed.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }
      print('Google Sign-In Error: $e');
      throw errorMessage;
    }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AppConstants.errorGeneric;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AppConstants.errorGeneric;
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      throw AppConstants.errorGeneric;
    }
    return null;
  }

  // Update user data
  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .update(user.toJson());
    } catch (e) {
      throw AppConstants.errorGeneric;
    }
  }

  // Handle Firebase Auth Exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? AppConstants.errorAuth;
    }
  }
}
