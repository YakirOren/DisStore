import 'package:flutter/material.dart';
import 'package:gali/UI_Elements/ThemeSwitcherButton.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Theme.of(context).highlightColor),
        backgroundColor: Theme.of(context).bottomAppBarColor,
      ),
      body: Column(
        children: [
          Center(
            child: ThemeButton(),
          ),
        ],
      ),
    );
  }
}
