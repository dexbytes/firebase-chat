import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_chat/chat_p/api_request.dart';
import 'package:firebase_chat/chat_p/shared_preferences_file.dart';
import 'package:firebase_chat/screens/inbox_p/models/group.dart';
import 'package:firebase_chat/screens/inbox_p/models/user_profile_details.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'local_constant.dart';
import 'api_constant.dart';

// In case we decide to implement another kind of authorization method
abstract class FireBaseStoreBase {
  // Sent new message
  Future<dynamic> sentMessageFireBase(
      {Key key,
      String uId,
      String peerId,
      String groupChatId,
      String name,
      String content,
      int type,
      bool isFromGroup});
  //Sent notification
  Future<dynamic> sentFCMNotificationFireBase(
      {Key key,
      receiverId,
      String senderName,
      String uId,
      String content,
      bool isFromGroup,
      bool isFirstTime,
      String notificationSentApi});
  //Upload file on fire-base
  Future<dynamic> uploadFileFireBase({Key key, File imageFile});
  //Update notification token of user
  Future<dynamic> updateFireBaseToken({Key key, String uId, String token});

  //******************* User details  ******************************************
  //Add new user on fire-base
  Future<dynamic> addNewUserOnFireBase(
      {Key key, String uId, String nickName, String imageUrl});
  //Get single fire-base user details
  Future<dynamic> getUsersListFireBase();
  //Get single fire-base user details
  Future<dynamic> getUserDetailsFireBase({Key key, String uId});
  //Update fire-base user details
  Future<dynamic> updatedUserProfileFireBase(
      {Key key, String uId, String nickName, String imageUrl});
  //******************* User Details ******************************************

  //******************* Group ******************************************
  //Get total joined group count
  Future<dynamic> getGroupCountFireBase({Key key, String uId});
  //Get fire-base group list privet, public and all
  Future<dynamic> getGroupsFireBase({Key key, String uId, bool isAll});
  //Get group details/info
  Future<dynamic> getGroupDetailsFireBase({Key key, String uId});
  //Create group on fire-base
  Future<dynamic> createChatGroupFireBase(
      {Key key, chatGroup, user, usersList, String notificationSentApi});
  Future<dynamic> inviteUserInGroupFireBase(
      {Key key, chatGroup, usersList, String notificationSentApi});
  //Update group details/info
  Future<dynamic> updatedChatGroupFireBase({Key key, chatGroup, UsersDetails user});

  //Join any group
  Future<dynamic> joinChatGroupFireBase({Key key, groupId, UsersDetails user});
  //Left group
  Future<dynamic> leftChatGroupFireBase({Key key, String groupId, user});
  //Delete group
  Future<dynamic> deleteChatGroupFireBase({Key key, String groupId});
  //******************* End Group ******************************************

  //******************* User Inbox ******************************************
  //Get inbox data list from fire-base
  Future<dynamic> getChatInboxFireBase({Key key, String uId, bool isAll});
  //inbox message update
  Future<dynamic> inboxUpdateMessageReadStatusFireBase(
      {Key key, String uId, bool isGroup});

  Future<dynamic> setBaseUrl({Key key, String url});
  Future<dynamic> setNotificationUrl({Key key, String url});
  //This below functions are using internally
  /* Future<dynamic> inboxNewEntryFireBase({Key key,String selfUid,String uId,ChatGroups chatGroup,
      User user,@required bool isFromGroup});*/
  /*Future<dynamic> inboxUpdateGroupJoinStatusFireBase({Key key,String selfUid,
      String uId,ChatGroups chatGroup,User user,bool isFromGroup});*/
//******************* End User Inbox ******************************************

}

class FireBaseStore implements FireBaseStoreBase {
  FirebaseAuth fireBaseAuth = FirebaseAuth.instance;
  FirebaseFirestore fireBaseStore = FirebaseFirestore.instance;

