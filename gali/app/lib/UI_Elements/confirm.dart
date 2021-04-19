import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    Key key,
    this.danger = false,
    this.title,
    this.actions,
    this.content,
    this.actionText,
    this.cancelFunction,
    this.actionFunction,
  }) : super(key: key);

  final bool danger;
  final String title;
  final Text actionText;
  final Text content;
  final Function() cancelFunction;
  final Function() actionFunction;

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIOS) {
      return CupertinoAlertDialog(

        title: Text(title, style: TextStyle(color: Colors.black)),
        content: content,
        actions: <Widget>[
          CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: cancelFunction,
              child: Text("Cancel")),
          CupertinoDialogAction(
            textStyle: danger ? TextStyle(color: Colors.red) : TextStyle(),
            isDefaultAction: true,
            onPressed: actionFunction,
            child: actionText,
          ),
        ],
      );
    } else {
      return AlertDialog(
        title: Center(child:Text(this.title, style: TextStyle(color: Theme.of(context).highlightColor))),
        backgroundColor: Theme.of(context).backgroundColor,
        content: content,
        actions: [

          TextButton(onPressed: cancelFunction,
              child: Text("Cancel")),

          TextButton(
            onPressed: actionFunction,
              child: actionText),


        ],
      );
    }
  }
}
