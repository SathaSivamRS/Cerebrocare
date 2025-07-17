import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // ✅ Persistent instance

  /// 🔹 Sign up with Email & Password
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        await user.sendEmailVerification();

        // ✅ Save user details to Firestore
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "fullName": "",
          "email": email,
          "phone": "",
          "verified": false,
          "createdAt": FieldValue.serverTimestamp(),
        });

        return user;
      }
      return null;
    } catch (e) {
      print("❌ Signup Error: $e");
      return null;
    }
  }

  /// 🔹 Sign in with Email & Password
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        await user.reload(); // 🔄 Refresh user data
        user = FirebaseAuth.instance.currentUser; // Get latest user state

        if (!user!.emailVerified) {
          await user.sendEmailVerification(); // 📨 Resend verification email
          _auth.signOut(); // 🔐 Log out unverified user
          return "⚠️ Warning: Your email is not verified!\n📩 A new verification email has been sent. Please check your inbox.";
        }

        // ✅ Email is verified, update Firestore
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .update({"verified": true});

        return "✅ Login successful!";
      }
      return "❌ Login failed! Please check your credentials.";
    } catch (e) {
      print("❌ Login Error: $e");
      return "❌ Login failed! ${e.toString()}";
    }
  }

  /// 🔹 Google Sign-In with Firestore Check
  Future<User?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut(); // ✅ Ensures fresh sign-in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled login

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection("users")
                .doc(user.uid)
                .get();

        if (!userDoc.exists) {
          // ✅ First-time Google login, save details
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .set({
                "fullName": googleUser.displayName ?? "",
                "email": googleUser.email,
                "phone": user.phoneNumber ?? "",
                "verified": user.emailVerified,
                "createdAt": FieldValue.serverTimestamp(),
              });
          print("✅ New Google User Registered in Firestore!");
        }
      }

      return user;
    } catch (e) {
      print("❌ Google Sign-In Error: $e");
      return null;
    }
  }

  /// 🔹 Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
