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
  }) async {
    final UserMemory nextMemory = _updateMemory(memory, userInput);

    if (!AiConfig.isConfigured) {
      return CompanionReply(
        text: _offlineReply(mode: mode, userInput: userInput),
        memory: nextMemory,
      );
    }

    try {
      final Uri uri =
          Uri.parse('${AiConfig.apiBaseUrl}${AiConfig.chatCompletionsPath}');

      final String systemPrompt = _buildSystemPrompt(
        mode: mode,
        memory: nextMemory,
        recentMessages: recentMessages,
      );

      final Map<String, dynamic> payload = <String, dynamic>{
        'model': AiConfig.model,
        'messages': <Map<String, String>>[
          <String, String>{
            'role': 'system',
            'content': systemPrompt,
          },
          <String, String>{
            'role': 'user',
            'content': userInput,
          },
        ],
        'thinking': <String, String>{
          'type': AiConfig.enableThinking ? 'enabled' : 'disabled',
        },
        'temperature': 0.7,
        'top_p': 0.9,
        'stream': false,
      };

      debugPrint('ECNU chat payload: ${jsonEncode(payload)}');
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

      debugPrint('ECNU chat status: ${response.statusCode}');
      debugPrint('ECNU chat body: ${response.body}');

      final String text = _extractReplyText(response);
      if (response.statusCode == 200 && text.isNotEmpty) {
        return CompanionReply(
          text: _trimReply(text),
          memory: nextMemory,
        );
      }
    } on TimeoutException {
      debugPrint('ECNU chat fallback: timeout');
    } catch (error) {
      debugPrint('ECNU chat fallback: $error');
    }

    return CompanionReply(
      text: _offlineReply(mode: mode, userInput: userInput),
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

  String _trimReply(String text) {
    final String normalized = text.replaceAll('\r\n', '\n').trim();
    if (normalized.length <= 80) {
      return normalized;
    }
    return '${normalized.substring(0, 80)}...';
  }

  String _buildSystemPrompt({
    required CompanionMode mode,
    required UserMemory memory,
    required List<ChatMessage> recentMessages,
  }) {
    final String persona = _personaHint(mode);
    final String memorySummary = memory.lastMoodSummary.isEmpty
        ? ''
        : '你记得用户最近的状态：${memory.lastMoodSummary}\n';
    final String recentSummary = recentMessages
        .where((ChatMessage item) => item.sender == Sender.user)
        .take(3)
        .map((ChatMessage item) => item.text)
        .join('；');

    final String contextBlock = recentSummary.isEmpty ? '' : '用户最近说过：$recentSummary\n';

    return '''
$persona
请用中文回复，20到80字，先共情再轻微疏导，不说教，不下诊断。
${memorySummary}${contextBlock}如果用户只是倾诉，就先接住情绪；如果用户明确求助，再给一个轻量可执行的小建议。
'''.trim();
  }

  String _personaHint(CompanionMode mode) {
    switch (mode) {
      case CompanionMode.general:
        return '你是温柔、简短、有共情力的情绪陪伴助手。';
      case CompanionMode.teen:
        return '你是温柔耐心、懂学生压力的大姐姐型陪伴助手。';
      case CompanionMode.workplace:
        return '你是成熟通透、懂职场疲惫的陪伴助手。';
      case CompanionMode.night:
        return '你是安静治愈、适合深夜低落时陪伴的助手。';
    }
  }

  UserMemory _updateMemory(UserMemory memory, String input) {
    final String text = input.trim();
    final List<String> nextTriggers = <String>{
      ...memory.triggers,
      ..._collectTriggers(text),
    }.take(5).toList();
    final List<String> nextPreferences = <String>{
      ...memory.preferences,
      ..._collectPreferences(text),
    }.take(5).toList();

    return memory.copyWith(
      triggers: nextTriggers,
      preferences: nextPreferences,
      lastMoodSummary: _summarizeMood(text),
      updatedAt: DateTime.now(),
    );
  }

  List<String> _collectTriggers(String input) {
    final Map<String, List<String>> mapping = <String, List<String>>{
      '学业压力': <String>['考试', '成绩', '作业', '学校', '上课'],
      '校园关系': <String>['同学', '老师', '朋友', '宿舍'],
      '亲子沟通': <String>['爸妈', '父母', '家里'],
      '工作焦虑': <String>['上班', '工作', '开会', '领导', '同事', '加班'],
      '睡眠困扰': <String>['睡不着', '失眠', '半夜'],
      '情绪低落': <String>['难过', '委屈', '崩溃', '压抑', '孤独'],
    };

    return mapping.entries
        .where((MapEntry<String, List<String>> item) {
          return item.value.any(input.contains);
        })
        .map((MapEntry<String, List<String>> item) => item.key)
        .toList();
  }

  List<String> _collectPreferences(String input) {
    final Map<String, List<String>> mapping = <String, List<String>>{
      '想被安静陪伴': <String>['只是想说说', '陪陪我', '听我说'],
      '想要实用建议': <String>['怎么办', '建议', '怎么做'],
      '偏好慢节奏安抚': <String>['睡不着', '好累', '不想说太多'],
    };

    return mapping.entries
        .where((MapEntry<String, List<String>> item) {
          return item.value.any(input.contains);
        })
        .map((MapEntry<String, List<String>> item) => item.key)
        .toList();
  }

  String _summarizeMood(String input) {
    if (input.contains('焦虑') || input.contains('慌')) {
      return '最近更容易焦虑紧绷。';
    }
    if (input.contains('难过') || input.contains('委屈')) {
      return '最近积压了不少委屈和难过。';
    }
    if (input.contains('累') || input.contains('疲惫')) {
      return '最近处在明显的疲惫状态。';
    }
    if (input.contains('孤独') || input.contains('失眠')) {
      return '最近更需要安静的陪伴和安抚。';
    }
    return '最近有些情绪堵在心里，想找个安全的出口。';
  }

  String _offlineReply({
    required CompanionMode mode,
    required String userInput,
  }) {
    final bool asksAdvice = userInput.contains('怎么办') ||
        userInput.contains('怎么做') ||
        userInput.contains('建议');
    final bool tired = userInput.contains('累') ||
        userInput.contains('烦') ||
        userInput.contains('压抑');

    switch (mode) {
      case CompanionMode.general:
        if (asksAdvice) {
          return '我懂你现在很乱。先只处理最刺痛你的那一件，小步走，会比硬撑轻一点。';
        }
        return tired
            ? '你已经撑了很久了，先别急着要求自己马上好起来，我陪你慢慢松一口气。'
            : '我在认真听，你可以把没说完的那部分也交给我。';
      case CompanionMode.teen:
        return asksAdvice
            ? '你已经很努力了。先把最担心的一点拆小，今天只完成眼前一步就够了。'
            : '这种委屈和压力压在学生身上，真的会很闷。你不用急着懂事，先让我陪你缓一缓。';
      case CompanionMode.workplace:
        return asksAdvice
            ? '你不是不行，是被消耗太久了。先把最急的事和最耗你的情绪分开，会轻一点。'
            : '职场里的拉扯最磨人，你会累很正常。先把呼吸放慢，我陪你把这团乱麻理一理。';
      case CompanionMode.night:
        return asksAdvice
            ? '先别逼自己立刻想通。喝口温水，放下手机一分钟，再把最堵的念头告诉我。'
            : '夜里情绪会被放大，我知道。你先靠一会儿，我会一直在这儿陪你。';
    }
  }
}
