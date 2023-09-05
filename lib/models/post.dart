class Post {
  Post({
    required this.title,
    required this.body,
    required this.receiverID,
  });

  final String receiverID;
  final String title;
  final String body;

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      title: json['receiverID'].toString(),
      body: json['title'].toString(),
      receiverID: json['body'].toString(),
    );
  }
}
