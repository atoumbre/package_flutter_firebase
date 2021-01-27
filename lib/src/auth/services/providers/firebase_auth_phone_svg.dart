// import 'dart:async';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:softi_common/index.dart';
// import 'package:softi_firebase_module/services/src/firebase_auth_service/firebase_auth_provider.dart';

// class FirebaseAuthPhone extends FirebaseAuthProvider {
//   FirebaseAuthPhone(FirebaseAuth firebaseAuth) : super(firebaseAuth);

//   Future<AuthCredential> getCredentialForPhone(String verificationId, String smsCode) async {
//     return PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
//   }

//   Future<AuthUser> signInWithPhone(verificationId, smsOTP) async {
//     return signInWithCredential(await getCredentialForPhone(verificationId, smsOTP));
//   }

//   Future<PhoneAuthResult> sendSignInWithPhoneCodeWeb(String phoneNumber) async {
//     var sendCodeCompleter = Completer<SendCodeResult>();

//     var confirmation = await firebaseAuth.signInWithPhoneNumber(phoneNumber);

//     var result = SendCodeResult(
//       phoneNumber: phoneNumber,
//       codeVerification: (code) async => FirebaseAuthProvider.userFromFirebase((await confirmation.confirm(code))),
//       resendCode: () => sendSignInWithPhoneCodeWeb(phoneNumber),
//     );

//     sendCodeCompleter.complete(result);

//     return PhoneAuthResult(
//       sendCodeFuture: await sendCodeCompleter.future,
//       autoRetriveFuture: null,
//     );
//   }

//   Future<PhoneAuthResult> sendSignInWithPhoneCodeNative({
//     String phoneNumber,
//     dynamic resendingId,
//     bool autoRetrive = true,
//     int autoRetrievalTimeoutSeconds = 30,
//   }) async {
//     var sendCodeCompleter = Completer<SendCodeResult>();
//     var autoRetriveCompleter = Completer<AuthUser>();

//     await firebaseAuth.verifyPhoneNumber(
//       phoneNumber: phoneNumber,
//       forceResendingToken: resendingId,
//       codeSent: (verificationId, [resendingId]) {
//         var result = SendCodeResult(
//           phoneNumber: phoneNumber,
//           codeVerification: (code) => signInWithPhone(verificationId, code),
//           resendCode: () => sendSignInWithPhoneCodeNative(
//             phoneNumber: phoneNumber,
//             resendingId: resendingId,
//             autoRetrive: autoRetrive,
//             autoRetrievalTimeoutSeconds: autoRetrievalTimeoutSeconds,
//           ),
//         );

//         sendCodeCompleter.complete(result);
//       },

//       verificationFailed: (FirebaseAuthException authException) {
//         sendCodeCompleter.completeError(authException);

//         return;
//       },

//       //? Auto retrieving flow

//       timeout: Duration(seconds: autoRetrive ? autoRetrievalTimeoutSeconds : 0),

//       verificationCompleted: (AuthCredential authCredential) async {
//         var _user = await signInWithCredential(authCredential);
//         autoRetriveCompleter.complete(_user);
//       },

//       codeAutoRetrievalTimeout: (String verificationId) {
//         // Dismiss autoretrieve timeout
//         return;
//       },
//     );

//     return PhoneAuthResult(
//       sendCodeFuture: await sendCodeCompleter.future,
//       autoRetriveFuture: autoRetriveCompleter.future,
//     );
//   }

//   Future<PhoneAuthResult> sendSignInWithPhoneCode({
//     String phoneNumber,
//     dynamic resendingId,
//     bool autoRetrive = true,
//     int autoRetrievalTimeoutSeconds = 30,
//   }) {
//     if (kIsWeb) {
//       return sendSignInWithPhoneCodeWeb(phoneNumber);
//     } else {
//       return sendSignInWithPhoneCodeNative(
//         phoneNumber: phoneNumber,
//         resendingId: resendingId,
//         autoRetrive: autoRetrive,
//         autoRetrievalTimeoutSeconds: autoRetrievalTimeoutSeconds,
//       );
//     }
//   }
// }
