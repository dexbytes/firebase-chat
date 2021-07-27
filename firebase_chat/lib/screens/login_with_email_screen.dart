import 'dart:io';
import 'package:device_info/device_info.dart';
import 'package:firebase_chat/chat_p/local_constant.dart';
import 'package:firebase_chat/chat_p/shared_preferences_file.dart';
import 'package:firebase_chat/chat_p/utils_p/app_color.dart';
import 'package:firebase_chat/chat_p/utils_p/app_dimens.dart';
import 'package:firebase_chat/chat_p/utils_p/app_fonts.dart';
import 'package:firebase_chat/chat_p/utils_p/app_string.dart';
import 'package:firebase_chat/chat_p/utils_p/custome_view.dart';
import 'package:firebase_chat/chat_p/utils_p/validation.dart';
import 'package:firebase_chat/firebse_chat_main.dart';
import 'package:firebase_chat/screens/inbox_screen.dart';
import 'package:firebase_chat/screens/register_with_gmail_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginWithEmailScreen extends StatefulWidget {
  @override
  _LoginWithEmailScreen createState() => _LoginWithEmailScreen();
}

class _LoginWithEmailScreen extends State<LoginWithEmailScreen>
    with WidgetsBindingObserver {
  var topViewHeight;
  var agree = false;
  String deviceToken, deviceOsVersion, deviceId;

  bool isLoading = false;
  bool showNewPass = true;
  AuthBase _auth = new Auth();
  FireBaseStore _fireBaseStore = new FireBaseStore();

  _LoginWithEmailScreen() {
    // appDimens.appDimensFind(context: this.context);
    deviceInfo();
    sharedPreferencesFile.readStr(deviceToken).then((value) {
      if (value == null) {
        print('getToken :');
        // new FirebaseNotifications().getToken();
      } else {
        print('already generated : $value');
        //new FirebaseNotifications().firebaseCloudMessagingListeners();
      }
    });
  }

  /*========device info==============*/
  Future deviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      print('is a IOS');

      //Device_type
      sharedPreferencesFile.readStr(deviceTypeC).then((value) {
        if (value == null) {
          print('Device_type ios}');
          sharedPreferencesFile.saveStr(deviceTypeC, '2');
        } else {
          print('Device_type $value');
          // deviceType = '2'
        }
      });

      //Device_os_version
      sharedPreferencesFile.readStr(deviceOsVersionC).then((value) {
        if (value == null) {
          print('Device_os_version ${iosInfo.systemVersion}');
          sharedPreferencesFile.saveStr(
              deviceOsVersionC, iosInfo.systemVersion);
        } else {
          print('Device_os_version $value');
        }
      });

      //Device id
      sharedPreferencesFile.readStr(deviceIdC).then((value) {
        if (value == null) {
          //device id
          print('Device id ${iosInfo.identifierForVendor}');
          sharedPreferencesFile.saveStr(deviceIdC, iosInfo.identifierForVendor);
        } else {
          print('Device id $value');
        }
      });
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      print('is a Andriod');

      //device type
      sharedPreferencesFile.readStr(deviceTypeC).then((value) {
        if (value == null) {
          print('Device_type android}');
          sharedPreferencesFile.saveStr(deviceTypeC, '1');
        } else {
          print('Device_type $value');
          //  deviceType = '1'
        }
      });

      //device os version
      sharedPreferencesFile.readStr(deviceOsVersionC).then((value) {
        if (value == null) {
          print('Device_os_version ${androidInfo.version.release}');
          sharedPreferencesFile.saveStr(
              deviceOsVersionC, androidInfo.version.release);
        } else {
          print('Device_os_version $value');
        }
      });

      //device id
      sharedPreferencesFile.readStr(deviceIdC).then((value) {
        if (value == null) {
          //device id
          print(' device id ${androidInfo.androidId}');
          sharedPreferencesFile.saveStr(deviceIdC, androidInfo.androidId);
        } else {
          print('device id $value');
        }
      });
    } else {}
  }

  Map<String, TextEditingController> controllers = {
    'email': new TextEditingController(),
    'password': new TextEditingController(),
  };

  Map<String, FocusNode> focusNodes = {
    'email': new FocusNode(),
    'password': new FocusNode(),
  };

  Map<String, String> errorMessages = {
    'email': null,
    'password': null,
  };

  bool passwordVisible = false;
  bool isUserNameValid = false;
  bool isOtherBackGroundApiCall = true;

  @override
  void initState() {
    super.initState();
    //getDeviceInfo();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    focusNodes['email'].dispose();
    focusNodes['password'].dispose();
    // Clean up the controller when the widget is disposed.
    WidgetsBinding.instance.removeObserver(this);
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

  @override
  Widget build(BuildContext context) {
    //Get Screen size
    appDimens.appDimensFind(context: context);

    topViewHeight = appDimens.heightDynamic(value: 245);
    // Check validation
    bool _isAllFieldValid() {
      if (controllers['email'].text == null ||
          controllers['email'].text == '' ||
          controllers['email'].text == "#error") {
        setState(() {
          if (controllers['email'].text != "#error") {
            errorMessages['email'] = appString.emailNotBlank;
          }
        });
        return false;
      } else if (controllers['password'].text == null ||
          controllers['password'].text == '' ||
          controllers['password'].text == "#error") {
        setState(() {
          if (controllers['password'].text != "#error") {
            errorMessages['password'] = appString.passwordNotBlank;
          }
        });
        return false;
      } else {
        return true;
      }
    }

    //Login text label
    Widget loginTextlabel = Align(
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () {},
        child: Text(
          "Log In",
          style: TextStyle(
              fontFamily: appFonts.defaultFont,
              //fontSize: screenWidth/18,
              fontSize: appDimens.fontSize(value: 24),
              fontWeight: FontWeight.w400,
              color: appColors.textHeadingColor),
        ),
      ),
    );

    //User name view
    Widget userNameView = Padding(
      padding: EdgeInsets.only(top: appDimens.verticalMarginPadding(value: 10)),
      child: customView.inputFields(
        keyboardType: 2,
        inputAction: 2,
        maxLength: 50,
        padding: EdgeInsets.all(appDimens.horizontalMarginPadding(value: 16)),
        readOnly: false,
        focusNode: focusNodes['email'],
        controller: controllers['email'],
        hint: "E-Mail",
        hintTextColor: appColors.editTextHintColor[100],
        fontSize: appDimens.fontSize(),
        error: errorMessages['email'],
        borderColor: appColors.editTextBorderColor[100],
        enabledBorder: appColors.editTextEnabledBorderColor[100],
        focusedBorderColor: appColors.editTextFocusedBorderColor[100],
        fillColor: appColors.editTextBgColor[100],
        cursorColor: appColors.editCursorColor[200],
        ontextChanged: (value) {
          if (validation.isNotEmpty(value)) {
            if (validation.validateEmail(value)) {
              print(value);
              setState(() {
                errorMessages['email'] = null;
                isUserNameValid = true;
              });
            } else {
              setState(() {
                isUserNameValid = false;
                errorMessages['email'] = appString.validEmail;
              });
            }
          } else {
            setState(() {
              //controllers['email'].text = "";
              isUserNameValid = false;
              errorMessages['email'] = appString.emailNotBlank;
            });
          }
        },
        onSubmit: (value) {
          {
            FocusScope.of(context).requestFocus(new FocusNode());
          }
          setState(() {
            controllers['email'].text = value;
          });
        },
      ),
    );

    Widget password = Padding(
      padding: EdgeInsets.only(
          top: appDimens.verticalMarginPadding(value: 10),
          bottom: appDimens.verticalMarginPadding(value: 10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /*inputFieldsLabel(AppValuesFilesLink().appValuesString.labelNewPass),*/
          Padding(
              padding: EdgeInsets.only(
                  top: appDimens.verticalMarginPadding(value: 13),
                  bottom: appDimens.verticalMarginPadding(value: 20)),
              child: customView.inputPasswordFields(
                keyboardType: 3,
                inputAction: 1,
                maxLength: 50,
                showPass: showNewPass,
                iconButton: IconButton(
                  icon: customView.suffixIconForPassword(showNewPass),
                  onPressed: () {
                    setState(() {
                      showNewPass = !showNewPass;
                    });
                  },
                ),
                readOnly: false,
                padding: EdgeInsets.all(
                    appDimens.horizontalMarginPadding(value: 16)),
                focusNode: focusNodes['password'],
                controller: controllers['password'],
                hint: appString.hintPassword,
                fontSize: appDimens.fontSize(value: 18),
                error: errorMessages['password'],
                errorColor: Colors.red,
                borderColor: appColors.editTextBorderColor[100],
                enabledBorder: appColors.editTextEnabledBorderColor[100],
                fillColor: appColors.editTextBgColor[100],
                focusedBorderColor: appColors.editTextFocusedBorderColor[100],
                cursorColor: appColors.editCursorColor[200],
                hintTextColor: appColors.editTextHintColor[100],
                ontextChanged: (value) {
                  if (validation.isNotEmpty(value)) {
                    if (value.length > 5) {
                      print(value);
                      if (validation.isPasswordValidation(value)) {
                        if (controllers['password'].text != null &&
                            controllers['password'].text != "") {
                          setState(() {
                            errorMessages['password'] = null;
                            passwordVisible = true;
                          });
                          /*if (controllers['password'].text ==
                            controllers['confirm_pass'].text) {
                          setState(() {
                            //isPasswordValid = true;
                            errorMessages['password'] = null;
                            errorMessages['confirm_pass'] = null;
                          });
                        } else {
                          errorMessages['password'] = appString.passwordConfirmation;
                        }*/
                        } else {
                          setState(() {
                            //isPasswordValid = true;
                            errorMessages['password'] = null;
                          });
                        }
                      } else {
                        setState(() {
                          errorMessages['password'] =
                              appString.passContainSpecialChar;
                          passwordVisible = false;
                        });
                      }
                    } else {
                      setState(() {
                        errorMessages['password'] = appString.passwordLength;
                        passwordVisible = false;
                      });
                    }
                  } else {
                    setState(() {
                      errorMessages['password'] = appString.newPasswordNotBlank;
                      passwordVisible = false;
                    });
                  }
                  _isAllFieldValid();
                },
                onSubmit: (value) {
                  /*FocusScope.of(context)
                    .requestFocus(focusNodes['confirm_pass']);*/
                  FocusScope.of(context).requestFocus(new FocusNode());
                  setState(() {
                    controllers['password'].text = value;
                  });
                },
              )),
        ],
      ),
    );

    //Input fields label
    Widget inputFieldsLabel(label) {
      return Padding(
        padding:
            EdgeInsets.only(top: appDimens.verticalMarginPadding(value: 24)),
        child: Text(
          label,
          style: TextStyle(
              fontFamily: appFonts.defaultFont,
              fontSize: appDimens.fontSize(value: 14),
              color: appColors.textNormalColor[100]),
        ),
      );
    }

    //Submit button view
    Widget submitButton = Container(
        height: appDimens.buttonHeight(value: 55),
        child: Align(
            alignment: Alignment.center,
            child: Stack(
              children: <Widget>[
                isLoading
                    ? Container(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors().loaderColor[300]),
                        ),
                        margin: EdgeInsets.only(bottom: 10),
                      )
                    : customView.buttonRoundCornerWithBg(
                        "Sign In",
                        (isUserNameValid && passwordVisible)
                            ? appColors.buttonTextColor
                            : appColors.buttonTextColor[100],
                        (isUserNameValid && passwordVisible)
                            ? appColors.buttonBgColor
                            : appColors.appDisabledColor[100],
                        appDimens.fontSizeButton(value: 16),
                        2, (value) {
                        if (isUserNameValid && passwordVisible) {
                          if (_isAllFieldValid()) {
                            /*ProjectUtil.printP(
                                "email", 'yes all field are valid');*/
                            loginStatusApi(
                              controllers['email'].text.toString(),
                              controllers['password'].text.toString(),
                            );
                          } else {
                            /*ProjectUtil.printP(
                                "email", 'no all field are not valid');*/
                          }
                        }
                      }),
              ],
            )));

    //email card
    Widget loginCardView = Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 0.3,
      margin: EdgeInsets.only(
          left: appDimens.horizontalMarginPadding(value: 25),
          right: appDimens.horizontalMarginPadding(value: 25),
          top: appDimens.verticalMarginPadding(value: 2)),
      child: Container(
        padding: EdgeInsets.only(
            left: appDimens.horizontalMarginPadding(value: 21),
            right: appDimens.horizontalMarginPadding(value: 21),
            top: appDimens.verticalMarginPadding(value: 29),
            bottom: appDimens.verticalMarginPadding(value: 22)),
        //height: screenHeight/1.8,
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              loginTextlabel,
              inputFieldsLabel("E-Mail"),
              userNameView,

              inputFieldsLabel("Password"),
              password,
              //termAndCondition,
              submitButton,
            ],
          ),
        ),
      ),
    );

    //Support view
    Widget supportContact = GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => RegisterWithEmailScreen()));
          //launch("mailto:" + appString.contactEmail);
        },
        child: Container(
          margin: EdgeInsets.only(
              left: appDimens.horizontalMarginPadding(value: 25),
              right: appDimens.horizontalMarginPadding(value: 25)),
          child: Stack(
            children: <Widget>[
              Container(
                alignment: Alignment.bottomCenter,
                margin: EdgeInsets.only(
                  top: appDimens.verticalMarginPadding(
                    value: 23,
                  ),
                  bottom: appDimens.verticalMarginPadding(
                    value: 36,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(
                          top: appDimens.verticalMarginPadding(value: 0.5)),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                              //fontWeight: FontWeight.w300,
                              fontFamily: appFonts.defaultFont,
                              color: appColors.textNormalColor[100],
                              fontSize: appDimens.fontSize(value: 14)),
                          text: appString.contactText,
                          children: <TextSpan>[
                            TextSpan(
                              text: appString.registerEmail,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontFamily: appFonts.defaultFont,
                                color: appColors.textNormalColor[600],
                                fontSize: appDimens.fontSize(value: 14),
                                //decoration: TextDecoration.underline,
                              ),
                            )
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ));
    //Main view
    return Scaffold(
        backgroundColor: appColors.appBgColor[100],
        appBar: PreferredSize(
            child: AppBar(
              brightness: (Platform.isIOS) ? Brightness.light : Brightness.dark,
              backgroundColor: appColors.primaryColor,
            ),
            preferredSize: Size.fromHeight(0.0)),
        body: new GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(new FocusNode());
            },
            child: Stack(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    Container(
                      color: appColors.appTopBgColor[100],
                      height: appDimens.heightFullScreen() * 0.5,
                    ),
                    Center(
                        child: ListView(
                      shrinkWrap: true,
                      children: <Widget>[
                        //topView,
                        Align(
                          child: Center(child: loginCardView),
                          alignment: Alignment.center,
                        ),
                        supportContact
                      ],
                    )),
                  ],
                ),
              ],
            )));
  }

  //login api caling
  loginStatusApi(String _eMail, String _ePassword) async {
    //Show loading
    setState(() {
      isLoading = true;
    });
    final authUserDetails =
        await _auth.signInWithEmailAndPassword(_eMail, _ePassword);
    if (authUserDetails == null) {
      Fluttertoast.showToast(msg: "User Not availble");
    } else {
      final authUserDetails = await _auth.currentUser();
      if (authUserDetails != null) {
        String fcmToken = await _auth.getFcmToken();

        await _fireBaseStore.updateFireBaseToken(
            uId: authUserDetails.uid, token: fcmToken);

        var value = await _fireBaseStore.getUserDetailsFireBase(
            uId: authUserDetails.uid);
        if (value == null) {
          String _eName = authUserDetails.email;
          await _fireBaseStore.addNewUserOnFireBase(
              uId: authUserDetails.uid, nickName: _eName, imageUrl: null);
        }
      }
      //Move to other screen
      moveToNextScreen(authUserDetails.uid);
    }
    setState(() {
      isLoading = false;
    });
    Fluttertoast.showToast(msg: "Sign in success");
  }

  //Move to next screen
  void moveToNextScreen(String uId) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) => InboxScreen(currentUserId: uId)),
      ModalRoute.withName('/'),
    );
  }
}