  //Get inbox from fire-base
  Future<dynamic> getChatInboxFireBase(
      {Key key, String uId, bool isAll}) async {
    try {
      //If want all list
      if (isAll) {
        uId = null;
      }
      if (uId != null) {
        //Get List of group or messages main node
        final QuerySnapshot result = await FirebaseFirestore.instance
            .collection('users_inbox')
            .doc(uId)
            .collection('inbox_user')
            .orderBy('timestamp', descending: true)
            .get();
        //.getDocuments();
        final List<DocumentSnapshot> listOfInbox = result.docs;
        //Get selected user data from list
        if (listOfInbox != null && listOfInbox.length > 0) {
          return listOfInbox;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  //Inbox update at new message and reade status
  Future<dynamic> inboxUpdateMessageReadStatusFireBase(
      {Key key, String uId, bool isGroup}) async {
    if (isGroup == null) {
      isGroup = false;
    }
    try {
      sharedPreferencesFile.readStr('chatUid').then((selfUid) {
        if (selfUid != null && uId != null) {
          try {
            //Update in self
            FirebaseFirestore.instance
                .collection('users_inbox')
                .doc(selfUid)
                .collection('inbox_user')
                .doc(uId)
                .update({'isReded': true});
            //.updateData({'isReded': true});
          } catch (e) {
            print(e);
          }
        }
      });
      return true;
    } on Exception catch (e) {
      // TODO
      print("firebase error $e");
      return false;
    }
  }

  //Send Message group
  Future<dynamic> sentMessageFireBase(
      {Key key,
      String uId,
      String peerId,
      String groupChatId,
      String name,
      String content,
      int type,
      bool isFromGroup}) async {
    //Check group id is created or not
    var documentReference = FirebaseFirestore.instance
        .collection('messages')
        .doc(groupChatId)
        .collection(groupChatId)
        // .doc(timeStamp.toString());
        .doc(DateTime.now().millisecondsSinceEpoch.toString());

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      await transaction.set(
        documentReference,
        {
          'idFrom': uId,
          'idTo': peerId,
          'name': name != null ? name : "NA",
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          //'timestamp': FieldValue.serverTimestamp().toString(),
          'content': content,
          'type': type
        },
      );
    });

    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection('messages')
        .where('id', isEqualTo: groupChatId)
        .get();
    // .getDocuments();
    final List<DocumentSnapshot> docs = result.docs;
    if (docs.length == 0) {
      try {
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(groupChatId)
            .set({
          'id': groupChatId,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'isGroup': isFromGroup
        });
        print("success $groupChatId");
        return "";
      } catch (e) {
        print(e);
        print("error $e");
        return "";
      }
    }
    return "";
  }

  //Delete group
  //Delete group
  Future<dynamic> deleteChatGroupFireBase({Key key, String groupId}) async {
    //Check group id is created or not
    try {
      if (groupId != null) {
        try {
          //Delete group from user inbox
          final QuerySnapshot groupDetails = await FirebaseFirestore.instance
              .collection('user_groups')
              .where('gId', isEqualTo: groupId)
              .get();
          // .getDocuments();
          if (groupDetails != null && groupDetails.docs != null) {
            final List<DocumentSnapshot> documentsUser = groupDetails.docs;
            if (documentsUser != null && documentsUser.length > 0) {
              DocumentSnapshot detailsTemp = documentsUser[0];
              List<dynamic> groupUsersList = detailsTemp["usersDetails"];
              if (groupUsersList != null && groupUsersList.length > 0) {
                for (int i = 0; i < groupUsersList.length; i++) {
                  var singleUserDetails = groupUsersList[i];
                  if (singleUserDetails != null) {
                    try {
                      String userId = singleUserDetails["id"];
                      if (userId != null) {
                        var chatId = groupId;
                        await inboxUpdateGroupDeleteStatusFireBase(
                            selfUid: userId,
                            chatId: chatId,
                            deleteStatus: true);
                      }
                    } catch (e) {
                      print(e);
                    }
                  }
                }
              }
            }
          }
          print("Ok");
        } catch (e) {
          // TODO
          print("firebase error $e");
        }
        try {
          await FirebaseFirestore.instance
              .collection("user_groups")
              .doc(groupId)
              .update({"isDeletes": true});
          Fluttertoast.showToast(msg: 'Deleted successfully');
          return true;
        } on Exception catch (e) {
          // TODO
          print("firebase error $e");
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  //Upload image on fire-base
  Future<dynamic> uploadFileFireBase({Key key, File imageFile}) async {
    String imageUrl;
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference reference = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = reference.putFile(imageFile);
      TaskSnapshot storageTaskSnapshot =
          await uploadTask.whenComplete(() => null);
      String downloadUrl = await storageTaskSnapshot.ref
          .getDownloadURL(); //.then((downloadUrl) {
      imageUrl = downloadUrl;
      return imageUrl;
    } catch (e) {
      print(e);
      return imageUrl;
    }
  }

/*  //Upload image on fire-base
  Future<String> uploadFile(File imageFile) async {
    String imageUrl;
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      StorageReference reference =
      FirebaseStorage.instance.ref().child(fileName);
      StorageUploadTask uploadTask = reference.putFile(imageFile);
      TaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
      String downloadUrl = await storageTaskSnapshot.ref
          .getDownloadURL(); //.then((downloadUrl) {
      imageUrl = downloadUrl;
      return imageUrl;
    } catch (e) {
      print(e);
      return imageUrl;
    }
  }*/

  //Add user details in fire-base users table
  Future<dynamic> addNewUserOnFireBase(
      {Key key, String uId, String nickName, String imageUrl}) async {
    try {
      if (uId != null && nickName != null) {
        // Check is already sign up
        final QuerySnapshot result = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: uId)
            .get();
        // .getDocuments();
        final List<DocumentSnapshot> docs = result.docs;
        if (docs.length == 0) {
          //Update data to server if new user
          FirebaseFirestore.instance.collection('users').doc(uId).set({
            'nickName': nickName,
            'imageUrl': imageUrl,
            'id': uId,
            'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
            'chattingWith': null
          });
          return true;
        } else {
          return true;
        }
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<dynamic> updateFireBaseToken(
      {Key key, String uId, String token}) async {
    try {
      if (uId != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(uId)
            .update({'pushToken': token});
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  //Edit/Updated user details on fire-base
  Future<dynamic> updatedUserProfileFireBase(
      {Key key, String uId, String nickName, String imageUrl}) async {
    //Check group id is created or not
    try {
      if (uId != null) {
        String mid = uId;
        Map<String, String> data = new Map<String, String>();
        if (nickName != null && nickName.trim().length > 0) {
          data['nickName'] = nickName;
        }
        if (imageUrl != null && imageUrl.trim().length > 0) {
          data['imageUrl'] = imageUrl;
        }
        await FirebaseFirestore.instance
            .collection("users")
            .doc(mid)
            .update(data);
        return true;
      } else {
        return false;
      }
    } on Exception catch (e) {
      // TODO
      print("firebase error $e");
      return false;
    }
  }

  //Create group on fire-base
  createChatGroupFireBase(
      {Key key, chatGroup, user, usersList, String notificationSentApi}) async {
    List<dynamic> userListTemp = new List();
    // Private group
    if (chatGroup.groupType == 1) {
      for (int i = 0; i < usersList.length; i++) {
        var uId = usersList[i];
        var obj = {
          "name": "",
          "id": uId,
          "imageUrl": "",
          "pushToken": "",
          "isRequestNotAccepted": (user.documentID == uId) ? false : true,
        };
        userListTemp.add(obj);
      }
    }
    //Public group
    else if (chatGroup.groupType == 0) {
      var obj = {
        "name": user.firstName != null ? user.firstName : "",
        "id": user.documentID,
        "imageUrl": user.imageUrl,
        "pushToken": user.fcmToken,
        "isRequestNotAccepted": false,
      };
      userListTemp.add(obj);
    }

    var documentReference =
        await FirebaseFirestore.instance.collection('user_groups').add({
      'createBy': chatGroup.createBy,
      'name': chatGroup.name,
      'subHeading': chatGroup.subHeading,
      'groupType': chatGroup.groupType,
      'gId': "",
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      'description': chatGroup.description,
      'totalUser': chatGroup.totalUser != null ? chatGroup.totalUser : 1,
      'image': chatGroup.image != null ? chatGroup.image : "",
      'usersDetails': userListTemp,
      'isDeletes': false
    });

    //Check group id is created or not
    if (documentReference != null && documentReference.id != null) {
      try {
        await FirebaseFirestore.instance
            .collection('user_groups')
            .doc(documentReference.id)
            .update({
          'gId': documentReference.get(),
        });

        try {
          try {
            if (chatGroup.groupType == 1) {
              for (int i = 0; i < usersList.length; i++) {
                await inboxNewEntryFireBase(
                    selfUid: usersList[i],
                    uId: documentReference.id,
                    chatGroup: chatGroup,
                    isFromGroup: true);
              }

              try {
                String currentLoggedInChatId =
                    await sharedPreferencesFile.readStr("chatUid");
                var usersListTemp = usersList;
                if (usersListTemp != null &&
                    usersListTemp.length > 0 &&
                    currentLoggedInChatId != null &&
                    usersListTemp.contains(currentLoggedInChatId)) {
                  usersListTemp.remove(currentLoggedInChatId);
                }
                //Sent notification
                await sentFCMNotificationFireBaseByApi(
                    receiverId: usersListTemp,
                    senderName: chatGroup.name,
                    content: "",
                    isFromGroup: false,
                    isFirstTime: true,
                    uId: currentLoggedInChatId,
                    isForGroupInvite: true,
                    notificationSentApi: notificationSentApi);
              } catch (e) {
                print(e);
              }
            } else {
              //Add group in in box
              await inboxNewEntryFireBase(
                  selfUid: user.documentID,
                  uId: documentReference.id,
                  chatGroup: chatGroup,
                  isFromGroup: true);
            }
          } catch (e) {
            print(e);
          }
        } catch (e) {
          // TODO
          print("firebase error $e");
        }
        return ChatGroups(gId: documentReference.id);
      } on Exception catch (e) {
        // TODO
        print("firebase error $e");
        return null;
      }
    } else {
      return ChatGroups(gId: null);
    }
  }

  //Invite user in group on fire-base
  inviteUserInGroupFireBase(
      {Key key, chatGroup, usersList, String notificationSentApi}) async {
    List<dynamic> userListTemp = new List();
    // Private group
    if (chatGroup.groupType == 1) {
      for (int i = 0; i < usersList.length; i++) {
        var uId = usersList[i];
        var obj = {
          "name": "",
          "id": uId,
          "imageUrl": "",
          "pushToken": "",
          "isRequestNotAccepted": true,
        };
        userListTemp.add(obj);
      }
    }
    try {
      await FirebaseFirestore.instance
          .collection("user_groups")
          .doc(chatGroup.gId)
          .update({"usersDetails": FieldValue.arrayUnion(userListTemp)});

      try {
        if (chatGroup.groupType == 1) {
          for (int i = 0; i < usersList.length; i++) {
            await inboxNewEntryFireBase(
                selfUid: usersList[i],
                uId: chatGroup.gId,
                chatGroup: chatGroup,
                isFromGroup: true);
          }

          try {
            String currentLoggedInChatId =
                await sharedPreferencesFile.readStr("chatUid");
            //Sent notification
            await sentFCMNotificationFireBaseByApi(
                receiverId: usersList,
                senderName: chatGroup.name,
                content: "",
                isFromGroup: false,
                isFirstTime: true,
                uId: currentLoggedInChatId,
                isForGroupInvite: true,
                notificationSentApi: notificationSentApi);
          } catch (e) {
            print(e);
          }
        }
      } catch (e) {
        print(e);
      }
    } catch (e) {
      print(e);
    }
    print("firebase error $userListTemp");
  }

  //Get group count on fire-base
  Future<dynamic> getGroupsFireBase({Key key, String uId, bool isAll}) async {
    try {
      //If want all list
      if (isAll) {
        uId = null;
      }
      if (uId != null || isAll) {
        String createById = uId;
        CollectionReference ref =
            FirebaseFirestore.instance.collection('user_groups');
        final QuerySnapshot result =
            await ref.where('isDeletes', isEqualTo: false).get();
        //.getDocuments();
        List<DocumentSnapshot> docs = result.docs;
        if (docs.length != 0) {
          docs.sort((a, b) => a['timestamp'].compareTo(b[
              'timestamp'])); //Sort list according time (Arrange list according time)
          docs = docs.reversed
              .toList(); // revers list according time new created will come on top
          List<DocumentSnapshot> documentsTemp = new List();
          if (!isAll && createById != null) {
            for (var doc in docs) {
              String groupMemberList;
              if (doc['usersDetails'] != null) {
                groupMemberList = doc['usersDetails'].toString();
              }
              if (doc['createBy'] == createById ||
                  (groupMemberList != null &&
                      groupMemberList.contains(createById))) {
                documentsTemp.add(doc); //return selected group details list
              }
            }
            if (documentsTemp.length <= 0) {
              return null;
            } else {
              return documentsTemp; //return selected group details list
            }
          } else {
            documentsTemp.addAll(docs);
            if (documentsTemp.length <= 0) {
              return null;
            } else {
              return documentsTemp;
            }
            //Return all Group details list
          }
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      print(e);
    }
  }

  //Get fire-base users list from fire-base
  Future<dynamic> getUsersListFireBase() async {
    try {
      final QuerySnapshot result =
          await FirebaseFirestore.instance.collection('users').get();
      //.getDocuments();
      final List<DocumentSnapshot> documentsUser = result.docs;
      if (documentsUser.length > 0) {
        return documentsUser;
      } else {
        return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  //Get firebse user details  from fire-base
  Future<dynamic> getUserDetailsFireBase(
      {Key key, @required String uId}) async {
    try {
      if (uId != null) {
        final QuerySnapshot result = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: uId)
            .get();
        // .getDocuments();
        final List<DocumentSnapshot> documentsUser = result.docs;
        if (documentsUser.length > 0) {
          DocumentSnapshot mDocumentSnapshotUser = documentsUser[0];
          if (mDocumentSnapshotUser != null) {
            return mDocumentSnapshotUser;
          } else {
            return null;
          }
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  //Get firebse user details  from fire-base
  Future<dynamic> getGroupDetailsFireBase(
      {Key key, @required String uId}) async {
    try {
      if (uId != null) {
        final QuerySnapshot result = await FirebaseFirestore.instance
            .collection('user_groups')
            .where('gId', isEqualTo: uId)
            .get();
        // .getDocuments();
        final List<DocumentSnapshot> documentsUser = result.docs;
        if (documentsUser.length > 0) {
          DocumentSnapshot mDocumentSnapshotUser = documentsUser[0];
          if (mDocumentSnapshotUser != null) {
            return mDocumentSnapshotUser;
          } else {
            return null;
          }
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  //Get group count on fire-base
  Future<dynamic> getGroupCountFireBase({Key key, String uId}) async {
    try {
      if (uId != null) {
        String createById = uId;
        final QuerySnapshot result = await FirebaseFirestore.instance
            .collection('user_groups')
            .where('isDeletes', isEqualTo: false)
            .get();
        // .getDocuments();
        final List<DocumentSnapshot> docs = result.docs;
        if (docs.length != 0) {
          List<DocumentSnapshot> documentsTemp = new List();
          for (var doc in docs) {
            if (doc != null) {
              String groupMemberList;
              if (doc['usersDetails'] != null && !doc['isDeletes']) {
                groupMemberList = doc['usersDetails'].toString();
              }
              if (doc['createBy'] == createById ||
                  (groupMemberList != null &&
                      groupMemberList.contains(createById))) {
                documentsTemp.add(doc);
              }
            }
          }
          return documentsTemp;
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      print(e);
    }
  }

  //Edit/Updated group details on fire-base
  Future<dynamic> updatedChatGroupFireBase({Key key, chatGroup, UsersDetails user}) async {
    //Check group id is created or not
    try {
      if (chatGroup != null && chatGroup.gId != null) {
        String groupId = chatGroup.gId;
        await FirebaseFirestore.instance
            .collection("user_groups")
            .doc(groupId)
            .update({
          'name': chatGroup.name,
          'subHeading': chatGroup.subHeading,
          'description': chatGroup.description,
          'image': chatGroup.image != null ? chatGroup.image : "",
          'groupType': chatGroup.groupType,
        });
        Fluttertoast.showToast(msg: 'Updated successfully');
        return true;
      } else {
        return false;
      }
    } on Exception catch (e) {
      // TODO
      print("firebase error $e");
      Fluttertoast.showToast(msg: 'Update failed!');
      return false;
    }
  }

  //inbox creation and entry
  Future<dynamic> inboxNewEntryFireBase(
      {Key key,
      String selfUid,
      String uId,
      chatGroup,
      UserInfo user,
      @required bool isFromGroup}) async {
    if (isFromGroup == null) {
      isFromGroup = false;
    }
    try {
      if (uId != null) {
        // Check is already sign up
        /*var documentTemp =  await FirebaseFirestore.instance
            .collection('users_inbox')
            .doc(selfUid)
            .collection('inbox_user').limit(1).getDocuments();*/
        //.get();

        var documentTemp = await FirebaseFirestore.instance
            .collection('users_inbox')
            .doc(selfUid)
            .collection('inbox_user')
            .doc(uId)
            .get();

        String imageUrl = "";
        String name = "";
        int groupType = 0;

        if (chatGroup != null) {
          name = chatGroup.name != null ? chatGroup.name : "";
          imageUrl = chatGroup.image != null ? chatGroup.image : "";
          groupType = chatGroup.groupType != null ? chatGroup.groupType : 0;
        } else if (user != null) {
          // name = user.firstName != null ? user.firstName : "";
          name = user.displayName != null ? user.displayName : "";
          imageUrl = user.photoURL != null ? user.photoURL : "";
        }
        //Update if already exist
        if (documentTemp != null) {
          if (documentTemp != null && documentTemp.data() == null) {
            if (isFromGroup) {
              try {
                String currentLoggedInChatId =
                    await sharedPreferencesFile.readStr("chatUid");

                await FirebaseFirestore.instance
                    .collection('users_inbox')
                    .doc(selfUid)
                    .collection('inbox_user')
                    .doc(uId)
                    .set({
                  "isGroup": isFromGroup,
                  "isDeletes": false,
                  "isJoin": (groupType == 1)
                      ? (currentLoggedInChatId != null &&
                              currentLoggedInChatId == selfUid)
                          ? true
                          : false
                      : true,
                  "isBlock": false,
                  'isReded': true,
                  'last_message': "Welcome in group",
                  'image': imageUrl,
                  "id": uId,
                  'name': name,
                  'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
                });
              } catch (e) {
                // TODO
                print("firebase error $e");
              }
            } else if (!isFromGroup) {
              //Update data to server if new user
              FirebaseFirestore.instance
                  .collection('users_inbox')
                  .doc(selfUid)
                  .collection('inbox_user')
                  .doc(uId)
                  .set({
                "isGroup": isFromGroup,
                "isDeletes": false,
                "isJoin": true,
                "isBlock": false,
                'isReded': true,
                'last_message': "",
                'image': imageUrl,
                "id": uId,
                'name': name,
                'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
              });
            }
          }
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  //Inbox update at new message and reade status
  Future<dynamic> inboxUpdateNewMessageStatusFireBase(
      {Key key,
      String selfUid,
      String chatId,
      String message,
      bool isGroup,
      receiverId}) async {
    if (isGroup == null) {
      isGroup = false;
    }
    try {
      //Group chat
      if (isGroup) {
        try {
          //Update in self
          await FirebaseFirestore.instance
              .collection('users_inbox')
              .doc(selfUid)
              .collection('inbox_user')
              .doc(chatId)
              .update({
            'isReded': true,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'last_message': message
          });
        } catch (e) {
          print(e);
        }
        try {
          for (int i = 0; i < receiverId.length; i++)
            FirebaseFirestore.instance
                .collection('users_inbox')
                .doc(receiverId[i])
                .collection('inbox_user')
                .doc(chatId)
                .update({
              'isReded': false,
              'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
              'last_message': message
            });
        } catch (e) {
          print(e);
        }
      }
      //One to one chat
      else {
        try {
          //Update in self
          await FirebaseFirestore.instance
              .collection('users_inbox')
              .doc(selfUid)
              .collection('inbox_user')
              .doc(receiverId[0])
              .update({
            'isReded': true,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'last_message': message
          });
        } catch (e) {
          print(e);
        }
        try {
          await FirebaseFirestore.instance
              .collection('users_inbox')
              .doc(receiverId[0])
              .collection('inbox_user')
              .doc(selfUid)
              .update({
            'isReded': false,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'last_message': message
          });
        } catch (e) {
          print(e);
        }
      }

      return true;
    } on Exception catch (e) {
      // TODO
      print("firebase error $e");
      return false;
    }
  }

  //Inbox update
  Future<dynamic> inboxUpdateGroupJoinStatusFireBase(
      {Key key,
      String selfUid,
      String uId,
      ChatGroups chatGroup,
      User user,
      bool isJoinGroup,
      bool isDeleted,
      bool isBlocked,
      bool isFromGroup}) async {
    try {
      var documentTemp = await FirebaseFirestore.instance
          .collection('users_inbox')
          .doc(selfUid)
          .collection('inbox_user')
          .doc(uId)
          .get();
      //Rejoin group
      if (documentTemp != null && documentTemp.data() != null) {
        var data = documentTemp.data();
        data['timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();
        if (isDeleted != null) {
          data['isDeletes'] = isDeleted;
        }
        if (isJoinGroup != null) {
          data['isJoin'] = isJoinGroup;
        }
        if (isBlocked != null) {
          data['isBlock'] = isBlocked;
        }
        FirebaseFirestore.instance
            .collection('users_inbox')
            .doc(selfUid)
            .collection('inbox_user')
            .doc(uId)
            .update(data);
        return true;
      }
      //Add new id
      else {
        try {
          //Add group in inbox
          await inboxNewEntryFireBase(
              selfUid: selfUid,
              uId: uId,
              chatGroup: chatGroup,
              isFromGroup: true);
        } catch (e) {
          // TODO
          print("firebase error $e");
          return false;
        }
        return true;
      }
    } on Exception catch (e) {
      // TODO
      print("firebase error $e");
      return false;
    }
  }

  //Inbox update in case of delete group or left group
  Future<dynamic> inboxUpdateGroupDeleteStatusFireBase(
      {Key key, String selfUid, String chatId, bool deleteStatus}) async {
    try {
      var documentTemp = await FirebaseFirestore.instance
          .collection('users_inbox')
          .doc(selfUid)
          .collection('inbox_user')
          .doc(chatId)
          .get();
      //Rejoin group
      if (documentTemp != null && documentTemp.data() != null) {
        var data = documentTemp.data();
        data['timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();
        data['isDeletes'] = false;
        FirebaseFirestore.instance
            .collection('users_inbox')
            .doc(selfUid)
            .collection('inbox_user')
            .doc(chatId)
            .update(data);
        return true;
      }
      //Add new id
      else {
        return false;
      }
    } on Exception catch (e) {
      // TODO
      print("firebase error $e");
      return false;
    }
  }

  //Send Message group
  Future<dynamic> sentFCMNotificationFireBase(
      {Key key,
      receiverId,
      String senderName,
      String uId,
      String content,
      String notificationSentApi,
      bool isFromGroup,
      bool isFirstTime}) async {
    try {
      //Add user in inbox
      if (!isFromGroup) {
        String uName = await sharedPreferencesFile.readStr('user_name');
        String imageUser = await sharedPreferencesFile.readStr('imageUrl');
        UserInfo selfUserDetails = new UserInfo({"displayName": uName, "photoURL": imageUser});
        UserInfo receiverUserDetails =
            new UserInfo({"displayName": uName, "photoURL": imageUser});
        try {
          // Add inbox in self chat
          await inboxNewEntryFireBase(
              selfUid: uId,
              uId: receiverId[0],
              user: receiverUserDetails,
              isFromGroup: false);
        } catch (e) {
          // TODO
          print("firebase error $e");
        }
        try {
          // Add inbox in receiver
          await inboxNewEntryFireBase(
              selfUid: receiverId[0],
              uId: uId,
              user: selfUserDetails,
              isFromGroup: false);
        } catch (e) {
          // TODO
          print("firebase error $e");
        }
      }

      //Sent notification
      sentFCMNotificationFireBaseByApi(
          receiverId: receiverId,
          senderName: senderName,
          content: content,
          isFromGroup: false,
          isFirstTime: isFirstTime,
          uId: uId,
          notificationSentApi: notificationSentApi);
      try {
        String selfUid = await sharedPreferencesFile.readStr('chatUid');
        await inboxUpdateNewMessageStatusFireBase(
            selfUid: selfUid,
            chatId: uId,
            message: content,
            isGroup: isFromGroup,
            receiverId: receiverId);
      } catch (e) {
        print(e);
      }
    } catch (e) {
      print(e);
      return "";
    }
    return Future.value("Done");
  }

  //Send Message group
  Future<dynamic> sentFCMNotificationFireBaseByApi(
      {Key key,
      receiverId,
      String senderName,
      String uId,
      String content,
      String notificationSentApi,
      bool isFromGroup,
      bool isForGroupInvite,
      bool isFirstTime}) async {
    try {
      //Normal message all time not first time
      int notificationFor = notificationOneToOneSecondC;
      if (isFromGroup != null && isFromGroup) {
        notificationFor = notificationGroupSecondC;
      }
      //If start chat first time for one to one or group
      if (isFirstTime) {
        notificationFor = notificationOneToOneC;
        if (isFromGroup != null && isFromGroup) {
          notificationFor = notificationGroupC;
        }
      }
      if (isForGroupInvite != null && isForGroupInvite) {
        notificationFor = notificationGroupInviteC;
      }
      Map data = {
        "send_email": isFirstTime,
        "send_fcm": true,
        "store_notification": true,
        "receiver_uids": receiverId,
        "message": content,
        "type": notificationFor,
        "uid": uId //Sender Id
      };
      //Add chat group name
      if (notificationFor == notificationGroupC)
        data["group_name"] = senderName != null ? senderName : "";

      //encode Map to JSON
      var requestBody = json.encode(data);
      sharedPreferencesFile.readStr(accessToken).then((value) {
        String authorization = value;
        String notificationUrl = ConstantC.notificationFullUrl;
        if (authorization != null && notificationUrl != null) {
          try {
            new ApiRequest()
                .apiRequestPostSendFCMNotificationOurServer(
                    url: notificationUrl,
                    bodyData: requestBody,
                    isLoader: false,
                    authorization: authorization)
                .then((response) {
              print("$response");
            });
          } catch (e) {
            print(e);
          }
        }
      });
    } catch (e) {
      print(e);
      return "";
    }
    return Future.value("Done");
  }

  //Join group
  Future<dynamic> joinChatGroupFireBase({Key key, groupId, UsersDetails user}) async {
    //Check group id is created or not
    if (groupId != null) {
      try {
        var documentDetails = await FirebaseFirestore.instance
            .collection("user_groups")
            .doc(groupId['gId'])
            .get();
        //Check user already added in group
        //Yes exist
        if (documentDetails != null && documentDetails.data() != null) {
          // Map<String, String> inboxMap = new Map();
          List listData = documentDetails.data()['usersDetails'];
          List listDataNew = new List();
          bool isAdded = false;
          for (var rowData in listData) {
            if (rowData != null && rowData['id'] == user.id) {
              try {
                rowData['isRequestNotAccepted'] = false;
              } catch (e) {
                print(e);
              }
              isAdded = true;
              listDataNew.add(rowData);
              print("firebase error $rowData");
            } else {
              listDataNew.add(rowData);
              print("firebase error $rowData");
            }
          }
          //if user not joiend group
          if (!isAdded && user.id != null) {
            var rowDataTemp = {
              "name": "",
              "imageUrl": null,
              "pushToken": null,
              "id": user.id,
              "isRequestNotAccepted": false
            };
            listDataNew.add(rowDataTemp);
            print("firebase error $rowDataTemp");
            try {
              await FirebaseFirestore.instance
                  .collection("user_groups")
                  .doc(groupId['gId'])
                  .update({"usersDetails": FieldValue.arrayUnion(listDataNew)});
            } catch (e) {
              print(e);
            }
          } else {
            try {
              await FirebaseFirestore.instance
                  .collection("user_groups")
                  .doc(groupId['gId'])
                  .update({"usersDetails": listDataNew});
            } catch (e) {
              print(e);
            }
          }
          print("firebase error $documentDetails");
        }
        //Not added and add new user when it join
        else {
          await FirebaseFirestore.instance
              .collection("user_groups")
              .doc(groupId['gId'])
              .update({
            "usersDetails": FieldValue.arrayUnion([
              {
                "name": user.name != null ? user.name : "",
                "id": user.id,
                "imageUrl": user.imageUrl,
                "pushToken": user.pushToken,
                "isRequestNotAccepted": false,
              }
            ])
          });
        }

        /*await FirebaseFirestore.instance
           .collection("user_groups")
           .doc(groupId['gId'])
           .update({
         "usersDetails": FieldValue.arrayUnion([
           {
             "name": user.firstName != null ? user.firstName : "",
             "id": user.documentID,
             "imageUrl": user.imageUrl,
             "pushToken": user.fcmToken,
             "isRequestNotAccepted": false,
           }
         ])
       });*/

        try {
          //Update group in in box
          var uId = groupId['gId'];
          String selfUid = user.id;
          ChatGroups mChatGroups =
              new ChatGroups(name: groupId['name'], image: groupId['name']);
          await inboxUpdateGroupJoinStatusFireBase(
              selfUid: selfUid,
              uId: uId,
              chatGroup: mChatGroups,
              isJoinGroup: true,
              isFromGroup: true);
        } catch (e) {
          // TODO
          print("firebase error $e");
        }
        return true;
      } on Exception catch (e) {
        // TODO
        print("firebase error $e");
        return false;
      }
    } else {
      return false;
    }
  }

  //left group
  Future<dynamic> leftChatGroupFireBase({Key key, String groupId, user}) async {
    //Check group id is created or not
    if (groupId != null) {
      try {
        try {
          //Left group
          var chatId = groupId;
          String selfUid = user.documentID;
          await inboxUpdateGroupJoinStatusFireBase(
              selfUid: selfUid,
              uId: chatId,
              isJoinGroup: false,
              isFromGroup: true);
        } catch (e) {
          // TODO
          print("firebase error $e");
        }
        final QuerySnapshot result = await FirebaseFirestore.instance
            .collection('user_groups')
            .where('gId', isEqualTo: groupId)
            .get();
        // .getDocuments();
        final List<DocumentSnapshot> docs = result.docs;
        if (docs.length > 0) {
          // Map<String, String> inboxMap = new Map();
          List listData = docs[0]['usersDetails'];
          List listDataNew = new List();
          for (var rowData in listData) {
            if (rowData != null && rowData['id'] == user.documentID) {
              print("firebase error $rowData");
            } else {
              listDataNew.add(rowData);
              print("firebase error $rowData");
            }
          }
          await FirebaseFirestore.instance
              .collection("user_groups")
              .doc(groupId)
              .update({"usersDetails": listDataNew});
          print("firebase error $docs");
        }
        return "";
      } on Exception catch (e) {
        // TODO
        print("firebase error $e");
        return "";
      }
    } else {
      return "";
    }
  }

  //left group
  Future<dynamic> setBaseUrl({Key key, String url}) async {
    //Check group id is created or not
    ConstantC.baseUrl = url;
    return true;
  }

  Future<dynamic> setNotificationUrl({Key key, String url}) async {
    //Check group id is created or not
    ConstantC.notificationFullUrl = url;
    return true;
  }
}
