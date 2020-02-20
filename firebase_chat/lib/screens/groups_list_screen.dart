import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_chat/chat_p/custom_widget/bottom_sheet_card_view.dart';
import 'package:firebase_chat/chat_p/custom_widget/pop_up_menu.dart';
import 'package:firebase_chat/chat_p/custom_widget/poup_menu_widgets.dart';
import 'package:firebase_chat/chat_p/local_constant.dart';
import 'package:firebase_chat/chat_p/shared_preferences_file.dart';
import 'package:firebase_chat/chat_p/utils_p/app_color.dart';
import 'package:firebase_chat/chat_p/utils_p/app_dimens.dart';
import 'package:firebase_chat/chat_p/utils_p/app_fonts.dart';
import 'package:firebase_chat/chat_p/utils_p/app_string.dart';
import 'package:firebase_chat/chat_p/utils_p/back_arrow_with_title_and_sub_title_app_bar.dart';
import 'package:firebase_chat/chat_p/utils_p/custome_view.dart';
import 'package:firebase_chat/chat_p/utils_p/take_photo_with_crop.dart';
import 'package:firebase_chat/chat_p/utils_p/validation.dart';
import 'package:firebase_chat/firebse_chat_main.dart';
import 'package:firebase_chat/screens/group_channel_information.dart';
import 'package:firebase_chat/screens/group_chat_screen.dart';
import 'package:firebase_chat/screens/inbox_p/models/group.dart';
import 'package:firebase_chat/screens/inbox_p/models/user.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GroupsListScreen extends StatefulWidget {
  final String selectedUChatId;
  final bool isAllGroups;

  GroupsListScreen({Key key, this.isAllGroups, @required this.selectedUChatId})
      : super(key: key);

  @override
  _GroupsListScreen createState() => _GroupsListScreen(
      isAllGroups: isAllGroups, selectedUChatId: selectedUChatId);
}

