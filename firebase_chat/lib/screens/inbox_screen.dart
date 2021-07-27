import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_chat/chat_p/custom_widget/poup_menu_widgets.dart';
import 'package:firebase_chat/chat_p/shared_preferences_file.dart';
import 'package:firebase_chat/chat_p/utils_p/app_color.dart';
import 'package:firebase_chat/chat_p/utils_p/app_dimens.dart';
import 'package:firebase_chat/chat_p/utils_p/app_fonts.dart';
import 'package:firebase_chat/chat_p/utils_p/back_arrow_with_title_and_sub_title_app_bar.dart';
import 'package:firebase_chat/chat_p/utils_p/custome_view.dart';
import 'package:firebase_chat/chat_p/utils_p/project_utils.dart';
import 'package:firebase_chat/firebse_chat_main.dart';
import 'package:firebase_chat/screens/group_chat_screen.dart';
import 'package:firebase_chat/screens/login_with_email_screen.dart';
import 'package:firebase_chat/screens/one_to_one_chat_screen.dart';
import 'package:firebase_chat/screens/groups_list_screen.dart';
import 'package:firebase_chat/screens/users_list_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class InboxScreen extends StatefulWidget {
  final String currentUserId;
  InboxScreen({Key key, @required this.currentUserId}) : super(key: key);
  @override
  _InboxScreen createState() => _InboxScreen(currentUserId: this.currentUserId);
}

class _InboxScreen extends State<InboxScreen> with WidgetsBindingObserver {
  int followersOrFollowing = 2;
  String currentUserId;

  String authorization;
  bool isLoading = false;
  List<dynamic> inboxList = new List();
  List<dynamic> inboxUserDetailsList = new List();

  int followStatus = 0;
  int fcmDataretrayCount = 3;

  var academicYearChoices;
  var isSubLoading = false;
  bool isReadyToClick = false;
  String selfUserChatId;

  StreamController<dynamic> streamController = new StreamController();

  _InboxScreen({Key key, @required this.currentUserId}) {
    //To find current screen width
    if (currentUserId == null) {
      currentUserId = "";
    }
    sharedPreferencesFile.readStr('chatUid').then((value) {
      if (value != null && value.trim().length > 0) {
        setState(() {
          selfUserChatId = value;
        });
      }
    });
    fcmDataretrayCount = 3;
  }

