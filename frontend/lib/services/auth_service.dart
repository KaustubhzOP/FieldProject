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

  // Update User Profile Method
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection(AppConstants.usersCollection).doc(userId).update(data);
  }

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
    // Restricted: No admin or driver creation via signup
    if (role == 'admin' || role == 'driver') {
      throw '${role.substring(0, 1).toUpperCase() + role.substring(1)} accounts cannot be created via Signup.';
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
      UserCredential result;
      try {
        result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        // Auto-create the demo admin account if it wasn't registered in Firebase Auth yet
        if (email == 'superadmin@smartwaste.com' && password == '123456') {
          try {
            result = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
          } catch (createError) {
             throw 'Please try logging in again, or ensure the password is correct if the account exists.';
          }
        } else {
          rethrow;
        }
      }

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

      // Force the account selection dialog to appear so you can pick a different account!
      // (This does NOT log you out of your Google account on your phone)
      await googleSignIn.signOut();

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

  // Update user data with safety merge
  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw AppConstants.errorGeneric;
    }
  }

  // Request home location verification
  Future<void> requestHomeVerification(String userId, double lat, double lng) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'pendingLat': lat,
        'pendingLng': lng,
        'homeStatus': 'pending_approval',
      });
    } catch (e) {
      throw 'Failed to submit home request: $e';
    }
  }

  // Admin: Approve or Reject home request
  Future<void> handleHomeApproval(String userId, bool approved) async {
    try {
      if (approved) {
        final doc = await _firestore.collection(AppConstants.usersCollection).doc(userId).get();
        final data = doc.data() as Map<String, dynamic>;
        await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
          'homeLat': data['pendingLat'],
          'homeLng': data['pendingLng'],
          'homeStatus': 'approved',
          'pendingLat': FieldValue.delete(),
          'pendingLng': FieldValue.delete(),
        });
      } else {
        await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
          'homeStatus': 'none', // Reset for retry
          'pendingLat': FieldValue.delete(),
          'pendingLng': FieldValue.delete(),
        });
      }
    } catch (e) {
      throw 'Verification process failed: $e';
    }
  }

  // Request removal of approved home
  Future<void> requestHomeRemoval(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'homeStatus': 'pending_removal',
      });
    } catch (e) {
      throw 'Failed to submit removal request: $e';
    }
  }

  // Admin: Approve home removal
  Future<void> approveHomeRemoval(String userId) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
        'homeLat': FieldValue.delete(),
        'homeLng': FieldValue.delete(),
        'homeStatus': 'none',
      });
    } catch (e) {
      throw 'Removal failed: $e';
    }
  }

  // Demo: Reset home status to allow testing of location flows
  Future<void> resetHomeStatus(String userId) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
        'homeLat': FieldValue.delete(),
        'homeLng': FieldValue.delete(),
        'pendingLat': FieldValue.delete(),
        'pendingLng': FieldValue.delete(),
        'homeStatus': 'none',
      });
    } catch (e) {
      throw 'Failed to reset location: $e';
    }
  }

  // Symmetric Seeding: Create both Auth accounts and tracking markers for the demo fleet
  Future<void> seedDummyTrucks() async {
    final List<Map<String, dynamic>> dummyTrucks = [
      {
        'id': 'dummy_1',
        'driverName': 'Driver 1 (Alpha)',
        'isOnDuty': true,
        'liveLocation': {'lat': 19.0596, 'lng': 72.8295, 'heading': 0.0, 'speed': 10.0},
        'truckNumber': 'MH-01-AA-0001',
        'currentRoute': null,
        'ward': 'Ward 1',
      },
      {
        'id': 'dummy_2',
        'driverName': 'Driver 2 (Beta)',
        'isOnDuty': true,
        'liveLocation': {'lat': 19.0400, 'lng': 72.8500, 'heading': 0.0, 'speed': 10.0},
        'truckNumber': 'MH-01-BB-0002',
        'currentRoute': null,
        'ward': 'Ward 2',
      },
      {
        'id': 'dummy_3',
        'driverName': 'Driver 3 (Gamma)',
        'isOnDuty': true,
        'liveLocation': {'lat': 19.0760, 'lng': 72.8777, 'heading': 0.0, 'speed': 10.0},
        'truckNumber': 'MH-01-CC-0003',
        'currentRoute': null,
        'ward': 'Ward 3',
      },
      {
        'id': 'dummy_4',
        'driverName': 'Driver 4 (Delta)',
        'isOnDuty': true,
        'liveLocation': {'lat': 19.0330, 'lng': 72.8166, 'heading': 0.0, 'speed': 10.0},
        'truckNumber': 'MH-01-DD-0004',
        'currentRoute': null,
        'ward': 'Ward 4',
      },
      {
        'id': 'dummy_5',
        'driverName': 'Driver 5 (Epsilon)',
        'isOnDuty': true,
        'liveLocation': {'lat': 19.0200, 'lng': 72.8300, 'heading': 0.0, 'speed': 10.0},
        'truckNumber': 'MH-01-EE-0005',
        'currentRoute': null,
        'ward': 'Ward 5',
      },
    ];

    final WriteBatch batch = _firestore.batch();

    for (var truck in dummyTrucks) {
      // 1. Update Tracking Profile
      final driverRef = _firestore.collection('drivers').doc(truck['id']);
      batch.set(driverRef, truck, SetOptions(merge: true));

      // 2. Update Auth User Profile (so they are selectable in Admin Panel)
      final userRef = _firestore.collection(AppConstants.usersCollection).doc(truck['id']);
      batch.set(userRef, {
        'id': truck['id'],
        'name': truck['driverName'],
        'email': 'driver${truck['id'].split('_')[1]}@gmail.com',
        'role': 'driver',
        'phone': '+91 90000 0000${truck['id'].split('_')[1]}',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    
    await batch.commit();
  }


  // Admin: Assign route to driver
  Future<void> assignRouteToDriver(String driverId, Map<String, dynamic>? route, {String? ward}) async {
    final Map<String, dynamic> trackingUpdates = {
      'currentRoute': route,
    };
    if (ward != null) {
      trackingUpdates['ward'] = ward;
      
      // Also update the main user profile so it shows in their personal profile page
      try {
        await _firestore.collection(AppConstants.usersCollection).doc(driverId).update({
          'ward': ward,
        });
      } catch (e) {
        print('User profile ward update failed: $e');
      }
    }
    
    // Ensure tracking document exists or is updated
    await _firestore
        .collection('drivers')
        .doc(driverId)
        .set(trackingUpdates, SetOptions(merge: true));
  }

  // Seed Demo Residents for pickup simulation
  Future<void> seedDemoResidents() async {
    final List<Map<String, dynamic>> wards = [
      {'name': 'Ward 1', 'lat': 19.0596, 'lng': 72.8295}, // Bandra
      {'name': 'Ward 2', 'lat': 19.0400, 'lng': 72.8500}, // Dharavi
      {'name': 'Ward 3', 'lat': 19.0760, 'lng': 72.8777}, // Kurla
    ];

    final WriteBatch batch = _firestore.batch();

    for (var ward in wards) {
      for (int i = 1; i <= 4; i++) {
        final String resId = 'demo_res_${ward['name'].toString().replaceAll(' ', '_')}_$i';
        final double lat = ward['lat'] + (i * 0.002) - 0.004;
        final double lng = ward['lng'] + (i * 0.001) - 0.002;

        final docRef = _firestore.collection(AppConstants.usersCollection).doc(resId);
        batch.set(docRef, {
          'id': resId,
          'name': 'Resident $i (${ward['name']})',
          'email': 'res${ward['name'].toString().split(' ')[1]}_$i@demo.com',
          'role': AppConstants.roleResident,
          'ward': ward['name'],
          'homeStatus': 'approved',
          'homeLat': lat,
          'homeLng': lng,
          'phone': '+91 98200 ${10000 + i}',
          'address': 'Building $i, Sector ${i+2}, ${ward['name']}',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    await batch.commit();
  }

  // Cleanup: Delete all drivers except the standard demo fleet (Dummy 1-5)
  // Now performs DEEP wipe and throws errors for UI transparency
  Future<void> pruneLegacyDrivers() async {
    final List<String> keepIds = ['dummy_1', 'dummy_2', 'dummy_3', 'dummy_4', 'dummy_5'];
    
    try {
      final batch = _firestore.batch();
      
      // 1. Cleanup drivers collection
      final driverSnapshot = await _firestore.collection('drivers').get();
      for (var doc in driverSnapshot.docs) {
        if (!keepIds.contains(doc.id)) {
          batch.delete(doc.reference);
        }
      }

      // 2. Cleanup users collection (strictly target all 'driver' roles except our IDs)
      final userSnapshot = await _firestore.collection(AppConstants.usersCollection)
          .where('role', isEqualTo: 'driver')
          .get();
      
      for (var doc in userSnapshot.docs) {
        if (!keepIds.contains(doc.id)) {
          batch.delete(doc.reference);
        }
      }
      
      await batch.commit();
    } catch (e) {
      print('Database Pruning Error: $e');
      rethrow; // Ensure UI can catch and show error
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
