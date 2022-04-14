import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;


class User {
  User();

  static Future<bool> isLoggedIn() async {

    // Create storage
    final prefs = await SharedPreferences.getInstance();

    // Read value
    bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

    return isLoggedIn;
  }

  static Future<String> getJWT() async {
    // Create storages
    const storage = FlutterSecureStorage();

    // Read value
    String jwt = await storage.read(key: "jwt") ?? "";

    return jwt;
  }

  static Future<bool> tryLogIn(String serverAddress, String email, String password) async {

    // TODO: Send a request to the backend, get a JWT in return
    Map<String, String> loginInfo = {email: email, password: password};
    http.Response resp = await http.post(Uri.parse(serverAddress + '/login'), body: loginInfo);
    String jwt = "I'm a JWT!";

    if(jwt != "") {

      // Create storages
      const storage = FlutterSecureStorage();
      final prefs = await SharedPreferences.getInstance();

      // Write value
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
