import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:gali/UI_Elements/FileTile.dart';

import 'package:gali/globals.dart';
import 'package:gali/grpc/protos/gali.pb.dart';

import 'package:gali/grpc/protos/gali.pbgrpc.dart';

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

      Globals.files.insert(0, FileTile(info: msg));
      setState(() {});
    });

    try {
      load(streamController); // enter data to the stream.
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
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

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      header: MaterialClassicHeader(
        color: Colors.blue,
      ),
      controller: _refreshController,
      onRefresh: _onRefresh,
      child: ListView(
        itemExtent: 80,
        children: Globals.files,
      ),
    );
  }
}
