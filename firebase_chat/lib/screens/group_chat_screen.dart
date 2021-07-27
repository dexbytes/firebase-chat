import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_chat/chat_p/local_constant.dart';
import 'package:firebase_chat/chat_p/shared_preferences_file.dart';
import 'package:firebase_chat/chat_p/utils_p/app_color.dart';
import 'package:firebase_chat/chat_p/utils_p/app_dimens.dart';
import 'package:firebase_chat/chat_p/utils_p/app_string.dart';
import 'package:firebase_chat/chat_p/utils_p/back_arrow_with_title_and_sub_title_app_bar.dart';
import 'package:firebase_chat/chat_p/utils_p/custome_view.dart';
import 'package:firebase_chat/chat_p/utils_p/project_utils.dart';
import 'package:firebase_chat/chat_p/utils_p/take_photo_with_crop.dart';
import 'package:firebase_chat/firebse_chat_main.dart';
import 'package:firebase_chat/screens/group_channel_information.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupChatScreen extends StatefulWidget {
  final String peerId;
  final String name;
  final String peerAvatar;
  final bool isGroupChat;
  final bool isGroupCreated;
  final groupInfo;
  GroupChatScreen(
      {Key key,
      this.groupInfo,
      @required this.peerId,
      @required this.name,
      @required this.peerAvatar,
      @required this.isGroupChat,
      @required this.isGroupCreated})
      : super(key: key);

  @override
  ChatScreenState createState() => ChatScreenState(
      peerId: this.peerId,
      name: this.name,
      peerAvatar: this.peerAvatar,
      isGroupChat: this.isGroupChat,
      groupInfo: this.groupInfo,
      isGroupCreated: this.isGroupCreated);
}

class ChatScreenState extends State<GroupChatScreen> {
  FireBaseStore _firebaseStore = new FireBaseStore();
  DocumentSnapshot fcmGroupDetails;
  int messageCountSent = 0;
  int messageCountReceived = 0;
  String selfChatId;
  var startDate;
  bool isDateStart = false;
  bool isGroupCreated;
  var groupInfo;

  ChatScreenState(
      {Key key,
      @required this.name,
      @required this.peerId,
      @required this.peerAvatar,
      @required this.isGroupChat,
      @required this.isGroupCreated,
      this.groupInfo}) {
    _firebaseStore = new FireBaseStore();

    //Update chat read status
    _firebaseStore.inboxUpdateMessageReadStatusFireBase(uId: peerId);

    //Get other user details
    _firebaseStore.getGroupDetailsFireBase(uId: peerId).then((value) {
      if (value != null) {
        fcmGroupDetails = value;
        setState(() {
          groupInfo = value;
          groupName = groupInfo['name'];
        });
      }
    });
  }
  String peerId;
  String peerAvatar;
  String selfAvatar;
  String id; //Chat id
  String name = 'NA';
  String groupName = '';
  final bool isGroupChat;

  var listMessage;
  String groupChatId;
  SharedPreferences prefs;

