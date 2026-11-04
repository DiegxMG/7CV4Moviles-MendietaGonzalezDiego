import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      return account;
    } catch (error) {
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.disconnect();
  }

  static Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }
}