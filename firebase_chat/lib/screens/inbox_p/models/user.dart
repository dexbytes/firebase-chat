class User {
  User({
    this.documentID,
    this.firstName,
    this.lastName,
    this.email,
    this.displayName,
    this.providerId,
    this.phoneNumber,
    this.imageUrl,
    this.fcmToken,
    this.rating,
    this.numOfReviews,
    this.wishlistProducts,
    this.numOfUnreadMessages,
    this.reviewedProducts,
  });

  final String documentID;
  String firstName;
  String lastName;
  String email;
  String providerId;
  String displayName;
  String phoneNumber;
  String imageUrl;
  String fcmToken;
  double rating;
  int numOfReviews;
  List<String> wishlistProducts = new List<String>();
  int numOfUnreadMessages = 0;
  List<String> reviewedProducts = new List<String>();

  factory User.fromMap(Map<String, dynamic> data) {
    if (data == null) {
      return null;
    }

    final String documentID = data['documentID'];
    final String firstName = data['firstName'];
    final String lastName = data['lastName'];
    final String email = data['email'];
    final String providerId = data['providerId'];
    final String displayName = data['displayName'];
    final String phoneNumber = data['phoneNumber'];
    final String imageUrl = data['imageUrl'];
    final String fcmToken = data['fcmToken'];
    final double rating = double.tryParse(data['rating'].toString());
    final int numOfReviews = data['numOfReviews'];
    final List<String> wishlistProducts = List.from(data['wishlistProducts']);
    final int numOfUnreadMessages = data['numOfUnreadMessages'];
    final List<String> reviewedProducts = List.from(data['reviewedProducts']);

    return User(
      documentID: documentID,
      firstName: firstName,
      lastName: lastName,
      email: email,
      providerId: providerId,
      displayName: displayName,
      phoneNumber: phoneNumber,
      imageUrl: imageUrl,
      fcmToken: fcmToken,
      rating: rating,
      numOfReviews: numOfReviews,
      wishlistProducts: wishlistProducts,
      numOfUnreadMessages: numOfUnreadMessages,
      reviewedProducts: reviewedProducts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'imageUrl': imageUrl,
      'fcmToken': fcmToken,
      'rating': rating,
      'numOfReviews': numOfReviews,
      'wishlistProducts': wishlistProducts,
      'reviewedProducts': reviewedProducts,
    };
  }
}
