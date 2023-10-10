import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;


class User {
  User();

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("isLoggedIn") ?? false;
  }

  static Future<String> getJWT() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: "jwt") ?? "";
  }

  static Future<String> getServerAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("serverAddress") ?? "";
  }

  static Future<String> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("email") ?? "";
  }

  static Future<String> getFirstName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("firstName") ?? "";
  }

  static Future<String> getLastName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("lastName") ?? "";
  }

  static String parseServerAddress(String serverAddress) {
    // Modify serverAddress if necessary
    if(!(serverAddress.contains("http://") || serverAddress.contains("https://"))) {
      serverAddress = "https://" + serverAddress;
    }
    if(serverAddress[serverAddress.length - 1] == "/") {
      serverAddress = serverAddress.substring(0, serverAddress.length - 1);
    }
    return serverAddress;
  }

  static Future<bool> tryRegister(String serverAddress, String email, String password) async {
    // Create storage
    final prefs = await SharedPreferences.getInstance();

    // Parse the server address to ensure the format is usable
    serverAddress = parseServerAddress(serverAddress);

    // Store the data for the user
    await prefs.setString("serverAddress", serverAddress);
    await prefs.setString("email", email);

    // Send a request to the backend with the registration info
    Map<String, String> registrationInfo = {"email": email, "password": password, "first_name": "", "last_name": ""};
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

    // Parse the server address to ensure the format is usable
    serverAddress = parseServerAddress(serverAddress);

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
    await prefs.setString("firstName", "");
    await prefs.setString("lastName", "");
    await prefs.setString("recentlyUploaded", "");
    await prefs.setString("localMediaFolders", "");

    // Set isLoggedIn to false
    prefs.setBool("isLoggedIn", false);
  }
}
