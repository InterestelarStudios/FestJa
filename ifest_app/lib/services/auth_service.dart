import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '385947009360-r2ie89lk7cjftfh82octgc2jh147bs9t.apps.googleusercontent.com',
  );

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current User
  User? get currentUser => _auth.currentUser;

  // Email & Password Sign In
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      debugPrint("Error signing in with email/password: $e");
      rethrow;
    }
  }

  // Email & Password Register
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        if (name.trim().isNotEmpty) {
          await user.updateDisplayName(name.trim());
        }
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'id': user.uid,
          'username': name.trim().isNotEmpty ? name.trim() : "Usuário Fest'Ja",
          'email': email.trim(),
          'image': '',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return credential;
    } catch (e) {
      debugPrint("Error registering with email/password: $e");
      rethrow;
    }
  }

  // Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      debugPrint("Error sending password reset email: $e");
      rethrow;
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
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
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      rethrow;
    }
  }

  // Facebook Sign In
  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success && result.accessToken != null) {
        final OAuthCredential credential = FacebookAuthProvider.credential(
          result.accessToken!.tokenString,
        );
        return await _auth.signInWithCredential(credential);
      } else if (result.status == LoginStatus.cancelled) {
        debugPrint("Facebook sign in cancelled by user");
        return null;
      } else {
        throw FirebaseAuthException(
          code: 'facebook-sign-in-failed',
          message: result.message ?? 'Falha ao autenticar com Facebook',
        );
      }
    } catch (e) {
      debugPrint("Error signing in with Facebook: $e");
      rethrow;
    }
  }

  // Phone Auth - Verify Number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(FirebaseAuthException e) verificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // ANDROID ONLY: Automatically signs in the user
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (String verificationId) {
        // Auto-resolution timed out
      },
    );
  }

  // Phone Auth - Verify OTP
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Error verifying OTP: $e");
      rethrow;
    }
  }

  // Re-authenticate user with current password
  Future<void> reauthenticate(String currentPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nenhum usuário autenticado com e-mail.',
      );
    }
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
  }

  // Update Email
  Future<void> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nenhum usuário logado.',
      );
    }
    await reauthenticate(currentPassword);

    try {
      await user.verifyBeforeUpdateEmail(newEmail.trim());
    } catch (_) {
      // ignore: deprecated_member_use
      await user.updateEmail(newEmail.trim());
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'email': newEmail.trim()});
  }

  // Update Password
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nenhum usuário logado.',
      );
    }
    await reauthenticate(currentPassword);
    await user.updatePassword(newPassword.trim());
  }

  // Delete Account
  Future<void> deleteAccount({required String currentPassword}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nenhum usuário logado.',
      );
    }
    await reauthenticate(currentPassword);

    final uid = user.uid;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    } catch (e) {
      debugPrint("Error deleting user profile: $e");
    }

    await user.delete();
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
