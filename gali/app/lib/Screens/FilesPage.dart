import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:gali/UI_Elements/FileTile.dart';

import 'package:gali/globals.dart';
import 'package:gali/grpc/protos/gali.pb.dart';

import 'package:gali/grpc/protos/gali.pbgrpc.dart';


import 'package:google_fonts/google_fonts.dart';


class FilesPage extends StatefulWidget {

  FilesPage({Key key,}) : super(key: key);

  @override
  _FilesPageState createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage>
    with SingleTickerProviderStateMixin {
  StreamController<FileInfo> streamController;
  List<FileInfo> files = [];

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

    if (Globals.files.length == 0 || streamController == null) {
      streamController = StreamController.broadcast();
      streamController.stream.listen((msg) {
        setState(() {
          files.insert(0, msg);
        });
      });
      load(streamController);
      Globals.files = files;
    }

    files = Globals.files;
  }

  load(StreamController<FileInfo> sc) async {
    Globals.client.getAllFiles().pipe(sc);
  }

  Widget _makeElement(int index) {
    if (index >= files.length) {
      return null;
    }

    return FileTile(info: files[index]);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: <Widget>[
      SliverFixedExtentList(
        itemExtent: 100.0,
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) => _makeElement(index),
        ),
      ),
    ]);
  }
}
