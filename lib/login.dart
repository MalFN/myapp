import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:http/http.dart' as http;
import 'home.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  Duration get loginTime => const Duration(milliseconds: 2250);

  Future<String?> _authUser(LoginData data) async {
    final response = await http.post(
      Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyD6Dh2PoIUGRpAoHIHzsyy3i0ZwqVY7h-E'),
      body: json.encode({
        'email': data.name,
        'password': data.password,
        'returnSecureToken': true,
      }),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 200) {
      return null; // Sign-in berhasil
    } else {
      return responseData['error']['message'];
    }
  }

  Future<String?> _signupUser(SignupData data) async {
    final response = await http.post(
      Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyD6Dh2PoIUGRpAoHIHzsyy3i0ZwqVY7h-E'),
      body: json.encode({
        'email': data.name!,
        'password': data.password!,
        'returnSecureToken': true,
      }),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 200) {
      return null; // Sign-up berhasil
    } else {
      return responseData['error']['message'];
    }
  }

  Future<String?> _recoverPassword(String name) async {
    final response = await http.post(
      Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=AIzaSyD6Dh2PoIUGRpAoHIHzsyy3i0ZwqVY7h-E'),
      body: json.encode({
        'requestType': 'PASSWORD_RESET',
        'email': name,
      }),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 200) {
      return null; // Email reset password telah dikirim
    } else {
      return responseData['error']['message'];
    }
  }
  Future<User?> _signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      print('Login dibatalkan oleh pengguna');
      return null;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    print('Access token: ${googleAuth.accessToken}');
    print('ID token: ${googleAuth.idToken}');

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final User? user = userCredential.user;

    if (user != null) {
      print('Login berhasil: ${user.email}');
      return user;
    }
    return null;
  } catch (e) {
    print('Gagal login: $e');
    return null;
  }
}


  @override
   Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'My-INA',
      onLogin: _authUser,
      onSignup: _signupUser,
      loginProviders: <LoginProvider>[
        LoginProvider(
          icon: FontAwesomeIcons.google,
          label: 'Google',
          callback: () async {
            User? user = await _signInWithGoogle();
            if (user != null) {
              return null; // Sign-in berhasil
            } else {
              return 'Login with Google failed';
            }
          },
        ),
      ],
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const Home(),
        ));
      },
      onRecoverPassword: _recoverPassword,
    );
  }
}
