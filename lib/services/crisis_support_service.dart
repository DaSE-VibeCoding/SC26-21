class CrisisSupportResult {
  const CrisisSupportResult({
    required this.isCrisis,
    required this.message,
  });

  final bool isCrisis;
  final String message;
}

class CrisisSupportService {
  static const List<String> _keywords = <String>[
    '不想活',
    '活不下去',
    '轻生',
    '自杀',
    '结束自己',
    '想死',
    '割腕',
    '跳楼',
    '没有意义',
    '撑不住了',
    '不如死',
  ];

  CrisisSupportResult inspect(String input) {
    final String content = input.trim();
    final bool hit = _keywords.any(content.contains);
    if (!hit) {
      return const CrisisSupportResult(isCrisis: false, message: '');
    }

    return const CrisisSupportResult(
      isCrisis: true,
      message:
          '你现在一定很难受，先别一个人扛着。请立刻联系信任的亲友，或尽快寻求专业支持。若有现实危险，请马上拨打 120 或 110。',
    );
  }

  List<String> hotlineLines() {
    return const <String>[
      '全国统一心理援助热线：12356',
      '生命危急或已实施自伤：120 / 110',
      '也可以马上联系身边信任的人陪着你。',
    ];
  }
}
