import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:gali/UI_Elements/FileTile.dart';

import 'package:gali/globals.dart';
import 'package:gali/grpc/protos/gali.pb.dart';

import 'package:gali/grpc/protos/gali.pbgrpc.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class FilesPage extends StatefulWidget {
  FilesPage({
    Key key,
  }) : super(key: key);

  @override
  _FilesPageState createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  StreamController<FileInfo> streamController;
  RefreshController _refreshController =
      RefreshController(initialRefresh: (Globals.files.length == 0));

  void _onRefresh() async {
    await Future.delayed(Duration(milliseconds: 1500));
    Globals.files = [];
    streamController = StreamController.broadcast();

    // setup the controller
    streamController.stream.listen((msg) {
      // this funciton runs everytime a msg enters the stream.
      setState(() {
        Globals.files.insert(0, FileTile(info: msg));
      });
    });

    try {
      load(streamController); // enter data to the stream.

      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }

  void _onLoading() async {
    print("loading");

    _refreshController.loadComplete();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    super.dispose();
    streamController?.close();
    streamController = null;
  }

  @override
  void initState() {
    super.initState();
  }

  load(StreamController<FileInfo> sc) async {
    // put files into the stream controler.
    Globals.client.getAllFiles().pipe(sc);
  }

  Widget _makeElement(int index) {
    if (index >= Globals.files.length) {
      return null;
    }

    return Globals.files[index];
  }

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      enablePullDown: true,
      header: ClassicHeader(
        refreshStyle: RefreshStyle.UnFollow,
        iconPos: IconPosition.top,
        refreshingText: "",
        refreshingIcon: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
        ),
      ),
      footer: CustomFooter(
        builder: (BuildContext context, LoadStatus mode) {
          Widget body;
          if (mode == LoadStatus.idle) {
            body = Text("pull up load");
          } else if (mode == LoadStatus.loading) {
            body = CupertinoActivityIndicator();
          } else if (mode == LoadStatus.failed) {
            body = Text("Load Failed!Click retry!");
          } else if (mode == LoadStatus.canLoading) {
            body = Text("release to load more");
          } else {
            body = Text("No more Data");
          }
          return Container(
            height: 55.0,
            child: Center(child: body),
          );
        },
      ),
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoading: _onLoading,


      child: ListView(
        itemExtent: 100,
        children: Globals.files,
      ),
    );
  }
}
