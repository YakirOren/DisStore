import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Card(
          child: Column(
        children: [
          ListTile(
            tileColor: Theme.of(context).backgroundColor,
            leading: Icon(
              Icons.folder,
              color: Theme.of(context).highlightColor,
            ),
            trailing:
                IconButton(icon: Icon(Icons.more_horiz, color: Theme.of(context).highlightColor), onPressed: () {}),
            title: Text(
              "avatar.png",
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ),
          Card(
            color: Theme.of(context).backgroundColor,
            semanticContainer: true,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Image(
              image: AssetImage('assets/images/avatar.png'),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 0,
            margin: EdgeInsets.all(10),
          ),
        ],
      )),
    ]);
  }
}
