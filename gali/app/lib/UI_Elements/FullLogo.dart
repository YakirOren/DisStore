import 'package:gali/globals.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class FullLogo extends StatefulWidget {
  FullLogo({
    Key key,
  }) : super(key: key);

  @override
  _FullLogoState createState() => _FullLogoState();
}

class _FullLogoState extends State<FullLogo> {

  @override
  Widget build(BuildContext context) {
    bool darkModeOn = Globals.isDarkMode(context);

    return Container(
      height: 200,
      child: SvgPicture.asset(
        darkModeOn
            ? 'assets/icon/galiLogoNoBackgroundWhite.svg'
            : 'assets/icon/galiLogoNoBackgroundBlack.svg',
      ),
    );
  }
}
