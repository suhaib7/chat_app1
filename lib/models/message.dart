import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  Message({
    required this.timestamp,
    required this.receiverId,
    this.message,
    this.photoMessage,
    required this.senderId,
    required this.senderName,
  });

  final String senderId;
  final String senderName;
  final String receiverId;
  final String? message;
  final String? photoMessage;
  final Timestamp timestamp;

  Map<String, dynamic> toMap() {
    return {
      'senderID': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'photoMessage': photoMessage,
    };
  }
}
