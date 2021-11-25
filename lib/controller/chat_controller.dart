import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:hibaike_app/model/chat_data.dart';

class ChatController extends GetxController {
  RxList<ChatDataState> chatList = <ChatDataState>[].obs;

  void addAllMessages(List<QueryDocumentSnapshot> docs) {
    // ChatData firstMessage = ChatData.fromJson(docs[0].data());
    // if(chatList[0].chatData.timestamp == firstMessage.timestamp) {
    //   print('chat list is not changed');
    //   return;
    // }

    docs.forEach((document) {
      ChatData chatData = ChatData.fromJson(document.data());
      int result = isExistMessage(document.id);
      if(result < 0) {
        ChatDataState chatDataState = ChatDataState(
            chatData: chatData, id: document.id, sentState: 'RECEIVED');
        //chatList.add(chatDataState);
        putInOrder(chatDataState);
      }
      else {
        chatList[result].chatData = chatData;
        if(chatList[result].sentState == 'SENT')
          chatList[result].sentState = 'RECEIVED';
      }
    });
  }

  int isExistMessage(String id) {
    for(var i = 0 ; i < chatList.length ; i++) {
      if(chatList[i].id == id) {
        return i;
      }
    }
    return -1;
  }

  void makePreviewMessage(String messageId, String idFrom, String idTo, String now, String content,
      int type, String state) {
    ChatData chatData = ChatData(
        idFrom: idFrom,
        idTo: idTo,
        timestamp: now,
        content: content,
        type: type,
        state: state);

    int result = isExistMessage(messageId);
    if(result >= 0) {
      chatList[result].chatData = chatData;
      if(chatList[result].sentState == 'PREVIEW')
          chatList[result].sentState = 'SENT';

      return;
    }

    ChatDataState chatDataState = ChatDataState(chatData: chatData, id: messageId, sentState: 'SENT');
    //chatList.insert(0, chatDataState);
    putInOrder(chatDataState);
  }

  void makePreviewPhotoMessage(String idFrom, String idTo, String now,
      String messageId, int totalBytes, int transferredBytes, Uint8List previewImage) {
    ChatData chatData = ChatData(
        idFrom: idFrom, idTo: idTo, timestamp: now, type: 1, state: 'unread');
    ChatDataState chatDataState = ChatDataState(
        chatData: chatData,
        id: messageId,
        sentState: 'PREVIEW',
        totalBytes: totalBytes,
        transferredBytes: transferredBytes,
        previewImage: previewImage);
    putInOrder(chatDataState);
  }

  void putInOrder(ChatDataState chatData) {
    if(chatList.length == 0) {
      print('put first message');
      chatList.add(chatData);
      return;
    }
    else {
      for(var index = 0 ; index < chatList.length ; index++) {
        if(int.parse(chatData.id) > int.parse(chatList[index].id)) {
          chatList.insert(index, chatData);
          return;
        }
      }
      chatList.add(chatData);
    }
  }
}