import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gali/Screens/FileInfoPage.dart';
import 'package:gali/UI_Elements/confirm.dart';
import 'package:gali/globals.dart';
import 'package:gali/grpc/protos/gali.pb.dart';

import 'package:gali/grpc/protos/gali.pbgrpc.dart';
import 'package:gali/helpers.dart';
import 'package:riverpod/riverpod.dart';

enum MenuOption { info, copy, save, remove }

class ProgNotf extends StateNotifier<double> {
  ProgNotf() : super(0);

  void setProg(double val) {
    state = val;
  }
}

class FileTile extends ConsumerWidget {
  final FileInfo info;

  FileTile({
    Key key,
    @required this.info,
  }) : super(key: key);

  FileInfo get getInfo => info;

  final prog = StateNotifierProvider<ProgNotf, double>((ref) {
    return ProgNotf();
  });

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final streamController = StreamController<double>.broadcast();
    final pn = watch(this.prog);

    streamController.stream.listen(
        (msg) {
          context.read(this.prog.notifier).setProg(msg);
        },
        cancelOnError: true,
        onDone: () {
          ScaffoldMessenger.of(context).showOkBar("Download completed");
        },
        onError: (e) {
          ScaffoldMessenger.of(context).showHTTPErrorBar(e);
        });

    return ListTile(
      leading: Icon(Icons.folder, color: Theme.of(context).highlightColor),

      trailing: PopupMenuButton<MenuOption>(
          color: Theme.of(context).backgroundColor,
          icon: Icon(Icons.more_horiz, color: Theme.of(context).highlightColor),
          onSelected: (MenuOption result) async {
            switch (result) {
              case MenuOption.info:
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => FileInfoPage(info: this.info)));

                break;

              case MenuOption.copy:
                break;

              case MenuOption.save:
                client
                    .getFile(this.info.name, this.info.id)
                    .pipe(streamController);

                break;

              case MenuOption.remove:
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return ConfirmDialog(
                        danger: true,
                        title: "Delete ${this.info.name}?",
                        content: Text("Are you sure you want to delete?"),
                        actionFunction: () {
                          client.deleteFile(this.info.id).then((value) {
                            context.read(fi.notifier).delete(this.info);
                            ScaffoldMessenger.of(context)
                                .showOkBar("${this.info.name} was deleted");
                          });
                          Navigator.of(context).pop();
                        },
                        cancelFunction: () {
                          Navigator.of(context).pop();
                          return false;
                        },
                        actionText: Text("Delete"),
                      );
                    });

                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuOption>>[
                PopupMenuItem<MenuOption>(
                  value: MenuOption.info,
                  child: ListTile(
                    leading: Icon(Icons.info_outline,
                        color: Theme.of(context).highlightColor),
                    title: Text('Info'),
                  ),
                ),
                PopupMenuItem<MenuOption>(
                  value: MenuOption.copy,
                  child: ListTile(
                    leading: Icon(Icons.copy_outlined,
                        color: Theme.of(context).highlightColor),
                    title: Text('Copy link'),
                    dense: true,
                  ),
                ),
                PopupMenuItem<MenuOption>(
                  value: MenuOption.save,
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.download_outlined,
                        color: Theme.of(context).highlightColor),
                    title: Text('Download'),
                  ),
                ),
                PopupMenuItem<MenuOption>(
                  value: MenuOption.remove,
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.delete_outline,
                        color: Theme.of(context).highlightColor),
                    title: Text('Delete'),
                  ),
                ),
              ]),

      title: pn > 0
          ? LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              backgroundColor: Colors.grey,
              value: pn,
            )
          : Text(
              this.info.name,
            ),
      //onTap: () async {},
    );
  }
}
