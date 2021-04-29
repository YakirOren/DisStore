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
    return Container(
      height: 200,
      child: SvgPicture.asset('assets/icon/Distore2.svg'),
    );
  }
}
