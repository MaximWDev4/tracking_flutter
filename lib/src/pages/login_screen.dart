import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracking_flutter/backend-helper/func.dart';
import '../Widgets/login_screen/flutter_login.dart';
import 'package:tracking_flutter/src/pages/map.dart';
import '../custom_route.dart';
import 'package:loader_overlay/loader_overlay.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/auth';
  @override
  State<StatefulWidget> createState() {
    return LoginScreenState();
  }
}

class LoginScreenState extends State<LoginScreen> {
  SharedPreferences prefs;
  Duration get loginTime => Duration(milliseconds: timeDilation.ceil() * 2250);
  LoginScreenState();
  @override
  void initState() {
    context.showLoaderOverlay();
    try {
      Func.logIn(pw: 'alex', un: 'alex')
          .then((value) {
        setState(() {
          context.hideLoaderOverlay();
        });
        if (value == null) {
          Navigator.pushNamedAndRemoveUntil(
              context, MapPage.route, (route) => false);
        } else {
          Get.rawSnackbar(message: value,);
        }
      }).catchError((error) => Get.rawSnackbar(message: "Ошибка"));
    }
    catch(onError) {
      Get.rawSnackbar(message: onError);
    }
    super.initState();
  }

  @override
  Future<String> _loginUser(LoginData data) {
    f() async{
      prefs = await SharedPreferences.getInstance();
    }
    f();
      return Func.logIn(pw: data.password, un: data.name);
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'Вход',
      logo: 'assets/find.png',
      // logoTag: 'Constants.logoTag',
      // titleTag: 'Constants.titleTag',
      // loginAfterSignUp: false,
      hideForgotPasswordButton: true,
      hideSignUpButton: true,
      messages: LoginMessages(
        usernameHint: 'Имя',
        passwordHint: 'Пароль',
      //   confirmPasswordHint: 'Confirm',
        loginButton: 'Войти',
      //   signupButton: 'REGISTER',
      //   forgotPasswordButton: '',
      //   recoverPasswordButton: 'HELP ME',
      //   goBackButton: 'GO BACK',
      //   confirmPasswordError: 'Not match!',
      //   recoverPasswordIntro: 'Don\'t feel bad. Happens all the time.',
      //   recoverPasswordDescription: 'Lorem Ipsum is simply dummy text of the printing and typesetting industry',
      //   recoverPasswordSuccess: 'Password rescued successfully',
      //   flushbarTitleError: 'Oh no!',
      //   flushbarTitleSuccess: 'Succes!',
      ),
      // theme: LoginTheme(
      //   primaryColor: Colors.teal,
      //   accentColor: Colors.yellow,
      //   errorColor: Colors.deepOrange,
      //   pageColorLight: Colors.indigo.shade300,
      //   pageColorDark: Colors.indigo.shade500,
      //   titleStyle: TextStyle(
      //     color: Colors.greenAccent,
      //     fontFamily: 'Quicksand',
      //     letterSpacing: 4,
      //   ),
      //   // beforeHeroFontSize: 50,
      //   // afterHeroFontSize: 20,
      //   bodyStyle: TextStyle(
      //     fontStyle: FontStyle.italic,
      //     decoration: TextDecoration.underline,
      //   ),
      //   textFieldStyle: TextStyle(
      //     color: Colors.orange,
      //     shadows: [Shadow(color: Colors.yellow, blurRadius: 2)],
      //   ),
      //   buttonStyle: TextStyle(
      //     fontWeight: FontWeight.w800,
      //     color: Colors.yellow,
      //   ),
      //   cardTheme: CardTheme(
      //     color: Colors.yellow.shade100,
      //     elevation: 5,
      //     margin: EdgeInsets.only(top: 15),
      //     shape: ContinuousRectangleBorder(
      //         borderRadius: BorderRadius.circular(100.0)),
      //   ),
      //   inputTheme: InputDecorationTheme(
      //     filled: true,
      //     fillColor: Colors.purple.withOpacity(.1),
      //     contentPadding: EdgeInsets.zero,
      //     errorStyle: TextStyle(
      //       backgroundColor: Colors.orange,
      //       color: Colors.white,
      //     ),
      //     labelStyle: TextStyle(fontSize: 12),
      //     enabledBorder: UnderlineInputBorder(
      //       borderSide: BorderSide(color: Colors.blue.shade700, width: 4),
      //       borderRadius: inputBorder,
      //     ),
      //     focusedBorder: UnderlineInputBorder(
      //       borderSide: BorderSide(color: Colors.blue.shade400, width: 5),
      //       borderRadius: inputBorder,
      //     ),
      //     errorBorder: UnderlineInputBorder(
      //       borderSide: BorderSide(color: Colors.red.shade700, width: 7),
      //       borderRadius: inputBorder,
      //     ),
      //     focusedErrorBorder: UnderlineInputBorder(
      //       borderSide: BorderSide(color: Colors.red.shade400, width: 8),
      //       borderRadius: inputBorder,
      //     ),
      //     disabledBorder: UnderlineInputBorder(
      //       borderSide: BorderSide(color: Colors.grey, width: 5),
      //       borderRadius: inputBorder,
      //     ),
      //   ),
      //   buttonTheme: LoginButtonTheme(
      //     splashColor: Colors.purple,
      //     backgroundColor: Colors.pinkAccent,
      //     highlightColor: Colors.lightGreen,
      //     elevation: 9.0,
      //     highlightElevation: 6.0,
      //     shape: BeveledRectangleBorder(
      //       borderRadius: BorderRadius.circular(10),
      //     ),
      //     // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      //     // shape: CircleBorder(side: BorderSide(color: Colors.green)),
      //     // shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(55.0)),
      //   ),
      // ),
      emailValidator: (value) {
        if (value.isEmpty) {
          return "Имя необходимо";
        }
        return null;
      },
      passwordValidator: (value) {
        if (value.isEmpty) {
          return 'Пароль необходим';
        }
        return null;
      },
      onLogin: (loginData) {
        return _loginUser(loginData);
      },
      onSignup: (loginData) {
        return _loginUser(loginData);
      },
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(FadePageRoute(
          builder: (context) => MapPage(),
        ));
      },
      onRecoverPassword: (a)  async {
        return '';
      },
      // showDebugButtons: true,
    );
  }
}
