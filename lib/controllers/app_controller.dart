import 'package:flutter/material.dart';

import '../models/chat_models.dart';
import '../services/companion_service.dart';
import '../services/crisis_support_service.dart';
import '../services/local_store_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    required LocalStoreService store,
    required CompanionService companionService,
  })  : _store = store,
        _companionService = companionService;

  final LocalStoreService _store;
  final CompanionService _companionService;
  final CrisisSupportService _crisisService = CrisisSupportService();

  bool isBootstrapping = true;
  bool isSending = false;
  bool isSavingMood = false;
  int currentTabIndex = 0;
  CompanionMode selectedMode = CompanionMode.general;
  String? activeSessionId;
  MoodType selectedMood = MoodType.tired;
  UserMemory memory = UserMemory.empty();
  ResponsePreference responsePreference = ResponsePreference.defaults();
  ReminderSettings reminderSettings = ReminderSettings.defaults();
  List<ChatSession> sessions = <ChatSession>[];
  List<MoodEntry> moodEntries = <MoodEntry>[];
  String? latestSafetyAlert;

  ChatSession get activeSession {
    final ChatSession? existing = _sessionById(activeSessionId);
    if (existing != null) {
      return existing;
    }

    final ChatSession? latestForMode = _latestSessionForMode(selectedMode);
    if (latestForMode != null) {
      return latestForMode;
    }

    return _buildDraftSession(selectedMode);
  }

  MoodEntry? get latestMoodEntry {
    if (moodEntries.isEmpty) {
      return null;
    }
    return moodEntries.first;
  }

  List<MoodEntry> get recentMoodEntries {
    return moodEntries.take(7).toList();
  }

  List<String> get memoryHighlights {
    final List<String> items = <String>[];
    if (memory.lastMoodSummary.isNotEmpty) {
      items.add(memory.lastMoodSummary);
    }
    items.addAll(memory.triggers.map((String item) => '压力点：$item'));
    items.addAll(memory.comfortTopics.map((String item) => '缓和线索：$item'));
    items.addAll(memory.preferences.map((String item) => '偏好：$item'));
    return items.take(6).toList();
  }

  Future<void> bootstrap() async {
    final AppSnapshot snapshot = await _store.loadSnapshot();
    sessions = snapshot.sessions;
    memory = snapshot.memory;
    moodEntries = snapshot.moodEntries
      ..sort((MoodEntry a, MoodEntry b) => b.createdAt.compareTo(a.createdAt));
    responsePreference = snapshot.responsePreference;
    reminderSettings = snapshot.reminderSettings;
    if (sessions.isNotEmpty) {
      activeSessionId = sessions.first.id;
      selectedMode = sessions.first.mode;
    }
    if (moodEntries.isNotEmpty) {
      selectedMood = moodEntries.first.mood;
    }
    isBootstrapping = false;
    notifyListeners();
  }

  void switchTab(int index) {
    currentTabIndex = index;
    notifyListeners();
  }

  void selectMode(CompanionMode mode) {
    selectedMode = mode;
    activeSessionId = _latestSessionForMode(mode)?.id;
    currentTabIndex = 1;
    notifyListeners();
  }

  void selectMood(MoodType mood) {
    selectedMood = mood;
    notifyListeners();
  }

  Future<void> startNewSession([CompanionMode? mode]) async {
    final CompanionMode targetMode = mode ?? selectedMode;
    selectedMode = targetMode;

    final DateTime now = DateTime.now();
    final ChatSession created = ChatSession(
      id: 'session_${targetMode.name}_${now.microsecondsSinceEpoch}',
      mode: targetMode,
      createdAt: now,
      updatedAt: now,
      messages: <ChatMessage>[
        ChatMessage(
          id: 'welcome_${targetMode.name}_${now.microsecondsSinceEpoch}',
          sender: Sender.assistant,
          text: targetMode.starterPrompt,
          timestamp: now,
          mode: targetMode,
        ),
      ],
    );

    activeSessionId = created.id;
    sessions = <ChatSession>[created, ...sessions];
    currentTabIndex = 1;
    await _persist();
    notifyListeners();
  }

  void openSession(String sessionId) {
    final ChatSession? session = _sessionById(sessionId);
    if (session == null) {
      return;
    }
    activeSessionId = session.id;
    selectedMode = session.mode;
    currentTabIndex = 1;
    notifyListeners();
  }

  Future<void> sendMessage(String input) async {
    final String content = input.trim();
    if (content.isEmpty || isSending) {
      return;
    }

    latestSafetyAlert = null;
    isSending = true;

    final DateTime now = DateTime.now();
    final ChatSession session = _resolveEditableSession();
    final ChatMessage userMessage = ChatMessage(
      id: 'user_${now.microsecondsSinceEpoch}',
      sender: Sender.user,
      text: content,
      timestamp: now,
      mode: selectedMode,
    );

    _upsertSession(
      session.copyWith(
        updatedAt: now,
        messages: <ChatMessage>[...session.messages, userMessage],
      ),
    );
    notifyListeners();

    final CrisisSupportResult safety = _crisisService.inspect(content);
    if (safety.isCrisis) {
      latestSafetyAlert = safety.message;
      final DateTime alertTime = DateTime.now();
      final ChatMessage assistantMessage = ChatMessage(
        id: 'safety_${alertTime.microsecondsSinceEpoch}',
        sender: Sender.assistant,
        text: safety.message,
        timestamp: alertTime,
        mode: selectedMode,
        isSafety: true,
      );
      final ChatSession current = activeSession;
      _upsertSession(
        current.copyWith(
          updatedAt: alertTime,
          messages: <ChatMessage>[...current.messages, assistantMessage],
        ),
      );
      await _persist();
      isSending = false;
      notifyListeners();
      return;
    }

    final CompanionReply reply = await _companionService.generateReply(
      mode: selectedMode,
      userInput: content,
      recentMessages: activeSession.messages,
      memory: memory,
      responsePreference: responsePreference,
      latestMoodEntry: latestMoodEntry,
    );

    memory = reply.memory;
    final DateTime replyTime = DateTime.now();
    final ChatMessage assistantMessage = ChatMessage(
      id: 'assistant_${replyTime.microsecondsSinceEpoch}',
      sender: Sender.assistant,
      text: reply.text,
      timestamp: replyTime,
      mode: selectedMode,
    );

    final ChatSession updatedSession = activeSession.copyWith(
      updatedAt: assistantMessage.timestamp,
      messages: <ChatMessage>[...activeSession.messages, assistantMessage],
    );
    _upsertSession(updatedSession);
    await _persist();
    isSending = false;
    notifyListeners();
  }

  Future<void> saveMoodEntry(String note) async {
    if (isSavingMood) {
      return;
    }
    isSavingMood = true;
    notifyListeners();

    final DateTime now = DateTime.now();
    final MoodEntry entry = MoodEntry(
      id: 'mood_${now.microsecondsSinceEpoch}',
      mood: selectedMood,
      note: note.trim(),
      createdAt: now,
    );

    moodEntries = <MoodEntry>[entry, ...moodEntries]
        .take(14)
        .toList()
      ..sort((MoodEntry a, MoodEntry b) => b.createdAt.compareTo(a.createdAt));

    memory = memory.copyWith(
      lastMoodSummary: _moodSummaryFromEntry(entry),
      updatedAt: now,
    );

    await _persist();
    isSavingMood = false;
    notifyListeners();
  }

  Future<void> updateResponsePreference(ResponsePreference next) async {
    responsePreference = next;
    await _store.saveResponsePreference(responsePreference);
    notifyListeners();
  }

  Future<void> updateReminderSettings(ReminderSettings next) async {
    reminderSettings = next;
    await _store.saveReminderSettings(reminderSettings);
    notifyListeners();
  }

  Future<void> deleteSession(String sessionId) async {
    sessions = sessions.where((ChatSession item) => item.id != sessionId).toList();
    if (activeSessionId == sessionId) {
      activeSessionId = sessions.isEmpty ? null : sessions.first.id;
      if (sessions.isNotEmpty) {
        selectedMode = sessions.first.mode;
      }
    }
    await _persist();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    sessions = <ChatSession>[];
    activeSessionId = null;
    moodEntries = <MoodEntry>[];
    memory = UserMemory.empty();
    latestSafetyAlert = null;
    await _store.clearAll();
    responsePreference = ResponsePreference.defaults();
    reminderSettings = ReminderSettings.defaults();
    selectedMood = MoodType.tired;
    notifyListeners();
  }

  Future<void> removeMemoryItem(String value) async {
    memory = memory.copyWith(
      triggers: memory.triggers.where((String item) => item != value).toList(),
      preferences: memory.preferences.where((String item) => item != value).toList(),
      comfortTopics: memory.comfortTopics.where((String item) => item != value).toList(),
      lastMoodSummary: memory.lastMoodSummary == value ? '' : memory.lastMoodSummary,
      updatedAt: DateTime.now(),
    );
    await _store.saveMemory(memory);
    notifyListeners();
  }

  String reminderHeadline() {
    if (!reminderSettings.enabled) {
      return '提醒已关闭';
    }
    return '每日 ${reminderSettings.formattedTime} 提醒';
  }

  String reminderSubtitle() {
    if (!reminderSettings.enabled) {
      return '你仍然可以随时手动来打卡。';
    }

    if (shouldShowReminderNudge()) {
      return reminderSettings.gentleNudge
          ? '差不多到你的打卡时间了，要不要停一下照顾自己？'
          : '这是你给自己的提醒，回来看看此刻的状态。';
    }

    return reminderSettings.weekdayOnly ? '仅工作日提醒' : '每天提醒';
  }

  bool shouldShowReminderNudge() {
    if (!reminderSettings.enabled) {
      return false;
    }

    final DateTime now = DateTime.now();
    if (reminderSettings.weekdayOnly && now.weekday >= DateTime.saturday) {
      return false;
    }

    final DateTime scheduledToday = DateTime(
      now.year,
      now.month,
      now.day,
      reminderSettings.hour,
      reminderSettings.minute,
    );
    if (now.isBefore(scheduledToday)) {
      return false;
    }

    final MoodEntry? latest = latestMoodEntry;
    if (latest == null) {
      return true;
    }

    return latest.createdAt.year != now.year ||
        latest.createdAt.month != now.month ||
        latest.createdAt.day != now.day ||
        latest.createdAt.isBefore(scheduledToday);
  }

  List<String> hotlineLines() {
    return _crisisService.hotlineLines();
  }

  ChatSession? _latestSessionForMode(CompanionMode mode) {
    return sessions.cast<ChatSession?>().firstWhere(
          (ChatSession? item) => item?.mode == mode,
          orElse: () => null,
        );
  }

  ChatSession? _sessionById(String? sessionId) {
    if (sessionId == null) {
      return null;
    }
    return sessions.cast<ChatSession?>().firstWhere(
          (ChatSession? item) => item?.id == sessionId,
          orElse: () => null,
        );
  }

  ChatSession _resolveEditableSession() {
    final ChatSession? existing = _sessionById(activeSessionId);
    if (existing != null) {
      return existing;
    }

    final ChatSession created = _buildDraftSession(selectedMode);
    activeSessionId = created.id;
    sessions = <ChatSession>[created, ...sessions];
    return created;
  }

  ChatSession _buildDraftSession(CompanionMode mode) {
    final DateTime now = DateTime.now();
    return ChatSession(
      id: 'session_${mode.name}_${now.microsecondsSinceEpoch}',
      mode: mode,
      createdAt: now,
      updatedAt: now,
      messages: <ChatMessage>[
        ChatMessage(
          id: 'welcome_${mode.name}_${now.microsecondsSinceEpoch}',
          sender: Sender.assistant,
          text: mode.starterPrompt,
          timestamp: now,
          mode: mode,
        ),
      ],
    );
  }

  void _upsertSession(ChatSession session) {
    final List<ChatSession> next = sessions.where((ChatSession item) => item.id != session.id).toList()
      ..insert(0, session);
    sessions = next;
    activeSessionId = session.id;
  }

  String _moodSummaryFromEntry(MoodEntry entry) {
    switch (entry.mood) {
      case MoodType.calm:
        return '今天状态还算稳，你想把这种平静多留一会。';
      case MoodType.tired:
        return '今天明显很疲惫，比起催自己更需要休息。';
      case MoodType.anxious:
        return '今天有点紧绷，脑子转得很快。';
      case MoodType.overwhelmed:
        return '今天像被很多事压住了，需要先减一点负担。';
      case MoodType.low:
        return '今天情绪偏低，想先有人把这种难受接住。';
      case MoodType.hopeful:
        return '今天虽然辛苦，但还是出现了一点点希望。';
    }
  }

  Future<void> _persist() async {
    await _store.saveSessions(sessions);
    await _store.saveMemory(memory);
    await _store.saveMoodEntries(moodEntries);
    await _store.saveResponsePreference(responsePreference);
    await _store.saveReminderSettings(reminderSettings);
  }
}
