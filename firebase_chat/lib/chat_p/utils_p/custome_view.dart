import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_chat/chat_p/local_constant.dart';
import 'package:firebase_chat/chat_p/utils_p/app_animation.dart';
import 'package:firebase_chat/chat_p/utils_p/app_color.dart';
import 'package:firebase_chat/chat_p/utils_p/app_dimens.dart';
import 'package:firebase_chat/chat_p/utils_p/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CustomView {
  /*============hide keyboard==========*/
  hideKeyboard(ctx) {
    FocusScope.of(ctx).requestFocus(new FocusNode());
  }

  //get first letter from string
  getFirstLetterFromName(String word) {
    var firstAndLastLetter = "NA";
    if (word != null) {
      if (word.trim() != null && word.trim() != "") {
        List wordSplit = new List();
        var firstLetter = "";
        var lastLetter = "";
        if (word.contains(" ")) {
          wordSplit = word.split(" ");
          try {
            firstLetter = String.fromCharCode(word.runes.first);
          } catch (e) {
            print(e);
          }
          if (wordSplit.length > 1) {
            try {
              String lastWordString = wordSplit[1];
              lastLetter = String.fromCharCode(lastWordString.runes.first);
            } catch (e) {
              print(e);
            }
          }
        } else {
          try {
            firstLetter = String.fromCharCode(word.runes.first);
            firstLetter = getDecodedValue(firstLetter);
          } catch (e) {
            print(e);
          }
        }
        firstAndLastLetter = firstLetter.toString().toUpperCase() +
            lastLetter.toString().toUpperCase();
      } else {
        return firstAndLastLetter;
      }
    }
    return firstAndLastLetter;
  }

  //get decoded format
  getDecodedValue(String value) {
    String decodedValue = value;
    try {
      decodedValue = utf8.decode(value.codeUnits);
    } catch (err) {
      print("Utils $err");
    }
    return decodedValue;
  }

  circularImageOrNameView(
      double height, double width, String image, String name) {
    try {
      name = getDecodedValue(name);
    } catch (e) {
      print(e);
    }

    // Animation<Color> color= AppValuesFilesLink().appValuesColors.primaryColor[500];
    if (image != null && image.trim() != "") {
      return Center(
          child: new Container(
              decoration: new BoxDecoration(
                shape: BoxShape.circle,
                // color: AppValuesFilesLink().appValuesColors.red
              ),
              height: height,
              width: width,
              child: Stack(
                children: <Widget>[
                  Center(
                    child: Container(
                        height: height / 5,
                        width: width / 5,
                        child: CircularProgressIndicator(
                          valueColor: new AlwaysStoppedAnimation<Color>(
                              appColors.loaderColor[300]),
                        )),
                  ),
                  (image != null && image.trim().length > 0)
                      ? ((image.contains('http') || image.contains('https'))
                          ?
                          /* ? ((image.contains('png') ||
            image.contains('jpg') ||
            image.contains('jpeg'))
            ? */
                          CircleAvatar(
                              radius: height / 2,
//          backgroundImage: NetworkImage(image),
                              backgroundImage: NetworkImage(image),
                              backgroundColor: Colors.transparent,
                            )
                          /* : new CircleAvatar(
          radius: height / 2,
          backgroundImage: NetworkImage(imageNotFoundC),
        )*/
                          : image.contains('assets')
                              ? new CircleAvatar(
                                  radius: height / 2,
                                  backgroundImage: /*image.contains('http')?Image.network(image)*/ AssetImage(
                                      image),
                                )
                              : new CircleAvatar(
                                  radius: height / 2,
                                  backgroundImage: /*image.contains('http')?Image.network(image)*/ FileImage(
                                      File(image)),
                                ))
                      : new CircleAvatar(
                          radius: height / 2,
                          backgroundImage: NetworkImage(imageNotFoundC),
                        )
                ],
              )));
    } else {
      var firstAndLastLetter = getFirstLetterFromName(name);
      return firstAndLastLetter != null
          ? Center(
              child: new Container(
                  decoration: new BoxDecoration(
                      shape: BoxShape.circle, color: appColors.iconColor[400]),
                  height: height,
                  width: width,
                  child: Center(
                    child: Text(
                        //count == 1 ? '1' : "+$count",
                        firstAndLastLetter != null ? firstAndLastLetter : "",
                        style: TextStyle(
                            fontFamily: appFonts.defaultFont,
                            fontSize: appDimens.fontSize(value: 14),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                            color: appColors.primaryColor)),
                  )))
          : Container();
    }
  }

  chatUploadedImageView1(double height, double width, String image) {
    //double height = 200, width=200;
    return CachedNetworkImage(
      imageUrl: image,
      imageBuilder: (context, imageProvider) {
        /*_calculateImageDimension(imageProvider).then((size) => {
         */ /* height = 0,
          width = 0,
          height = (size.height*0.5625)*0.2,
          width = (size.width*0.5625)*0.2,*/ /*

          //print("size = ${height}  wi  ${width}  size  ${size}")
        });*/

        return Container(
          height: appDimens.heightDynamic(value: height),
          width: appDimens.heightDynamic(value: width),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.circular(9)),
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
              /*colorFilter:
                     ColorFilter.mode(Colors.red, BlendMode.colorBurn)*/
            ),
          ),
        );
      },
      placeholder: (context, url) => Container(
        height: appDimens.heightDynamic(value: height),
        width: appDimens.heightDynamic(value: height),
        /* AppValuesFilesLink()
            .appValuesDimens
            .heightDynamic(value: height),*/
        //border radius according to number of images
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.all(Radius.circular(9)),
          //It is just a dummy image
        ),
        child: appAnimation.mShimmerEffectClass.shimmerEffectNewsFeedList(
            shimmerBaseColor: null,
            shimmerHighlightColor: null,
            height: height,
            width: width),
      ),
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }

  RaisedButton buttonRoundCornerWithBg(
      String label,
      Color labelColor,
      Color bgColor,
      double textSize,
      double borderRadius,
      Function(String) onPressed) {
    return RaisedButton(
      elevation: 0.0,
      child: Stack(
        children: <Widget>[
          Align(
              alignment: Alignment.center,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: appFonts.semiBoldFont,
                  color: labelColor,
                  fontSize: textSize,
                  //fontWeight: FontWeight.w400
                ),
              ))
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      onPressed: () => onPressed(label),
      color: bgColor,
    );
  }

  //
  Widget divider() {
    return Container(
      //height: AppValuesFilesLink().appValuesDimens.heightDynamic(value: 5),
      //color: AppValuesFilesLink().appValuesColors.appTransColor[700],
      //color: Colors.red,
      color: appColors.appTransColor[700],
      padding: EdgeInsets.only(
          top: appDimens.verticalMarginPadding(value: 22),
          bottom: appDimens.verticalMarginPadding(value: 13),
          left: appDimens.horizontalMarginPadding(value: 0),
          right: appDimens.verticalMarginPadding(value: 0)),
      width: appDimens.widthDynamic(value: 120),
      child: Container(
        height: appDimens.heightDynamic(value: 4),
        decoration: BoxDecoration(
          color: appColors.appDividerColor[600],
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
      ),
    );
  }

  //BottomSheet for take media
  Future confirmationBottomSheet(
      {Key key,
      context,
      headerTitle,
      view,
      sheetDismissCallback,
      screenWidth}) {
    /********* Image cropping End ********** */
    return showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            color: appColors.appTransColor[600],
            child: Padding(
              padding: EdgeInsets.only(left: 0, right: 0, top: 0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40.0),
                      topRight: Radius.circular(40.0)),
                ),
                elevation: 0.0,
                margin: EdgeInsets.only(left: 0, right: 0, top: 0),
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: sheetDismissCallback,
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: appDimens.verticalMarginPadding(value: 0)),
                          child: divider(),
                        ),
                      ),
                    ),
                    Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          margin: EdgeInsets.only(
                              top: (headerTitle != null && headerTitle != "")
                                  ? appDimens.verticalMarginPadding(value: 12)
                                  : 0,
                              bottom: appDimens.verticalMarginPadding(
                                  value:
                                      8), // bottom margin also added in divider
                              left: appDimens.verticalMarginPadding(value: 25),
                              right:
                                  appDimens.verticalMarginPadding(value: 25)),
                          child: Text(
                            headerTitle ?? "",
                            style: TextStyle(
                                fontFamily: appFonts.mediumFont,
                                fontSize: appDimens.fontSize(value: 20),
                                color: appColors.textHeadingColor),
                          ),
                        )),
                    view
                  ],
                ),
              ),
            ),
          );
        });
  }

  /*================suffix icon for password==============*/
  Icon suffixIconForPassword(bool oldpasswordVisible) {
    return oldpasswordVisible
        ? Icon(
            Icons.visibility_off,
            color: appColors.passwordVisibleEyeColor,
            size: 20,
          )
        : Icon(
            Icons.visibility,
            color: appColors.passwordVisibleEyeColor,
            size: 20,
          );

    /*Image(
            image: AssetImage("assets/images/home_module_images/NoSeen.png"),
            height: 25,
            width: 25,
          )
        : Image(
            image: AssetImage("assets/images/home_module_images/Seen.png"),
            height: 25,
            width: 25,
          );*/
  }

