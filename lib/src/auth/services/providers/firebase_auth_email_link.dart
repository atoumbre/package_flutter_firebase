import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:softi_common/auth.dart';
import 'package:softi_firebase/src/auth/services/firebase_auth_provider.dart';

class FirebaseAuthEmailLink extends FirebaseAuthProvider {
  final ActionCodeSettings actionCodeSettings;

  FirebaseAuthEmailLink(FirebaseAuth firebaseAuth, {this.actionCodeSettings}) : super(firebaseAuth);

  Future<AuthCredential> _getCredentialForEmailAndLink(String email, String link) async {
    return EmailAuthProvider.credentialWithLink(email: email, emailLink: link);
  }

  Future<AuthUser> signInWithEmailAndLink({String email, String link}) async {
    return signInWithCredential(await _getCredentialForEmailAndLink(email, link));
  }

  Future<bool> isSignInWithEmailLink(String link) async {
    return Future.value(firebaseAuth.isSignInWithEmailLink(link));
  }

  Future<void> sendSignInWithEmailLink({@required String email}) async {
    return await firebaseAuth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
  }
}
