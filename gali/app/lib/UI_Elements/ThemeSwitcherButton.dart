import 'package:flutter/material.dart';
import 'package:gali/globals.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeButton extends StatefulWidget {
  @override
  _ThemeButtonState createState() => _ThemeButtonState();
}

class _ThemeButtonState extends State<ThemeButton> {
  /// The corresponding selection state of each toggle button.
  ///
  /// Each value in this list represents the selection state of the [children]
  /// widget at the same index.
  ///
  /// The length of [isSelected] has to match the length of [children].
  List<bool> isSelected = List.generate(3, (_) => false);

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      children: <Widget>[
        FittedBox(
          child: Text(
            "🌚",
            style: TextStyle(fontSize: 30),
          ),
          fit: BoxFit.cover,
        ),
        FittedBox(
          child: Text(
            "🌞",
            style: TextStyle(fontSize: 30),
          ),
          fit: BoxFit.fill,
        ),
        FittedBox(
          child: Text(
            "auto",
            style: TextStyle(fontSize: 30),
          ),
          fit: BoxFit.fill,
        ),
      ],
      onPressed: (int index) {
        updateSelected(index);

        context.read(themeMode.notifier).updateThemeMode(index);
      },
      borderRadius: BorderRadius.circular(15),
      isSelected: isSelected,
      selectedBorderColor: Theme.of(context).highlightColor,
      borderColor: Theme.of(context).highlightColor,
      color: Theme.of(context).highlightColor,
    );
  }

  

  /// Here is an implementation that requires mutually exclusive selection while requiring at least one selection.
  /// Note that this assumes that isSelected was properly initialized with one selection.
  ///
  /// Taken from [https://api.flutter.dev/flutter/material/ToggleButtons-class.html]
  void updateSelected(int index) {
    setState(() {
      for (int buttonIndex = 0;
          buttonIndex < isSelected.length;
          buttonIndex++) {
        if (buttonIndex == index) {
          isSelected[buttonIndex] = true;
        } else {
          isSelected[buttonIndex] = false;
        }
      }
    });
  }
}
