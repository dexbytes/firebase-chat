import 'package:firebase_chat/chat_p/custom_widget/pop_up_menu.dart';
import 'package:firebase_chat/chat_p/utils_p/app_color.dart';
import 'package:firebase_chat/chat_p/utils_p/app_dimens.dart';
import 'package:flutter/material.dart';

class PoupMenuWidgets extends StatefulWidget {
 final List<Choice> itemList;
  final selectedCallBack;
  final  menuView;
  PoupMenuWidgets({Key key,this.menuView,@required  this.itemList,@required this.selectedCallBack});

  @override
  _PoupMenuWidgetsState createState() => _PoupMenuWidgetsState(menuView: this.menuView, itemList : this.itemList,selectedCallBack : this.selectedCallBack);
}
class _PoupMenuWidgetsState extends State<PoupMenuWidgets> {
  List<Choice> choices =  <Choice>[
    Choice(title: 'Edit', icon: Icons.edit),
    Choice(title: 'Delete', icon: Icons.delete),
  ];

  List<Choice> academicYearChoices =  <Choice>[
    Choice(title: '1930 - 1934'),
  ];


  List<Choice> itemList;
  var selectedCallBack;
  var menuView ;

  @override
  void didUpdateWidget(PoupMenuWidgets oldWidget) {
// TODO: implement didUpdateWidget
    this.itemList = widget.itemList;
    this.selectedCallBack = widget.selectedCallBack;
    super.didUpdateWidget(oldWidget);
  }

  _PoupMenuWidgetsState({Key key,menuView,List<Choice> itemList, selectedCallBack}){
    this.itemList = itemList;
    this.selectedCallBack = selectedCallBack;
    this.menuView = menuView;
    //
    if(itemList!=null){
      choices =  new List();
      choices.addAll(this.itemList);
    }
  }

  @override
  Widget build(BuildContext context) {
    void _select(Choice choice) {
     String  _selectedChoice = choice.title;
     int  _selectedChoiceId = -1;
     try {
       _selectedChoiceId =  choice.id;
     } catch (e) {
       print(e);
     }

     selectedCallBack((_selectedChoiceId!=null&& _selectedChoiceId>=0)?_selectedChoiceId:_selectedChoice,choice);
     print("$_selectedChoice");
    }
    Widget popupMenuButton() {
      return PopupMenuButtons<Choice>(
        enabled: true,
        padding: EdgeInsets.only(top: 2),
        child: this.menuView!=null?menuView:Container(
            child: Align(child: Icon(Icons.more_vert,size: /*leftIconSize ??*/
                appDimens.imageSquareAccordingScreen(value: 20),color: /*appBarBackIconColor ??*/
                appColors.appBarLetIconColor[200],),
              alignment: Alignment.center,)
        ),
        onSelected: _select,
        itemBuilder: (BuildContext context) {
          return choices.skip(0).map((Choice choice) {
            // choice.mChatGroups = mChatGroups;
            return PopupMenuItems<Choice>(
              value: choice,
              child: Text(choice.title),
            );
          }).toList();
        },
      );
    }
    return popupMenuButton();
  }
}
class Choice {
  Choice({this.title, this.icon,this.id});
  final String title;
  final int id;
  final IconData icon;
}