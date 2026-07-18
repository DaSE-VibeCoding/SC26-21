import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/chat_models.dart';

class LocalStoreService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _sessionsKey = 'yuxin_sessions';
  static const String _memoryKey = 'yuxin_memory';
  static const String _moodEntriesKey = 'yuxin_mood_entries';
  static const String _responsePreferenceKey = 'yuxin_response_preference';
  static const String _reminderSettingsKey = 'yuxin_reminder_settings';

  Future<AppSnapshot> loadSnapshot() async {
    try {
      final String? sessionsRaw = await _storage.read(key: _sessionsKey);
      final String? memoryRaw = await _storage.read(key: _memoryKey);
      final String? moodEntriesRaw = await _storage.read(key: _moodEntriesKey);
      final String? responsePreferenceRaw = await _storage.read(key: _responsePreferenceKey);
      final String? reminderSettingsRaw = await _storage.read(key: _reminderSettingsKey);

      final List<ChatSession> sessions = sessionsRaw == null || sessionsRaw.isEmpty
          ? <ChatSession>[]
          : (jsonDecode(sessionsRaw) as List<dynamic>)
              .map((dynamic item) => ChatSession.fromJson(item as Map<String, dynamic>))
              .toList();

      final UserMemory memory = memoryRaw == null || memoryRaw.isEmpty
          ? UserMemory.empty()
          : UserMemory.fromJson(jsonDecode(memoryRaw) as Map<String, dynamic>);

      final List<MoodEntry> moodEntries = moodEntriesRaw == null || moodEntriesRaw.isEmpty
          ? <MoodEntry>[]
          : (jsonDecode(moodEntriesRaw) as List<dynamic>)
              .map((dynamic item) => MoodEntry.fromJson(item as Map<String, dynamic>))
              .toList();

      final ResponsePreference responsePreference =
          responsePreferenceRaw == null || responsePreferenceRaw.isEmpty
              ? ResponsePreference.defaults()
              : ResponsePreference.fromJson(
                  jsonDecode(responsePreferenceRaw) as Map<String, dynamic>,
                );

      final ReminderSettings reminderSettings =
          reminderSettingsRaw == null || reminderSettingsRaw.isEmpty
              ? ReminderSettings.defaults()
              : ReminderSettings.fromJson(
                  jsonDecode(reminderSettingsRaw) as Map<String, dynamic>,
                );

      return AppSnapshot(
        sessions: sessions,
        memory: memory,
        moodEntries: moodEntries,
        responsePreference: responsePreference,
        reminderSettings: reminderSettings,
      );
    } catch (_) {
      return AppSnapshot(
        sessions: const <ChatSession>[],
        memory: UserMemory.empty(),
        moodEntries: const <MoodEntry>[],
        responsePreference: ResponsePreference.defaults(),
        reminderSettings: ReminderSettings.defaults(),
      );
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

  Future<void> saveMoodEntries(List<MoodEntry> moodEntries) async {
    try {
      await _storage.write(
        key: _moodEntriesKey,
        value: jsonEncode(moodEntries.map((MoodEntry item) => item.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> saveResponsePreference(ResponsePreference preference) async {
    try {
      await _storage.write(
        key: _responsePreferenceKey,
        value: jsonEncode(preference.toJson()),
      );
    } catch (_) {}
  }

  Future<void> saveReminderSettings(ReminderSettings settings) async {
    try {
      await _storage.write(
        key: _reminderSettingsKey,
        value: jsonEncode(settings.toJson()),
      );
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      await _storage.delete(key: _sessionsKey);
      await _storage.delete(key: _memoryKey);
      await _storage.delete(key: _moodEntriesKey);
      await _storage.delete(key: _responsePreferenceKey);
      await _storage.delete(key: _reminderSettingsKey);
    } catch (_) {}
  }
}
