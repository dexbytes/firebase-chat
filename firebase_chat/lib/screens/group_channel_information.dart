import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_chat/chat_p/shared_preferences_file.dart';
import 'package:firebase_chat/chat_p/utils_p/app_animation.dart';
import 'package:firebase_chat/chat_p/utils_p/app_color.dart';
import 'package:firebase_chat/chat_p/utils_p/app_dimens.dart';
import 'package:firebase_chat/chat_p/utils_p/app_fonts.dart';
import 'package:firebase_chat/chat_p/utils_p/app_string.dart';
import 'package:firebase_chat/chat_p/utils_p/back_arrow_with_title_and_sub_title_app_bar.dart';
import 'package:firebase_chat/chat_p/utils_p/cached_network_image_p/cached_network_image.dart';
import 'package:firebase_chat/chat_p/utils_p/custome_view.dart';
import 'package:firebase_chat/firebse_chat_main.dart';
import 'package:firebase_chat/screens/group_chat_screen.dart';
import 'package:firebase_chat/screens/inbox_p/models/user.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GroupChannelInformation extends StatefulWidget {
  final groupInfo;
  final bool isJoinedGroup, isGroupCreated;

  GroupChannelInformation(
      {Key key, this.groupInfo, this.isJoinedGroup, this.isGroupCreated})
      : super(key: key);

  @override
  _GroupChannelInformationState createState() => _GroupChannelInformationState(
      this.groupInfo, this.isJoinedGroup, this.isGroupCreated);
}

class _GroupChannelInformationState extends State<GroupChannelInformation> {
  String groupCreatedBy,
      createdDate,
      groupDescription =
          "Energistically morph pandemic relationships vis-a-vis timely technology. Energistically synthesize dynamic total.",
      groupImage;
  var groupInfo;
  bool isJoinedGroup = false;
  bool isGroupCreated = false;
  var groupId;
  var groupDetails;
  var isSubLoading = false;
  var isLoading = false;
  String uId;

  double groupImageHeight = appDimens.widthFullScreen() - 40;
  double groupImageWidth =appDimens.widthFullScreen();

  _GroupChannelInformationState(groupInfo, isJoinedGroup, isGroupCreated) {
    this.groupInfo = groupInfo;
    if (isGroupCreated != null) {
      this.isGroupCreated = isGroupCreated;
    }
    groupCreatedBy = "";
    createdDate = groupInfo['timestamp'];
    groupImage = groupInfo['image'];
    groupDescription = groupInfo['description'];
    try {
      groupId = groupInfo['gId'];

    } catch (e) {
      print(e);
    }
    this.isJoinedGroup = isJoinedGroup;

    sharedPreferencesFile
        .readStr("chatUid")
        .then((value) {
      if (value != null && value != '') {
        setState(() {
          uId = value;
        });
      }
    });

    groupInformation(groupInfo);
  }

