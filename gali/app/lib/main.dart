import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gali/Screens/LoginPage.dart';
import 'package:gali/UI_Elements/FullLogo.dart';

import 'package:gali/globals.dart';
import 'secure_storage.dart';
import 'Screens/AppBase.dart';
import 'package:gali/helpers.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(
    ProviderScope(child: MyApp()),
  );
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).backgroundColor,
      child: FullLogo(),
    );
  }
}

/// This is the main application widget.
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoggedUser = null;
  Future<bool> aaa;

  @override
  void initState() {
    super.initState();

    // get what theme to show the user.
    SecureStorage.readSecureData('ThemeIndex').then((index) {
      if (index != null) {
        context.read(themeMode.notifier).updateThemeMode(int.parse(index));
      }
    });

    // try logging in using stored key.
    aaa = client.loginWithRefresh();
  }

  @override
  Widget build(BuildContext context) {
    // this gesture detector allows as to click out side the keyboard to dismiss it.
    return GestureDetector(onTap: () {
      FocusScopeNode currentFocus = FocusScope.of(context);
      if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
        currentFocus.focusedChild.unfocus();
      }
    }, child: Consumer(builder: (context, watch, _) {
      final theme = watch(themeMode);
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: theme,
        // this is the theme of the app.
        darkTheme: ThemeData(
          unselectedWidgetColor: Colors.white,
          accentColor: Colors.white,
          primarySwatch: Colors.white.createMaterialColor(),

          hintColor: Colors.white30,
          primaryColor: Color(0xFF2A2D3E),
          //primaryColor: Colors.white,

          inputDecorationTheme:
              InputDecorationTheme(fillColor: Color(0xFF2A2D3E)),

          visualDensity: VisualDensity.adaptivePlatformDensity,
          highlightColor: Colors.white,

          iconTheme: IconThemeData(color: Colors.white),
          primaryIconTheme: IconThemeData(color: Colors.white),
          bottomAppBarColor: Color(0xFF2A2D3E),
          textTheme: TextTheme(
            headline1: GoogleFonts.roboto(
                fontWeight: FontWeight.w300,
                fontSize: 96,
                letterSpacing: -1.5,
                color: Colors.white),
            bodyText1: GoogleFonts.roboto(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                letterSpacing: 0.5,
                color: Colors.white),
            bodyText2: GoogleFonts.roboto(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                letterSpacing: 0.25,
                color: Colors.white),
            subtitle1: GoogleFonts.roboto(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                letterSpacing: 0.25,
                color: Colors.white),
            subtitle2: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.25,
                color: Colors.white),
          ),
          //backgroundColor: const Color(0xff2c4260),
          backgroundColor: Color(0xFF212332),
        ),

        theme: ThemeData(
            unselectedWidgetColor: Colors.black,
            primaryColor: Color(0xff7289DA),
            hintColor: Colors.black26,
            inputDecorationTheme: InputDecorationTheme(fillColor: Colors.white),
            accentColor: Color(0xff7289DA),
            highlightColor: Colors.grey,
            bottomAppBarColor: Colors.white,
            primarySwatch: Color(0xff7289DA).createMaterialColor(),

            //iconTheme: IconThemeData(color: Colors.grey) ,
            //primaryIconTheme: IconThemeData(color: Colors.grey),
            textTheme: TextTheme(
              headline1: GoogleFonts.roboto(
                  fontWeight: FontWeight.w300,
                  fontSize: 22,
                  letterSpacing: -1.5),
              headline2: GoogleFonts.roboto(
                  color: Colors.black,
                  fontWeight: FontWeight.w300,
                  fontSize: 22,
                  letterSpacing: -0.5),
              bodyText1: GoogleFonts.roboto(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  letterSpacing: 0.5),
              bodyText2: GoogleFonts.roboto(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  letterSpacing: 0.25),
              subtitle1: GoogleFonts.roboto(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  letterSpacing: 0.25),
              subtitle2: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.25),
            ),
            backgroundColor: Color(0xfff7f7f7)),
        home: FutureBuilder(
          //initialData:,
          future: aaa,
          builder: (context, AsyncSnapshot<bool> snapshot) {

            if (snapshot.hasData) {
              // log the user
              if (snapshot.data == true) {
                return AppBase();
              }
              return LoginPage();
            } else {
              return SplashScreen();
            }
          }
        ),
      );
    }));
  }
}
