import 'package:firebase_chat/chat_p/utils_p/app_color.dart';
import 'package:firebase_chat/chat_p/utils_p/app_dimens.dart';
import 'package:firebase_chat/chat_p/utils_p/app_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppBarBackArrowWithTitleAndSubTitle{
//App bar
  AppBar appBarBackArrowWithTitleAndSubTitle(bool back,String appBarTitle,bool isCenter,List<Widget> rightIcon,String appBarSubTitle, Color appBarTitleColor, Color appBarSubTitleColor, Color appBarBackIconColor,
      Color appBarBgColor, double screenSize, Function() onPressed) {
    return AppBar(
      backgroundColor: appBarBgColor,
      elevation: 0.0,
      //For card view
      flexibleSpace: Container(
        // Add box decoration
        decoration: BoxDecoration(
          // Box decoration takes a gradient
          gradient: LinearGradient(
            // Where the linear gradient begins and ends
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            // Add one stop for each color. Stops should increase from 0 to 1
            stops: [0.1, 0.6, 0.9],
            colors: [
              // Colors are easy thanks to Flutter's Colors class.
              Color(0xFFFFF),
              Color(0xFFFFF),
              Color(0xFFFFF),
            ],
          ),
        ),
      ),
      automaticallyImplyLeading: true,
      //`true` if you want Flutter to automatically add Back Button when needed,
      //or `false` if you want to force your own back button every where
      centerTitle: isCenter,
      title: (appBarSubTitle!=null && appBarSubTitle!= "")?
          Container(
        margin: EdgeInsets.only(bottom: 8),
        child:  Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: appDimens.heightDynamic(value: 24),
              child:  new Text(appBarTitle, style: new TextStyle(
                //fontWeight: FontWeight.w500,
                fontFamily: appFonts.mediumFont,
                color: appBarTitleColor,
                fontSize:appDimens.fontSize(value: 19),
              ),),
            ),
            new Text(appBarSubTitle, style: new TextStyle(
              //fontWeight: FontWeight.w500,
              fontFamily: appFonts.mainFont,
              color: appBarSubTitleColor,
              fontSize:appDimens.fontSize(value: 12),
            ),),
          ],
        ),
      ):
      Container(
        child: Align(
          alignment: Alignment.centerLeft,
          child: new Text(appBarTitle, style: new TextStyle(
            //fontWeight: FontWeight.w500,
            fontFamily: appFonts.mediumFont,
            color: appBarTitleColor,
            fontSize:appDimens.fontSize(value: 19),
          ),),
        )
      ),
      leading: back?IconButton(icon: new ImageIcon(
        new AssetImage("assets/images/back_arrow_appbar/Back1.png"),
        color: appBarBackIconColor!=null?appBarBackIconColor:null,
        size: appDimens.widthDynamic(value: 20),),
        onPressed: () => onPressed(),
      ):null,
      actions: rightIcon,
    );


  }

//App bar
  Widget appBarWithLeftRightIconTitleSubtitle(
      {Key key,
        bool back,
        double statusbarHeight,
        @required String title,
        Color titleColor,
        Color subtitleColor,
        double titleFontSize,
         String profileUrl,
        double profileSize,
        rightIcon,
        String appBarSubTitle,
        String notificationCount,
        double rightIconSize,
        double leftIconSize,
        double marginLeft,
        double marginRight,
        Color appBarBgColor,
        Color appBarBackIconColor,
        Function() onPressed,
        Function() onRightIconPressed}) {
    return PreferredSize(
        preferredSize: Size(
            appDimens.widthFullScreen(),
            appDimens.heightDynamic(
              value: 94 - statusbarHeight,
            )),
        child: Container(
          color: appBarBgColor!=null?appBarBgColor:appColors
              .appBarBgColor,
          child: Center(
            child: Stack(
              //crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                //Left icon
                Align(
                  child:  GestureDetector(
                    child: Container(
                      height:appDimens.heightDynamic(
                        value: 35,
                      ) ,
                      // color:Colors.red,
                      padding: EdgeInsets.only(
                        left: marginLeft ??
                            appDimens
                                .horizontalMarginPadding(
                              value: 20,
                            ),
                        right:
                        appDimens
                            .horizontalMarginPadding(
                          value: 18,
                        ),),
                      child: (back!=null && back)?Image(
                        image:
                        AssetImage("packages/firebase_chat/assets/images/Back1.png"),
                        color: appBarBackIconColor ??
                            appColors
                                .appBarLetIconColor[200],
                        width: leftIconSize ??
                            appDimens.imageSquareAccordingScreen(value: 20),
                        height: leftIconSize ??
                            appDimens.imageSquareAccordingScreen(value: 20),
                      ):Container(),
                    ),
                    onTap: () => (back!=null && back)?onPressed():null,
                  ),
                  alignment: Alignment.centerLeft,
                ),

                Align(
                  child:  Container(
                    padding: EdgeInsets.only(left: appDimens.horizontalMarginPadding(value: 60)),
                    width: appDimens.widthFullScreen(),
                    //margin: EdgeInsets.only(left: 70),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: (appBarSubTitle!=null && appBarSubTitle!= "")?
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        child:  Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(
                              height: appDimens.heightDynamic(value: 24),
                              child:  new Text(title, style: new TextStyle(
                                fontWeight: FontWeight.w500,
                                fontFamily: appFonts.defaultFont,
                                color: titleColor,
                                fontSize:appDimens.fontSize(value: 19),
                              ),),
                            ),
                            new Text(appBarSubTitle, style: new TextStyle(
                              //fontWeight: FontWeight.w500,
                              fontFamily: appFonts.mainFont,
                              color: subtitleColor,
                              fontSize:appDimens.fontSize(value: 12),
                            ),),
                          ],
                        ),
                      ):
                      Container(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child:  new Text(title, style: new TextStyle(
                              fontWeight: FontWeight.w500,
                              fontFamily: appFonts.defaultFont,
                              color: titleColor,
                              fontSize:appDimens.fontSize(value: 19),
                            ),),
                          )
                      ),),
                    alignment: Alignment.center,
                  ),

                ),

                rightIcon!=null?Align(
                  child:  GestureDetector(
                    child: Container(
                      padding: EdgeInsets.only(
                          right: marginRight ??appDimens.horizontalMarginPadding(
                                value: 20,
                              )),
                      child:
    (rightIcon.runtimeType != String)?
    /*If any Widget come like over flow menu*/rightIcon:
    /*If any normal image come*/Image(
      image:
      AssetImage(rightIcon),
      color: appBarBackIconColor ??
          appColors
              .appBarLetIconColor[200],
      width: leftIconSize ??
          appDimens.imageSquareAccordingScreen(value: 20),
      height: leftIconSize ??
          appDimens.imageSquareAccordingScreen(value: 20),
    ),
                    ),
                    onTap: () => onRightIconPressed(),
                  ),
                  alignment: Alignment.centerRight,
                ):Container(),
              ],
            ),
          )
        ));
  }
}
final appBarBackArrowWithTitleAndSubTitle = AppBarBackArrowWithTitleAndSubTitle();
