import 'dart:async';
import 'dart:io';
import 'package:firebase_chat/chat_p/shared_preferences_file.dart';
import 'package:firebase_chat/chat_p/utils_p/app_color.dart';
import 'package:firebase_chat/chat_p/utils_p/app_dimens.dart';
import 'package:firebase_chat/chat_p/utils_p/app_fonts.dart';
import 'package:firebase_chat/chat_p/utils_p/back_arrow_with_title_and_sub_title_app_bar.dart';
import 'package:firebase_chat/chat_p/utils_p/custome_view.dart';
import 'package:firebase_chat/firebse_chat_main.dart';
import 'package:firebase_chat/screens/one_to_one_chat_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class UsersListScreen extends StatefulWidget {
  UsersListScreen();
  @override
  _UsersListScreen createState() => _UsersListScreen();
}
class _UsersListScreen extends State<UsersListScreen> with WidgetsBindingObserver {
  int followersOrFollowing = 2;
  String authorization;
  bool isLoading = false;
  List<dynamic> usersList = new List();
  List<dynamic> usersDuplicateList = new List();

  int followStatus = 0;
  int fcmDataretrayCount = 3;

  var academicYearChoices;
  var isSubLoading = false;
  bool isReadyToClick = false;
  String selfUserChatId;

  StreamController<dynamic> streamController = new StreamController();


