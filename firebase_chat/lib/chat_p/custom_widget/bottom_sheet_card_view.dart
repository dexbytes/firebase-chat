import 'package:firebase_chat/chat_p/utils_p/app_color.dart';
import 'package:firebase_chat/chat_p/utils_p/app_dimens.dart';
import 'package:firebase_chat/chat_p/utils_p/custome_view.dart';
import 'package:flutter/material.dart';

int showHideTemp = 0;
int cameraOpenTemp = 0;
var cardBodyViewTemp1;

class BottomSheetCardView extends StatefulWidget {
  final int showHide ;
  final cardBodyView;
  final sheetDismis;
  final cameraOpen;

  BottomSheetCardView(
      {Key key, this.showHide, this.cardBodyView, this.sheetDismis, this.cameraOpen}) {
    showHideTemp = this.showHide!=null?this.showHide:0;
    cardBodyViewTemp1 = this.cardBodyView;
    cameraOpenTemp = this.cameraOpen;
    //controller.reverse();
  }

  @override
  _BottomSheetCardViewState createState() => _BottomSheetCardViewState(
      showHide: this.showHide,
      cardBodyViewTemp: this.cardBodyView,
      sheetDismis: this.sheetDismis);
}

class _BottomSheetCardViewState extends State<BottomSheetCardView>
    with SingleTickerProviderStateMixin {
  static AnimationController controller;
  Animation<Offset> offset;
  int showHide = 0;
  var cardBodyViewTemp;
  var sheetDismis;
  @override
  void dispose() {

    super.dispose();
  }

  _BottomSheetCardViewState(
      {Key key, this.showHide, this.cardBodyViewTemp, this.sheetDismis}) {
    showHideTemp = showHide;
    cardBodyViewTemp1 = cardBodyViewTemp;
    sheetDismis = sheetDismis;

  }

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 400));
    offset = Tween<Offset>(begin: Offset(0.0, 1.0), end: Offset.zero)
        .animate(controller);
  }

  @override
  Widget build(BuildContext context) {
    if (showHideTemp == 1) {
      controller.forward();

    } else {
      controller.reverse();
    }
    //Semi transparent view
    Widget _semiTransPopUpBg() => Container(
          child: Material(
            color: appColors.appTransColor[600],
            child: InkWell(
              onTap: () => setState(() {
                showHideTemp = 0;
                sheetDismis();
              }), // handle your onTap here
              child: Container(
                  height:appDimens.heightFullScreen(),
                  width:appDimens.widthFullScreen()),
            ),
          ),
        );

    Future<bool> onBackPress() {
      showHideTemp = 0;
      sheetDismis();
      return Future.value(false);
    }

    return SafeArea(
      child: WillPopScope(
        child:Container(
          height: cameraOpenTemp==1?0: appDimens.heightFullScreen(),
          child:  Stack(
            children: <Widget>[
              Container(
                child: showHideTemp == 1 ? _semiTransPopUpBg() : Container(),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SlideTransition(
                  position: offset,
                  child: Padding(
                    padding: EdgeInsets.only(left: 0, right: 0, top: 0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(0.0),
                            topRight: Radius.circular(0.0)),
                      ),
                      elevation: 0.0,
                      margin: EdgeInsets.only(left: 0, right: 0, top: 0),
                      child: ListView(
                        shrinkWrap: true,
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.only(
                                left: appDimens.horizontalMarginPadding(value: 8),
                                right: appDimens.horizontalMarginPadding(value: 8),
                                top: 0,
                                bottom: 0),
                            //height: screenHeight/1.8,
                            child: Stack(
                              children: <Widget>[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    /*Align(
                                      alignment: Alignment.topCenter,
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          showHideTemp = 0;
                                          sheetDismis();
                                        }),
                                        child: customView.divider(),
                                      ),
                                    ),*/
                                    cardBodyViewTemp1 == null
                                        ? Container()
                                        : cardBodyViewTemp1
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      ),
                  ),
                ),
              )
            ],
          ),
        ),
        onWillPop: onBackPress,
      ),
    );
  }


}
