import 'package:flutter_secure_storage/flutter_secure_storage.dart';



class User {
  User();

  static bool isLoggedIn() {
    return false;
  }

  static bool tryLogIn(String email, String password) {
    // TODO: Send a request to the backend, get a JWT in return
    String jwt = "I'm a JWT!";


    return false;
  }

  static void logOut() {

  }
}
