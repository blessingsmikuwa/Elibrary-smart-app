import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OfflineBooksService {
  static const _metaKey = 'offline_books_meta';

  // Returns the local file path for a saved book, or null if not saved
  static Future<String?> getLocalPath(String bookId) async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/books/$bookId.pdf');
    return file.existsSync() ? file.path : null;
  }

  static Future<bool> isSaved(String bookId) async {
    final path = await getLocalPath(bookId);
    return path != null;
  }

  // Save a book locally from its URL
  static Future<void> saveBook({
    required String bookId,
    required String title,
    required String fileUrl,
    void Function(double)? onProgress,
  }) async {
    final dir       = Directory('${(await getApplicationDocumentsDirectory()).path}/books');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final file      = File('${dir.path}/$bookId.pdf');
    final client    = http.Client();
    try {
      final request  = http.Request('GET', Uri.parse(fileUrl));
      final response = await client.send(request);
      final total    = response.contentLength ?? 0;
      int   received = 0;
      final sink     = file.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
      await sink.close();
    } catch (e) {
      if (file.existsSync()) file.deleteSync();
      rethrow;
    } finally {
      client.close();
    }
    // Save metadata
    await _saveMeta(bookId, title);
  }

  static Future<void> removeBook(String bookId) async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/books/$bookId.pdf');
    if (file.existsSync()) file.deleteSync();
    await _removeMeta(bookId);
  }

  static Future<List<Map<String, dynamic>>> getSavedBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_metaKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  static Future<void> _saveMeta(String bookId, String title) async {
    final prefs = await SharedPreferences.getInstance();
    final list  = await getSavedBooks();
    if (!list.any((b) => b['id'] == bookId)) {
      list.add({'id': bookId, 'title': title, 'savedAt': DateTime.now().toIso8601String()});
      await prefs.setString(_metaKey, jsonEncode(list));
    }
  }

  static Future<void> _removeMeta(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final list  = await getSavedBooks();
    list.removeWhere((b) => b['id'] == bookId);
    await prefs.setString(_metaKey, jsonEncode(list));
  }
}