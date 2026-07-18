import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/chat_models.dart';
import 'ai_config.dart';

class CompanionReply {
  const CompanionReply({
    required this.text,
    required this.memory,
  });

  final String text;
  final UserMemory memory;
}

class CompanionService {
  final http.Client _client = http.Client();

  Future<CompanionReply> generateReply({
    required CompanionMode mode,
    required String userInput,
    required List<ChatMessage> recentMessages,
    required UserMemory memory,
    required ResponsePreference responsePreference,
    MoodEntry? latestMoodEntry,
  }) async {
    final UserMemory nextMemory = _updateMemory(memory, userInput, latestMoodEntry);

    if (!AiConfig.isConfigured) {
      return CompanionReply(
        text: _offlineReply(
          mode: mode,
          userInput: userInput,
          responsePreference: responsePreference,
          latestMoodEntry: latestMoodEntry,
        ),
        memory: nextMemory,
      );
    }

    try {
      final Uri uri = Uri.parse('${AiConfig.apiBaseUrl}${AiConfig.chatCompletionsPath}');
      final String systemPrompt = _buildSystemPrompt(
        mode: mode,
        memory: nextMemory,
        recentMessages: recentMessages,
        responsePreference: responsePreference,
        latestMoodEntry: latestMoodEntry,
      );

      final Map<String, dynamic> payload = <String, dynamic>{
        'model': AiConfig.model,
        'messages': <Map<String, String>>[
          <String, String>{'role': 'system', 'content': systemPrompt},
          <String, String>{'role': 'user', 'content': userInput},
        ],
        'thinking': <String, String>{
          'type': AiConfig.enableThinking ? 'enabled' : 'disabled',
        },
        'temperature': 0.7,
        'top_p': 0.9,
        'stream': false,
      };

      debugPrint('YuXin payload: ${jsonEncode(payload)}');
      final http.Response response = await _client
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AiConfig.apiKey}',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('YuXin status: ${response.statusCode}');
      final String text = _extractReplyText(response);
      if (response.statusCode == 200 && text.isNotEmpty) {
        return CompanionReply(
          text: _trimReply(text, responsePreference),
          memory: nextMemory,
        );
      }
    } on TimeoutException {
      debugPrint('YuXin fallback: timeout');
    } catch (error) {
      debugPrint('YuXin fallback: $error');
    }

