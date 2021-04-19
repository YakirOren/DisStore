import 'package:gali/grpc/protos/gali.pbgrpc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gali/grpc/galiClient.dart';
import 'package:grpc/grpc.dart';
import 'package:flutter/material.dart';
import 'secure_storage.dart';

class Globals {
  // this is the index of the current page.
  static var selectedIndex = StateProvider((ref) => 0);
  
  static var themeMode = StateProvider((ref) => ThemeMode.system);

  static List<FileInfo> files = [];

  static var client = GaliClient(GaliChannel(
    ClientChannel(
      '192.168.1.26',
      port: 6969,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    ),
  ));

  /// [updateThemeMode] changes [Globals.themeMode] for a given index.
  ///
  /// 0 -> darkTheme
  /// 1 -> lightTheme
  /// 2 -> system theme.
  static void updateThemeMode(int index, BuildContext context) {

    switch (index) {
      case 0:
        {
          context.read(themeMode).state = ThemeMode.dark;
          break;
        }
      case 1:
        {
          context.read(themeMode).state = ThemeMode.light;
          break;
        }
      case 2:
        {
          context.read(themeMode).state = ThemeMode.system;
          break;
        }
    }

    SecureStorage.writeSecureData('ThemeIndex', index.toString());
  }

  static bool isDarkMode(BuildContext context){
    var brightness = MediaQuery.of(context).platformBrightness;
    bool darkModeOn =
        (context.read(themeMode).state == ThemeMode.dark &&
            brightness == Brightness.dark);
    return darkModeOn;
  }
}
