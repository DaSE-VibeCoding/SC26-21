import 'package:flutter/material.dart';

enum CompanionMode { general, teen, workplace, night }

extension CompanionModeX on CompanionMode {
  String get label {
    switch (this) {
      case CompanionMode.general:
        return '通用陪伴';
      case CompanionMode.teen:
        return '青少年';
      case CompanionMode.workplace:
        return '职场';
      case CompanionMode.night:
        return '深夜树洞';
    }
  }

  String get shortDescription {
    switch (this) {
      case CompanionMode.general:
        return '适合日常压力、情绪打结。';
      case CompanionMode.teen:
        return '适合学习压力、朋友关系。';
      case CompanionMode.workplace:
        return '适合加班内耗、会议、疲惫。';
      case CompanionMode.night:
        return '适合失眠、孤独、深夜低压陪伴。';
    }
  }

  String get personaTitle {
    switch (this) {
      case CompanionMode.general:
        return '温柔陪伴者';
      case CompanionMode.teen:
        return '懂你的大姐姐';
      case CompanionMode.workplace:
        return '职场知心搭子';
      case CompanionMode.night:
        return '深夜安静陪伴';
    }
  }

  String get starterPrompt {
    switch (this) {
      case CompanionMode.general:
        return '今天想先把什么说出来？你可以从任何地方开始。';
      case CompanionMode.teen:
        return '你可以慢慢说，学习和关系里的压力都可以先放过来。';
      case CompanionMode.workplace:
        return '今天上班最压你的那件事是什么？';
      case CompanionMode.night:
        return '夜里会把情绪放大一点，我在这里陪你。';
    }
  }
}

enum MoodType { calm, tired, anxious, overwhelmed, low, hopeful }

extension MoodTypeX on MoodType {
  String get label {
    switch (this) {
      case MoodType.calm:
        return '平静';
      case MoodType.tired:
        return '疲惫';
      case MoodType.anxious:
        return '焦虑';
      case MoodType.overwhelmed:
        return '压住了';
      case MoodType.low:
        return '低落';
      case MoodType.hopeful:
        return '有点希望';
    }
  }

  String get subtitle {
    switch (this) {
      case MoodType.calm:
        return '今天还算稳住';
      case MoodType.tired:
        return '像快没电了';
      case MoodType.anxious:
        return '脑子停不下来';
      case MoodType.overwhelmed:
        return '事情一下太多';
      case MoodType.low:
        return '闷闷地下坠';
      case MoodType.hopeful:
        return '有一点回光';
    }
  }

  IconData get icon {
    switch (this) {
      case MoodType.calm:
        return Icons.spa_rounded;
      case MoodType.tired:
        return Icons.bedtime_rounded;
      case MoodType.anxious:
        return Icons.psychology_alt_rounded;
      case MoodType.overwhelmed:
        return Icons.thunderstorm_rounded;
      case MoodType.low:
        return Icons.cloud_rounded;
      case MoodType.hopeful:
        return Icons.wb_sunny_rounded;
    }
  }

  Color get color {
    switch (this) {
      case MoodType.calm:
        return const Color(0xFF59B89C);
      case MoodType.tired:
        return const Color(0xFF7C89D9);
      case MoodType.anxious:
        return const Color(0xFFF09A49);
      case MoodType.overwhelmed:
        return const Color(0xFFE56D83);
      case MoodType.low:
        return const Color(0xFF6A7BA8);
      case MoodType.hopeful:
        return const Color(0xFFEFBE4A);
    }
  }
}

enum Sender { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.mode,
    this.isSafety = false,
  });

  final String id;
  final Sender sender;
  final String text;
  final DateTime timestamp;
  final CompanionMode mode;
  final bool isSafety;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'sender': sender.name,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'mode': mode.name,
      'isSafety': isSafety,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      sender: Sender.values.byName(json['sender'] as String),
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      mode: CompanionMode.values.byName(json['mode'] as String),
      isSafety: json['isSafety'] as bool? ?? false,
    );
  }
}