    return CompanionReply(
      text: _offlineReply(
        mode: mode,
        userInput: userInput,
        responsePreference: responsePreference,
        latestMoodEntry: latestMoodEntry,
      ),
      memory: nextMemory,
    );
  }

  String _extractReplyText(http.Response response) {
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return '';
    }

    final List<dynamic>? choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      return '';
    }

    final dynamic firstChoice = choices.first;
    if (firstChoice is! Map<String, dynamic>) {
      return '';
    }

    final dynamic message = firstChoice['message'];
    if (message is! Map<String, dynamic>) {
      return '';
    }

    return (message['content'] as String? ?? '').trim();
  }

  String _trimReply(String text, ResponsePreference preference) {
    final String normalized = text.replaceAll('\r\n', '\n').trim();
    final int limit = preference.conciseReplies ? 70 : 140;
    if (normalized.length <= limit) {
      return normalized;
    }
    return '${normalized.substring(0, limit)}...';
  }

  String _buildSystemPrompt({
    required CompanionMode mode,
    required UserMemory memory,
    required List<ChatMessage> recentMessages,
    required ResponsePreference responsePreference,
    required MoodEntry? latestMoodEntry,
  }) {
    final StringBuffer buffer = StringBuffer()
      ..writeln(_personaHint(mode))
      ..writeln(
        'Reply in Chinese. Be warm, steady, and emotionally safe. Do not diagnose, lecture, or replace professional help.',
      )
      ..writeln(
        responsePreference.quietCompanionship
            ? 'Lead with empathy before guidance.'
            : 'You may answer the core point more directly.',
      )
      ..writeln(
        responsePreference.actionableAdvice
            ? 'If the user clearly asks for help, offer one light, concrete next step.'
            : 'Avoid step-by-step advice unless the user directly asks for it.',
      )
      ..writeln(
        responsePreference.conciseReplies
            ? 'Keep replies around 45 to 80 Chinese characters.'
            : 'Keep replies around 60 to 120 Chinese characters.',
      )
      ..writeln(
        responsePreference.gentleTone
            ? 'Use soft language, not commanding language.'
            : 'Keep the tone natural and sincere.',
      );

    if (responsePreference.nightSoftness && mode == CompanionMode.night) {
      buffer.writeln('In late-night mode, respond even more softly and slowly.');
    }

    if (memory.lastMoodSummary.isNotEmpty) {
      buffer.writeln('Recent emotional pattern: ${memory.lastMoodSummary}');
    }
    if (memory.triggers.isNotEmpty) {
      buffer.writeln('Frequent stress themes: ${memory.triggers.join(', ')}');
    }
    if (memory.comfortTopics.isNotEmpty) {
      buffer.writeln('Things that help them settle: ${memory.comfortTopics.join(', ')}');
    }
    if (latestMoodEntry != null) {
      buffer.writeln('Latest mood check-in: ${latestMoodEntry.mood.label}.');
      if (latestMoodEntry.note.trim().isNotEmpty) {
        buffer.writeln('Mood note: ${latestMoodEntry.note.trim()}');
      }
    }

    final Iterable<String> latestUserMessages = recentMessages
        .where((ChatMessage item) => item.sender == Sender.user)
        .take(4)
        .map((ChatMessage item) => item.text);
    if (latestUserMessages.isNotEmpty) {
      buffer.writeln('Recent user lines: ${latestUserMessages.join(' ; ')}');
    }

    return buffer.toString().trim();
  }

  String _personaHint(CompanionMode mode) {
    switch (mode) {
      case CompanionMode.general:
        return 'You are a warm, emotionally attuned everyday support companion.';
      case CompanionMode.teen:
        return 'You are a patient, steady support companion for teenage stress and school pressure.';
      case CompanionMode.workplace:
        return 'You are a grounded support companion for burnout, meetings, and work pressure.';
      case CompanionMode.night:
        return 'You are a quiet late-night companion for insomnia, loneliness, and overthinking.';
    }
  }

  UserMemory _updateMemory(
    UserMemory memory,
    String input,
    MoodEntry? latestMoodEntry,
  ) {
    final String text = input.trim();
    final List<String> nextTriggers = <String>{
      ...memory.triggers,
      ..._collectTriggers(text),
    }.take(6).toList();
    final List<String> nextPreferences = <String>{
      ...memory.preferences,
      ..._collectPreferences(text),
    }.take(6).toList();
    final List<String> nextComfortTopics = <String>{
      ...memory.comfortTopics,
      ..._collectComfortTopics(text),
      if (latestMoodEntry != null && latestMoodEntry.mood == MoodType.hopeful) 'small signs of hope',
    }.take(6).toList();

    return memory.copyWith(
      triggers: nextTriggers,
      preferences: nextPreferences,
      comfortTopics: nextComfortTopics,
      lastMoodSummary: _summarizeMood(text, latestMoodEntry),
      updatedAt: DateTime.now(),
    );
  }

  List<String> _collectTriggers(String input) {
    final Map<String, List<String>> mapping = <String, List<String>>{
      'study pressure': <String>['exam', 'grade', 'homework', 'school', 'class'],
      'friendship stress': <String>['friend', 'classmate', 'teacher', 'dorm'],
      'family tension': <String>['mom', 'dad', 'parents', 'home'],
      'work stress': <String>['work', 'office', 'meeting', 'boss', 'coworker', 'overtime'],
      'sleep trouble': <String>['sleep', 'insomnia', 'late night'],
      'low mood': <String>['sad', 'hurt', 'breakdown', 'empty', 'alone'],
    };

    return mapping.entries
        .where((MapEntry<String, List<String>> item) => item.value.any(input.toLowerCase().contains))
        .map((MapEntry<String, List<String>> item) => item.key)
        .toList();
  }

  List<String> _collectPreferences(String input) {
    final Map<String, List<String>> mapping = <String, List<String>>{
      'wants quiet company first': <String>['just listen', 'stay with me', 'hear me out'],
      'wants practical ideas': <String>['what should i do', 'advice', 'how do i'],
      'needs low-pressure replies': <String>['too tired', 'cannot sleep', 'do not want too much'],
    };

    final String lowered = input.toLowerCase();
    return mapping.entries
        .where((MapEntry<String, List<String>> item) => item.value.any(lowered.contains))
        .map((MapEntry<String, List<String>> item) => item.key)
        .toList();
  }

  List<String> _collectComfortTopics(String input) {
    final Map<String, List<String>> mapping = <String, List<String>>{
      'going outside for a short walk': <String>['walk', 'outside', 'fresh air'],
      'resting quietly': <String>['rest', 'lie down', 'sleep'],
      'having someone nearby': <String>['stay with me', 'talk with me', 'company'],
      'stepping away for a moment': <String>['leave for a bit', 'hide', 'get away'],
    };

    final String lowered = input.toLowerCase();
    return mapping.entries
        .where((MapEntry<String, List<String>> item) => item.value.any(lowered.contains))
        .map((MapEntry<String, List<String>> item) => item.key)
        .toList();
  }

  String _summarizeMood(String input, MoodEntry? latestMoodEntry) {
    if (latestMoodEntry != null) {
      switch (latestMoodEntry.mood) {
        case MoodType.calm:
          return 'They have been trying to stay steady and may want a little quiet space.';
        case MoodType.tired:
          return 'They have been worn down and need more rest than pressure.';
        case MoodType.anxious:
          return 'They have been tense and their mind has been moving too fast.';
        case MoodType.overwhelmed:
          return 'They have been carrying too much and need less weight first.';
        case MoodType.low:
          return 'They have been low and need gentleness more than fixing.';
        case MoodType.hopeful:
          return 'They are still tired, but some small hope has started to return.';
      }
    }

    final String lowered = input.toLowerCase();
    if (lowered.contains('anxious') || lowered.contains('panic')) {
      return 'They have been more anxious and tightly wound lately.';
    }
    if (lowered.contains('sad') || lowered.contains('hurt')) {
      return 'They have been carrying hurt and sadness lately.';
    }
    if (lowered.contains('tired') || lowered.contains('burned out')) {
      return 'They have been very tired and depleted lately.';
    }
    if (lowered.contains('alone') || lowered.contains('insomnia')) {
      return 'They have been needing quiet company and stability lately.';
    }
    return 'They have been holding unspoken emotion inside for a while.';
  }

  String _offlineReply({
    required CompanionMode mode,
    required String userInput,
    required ResponsePreference responsePreference,
    required MoodEntry? latestMoodEntry,
  }) {
    final String lowered = userInput.toLowerCase();
    final bool asksAdvice = lowered.contains('what should i do') ||
        lowered.contains('how do i') ||
        lowered.contains('advice');
    final bool tired = lowered.contains('tired') ||
        lowered.contains('exhausted') ||
        lowered.contains('drained');
    final String moodLead = latestMoodEntry == null
        ? ''
        : 'I noticed your latest check-in was "${latestMoodEntry.mood.label}". ';

    final String adviceTail = responsePreference.actionableAdvice && asksAdvice
        ? 'Try shrinking the problem down to the next tiny step instead of solving all of it at once.'
        : 'You do not have to tidy all of this up at once. You can give me the hardest part first.';

    switch (mode) {
      case CompanionMode.general:
        return tired
            ? '${moodLead}You have been carrying a lot. Take one softer breath before asking yourself for anything else.'
            : '$moodLead$adviceTail';
      case CompanionMode.teen:
        return asksAdvice
            ? '${moodLead}You are already trying hard. Pick the smallest next step and let that be enough for today.'
            : '${moodLead}This kind of pressure feels huge when you are still in it. You do not need to act okay for me.';
      case CompanionMode.workplace:
        return asksAdvice
            ? '${moodLead}You are not failing. You sound overused. Separate the urgent task from the emotional weight first.'
            : '${moodLead}Work stress can grind people down quietly. It makes sense that you are tired.';
      case CompanionMode.night:
        if (responsePreference.nightSoftness) {
          return asksAdvice
              ? '${moodLead}Do not force a life answer tonight. Drink some water, put the phone down for one minute, then tell me the most stuck sentence.'
              : '${moodLead}Night makes feelings louder. You do not need to get better right now. I can stay here with you.';
        }
        return '$moodLead$adviceTail';
    }
  }
}
