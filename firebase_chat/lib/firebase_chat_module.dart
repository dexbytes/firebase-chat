import 'package:firebase_chat/chat_p/shared_preferences_file.dart';
import 'package:firebase_chat/chat_p/utils_p/app_color.dart';
import 'package:firebase_chat/chat_p/utils_p/app_dimens.dart';
import 'package:firebase_chat/screens/inbox_screen.dart';
import 'package:firebase_chat/screens/login_with_email_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
class DemoChet {
    final BuildContext context;
    DemoChet({Key key,@required this.context}){
        if(this.context!=null){
           // appDimens.appDimensFind(context: this.context);
        }
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

/*class BaseScreen extends StatefulWidget {
  @override
  _BaseScreenState createState() => _BaseScreenState();
}
class _BaseScreenState extends State<BaseScreen> {
_BaseScreenState(){
     //Get user chat id to get inbox screen data
      sharedPreferencesFile
          .readStr('chatUid')
          .then((value) {
          Navigator.pop(context);  //Finish Base screen
          if (value != null && value.trim().length > 0) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          InboxScreen(currentUserId: value)));
          }
          else
          {
              Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      LoginWithEmailScreen()));

          }

      });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Container(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors().loaderColor[300]),
              ),
              margin: EdgeInsets.only(bottom: 10),
          ),
        ),
      ),
    );
  }
}*/
