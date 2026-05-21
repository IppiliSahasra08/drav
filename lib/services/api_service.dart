// ---------------------------------------------------------------------------
// ApiService — mirrors lib/api.ts from the React Native version exactly.
// Same 4 calls: syncProfile, nextExercise, submitAnswer, getProgress.
// Uses the 'http' package instead of fetch().
// ---------------------------------------------------------------------------

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/exercise.dart';

class ApiService {
  // Singleton so we only build the base URL once
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get _base => dotenv.env['BACKEND_URL'] ?? dotenv.env['API_URL'] ?? '';

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  // POST /auth/sync
  /// Attempts to sync the signed-in user profile with the backend.
  /// Returns true on success, false on failure. Does not throw to avoid
  /// bringing down the UI flow during login.
  Future<bool> syncUserProfile({
    required String userId,
    required String email,
    required String displayName,
    String role = 'child',
    String? username,
    String? preferredLanguage,
    String? learningGoal,
    Map<String, dynamic>? accessibilityMode,
  }) async {
    try {
      final safeUserId = userId.trim();
      final safeEmail = email.trim();
      final safeDisplayName = displayName.trim().isNotEmpty
          ? displayName.trim()
          : (safeEmail.contains('@') ? safeEmail.split('@').first : 'User');
      final safeRole = role.trim().isNotEmpty ? role.trim() : 'child';
      final baseUrl = (dotenv.env['BACKEND_URL'] ?? dotenv.env['API_URL'] ?? '').trim();

      if (safeUserId.isEmpty) {
        debugPrint('syncUserProfile skipped: missing user id');
        return false;
      }

      if (baseUrl.isEmpty) {
        debugPrint('syncUserProfile skipped: missing BACKEND_URL or API_URL in .env');
        return false;
      }

      final uri = Uri.tryParse('$baseUrl/auth/sync');
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        debugPrint('syncUserProfile skipped: invalid backend URL "$baseUrl"');
        return false;
      }

      final Map<String, dynamic> bodyMap = {
        'user_id': safeUserId,
        'email': safeEmail,
        'display_name': safeDisplayName,
        'role': safeRole,
      };
      if (username != null && username.trim().isNotEmpty) bodyMap['username'] = username.trim();
      if (preferredLanguage != null && preferredLanguage.trim().isNotEmpty) bodyMap['preferred_language'] = preferredLanguage.trim();
      if (learningGoal != null && learningGoal.trim().isNotEmpty) bodyMap['learning_goal'] = learningGoal.trim();
      if (accessibilityMode != null) bodyMap['accessibility_mode'] = accessibilityMode;

      final body = jsonEncode(bodyMap);

      debugPrint('syncUserProfile started for user $safeUserId');
      final res = await http.post(
        uri,
        headers: _headers,
        body: body,
      );

      if (res.statusCode != 200) {
        debugPrint('syncUserProfile failed: HTTP ${res.statusCode} ${res.body}');
        return false;
      }

      debugPrint('syncUserProfile succeeded: ${res.body}');
      return true;
    } catch (e, st) {
      debugPrint('syncUserProfile exception: $e');
      debugPrint(st.toString());
      return false;
    }
  }

  // GET /exercises/next?user_id=&language=
  Future<ExerciseBundle> fetchNextExercise({
    required String userId,
    required String language,
  }) async {
    final base = _base.trim();
    if (base.isEmpty) {
      throw Exception('fetchNextExercise failed: BACKEND_URL is not set in .env');
    }

    final uri = Uri.parse('$base/exercises/next')
        .replace(queryParameters: {'user_id': userId, 'language': language});
    try {
      debugPrint('fetchNextExercise: GET $uri');
      final res = await http.get(uri, headers: _headers);
      debugPrint('fetchNextExercise: HTTP ${res.statusCode}');
      debugPrint('fetchNextExercise: body: ${res.body}');

      if (res.statusCode != 200) {
        throw Exception('fetchNextExercise failed: HTTP ${res.statusCode}: ${res.body}');
      }

      // Guard against HTML error pages (e.g., index.html served by webserver)
      final contentType = res.headers['content-type'] ?? '';
      final bodyTrim = res.body.trimLeft();
      if (contentType.toLowerCase().contains('text/html') || bodyTrim.startsWith('<')) {
        throw Exception('fetchNextExercise failed: expected JSON but received HTML/HTML error page');
      }

      final parsed = jsonDecode(res.body);
      if (parsed is! Map<String, dynamic>) {
        throw Exception('fetchNextExercise parse error: expected object, got ${parsed.runtimeType}');
      }

      try {
        return ExerciseBundle.fromJson(parsed as Map<String, dynamic>);
      } catch (e, st) {
        debugPrint('fetchNextExercise: ExerciseBundle.fromJson failed: $e');
        debugPrint(st.toString());
        throw Exception('fetchNextExercise parse error: $e');
      }
    } catch (e) {
      debugPrint('fetchNextExercise exception: $e');
      rethrow;
    }
  }

  // POST /exercises/submit
  Future<Map<String, dynamic>> submitAnswer({
    required String userId,
    required String sessionId,
    required String exerciseId,
    required String answer,
    required bool isCorrect,
    required int responseTimeMs,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/exercises/submit'),
      headers: _headers,
      body: jsonEncode({
        'user_id': userId,
        'session_id': sessionId,
        'exercise_id': exerciseId,
        'answer': answer,
        'is_correct': isCorrect,
        'response_time_ms': responseTimeMs,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('submitAnswer failed: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // GET /progress/:userId
  Future<List<SkillMastery>> fetchProgress(String userId) async {
    final res = await http.get(
      Uri.parse('$_base/progress/$userId'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('fetchProgress failed: ${res.body}');
    }
    final list = jsonDecode(res.body) as List;
    return list.map((e) => SkillMastery.fromJson(e as Map<String, dynamic>)).toList();
  }
}
