import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  AppButton({
    Key key,
    this.text,
    this.icon,
    this.isLoading = false,
    this.clickFunction,
  }) : super(key: key);

  final String text;
  final Icon icon;
  final bool isLoading;
  final Function() clickFunction;

  @override
  Widget build(BuildContext context) {
    TextStyle style = TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 20.0,
        color: Theme.of(context).highlightColor);

    List<Widget> children = [];

    if (icon != null) {
      children.add(icon);
    }
    children.add(!isLoading
        ? Text(text,
            textAlign: TextAlign.center,
            style: style.copyWith(
                color: Theme.of(context).accentColor,
                fontWeight: FontWeight.bold))
        : CupertinoActivityIndicator());

    return Material(
        color: Theme.of(context).primaryColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: MaterialButton(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            minWidth: MediaQuery.of(context).size.width,
            padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
            onPressed: () async {
              clickFunction?.call();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            )));
  }
}
