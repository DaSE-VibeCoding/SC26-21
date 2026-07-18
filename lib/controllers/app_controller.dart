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
  int currentTabIndex = 0;
  CompanionMode selectedMode = CompanionMode.general;
  UserMemory memory = UserMemory.empty();
  List<ChatSession> sessions = <ChatSession>[];
  String? latestSafetyAlert;

  ChatSession get activeSession {
    final ChatSession? existing = sessions.cast<ChatSession?>().firstWhere(
          (ChatSession? item) => item?.mode == selectedMode,
          orElse: () => null,
        );

    if (existing != null) {
      return existing;
    }

    final DateTime now = DateTime.now();
    return ChatSession(
      id: 'session_${selectedMode.name}',
      mode: selectedMode,
      createdAt: now,
      updatedAt: now,
      messages: <ChatMessage>[
        ChatMessage(
          id: 'welcome_${selectedMode.name}',
          sender: Sender.assistant,
          text: selectedMode.starterPrompt,
          timestamp: now,
          mode: selectedMode,
        ),
      ],
    );
  }

  Future<void> bootstrap() async {
    final AppSnapshot snapshot = await _store.loadSnapshot();
    sessions = snapshot.sessions;
    memory = snapshot.memory;
    isBootstrapping = false;
    notifyListeners();
  }

  void switchTab(int index) {
    currentTabIndex = index;
    notifyListeners();
  }

  void selectMode(CompanionMode mode) {
    selectedMode = mode;
    _ensureSession(mode);
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
    final ChatSession session = _ensureSession(selectedMode);
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
      final ChatMessage assistantMessage = ChatMessage(
        id: 'safety_${DateTime.now().microsecondsSinceEpoch}',
        sender: Sender.assistant,
        text: safety.message,
        timestamp: DateTime.now(),
        mode: selectedMode,
        isSafety: true,
      );
      final ChatSession current = activeSession;
      _upsertSession(
        current.copyWith(
          updatedAt: assistantMessage.timestamp,
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
    );

    memory = reply.memory;
    final ChatMessage assistantMessage = ChatMessage(
      id: 'assistant_${DateTime.now().microsecondsSinceEpoch}',
      sender: Sender.assistant,
      text: reply.text,
      timestamp: DateTime.now(),
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

  Future<void> deleteSession(String sessionId) async {
    sessions = sessions.where((ChatSession item) => item.id != sessionId).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    sessions = <ChatSession>[];
    memory = UserMemory.empty();
    latestSafetyAlert = null;
    await _store.clearAll();
    notifyListeners();
  }

  List<String> hotlineLines() {
    return _crisisService.hotlineLines();
  }

  ChatSession _ensureSession(CompanionMode mode) {
    final ChatSession? existing = sessions.cast<ChatSession?>().firstWhere(
          (ChatSession? item) => item?.mode == mode,
          orElse: () => null,
        );

    if (existing != null) {
      return existing;
    }

    final DateTime now = DateTime.now();
    final ChatSession created = ChatSession(
      id: 'session_${mode.name}',
      mode: mode,
      createdAt: now,
      updatedAt: now,
      messages: <ChatMessage>[
        ChatMessage(
          id: 'welcome_${mode.name}',
          sender: Sender.assistant,
          text: mode.starterPrompt,
          timestamp: now,
          mode: mode,
        ),
      ],
    );

    sessions = <ChatSession>[created, ...sessions];
    return created;
  }

  void _upsertSession(ChatSession session) {
    final List<ChatSession> next = sessions.where((ChatSession item) => item.id != session.id).toList()
      ..insert(0, session);
    sessions = next;
  }

  Future<void> _persist() async {
    await _store.saveSessions(sessions);
    await _store.saveMemory(memory);
  }
}