  _UsersListScreen() {
    appDimens.appDimensFind(context: context); //To find current screen width
    sharedPreferencesFile
        .readStr('chatUid')
        .then((value) {
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

  String searchInput;
  Map<String, TextEditingController> controllers = {
    'search': new TextEditingController(),
  };

  Map<String, FocusNode> focusNodes = {
    'search': new FocusNode()
  };

  Map<String, String> errorMessages = {'search': null};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    focusNodes['search'].dispose();
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
  RefreshController _refreshController =  RefreshController(initialRefresh: false);
  /*Pul To refresh*/
  void _onRefresh() async {
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    if (mounted) setState(() {});
  }


  @override
  Widget build(BuildContext context) {
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
          }
          else {
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
      child:
      StreamBuilder(
        stream: FireBaseStore().getUsersListFireBase().asStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors().loaderColor[300]),

              ),
            );
          }
          else {
            if(searchInput==null) {
              usersList = new List();
              usersList.addAll(snapshot.data);

              usersDuplicateList = new List();
              usersDuplicateList.addAll(snapshot.data);
            }

            return usersList.length>0? ListView.builder(
              padding: EdgeInsets.fromLTRB(
                appDimens.horizontalMarginPadding(value: 15),
                appDimens.horizontalMarginPadding(value: 20),
                appDimens.horizontalMarginPadding(value: 15),
                appDimens.horizontalMarginPadding(value: 20),
              ),
              itemBuilder: (context, index) =>
                  buildItemRow(context, usersList[index]),
              itemCount: usersList.length,
            ):
            Center(
                child: Text("No Users found!")
            );
          }
        },
      ),

    );

    //Search view
    Widget searchField = Container(
        color: appColors.editTextBgColor,
        padding: EdgeInsets.only(
          left: appDimens.widthDynamic(value: 20),
        ),
        height: appDimens.heightDynamic(value: 53),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Image(
                        image: AssetImage(
                            "packages/firebase_chat/assets/images/search@3x.png"),
                        width: appDimens.widthDynamic(value: 22),
                        height: appDimens.widthDynamic(value: 22),
                      ),
                    )),
                onTap: () {},
              ),
              Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                        left: appDimens.horizontalMarginPadding(value: 12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        new Flexible(
                          child: Padding(
                              padding: const EdgeInsets.only(
                                top: 4,
                              ),
                              child: Center(
                                child: customView.inputFields(
                                  keyboardType: 2,
                                  inputAction: 1,
                                  maxLength: 200,
                                  readOnly: false,
                                  //textAlign:TextAlign.center,
                                  hint: "Search ...",
                                  hintTextColor: appColors.editTextHintColor[100],
                                  controller: controllers['search'],
                                  fontSize: appDimens.fontSize(value: 16),
                                  cursorColor: appColors.editCursorColor[200],
                                  ontextChanged: (value) {
                                    if (value != null) {
                                      searchInput = value.trim().trim();
                                      filterSearchResults(
                                          query: searchInput);
                                    } else {
                                      searchInput = null;
                                      filterSearchResults(
                                          query: searchInput);
                                    }
                                  },
                                  onSubmit: (value) {
                                    if (value != null) {
                                      searchInput = value.trim().trim();
                                      filterSearchResults(
                                          query: searchInput);
                                    } else {
                                      searchInput = null;
                                      filterSearchResults(
                                          query: searchInput);
                                    }
                                  },
                                ),
                              )),
                        ),
                      ],
                    ),
                  ))
            ],
          ),
        ));

    //App bar
    Widget appBar =  appBarBackArrowWithTitleAndSubTitle.appBarWithLeftRightIconTitleSubtitle(
        statusbarHeight:MediaQuery.of(context).padding.top,
        back:true,
        title: "Users",
        appBarBgColor: appColors.appBarBgColor,
        titleColor:
        appColors.appBarTextColor[600],
        titleFontSize:
        appDimens.fontSize(value: 20),
        rightIcon: null,
        rightIconSize:
        appDimens.widthDynamic(value: 22),
        leftIconSize:
        appDimens.widthDynamic(value: 20),
        onPressed: () {
          Navigator.pop(context);
        },
        onRightIconPressed: () {

        });

    Future<bool> onBackPress() async {
      exit(0);
      return Future.value(true);
    }
    /*==================== Main view ======================*/
    return
      WillPopScope(
        child:
        Container(
            color: appColors.appBgColor[200],
            child:  SafeArea(
                child:new Scaffold(
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
                          Container(
                              margin: EdgeInsets.only(
                                  top: appDimens.verticalMarginPadding(value: 0)),
                              child:searchField),
                          // List
                          Container(
                              margin: EdgeInsets.only(
                                  top: appDimens.verticalMarginPadding(value: appDimens.heightDynamic(value: 55))),
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

  Widget buildItemRow(BuildContext context, document) {
    if (document == null) {
      return Container();
    }
    else {
      String time = "", alumniName = "", message = "", profileImage;
      String otherUid;
      try {
        //time = document['timestamp'];
        alumniName = document['nickName'];
        profileImage = document['imageUrl'];
        otherUid = document['id'];
      }
      catch (e) {
        print(e);
      }
      return
        (selfUserChatId!=null && otherUid!=null && selfUserChatId!=otherUid)?
        Container(
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
                              fontFamily:
                              appFonts.defaultFont,
                              fontSize: appDimens.fontSize(value: 18),
                              color: appColors.textHeadingColor[100],
                            ),
                            maxLines: 1,
                          ),
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                        ),
                        Container(
                          child: Text('$message',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontFamily: appFonts.defaultFont,
                                  fontSize: appDimens
                                      .fontSize(value: 12),
                                  fontWeight: FontWeight.w400,
                                  color: AppColors().textNormalColor[300]),
                              maxLines: 1),
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
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
                          child:
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
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
                                          fontFamily: appFonts.defaultFont,
                                          fontWeight: FontWeight.w400,
                                          fontSize: appDimens
                                              .fontSize(value: 12),
                                          color: AppColors().textNormalColor[300],
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
              if (otherUid != null && otherUid.toString().length > 0) {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            OneToOneChatScreen(
                              peerId: otherUid,
                              name: alumniName != null ? alumniName : "",
                              peerAvatar: profileImage,
                              isGroupChat: false,
                            )));
              }
            },
            color: appColors.listRowBgColor[700],
            padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 22.0),
          ),
          margin: EdgeInsets.only(bottom: 0, left: 0.0, right: 5.0),
        ):Container();
    }
  }


  //Function for search
  void filterSearchResults({Key key, String query, List<dynamic> selectedFilter}) {
    List<dynamic> alumniListForSearch = List<dynamic>();
    alumniListForSearch.addAll(usersDuplicateList);
    if (query != null && query.isNotEmpty && query != "") {
      List<dynamic> dummyListData = List<dynamic>();
      alumniListForSearch.forEach((item) {
        if (item["nickName"]
            .toString()
            .trim()
            .toLowerCase()
            .contains(query.trim().toLowerCase()) ||
            item["lastName"]
                .toString()
                .trim()
                .toLowerCase()
                .contains(query.trim().toLowerCase()) ||
            item["firstName"]
                .toString()
                .trim()
                .toLowerCase()
                .contains(query.trim().toLowerCase())) {
          print(query);
          dummyListData.add(item);
        }
      });
      setState(() {
        usersList.clear();
        usersList.addAll(dummyListData);
      });
      //return;
    }
    else {
      //Apply filter
      setState(() {
        usersList.clear();
        usersList.addAll(usersDuplicateList);
      });
    }
  }
}