  //Back press
  Future<bool> onBackPress() {
    if (isJoinedGroup) {
      return Future.value(true);
    } else {
      Navigator.pop(context, true);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onBackPress,
      child: Container(
          color: appColors.appBgColor[200],
          child:  SafeArea(
              child:Scaffold(
        backgroundColor: appColors.appBgColor[400],
        appBar:appBarBackArrowWithTitleAndSubTitle.appBarWithLeftRightIconTitleSubtitle(
          statusbarHeight:MediaQuery.of(context).padding.top,
          title: appString.appBarGroupInformation,
          back: true,
          appBarBgColor: appColors.appBarBgColor,
          titleColor: appColors.appBarTextColor[600],
          titleFontSize: appDimens.fontSize(value: 20),
          leftIconSize: appDimens.widthDynamic(value: 20),
          onPressed: (){
            Navigator.pop(context);
          },
        ),
        body: Container(
          // color: Colors.red,
          margin: EdgeInsets.fromLTRB(
              appDimens.horizontalMarginPadding(value: 20),
              appDimens.verticalMarginPadding(value: 0),
              appDimens.horizontalMarginPadding(value: 20),
              appDimens.verticalMarginPadding(value: 20)),
          child: ListView(
            children: <Widget>[
              //Image View
              (groupImage != null && groupImage != "")
                  ? CachedNetworkImage(
                      imageUrl: groupImage,
                      imageBuilder: (context, imageProvider) => Container(
                        margin: EdgeInsets.only(
                          top: appDimens.horizontalMarginPadding(value: 20),
                        ),
                        height: groupImageHeight,
                        width: groupImageWidth,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.all(Radius.circular(9)),
                          image: DecorationImage(
                            image: NetworkImage(
                              groupImage,
                            ),
                            fit: BoxFit.fill,
                          ), //It is just a dummy image
                        ),
                      ),
                      placeholder: (context, url) => Container(
                        margin: EdgeInsets.only(
                          top: appDimens.horizontalMarginPadding(value: 20),
                        ),
                        height: groupImageHeight, //previous height  - 181
                        width: groupImageWidth,

                        //border radius according to number of images
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.all(Radius.circular(9)),
                          //It is just a dummy image
                        ),
                        child: appAnimation.mShimmerEffectClass.shimmerEffectNewsFeedList(
                                shimmerBaseColor: null,
                                shimmerHighlightColor: null,
                                height: groupImageHeight,
                                width: groupImageWidth),
                      ),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    )
                  : Container(),

              //Group information card
              Card(
                margin: EdgeInsets.only(
                  top: appDimens.verticalMarginPadding(
                          value: (groupImage != null && groupImage != "")
                              ? 27
                              : 20),
                ),
                elevation: 0.2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: Container(
                    padding: EdgeInsets.fromLTRB(
                      appDimens.verticalMarginPadding(value: 22),
                      appDimens.verticalMarginPadding(value: 16),
                      appDimens.verticalMarginPadding(value: 22),
                      appDimens.verticalMarginPadding(value: 22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "Author: ",
                              style: TextStyle(
                                  fontFamily: appFonts.defaultFont,
                                  fontSize: appDimens.fontSize(value: 16),
                                  //fontWeight: FontWeight.w400,
                                  color: appColors.textNormalColor[400]),
                            ),
                            Flexible(
                              child: Text(
                                groupCreatedBy ?? "",
                                style: TextStyle(
                                    fontFamily: appFonts.defaultFont,
                                    fontSize: appDimens.fontSize(value: 16),
                                    //fontWeight: FontWeight.w400,
                                    color: appColors.textNormalColor[400]),
                              ),
                            )
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              top: appDimens.verticalMarginPadding(value: 13)),
                          child: Row(
                            children: <Widget>[
                              Text(
                                "Created: ",
                                style: TextStyle(
                                    fontFamily: appFonts.defaultFont,
                                    fontSize: appDimens.fontSize(value: 16),
                                    //fontWeight: FontWeight.w400,
                                    color: appColors.textNormalColor[400]),
                              ),
                              Flexible(
                                child: Text(
                                  createdDate != null
                                      ? customView.getTimeByMilliseconds(
                                              int.parse(createdDate),
                                              appString.dateFormat)
                                      : '',
                                  style: TextStyle(
                                      fontFamily: appFonts.defaultFont,
                                      fontSize: appDimens.fontSize(value: 16),
                                      //fontWeight: FontWeight.w400,
                                      color: appColors.textNormalColor[400]),
                                ),
                              )
                            ],
                          ),
                        ),
                        (groupDescription != null && groupDescription != "")
                            ? ListView(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.only(
                                        top: appDimens.verticalMarginPadding(value: 34)),
                                    child: Text(
                                      appString.textGroupDescription,
                                      style: TextStyle(
                                          fontFamily: appFonts.defaultFont,
                                          fontSize: appDimens.fontSize(value: 16),
                                          //fontWeight: FontWeight.w400,
                                          color: appColors.textNormalColor[400]),
                                    ),
                                  ),
                                  Container(
                                    width: appDimens.widthFullScreen() -
                                        70,
                                    margin: EdgeInsets.only(
                                      top: appDimens.verticalMarginPadding(value: 13),
                                    ),
                                    decoration: BoxDecoration(
                                      color: appColors.appBgColor[400],
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(appDimens.widthDynamic(value: 3))),
                                    ),
                                    padding: EdgeInsets.fromLTRB(
                                      appDimens.verticalMarginPadding(value: 15),
                                      appDimens.verticalMarginPadding(value: 8),
                                      appDimens.verticalMarginPadding(value: 15),
                                      appDimens.verticalMarginPadding(value: 15),
                                    ),
                                    child: Text(
                                      groupDescription ?? "",
                                      style: TextStyle(
                                          height: appDimens.verticalMarginPadding(
                                                  value: 1.5),
                                          fontFamily: appFonts.defaultFont,
                                          fontSize: appDimens.fontSize(value: 14),
                                          //fontWeight: FontWeight.w400,
                                          color: appColors.textNormalColor[400]),
                                    ),
                                  )
                                ],
                              )
                            : Container(),
                      ],
                    )),
              ),

