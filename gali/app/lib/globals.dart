import 'package:gali/grpc/protos/gali.pbgrpc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gali/grpc/galiClient.dart';
import 'package:grpc/grpc.dart';
import 'package:flutter/material.dart';
import 'secure_storage.dart';

// this is the index of the current page.
var selectedIndex = StateProvider((ref) => 0);
//var themeMode = StateProvider((ref) => ThemeMode.system);

// final fileTileProvider = StateNotifierProvider((ref) {
//   return FilesNotifier();
// });

final fi = StateNotifierProvider<FilesNotifier, List<FileInfo>>((ref) {
  return FilesNotifier();
});

final themeMode = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

var client = new GaliClient(GaliChannel(
  ClientChannel(
    '6.tcp.ngrok.io',
    port: 11889,
    options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
  ),
));

class FilesNotifier extends StateNotifier<List<FileInfo>> {
  FilesNotifier() : super([]);

  void clear() {
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

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  /// [updateThemeMode] changes [Globals.themeMode] for a given index.
  ///
  /// 0 -> darkTheme
  /// 1 -> lightTheme
  /// 2 -> system theme.
  void updateThemeMode(int index) {
    switch (index) {
      case 0:
        {
          state = ThemeMode.dark;
          break;
        }
      case 1:
        {
          state = ThemeMode.light;
          break;
        }
      case 2:
        {
          state = ThemeMode.system;
          break;
        }
    }

    SecureStorage.writeSecureData('ThemeIndex', index.toString());
  }

}
