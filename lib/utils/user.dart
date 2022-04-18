import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;


class User {
  User();

  static Future<bool> isLoggedIn() async {
    // Create storage
    final prefs = await SharedPreferences.getInstance();

    // Read value
    return prefs.getBool("isLoggedIn") ?? false;
  }

  static Future<String> getJWT() async {
    // Create storages
    const storage = FlutterSecureStorage();

    // Read value
    return await storage.read(key: "jwt") ?? "";
  }

  static Future<String> getServerAddress() async {
    // Create storage
    final prefs = await SharedPreferences.getInstance();

    // Read value
    return prefs.getString("serverAddress") ?? "";
  }

  static Future<String> getEmail() async {
    // Create storage
    final prefs = await SharedPreferences.getInstance();

    // Read value
    return prefs.getString("email") ?? "";
  }

  static Future<bool> tryRegister(String serverAddress, String email, String password) async {
    // Create storages
    const storage = FlutterSecureStorage();
    final prefs = await SharedPreferences.getInstance();

    // Store the data for the user
    await prefs.setString("serverAddress", serverAddress);
    await prefs.setString("email", email);

    // Send a request to the backend with the registration info
    Map<String, String> registrationInfo = {"email": email, "password": password, "first_name": "", "last_name": ""};
    http.Response resp;
    try {
      resp = await http.post(Uri.parse(serverAddress + '/api/v1/user'), body: registrationInfo);
    } on SocketException {
      return false;
    }

    if(resp.statusCode == 200) {
      // Success, do a login now
      return await tryLogIn(serverAddress, email, password);
    } else {
      return false;
    }

  }

  static Future<bool> tryLogIn(String serverAddress, String email, String password) async {
    // Create storages
    const storage = FlutterSecureStorage();
    final prefs = await SharedPreferences.getInstance();

    // Store the data for the user
    await prefs.setString("serverAddress", serverAddress);
    await prefs.setString("email", email);

    // Send a request to the backend with the login info
    Map<String, String> loginInfo = {email: email, password: password};
    http.Response resp;
    try {
      resp = await http.post(Uri.parse(serverAddress + '/api/v1/user/login'), body: loginInfo);
    } on SocketException {
      return false;
    }

    if(resp.statusCode != 200) {
      return false;
    }

    // Success, get JWT
    String jwt = resp.body;

    if(jwt != "") {
      // Write values
      await storage.write(key: "jwt", value: jwt);
      await prefs.setBool("isLoggedIn", true);
      return true;

    } else {
      return false;
    }

  }

  static void logOut() async {
    // Create storages
    const storage = FlutterSecureStorage();
    final prefs = await SharedPreferences.getInstance();

    // Delete jwt auth token
    await storage.delete(key: "jwt");

    // Set isLoggedIn to false
    prefs.setBool("isLoggedIn", false);

  }
}
