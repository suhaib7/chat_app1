import 'package:cloud_firestore/cloud_firestore.dart';

class PhotoMessage {
  PhotoMessage({
    required this.timestamp,
    required this.photoMessage,
    required this.receiverID,
    required this.senderID,
    required this.senderName,
  });

  final String senderID;
  final String senderName;
  final String receiverID;
  final String photoMessage;
  final Timestamp timestamp;

  Map<String ,dynamic> toMap(){
    return{
      'senderID': senderID,
      'senderName': senderName,
      'receiverID': receiverID,
      'photoMessage': photoMessage,
      'timestamp': timestamp,
    };
  }
}
