import 'package:gali/Screens/LoginPage.dart';
import 'package:gali/UI_Elements/AppButton.dart';
import 'package:gali/UI_Elements/AppInputField.dart';
import 'package:gali/UI_Elements/FullLogo.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:gali/helpers.dart';
import 'package:gali/globals.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Center(
          child: SingleChildScrollView(
              child: Column(children: <Widget>[
        SizedBox(height: 45.0),
        FullLogo(),
        SizedBox(height: 45.0),
        MyForm(),
      ]))),
    );
  }
}

class MyForm extends StatefulWidget {
  @override
  _MyFormState createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final confirmEmailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    confirmEmailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    TextStyle style = TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 20.0,
        color: Theme.of(context).highlightColor);

    return Form(
        key: _formKey,
        child: Container(
            child: Padding(
                padding:
                    EdgeInsets.only(left: 36, right: 36, bottom: 36, top: 0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppInputField(
                        placeholderText: 'First Name',
                        title: 'First Name',
                        controller: firstNameController,
                        textInputAction: TextInputAction.next,
                        inputType: TextInputType.name,
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10.0),
                      AppInputField(
                        placeholderText: 'Last Name',
                        title: 'Last Name',
                        controller: lastNameController,
                        textInputAction: TextInputAction.next,
                        inputType: TextInputType.name,
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 25.0),
                      AppInputField(
                        placeholderText: 'Email',
                        title: 'Email Address',
                        controller: emailController,
                        textInputAction: TextInputAction.next,
                        inputType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10.0),
                      AppInputField(
                        placeholderText: 'Confirm Email',
                        title: 'Confirm Email Address',
                        controller: confirmEmailController,
                        textInputAction: TextInputAction.next,
                        inputType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter some text';
                          }
                          if (value != emailController.text) {
                            return 'No no, email not match';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 25.0),
                      AppInputField(
                        placeholderText: 'Password',
                        title: 'Password',
                        controller: passwordController,
                        textInputAction: TextInputAction.next,
                        obscureText: true,
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10.0),
                      AppInputField(
                        placeholderText: 'Confirm Password',
                        title: 'Confirm Password',
                        controller: confirmPasswordController,
                        textInputAction: TextInputAction.next,
                        obscureText: true,
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter some text';
                          }
                          if (value != passwordController.text) {
                            return 'No no, password not match';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10.0),
                      Center(
                        child: Card(
                          color: Theme.of(context).backgroundColor,
                          shadowColor: Theme.of(context).highlightColor,
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: RichText(
                              text: TextSpan(
                                style: style.copyWith(fontSize: 15),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: 'Password Requirements:\n',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                  TextSpan(
                                      text:
                                          '∙ minumum length of 5 characters\n'),
                                  TextSpan(
                                      text:
                                          '∙ password must contains at least 1 special character ~<=>+-@!#\$%^&* \n'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Material(
                          elevation: 5.0,
                          borderRadius: BorderRadius.circular(30.0),
                          color: Color(0xff01A0C7),
                          child: AppButton(
                            text: "Register",
                            isLoading: _loading,
                            clickFunction: () async {
                              if (_formKey.currentState.validate()) {
                                try {
                                  setState(() {
                                    _loading = true;
                                  });
                                  await Globals.client.register(
                                      firstNameController.text,
                                      lastNameController.text,
                                      emailController.text,
                                      passwordController.text);
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (context) {
                                      return LoginPage();
                                    }),
                                  );
                                } catch (e) {
                                  setState(() {
                                    _loading = false;
                                  });

                                  ScaffoldMessenger.of(context).showErrorBar(e);
                                }
                              }
                            },
                          ),
                        ),
                      ),
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                              child: RichText(
                            text: TextSpan(
                              style: style,
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'Already registered? ',
                                  style: style.copyWith(
                                      color: Theme.of(context).hintColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: style.fontSize / 1.5),
                                ),
                                TextSpan(
                                    text: 'Login',
                                    style: style.copyWith(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: style.fontSize / 1.5),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.pop(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  LoginPage()),
                                        );
                                      }),
                              ],
                            ),
                          ))),
                    ],
                  ),
                ))));
  }
}
