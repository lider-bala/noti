import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Client-side bootstrap for a first development/admin account.
///
/// This uses the normal Firebase client SDK. It does not set custom claims:
/// production projects that enforce custom claims still need a backend/Admin SDK
/// provisioning step for high-privilege claims.
class FirebaseInitService {
  static const String adminEmail = 'admin@noti.kg';
  static const String adminPassword = 'admin123';
  static const String adminName = 'Bootstrap Admin';
  static const String adminPhone = '+996555000444';
  static const String schoolId = 'default';

  static Future<bool> initializeFirebaseAdmin() async {
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      UserCredential credential;
      try {
        credential = await auth.createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
      } on FirebaseAuthException catch (error) {
        if (error.code != 'email-already-in-use') {
          rethrow;
        }
        credential = await auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
      }

      final user = credential.user ?? auth.currentUser;
      if (user == null) {
        return false;
      }

      await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('accounts')
          .doc(user.uid)
          .set(
        {
          'id': user.uid,
          'fullName': adminName,
          'email': adminEmail,
          'phone': adminPhone,
          'role': 'admin',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return true;
    } catch (error) {
      debugPrintFirebaseInitError(error);
      return false;
    }
  }

  static void debugPrintFirebaseInitError(Object error) {
    // Keep this quiet enough for release logs but visible during local setup.
    // ignore: avoid_print
    print('Firebase admin bootstrap failed: $error');
  }
}
