import 'dart:ui';

import 'package:flutter/material.dart';

import 'dart:async';

import 'package:gali/globals.dart';
import 'package:gali/Screens/settingsPage.dart';
import 'package:gali/Screens/Home.dart';
import 'package:gali/Screens/FilesPage.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';

import 'package:gali/helpers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/svg.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:gali/UI_Elements/confirm.dart';
import 'package:gali/secure_storage.dart';
import 'LoginPage.dart';

//AppBase is the base of the application,
//it has a navigation bar and
class AppBase extends StatefulWidget {
  // this will show in the bottom part of the app.
  @override
  _AppBaseState createState() => _AppBaseState();
}

class _AppBaseState extends State<AppBase> {
  @override
  void initState() {
    super.initState();
    init();
  }

  /// [init] sets values to the globals and starts a timer to refresh the access toekn.
  void init() async {
    // stating a periodic timer to refresh the accsess token in the backround.
    Timer.periodic(Duration(minutes: 5), (timer) async {
      await client.loginWithRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    // _widgetOptions holds the pages
    final List<Widget> _widgetOptions = <Widget>[
      FilesPage(),
      HomePage(),
    ];
    void _onItemTapped(int index) {
      context.read(selectedIndex).state = index;
    }

    MaterialColor color =
        (Theme.of(context).highlightColor).createMaterialColor();

    return Consumer(builder: (context, watch, _) {
      final index = watch(selectedIndex).state;

      final navItems = [
        BottomNavigationBarItem(
            icon: Icon(index == 0 ? Icons.folder : Icons.folder_outlined),
            label: "Files",
            backgroundColor: Theme.of(context).bottomAppBarColor),
        BottomNavigationBarItem(
          icon: Icon(index == 1 ? Icons.search : Icons.search_outlined),
          label: "Search",
          backgroundColor: Theme.of(context).bottomAppBarColor,
        ),
      ];

      return Scaffold(
        primary: true,
        floatingActionButton: ActionsButton(),
        backgroundColor: Theme.of(context).backgroundColor,
        drawer: Drawer(
          child: Container(
            color: Theme.of(context).backgroundColor,
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                UserAccountsDrawerHeader(
                  otherAccountsPictures: [
                    IconButton(
                      icon: Icon(Icons.logout, color: Colors.white),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => ConfirmDialog(
                              danger: true,
                              title: 'Log out?',
                              content:
                                  Text("Are you sure you want to log out?"),
                              cancelFunction: () {
                                Navigator.of(context).pop();
                                return false;
                              },
                              actionText: Text('logout'),
                              actionFunction: () {
                                logout(context);
                              }),
                        );
                      },
                    ),
                  ],
                  accountEmail: Text(client.getCachedMail),
                  accountName: Text(
                      "${client.getCachedFirstName.capitalize()} ${client.getCachedLastName.capitalize()}"),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: AssetImage("assets/images/avatar.png"),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.offline_pin_outlined, color: color[800]),
                  title: Text('Offline'),
                  onTap: () {},
                  horizontalTitleGap: 0,
                ),
                ListTile(
                  leading: Icon(Icons.settings_outlined, color: color[800]),
                  title: Text('Settings'),
                  horizontalTitleGap: 0,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) => SettingsPage()));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.help_outline, color: color[800]),
                  title: Text('Help & Feedback'),
                  horizontalTitleGap: 0,
                ),
                ListTile(
                  leading: Icon(Icons.cloud_outlined, color: color[800]),
                  horizontalTitleGap: 0,
                  title: Text(
                    'Storage',
                  ),
                  subtitle: LimitedBox(
                    maxHeight: 40,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Spacer(),
                        LinearProgressIndicator(
                          value: client.getUsedStorage / 10,
                          backgroundColor: color[300],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        Spacer(),
                        Text(
                            "${formatFileSize(client.getUsedStorage)} of ∞ GB used",
                            style: Theme.of(context).textTheme.subtitle1),
                      ],
                    ),
                  ),
                  isThreeLine: true,
                  trailing: LimitedBox(),
                ),
              ],
            ),
          ),
        ),
        appBar: AppBar(
          iconTheme: IconThemeData(color: color),
          centerTitle: true,
          elevation: 1,
          backgroundColor: Theme.of(context).bottomAppBarColor,
        ),
        body: Center(
          child: _widgetOptions.elementAt(index),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: false,
          backgroundColor: Theme.of(context).bottomAppBarColor,
          unselectedItemColor: Colors.grey,
          selectedItemColor: Colors.blue,
          items: navItems,
          currentIndex: index,
          onTap: _onItemTapped,
        ),
      );
    });
  }
}

