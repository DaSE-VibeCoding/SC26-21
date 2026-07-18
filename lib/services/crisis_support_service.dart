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
    'do not want to live',
    'cannot go on',
    'suicide',
    'kill myself',
    'end my life',
    'want to die',
    'self harm',
    'jump off',
    'no point',
    'cannot hold on',
  ];

  CrisisSupportResult inspect(String input) {
    final String content = input.trim().toLowerCase();
    final bool hit = _keywords.any(content.contains);
    if (!hit) {
      return const CrisisSupportResult(isCrisis: false, message: '');
    }

    return const CrisisSupportResult(
      isCrisis: true,
      message:
          'You sound in real danger right now. Please do not stay alone with this. Contact someone you trust immediately, and if you might act on it, call emergency help right now.',
    );
  }

  List<String> hotlineLines() {
    return const <String>[
      'US and Canada: 988 Suicide & Crisis Lifeline',
      'Emergency right now: call local emergency services immediately',
      'If possible, ask a trusted person to stay with you in real life',
    ];
  }
}
