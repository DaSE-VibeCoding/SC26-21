import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/chat_models.dart';

class LocalStoreService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _sessionsKey = 'yuxin_sessions';
  static const String _memoryKey = 'yuxin_memory';

  Future<AppSnapshot> loadSnapshot() async {
    try {
      final String? sessionsRaw = await _storage.read(key: _sessionsKey);
      final String? memoryRaw = await _storage.read(key: _memoryKey);

      final List<ChatSession> sessions = sessionsRaw == null || sessionsRaw.isEmpty
          ? <ChatSession>[]
          : (jsonDecode(sessionsRaw) as List<dynamic>)
              .map((dynamic item) => ChatSession.fromJson(item as Map<String, dynamic>))
              .toList();

      final UserMemory memory = memoryRaw == null || memoryRaw.isEmpty
          ? UserMemory.empty()
          : UserMemory.fromJson(jsonDecode(memoryRaw) as Map<String, dynamic>);

      return AppSnapshot(sessions: sessions, memory: memory);
    } catch (_) {
      return AppSnapshot(sessions: const <ChatSession>[], memory: UserMemory.empty());
    }
  }

  Future<void> saveSessions(List<ChatSession> sessions) async {
    try {
      await _storage.write(
        key: _sessionsKey,
        value: jsonEncode(sessions.map((ChatSession item) => item.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> saveMemory(UserMemory memory) async {
    try {
      await _storage.write(key: _memoryKey, value: jsonEncode(memory.toJson()));
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      await _storage.delete(key: _sessionsKey);
      await _storage.delete(key: _memoryKey);
    } catch (_) {}
  }
}
