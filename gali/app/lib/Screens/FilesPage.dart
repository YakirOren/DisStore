import 'package:flutter/material.dart';
import 'package:gali/globals.dart';
import 'package:gali/grpc/protos/gali.pb.dart';

import 'dart:async';
import 'package:gali/grpc/protos/gali.pbgrpc.dart';

import 'package:flutter/cupertino.dart';

import 'package:google_fonts/google_fonts.dart';

enum FileMenu { info, copy, save, remove }

class FilesPage extends StatefulWidget {
  final String transferEmail;

  FilesPage({Key key, this.transferEmail}) : super(key: key);

  @override
  _FilesPageState createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage>
    with SingleTickerProviderStateMixin {
  final emailControler = TextEditingController();
  StreamController<FileInfo> streamController;
  List<FileInfo> files = [];

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    super.dispose();
    emailControler.dispose();
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

    return ListTile(
      leading: Icon(Icons.folder, color: Theme.of(context).highlightColor),
      trailing: PopupMenuButton<FileMenu>(
          icon: Icon(Icons.more_horiz, color: Theme.of(context).highlightColor),
          onSelected: (FileMenu result) async {
            switch (result) {
              case FileMenu.save:
                print(files[index].id);
                await Globals.client
                    .getFile(files[index].name, files[index].id);
                break;
              default:
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<FileMenu>>[
                PopupMenuItem<FileMenu>(
                  value: FileMenu.info,
                  child: ListTile(
                    leading: Icon(Icons.info_outline,
                        color: Theme.of(context).highlightColor),
                    title: Text('Info'),
                  ),
                ),
                PopupMenuItem<FileMenu>(
                  value: FileMenu.copy,
                  child: ListTile(
                    leading: Icon(Icons.copy_outlined,
                        color: Theme.of(context).highlightColor),
                    title: Text('Copy link'),
                    dense: true,
                  ),
                ),
                PopupMenuItem<FileMenu>(
                  value: FileMenu.save,
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.download_outlined,
                        color: Theme.of(context).highlightColor),
                    title: Text('Download'),
                  ),
                ),
                PopupMenuItem<FileMenu>(
                  value: FileMenu.remove,
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.delete_outline,
                        color: Theme.of(context).highlightColor),
                    title: Text('Delete'),
                  ),
                ),
              ]),
      title: Text(
        files[index].name,
      ),
      onTap: () async {},
    );

    //var format = DateFormat('d/M/y');
    //format.format(DateTime.fromMillisecondsSinceEpoch(files[index].time.toInt() * 1000))
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