/*=========================ui for input field suffix icon with validation===============*/
  SizedBox passwordFieldWithErrorNSuffixIcon(
      bool visible,
      FocusNode focusNode,
      String hint,
      TextEditingController controller,
      IconButton iconButton,
      Function(String) ontextChanged,
      Function(String) onFieldSubmit,
      String error) {
    return SizedBox(
      //height: screenHeight / 15,
      child: TextFormField(
        obscureText: visible,
        focusNode: focusNode,
        textInputAction: TextInputAction.done,
        //controller: controller,
        textAlign: TextAlign.left,
        decoration: InputDecoration(
            //contentPadding: EdgeInsets.only(right: 30.0),
            hintText: hint,
            contentPadding: EdgeInsets.only(top: 20, bottom: 5),
            alignLabelWithHint: true,
            hintStyle: TextStyle(
                fontFamily: appFonts.mediumFont,
                color: appColors.editTextColor[400],
                fontSize: 16.0,
                fontWeight: FontWeight.w300),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: appColors.whiteUnSelected,
                width: 1.0,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: appColors.wordGreyColor)),
            // Here is key idea
            suffixIcon: iconButton,
            errorBorder: error != null
                ? UnderlineInputBorder(
                    borderSide: BorderSide(color: appColors.primaryColor))
                : UnderlineInputBorder(
                    borderSide: BorderSide(color: appColors.whiteUnSelected)),
            errorText: error),
        onChanged: ontextChanged,
        onFieldSubmitted: onFieldSubmit,
        cursorColor: appColors.lightBlack,
        style: TextStyle(
            fontSize: 16,
            fontFamily: appFonts.defaultFont,
            fontWeight: FontWeight.w400),
        autovalidate: true,
      ),
    );
  }

  TextField inputPasswordFields(
      {Key key,
      @required int keyboardType,
      @required int inputAction,
      @required int maxLength,
      @required bool readOnly,
      @required bool showPass,
      FocusNode focusNode,
      @required TextEditingController controller,
      @required String hint,
      @required double fontSize,
      String error,
      String prefixString,
      double focusedBorderWidth,
      IconButton iconButton,
      double borderRadius,
      Color errorColor,
      Color hintTextColor,
      int maxLines,
      EdgeInsetsGeometry padding,
      TextAlign textAlign,
      Color fillColor,
      Color borderColor,
      Color focusedBorderColor,
      Color enabledBorder,
      Color cursorColor,
      @required Function(String) ontextChanged,
      @required Function(String) onSubmit}) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      enableInteractiveSelection: true, //To remove selector
      textAlignVertical: TextAlignVertical.center,
      obscureText: showPass,
      //textAlign: textAlign!=null?textAlign:TextAlign.left,
      keyboardType: keyboardType == 1
          ? TextInputType.number
          : keyboardType == 2
              ? TextInputType.emailAddress
              : keyboardType == 3
                  ? TextInputType.text
                  : TextInputType.text,
      textCapitalization: keyboardType == 3
          ? TextCapitalization.words
          : keyboardType == 3
              ? TextCapitalization.sentences
              : TextCapitalization.none,
      textInputAction: inputAction == 1
          ? TextInputAction.done
          : inputAction == 2
              ? TextInputAction.next
              : inputAction == 3
                  ? TextInputAction.newline
                  : TextInputAction.done,
      inputFormatters: keyboardType == 1
          ? <TextInputFormatter>[WhitelistingTextInputFormatter.digitsOnly]
          : <TextInputFormatter>[],
      maxLength: maxLength,
      maxLines: maxLines != null ? maxLines : 1,
      decoration: InputDecoration(
          suffixIcon: iconButton,
          filled: true,
          fillColor: fillColor != null ? fillColor : appColors.editTextBgColor,
          hintText: hint != null ? hint : appColors.editTextHintColor,
          contentPadding: padding != null ? padding : EdgeInsets.all(0),
          //counterText: inputAction == 3 ? (controller != null ? controller.text.length.toString() : '') : "",
          counterText: "",
          hintStyle: TextStyle(
            color: hintTextColor != null ? hintTextColor : Colors.black87,
            fontSize: fontSize,
            //fontWeight: FontWeight.w300
          ),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                  Radius.circular(borderRadius != null ? borderRadius : 0)),
              borderSide: BorderSide(
                color: borderColor != null
                    ? borderColor
                    : appColors.appDisabledColor[400],
                style: BorderStyle.none,
              )),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                  Radius.circular(borderRadius != null ? borderRadius : 0)),
              borderSide: BorderSide(
                  color: focusedBorderColor != null
                      ? focusedBorderColor
                      : appColors.editTextEnabledBorderColor,
                  style: BorderStyle.none,
                  width: focusedBorderWidth != null ? focusedBorderWidth : 0)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                  Radius.circular(borderRadius != null ? borderRadius : 0)),
              borderSide: BorderSide(
                  color: focusedBorderColor != null
                      ? focusedBorderColor
                      : appColors.editTextEnabledBorderColor,
                  style: BorderStyle.none,
                  width: focusedBorderWidth != null ? focusedBorderWidth : 0)),
          errorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: errorColor != null
                      ? errorColor
                      : appColors.appErrorTextColor,
                  style: BorderStyle.solid)),
          errorText: error,
          errorMaxLines: 2),
      onSubmitted: onSubmit,
      style: TextStyle(color: appColors.textNormalColor[400]),

      onChanged: ontextChanged,
      cursorColor:
          cursorColor != null ? cursorColor : appColors.editCursorColor,
    );
  }

  TextField inputFields(
      {Key key,
      @required int keyboardType,
      @required int inputAction,
      @required int maxLength,
      @required bool readOnly,
      FocusNode focusNode,
      @required TextEditingController controller,
      @required String hint,
      @required double fontSize,
      String error,
      double focusedBorderWidth,
      double borderRadius,
      Color errorColor,
      Color hintTextColor,
      int maxLines,
      EdgeInsetsGeometry padding,
      TextAlign textAlign,
      Color fillColor,
      Color borderColor,
      Color focusedBorderColor,
      Color enabledBorder,
      Color cursorColor,
      @required Function(String) ontextChanged,
      @required Function(String) onSubmit}) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      enableInteractiveSelection: true, //To remove selector
      textAlignVertical: TextAlignVertical.center,
      //textAlign: textAlign!=null?textAlign:TextAlign.left,
      keyboardType: keyboardType == 1
          ? TextInputType.number
          : keyboardType == 2
              ? TextInputType.emailAddress
              : keyboardType == 3
                  ? TextInputType.text
                  : TextInputType.text,
      textCapitalization: keyboardType == 3
          ? TextCapitalization.words
          : keyboardType == 3
              ? TextCapitalization.sentences
              : TextCapitalization.none,
      textInputAction: inputAction == 1
          ? TextInputAction.done
          : inputAction == 2
              ? TextInputAction.next
              : inputAction == 3
                  ? TextInputAction.newline
                  : TextInputAction.done,
      inputFormatters: keyboardType == 1
          ? <TextInputFormatter>[WhitelistingTextInputFormatter.digitsOnly]
          : <TextInputFormatter>[],
      maxLength: maxLength,
      maxLines: maxLines != null ? maxLines : 1,
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor != null ? fillColor : appColors.editTextBgColor,
        hintText: hint != null ? hint : appColors.editTextHintColor,
        contentPadding: padding != null ? padding : EdgeInsets.all(0),
        //counterText: inputAction == 3 ? (controller != null ? controller.text.length.toString() : '') : "",
        counterText: "",
        hintStyle: TextStyle(
          color: hintTextColor != null ? hintTextColor : Colors.black87,
          fontSize: fontSize,
          //fontWeight: FontWeight.w300
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
                Radius.circular(borderRadius != null ? borderRadius : 0)),
            borderSide: BorderSide(
              color: borderColor != null
                  ? borderColor
                  : appColors.appDisabledColor[400],
              style: BorderStyle.none,
            )),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
                Radius.circular(borderRadius != null ? borderRadius : 0)),
            borderSide: BorderSide(
                color: focusedBorderColor != null
                    ? focusedBorderColor
                    : appColors.editTextEnabledBorderColor,
                style: BorderStyle.none,
                width: focusedBorderWidth != null ? focusedBorderWidth : 0)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
                Radius.circular(borderRadius != null ? borderRadius : 0)),
            borderSide: BorderSide(
                color: focusedBorderColor != null
                    ? focusedBorderColor
                    : appColors.editTextEnabledBorderColor,
                style: BorderStyle.none,
                width: focusedBorderWidth != null ? focusedBorderWidth : 0)),
        errorBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: errorColor != null
                    ? errorColor
                    : appColors.appErrorTextColor,
                style: BorderStyle.solid)),
        errorText: error,
      ),
      onSubmitted: onSubmit,
      style: TextStyle(color: appColors.textNormalColor[400]),

      onChanged: ontextChanged,
      cursorColor:
          cursorColor != null ? cursorColor : appColors.editCursorColor,
    );
  }

  RaisedButton buttonRoundCornerWithBgAndLeftImage(
      String label,
      String image,
      double iconSize,
      screenSize,
      Color labelColor,
      Color bgColor,
      double textSize,
      double borderRadius,
      Function(String) onPressed) {
    return RaisedButton(
      elevation: 0.0,
      child: Stack(
        children: <Widget>[
          Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Image(
                    image: new AssetImage(image),
                    width: iconSize,
                    height: iconSize,
                    // color: iconColor != null? iconColor: AppValuesFilesLink().appValuesColors.appTransColor,
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                  ),
                  Padding(
                      padding: EdgeInsets.only(
                        left: 5,
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                            fontFamily: appFonts.defaultFont,
                            color: labelColor,
                            fontSize: textSize,
                            fontWeight: FontWeight.w400),
                      ))
                ],
              ))
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      onPressed: () => onPressed(label),
      color: bgColor,
    );
  }

  circleTextView(double height, double width, double fontSize, int count,
      Color circleTextColor, Color circleBgColor) {
    return Center(
        child: new Container(
            decoration:
                new BoxDecoration(shape: BoxShape.circle, color: circleBgColor),
            height: height,
            width: width,
            child: Center(
              child: Text(
                  // count == 1 ? '1' : "+$count",
                  "+$count",
                  style: TextStyle(
                      fontFamily: appFonts.defaultFont,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: circleTextColor)),
            )));
  }

  //Set rect image
  rectImageView(double height, double width, String image) {
    return Center(
        child: new Container(
            decoration: new BoxDecoration(
              shape: BoxShape.circle,
            ),
            height: height,
            width: width,
            //child: new Image.network(image, fit: BoxFit.cover, gaplessPlayback: true)));
            child: (image.contains('http') || image.contains('https'))
                ? new Image.network(image,
                    fit: BoxFit.cover, gaplessPlayback: true)
                : image.contains('assets')
                    ? AssetImage(image)
                    : Image.file(File(image), fit: BoxFit.cover)));
  }

  String getTimeByMilliseconds(int timestamp, String formate) {
    String formattedTime = "";
    try {
      DateTime date = new DateTime.fromMillisecondsSinceEpoch(timestamp);
      var format = new DateFormat(formate);
      formattedTime = format.format(date);
    } catch (e) {
      formattedTime = "";
      print('CustomerUi error in formatting $e');
    }
    return formattedTime;
  }
}

final customView = CustomView();