  var screenSize, screenHeight, screenWidth;
  int showHideEditProfileSheet = 0;

  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    // Clean up the controller when the widget is disposed.
    WidgetsBinding.instance.removeObserver(this);
    streamController.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // user returned to our app
    } else if (state == AppLifecycleState.inactive) {
      // app is inactive
    } else if (state == AppLifecycleState.paused) {
      // user is about quit our app temporally
    }
  }

  /*Pul To refresh*/
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  /*Pul To refresh*/
  void _onRefresh() async {
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    appDimens.appDimensFind(context: context);
    screenSize = MediaQuery.of(context).size;
    screenHeight = screenSize.height; //Device Screen height
    screenWidth = screenSize.width; //Device Screen Width
    isFollowing = false;

    //Pull to refresh
    Widget centerItemsViewPull1 = SmartRefresher(
      enablePullDown: true,
      enablePullUp: false,
      header: null,
      footer: CustomFooter(
        builder: (BuildContext context, LoadStatus mode) {
          Widget body;
          if (mode == LoadStatus.idle) {
            body = Text("pull up load");
          } else if (mode == LoadStatus.loading) {
            body = CupertinoActivityIndicator();
          } else if (mode == LoadStatus.failed) {
            body = Text("Load Failed!Click retry!");
          } else {
            body = Text("No more Data");
          }
          return Container(
            height: 55.0,
            child: Center(child: body),
          );
        },
      ),
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      child: StreamBuilder(
        stream: FireBaseStore()
            .getChatInboxFireBase(uId: currentUserId, isAll: false)
            .asStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors().loaderColor[300]),
              ),
            );
          } else {
            return snapshot.data.length > 0
                ? ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      appDimens.horizontalMarginPadding(value: 15),
                      appDimens.horizontalMarginPadding(value: 20),
                      appDimens.horizontalMarginPadding(value: 15),
                      appDimens.horizontalMarginPadding(value: 20),
                    ),
                    itemBuilder: (context, index) =>
                        buildItemRow(context, snapshot.data[index]),
                    itemCount: snapshot.data.length,
                  )
                : Center(child: Text("No Chat Found!"));
          }
        },
      ),
    );

    Widget menuOverFlow = Container(
      width: 50,
      child: Align(
        alignment: Alignment.centerRight,
        child: PoupMenuWidgets(
          itemList: <Choice>[
            Choice(title: 'Groups', icon: Icons.edit, id: 0),
            Choice(title: 'Users', icon: Icons.edit, id: 1),
            Choice(title: 'Log Out', icon: Icons.delete, id: 2),
          ],
          selectedCallBack: (value, choiceValue) async {
            if (value != null) {
              //Groups List
              if (value == 0) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => GroupsListScreen(
                              isAllGroups: true,
                              selectedUChatId: selfUserChatId,
                            )));
              }
              //Users list
              else if (value == 1) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => UsersListScreen()));
              }

              //Logout
              else if (value == 2) {
                await sharedPreferencesFile.saveStr(
                    "chatUid", ""); // Re-save Chat uid on logout
                Navigator.pop(context); //Finish Base screen
                //Redirect to login screen
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LoginWithEmailScreen()));
              }
            }
          },
        ),
      ),
    );
    //App bar
    Widget appBar = appBarBackArrowWithTitleAndSubTitle
        .appBarWithLeftRightIconTitleSubtitle(
            statusbarHeight: MediaQuery.of(context).padding.top,
            title: "Inbox",
            appBarBgColor: appColors.appBarBgColor,
            titleColor: appColors.appBarTextColor[600],
            titleFontSize: appDimens.fontSize(value: 20),
            rightIcon: menuOverFlow,
            rightIconSize: appDimens.widthDynamic(value: 22),
            leftIconSize: appDimens.widthDynamic(value: 20),
            onPressed: () {
              Navigator.pop(context);
            },
            onRightIconPressed: () {});

    Future<bool> onBackPress() async {
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      } else if (Platform.isIOS) {
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      } else {
        exit(0);
      }
      return Future.value(false);
    }

    /*==================== Main view ======================*/
    return WillPopScope(
      child: Container(
          color: appColors.appBgColor[200],
          child: SafeArea(
              child: new Scaffold(
            appBar: appBar,
            body: Container(
                padding: EdgeInsets.only(
                  left: appDimens.widthDynamic(value: 20),
                  right: appDimens.widthDynamic(value: 20),
                  //bottom: 0.2
                ),
                color: appColors.appBgColor[400],
                child: Stack(
                  children: <Widget>[
                    // List
                    Container(
                        margin: EdgeInsets.only(
                            top: appDimens.verticalMarginPadding(value: 0)),
                        child: Container(
                          decoration: BoxDecoration(
                            color: appColors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8.0),
                              topRight: Radius.circular(8.0),
                            ),
                          ),
                          child: centerItemsViewPull1,
                        )),
                  ],
                )),
          ))),
      onWillPop: onBackPress,
    );
  }

  Widget buildItemRow(BuildContext context, doc) {
    if (doc == null) {
      return Container();
    } else {
      String time = "", alumniName = "", message = "", profileImage;
      bool isGroupChat = false;
      String gId;
      bool isGroupCreated = false;
      bool isNewMessage = false;
      String otherUid;
      try {
        time = doc['timestamp'];
        alumniName = "";
        profileImage = "";
        isGroupChat = doc['isGroup'];
        otherUid = doc['id'];
        gId = doc['id'];
        time = time;
        if (time != null) {
          time = projectUtil.getTimeAgo(timestamp: int.parse(time));
        }
      } catch (e) {
        print(e);
      }
      return FutureBuilder(
        future: !isGroupChat
            ? FirebaseFirestore.instance
                .collection('users')
                .where('id', isEqualTo: gId)
                .get()
            : FirebaseFirestore.instance
                .collection('user_groups')
                .where('gId', isEqualTo: gId)
                .get(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            var value = snapshot.data;
            final List<DocumentSnapshot> docs = value.docs;
            if (docs.length != 0) {
              //One to One chat
              if (!isGroupChat) {
                profileImage = docs[0]['imageUrl'];
                alumniName = docs[0]['nickName'];
                message = doc['last_message'];
                isNewMessage = !doc['isReded'];
              }
              //Group chat details
              else {
                isGroupCreated =
                    docs[0]['createBy'] == selfUserChatId ? true : false;
                profileImage = docs[0]['image'];
                alumniName = docs[0]['name'];
                message = doc['last_message'];
                isNewMessage = !doc['isReded'];
              }
              return Container(
                child: FlatButton(
                  child: Row(
                    children: <Widget>[
                      //User image
                      Container(
                          child: customView.circularImageOrNameView(
                              appDimens.imageSquareAccordingScreen(value: 44),
                              appDimens.imageSquareAccordingScreen(value: 44),
                              profileImage,
                              alumniName)),

                      //Center text
                      Flexible(
                        // flex: 2,
                        child: Container(
                          // color: Colors.green,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                child: Text(
                                  alumniName ?? "",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: appFonts.defaultFont,
                                    fontSize: appDimens.fontSize(value: 18),
                                    color: appColors.textHeadingColor[100],
                                  ),
                                  maxLines: 1,
                                ),
                                alignment: Alignment.centerLeft,
                                margin:
                                    EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                              ),
                              Container(
                                child: Text('$message',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontFamily: appFonts.defaultFont,
                                        fontSize: appDimens.fontSize(value: 12),
                                        fontWeight: FontWeight.w400,
                                        color:
                                            AppColors().textNormalColor[300]),
                                    maxLines: 1),
                                alignment: Alignment.centerLeft,
                                margin:
                                    EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                              )
                            ],
                          ),
                          margin: EdgeInsets.only(left: 2.0),
                        ),
                      ),
                      Expanded(
                          child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                //color: Colors.red,
                                //width: 70,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    isNewMessage
                                        ? Icon(
                                            Icons.fiber_manual_record,
                                            color: appColors.primaryColor[500],
                                            size: 12,
                                          )
                                        : Container(),
                                    Container(
                                      width: 65,
                                      child: Padding(
                                          padding: EdgeInsets.only(left: 2),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              time != null ? "$time" : "",
                                              //"12:30 dhjgh hd hu u h",
                                              style: TextStyle(
                                                fontFamily:
                                                    appFonts.defaultFont,
                                                fontWeight: FontWeight.w400,
                                                fontSize: appDimens.fontSize(
                                                    value: 12),
                                                color: AppColors()
                                                    .textNormalColor[300],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          )),
                                    ),
                                  ],
                                ),
                              )))
                    ],
                  ),
                  onPressed: () {
                    if (isGroupChat && gId != null) {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => GroupChatScreen(
                                          groupInfo: {
                                            "timestamp": doc['timestamp'],
                                            "image": doc['imageUrl'],
                                            "description": doc['description'],
                                            "gId": doc['gId']
                                          },
                                          peerId: gId,
                                          name: alumniName != null
                                              ? alumniName
                                              : "",
                                          peerAvatar: profileImage,
                                          isGroupChat: true,
                                          isGroupCreated: isGroupCreated)))
                          .then((value) {});
                    }
                    //One to One Chat
                    else {
                      if (otherUid != null && otherUid.toString().length > 0) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => OneToOneChatScreen(
                                      peerId: otherUid,
                                      name:
                                          alumniName != null ? alumniName : "",
                                      peerAvatar: profileImage,
                                      isGroupChat: false,
                                    ))).then((value) {});
                      }
                    }
                  },
                  color: appColors.listRowBgColor[700],
                  padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 22.0),
                ),
                margin: EdgeInsets.only(bottom: 0, left: 0.0, right: 5.0),
              );
            }
            return Container();
          }
          return Container(); // noop, this builder is called again when the future completes
        },
      );
    }
  }
}
