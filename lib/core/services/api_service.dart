import 'package:shared_preferences/shared_preferences.dart';

const String kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'https://online-library-api-muuz.onrender.com',
);

Future<Map<String, String>> authHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('accessToken');
  return {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}