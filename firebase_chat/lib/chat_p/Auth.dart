import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_chat/chat_p/local_constant.dart';
import 'package:firebase_chat/chat_p/shared_preferences_file.dart';
import 'package:firebase_chat/firebse_chat_main.dart';
import 'package:firebase_chat/screens/inbox_p/models/user_profile_details.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_chat/screens/inbox_p/models/user_profile_details.dart';

// In case we decide to implement another kind of authorization method
abstract class AuthBase {
  //Stream<UserInfo> get onAuthStateChanged;
  Future<UserInfo> currentUser();
  Future<UserInfo> signInWithEmailAndPassword(String email, String password);
  Future<UserInfo> createUserWithEmailAndPassword(
      UserProfileDetails user, String password);
  Future<UserInfo> signInAnonymously();
  Future<UserInfo> signInWithGoogle();
  Future<UserInfo> signInWithFacebook();
  Future<String> getFcmToken();
  Future<void> signOut();
}

class Auth implements AuthBase {
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  UserInfo _userFromFirebase(UserInfo firebaseUser) {
    if (firebaseUser == null) {
      return null;
    }

    Map<String, String> _data = {
      "uid": firebaseUser.uid,
      "providerId": firebaseUser.providerId,
      "email": firebaseUser.email,
      "displayName": '${firebaseUser.displayName}',
      "photoURL": '${firebaseUser.photoURL}',
      "phoneNumber": firebaseUser.phoneNumber,
    };
    return UserInfo(
            _data) /*UserInfo({
      documentID: firebaseUser.uid,
      providerId: firebaseUser.providerId,
      email: firebaseUser.email,
      */ /*firstName: names[0],
      lastName: names[1],*/ /*
     // displayName: firebaseUser.displayName,
      imageUrl: firebaseUser.photoUrl,
      phoneNumber: firebaseUser.phoneNumber,
      rating: 0,
      fcmToken: '',
      numOfReviews: 0,
      wishlistProducts: [],
      reviewedProducts: []}
    )*/
        ;
  }

  Future<UserInfo> _userFromRegisterAndFirebase(
      UserInfo firebaseUser, UserProfileDetails newUser) async {
    if (firebaseUser == null) {
      return null;
    }
    //Add new user on fire-base users table
    try {
      await new FireBaseStore().addNewUserOnFireBase(
          uId: firebaseUser.uid, nickName: newUser.displayName, imageUrl: "");
    } catch (e) {
      print(e);
    }
    //Store user chat id
    try {
      await sharedPreferencesFile.saveStr(chatUid, firebaseUser.uid);
    } catch (e) {
      print(e);
    }

    Map<String, String> _data = {
      "uid": firebaseUser.uid,
      "providerId": firebaseUser.providerId,
      "email": newUser.email,
      "displayName": '${firebaseUser.displayName}',
      "photoURL": '${firebaseUser.photoURL}',
      "phoneNumber": newUser.phoneNumber,
    };
    return UserInfo(
            _data) /*UserInfo(
      documentID: firebaseUser.uid,
      providerId: firebaseUser.providerId,
      email: newUser.email,
      firstName: newUser.firstName,
      lastName: newUser.lastName,
      displayName: '${newUser.firstName} ${newUser.lastName}',
      imageUrl: null,
      phoneNumber: newUser.phoneNumber,
      rating: 0,
      fcmToken: '',
      numOfReviews: 0,
      wishlistProducts: [],
      reviewedProducts: [],
    )*/
        ;
  }

  /*Stream<UserInfo> get onAuthStateChanged {
    return firebaseAuth.onAuthStateChanged.map((UserInfo firebaseUser) {
      if (firebaseUser == null) {
        return null;
      }
      return UserInfo({"uid": firebaseUser.uid});
    });
  }*/