  File imageFile;
  bool isLoading;
  bool isShowSticker;
  String imageUrl;

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(onFocusChange);
    groupChatId = '';
    isLoading = false;
    isShowSticker = false;
    imageUrl = '';
    readLocal();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    super.dispose();
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
        isShowSticker = false;
      });
    }
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    sharedPreferencesFile.readStr(userFullNameC).then((value) {
      setState(() {
        name = value;
      });
    });

    sharedPreferencesFile.readStr(UserProfileImageThumbnailC).then((value) {
      setState(() {
        selfAvatar = value;
      });
    });

    id = await sharedPreferencesFile.readStr('chatUid') ?? '';
    selfChatId = await sharedPreferencesFile.readStr('chatUid') ?? '';

    //Group Chat
    if (isGroupChat) {
      groupChatId = '$peerId';
    }
    //Single chat
    else {
      groupChatId = '$peerId-$id';
    }
    FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .update({'chattingWith': peerId});
    setState(() {});
  }

  Future getImage() async {
    TakePhotoWithCrop(context: context).takeMediaBottomSheet(
        ratio: 1,
        backPress: () {
          Navigator.pop(context, true);
        },
        callBack: (imageFileTemp, imagePathTemp) {
          //print('file into string=====================  ${imageFileTemp.path} ##### ${imagePathTemp}');
          if (imageFileTemp != null && imagePathTemp != null) {
            setState(() {
              imageFile = imageFileTemp;
              if (imageFile != null) {
                setState(() {
                  isLoading = true;
                });
                uploadFile();
              }
            });
          }
        });
  }

  void getSticker() {
    // Hide keyboard when sticker appear
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  Future uploadFile() async {
    String selfUserId = await sharedPreferencesFile.readStr(chatUid);
    if (selfUserId != null) {
      var imageUrlTemp =
          await _firebaseStore.uploadFileFireBase(imageFile: imageFile);
      if (imageUrlTemp != null) {
        imageUrl = imageUrlTemp.toString();
        setState(() {
          isLoading = false;
          onSendMessage(imageUrl, 1);
        });
      }
    }
  }

  Future onSendMessage(String content, int type) async {
    if (content.trim() != '') {
      try {
        customView.hideKeyboard(context);
      } catch (e) {
        print(e);
      }
      textEditingController.clear();
      //Sent message
      await _firebaseStore.sentMessageFireBase(
          uId: id,
          peerId: peerId,
          groupChatId: groupChatId,
          name: name,
          content: content,
          type: type,
          isFromGroup: true);
      if (fcmGroupDetails != null) {
        try {
          if (fcmGroupDetails['usersDetails'] != null &&
              fcmGroupDetails['usersDetails'].length > 0) {
            List<String> otherUserUid = new List();
            try {
              List<dynamic> usersList = fcmGroupDetails['usersDetails'];

              for (int i = 0; i < usersList.length; i++) {
                try {
                  var listRow = usersList[i];
                  if (listRow['id'] != id) {
                    otherUserUid.add(listRow['id']);
                  }
                } catch (e) {
                  print(e);
                }
              }
            } catch (e) {
              print(e);
            }
            bool isFirstTimeMessage = (messageCountSent == 0) ? true : false;
            await _firebaseStore.sentFCMNotificationFireBase(
                receiverId: otherUserUid,
                senderName: groupName,
                content: content,
                isFromGroup: true,
                isFirstTime: isFirstTimeMessage,
                uId: peerId);
          }
        } catch (e) {
          print(e);
        }
      }
      _scrollToBottom();
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  Widget buildItem(int index, DocumentSnapshot document) {
    String date = projectUtil.getCompareDateStr(
        document['timestamp'], appString.dateFormat, index);
    if (document['idFrom'] == id) {
      messageCountSent++;
      //Self messages
      // Right (my message)
      return Container(
        child: Column(
          children: <Widget>[
            date != null
                ? Row(children: <Widget>[
                    Expanded(
                      child: new Container(
                        margin: EdgeInsets.only(
                            right:
                                appDimens.horizontalMarginPadding(value: 10)),
                        child: Divider(
                          color: appColors.appListDividerColor[600],
                          height: 50,
                        ),
                      ),
                    ),
                    Text(date != null ? date.toString() : "",
                        style: TextStyle(
                          color: appColors.datetimeColor,
                        )),
                    Expanded(
                      child: new Container(
                        margin: EdgeInsets.only(
                            left: appDimens.horizontalMarginPadding(value: 10)),
                        child: Divider(
                          color: appColors.appListDividerColor[600],
                          height: 50,
                        ),
                      ),
                    ),
                  ])
                : Container(),
            Container(
              padding: EdgeInsets.fromLTRB(
                appDimens.horizontalMarginPadding(value: 20),
                appDimens.horizontalMarginPadding(value: 0),
                appDimens.horizontalMarginPadding(value: 20),
                appDimens.horizontalMarginPadding(value: 0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  document['type'] == 0
                      // Text
                      ? Container(
                          child: Text(
                            document['content'],
                            style:
                                TextStyle(color: appColors.chatSelfTextColor),
                          ),
                          padding: EdgeInsets.fromLTRB(
                              appDimens.horizontalMarginPadding(
                                  value:
                                      document['content'].toString().length > 22
                                          ? 28
                                          : 15),
                              appDimens.horizontalMarginPadding(
                                  value:
                                      document['content'].toString().length > 22
                                          ? 20
                                          : 15),
                              appDimens.horizontalMarginPadding(
                                  value:
                                      document['content'].toString().length > 22
                                          ? 28
                                          : 15),
                              appDimens.horizontalMarginPadding(
                                  value:
                                      document['content'].toString().length > 22
                                          ? 20
                                          : 15)),
                          constraints:
                              BoxConstraints(minWidth: 10, maxWidth: 250),
                          decoration: BoxDecoration(
                              color: appColors.chatSelfRowBgColor,
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(60.0),
                                  topRight: Radius.circular(80.0),
                                  bottomLeft: Radius.circular(60.0))),
                          margin: EdgeInsets.only(
                              bottom: isLastMessageRight(index) ? 0.0 : 0.0,
                              right: 10.0),
                        )
                      : document['type'] == 1
                          ? Container(
                              child: FlatButton(
                                child: Material(
                                  child: Container(
                                      decoration: BoxDecoration(
                                          color: appColors.appTransColor[700],
                                          borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(8.0),
                                              topRight: Radius.circular(8.0),
                                              bottomLeft:
                                                  Radius.circular(8.0))),
                                      child: customView.chatUploadedImageView1(
                                          appDimens.imageSquareAccordingScreen(
                                              value: 125),
                                          appDimens.imageSquareAccordingScreen(
                                              value: 125),
                                          document['content'])),
                                ),
                                onPressed: () {
                                  try {
                                    List<String> imageList = new List();
                                    imageList.add(document['content']);
                                    /* Navigator.push(
                                        context,
                                        SlideRightRoute(
                                            widget: AppScreensFilesLink()
                                                .mFullPhoto(
                                                    url: document['content'],
                                                    title: "Image")));*/
                                  } catch (e) {
                                    print(e);
                                  }
                                },
                                padding: EdgeInsets.all(0),
                              ),
                              margin: EdgeInsets.only(right: 10.0),
                            )

                          // Sticker
                          : Container(
                              child: new Image.asset(
                                'images/${document['content']}.gif',
                                width: 100.0,
                                height: 100.0,
                                fit: BoxFit.cover,
                              ),
                              margin: EdgeInsets.only(
                                  bottom:
                                      isLastMessageRight(index) ? 0.0 : 10.0,
                                  right: 10.0),
                            ),
                  isLastMessageLeft(index)
                      ? Material(
                          child: customView.circularImageOrNameView(
                              appDimens.imageSquareAccordingScreen(value: 34),
                              appDimens.imageSquareAccordingScreen(value: 34),
                              selfAvatar,
                              name),
                          borderRadius: BorderRadius.all(
                            Radius.circular(18.0),
                          ),
                          clipBehavior: Clip.hardEdge,
                        )
                      : Container(width: 35.0),
                ],
                mainAxisAlignment: MainAxisAlignment.end,
              ),
            ),

            // Time
            isLastMessageLeft(index)
                ? Container(
                    child: Text(
                      DateFormat(appString.timeFormat).format(
                          DateTime.fromMillisecondsSinceEpoch(
                              int.parse(document['timestamp']))),
                      style: TextStyle(
                          color: appColors.datetimeColor, fontSize: 12.0),
                    ),
                    margin: EdgeInsets.only(
                        //  left: 5.0,
                        top: appDimens.verticalMarginPadding(value: 7),
                        bottom: 5.0,
                        right: 64),
                  )
                : Container()
          ],
          crossAxisAlignment: CrossAxisAlignment.end,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    }
    //Other's message
    else {
      messageCountReceived++;
      // Left (peer message)
      return Container(
        child: Column(
          children: <Widget>[
            date != null
                ? Row(children: <Widget>[
                    Expanded(
                      child: new Container(
                        margin: EdgeInsets.only(
                            right:
                                appDimens.horizontalMarginPadding(value: 10)),
                        child: Divider(
                          color: appColors.appListDividerColor[600],
                          height: 50,
                        ),
                      ),
                    ),
                    Text(date != null ? date.toString() : "",
                        style: TextStyle(
                          color: appColors.datetimeColor,
                        )),
                    Expanded(
                      child: new Container(
                        margin: EdgeInsets.only(
                            left: appDimens.horizontalMarginPadding(value: 10)),
                        child: Divider(
                          color: appColors.appListDividerColor[600],
                          height: 50,
                        ),
                      ),
                    ),
                  ])
                : Container(),
            Container(
                padding: EdgeInsets.fromLTRB(
                  appDimens.horizontalMarginPadding(value: 20),
                  appDimens.horizontalMarginPadding(value: 0),
                  appDimens.horizontalMarginPadding(value: 20),
                  appDimens.horizontalMarginPadding(value: 0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    isLastMessageLeft(index)
                        ? Material(
                            child: FutureBuilder(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .where('id', isEqualTo: document['idFrom'])
                                  .get(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<dynamic> snapshot) {
                                if (snapshot.hasData) {
                                  var value = snapshot.data;
                                  final List<DocumentSnapshot> documents =
                                      value.documents;
                                  if (documents.length != 0) {
                                    /*ProjectUtil.printP(
                                        "UsrData ", "$documents");*/
                                    var dta = documents[0]['imageUrl'];
                                    var name = documents[0]['nickName'];
                                    return GestureDetector(
                                        onTap: () {
                                          /*Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      AppScreensFilesLink()
                                                          .mProfileScreen(
                                                              chatUid: document[
                                                                  'idFrom'],
                                                              userId: id,
                                                              name: documents[0]
                                                                      .data[
                                                                  'nickName'],
                                                              peerAvatar:
                                                                  documents[0]
                                                                          .data[
                                                                      'imageUrl'],
                                                              isFromChat:
                                                                  true)));*/
                                        },
                                        child:
                                            customView.circularImageOrNameView(
                                                appDimens
                                                    .imageSquareAccordingScreen(
                                                        value: 34),
                                                appDimens
                                                    .imageSquareAccordingScreen(
                                                        value: 34),
                                                dta,
                                                name));
                                  }
                                  return Container();
                                }
                                return Container(); // noop, this builder is called again when the future completes
                              },
                            ),
                            borderRadius: BorderRadius.all(
                              Radius.circular(18.0),
                            ),
                            clipBehavior: Clip.none,
                          )
                        : Container(width: 35.0),
                    document['type'] == 0
                        ? Container(
                            child: Text(
                              document['content'],
                              style: TextStyle(
                                  color: appColors.chatSenderTextColor),
                            ),
                            padding: EdgeInsets.fromLTRB(
                                appDimens.horizontalMarginPadding(
                                    value:
                                        document['content'].toString().length >
                                                22
                                            ? 28
                                            : 15),
                                appDimens.horizontalMarginPadding(
                                    value:
                                        document['content'].toString().length >
                                                22
                                            ? 20
                                            : 15),
                                appDimens.horizontalMarginPadding(
                                    value:
                                        document['content'].toString().length >
                                                22
                                            ? 28
                                            : 15),
                                appDimens.horizontalMarginPadding(
                                    value:
                                        document['content'].toString().length >
                                                22
                                            ? 20
                                            : 15)),
                            constraints:
                                BoxConstraints(minWidth: 10, maxWidth: 250),
                            decoration: BoxDecoration(
                                color: appColors.chatSenderRowBgColor,
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(80.0),
                                    topRight: Radius.circular(60.0),
                                    bottomRight: Radius.circular(60.0))),
                            margin: EdgeInsets.only(left: 10.0),
                          )
                        : document['type'] == 1
                            ? Container(
                                child: FlatButton(
                                  child: Material(
                                    child: Container(
                                        decoration: BoxDecoration(
                                            color: appColors.appTransColor[700],
                                            borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(8.0),
                                                topRight: Radius.circular(8.0),
                                                bottomRight:
                                                    Radius.circular(8.0))),
                                        child:
                                            customView.chatUploadedImageView1(
                                                appDimens
                                                    .imageSquareAccordingScreen(
                                                        value: 125),
                                                appDimens
                                                    .imageSquareAccordingScreen(
                                                        value: 125),
                                                document['content'])),
                                  ),
                                  onPressed: () {
                                    try {
                                      List<String> imageList = new List();
                                      imageList.add(document['content']);
                                      /*Navigator.push(
                                          context,
                                          SlideRightRoute(
                                              widget: AppScreensFilesLink()
                                                  .mFullPhoto(
                                                      url: document['content'],
                                                      title: "Image")));*/
                                    } catch (e) {
                                      print(e);
                                    }
                                  },
                                  padding: EdgeInsets.all(0),
                                ),
                                margin: EdgeInsets.only(left: 10.0),
                              )
                            : Container(
                                child: new Image.asset(
                                  'images/${document['content']}.gif',
                                  width: 100.0,
                                  height: 100.0,
                                  fit: BoxFit.cover,
                                ),
                                margin: EdgeInsets.only(
                                    bottom:
                                        isLastMessageRight(index) ? 20.0 : 10.0,
                                    right: 10.0),
                              ),
                  ],
                )),
            // Time
            isLastMessageLeft(index)
                ? Container(
                    child: Text(
//                DateFormat('dd MMM kk:mm')
                      DateFormat(appString.timeFormat).format(
                          DateTime.fromMillisecondsSinceEpoch(
                              int.parse(document['timestamp']))),
                      style: TextStyle(
                          color: appColors.datetimeColor, fontSize: 12.0),
                    ),
                    margin: EdgeInsets.only(left: 64.0, top: 5.0, bottom: 5.0),
                  )
                : Container()
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    }
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]['idFrom'] == id) ||
        index == 0) {
      return true;
    } else {
      return true;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]['idFrom'] != id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .update({'chattingWith': null});
      Navigator.pop(context);
    }

    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    /*Horizontal Divider*/
    Widget divider() {
      return Divider(
        color: appColors.appDividerColor[600],
        height: 1.0,
      );
    }

    //App bar
    Widget appBar = appBarBackArrowWithTitleAndSubTitle
        .appBarWithLeftRightIconTitleSubtitle(
            statusbarHeight: MediaQuery.of(context).padding.top,
            title: groupName,
            back: true,
            appBarBgColor: appColors.appBarBgColor,
            titleColor: appColors.appBarTextColor[600],
            titleFontSize: appDimens.fontSize(value: 20),
            rightIcon: 'packages/firebase_chat/assets/images/info@3x.png',
            rightIconSize: appDimens.widthDynamic(value: 22),
            leftIconSize: appDimens.widthDynamic(value: 20),
            onPressed: () {
              Navigator.pop(context);
            },
            onRightIconPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => GroupChannelInformation(
                          groupInfo: groupInfo,
                          isJoinedGroup: true,
                          isGroupCreated: isGroupCreated)));
              /*Navigator.push(
                      context,
                      SlideRightRoute(
                          widget: AppScreensFilesLink()
                              .mGroupChannelInformation(
                                  groupInfo: groupInfo,
                                  isJoinedGroup: true,
                                  isGroupCreated: isGroupCreated)))
                  .then((value) {
                if (value != null && value) {
                  Navigator.pop(context, true);
                }
              });*/
            });

    return WillPopScope(
      child: Container(
          color: appColors.appBgColor[200],
          child: SafeArea(
              child: new Scaffold(
                  appBar: appBar,
                  body: Stack(
                    children: <Widget>[
                      Container(
                        child: Column(
                          children: <Widget>[
                            divider(),
                            // List of messages
                            buildListMessage(),
                            // Sticker
                            (isShowSticker ? buildSticker() : Container()),
                            // Input content
                            buildInput(),
                          ],
                        ),
                        color: appColors.appBgColor[400],
                      ),
                      // Loading
                      buildLoading()
                    ],
                  )))),
      onWillPop: onBackPress,
    );
  }

  Widget buildSticker() {
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi1', 2),
                child: new Image.asset(
                  'images/mimi1.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi2', 2),
                child: new Image.asset(
                  'images/mimi2.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi3', 2),
                child: new Image.asset(
                  'images/mimi3.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi4', 2),
                child: new Image.asset(
                  'images/mimi4.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi5', 2),
                child: new Image.asset(
                  'images/mimi5.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi6', 2),
                child: new Image.asset(
                  'images/mimi6.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi7', 2),
                child: new Image.asset(
                  'images/mimi7.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi8', 2),
                child: new Image.asset(
                  'images/mimi8.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi9', 2),
                child: new Image.asset(
                  'images/mimi9.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
      decoration: new BoxDecoration(
          border: new Border(
              top: new BorderSide(color: appColors.grey, width: 0.5)),
          color: Colors.white),
      padding: EdgeInsets.all(5.0),
      height: 180.0,
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        appColors.loaderColor[300])),
              ),
              color: Colors.white.withOpacity(0.8),
            )
          : Container(),
    );
  }

  Widget buildInput() {
    return Container(
      height: appDimens.heightDynamic(value: 73),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Edit text
          Flexible(
            child: Container(
              margin: new EdgeInsets.only(
                  left: appDimens.horizontalMarginPadding(value: 18)),
              child: TextField(
                style: TextStyle(
                    color: appColors.textNormalColor,
                    fontSize: appDimens.fontSize(value: 16)),
                controller: textEditingController,
                decoration: InputDecoration.collapsed(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: appColors.editTextHintColor[200]),
                ),
                focusNode: focusNode,
              ),
            ),
          ),
          // Button send image
          Material(
            child: new Container(
                margin: new EdgeInsets.only(
                    top: 0,
                    bottom: 0,
                    right: appDimens.horizontalMarginPadding(value: 20)),
                child: GestureDetector(
                  child: Container(
                    child: Image.asset(
                      'packages/firebase_chat/assets/images/camera.png',
                      height: appDimens.imageSquareAccordingScreen(value: 23),
                      width: appDimens.imageSquareAccordingScreen(value: 23),
                    ),
                    height: appDimens.imageSquareAccordingScreen(value: 23),
                    width: appDimens.imageSquareAccordingScreen(value: 23),
                  ),
                  onTap: () => getImage(),
                )),
            color: appColors.iconColor[300],
          ),
          // Button send message
          Material(
            child: new Container(
                margin: new EdgeInsets.only(top: 0.0, bottom: 0.0, right: 20.0),
                // padding: new EdgeInsets.only(top: 0,bottom:0,right:5.0),
                child: GestureDetector(
                  child: Container(
                    child: Stack(
                      children: <Widget>[
                        Container(
                          height: appDimens.heightDynamic(value: 35),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: appColors.primaryColor.withOpacity(0.1),
                            boxShadow: [
                              BoxShadow(
                                color: appColors.primaryColor.withOpacity(0.22),
                                spreadRadius: 4,
                                blurRadius: 5,
                                offset:
                                    Offset(0, 3), // changes position of shadow
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'packages/firebase_chat/assets/images/send1@2x.png',
                            height:
                                appDimens.imageSquareAccordingScreen(value: 35),
                            width:
                                appDimens.imageSquareAccordingScreen(value: 35),
                          ),
                        )
                      ],
                    ),
                  ),
                  onTap: () => onSendMessage(textEditingController.text, 0),
                )),
            color: appColors.iconColor[300],
          ),
        ],
      ),
      width: double.infinity,
      padding: EdgeInsets.only(top: 0),
      decoration: new BoxDecoration(
          border: new Border(
              top: new BorderSide(color: appColors.grey, width: 0.5)),
          color: appColors.editTextBgColor[500]),
    );
  }

  //date
  Widget showDate(date) {
    return Row(children: <Widget>[
      Expanded(
        child: new Container(
          margin: EdgeInsets.only(
              right: appDimens.horizontalMarginPadding(value: 10)),
          child: Divider(
            color: appColors.appListDividerColor[600],
            height: 50,
          ),
        ),
      ),
      Text(date != null ? date.toString() : ""),
      Expanded(
        child: new Container(
          margin: EdgeInsets.only(
              left: appDimens.horizontalMarginPadding(value: 10)),
          child: Divider(
            color: appColors.appListDividerColor[600],
            height: 50,
          ),
        ),
      ),
    ]);
  }

  //Date view
  String dateSelected(document, index) {
    if (index == 0) {
      startDate = null;
    }
    var currentDate = DateFormat(appString.dateFormat).format(
        DateTime.fromMillisecondsSinceEpoch(int.parse(document['timestamp'])));
    if (startDate == null) {
      startDate = currentDate;
      return currentDate;
    } else {
      if (startDate != null && startDate != currentDate) {
        startDate = currentDate;
        return currentDate;
      } else {
        startDate = currentDate;
        return null;
      }
    }
  }

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId == ''
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      appColors.loaderColor[300])))
          : StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .doc(groupChatId)
                  .collection(groupChatId)
                  .orderBy('timestamp', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              appColors.loaderColor[300])));
                } else {
                  listMessage = snapshot.data.documents;
                  listMessage = listMessage.reversed.toList();
                  Timer(Duration(seconds: 1), () {
                    _scrollToBottom();
                    print("print after every 3 seconds");
                  });
                  return ListView.builder(
                    itemBuilder: (context, index) {
                      return Column(
                        children: <Widget>[
                          buildItem(index, listMessage[index])
                        ],
                      );
                    },
                    itemCount: snapshot.data.documents.length,
                    reverse: false,
                    controller: listScrollController,
                  );
                }
              },
            ),
    );
  }

  //**********  Image cropping End *********** */
  _scrollToBottom() {
    try {
      if (listScrollController != null) {
        listScrollController.animateTo(
            listScrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 5),
            curve: Curves.easeOut);
      }
    } catch (e) {
      print(e);
    }
  }
}
