import 'package:cloud_firestore/cloud_firestore.dart';

class ContactModel {
  String? uid;
  Timestamp? addedOn;
  int? lastMessageTime;
  int? unReadFromUser;
  String? chatType; // 'post' or 'service'

  ContactModel(
      {this.uid,
      this.addedOn,
      this.lastMessageTime,
      this.unReadFromUser,
      this.chatType});

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      uid: json['uid'],
      lastMessageTime: json['lastMessageTime'],
      unReadFromUser: json['unReadFromUser'],
      addedOn: json['addedOn'],
      chatType: json['chatType'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (uid != null) data['uid'] = uid;
    if (addedOn != null) data['addedOn'] = addedOn;
    if (unReadFromUser != null) data['unReadFromUser'] = unReadFromUser;
    if (lastMessageTime != null) data['lastMessageTime'] = lastMessageTime;
    if (chatType != null) data['chatType'] = chatType;

    return data;
  }
}
