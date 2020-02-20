import 'package:timeago/timeago.dart'as timeago;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProjectUtil {
  static DateTime olddate;

  String getTimeAgo({Key key, @required int timestamp, String format}) {
    //Note /*
    //
    //
    // Add this dependancy
    // timeago: ^2.0.22
    //
    // */
    String formattedTime = "";
    try {
      if (format != null) {
      } else {
        final fifteenAgo = DateTime.fromMillisecondsSinceEpoch(timestamp);
        formattedTime = timeago.format(fifteenAgo, locale: 'en');
      }
    } catch (e) {
      formattedTime = "";
      print('error in formatting $e');
    }
    return formattedTime;
  }
  String getCompareDateStr(String timestamp, String format, int index) {
    String formattedTime = "";
    try {
      if (index <= 0) {
        olddate = null;
      }
      int timee = int.parse(timestamp);
      print('error in formatting $timee');
      DateTime date = new DateTime.fromMillisecondsSinceEpoch(timee);
      if (olddate == null) {
        olddate = date;
        formattedTime = new DateFormat(format).format(olddate);
      } else {
        String formattedTimeOld = "";
        String formattedTimeCurrent = "";
        formattedTimeOld = new DateFormat(format).format(olddate);
        formattedTimeCurrent = new DateFormat(format).format(date);
        if (formattedTimeOld == formattedTimeCurrent) {
          formattedTime = null;
        } else {
          olddate = date;
          formattedTime = new DateFormat(format).format(olddate);
        }
      }
    } catch (e) {
      formattedTime = "";
      print('error in formatting $e');
    }
    return formattedTime;
  }
}

final projectUtil = ProjectUtil();