void logout(BuildContext context) {
  SecureStorage.deleteSecureData('refreshToken');

  // final f = watch(fileTileProvider);
  // //files.clear();

  context.read(fi).clear();

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
        fullscreenDialog: true,
        maintainState: false,
        builder: (context) {
          return LoginPage();
        }),
  );
}

class ActionsButton extends StatelessWidget {
  const ActionsButton({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: LimitedBox(
        maxHeight: 20,
        maxWidth: 20,
        child: SvgPicture.asset(
          "assets/icon/plus.svg",
        ),
      ),
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          builder: (BuildContext context) {
            return Container(
              height: 200,
              color: Theme.of(context).backgroundColor,
              child: Center(
                child: Column(
                  children: [
                    Spacer(
                      flex: 5,
                    ),
                    Text(
                      "Create new",
                      style: GoogleFonts.roboto(
                        color: Theme.of(context).highlightColor,
                        fontWeight: FontWeight.w300,
                        fontSize: 20,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Spacer(
                      flex: 5,
                    ),
                    Wrap(
                      spacing: 32.0, // gap between adjacent chips
                      runSpacing: 4.0, // gap between lines
                      children: <Widget>[
                        CircleAvatar(
                          child: CircleAvatar(
                            radius: 29.5,
                            backgroundColor: Theme.of(context).backgroundColor,
                            child: IconButton(
                                icon: Icon(
                                  Icons.folder_open_rounded,
                                ),
                                onPressed: () async {
                                  FilePickerResult result = await FilePicker
                                      .platform
                                      .pickFiles(type: FileType.any);

                                  if (result != null) {
                                    client
                                        .upload(result.files.single)
                                        .then((value) {
                                      Navigator.of(context).pop();

                                      ScaffoldMessenger.of(context)
                                          .showOkBar("Upload completed!");
                                    });
                                  } else {
                                    // User canceled the picker
                                  }
                                }),
                          ),
                          backgroundColor: Theme.of(context).highlightColor,
                          radius: 30,
                        ),
                        CircleAvatar(
                          child: CircleAvatar(
                            radius: 29.5,
                            backgroundColor: Theme.of(context).backgroundColor,
                            child: IconButton(
                                icon: Icon(
                                  Icons.file_upload,
                                ),
                                onPressed: () async {
                                  FilePickerResult result = await FilePicker
                                      .platform
                                      .pickFiles(type: FileType.media);

                                  if (result != null) {
                                    client
                                        .upload(result.files.single)
                                        .then((value) {
                                      Navigator.of(context).pop();

                                      ScaffoldMessenger.of(context)
                                          .showOkBar("Upload completed!");
                                    });
                                  } else {
                                    // User canceled the picker
                                  }
                                }),
                          ),
                          backgroundColor: Theme.of(context).highlightColor,
                          radius: 30,
                        ),
                        CircleAvatar(
                          child: CircleAvatar(
                            radius: 29.5,
                            backgroundColor: Theme.of(context).backgroundColor,
                            child: IconButton(
                                splashColor: Colors.grey,
                                icon: Icon(
                                  Icons.photo_camera_outlined,
                                ),
                                onPressed: () {
                                  print("cam");
                                }),
                          ),
                          backgroundColor: Theme.of(context).highlightColor,
                          radius: 30,
                        ),
                      ],
                    ),
                    Spacer(
                      flex: 40,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      foregroundColor: Theme.of(context).highlightColor,
      backgroundColor: Theme.of(context).backgroundColor,
    );
  }
}