class ChatSession {
  const ChatSession({
    required this.id,
    required this.mode,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  final String id;
  final CompanionMode mode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  String get preview {
    if (messages.isEmpty) {
      return mode.starterPrompt;
    }
    return messages.last.text;
  }

  ChatSession copyWith({
    String? id,
    CompanionMode? mode,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  }) {
    return ChatSession(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'mode': mode.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((ChatMessage item) => item.toJson()).toList(),
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawMessages =
        json['messages'] as List<dynamic>? ?? <dynamic>[];
    return ChatSession(
      id: json['id'] as String,
      mode: CompanionMode.values.byName(json['mode'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messages: rawMessages
          .map(
            (dynamic item) =>
                ChatMessage.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class MoodEntry {
  const MoodEntry({
    required this.id,
    required this.mood,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final MoodType mood;
  final String note;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'mood': mood.name,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] as String,
      mood: MoodType.values.byName(json['mood'] as String),
      note: json['note'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ResponsePreference {
  const ResponsePreference({
    required this.quietCompanionship,
    required this.actionableAdvice,
    required this.conciseReplies,
    required this.gentleTone,
    required this.nightSoftness,
  });

  final bool quietCompanionship;
  final bool actionableAdvice;
  final bool conciseReplies;
  final bool gentleTone;
  final bool nightSoftness;

  ResponsePreference copyWith({
    bool? quietCompanionship,
    bool? actionableAdvice,
    bool? conciseReplies,
    bool? gentleTone,
    bool? nightSoftness,
  }) {
    return ResponsePreference(
      quietCompanionship: quietCompanionship ?? this.quietCompanionship,
      actionableAdvice: actionableAdvice ?? this.actionableAdvice,
      conciseReplies: conciseReplies ?? this.conciseReplies,
      gentleTone: gentleTone ?? this.gentleTone,
      nightSoftness: nightSoftness ?? this.nightSoftness,
    );
  }

  List<String> get enabledLabels {
    final List<String> labels = <String>[];
    if (quietCompanionship) {
      labels.add('先接住情绪');
    }
    if (actionableAdvice) {
      labels.add('给一点建议');
    }
    if (conciseReplies) {
      labels.add('回答短一点');
    }
    if (gentleTone) {
      labels.add('别太说教');
    }
    if (nightSoftness) {
      labels.add('深夜更轻一点');
    }
    return labels;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'quietCompanionship': quietCompanionship,
      'actionableAdvice': actionableAdvice,
      'conciseReplies': conciseReplies,
      'gentleTone': gentleTone,
      'nightSoftness': nightSoftness,
    };
  }

  factory ResponsePreference.fromJson(Map<String, dynamic> json) {
    return ResponsePreference(
      quietCompanionship: json['quietCompanionship'] as bool? ?? true,
      actionableAdvice: json['actionableAdvice'] as bool? ?? true,
      conciseReplies: json['conciseReplies'] as bool? ?? false,
      gentleTone: json['gentleTone'] as bool? ?? true,
      nightSoftness: json['nightSoftness'] as bool? ?? true,
    );
  }

  static ResponsePreference defaults() {
    return const ResponsePreference(
      quietCompanionship: true,
      actionableAdvice: true,
      conciseReplies: false,
      gentleTone: true,
      nightSoftness: true,
    );
  }
}

class ReminderSettings {
  const ReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.weekdayOnly,
    required this.gentleNudge,
  });

  final bool enabled;
  final int hour;
  final int minute;
  final bool weekdayOnly;
  final bool gentleNudge;

  ReminderSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    bool? weekdayOnly,
    bool? gentleNudge,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekdayOnly: weekdayOnly ?? this.weekdayOnly,
      gentleNudge: gentleNudge ?? this.gentleNudge,
    );
  }

  String get formattedTime {
    final String hh = hour.toString().padLeft(2, '0');
    final String mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'enabled': enabled,
      'hour': hour,
      'minute': minute,
      'weekdayOnly': weekdayOnly,
      'gentleNudge': gentleNudge,
    };
  }

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    return ReminderSettings(
      enabled: json['enabled'] as bool? ?? true,
      hour: json['hour'] as int? ?? 21,
      minute: json['minute'] as int? ?? 30,
      weekdayOnly: json['weekdayOnly'] as bool? ?? false,
      gentleNudge: json['gentleNudge'] as bool? ?? true,
    );
  }

  static ReminderSettings defaults() {
    return const ReminderSettings(
      enabled: true,
      hour: 21,
      minute: 30,
      weekdayOnly: false,
      gentleNudge: true,
    );
  }
}

class UserMemory {
  const UserMemory({
    required this.nickHint,
    required this.triggers,
    required this.preferences,
    required this.lastMoodSummary,
    required this.comfortTopics,
    required this.updatedAt,
  });

  final String nickHint;
  final List<String> triggers;
  final List<String> preferences;
  final String lastMoodSummary;
  final List<String> comfortTopics;
  final DateTime updatedAt;

  UserMemory copyWith({
    String? nickHint,
    List<String>? triggers,
    List<String>? preferences,
    String? lastMoodSummary,
    List<String>? comfortTopics,
    DateTime? updatedAt,
  }) {
    return UserMemory(
      nickHint: nickHint ?? this.nickHint,
      triggers: triggers ?? this.triggers,
      preferences: preferences ?? this.preferences,
      lastMoodSummary: lastMoodSummary ?? this.lastMoodSummary,
      comfortTopics: comfortTopics ?? this.comfortTopics,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nickHint': nickHint,
      'triggers': triggers,
      'preferences': preferences,
      'lastMoodSummary': lastMoodSummary,
      'comfortTopics': comfortTopics,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserMemory.fromJson(Map<String, dynamic> json) {
    return UserMemory(
      nickHint: json['nickHint'] as String? ?? '',
      triggers: (json['triggers'] as List<dynamic>? ?? <dynamic>[])
          .cast<String>(),
      preferences: (json['preferences'] as List<dynamic>? ?? <dynamic>[])
          .cast<String>(),
      lastMoodSummary: json['lastMoodSummary'] as String? ?? '',
      comfortTopics: (json['comfortTopics'] as List<dynamic>? ?? <dynamic>[])
          .cast<String>(),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  static UserMemory empty() {
    return UserMemory(
      nickHint: '',
      triggers: const <String>[],
      preferences: const <String>[],
      lastMoodSummary: '',
      comfortTopics: const <String>[],
      updatedAt: DateTime.now(),
    );
  }
}

class AppSnapshot {
  const AppSnapshot({
    required this.sessions,
    required this.memory,
    required this.moodEntries,
    required this.responsePreference,
    required this.reminderSettings,
  });

  final List<ChatSession> sessions;
  final UserMemory memory;
  final List<MoodEntry> moodEntries;
  final ResponsePreference responsePreference;
  final ReminderSettings reminderSettings;
}
