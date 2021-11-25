// To parse this JSON data, do
//
//     final chatData = chatDataFromJson(jsonString);

import 'dart:convert';

import 'dart:typed_data';

ChatData chatDataFromJson(String str) => ChatData.fromJson(json.decode(str));

String chatDataToJson(ChatData data) => json.encode(data.toJson());

class ChatData {
  ChatData({
    this.idFrom,
    this.idTo,
    this.timestamp,
    this.type,
    this.content,
    this.state,
  });

  String idFrom;
  String idTo;
  String timestamp;
  int type;
  String content;
  String state;

  factory ChatData.fromJson(Map<String, dynamic> json) => ChatData(
    idFrom: json["idFrom"],
    idTo: json["idTo"],
    timestamp: json["timestamp"],
    type: json["type"],
    content: json["content"],
    state: json["state"],
  );

  Map<String, dynamic> toJson() => {
    "idFrom": idFrom,
    "idTo": idTo,
    "timestamp": timestamp,
    "type": type,
    "content": content,
    "state": state,
  };
}

class ChatDataState {
  ChatData chatData;
  String id;
  String sentState;
  int totalBytes;
  int transferredBytes;
  Uint8List previewImage;

  ChatDataState({
      this.chatData,
      this.id,
      this.sentState,
      this.totalBytes,
      this.transferredBytes,
      this.previewImage
  });
}