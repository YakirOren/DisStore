import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gali/UI_Elements/FileTile.dart';

import 'package:gali/globals.dart';
import 'package:gali/grpc/protos/gali.pb.dart';

import 'package:gali/grpc/protos/gali.pbgrpc.dart';

import 'package:pull_to_refresh/pull_to_refresh.dart';

class FilesPage extends ConsumerWidget {
  final _refreshController = RefreshController(initialRefresh: (true));

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final streamController = StreamController<FileInfo>.broadcast();
    final listFile = watch(fi);

    return SmartRefresher(
      header: MaterialClassicHeader(
        color: Colors.blue,
      ),
      controller: _refreshController,
      onRefresh: () {
        context.read(fi.notifier).clear();
        streamController.stream.listen((msg) {
          // this funciton runs everytime a msg enters the stream.

          context.read(fi.notifier).add(msg);
        });

        try {
          load(streamController); // enter data to the stream.
          _refreshController.refreshCompleted();
        } catch (e) {
          _refreshController.refreshFailed();
        }
      },
      child: ListView.builder(
        itemExtent: 80,
        itemBuilder: (context, index) {
          return FileTile(
            info: listFile[index],
          );
        },
        itemCount: listFile.length,
      ),

    );
  }

  load(StreamController<FileInfo> sc) async {
    // put files into the stream controler.
    client.getAllFiles().pipe(sc);
  }
}
