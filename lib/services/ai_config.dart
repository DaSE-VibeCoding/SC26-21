import 'ai_config_local.dart';

class AiConfig {
  const AiConfig._();

  static const String apiBaseUrl = 'https://chat.ecnu.edu.cn/open/api/v1';
  static const String apiKey = AiConfigLocal.apiKey;
  static const String chatCompletionsPath = '/chat/completions';
  static const String model = 'ecnu-plus';
  static const bool enableThinking = false;

  static bool get isConfigured {
    return apiKey != 'YOUR_API_KEY';
  }
}