class _GroupsListScreen extends State<GroupsListScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  String uId;
  AnimationController controller;
  Animation<Offset> offset;
  FireBaseStore _firebaseStore = new FireBaseStore();

  int showHideEditProfileSheet = 0;
  bool isAllGroups = false;
  bool isSelfGroupsChannel = false;
  final String selectedUChatId;
  String currentLoggedInChatUid;

  int isCameraPopUpOpen = 0;
  double groupImageHeight = 100;
  double groupImageWidth = 100;
  int groupType = 0;  //0 = public , 1 = privet

  _GroupsListScreen(
      {Key key, this.isAllGroups, @required this.selectedUChatId}) {
    try {
      sharedPreferencesFile
          .readStr(chatUid)
          .then((value) {
        if (value != null) {
          setState(() {
            currentLoggedInChatUid = value;
            isSelfGroupsChannel =
                currentLoggedInChatUid == selectedUChatId ? true : false;
          });
        }
      });
    } catch (e) {
      print(e);
    }
    _firebaseStore = new FireBaseStore();
    if (this.selectedUChatId != null) {
      uId = this.selectedUChatId;
    } else {
      sharedPreferencesFile
          .readStr("chatUid")
          .then((value) {
        if (value != null && value != '') {
          setState(() {
            uId = value;
          });
        }
      });
    }
    fcmDataretrayCount = 3;
  }

  var screenSize, screenHeight, screenWidth;
  bool isBackButtonActivated = false;
  bool isLoading = false;
  bool isSubLoading = false;
  bool isReadyToClick = false;
  bool isEditGroupDetails = false;
  String selectedGid = "";
  bool isBottomSheetClicked = false;
  String createLble = "Create Group";
  File croppedFile;
  File imageFile;
  String imagePath;
  String selectedGroupImageUrl;
  double rowCardRadius = 10.5;

  bool isRefreshScreenData = false;

  final FirebaseMessaging firebaseMessaging = new FirebaseMessaging();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      new FlutterLocalNotificationsPlugin();
  final GoogleSignIn googleSignIn = GoogleSignIn();

  Map<String, TextEditingController> controllers = {
    'name': new TextEditingController(),
    'subHeader': new TextEditingController(),
    'description': new TextEditingController(),
  };

  Map<String, FocusNode> focusNodes = {
    'name': new FocusNode(),
    'subHeader': new FocusNode(),
    'description': new FocusNode(),
  };

  Map<String, String> errorMessages = {
    'name': null,
    'subHeader': null,
    'description': null,
  };

  int fcmDataretrayCount = 3;

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
                        appString.confirmationDeleteGroupMessage,
                        style: TextStyle(
                            fontSize: appDimens.fontSize(value: 16),
                            fontFamily:
                                appFonts.defaultFont,
                            color: appColors
                                .textNormalColor),
                      ),
                    ),

                    //Save button
                    Container(
                        height: appDimens.buttonHeight(value: 50),
                        margin: EdgeInsets.only(),
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
                                        await _firebaseStore.deleteChatGroupFireBase(groupId:
                                            _selectedChoice.mChatGroups.gId);
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
                                  fontFamily: appFonts.defaultFont,
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
  Widget leftGroupView(String groupId) {
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
                            fontFamily:
                                appFonts.defaultFont,
                            color: appColors
                                .textNormalColor),
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
                                  fontFamily:appFonts.defaultFont,
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

  //BottomSheet for contact us
  _groupDeleteBottomSheet() {
    return customView.confirmationBottomSheet(
        context: context,
        screenWidth: appDimens.widthFullScreen(),
        view: deleteView(),
        sheetDismissCallback: () {
          Navigator.pop(context);
        });
  }

  //BottomSheet for contact us
  _groupLeftBottomSheet(groupId) {
    return customView.confirmationBottomSheet(
        context: context,
        screenWidth: appDimens.widthFullScreen(),
        view: leftGroupView(groupId),
        sheetDismissCallback: () {
          Navigator.pop(context);
        });
  }

  ChoiceTemp _selectedChoice = choices[0];

  // The app's "state".
  void _select(ChoiceTemp choice) {
    // Causes the app to rebuild with the new _selectedChoice.
    setState(() async {
      _selectedChoice = choice;
      if (_selectedChoice.title == "Edit") {
        isReadyToClick = true;
        _createNewGroupChannelBottomSheet(_selectedChoice.mChatGroups, true);
        setState(() {
          showHideEditProfileSheet = 1;
        });
      }
      if (_selectedChoice.title == "Delete") {
        _groupDeleteBottomSheet();
      }
      print("Selected menu $_selectedChoice");
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 400));
    offset = Tween<Offset>(begin: Offset(0.0, 1.0), end: Offset.zero)
        .animate(controller);
  }

  @override
  void dispose() {
    focusNodes['name'].unfocus();
    focusNodes['subHeader'].unfocus();
    focusNodes['description'].unfocus();
    // Clean up the controller when the widget is disposed.
    WidgetsBinding.instance.removeObserver(this);
    focusNodes['name'].dispose();
    focusNodes['subHeader'].dispose();
    focusNodes['description'].dispose();
    super.dispose();
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

  void showNotification(message) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      Platform.isAndroid
          ? 'com.dexbytes.firebase_chat_module'
          : 'com.dexbytes.firebase_chat_module',
      'Flutter chat demo',
      'your channel description',
      playSound: true,
      enableVibration: true,
      importance: Importance.Max,
      priority: Priority.High,
    );
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, message['title'].toString(),
        message['body'].toString(), platformChannelSpecifics,
        payload: json.encode(message));
  }

  //Back press
  Future<bool> onBackPress() {
    if (isCameraPopUpOpen == 1 || showHideEditProfileSheet > 0) {
      setState(() {
        isCameraPopUpOpen = 0;
        showHideEditProfileSheet = 0;
      });
      return Future.value(false);
    } else {
      isRefreshScreenData = true;
      Navigator.pop(context, isRefreshScreenData);
      return Future.value(false);
    }
  }

  var appBarHeight, statusBarHeight;

  @override
  Widget build(BuildContext context) {
    rowCardRadius = 8.5;
    statusBarHeight = MediaQuery.of(context).padding.top;
    appBarHeight = 82 - statusBarHeight; //Card radius

    /*==================== Create Group Channel  Button View =============================*/
    Widget createGroupChannelBtn = Container(
        height: appDimens.buttonHeight(value: 55),
        margin: EdgeInsets.only(top: 0),
        child: Align(
          alignment: Alignment.center,
          child: customView.buttonRoundCornerWithBg(
              "Create Group",
              appColors.buttonTextColor,
              appColors.buttonBgColor[100],
              appDimens.fontSizeButton(value: 18),
              2, (value) {
            setState(() {
              imageFile = null;
              imagePath = null;
              isLoading = false;
              isSubLoading = false;
              showHideEditProfileSheet = 1;
            });
            _createNewGroupChannelBottomSheet(null, false);
          }),
        ));

    /*==================== Bottom View =============================*/
    Widget bottomView = Container(
      color: appColors.appBgColor[400],
      padding: EdgeInsets.only(
          left: appDimens.horizontalMarginPadding(value: 35),
          right: appDimens.horizontalMarginPadding(value: 35)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
              padding: EdgeInsets.only(
                  top: appDimens.horizontalMarginPadding(value: 0),
                  bottom: appDimens.verticalMarginPadding(value: 20)),
              child: createGroupChannelBtn),
        ],
      ),
    );

    //Create Group Channel PopupUi
    Widget createGroupChannelPopupUi() {
      return Container(
        margin: EdgeInsets.only(
            bottom: appDimens.verticalMarginPadding(value: 5),
            left: appDimens.verticalMarginPadding(value: 25),
            right: appDimens.verticalMarginPadding(value: 25)),
        child: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(
                    top: appDimens.verticalMarginPadding(value: 20),
                  ),
                  child: Text(
                    "Group Name",
                    style: TextStyle(
                        fontFamily:
                            appFonts.defaultFont,
                        fontSize: appDimens.fontSize(value: 16),
                        color: appColors
                            .textNormalColor[400]),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                      top: appDimens.verticalMarginPadding(value: 13)),
                  child: customView.inputFields(
                        keyboardType: nameInputC,
                        inputAction: nextC,
                        maxLength: nameInputMaxLenthC,
                        readOnly: false,
                        padding: EdgeInsets.all(appDimens.horizontalMarginPadding(value: 16)),
                        focusNode: null,
                        controller: controllers['name'],
                        hint: "Name",
                        fontSize: appDimens.fontSize(value: 18),
                        error: errorMessages['name'],
                        borderColor: appColors
                            .editTextBorderColor[100],
                        enabledBorder: appColors
                            .editTextEnabledBorderColor[100],
                        fillColor: appColors
                            .editTextBgColor[100],
                        focusedBorderColor: appColors
                            .editTextFocusedBorderColor[100],
                        cursorColor: appColors
                            .editCursorColor[200],
                        hintTextColor: appColors
                            .editTextHintColor[100],
                        ontextChanged: (value) {
                          isReadyToClick = false;
                          if (validation.isNotEmpty(value)) {
                            print(value);
                            setState(() {
                              errorMessages['name'] = null;
                              isReadyToClick = true;
                            });
                          } else {
                            setState(() {
                              errorMessages['name'] = appString.groupNameNotBlank;
                              isReadyToClick = false;
                            });
                          }
                        },
                        onSubmit: (value) {
                          FocusScope.of(context)
                              .requestFocus(focusNodes['subHeader']);
                          setState(() {
                            controllers['name'].text = value;
                          });
                        },
                      ),
                ),

                 /* Padding(
                  padding: EdgeInsets.only(
                      top: appDimens.verticalMarginPadding(value: 20)),
                  child: Text(
                    "Group Chat Sub-Header",
                    style: TextStyle(
                        fontFamily:
                            appFonts.defaultFont,
                        fontSize: appDimens.fontSize(value: 16),
                        //fontWeight: FontWeight.w600,
                        color: appColors
                            .textNormalColor[400]),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                      top: appDimens.verticalMarginPadding(value: 13)),
                  child: customView.inputFields(
                        keyboardType: textInputC,
                        inputAction: nextC,
                        maxLength: nameInputMaxLenthC,
                        readOnly: false,
                        padding: EdgeInsets.all(appDimens.horizontalMarginPadding(value: 16)),
                        focusNode: focusNodes['subHeader'],
                        controller: controllers['subHeader'],
                        hint: "Sub-Header",
                        fontSize: appDimens.fontSize(value: 18),
                        error: errorMessages['subHeader'],
                        borderColor: appColors
                            .editTextBorderColor[100],
                        enabledBorder: appColors
                            .editTextEnabledBorderColor[100],
                        fillColor: appColors
                            .editTextBgColor[100],
                        focusedBorderColor: appColors
                            .editTextFocusedBorderColor[100],
                        cursorColor: appColors
                            .editCursorColor[200],
                        hintTextColor: appColors
                            .editTextHintColor[100],
                        ontextChanged: (value) => {},
                        onSubmit: (value) {
                          {
                            FocusScope.of(context)
                                .requestFocus(focusNodes['description']);
                          }
                          setState(() {
                            controllers['subHeader'].text = value;
                          });
                        },
                      ),
                ),
*/
                /*Padding(
                  padding: EdgeInsets.only(
                      top: appDimens.verticalMarginPadding(value: 20)),
                  child: Text(
                    "Description",
                    style: TextStyle(
                        fontFamily:
                            appFonts.defaultFont,
                        fontSize: appDimens.fontSize(value: 16),
                        //fontWeight: FontWeight.w600,
                        color: appColors
                            .textNormalColor[400]),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                      top: appDimens.verticalMarginPadding(value: 13)),
                  child: customView.inputFields(
                        keyboardType: textInputC,
                        inputAction: doneC,
                        maxLength: descriptionInputMaxLenthC,
                        readOnly: false,
                        focusNode: focusNodes['description'],
                        controller: controllers['description'],
                        hint: "Type group description",
                        fontSize: appDimens.fontSize(value: 14),
                        maxLines: 3,
                        padding: EdgeInsets.all(appDimens.horizontalMarginPadding(value: 18)),
                        error: errorMessages['description'],
                        borderColor: appColors
                            .editTextBorderColor[100],
                        enabledBorder: appColors
                            .editTextEnabledBorderColor[100],
                        fillColor: appColors
                            .editTextBgColor[100],
                        focusedBorderColor: appColors
                            .editTextFocusedBorderColor[100],
                        cursorColor: appColors
                            .editCursorColor[200],
                        hintTextColor: appColors
                            .editTextHintColor[100],
                        ontextChanged: (value) {},
                        onSubmit: (value) {
                          setState(() {
                            controllers['description'].text = value;
                          });
                        },
                      ),
                ),*/

                Container(
                    height: appDimens.buttonHeight(
                        value: (imagePath != null && imagePath.trim() != "")
                            ? 125
                            : 50),
                    width: (imagePath != null && imagePath.trim() != "")
                        ? appDimens.widthDynamic(value: groupImageWidth)
                        : appDimens.widthFullScreen(),
                    margin: EdgeInsets.only(
                        top: appDimens.verticalMarginPadding(
                                value: (imagePath != null &&
                                        imagePath.trim() != "")
                                    ? 0
                                    : 20)),
                    child: Align(
                        alignment: Alignment.center,
                        child: Stack(
                          children: <Widget>[
                            (imagePath != null && imagePath.trim() != "")
                                ? Container(
                                    child: selectedGroupImageView(imagePath),
                                  )
                                : Container(
                                    child: customView.buttonRoundCornerWithBgAndLeftImage(
                                            "Choose a group Picture",
                                            'packages/firebase_chat/assets/camera.png',
                                            appDimens.imageSquareAccordingScreen(
                                                    value: 22),
                                            appDimens.imageSquareAccordingScreen(
                                                    value: 22),
                                            appColors
                                                .textNormalColor[600],
                                            //(isEmailOk && agree)?
                                            appColors
                                                .buttonBgColor[300],
                                            appDimens.fontSize(value: 18),
                                            2, (value) async {
                                      if (!isSubLoading) {
                                        setState(() {
                                          isCameraPopUpOpen = 1;
                                        });
                                        TakePhotoWithCrop(context: context)
                                            .takeMediaBottomSheet(
                                                ratio: 1,
                                                hardBackPress: () {
                                                  setState(() {
                                                    isCameraPopUpOpen = 0;
                                                  });
                                                  Navigator.pop(context, true);
                                                },
                                                backPress: () {
                                                  setState(() {
                                                    isCameraPopUpOpen = 0;
                                                  });
                                                  Navigator.pop(context, true);
                                                },
                                                callBack: (imageFileTemp,
                                                    imagePathTemp) {
                                                  setState(() {
                                                    isCameraPopUpOpen = 0;
                                                  });
                                                  //print('file into string=====================  ${imageFileTemp.path} ##### $imagePathTemp');
                                                  if (imageFileTemp != null &&
                                                      imagePathTemp != null) {
                                                    setState(() {
                                                      imageFile = imageFileTemp;
                                                      imagePath = imagePathTemp;
                                                    });
                                                  }
                                                });
                                      }
                                    }),
                                    height: appDimens.buttonHeight(),
                                  )
                          ],
                        ))),
                Container(
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
                                        createLble,
                                        isReadyToClick
                                            ? appColors
                                                .buttonTextColor
                                            : appColors
                                                .buttonTextColor[100],
                                        //(isEmailOk && agree)?
                                        isReadyToClick
                                            ? appColors
                                                .buttonBgColor[100]
                                            : appColors
                                                .appDisabledColor[100]
                                        //:appColors.appDisabledColor[100]
                                        ,
                                        appDimens.fontSize(value: 18),
                                        2, (value) async {
                                    if (isReadyToClick) {
                                      customView.hideKeyboard(context);
                                      submitGroupDetails();
                                    }
                                  })
                          ],
                        ))),

                //Cancel button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showHideEditProfileSheet = 0;
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
                          appString.buttonCancel,
                          style: TextStyle(
                              fontSize: appDimens.fontSize(value: 20),
                              fontFamily:appFonts.defaultFont,
                              color: appColors
                                  .textNormalColor[400]),
                        ),
                      )),
                ),
              ],
            ),
          ],
        ),
      );
    }

    statusBarHeight = MediaQuery.of(context).padding.top;
    //App bar
    Widget appBar = Container(
      // color:   Colors.red,
      height: appDimens.heightDynamic(
        value: 77 - statusBarHeight,
      ),
      child:appBarBackArrowWithTitleAndSubTitle.appBarWithLeftRightIconTitleSubtitle(
      statusbarHeight:MediaQuery.of(context).padding.top,
      title: "Group",
      back: true,
      appBarBgColor: appColors.appBarBgColor,
      titleColor: appColors.appBarTextColor[600],
      titleFontSize: appDimens.fontSize(value: 20),
      leftIconSize: appDimens.widthDynamic(value: 20),
      onPressed: (){
        Navigator.pop(context);
      },
    ));

    /*==================== Main view =========================*/
    return WillPopScope(
      child: Scaffold(
        body: Listener(
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                Container(
                  child: Stack(
                    children: <Widget>[
                      // List
                      Container(
                        margin: EdgeInsets.only(
                            top: appDimens.heightDynamic(
                                  value: 90 - statusBarHeight,
                                ),
                            bottom: isAllGroups
                                ? appDimens.verticalMarginPadding(value: 45)
                                : (isSelfGroupsChannel
                                    ? appDimens.verticalMarginPadding(value: 45)
                                    : appDimens.verticalMarginPadding(value: 5))),
                        padding: EdgeInsets.only(
                            bottom: isAllGroups
                                ? appDimens.verticalMarginPadding(value: 35)
                                : (isSelfGroupsChannel
                                    ? appDimens.verticalMarginPadding(value: 35)
                                    : appDimens.verticalMarginPadding(value: 5))),
                        child:
                        Container(
                          /*color: Colors.green,*/
                          child: StreamBuilder(
                            stream: _firebaseStore.getGroupsFireBase(uId: uId, isAll: isAllGroups)
                                .asStream(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                fcmDataretrayCount > 0 ?? fcmDataretrayCount--;
                                return fcmDataretrayCount <= 0
                                    ? Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  appColors
                                                      .loaderColor[300]),
                                        ),
                                      )
                                    : Center(child: Text("No Groups Found!"));
                              } else {
                                //setState(() {
                                fcmDataretrayCount = 3;
                                //});
                                return snapshot.data.length > 0
                                    ? ListView.builder(
                                        padding: EdgeInsets.all(
                                            appDimens.horizontalMarginPadding(
                                                    value: 20)),
                                        itemBuilder: (context, index) =>
                                            buildItem(
                                                context, snapshot.data[index]),
                                        itemCount: snapshot.data.length,
                                      )
                                    : Center(child: Text("Empty Group List!"));
                              }
                            },
                          ),
                        ),
                      ),
                      isAllGroups
                          ? Positioned(
                              child: Align(
                              child: bottomView,
                              alignment: Alignment.bottomCenter,
                            ))
                          : (isSelfGroupsChannel
                              ? Positioned(
                                  child: Align(
                                  child: bottomView,
                                  alignment: Alignment.bottomCenter,
                                ))
                              : Container()),
                    ],
                  ),
                  color: appColors.appBgColor[400],
                ),
                appBar,
                _groupChatViewBottomSheet(createGroupChannelPopupUi()),
                // Loading
                Positioned(
                  child: isLoading
                      ? CircularProgressIndicator(
                    valueColor: new AlwaysStoppedAnimation<Color>(
                        appColors.loaderColor[300]),
                  )
                      : Container(),
                )
              ],
            ),
          ),
        ),
      ),
      onWillPop: onBackPress,
    );
  }

  Widget menuOverFlow = Container(width: 50,child: Align(
    alignment: Alignment.centerRight,
    child: PoupMenuWidgets(
      itemList: <Choice>[
        Choice(title: 'Groups', icon: Icons.edit,id: 0),
        Choice(title: 'Log Out', icon: Icons.delete,id: 1),
      ],
      selectedCallBack: (value) {
        if (value != null) {
          //Groups List
          if (value == 0) {
           /* Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        GroupsListScreen(
                          isAllGroups: true,
                          selectedUChatId: selfUserChatId,
                        )));*/
          }
          //New group Creation
          else if (value == 1)
         {
         /*   Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        GroupsListScreen(
                          isAllGroups: true,
                          selectedUChatId: selfUserChatId,
                        )));*/
          }
        }
      },
    ),),);


  //Pop up menu
  Widget popupMenuButton(ChatGroups mChatGroups) {
    return PopupMenuButtons<ChoiceTemp>(
      //icon: Icon(Icons.settings),
      child: Container(
          margin: EdgeInsets.only(
              left: appDimens.horizontalMarginPadding(value: 5),
              right: appDimens.horizontalMarginPadding(value: 14)),
          child: Align(
            child: Image(
              image:
              AssetImage("packages/firebase_chat/assets/images/dot@3x.png"),
              color: appColors.appBarLetIconColor[200],
              width: appDimens.imageSquareAccordingScreen(value: 21),
              height: appDimens.imageSquareAccordingScreen(value: 21),
            ),
            alignment: Alignment.topCenter,
          )),
      onSelected: _select,
      itemBuilder: (BuildContext context) {
        return choices.skip(0).map((ChoiceTemp choice) {
          choice.mChatGroups = mChatGroups;
          return PopupMenuItems<ChoiceTemp>(
            value: choice,
            child: Text(choice.title),
          );
        }).toList();
      },
    );
  }

  //User image view
