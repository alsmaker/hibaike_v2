import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hibaike_app/component/data_time_format.dart';
import 'package:hibaike_app/component/full_photo.dart';
import 'package:hibaike_app/controller/chat_controller.dart';
import 'package:hibaike_app/controller/multi_image_controller.dart';
import 'package:hibaike_app/controller/sign_controller.dart';
import 'package:hibaike_app/model/bike_data.dart';
import 'package:hibaike_app/model/chat_data.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:percent_indicator/circular_percent_indicator.dart';

class Chat extends StatefulWidget {
  Chat({Key key}) : super(key: key);

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  //String bikeDataId = Get.arguments;
  List<String> arguments = Get.arguments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(arguments[2], style: TextStyle(color: Colors.white),),
        iconTheme: IconThemeData(
          color: Colors.white, //change your color here
        ),
        //centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        backwardsCompatibility: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:Brightness.light,
          statusBarBrightness: Brightness.dark
        ),
      ),
      body: ChatScreen(
        arguments: arguments,
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final List<String> arguments;

  //ChatScreen({Key key, @required this.peerId, @required this.peerAvatar}) : super(key: key);
  ChatScreen({Key key, @required this.arguments}) : super(key: key);

  @override
  State createState() => ChatScreenState(arguments: arguments);
}

class ChatScreenState extends State<ChatScreen> {
  //ChatScreenState({Key key, @required this.peerId, @required this.peerAvatar});
  ChatScreenState({Key key, @required this.arguments});

  List<String> arguments;
  String bikeDataId;

  final ChatController chatController = Get.put(ChatController());

  String peerId;
  String peerAvatar;
  String id;

  List<QueryDocumentSnapshot> listMessage = new List.from([]);
  int _limit = 20;
  int _limitIncrement = 20;
  String groupChatId;
  //SharedPreferences prefs;
  SignController signCtrl = Get.find();

  File imageFile;
  bool isLoading;
  //bool isShowSticker;
  String imageUrl;
  bool isChatExist = false;
  final dateTimeFormatter = DateTimeFormatter();
  bool hasMore = true;

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  double _inputHeight = 50;

  final multiImageController = Get.put(MultiImageController());

