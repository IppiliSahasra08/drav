// ---------------------------------------------------------------------------
// ApiService — mirrors lib/api.ts from the React Native version exactly.
// Same 4 calls: syncProfile, nextExercise, submitAnswer, getProgress.
// Uses the 'http' package instead of fetch().
// ---------------------------------------------------------------------------

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/exercise.dart';

class ApiService {
  // Singleton so we only build the base URL once
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get _base => dotenv.env['BACKEND_URL'] ?? '';

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  // POST /auth/sync
  Future<void> syncUserProfile({
    required String userId,
    required String email,
    required String displayName,
    String role = 'child',
  }) async {
    final res = await http.post(
      Uri.parse('$_base/auth/sync'),
      headers: _headers,
      body: jsonEncode({
        'user_id': userId,
        'email': email,
        'display_name': displayName,
        'role': role,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('syncUserProfile failed: ${res.body}');
    }
  }

  // GET /exercises/next?user_id=&language=
  Future<ExerciseBundle> fetchNextExercise({
    required String userId,
    required String language,
  }) async {
    final uri = Uri.parse('$_base/exercises/next')
        .replace(queryParameters: {'user_id': userId, 'language': language});
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('fetchNextExercise failed: ${res.body}');
    }
    return ExerciseBundle.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
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
