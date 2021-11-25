import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hibaike_app/controller/page_index_controller.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:photo_view/photo_view.dart';

class FullPhotoSlide extends StatefulWidget {
  @override
  _FullPhotoSlideState createState() => _FullPhotoSlideState();
}

class _FullPhotoSlideState extends State<FullPhotoSlide> {
  List<String> imageList = Get.arguments;
  PageController _pageController;
  PageIndexController _pageIndexController = Get.find();

  @override
  void initState() {
    _pageController = PageController(initialPage: _pageIndexController.index.value);
    super.initState();
  }

  void onPageChanged(int index) {
    _pageIndexController.chageIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              child: PhotoViewGallery.builder(
                scrollPhysics: const BouncingScrollPhysics(),
                builder: (BuildContext context, int index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: NetworkImage(imageList[index]),
                    initialScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                    //minScale: PhotoViewComputedScale.covered
                    minScale: PhotoViewComputedScale.contained * 0.8,
                    // heroAttributes:
                    //     PhotoViewHeroAttributes(tag: galleryItems[index].id),
                  );
                },
                itemCount: imageList.length,
                loadingBuilder: (context, event) => Center(
                  child: Container(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      value: event == null
                          ? 0
                          : event.cumulativeBytesLoaded / event.expectedTotalBytes,
                    ),
                  ),
                ),
                // backgroundDecoration: widget.backgroundDecoration,
                pageController: _pageController,
                onPageChanged: onPageChanged,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: imageList.map((url) {
                  int index = imageList.indexOf(url);
                  return Obx(()=>Container(
                    width: 10.0,
                    height: 10.0,
                    margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Get.find<PageIndexController>().index.value == index
                          ? Color.fromRGBO(255, 255, 255, 0.8)
                          : Color.fromRGBO(80, 80, 80, 0.6),
                    ),
                  ));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullPhotoInChat extends StatefulWidget {
  final String currentUrl;
  final String groupChatId;

  FullPhotoInChat({Key key, @required this.currentUrl, @required this.groupChatId}) : super(key: key);

  @override
  State createState() => FullPhotoInChatState(currentUrl: currentUrl, groupChatId: groupChatId);
}

class FullPhotoInChatState extends State<FullPhotoInChat> {
  final String currentUrl;
  final groupChatId;

  FullPhotoInChatState({Key key, @required this.currentUrl, @required this.groupChatId});

  int firstPage = 2;
  PageController _pageController;
  List<String> imageUrlList=[];

  @override
  void initState() {
    //_pageController = PageController(initialPage: firstPage);
    //fetchImageList();
    super.initState();
  }

  Future<List<String>> fetchImageList() async {
    List<String> _imageUrlList=[];
    var snap = await FirebaseFirestore.instance
        .collection('chats')
        .doc(groupChatId)
        .collection(groupChatId)
        .where('type', isEqualTo: 1)
        .get();

    for(var i = 0 ; i < snap.docs.length ; i++){
      _imageUrlList.add(snap.docs[i].data()['content']);
    }

    imageUrlList = List.from(_imageUrlList.reversed);

    _pageController = PageController(initialPage: imageUrlList.indexOf(currentUrl));

    return imageUrlList;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: FutureBuilder<List<String>>(
            future: fetchImageList(),
            builder: (context, AsyncSnapshot<List<String>> snapshot) {
              if(!snapshot.hasData)
                return Center(
                  child: CircularProgressIndicator(),
                  //Text("loading", style: TextStyle(color: Colors.white),)//
                );
              else {
                return Container(
                  child: PhotoViewGallery.builder(
                    scrollPhysics: const BouncingScrollPhysics(),
                    builder: (BuildContext context, int index) {
                      return PhotoViewGalleryPageOptions(
                        imageProvider: NetworkImage(snapshot.data[index]),
                        initialScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 1.5,
                        // heroAttributes:
                        //     PhotoViewHeroAttributes(tag: galleryItems[index].id),
                      );
                    },
                    itemCount: snapshot.data.length,

                    loadingBuilder: (context, event) => Center(
                      child: Container(
                        width: 20.0,
                        height: 20.0,
                        child: CircularProgressIndicator(
                          value: event == null
                              ? 0
                              : event.cumulativeBytesLoaded / event.expectedTotalBytes,
                        ),
                      ),
                    ),
                    // backgroundDecoration: widget.backgroundDecoration,
                    pageController: _pageController,
                    // onPageChanged: onPageChanged,
                  ),
                );}
            }
        ),
      ),
    );
  }
}
