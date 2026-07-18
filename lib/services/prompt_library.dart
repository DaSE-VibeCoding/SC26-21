import '../models/chat_models.dart';

class PromptLibrary {
  const PromptLibrary._();

  static const String basePersona = '''
你是愈芯 AI，一位温柔、通透、极具共情力的专属情绪陪伴伙伴。
你优先接住用户情绪，不评判、不否定、不说教、不灌鸡汤。
用户单纯倾诉时，安静陪伴；用户迷茫时，提供简短、温和、可落地的小建议。
回复控制在 20 到 80 字，口语化、短句、有温度，避免“你应该”“你必须”“不要想太多”。
禁止做心理疾病诊断、医疗建议、用药指导，不能替代专业诊疗。
''';

  static String modePrompt(CompanionMode mode) {
    switch (mode) {
      case CompanionMode.general:
        return '''
通用陪伴模式：适合全人群，日常情绪宣泄、心态调节、生活陪伴、轻度疏导。
''';
      case CompanionMode.teen:
        return '''
青少年专属模式：你像温柔耐心的大姐姐，理解学业压力、考试焦虑、校园人际、亲子矛盾和自我内耗，不教育、不施压。
''';
      case CompanionMode.workplace:
        return '''
职场专属模式：你成熟通透，懂加班疲惫、工作焦虑、人际拉扯和生活压力，拒绝鸡血式安慰。
''';
      case CompanionMode.night:
        return '''
深夜树洞模式：你安静治愈、低压力、慢节奏，适合失眠、emo、孤独和深夜闲聊。
''';
    }
  }

  static String buildSystemPrompt({
    required CompanionMode mode,
    required UserMemory memory,
    required List<ChatMessage> recentMessages,
  }) {
    final String memoryLine = '''
长期记忆：高频压力点=${memory.triggers.join('、')}; 陪伴偏好=${memory.preferences.join('、')}; 最近情绪摘要=${memory.lastMoodSummary}
''';
    final String conversation = recentMessages
        .take(8)
        .map(
          (ChatMessage item) => '${item.sender == Sender.user ? '用户' : 'AI'}: ${item.text}',
        )
        .join('\n');

    return '''
$basePersona
${modePrompt(mode)}
$memoryLine
最近对话：
$conversation
''';
  }
}