//User image view
  Widget userImageView(DocumentSnapshot document) {
    List<dynamic> userListStr = document['usersDetails'];
    int count = userListStr.length;
// bool isGroupCreated = document['createBy'] == uId ? true : false;
/*1. Check is user see it self group.
If user see other's group channel so he joined group or not*/
    double imageSize = appDimens.imageSquareAccordingScreen(value: 33);
    double outerCircleSize = appDimens.imageSquareAccordingScreen(value: 36);
    double imageRadius = appDimens.imageSquareAccordingScreen(value: 33) /
        2;
//print('User List: $userListStr.');
    return count > 0
        ? Padding(
            padding: EdgeInsets.only(
                top: appDimens.verticalMarginPadding(value: 0),
                right: appDimens.horizontalMarginPadding(value: 0)),
            child: Stack(
              children: <Widget>[
                (count > 0)
                    ? Container(
                        alignment: Alignment.center,
                        child: Container(
                            height: outerCircleSize,
                            width: outerCircleSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: appColors.white,
                            ),
                            child: FutureBuilder(
                              future: Firestore.instance
                                  .collection('users')
                                  .where('id', isEqualTo: userListStr[0]["id"])
                                  .getDocuments(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<dynamic> snapshot) {
                                if (snapshot.hasData) {
                                  var value = snapshot.data;
                                  final List<DocumentSnapshot> documents =
                                      value.documents;
                                  if (documents.length != 0) {
                                    print(" UsrData $documents");
                                    var dta = documents[0].data['imageUrl'];
                                    var name = documents[0].data['nickName'];
                                    return customView.circularImageOrNameView(
                                            imageSize, imageSize, dta, name);
                                  }
                                  return Container();
                                }
                                return Container(); // noop, this builder is called again when the future completes
                              },
                            ),
                            margin: EdgeInsets.only(left: imageRadius * 3.25)))
                    : Container(),
                (count > 1)
                    ? Container(
                        alignment: Alignment.center,
                        child: Container(
                          height: outerCircleSize,
                          width: outerCircleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: appColors.white,
                          ),
                          child: FutureBuilder(
                            future: Firestore.instance
                                .collection('users')
                                .where('id', isEqualTo: userListStr[1]["id"])
                                .getDocuments(),
                            builder: (BuildContext context,
                                AsyncSnapshot<dynamic> snapshot) {
                              if (snapshot.hasData) {
                                var value = snapshot.data;
                                final List<DocumentSnapshot> documents =
                                    value.documents;
                                if (documents.length != 0) {
                                  print(" UsrData $documents");
                                  var dta = documents[0].data['imageUrl'];
                                  var name = documents[0].data['nickName'];
                                  return customView.circularImageOrNameView(
                                          imageSize, imageSize, dta, name);
                                }
                                return Container();
                              }
                              return Container(); // noop, this builder is called again when the future completes
                            },
                          ),
                        ),
                        margin: EdgeInsets.only(left: imageRadius * 2.25))
                    : Container(),
                (count > 2)
                    ? Container(
                        alignment: Alignment.center,
                        child: Container(
                            height: outerCircleSize,
                            width: outerCircleSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: appColors.white,
                            ),
                            child: FutureBuilder(
                              future: Firestore.instance
                                  .collection('users')
                                  .where('id', isEqualTo: userListStr[2]["id"])
                                  .getDocuments(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<dynamic> snapshot) {
                                if (snapshot.hasData) {
                                  var value = snapshot.data;
                                  final List<DocumentSnapshot> documents =
                                      value.documents;
                                  if (documents.length != 0) {
                                    print(" UsrData $documents");
                                    var dta = documents[0].data['imageUrl'];
                                    var name = documents[0].data['nickName'];
                                    return customView.circularImageOrNameView(
                                            imageSize, imageSize, dta, name);
                                  }
                                  return Container();
                                }
                                return Container(); // noop, this builder is called again when the future completes
                              },
                            ),
                            margin: EdgeInsets.only(left: imageRadius * 1.25)))
                    : Container(),
                (count > 3)
                    ? Container(
                        alignment: Alignment.center,
                        child: Container(
                            height: outerCircleSize + 2,
                            width: outerCircleSize + 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: appColors.white,
                            ),
                            child: customView.circleTextView(
                                    imageSize + 2,
                                    imageSize + 2,
                                    appDimens.fontSize(value: 12),
                                    count,
                                    appColors
                                        .textNormalColor[600],
                                    appColors
                                        .circleColor[200]),
                            margin: EdgeInsets.only(left: imageRadius * 0)))
                    : Container(),
              ],
            ),
          )
        : Container();
  }

  //Group list row background image
  Widget rowBackgroundImage(String imagePathTemp) {
    return Container(
      child: Material(
        child: imagePathTemp != null
            ? Container(
                color: appColors.white,
              )
            : Container(
                color: appColors.white,
              ),
        borderRadius: BorderRadius.all(Radius.circular(rowCardRadius)),
        clipBehavior: Clip.hardEdge,
      ),
    );
  }

  //Selected group image
  Widget selectedGroupImageView(String imagePathTemp) {
    return Container(
      height: (appDimens.imageSquareAccordingScreen(value: groupImageHeight)),
      width: (appDimens.imageSquareAccordingScreen(value: (groupImageWidth + 10))),
      child: Stack(
        children: <Widget>[
          imagePathTemp != null
              ? Container(
                  padding: EdgeInsets.only(top: 15, bottom: 0, right: 10),
                  child: customView.rectImageView(
                      appDimens.imageSquareAccordingScreen(value: groupImageHeight),
                      appDimens.imageSquareAccordingScreen(value: groupImageWidth),
                      imagePathTemp))
              : Container(
                  color: appColors.white,
                ),
          Align(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  imagePath = null;
                  imageFile = null;
                });
              },
              child: Container(
                color: appColors.appTransColor[700],
                height: 35,
                width: 35,
                padding: EdgeInsets.fromLTRB(7, 7, 0, 7),
                child: Icon(Icons.close,size: /*leftIconSize ??*/
                appDimens.imageSquareAccordingScreen(value: 35),color: /*appBarBackIconColor ??*/
                appColors.iconColor[500],),
              ),
            ),
            alignment: Alignment.topRight,
          )
        ],
      ),
    );
  }

  // Check validation
  bool _isAllFieldValid() {
    if (controllers['name'].text == null ||
        controllers['name'].text == '' ||
        controllers['name'].text == "#error") {
      setState(() {
        if (controllers['name'].text != "#error") {
          errorMessages['name'] =
              appString.nameNotBlank;
          isReadyToClick = false;
        }
      });
      return false;
    } else {
      setState(() {
        isReadyToClick = true;
      });
      return true;
    }
  }

  //Group List Row
  Widget buildItem(BuildContext context, DocumentSnapshot document) {
    final userListStr = document['usersDetails'].toString();
    final groupId = document['gId'];
    final groupDetails = document;

    /*1. Check is user see it self group.
    If user see other's group channel so he joined group or not*/
    bool isJoinedGroup = userListStr.contains((!isAllGroups
            ? (!isSelfGroupsChannel ? currentLoggedInChatUid : uId)
            : (currentLoggedInChatUid)))
        ? true
        : false;
    bool isGroupCreated = !isAllGroups
        ? (isSelfGroupsChannel
            ? (document['createBy'] == uId ? true : false)
            : false)
        : (document['createBy'] == currentLoggedInChatUid ? true : false);

    bool isGroupDeleted = document['isDeletes'] ? true : false;
    print("List " + userListStr);
    ChatGroups mChatGroups;

    try {
      mChatGroups = new ChatGroups(
          name: document['name'],
          subHeading: document['subHeading'],
          description: document['description'],
          gId: groupId != null ? groupId : document['gId'],
          image: document['image']);
    } catch (e) {
      print(e);
    }
    return isGroupDeleted
        ? Container()
        : Padding(
            padding: EdgeInsets.only(
                bottom: appDimens.verticalMarginPadding(value: 20)),
            child: Container(
              height: (appDimens.heightDynamic(value: 70)),
              child: GestureDetector(
                onTap: () {
                  if (isJoinedGroup || isGroupCreated) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GroupChatScreen(
                                    groupInfo: document,
                                    peerId: document.documentID,
                                    name: document['name'],
                                    peerAvatar: document['image'],
                                    isGroupChat: true,
                                    isGroupCreated: isGroupCreated)));
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GroupChannelInformation(
                                groupInfo: document,
                                isJoinedGroup: false,
                                isGroupCreated: isGroupCreated)));

                  }
                },
                child: Material(
                  child: Stack(
                    children: <Widget>[
                      rowBackgroundImage(document['image']),
                      Container(
                          height: appDimens.heightDynamic(value: 70),
                          child: Row(
                            children: <Widget>[
                              /*Text View*/
                              Flexible(
                                child: Container(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Container(
                                        child: Text(
                                          '${document['name']}',
                                          style: TextStyle(
                                              fontFamily:appFonts.defaultFont,
                                              fontSize: appDimens.fontSize(value: 18),
                                              fontWeight: FontWeight.w500,
                                              color: appColors
                                                  .textHeadingColor),
                                          maxLines: 1,
                                        ),
                                        alignment: Alignment.centerLeft,
                                      ),
                                      Container(
                                        child: Text(
                                            '${document['subHeading'] ?? 'NA'}',
                                            style: TextStyle(
                                                fontFamily:appFonts.defaultFont,
                                                fontSize: appDimens.fontSize(value: 14),
                                                fontWeight: FontWeight.w400,
                                                color: appColors
                                                    .textNormalColor[400]),
                                            maxLines: 1),
                                        alignment: Alignment.centerLeft,
                                      )
                                    ],
                                  ),
                                  margin: EdgeInsets.only(
                                      left: appDimens.horizontalMarginPadding(value: 15)),
                                ),
                              ),
                              userImageView(document),
                              Container(
                                alignment: Alignment.center,
                                child: //Overflow view
                                    //Check if group created by loggedin user and see it'sself  group channels
                                    !isAllGroups
                                        ? ((isGroupCreated &&
                                                isSelfGroupsChannel)
                                            ?
                                            // overflow menu
                                            popupMenuButton(mChatGroups)
                                            :
                                            //Right button view
                                            Container(
                                                margin: EdgeInsets.only(
                                                    left: appDimens.horizontalMarginPadding(
                                                            value: 5),
                                                    right: appDimens.horizontalMarginPadding(
                                                            value: 14)),
                                                child: isJoinedGroup
                                                    ? GestureDetector(
                                                        child: Image(
                                                          image:
                                                          AssetImage("packages/firebase_chat/assets/images/check_pink@3x.png"),
                                                          color: appColors.appBarLetIconColor[200],
                                                          width: appDimens.imageSquareAccordingScreen(value: 30),
                                                          height: appDimens.imageSquareAccordingScreen(value: 30),
                                                        ),
                                                        onTap: () =>
                                                            _groupLeftBottomSheet(
                                                                groupId),
                                                      )
                                                    : GestureDetector(
                                                        child: Image(
                                                          image:
                                                          AssetImage("packages/firebase_chat/assets/images/add_border@3x.png"),
                                                          //color: appColors.appBarLetIconColor[200],
                                                          width: appDimens.imageSquareAccordingScreen(value: 30),
                                                          height: appDimens.imageSquareAccordingScreen(value: 30),
                                                        ),
                                                        onTap: () =>
                                                            joinGroupDetails(
                                                                groupDetails),
                                                      )))
                                        : ((isGroupCreated)
                                            ?
                                            // overflow menu
                                            popupMenuButton(mChatGroups)
                                            :
                                            //Right button view
                                            Container(
                                                margin: EdgeInsets.only(
                                                    left: appDimens.horizontalMarginPadding(
                                                            value: 5),
                                                    right: appDimens.horizontalMarginPadding(
                                                            value: 14)),
                                                child: isJoinedGroup
                                                    ? GestureDetector(
                                                        child: Image(
                                                          image:
                                                          AssetImage("packages/firebase_chat/assets/images/check_pink@3x.png"),
                                                          //color: appColors.appBarLetIconColor[200],
                                                          width: appDimens.imageSquareAccordingScreen(value: 30),
                                                          height: appDimens.imageSquareAccordingScreen(value: 30),
                                                        ),
                                                        onTap: () =>
                                                            _groupLeftBottomSheet(
                                                                groupId),
                                                      )
                                                    : GestureDetector(
                                                        child: Image(
                                                          image:
                                                          AssetImage("packages/firebase_chat/assets/images/add_border@3x.png"),
                                                          //color: appColors.appBarLetIconColor[200],
                                                          width: appDimens.imageSquareAccordingScreen(value: 30),
                                                          height: appDimens.imageSquareAccordingScreen(value: 30),
                                                        ),
                                                        onTap: () =>
                                                            joinGroupDetails(
                                                                groupDetails),
                                                      ))),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.fromLTRB(5.0, 10.0, 0.0, 10.0))
                    ],
                  ),
                  borderRadius:
                      BorderRadius.all(Radius.circular(rowCardRadius)),
                  clipBehavior: Clip.hardEdge,
                ),
              ),
              margin: EdgeInsets.only(
                  bottom: appDimens.verticalMarginPadding(value: 2.5),
                  left: appDimens.horizontalMarginPadding(value: 0),
                  right: appDimens.horizontalMarginPadding(value: 0)),
            ),
          );
  }

  //BottomSheet for create group
  void _createNewGroupChannelBottomSheet(
    ChatGroups mChatGroups,
    bool isEditDetails,
  ) {
    setState(() {
      isBottomSheetClicked = true;
      isEditGroupDetails = false;
      selectedGid = null;

      //Reset values
      controllers["name"].text = "";
      controllers["subHeader"].text = "";
      controllers["description"].text = "";
      imageFile = null;
      imagePath = null;

      if (isEditDetails && mChatGroups != null) {
        try {
          createLble = "Update Group";
          isEditGroupDetails = isEditDetails;
          selectedGid = mChatGroups.gId != null ? mChatGroups.gId : "";
          controllers["name"].text =
              mChatGroups.name != null ? mChatGroups.name : "";
          controllers["subHeader"].text =
              mChatGroups.subHeading != null ? mChatGroups.subHeading : "";
          controllers["description"].text =
              mChatGroups.description != null ? mChatGroups.description : "";
          selectedGroupImageUrl =
              mChatGroups.image != null ? mChatGroups.image : "";
          imagePath = mChatGroups.image != null ? mChatGroups.image : "";

          focusNodes['name'].unfocus();
          focusNodes['subHeader'].unfocus();
          focusNodes['description'].unfocus();
        } catch (e) {
          print(e);
        }
      } else {
        createLble = "Create Group";
      }
    });
    //controller.forward();
  }

  //BottomSheet for create group
  _groupChatViewBottomSheet(view) {
    return Container(
        child: BottomSheetCardView(
            showHide: showHideEditProfileSheet,
            cameraOpen: isCameraPopUpOpen,
            cardBodyView: view,
            sheetDismis: () {
              setState(() {
                showHideEditProfileSheet = 0;
                try {
                  customView.hideKeyboard(context);

                  focusNodes['name'].unfocus();
                  focusNodes['subHeader'].unfocus();
                  focusNodes['description'].unfocus();
                } catch (e) {
                  print(e);
                }
              });
            }));
  }

  //Submit group details
  submitGroupDetails() async {
    if (_isAllFieldValid()) {
      setState(() {
        isReadyToClick = false;
        isSubLoading = true;
      });
      if (imageFile != null) {
        selectedGroupImageUrl = await _firebaseStore.uploadFileFireBase(imageFile:imageFile);
      }
      /*String uName = await sharedPreferencesFile.readStr('nickName');
      String imageUser = await sharedPreferencesFile.readStr('imageUrl');
      String fcmToken = await sharedPreferencesFile.readStr('fcmToken');*/
      String uName = "Dinesh";
      String imageUser = "";
      String fcmToken = "";

      User mUser = new User(
          firstName: uName,
          imageUrl: imageUser,
          documentID: uId,
          fcmToken: fcmToken);
      //Updated group details
      if (isEditGroupDetails) {
        //ChatGroups chatGroup, User user
        ChatGroups chatGroup = new ChatGroups(
            name: controllers["name"].text.toString(),
            createBy: uId,
            gId: selectedGid,
            subHeading: controllers["subHeader"].text.toString(),
            description: controllers["description"].text.toString(),
            image: selectedGroupImageUrl);
        await _firebaseStore.updatedChatGroupFireBase(chatGroup: chatGroup,user: mUser);
        selectedGroupImageUrl = null;
      }
      //Create new group
      else {
        //ChatGroups chatGroup, User user
        ChatGroups chatGroup = new ChatGroups(
            name: controllers["name"].text.toString(),
            createBy: uId,
            groupType: groupType,
            subHeading: controllers["subHeader"].text.toString(),
            description: controllers["description"].text.toString(),
            image: selectedGroupImageUrl);
        await _firebaseStore.createChatGroupFireBase(chatGroup:chatGroup, user:mUser);
        selectedGroupImageUrl = null;
      }
      try {
        controller.reverse();
      } catch (e) {
        print(e);
      }
      setState(() {
        showHideEditProfileSheet = 0;
        isBottomSheetClicked = false; // Close Sheet
        isSubLoading = false;
        //Reset values
        controllers["name"].text = "";
        controllers["subHeader"].text = "";
        controllers["description"].text = "";
        imageFile = null;
      });
    }
  }

  //Join group
  joinGroupDetails(groupId) async {
    setState(() {
      isLoading = true;
    });

    String uName =
        await sharedPreferencesFile.readStr('nickName');
    String imageUser =
        await sharedPreferencesFile.readStr('imageUrl');
    String fcmToken =
        await sharedPreferencesFile.readStr('fcmToken');

    User mUser = new User(
        firstName: uName,
        imageUrl: imageUser,
        documentID: currentLoggedInChatUid,
        fcmToken: fcmToken);

    await _firebaseStore.joinChatGroupFireBase(groupId: groupId, user:mUser);

    setState(() {
      isLoading = false;
      //Reset values
      controllers["name"].text = "";
      controllers["subHeader"].text = "";
      controllers["description"].text = "";
      imageFile = null;
    });
  }

  //Join group
  leftGroupDetails(String groupId) async {
    setState(() {
      isLoading = true;
    });

    String uName =
        await sharedPreferencesFile.readStr('nickName');
    String imageUser =
        await sharedPreferencesFile.readStr('imageUrl');
    String fcmToken =
        await sharedPreferencesFile.readStr('fcmToken');

    User mUser = new User(
        firstName: uName,
        imageUrl: imageUser,
        documentID: currentLoggedInChatUid,
        fcmToken: fcmToken);

    await _firebaseStore.leftChatGroupFireBase(groupId:groupId,user: mUser);

    setState(() {
      isLoading = false;
      //Reset values
      controllers["name"].text = "";
      controllers["subHeader"].text = "";
      controllers["description"].text = "";
      imageFile = null;
    });
  }
}

//******* Edit over flow option start ********
List<ChoiceTemp> choices = <ChoiceTemp>[
  ChoiceTemp(title: 'Edit', icon: Icons.edit),
  ChoiceTemp(title: 'Delete', icon: Icons.delete),
];

class ChoiceTemp {
  ChoiceTemp({this.title, this.icon,this.mChatGroups,this.id});
  final int id;
  final String title;
  ChatGroups mChatGroups;
  final IconData icon;
}
//******* Edit over flow option start *****