  Future<UserInfo> currentUser() async {
    var authResult = await FirebaseAuth.instance.currentUser;
    Map<String, String> _data = {
      "uid": authResult.uid,
      // "providerId": authResult.providerId,
      "email": authResult.email,
      "displayName": '${authResult.displayName}',
      "photoURL": '${authResult.photoURL}',
      "phoneNumber": '${authResult.phoneNumber}',
    };
    return _userFromFirebase(UserInfo(_data));
    //return _userFromFirebase(firebaseUser);
  }

  Future<UserInfo> signInAnonymously() async {
    final authResult = await FirebaseAuth.instance.signInAnonymously();
    Map<String, String> _data = {
      "uid": authResult.user.uid,
      "providerId": authResult.additionalUserInfo.providerId,
      "email": authResult.user.email,
      "displayName": '${authResult.user.displayName}',
      "photoURL": '${authResult.user.photoURL}',
      "phoneNumber": '${authResult.user.phoneNumber}',
    };
    return _userFromFirebase(UserInfo(_data));
    //return _userFromFirebase(authResult.additionalUserInfo);
  }

  Future<UserInfo> signInWithEmailAndPassword(
      String email, String password) async {
    final authResult = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (authResult.user == null) {
      return null;
    }
    //Store user chat id
    try {
      await sharedPreferencesFile.saveStr(chatUid, authResult.user.uid);
    } catch (e) {
      print(e);
    }
    return UserInfo({"uid": authResult.user.uid});
  }

  Future<UserInfo> createUserWithEmailAndPassword(
    UserProfileDetails user,
    String password,
  ) async {
    firebaseAuth = FirebaseAuth.instance;
    final authResult = await firebaseAuth.createUserWithEmailAndPassword(
      email: user.email,
      password: password,
    );

    Map<String, String> _data = {
      "uid": authResult.user.uid,
      "providerId": authResult.additionalUserInfo.providerId,
      "email": authResult.user.email,
      "displayName": '${authResult.user.displayName}',
      "photoURL": '${authResult.user.photoURL}',
      "phoneNumber": '${authResult.user.phoneNumber}',
    };
    // return _userFromFirebase(UserInfo(_data));
    return _userFromRegisterAndFirebase(UserInfo(_data), user);
  }

//Get fire-base token of registered user
  Future<String> getFcmToken() async {
    try {
      final FirebaseMessaging fcm = FirebaseMessaging.instance;
      String fcmToken;
      if (Platform.isIOS) {
        fcm.requestPermission(
            /*IosNotificationSettings()*/ criticalAlert: true);
      } else {
        fcmToken = await fcm.getToken();
      }
      if (fcmToken != null) {
        return fcmToken;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<UserInfo> signInWithGoogle() async {
    GoogleSignIn googleSignIn = GoogleSignIn();
    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    if (googleUser != null) {
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.idToken != null && googleAuth.accessToken != null) {
        final authResult = await FirebaseAuth.instance
            .signInWithCredential(GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        ));

        Map<String, String> _data = {
          "uid": authResult.user.uid,
          "providerId": authResult.additionalUserInfo.providerId,
          "email": authResult.user.email,
          "displayName": '${authResult.user.displayName}',
          "photoURL": '${authResult.user.photoURL}',
          "phoneNumber": '${authResult.user.phoneNumber}',
        };
        return _userFromFirebase(UserInfo(_data));
      } else {
        throw Exception('Missing Google Auth Token');
      }
    } else {
      throw Exception('Google sign in aborted');
    }
  }

  Future<UserInfo> signInWithFacebook() async {
/*    final facebookLogin = FacebookLogin();
    FacebookLoginResult result = await facebookLogin.logIn(
      [
        'public_profile',
        'email',
        'user_friends',
      ],
    );
    if (result.accessToken != null) {
      final authResult = await firebaseAuth
          .signInWithCredential(FacebookAuthProvider.credential(
        accessToken: result.accessToken.token,
      ));
      return _userFromFirebase(authResult.user);
    } else {
      throw Exception('Missing Facebook Access Token');
    }*/
    return null;
  }

  Future<void> signOut() async {
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();

    /*final facebookLogin = FacebookLogin();
    facebookLogin.logOut();*/

    return await firebaseAuth.signOut();
  }
}
