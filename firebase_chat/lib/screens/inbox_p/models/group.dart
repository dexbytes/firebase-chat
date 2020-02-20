class ChatGroups {
  String createBy;
  String name;
  String subHeading;
  String gId;
  String timestamp;
  String description;
  int totalUser;
  int groupType;
  String image;
  List<UsersDetails> usersDetails;
  bool isDeletes;

  ChatGroups(
      {this.createBy,
        this.name,
        this.subHeading,
        this.gId,
        this.timestamp,
        this.description,
        this.totalUser,
        this.image,
        this.usersDetails,
        this.isDeletes,this.groupType});

  ChatGroups.fromJson(Map<String, dynamic> json) {
    createBy = json['createBy'];
    name = json['name'];
    subHeading = json['subHeading'];
    gId = json['gId'];
    timestamp = json['timestamp'];
    description = json['description'];
    totalUser = json['totalUser'];
    groupType = json.containsKey('groupType')?json['groupType']:0;
    image = json['image'];
    if (json['usersDetails'] != null) {
      usersDetails = new List<UsersDetails>();
      json['usersDetails'].forEach((v) {
        usersDetails.add(new UsersDetails.fromJson(v));
      });
    }
    isDeletes = json['isDeletes'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['createBy'] = this.createBy;
    data['name'] = this.name;
    data['subHeading'] = this.subHeading;
    data['gId'] = this.gId;
    data['timestamp'] = this.timestamp;
    data['description'] = this.description;
    data['totalUser'] = this.totalUser;
    data['groupType'] = this.groupType;
    data['image'] = this.image;
    if (this.usersDetails != null) {
      data['usersDetails'] = this.usersDetails.map((v) => v.toJson()).toList();
    }
    data['isDeletes'] = this.isDeletes;
    return data;
  }
}

class UsersDetails {
  String name;
  String id;
  String imageUrl;
  String pushToken;

  UsersDetails({this.name, this.id, this.imageUrl, this.pushToken});

  UsersDetails.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    id = json['id'];
    imageUrl = json['imageUrl'];
    pushToken = json['pushToken'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['id'] = this.id;
    data['imageUrl'] = this.imageUrl;
    data['pushToken'] = this.pushToken;
    return data;
  }
}