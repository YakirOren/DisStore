import 'package:http/http.dart';

import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:intl/intl.dart';

// This file has helper functions to manage the app better

// This extends the string type to add a method named capitalize
//   that returns the string with the first letter capitalized
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

extension MaterialC on Color {
  MaterialColor createMaterialColor() {
    List strengths = <double>[.05];
    Map swatch = <int, Color>{};
    final int r = this.red, g = this.green, b = this.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    strengths.forEach((strength) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    });
    return MaterialColor(this.value, swatch);
  }
}

extension SnackBars on ScaffoldMessengerState {
  // showErrorBar displays the grpc error to the user.
  void showErrorBar(GrpcError e) {
    this.showSnackBar(SnackBar(
      content: Text('[${e.codeName}] ${e.message}'),
      backgroundColor: Colors.red,
    ));
  }

  // showErrorBar displays the grpc error to the user.
  void showHTTPErrorBar(ClientException e) {
    this.showSnackBar(SnackBar(
      content: Text('${e.toString()}'),
      backgroundColor: Colors.red,
    ));
  }

  // showErrorBar displays the grpc error to the user.
  void showOkBar(String content) {
    this.showSnackBar(SnackBar(
      content: Text(content),
      backgroundColor: Colors.green,
    ));
  }

  // showErrorBar displays the grpc error to the user.
  void showLoadingBar() {
    this.showSnackBar(SnackBar(
      content: LinearProgressIndicator(),
      backgroundColor: Theme.of(context).bottomAppBarColor,
    ));
  }
}

String readTimestamp(int timestamp) {
  var now = DateTime.now();
  var format = DateFormat('HH:mm a');
  var date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  var diff = now.difference(date);
  var time = '';

  if (diff.inSeconds <= 0 ||
      diff.inSeconds > 0 && diff.inMinutes == 0 ||
      diff.inMinutes > 0 && diff.inHours == 0 ||
      diff.inHours > 0 && diff.inDays == 0) {
    time = format.format(date);
  } else if (diff.inDays > 0 && diff.inDays < 7) {
    time = diff.inDays.toString() +
        ((diff.inDays == 1) ? ' DAY AGO' : ' DAYS AGO');
  } else {
    time = (diff.inDays / 7).floor().toString() +
        (((diff.inDays / 7).floor() == 1) ? ' WEEK AGO' : ' WEEKS AGO');
  }

  time += '\n' + DateFormat.yMMMd().format(date);

  return time;
}

String formatFileSize(double size) {
  if (size < 1) {
    return (size * 1000).toStringAsFixed(2) + "MB";
  }
  return size.toStringAsFixed(2) + "GB";
}
