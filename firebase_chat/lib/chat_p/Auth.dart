import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_chat/chat_p/local_constant.dart';
import 'package:firebase_chat/chat_p/shared_preferences_file.dart';
import 'package:firebase_chat/firebse_chat_main.dart';
import 'package:firebase_chat/screens/inbox_p/models/user.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';


// In case we decide to implement another kind of authorization method
abstract class AuthBase {
  Stream<User> get onAuthStateChanged;
  Future<User> currentUser();
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> createUserWithEmailAndPassword(User user, String password);
  Future<User> signInAnonymously();
  Future<User> signInWithGoogle();
  Future<User> signInWithFacebook();
  Future<String> getFcmToken();
  Future<void> signOut();
}

class Auth implements AuthBase {
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User _userFromFirebase(FirebaseUser firebaseUser) {
    if (firebaseUser == null) {
      return null;
    }

    return User(
      documentID: firebaseUser.uid,
      providerId: firebaseUser.providerId,
      email: firebaseUser.email,
      /*firstName: names[0],
      lastName: names[1],*/
     // displayName: firebaseUser.displayName,
      imageUrl: firebaseUser.photoUrl,
      phoneNumber: firebaseUser.phoneNumber,
      rating: 0,
      fcmToken: '',
      numOfReviews: 0,
      wishlistProducts: [],
      reviewedProducts: [],
    );
  }

  Future<User> _userFromRegisterAndFirebase(FirebaseUser firebaseUser, User newUser) async {
    if (firebaseUser == null) {
      return null;
    }
    //Add new user on fire-base users table
    try {
    await new FireBaseStore().addNewUserOnFireBase(uId:firebaseUser.uid,nickName: newUser.firstName,imageUrl: "");
    }
    catch (e) {
      print(e);
    }
    //Store user chat id
    try {
    await sharedPreferencesFile.saveStr(chatUid,firebaseUser.uid);
    } catch (e) {
      print(e);
    }
   return User(
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
    );
  }

  Stream<User> get onAuthStateChanged {
    return firebaseAuth.onAuthStateChanged.map((FirebaseUser firebaseUser) {
      if (firebaseUser == null) {
        return null;
      }
      return User(documentID: firebaseUser.uid);
    });
  }

  Future<User> currentUser() async {
    FirebaseUser firebaseUser = await FirebaseAuth.instance.currentUser();
    return _userFromFirebase(firebaseUser);
  }

  Future<User> signInAnonymously() async {
    final authResult = await FirebaseAuth.instance.signInAnonymously();
    return _userFromFirebase(authResult.user);
  }

  Future<User> signInWithEmailAndPassword(String email, String password) async {
    final authResult = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (authResult.user == null) {
      return null;
    }
    //Store user chat id
    try {
      await sharedPreferencesFile.saveStr(chatUid,authResult.user.uid);
    } catch (e) {
      print(e);
    }
    return User(documentID: authResult.user.uid);
  }

  Future<User> createUserWithEmailAndPassword(
    User user,
    String password,
  ) async {
    firebaseAuth = FirebaseAuth.instance;
    final authResult = await firebaseAuth.createUserWithEmailAndPassword(
      email: user.email,
      password: password,
    );
    return _userFromRegisterAndFirebase(authResult.user, user);
  }
//Get fire-base token of registered user
  Future<String> getFcmToken() async {
    try {
      final FirebaseMessaging fcm = FirebaseMessaging();
      String fcmToken;
      if (Platform.isIOS) {
        fcm.requestNotificationPermissions(IosNotificationSettings());
      } else {
        fcmToken = await fcm.getToken();
      }
      if (fcmToken != null) {
        return fcmToken;
      }
      else{
        return null;
      }
    } catch (e) {
      return null;

    }
  }
  Future<User> signInWithGoogle() async {
    GoogleSignIn googleSignIn = GoogleSignIn();
    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    if (googleUser != null) {
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.idToken != null && googleAuth.accessToken != null) {
        final authResult = await FirebaseAuth.instance
            .signInWithCredential(GoogleAuthProvider.getCredential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        ));
        return _userFromFirebase(authResult.user);
      } else {
        throw Exception('Missing Google Auth Token');
      }
    } else {
      throw Exception('Google sign in aborted');
    }
  }

  Future<User> signInWithFacebook() async {
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
          .signInWithCredential(FacebookAuthProvider.getCredential(
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
