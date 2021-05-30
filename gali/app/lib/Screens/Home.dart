import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gali/UI_Elements/FileTile.dart';
import 'package:gali/globals.dart';
import 'package:flappy_search_bar/flappy_search_bar.dart';
import 'package:flappy_search_bar/search_bar_style.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Theme.of(context).backgroundColor,
        child: LimitedBox(
          maxHeight: 400,
          child: SearchFriend(),
        ));
  }
}

class SearchFriend extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    Future<List<FileTile>> search(String search) async {
      return Future.delayed(
          Duration(seconds: 1, milliseconds: 500),
          () => context
              .read(fi)
              .where((element) =>
                  element.name.toLowerCase().contains(search.toLowerCase()))
              .map((info) => FileTile(
                    info: info,
                  ))
              .toList());

    }

    return SearchBar<FileTile>(
      mainAxisSpacing: 30,
      suggestions: context
          .read(fi)
          .getRange(0, context.read(fi).length ~/ 2)
          .map((info) => FileTile(
                info: info,
              ))
          .toList(),
      searchBarStyle: SearchBarStyle(
          borderRadius: BorderRadius.circular(16.0),
          backgroundColor: Theme.of(context).bottomAppBarColor),
      hintText: 'Search file',
      minimumChars: 1,
      iconActiveColor: Theme.of(context).highlightColor,
      textStyle: TextStyle(color: Theme.of(context).highlightColor),
      cancellationText: Text(
        "clear",
        style: TextStyle(
            color: Theme.of(context).highlightColor,
            fontWeight: FontWeight.bold),
      ),
      onSearch: search,
      onItemFound: (FileTile response, int index) {
        return response;
      },
      onError: (error) {
        return Center(
          child: Text("Error occurred : $error"),
        );
      },
      loader: Center(
        child: CircularProgressIndicator(
          valueColor:
              AlwaysStoppedAnimation<Color>(Theme.of(context).highlightColor),
        ),
        //child: CupertinoActivityIndicator(),
      ),
      emptyWidget: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.withOpacity(0.5),
              child: SizedBox(
                height: 50,
                child: Image.asset('assets/images/dog.png'),
              )),
          Text(
            "Wow, such empty",
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).highlightColor),
          )
        ],
      )),
    );
  }
}
