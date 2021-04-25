import 'package:flutter/material.dart';
import 'package:gali/Screens/FileInfoPage.dart';
import 'package:gali/globals.dart';
import 'package:gali/grpc/protos/gali.pb.dart';

import 'package:gali/grpc/protos/gali.pbgrpc.dart';

enum FileMenu { info, copy, save, remove }

class FileTile extends StatefulWidget {
  final FileInfo info;
  const FileTile({
    Key key,
    @required this.info,
  }) : super(key: key);

  @override
  _FileTileState createState() => _FileTileState();
}

class _FileTileState extends State<FileTile> {
  double loadingProgress = 0;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.folder, color: Theme.of(context).highlightColor),

      trailing: PopupMenuButton<FileMenu>(
          color: Theme.of(context).backgroundColor,
          icon: Icon(Icons.more_horiz, color: Theme.of(context).highlightColor),
          onSelected: (FileMenu result) async {
            switch (result) {
              case FileMenu.info:
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => FileInfoPage(info: widget.info)));

                break;

              case FileMenu.copy:
                break;

              case FileMenu.save:
                Globals.client
                    .getFile(widget.info.name, widget.info.id)
                    .listen((val) {
                  setState(() {
                    loadingProgress = val;
                  });
                }).onDone(() {
                  setState(() {
                    loadingProgress = 0;
                  });
                });
                break;

              case FileMenu.remove:
                break;
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

      title: loadingProgress > 0
          ? LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              backgroundColor: Colors.grey,
              value: loadingProgress,
            )
          : Text(
              widget.info.name,
            ),
      //onTap: () async {},
    );
  }
}