  _scrollListener() {
    if (listScrollController.offset >=
        listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      print('chat data reload : offset = ${listScrollController.offset}, maxScroll = ${listScrollController.position.maxScrollExtent}');
      if(hasMore == true) {
        setState(() {
          _limit += _limitIncrement;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    focusNode.addListener(onFocusChange);
    listScrollController.addListener(_scrollListener);

    groupChatId = '';
    id = signCtrl.currentUser.value.uid;
    peerId = arguments[1];

    bikeDataId = arguments[0];

    isLoading = false;
    //isShowSticker = false;
    imageUrl = '';

    initChat();
    textEditingController.addListener(_checkInputHeight);
  }

  void _checkInputHeight() async {
    int count = textEditingController.text.split('\n').length;

    if (count == 0 && _inputHeight == 50.0) {
      return;
    }
    if (count <= 5) {  // use a maximum height of 6 rows
      // height values can be adapted based on the font size
      var newHeight = count == 0 ? 50.0 : 28.0 + (count * 18.0);
      setState(() {
        _inputHeight = newHeight;
      });
    }
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      // setState(() {
      //   isShowSticker = false;
      // });
    }
  }

  initChat() async {
    DocumentSnapshot peerSnapshot =
    await FirebaseFirestore.instance.collection('users').doc(peerId).get();

    if((peerSnapshot.data()['profile_image_url'] == null) || (peerSnapshot.data()['profile_image_url'] ==0))
      peerAvatar = 'https://i.stack.imgur.com/l60Hf.png';
    else
      peerAvatar = (peerSnapshot.data()['profile_image_url']);

    if (id.hashCode <= peerId.hashCode) {
      groupChatId = '$id-$peerId-$bikeDataId';
    } else {
      groupChatId = '$peerId-$id-$bikeDataId';
    }

    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(groupChatId)
        .get();
    if (snapshot.data() != null) if (snapshot.data().length > 0)
      isChatExist = true;

    setState(() {});
  }

  Future getImage() async {
    // ImagePicker imagePicker = ImagePicker();
    // PickedFile pickedFile;
    //
    // pickedFile = await imagePicker.getImage(source: ImageSource.gallery);
    // imageFile = File(pickedFile.path);
    //
    // if (imageFile != null) {
    //   setState(() {
    //     isLoading = true;
    //   });
    //    uploadFile();
    // }
    int maxCount = 5;
    await multiImageController.getMultiImage(maxCount, false);

    uploadFiles();
  }

  void getSticker() {
    // Hide keyboard when sticker appear
    focusNode.unfocus();
    // setState(() {
    //   isShowSticker = !isShowSticker;
    // });
  }

  Future uploadFile() async {
    //String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();

    var image = img.decodeImage(File(imageFile.path).readAsBytesSync());
    var width = image.width;
    var height = image.height;
    int baseSize = 900;
    var resizeImage;

    if (width < baseSize || height < baseSize) {
      print('small size image - no convert');
    }
    else if (width < height) {
      resizeImage = img.copyResize(image, height: baseSize);
    } else if (height < width) {
      resizeImage = img.copyResize(image, width: baseSize);
    } else {
      resizeImage = img.copyResize(image, width: baseSize, height: baseSize);
    }

    Uint8List resultImgData = img.encodeJpg(resizeImage);

    firebase_storage.Reference reference =
    firebase_storage.FirebaseStorage.instance.ref().child('chats').child(groupChatId).child(fileName);
    firebase_storage.UploadTask uploadTask = reference.putData(resultImgData);

    uploadTask.whenComplete(() async {
      try {
        reference.getDownloadURL().then((downloadUrl) {
          imageUrl = downloadUrl;
          setState(() {
            isLoading = false;
            //onSendMessage(imageUrl, 1);
          });
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: 'This file is not an image');
      }
    });
  }

  Future uploadFiles() async {
    for(var i = 0 ; i < multiImageController.images.length ; i++) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      await multiImageController.loadImageData(i);

      var image = img.decodeImage(multiImageController.images[i]);
      var width = image.width;
      var height = image.height;
      int baseSize = 900;
      var resizeImage;

      if (width < baseSize || height < baseSize) {
        resizeImage = image;
        print('small size image - no convert');
      }
      else if (width < height) {
        resizeImage = img.copyResize(image, height: baseSize);
      } else if (height < width) {
        resizeImage = img.copyResize(image, width: baseSize);
      } else {
        resizeImage = img.copyResize(image, width: baseSize, height: baseSize);
      }

      Uint8List resultImgData = img.encodeJpg(resizeImage);

      firebase_storage.Reference reference =
      firebase_storage.FirebaseStorage.instance.ref().child('chats').child(groupChatId).child(fileName);

      // put data to storage
      firebase_storage.UploadTask uploadTask = reference.putData(resultImgData);

      DateTime now = DateTime.now();
      // make preview message
      chatController.makePreviewPhotoMessage(
        id, peerId, now.toString(),
        now.millisecondsSinceEpoch.toString(),
        uploadTask.snapshot.totalBytes,
        0, // transferred bytes
        resultImgData);

      uploadTask.snapshotEvents.listen((event) {
          var index = chatController.isExistMessage(now.millisecondsSinceEpoch.toString());
          setState(() {
            chatController.chatList[index].totalBytes = event.totalBytes;
            chatController.chatList[index].transferredBytes = event.bytesTransferred;
          });
      });

      uploadTask.whenComplete(() async {
        try {
          reference.getDownloadURL().then((downloadUrl) {
            imageUrl = downloadUrl;
            setState(() {
              isLoading = false;
              onSendMessage(imageUrl, 1, now);
            });
          });
        } catch (e) {
          setState(() {
            isLoading = false;
          });
          Fluttertoast.showToast(msg: 'This file is not an image');
        }
      });
    }
  }

  void onSendMessage(String content, int type, DateTime now) {
    //String now = DateTime.now().microsecondsSinceEpoch.toString();
    //DateTime now = DateTime.now();
    String nowString = now.toString();
    String nowMillisecond = now.millisecondsSinceEpoch.toString();
    // type: 0 = text, 1 = image, 2 = sticker

    if (isChatExist == false) {
      print('insert chat room data');
      var chatDocRef =
      FirebaseFirestore.instance.collection('chats').doc(groupChatId);

      FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(chatDocRef, {
          'bikeId': bikeDataId,
          'lastChatTime': nowString,
          'lastMessage': content,
          'lastMessageType' : type,
          'userPair': [id, peerId],
        });
      });
      isChatExist = true;
    }

    if (content.trim() != '') {
      textEditingController.clear();

      // var documentReference = FirebaseFirestore.instance
      //     .collection('chats')
      //     .doc(groupChatId)
      //     .collection(groupChatId)
      //     .doc(now);

      chatController.makePreviewMessage(nowMillisecond, id, peerId, nowString, content, type, 'unread');

      FirebaseFirestore.instance
          .collection('chats')
          .doc(groupChatId)
          .update({
        "lastChatTime": nowString,
        "lastMessage": content,
        "lastMessageType" : type,
      }).then((value) {
        FirebaseFirestore.instance
            .collection('chats')
            .doc(groupChatId)
            .collection(groupChatId)
            .doc(nowMillisecond)
            .set({
          'idFrom': id,
          'idTo': peerId,
          'timestamp': nowString,
          'content': content,
          'type': type,
          'state': 'unread',
        });
      });

      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(
        msg: 'Nothing to send',);
    }
  }

  //Widget myContentBox(int index, DocumentSnapshot document) {
  Widget myContentBox(int index, ChatDataState chatData) {
    if(chatData.sentState == 'PREVIEW') {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              color: Colors.grey[400].withOpacity(0.5),
              image: DecorationImage(
                image: MemoryImage(chatData.previewImage),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.dstATop),
              ),
            ),
            margin: EdgeInsets.only(
                bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
          ),

          CircularPercentIndicator(
                radius: 40,
                lineWidth: 3,
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: Colors.grey,
                progressColor: Colors.white,
                percent: chatData.transferredBytes / chatData.totalBytes,
                center: Text('${((chatData.transferredBytes / chatData.totalBytes) * 100).floor()}%',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),),
              ),

        ],
      );
    }
    // 내가 보낸 메세지일때
    //if (document.data()['idFrom'] == id) {
    else if (chatData.chatData.idFrom == id) {
      // Text
      //if (document.data()['type'] == 0) {
      if (chatData.chatData.type == 0) {
        return Container(
          child: Text(
            //document.data()['content'],
            chatData.chatData.content,
            style: TextStyle(color: Colors.white),
          ),
          padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
          //width: 200.0,
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width*0.6),
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.0),
                bottomRight: Radius.circular(12.0),
                bottomLeft: Radius.circular(12.0),
              )),
          margin: EdgeInsets.only(
              bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
        );
      }
      // image
      //else if (document.data()['type'] == 1) {
      else if (chatData.chatData.type == 1) {
        return InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        //FullPhotoInChat(currentUrl: document.data()['content'], groupChatId: groupChatId,)));
                    FullPhotoInChat(currentUrl: chatData.chatData.content, groupChatId: groupChatId,)));
          },
          child: Container(
            child: Material(
              child: CachedNetworkImage(
                placeholder: (context, url) => Container(
                  child: CircularProgressIndicator(
                    //valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                  width: 200.0,
                  height: 200.0,
                  padding: EdgeInsets.all(70.0),
                  decoration: BoxDecoration(
                    //color: greyColor2,
                    color: Colors.grey,
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.0),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Material(
                  child: Image.asset(
                    'images/img_not_available.jpeg',
                    width: 200.0,
                    height: 200.0,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(8.0),
                  ),
                  clipBehavior: Clip.hardEdge,
                ),
                //imageUrl: document.data()['content'],
                imageUrl: chatData.chatData.content,
                width: 200.0,
                height: 200.0,
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              clipBehavior: Clip.hardEdge,
            ),
            margin: EdgeInsets.only(
                bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
            decoration: BoxDecoration(color: Colors.transparent),
          ),
        );
      }
      // Sticker
      else {
        return Container(
          child: Image.asset(
            //'images/${document.data()['content']}.gif',
            'images/${chatData.chatData.content}.gif',
            width: 100.0,
            height: 100.0,
            fit: BoxFit.cover,
          ),
          margin: EdgeInsets.only(
              bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
        );
      }
    }
  }

  //Widget myTimeStamp(int index, DocumentSnapshot document) {
  Widget myTimeStamp(int index, ChatDataState chatData) {
    if(chatData.sentState == 'SENT') {
      return Container(
          height: 20,
          width: 20,
          margin: EdgeInsets.only(
              bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 5.0),
          child: CircularProgressIndicator(
            strokeWidth: 1,
              valueColor:
              AlwaysStoppedAnimation<Color>(Colors.grey)
          ));
    }
    else if(chatData.sentState == 'PREVIEW') {
      return Container();
    }
    if (isTimeDisplay(index))
      return Row(
        children: [
          chatData.chatData.state == 'unread'
              ? Container(
                  width: 8.0,
                  height: 8.0,
                  decoration: new BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  margin: EdgeInsets.only(
                      bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                      right: 5.0),
                )
              : Container(),
          Container(
            child: Text(
              //dateTimeFormatter.chatDateTime(document.data()['timestamp']),
              dateTimeFormatter.chatDateTime(chatData.chatData.timestamp),
              style: TextStyle(
                color: Colors.black54,
                fontSize: 10.0,
              ),
            ),
            //margin: EdgeInsets.only(right: 5.0, top: 5.0, bottom: 3),
            margin: EdgeInsets.only(
                bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 5.0),
          ),
        ],
      );
    else {
      if (chatData.chatData.state == 'unread') {
        return Container(
          width: 8.0,
          height: 8.0,
          decoration: new BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          margin: EdgeInsets.only(
              bottom: isLastMessageRight(index) ? 20.0 : 10.0,
              right: 5.0),
        );
      }
      else
        return Container();
    }
  }

  //Widget peerAvatarDisplay(int index, DocumentSnapshot document) {
  Widget peerAvatarDisplay(int index, ChatDataState chatData) {
    if (isAvatarDisplay(index))
      return Material(
        child: CachedNetworkImage(
          placeholder: (context, url) => Container(
            child: CircularProgressIndicator(
              strokeWidth: 1.0,
              //valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
            width: 35.0,
            height: 35.0,
            padding: EdgeInsets.all(10.0),
          ),
          imageUrl: peerAvatar,
          width: 35.0,
          height: 35.0,
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.all(
          Radius.circular(18.0),
        ),
        clipBehavior: Clip.hardEdge,
      );
    else
      return Container(width: 35.0);
  }

  //Widget peerContentBox(int index, DocumentSnapshot document) {
  Widget peerContentBox(int index, ChatDataState chatData) {
    //if (document.data()['type'] == 0) {
    if (chatData.chatData.type == 0) {
      return Container(
        child: Text(
          //document.data()['content'],
          chatData.chatData.content,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
        //width: 200.0,
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.57),
        //decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8.0)),
        decoration: BoxDecoration(
            color: Colors.red,
            //borderRadius: BorderRadius.circular(8.0)),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(12.0),
              bottomLeft: Radius.circular(12.0),
              bottomRight: Radius.circular(12.0),
            )),
        margin: EdgeInsets.only(bottom: isLastMessageLeft(index) ? 20.0 : 10.0, left: 10.0),
      );
    //} else if (document.data()['type'] == 1) {
    } else if (chatData.chatData.type == 1) {
      return InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      //FullPhotoInChat(currentUrl: document.data()['content'], groupChatId: groupChatId,)));
                  FullPhotoInChat(currentUrl: chatData.chatData.content, groupChatId: groupChatId,)));
        },
        child: Container(
          child: Material(
            child: CachedNetworkImage(
              placeholder: (context, url) => Container(
                child: CircularProgressIndicator(
                  //valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.red.withOpacity(0.8)),
                ),
                width: 200.0,
                height: 200.0,
                padding: EdgeInsets.all(70.0),
                decoration: BoxDecoration(
                  //color: greyColor2,
                  color: Colors.grey,
                  borderRadius: BorderRadius.all(
                    Radius.circular(8.0),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Material(
                child: Image.asset(
                  'images/img_not_available.jpeg',
                  width: 200.0,
                  height: 200.0,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.all(
                  Radius.circular(8.0),
                ),
                clipBehavior: Clip.hardEdge,
              ),
              // imageUrl: document.data()['content'],
              imageUrl: chatData.chatData.content,
              width: 200.0,
              height: 200.0,
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            clipBehavior: Clip.hardEdge,
          ),
          margin: EdgeInsets.only(
              bottom: isLastMessageLeft(index) ? 20.0 : 10.0,
              left: 10.0),
        ),
      );
    } else
      return Container(
        child: Image.asset(
          // 'images/${document.data()['content']}.gif',
          'images/${chatData.chatData.content}.gif',
          width: 100.0,
          height: 100.0,
          fit: BoxFit.cover,
        ),
        margin: EdgeInsets.only(
            bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
      );
  }

  Widget peerTimeStamp(int index, ChatDataState chatData) {
    if (isTimeDisplay(index)) {
      return Container(
        child: Text(
          //dateTimeFormatter.chatDateTime(document.data()['timestamp']),
          dateTimeFormatter.chatDateTime(chatData.chatData.timestamp),
          style: TextStyle(
            color: Colors.black54,
            fontSize: 10.0,
          ),
        ),
        margin: EdgeInsets.only(bottom: isLastMessageLeft(index) ? 20.0 : 10.0, left: 5.0),
      );
    } else
      return Container();
  }

  //Widget dateChangeDisplay(int index, DocumentSnapshot document) {
  Widget dateChangeDisplay(int index, ChatDataState chatData) {
    //DateTime current = DateTime.parse(listMessage[index]['timestamp']);
    DateTime current = DateTime.parse(chatController.chatList[index].chatData.timestamp);
    return Center(
      child: Container(
        child: Text(current.month.toString()+'월 '+current.day.toString() + '일', style: TextStyle(color: Colors.white),),
        decoration: BoxDecoration(color: Colors.black26,
            borderRadius: BorderRadius.all(Radius.circular(15))),
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 5),
        margin: EdgeInsets.only(top: 10, bottom: 10),
      ),
    );
  }

  //Widget buildItem(int index, DocumentSnapshot document) {
  Widget buildItem(int index, ChatDataState chatData) {
    //if (document.data()['state'] == 'unread' && document.data()['idFrom'] == peerId) {
    // if (chatData.chatData.state == 'unread' &&
    //     chatData.chatData.idFrom == peerId) {
    //   FirebaseFirestore.instance
    //       .collection('chats')
    //       .doc(groupChatId)
    //       .collection(groupChatId)
    //   //.doc(document.id)
    //       .doc(chatData.id)
    //       .update({'state': 'read'});
    // }

    FirebaseFirestore.instance
        .collection('chats')
        .doc(groupChatId)
        .collection(groupChatId)
        .where('state', isEqualTo: 'unread')
        .where('idFrom', isEqualTo: peerId)
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((document) {
        FirebaseFirestore.instance
            .collection('chats')
            .doc(groupChatId)
            .collection(groupChatId)
            .doc(document.id)
            .update({'state': 'read'});
      });
    });

    print('chat index = $index');

    if(isDateChanged(index)) {
      //if (document.data()['idFrom'] == id) {
      if (chatData.chatData.idFrom == id) {
        return Column(
          children: [
            //dateChangeDisplay(index, document),
            dateChangeDisplay(index, chatData),
            Row(
              children: <Widget>[
                //myTimeStamp(index, document),
                myTimeStamp(index, chatData),
                //myContentBox(index, document),
                myContentBox(index, chatData),
              ],
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: chatData.sentState == 'SENT'
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.end
            ),
          ],
        );
      }
      else {
        return Column(
          children: [
            //dateChangeDisplay(index, document),
            dateChangeDisplay(index, chatData),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // peerAvatarDisplay(index, document),
                    peerAvatarDisplay(index, chatData),
                    // peerContentBox(index, document),
                    peerContentBox(index, chatData),
                  ],
                ),
                // peerTimeStamp(index, document),
                peerTimeStamp(index, chatData),
              ],
            ),
          ],
        );
      }
    }
    else {
      // 내가 보낸 메세지일때
      //if (document.data()['idFrom'] == id) {
      if (chatData.chatData.idFrom == id) {
        // Right (my message)
        return Row(
          children: <Widget>[
            // myTimeStamp(index, document),
            myTimeStamp(index, chatData),
            // myContentBox(index, document),
            myContentBox(index, chatData),
          ],
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
        );
      }
      else {   // Left (peer message)
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // peerAvatarDisplay(index, document),
                peerAvatarDisplay(index, chatData),
                // peerContentBox(index, document),
                peerContentBox(index, chatData),
              ],
            ),
            // peerTimeStamp(index, document),
            peerTimeStamp(index, chatData),
          ],
        );
      }

    }
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 &&
        //listMessage != null &&
        chatController.chatList != null &&
        //listMessage[index - 1].data()['idFrom'] == id) ||
        chatController.chatList[index - 1].chatData.idFrom == id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isAvatarDisplay(int index) {
    //print('$index : ${listMessage.length} ${listMessage[index]['idFrom']}');
    print('$index : ${chatController.chatList.length} ${chatController.chatList[index].chatData.idFrom}');
    //if(index == listMessage.length-1) {
    if(index == chatController.chatList.length-1) {
      //print('display avatar 1');
      return true;
    }

    //if(listMessage[index]['idFrom'] == peerId) { // 상대방의 메세지일 경우만 avatar 표시
    if(chatController.chatList[index].chatData.idFrom == peerId) { // 상대방의 메세지일 경우만 avatar 표시
      //if(listMessage[index+1]['idFrom'] == peerId) { // 이전 메제지도 상대방의 메세지이면 avatar 표시안함
      if(chatController.chatList[index+1].chatData.idFrom == peerId) { // 이전 메제지도 상대방의 메세지이면 avatar 표시안함
        //print(listMessage[index+1]['idFrom']);
        print(chatController.chatList[index+1].chatData.idFrom);
        return false;
      }
      else {
        //print('display avatar 2');
        return true;
      }
    }
    else //
      return false;
  }

  bool isTimeDisplay(int index) {
    if(index == 0) // 가장 최근 메세지는 무조건 표시되어야 함
      return true;

    //if(listMessage[index]['idFrom'] == listMessage[index-1]['idFrom']) {
    if(chatController.chatList[index].chatData.idFrom == chatController.chatList[index-1].chatData.idFrom) {
      // DateTime current = DateTime.parse(listMessage[index]['timestamp']);
      // DateTime next = DateTime.parse(listMessage[index-1]['timestamp']);

      DateTime current = DateTime.parse(chatController.chatList[index].chatData.timestamp);
      DateTime next = DateTime.parse(chatController.chatList[index-1].chatData.timestamp);

      if((current.day==next.day) && (current.hour==next.hour) && (current.minute==next.minute))
        return false;
      else
        return true;
    }
    else
      return true;
  }

  bool isDateChanged(index) {
    //if(index == (listMessage.length-1))
    if(index == (chatController.chatList.length-1))
      if(!hasMore)
        return true;
      else
        return false;

    else {
      // DateTime current = DateTime.parse(listMessage[index]['timestamp']);
      // DateTime prev = DateTime.parse(listMessage[index+1]['timestamp']);

      DateTime current = DateTime.parse(chatController.chatList[index].chatData.timestamp);
      DateTime prev = DateTime.parse(chatController.chatList[index+1].chatData.timestamp);

      if(current.day != prev.day)
        return true;
      else
        return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
        //listMessage != null &&
        chatController.chatList != null &&
        //listMessage[index - 1].data()['idFrom'] != id) ||
        chatController.chatList[index - 1].chatData.idFrom != id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    // if (isShowSticker) {
    //   setState(() {
    //     isShowSticker = false;
    //   });
    // } else {
    //   Get.back();
    // }
    Get.back();

    return Future.value(false);
  }

  Widget buildBikeData() {
    return FutureBuilder(
      future: FirebaseFirestore.instance.collection('bikes').doc(bikeDataId).get(),
      builder: (context, snapshot) {
        if(!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        else {
          print('future builder data = ${snapshot.data}');
          BikeData bikeData = BikeData.fromJson(snapshot.data.data());
          double thumbnailSize = 45;
          final formatter = NumberFormat('#,###');
          return Container(
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                  child: Material(
                    child: CachedNetworkImage(
                      placeholder: (context, url) => Container(
                        child: CircularProgressIndicator(
                          strokeWidth: 1.0,
                          //valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                        width: thumbnailSize,
                        height: thumbnailSize,
                        padding: EdgeInsets.all(10.0),
                      ),
                      imageUrl: bikeData.imageList[0],
                      width: thumbnailSize,
                      height: thumbnailSize,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(5.0),
                    ),
                    clipBehavior: Clip.hardEdge,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(bikeData.manufacturer + ' ' +bikeData.model, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),),
                    Text(bikeData.birthYear.toString()+'년 ' + formatter.format(bikeData.mileage) +'km ' + bikeData.locationLevel2)
                  ],
                ),
              ],
            ),
          );

        }
      },
    );

  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Divider(height: 0,),
              buildBikeData(),
              Divider(height: 0,),
              // List of messages
              buildListMessage(),

              // Sticker
              //(isShowSticker ? buildSticker() : Container()),

              // Input content
              buildInput(),
            ],
          ),

          // Loading
          buildLoading()
        ],
      ),
      onWillPop: onBackPress,
    );
  }

  Widget buildSticker() {
    DateTime now = DateTime.now();
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              ElevatedButton(
                onPressed: () => onSendMessage('mimi1', 2, now),
                child: Image.asset(
                  'images/mimi1.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              ElevatedButton(
                onPressed: () => onSendMessage('mimi2', 2, now),
                child: Image.asset(
                  'images/mimi2.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              ElevatedButton(
                onPressed: () => onSendMessage('mimi3', 2, now),
                child: Image.asset(
                  'images/mimi3.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              ElevatedButton(
                onPressed: () => onSendMessage('mimi4', 2, now),
                child: Image.asset(
                  'images/mimi4.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              ElevatedButton(
                onPressed: () => onSendMessage('mimi5', 2, now),
                child: Image.asset(
                  'images/mimi5.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              ElevatedButton(
                onPressed: () => onSendMessage('mimi6', 2, now),
                child: Image.asset(
                  'images/mimi6.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              ElevatedButton(
                onPressed: () => onSendMessage('mimi7', 2, now),
                child: Image.asset(
                  'images/mimi7.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              ElevatedButton(
                onPressed: () => onSendMessage('mimi8', 2, now),
                child: Image.asset(
                  'images/mimi8.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              ElevatedButton(
                onPressed: () => onSendMessage('mimi9', 2, now),
                child: Image.asset(
                  'images/mimi9.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),

      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
          color: Colors.white),
      padding: EdgeInsets.all(5.0),
      height: 180.0,
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading ? Center(child: const CircularProgressIndicator()) : Container(),
    );
  }

  Widget buildInput() {
    return SafeArea(
      child: Container(
        child: Row(
          children: <Widget>[
            // Button send image
            InkWell(
              child: Container(
                child: Icon(Icons.image, size: 24, color: Colors.black,),
                margin: EdgeInsets.fromLTRB(10.0, 0, 10, 0),
              ),
              onTap: () {
                getImage();
              },
            ),

            // GestureDetector(
            //   child: Container(
            //     child: Icon(Icons.face, size: 24, color: Colors.black,),
            //     margin: EdgeInsets.fromLTRB(5.0, 0, 13, 0),
            //   ),
            //   onTap: () {
            //     getSticker();
            //   },
            // ),
            // Edit text
            Expanded(
              child: Container(
                constraints: BoxConstraints(maxHeight: 200),
                child: TextField(
                  onSubmitted: (value) {
                    DateTime now = DateTime.now();
                    onSendMessage(textEditingController.text, 0, now);
                  },
                  //style: TextStyle(color: primaryColor, fontSize: 15.0),
                  style: TextStyle(color: Colors.black, fontSize: 15.0),
                  controller: textEditingController,
                  maxLines: null,
                  //expands: true,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration.collapsed(
                    hintText: '메세지를 입력하세요',
                    //hintStyle: TextStyle(color: greyColor),
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  focusNode: focusNode,
                ),
              ),
            ),

            // Button send message

            Container(
              margin: EdgeInsets.symmetric(horizontal: 8.0),
                child: textEditingController.text.length != 0
                    ? IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () {
                          DateTime now = DateTime.now();
                          onSendMessage(textEditingController.text, 0, now);
                        },
                        //color: primaryColor,
                        color: Colors.black,
                      )
                    : IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () {
                        },
                        //color: primaryColor,
                        color: Colors.black.withOpacity(0.2),
                      )),
          ],
        ),
        width: double.infinity,
        height: 50.0,
        //decoration: BoxDecoration(border: Border(top: BorderSide(color: greyColor2, width: 0.5)), color: Colors.white),
        decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            color: Colors.white),
      ),
    );
  }

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId == ''
      //? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor)))
          ? Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red)))
          : StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(groupChatId)
            .collection(groupChatId)
            .orderBy('timestamp', descending: true)
            .limit(_limit)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              //child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor)));
                child: CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.red)));
          } else {
            //print(snapshot.data.docs.id);
            print(snapshot.data);
            if (isChatExist == false && snapshot.data.docs.length > 0)
              isChatExist = true;
            if(snapshot.data.docs.length < _limit)
              hasMore = false;

            listMessage.clear();
            //chatController.chatList.clear();
            listMessage.addAll(snapshot.data.docs);
            chatController.addAllMessages(snapshot.data.docs);
            //print(snapshot.data.docs[0].id);
            return Obx(() => ListView.builder(
              padding: EdgeInsets.all(10.0),
              itemBuilder: (context, index) =>
                  //buildItem(index, snapshot.data.docs[index]),
                  buildItem(index, chatController.chatList[index]),
              //itemCount: snapshot.data.docs.length,
              itemCount: chatController.chatList.length,
              reverse: true,
              controller: listScrollController,
            ),);
          }
        },
      ),
    );
  }
}