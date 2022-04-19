import 'dart:convert';
import 'dart:developer';
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

  static Future<String> getFirstName() async {
    // Create storage
    final prefs = await SharedPreferences.getInstance();

    // Read value
    return prefs.getString("firstName") ?? "";
  }

  static Future<String> getLastName() async {
    // Create storage
    final prefs = await SharedPreferences.getInstance();

    // Read value
    return prefs.getString("lastName") ?? "";
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
    log(registrationInfo.toString());
    http.Response resp;
    try {
      resp = await http.post(Uri.parse(serverAddress + '/api/v1/user'),
          body: registrationInfo,
      );
    } on SocketException {
      log("Registration socket exception");
      return false;
    }

    if(resp.statusCode == 200) {
      // Success, do a login now
      log("Registration success");
      return await tryLogIn(serverAddress, email, password);
    } else {
      log("Non 200 registration status code: " + resp.statusCode.toString());
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
    Map<String, String> loginInfo = {"email": email, "password": password};
    http.Response resp;
    try {
      resp = await http.post(Uri.parse(serverAddress + '/api/v1/user/login'),
        body: loginInfo,
      );
    } on SocketException {
      log("Login socket exception");
      return false;
    }

    if(resp.statusCode != 200) {
      log("Non 200 login status code: " + resp.statusCode.toString());
      return false;
    }

    // Success, get JWT
    log("Login Success");
    String jwt = resp.body;
    log("JWT: " + jwt);

    if(jwt != "") {
      // Write values
      await storage.write(key: "jwt", value: jwt);
      await prefs.setBool("isLoggedIn", true);
      return true;

    } else {
      return false;
    }

  }

  static Future<bool> setAccountInfo(String firstName, String lastName, String email, String password) async {
    // Create storages
    final prefs = await SharedPreferences.getInstance();
    String serverAddress = await User.getServerAddress();
    String jwt = await User.getJWT();

    // Send a request to the backend with the updated info info
    Map<String, String> accountInfo;
    if(password != "") {
      accountInfo = {"first_name": firstName, "last_name": lastName, "email": email, "password": password};
    } else {
      accountInfo = {"first_name": firstName, "last_name": lastName, "email": email};
    }
    http.Response resp;
    try {
      resp = await http.put(Uri.parse(serverAddress + '/api/v1/user'),
          headers: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt },
          body: accountInfo,
      );
    } on SocketException {
      log("updateAccountInfo socket exception");
      return false;
    }

    if(resp.statusCode != 200) {
      log("updateAccountInfo Non 200 status code: " + resp.statusCode.toString());
      return false;
    }

    // Success, save info
    await prefs.setString("email", email);
    await prefs.setString("firstName", firstName);
    await prefs.setString("lastName", lastName);
    return true;
  }

  static Future<bool> getAccountInfo() async {
    // Create storages
    final prefs = await SharedPreferences.getInstance();
    String serverAddress = await User.getServerAddress();
    String jwt = await User.getJWT();

    // Send a request to the backend to get the updated info
    http.Response resp;
    try {
      resp = await http.get(Uri.parse(serverAddress + '/api/v1/user'),
        headers: { HttpHeaders.authorizationHeader: 'Bearer ' + jwt },);

      if(resp.statusCode != 200) {
        log("getAccountInfo Non 200 status code: " + resp.statusCode.toString());
        return false;

      } else {
        final data = jsonDecode(resp.body);
        log(data.toString());

        // Success, save info
        await prefs.setString("email", data["email"]);
        await prefs.setString("firstName", data["first_name"]);
        await prefs.setString("lastName", data["last_name"]);
        return true;
      }

    } on SocketException {
      log("getAccountInfo socket exception");
      return false;
    }

  }

  static void logOut() async {
    // Create storages
    const storage = FlutterSecureStorage();
    final prefs = await SharedPreferences.getInstance();

    // Delete account information
    await storage.delete(key: "jwt");
    await storage.delete(key: "firstName");
    await storage.delete(key: "lastName");

    // Set isLoggedIn to false
    prefs.setBool("isLoggedIn", false);
  }
}
