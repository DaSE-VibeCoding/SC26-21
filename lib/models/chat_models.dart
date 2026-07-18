enum CompanionMode {
  general,
  teen,
  workplace,
  night,
}

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
        return '适合日常倾诉、压力释放和心态调节。';
      case CompanionMode.teen:
        return '更懂学业焦虑、校园关系和青春期敏感。';
      case CompanionMode.workplace:
        return '接住加班内耗、工作焦虑和生活压力。';
      case CompanionMode.night:
        return '低压慢聊，适合失眠、孤独和深夜低落。';
    }
  }

  String get personaTitle {
    switch (this) {
      case CompanionMode.general:
        return '温柔陪伴者';
      case CompanionMode.teen:
        return '懂学生压力的大姐姐';
      case CompanionMode.workplace:
        return '懂职场疲惫的知心伙伴';
      case CompanionMode.night:
        return '深夜安静陪你的人';
    }
  }

  String get starterPrompt {
    switch (this) {
      case CompanionMode.general:
        return '今天想把什么情绪先放下来，我会认真听。';
      case CompanionMode.teen:
        return '你可以慢慢说，学习和关系里的委屈我都会接住。';
      case CompanionMode.workplace:
        return '先别撑着，把今天最压你的那件事讲给我。';
      case CompanionMode.night:
        return '夜深的时候更容易难受，我在，你不用急着振作。';
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
    final List<dynamic> rawMessages = json['messages'] as List<dynamic>? ?? <dynamic>[];
    return ChatSession(
      id: json['id'] as String,
      mode: CompanionMode.values.byName(json['mode'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messages: rawMessages
          .map((dynamic item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UserMemory {
  const UserMemory({
    required this.nickHint,
    required this.triggers,
    required this.preferences,
    required this.lastMoodSummary,
    required this.updatedAt,
  });

  final String nickHint;
  final List<String> triggers;
  final List<String> preferences;
  final String lastMoodSummary;
  final DateTime updatedAt;

  UserMemory copyWith({
    String? nickHint,
    List<String>? triggers,
    List<String>? preferences,
    String? lastMoodSummary,
    DateTime? updatedAt,
  }) {
    return UserMemory(
      nickHint: nickHint ?? this.nickHint,
      triggers: triggers ?? this.triggers,
      preferences: preferences ?? this.preferences,
      lastMoodSummary: lastMoodSummary ?? this.lastMoodSummary,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nickHint': nickHint,
      'triggers': triggers,
      'preferences': preferences,
      'lastMoodSummary': lastMoodSummary,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserMemory.fromJson(Map<String, dynamic> json) {
    return UserMemory(
      nickHint: json['nickHint'] as String? ?? '',
      triggers: (json['triggers'] as List<dynamic>? ?? <dynamic>[]).cast<String>(),
      preferences: (json['preferences'] as List<dynamic>? ?? <dynamic>[]).cast<String>(),
      lastMoodSummary: json['lastMoodSummary'] as String? ?? '',
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
      updatedAt: DateTime.now(),
    );
  }
}

class AppSnapshot {
  const AppSnapshot({
    required this.sessions,
    required this.memory,
  });

  final List<ChatSession> sessions;
  final UserMemory memory;
}
