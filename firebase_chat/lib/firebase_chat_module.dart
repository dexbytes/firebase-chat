import 'package:firebase_chat/chat_p/shared_preferences_file.dart';
import 'package:firebase_chat/chat_p/utils_p/app_color.dart';
import 'package:firebase_chat/chat_p/utils_p/app_dimens.dart';
import 'package:firebase_chat/screens/inbox_screen.dart';
import 'package:firebase_chat/screens/login_with_email_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
class FireBaseChat {
    final BuildContext context;
    FireBaseChat({Key key,@required this.context}){
        if(this.context!=null){}
    }
    initChatModule(BuildContext context) => FutureBuilder(
      future: sharedPreferencesFile
          .readStr('chatUid'),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData) {
          var value = snapshot.data;
          return (value != null && value.trim().length > 0)?
          InboxScreen(currentUserId: value):
          LoginWithEmailScreen();
        }
        return LoginWithEmailScreen(); // noop, this builder is called again when the future completes
      },
    );
}

