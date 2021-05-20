import 'package:gali/grpc/protos/gali.pbgrpc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gali/grpc/galiClient.dart';
import 'package:grpc/grpc.dart';
import 'package:flutter/material.dart';
import 'secure_storage.dart';

// this is the index of the current page.
var selectedIndex = StateProvider((ref) => 0);
var themeMode = StateProvider((ref) => ThemeMode.system);

// final fileTileProvider = StateNotifierProvider((ref) {
//   return FilesNotifier();
// });

final fi = StateNotifierProvider<FilesNotifier, List<FileInfo>>((ref) {
    return FilesNotifier();
});


var client = new GaliClient(GaliChannel(
  ClientChannel(
    '192.168.1.22',
    port: 6969,
    options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
  ),
));

/// [updateThemeMode] changes [Globals.themeMode] for a given index.
///
/// 0 -> darkTheme
/// 1 -> lightTheme
/// 2 -> system theme.
void updateThemeMode(int index, BuildContext context) {
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

bool isDarkMode(BuildContext context) {
  var brightness = MediaQuery.of(context).platformBrightness;
  bool darkModeOn = (context.read(themeMode).state == ThemeMode.dark &&
      brightness == Brightness.dark);
  return darkModeOn;
}

class FilesNotifier extends StateNotifier<List<FileInfo>> {
  FilesNotifier() : super([]);

  void clear(){
    state = [];
  }

  void add(FileInfo ft) {
    state = [...state, ft];
  }

  void delete(FileInfo ft) {
    state = [
      for (final tile in state)
        if (ft != tile) tile
    ];
  }
}
