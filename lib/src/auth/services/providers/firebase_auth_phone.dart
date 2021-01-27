import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:softi_common/auth.dart';
import 'package:softi_firebase_module/src/auth/services/firebase_auth_provider.dart';

class FirebaseAuthPhone extends FirebaseAuthProvider {
  FirebaseAuthPhone(FirebaseAuth firebaseAuth) : super(firebaseAuth);

  Future<AuthCredential> getCredentialForPhone(String verificationId, String smsCode) async {
    return PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
  }

  Future<AuthUser> signInWithPhone(verificationId, smsOTP) async {
    return signInWithCredential(await getCredentialForPhone(verificationId, smsOTP));
  }

  Future<SendCodeResult> _sendSignInWithPhoneCodeWeb(String phoneNumber) async {
    var confirmation = await firebaseAuth.signInWithPhoneNumber(phoneNumber);

    return SendCodeResult(
      phoneNumber: phoneNumber,
      codeVerification: (code) async => FirebaseAuthProvider.userFromFirebase((await confirmation.confirm(code))),
      resendCode: () => _sendSignInWithPhoneCodeWeb(phoneNumber),
    );
  }

  Future<SendCodeResult> _sendSignInWithPhoneCodeNative({
    String phoneNumber,
    dynamic resendingId,
    bool autoRetrive = true,
    int autoRetrievalTimeoutSeconds = 30,
  }) async {
    var _sendCodeCompleter = Completer<SendCodeResult>();

    var autoRetriveCompleter = Completer<AuthUser>();

    await firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: resendingId,
      codeSent: (verificationId, [resendingId]) {
        var result = SendCodeResult(
          ///
          phoneNumber: phoneNumber,

          ///
          codeVerification: (code) async {
            var _result = await signInWithPhone(verificationId, code);
            autoRetriveCompleter.complete(_result);
            return _result;
          },

          ///
          resendCode: () => _sendSignInWithPhoneCodeNative(
            phoneNumber: phoneNumber,
            resendingId: resendingId,
            autoRetrive: autoRetrive,
            autoRetrievalTimeoutSeconds: autoRetrievalTimeoutSeconds,
          ),

          ///
          authResult: autoRetriveCompleter.future,
        );

        _sendCodeCompleter.complete(result);
      },

      verificationFailed: (authException) {
        _sendCodeCompleter.completeError(authException);
        return;
      },

      //? Auto retrieving flow

      timeout: Duration(seconds: autoRetrive ? autoRetrievalTimeoutSeconds : 0),

      verificationCompleted: (AuthCredential authCredential) async {
        var _user = await signInWithCredential(authCredential);
        autoRetriveCompleter.complete(_user);
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        // Dismiss autoretrieve timeout
        return;
      },
    );

    return _sendCodeCompleter.future;
  }

  Future<SendCodeResult> sendSignInWithPhoneCode({
    String phoneNumber,
    dynamic resendingId,
    bool autoRetrive = true,
    int autoRetrievalTimeoutSeconds = 30,
  }) {
    if (kIsWeb) {
      return _sendSignInWithPhoneCodeWeb(phoneNumber);
    } else {
      var test = _sendSignInWithPhoneCodeNative(
        phoneNumber: phoneNumber,
        resendingId: resendingId,
        autoRetrive: autoRetrive,
        autoRetrievalTimeoutSeconds: autoRetrievalTimeoutSeconds,
      );
      return test;
    }
  }
}