              !isGroupCreated
                  ? Container(
                      height: appDimens.buttonHeight(value: 50),
                      margin: EdgeInsets.only(
                          top: appDimens.verticalMarginPadding(value: 20)),
                      child: Align(
                          alignment: Alignment.center,
                          child: Stack(
                            children: <Widget>[
                              isSubLoading
                                  ? Container(
                                child: CircularProgressIndicator(
                                  valueColor: new AlwaysStoppedAnimation<Color>(
                                      appColors.loaderColor[300]),
                                ),
                                margin: EdgeInsets.only(bottom: 10),
                              )
                                  : customView.buttonRoundCornerWithBg(
                                          isJoinedGroup
                                              ? appString.buttonLeft
                                              : appString.buttonJoin,
                                          appColors.buttonTextColor,
                                  appColors.buttonBgColor[100],
                                          appDimens.fontSize(value: 18),
                                          2, (value) async {
                                      FocusScope.of(context)
                                          .requestFocus(new FocusNode());
                                      if (isJoinedGroup) {
                                        leftGroupView(groupId);
                                      } else if (!isJoinedGroup) {
                                        joinGroupDetails(groupInfo);
                                      }
                                    })
                            ],
                          )))
                  : Container()
            ],
          ),
        ),
      ))),
    );
  }

  Future<void> groupInformation(groupInfo) async {
    try {
      if (groupInfo != null) {
        String createById = groupInfo['createBy'];

        final QuerySnapshot result = await Firestore.instance
            .collection('users')
            .where('id', isEqualTo: createById)
            .getDocuments();
        final List<DocumentSnapshot> documents = result.documents;
        if (documents.length != 0) {
          print(" UsrData $documents");
          var nickName = documents[0].data['nickName'];
          setState(() {
            if (nickName != null) {
              groupCreatedBy = nickName;
              groupCreatedBy = groupCreatedBy.trim();
            }
          });
        }
        return true;
      } else {
        return true;
      }
    } catch (e) {
      print(e);
    }
  }

  //Filter pop up view
  Widget deleteView() {
    return Container(
      margin: EdgeInsets.only(
          bottom: appDimens.verticalMarginPadding(value: 5),
          left: appDimens.verticalMarginPadding(value: 25),
          right: appDimens.verticalMarginPadding(value: 25)),
      child: Container(
        child: Stack(
          children: <Widget>[
            SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    //confirmation message
                    Container(
                      padding: EdgeInsets.only(
                          bottom: appDimens.verticalMarginPadding(value: 12)),
                      child: Text(
                        appString.confirmationLeftGroupMessage,
                        style: TextStyle(
                            fontSize: appDimens.fontSize(value: 16),
                            fontFamily:appFonts.defaultFont,
                            color: appColors.textNormalColor),
                      ),
                    ),

                    //Save button
                    Container(
                        height: appDimens.buttonHeight(value: 50),
                        child: Align(
                            alignment: Alignment.center,
                            child: Stack(
                              children: <Widget>[
                                isSubLoading
                                    ? Container(
                                  child: CircularProgressIndicator(
                                    valueColor: new AlwaysStoppedAnimation<Color>(
                                        appColors.loaderColor[300]),
                                  ),
                                  margin: EdgeInsets.only(bottom: 10),
                                )
                                    : customView.buttonRoundCornerWithBg(
                                            appString.buttonConfirm,
                                            appColors
                                                .buttonTextColor,
                                            appColors
                                                .buttonBgColor[100],
                                            appDimens.fontSize(value: 18),
                                            2, (value) async {
                                        FocusScope.of(context)
                                            .requestFocus(new FocusNode());
                                        Navigator.pop(context);
                                        leftGroupDetails(groupId);
                                      })
                              ],
                            ))),

                    //Cancel button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          Navigator.pop(context);
                        });
                      },
                      child: Container(
                          //color: Colors.red,
                          padding: EdgeInsets.only(
                            top: appDimens.verticalMarginPadding(value: 20),
                            bottom: appDimens.verticalMarginPadding(value: 15),
                          ),
                          child: Center(
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                  fontSize: appDimens.fontSize(value: 20),
                                  fontFamily: appFonts
                                      .defaultFont,
                                  color: appColors
                                      .textNormalColor),
                            ),
                          )),
                    )
                  ]),
            )
          ],
        ),
      ),
    );
  }

  //Filter pop up view
  leftGroupView(String groupId) {
    if (groupId == null) {
      return Container();
    }
    return !isLoading
        ? customView.confirmationBottomSheet(
            context: context,
            screenWidth: appDimens.widthFullScreen(),
            view: deleteView(),
            sheetDismissCallback: () {
              Navigator.pop(context);
            })
        : Container();
  }

  //Join group
  joinGroupDetails(groupId) async {
    String uName =
        await sharedPreferencesFile.readStr('nickName');
    String imageUser =
        await sharedPreferencesFile.readStr('imageUrl');
    String fcmToken =
        await sharedPreferencesFile.readStr('fcmToken');

    User mUser = new User(
        firstName: uName,
        imageUrl: imageUser,
        documentID: uId,
        fcmToken: fcmToken);
    FireBaseStore _firebaseStore = new FireBaseStore();
    await _firebaseStore.joinChatGroupFireBase(groupId: groupId,user: mUser);
    setState(() {
      isJoinedGroup = !isJoinedGroup;
      Fluttertoast.showToast(
          msg: appString.joinGroup);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => GroupChatScreen(
                  groupInfo: groupInfo,
                  peerId: groupInfo['gId'],
                  name: groupInfo['name'],
                  peerAvatar: groupInfo['imageUrl'],
                  isGroupChat: true,
                  isGroupCreated: isGroupCreated)));
    });
  }

  //Join group
  leftGroupDetails(String groupId) async {
    if (uId != null) {
      setState(() {
        isLoading = true;
      });
      String uName = await sharedPreferencesFile
          .readStr('nickName');
      String imageUser = await sharedPreferencesFile
          .readStr('imageUrl');
      String fcmToken = await sharedPreferencesFile
          .readStr('fcmToken');

      User mUser = new User(
          firstName: uName,
          imageUrl: imageUser,
          documentID: uId,
          fcmToken: fcmToken);
      FireBaseStore _firebaseStore = new FireBaseStore();
      await _firebaseStore.leftChatGroupFireBase(groupId: groupId, user: mUser);
      setState(() {
        isJoinedGroup = !isJoinedGroup;
        isLoading = false;
        Fluttertoast.showToast(
            msg: appString.leftGroup);
      });
    }
  }
}
