import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String selectedLanguage = "en"; // Default English

  @override
  void initState() {
    super.initState();
    loadLanguagePreference();
  }

  Future<void> loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedLanguage = prefs.getString("language") ?? "en";
    });
  }

  Future<void> saveLanguagePreference(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("language", lang);
  }

  void onLanguageChanged(String lang) {
    setState(() {
      selectedLanguage = lang;
    });
    saveLanguagePreference(lang);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButton<String>(
              value: selectedLanguage,
              items: [
                DropdownMenuItem(value: "en", child: Text("English")),
                DropdownMenuItem(value: "ta", child: Text("தமிழ்")),
              ],
              onChanged: (value) {
                if (value != null) onLanguageChanged(value);
              },
            ),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText:
                    selectedLanguage == "ta" ? "பயனர் பெயர்" : "Username",
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: selectedLanguage == "ta" ? "கடவுச்சொல்" : "Password",
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => HomeScreen(language: selectedLanguage),
                  ),
                );
              },
              child: Text(selectedLanguage == "ta" ? "உள்நுழைய" : "Login"),
            ),
          ],
        ),
      ),
    );
  }
}
