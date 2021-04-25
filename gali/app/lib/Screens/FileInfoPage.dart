import 'package:flutter/material.dart';
import 'package:gali/globals.dart';
import 'package:gali/grpc/protos/gali.pb.dart';
import 'package:gali/grpc/protos/gali.pbgrpc.dart';
import 'package:gali/helpers.dart';

class FileInfoPage extends StatefulWidget {
  final FileInfo info;
  const FileInfoPage({
    Key key,
    @required this.info,
  }) : super(key: key);

  @override
  _FileInfoPageState createState() => _FileInfoPageState();
}

class _FileInfoPageState extends State<FileInfoPage> {
  @override
  Widget build(BuildContext context) {
    MaterialColor color =
        (Theme.of(context).highlightColor).createMaterialColor();
    var style = Theme.of(context).textTheme.subtitle2;
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        iconTheme: IconThemeData(color: color),
        centerTitle: false,
        elevation: 1,
        backgroundColor: Theme.of(context).bottomAppBarColor,
      ),
      body: Container(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            ListTile(
              title: Text(
                'Type',
                style: style,
              ),
              subtitle: Text(
                '.' +
                    widget.info.name
                        .substring(widget.info.name.lastIndexOf('.') + 1),
                style: Theme.of(context).textTheme.bodyText1,
              ),
            ),
            ListTile(
              title: Text(
                'Created',
                style: style,
              ),
              subtitle: Text(readTimestamp(widget.info.creationTime.toInt()),
                  style: Theme.of(context).textTheme.bodyText1),
            ),
            ListTile(
              title: Text(
                'Name',
                style: style,
              ),
              subtitle: Text(widget.info.name,
                  style: Theme.of(context).textTheme.bodyText1),
            ),
            ListTile(
              title: Text(
                'Size',
                style: style,
              ),
              subtitle: Text(formatFileSize(widget.info.fileSize),
                  style: Theme.of(context).textTheme.bodyText1),
            ),
          ],
        ),
      ),
    );
  }
}
