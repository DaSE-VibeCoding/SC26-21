import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/chat_models.dart';
import '../services/ai_config.dart';
import '../widgets/breathing_avatar.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  static const Map<CompanionMode, List<String>> _quickPrompts =
      <CompanionMode, List<String>>{
    CompanionMode.general: <String>[
      '今天有点乱，我想先把情绪理一理。',
      '我最近脑子一直停不下来。',
      '你先听我说完就好。',
    ],
    CompanionMode.teen: <String>[
      '最近学习压力有点大。',
      '和朋友之间的事让我很烦。',
      '我有点怕让别人失望。',
    ],
    CompanionMode.workplace: <String>[
      '工作堆得太多了，我有点喘不过气。',
      '我现在光是撑着就很累。',
      '职场里的人和事把我磨得很烦。',
    ],
    CompanionMode.night: <String>[
      '一到晚上情绪就会变大。',
      '我睡不着，脑子一直在转。',
      '我现在就想有人陪我一下。',
    ],
  };

  static const List<_RescueToolData> _rescueTools = <_RescueToolData>[
    _RescueToolData(
      title: '30 秒缓下来',
      subtitle: '胸口发紧的时候，先靠一个很短的呼吸循环缓一下。',
      icon: Icons.air_rounded,
      color: Color(0xFF7A78F2),
      steps: <String>[
        '吸气 4 秒。',
        '停 2 秒。',
        '呼气 6 秒。',
        '重复 4 轮，先别逼自己处理别的事。',
      ],
    ),
    _RescueToolData(
      title: '5-4-3-2-1 落地法',
      subtitle: '适合心慌、发飘、脑子转太快的时候。',
      icon: Icons.center_focus_strong_rounded,
      color: Color(0xFF4FAE98),
      steps: <String>[
        '说出 5 个你能看见的东西。',
        '摸到 4 个你能感受到的东西。',
        '注意 3 个你能听见的声音。',
        '说出 2 个你能闻到的味道。',
        '对自己说 1 句稳住的话。',
      ],
    ),
    _RescueToolData(
      title: '睡前慢一点',
      subtitle: '适合睡前停不下来、越想越多的时候。',
      icon: Icons.nightlight_round_rounded,
      color: Color(0xFF6286D8),
      steps: <String>[
        '先把周围灯光调暗一点。',
        '告诉自己，今晚不是拿来想通整个人生的。',
        '写下明天最重要的一件事，让它先离开脑子。',
        '如果愿意，再把最卡住的那句带回聊天页。',
      ],
    ),
    _RescueToolData(
      title: '给自己一句稳住的话',
      subtitle: '适合自责、快崩、想往下掉的时候。',
      icon: Icons.favorite_outline_rounded,
      color: Color(0xFFE2857F),
      steps: <String>[
        '我现在很难受，但这不等于我就完了。',
        '我先照顾好这一刻就够了。',
        '我已经很努力了。',
        '如果需要，我可以去找真实的人支持我。',
      ],
    ),
  ];

  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _moodController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  AppController get controller => widget.controller;

  @override
  void dispose() {
    _inputController.dispose();
    _moodController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    if (controller.latestSafetyAlert != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showSafetySheet());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (controller.isBootstrapping) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> pages = <Widget>[
      _buildHomePage(context),
      _buildChatPage(context),
      _buildRescuePage(context),
      _buildMemoryPage(context),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFFF3F5FF), Color(0xFFFFFBFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: IndexedStack(
            index: controller.currentTabIndex,
            children: pages,
          ),
        ),
      ),
      bottomNavigationBar: keyboardVisible
          ? null
          : NavigationBar(
              selectedIndex: controller.currentTabIndex,
              onDestinationSelected: controller.switchTab,
              destinations: const <NavigationDestination>[
                NavigationDestination(icon: Icon(Icons.home_rounded), label: '首页'),
                NavigationDestination(icon: Icon(Icons.chat_bubble_rounded), label: '聊天'),
                NavigationDestination(icon: Icon(Icons.health_and_safety_rounded), label: '急救包'),
                NavigationDestination(icon: Icon(Icons.auto_stories_rounded), label: '记忆'),
              ],
            ),
    );
  }

  Widget _buildHomePage(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildHero(),
                const SizedBox(height: 20),
                _SectionCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _SectionHeader(
                        title: '情绪打卡',
                        subtitle: '留下一点当下状态，让这次陪伴不总是从零开始。',
                        trailing: controller.latestMoodEntry == null
                            ? null
                            : _SoftBadge(
                                label: '最近一次 · ${controller.latestMoodEntry!.mood.label}',
                                color: controller.latestMoodEntry!.mood.color,
                              ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 96,
                        ),
                        itemCount: MoodType.values.length,
                        itemBuilder: (BuildContext context, int index) {
                          final MoodType mood = MoodType.values[index];
                          return _MoodChip(
                            mood: mood,
                            selected: controller.selectedMood == mood,
                            onTap: () => controller.selectMood(mood),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _moodController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: '今天最卡你的是什么，或者你现在最需要什么？',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              controller.shouldShowReminderNudge()
                                  ? controller.reminderSubtitle()
                                  : '只保存在本地，用来帮它更像真人一样记得你。',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF67708A),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: controller.isSavingMood ? null : _handleMoodSave,
                            icon: controller.isSavingMood
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.check_rounded),
                            label: const Text('保存'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const _SectionHeader(
                        title: '最近情绪轨迹',
                        subtitle: '不评判你，只是帮你看见最近的自己。',
                      ),
                      const SizedBox(height: 16),
                      if (controller.recentMoodEntries.isEmpty)
                        const _EmptyHint(
                          text: '还没有打卡记录，先记下一次状态吧。',
                          icon: Icons.insights_rounded,
                        )
                      else
                        SizedBox(
                          height: 108,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (BuildContext context, int index) {
                              final MoodEntry entry = controller.recentMoodEntries[index];
                              return _MoodHistoryTile(entry: entry);
                            },
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemCount: controller.recentMoodEntries.length,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _SectionHeader(
                        title: '现在就能开始',
                        subtitle: '选一个最贴近你当下处境的陪伴模式。',
                        trailing: IconButton(
                          onPressed: () => controller.switchTab(1),
                          tooltip: '去聊天',
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 144,
                        ),
                        itemCount: CompanionMode.values.length,
                        itemBuilder: (BuildContext context, int index) {
                          final CompanionMode mode = CompanionMode.values[index];
                          return _ModeLaunchCard(
                            mode: mode,
                            onTap: () => controller.startNewSession(mode),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _SectionHeader(
                        title: '回复偏好',
                        subtitle: '你可以直接决定它怎么陪你。',
                        trailing: TextButton(
                          onPressed: _showPreferenceSheet,
                          child: const Text('调整'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.responsePreference.enabledLabels
                            .map((String label) => _TagPill(label: label))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatPage(BuildContext context) {
    final ChatSession session = controller.activeSession;
    final bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(20, keyboardVisible ? 8 : 16, 20, 12),
          child: _SectionCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const BreathingAvatar(size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '当前模式',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              Text(
                                session.mode.label,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              _SoftBadge(
                                label: session.mode.personaTitle,
                                color: _modeColor(session.mode),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _showPreferenceSheet,
                      tooltip: '回复偏好',
                      icon: const Icon(Icons.tune_rounded),
                    ),
                    IconButton(
                      onPressed: controller.isSending
                          ? null
                          : () => controller.startNewSession(session.mode),
                      tooltip: '新建会话',
                      icon: const Icon(Icons.add_comment_rounded),
                    ),
                  ],
                ),
                if (!keyboardVisible && controller.shouldShowReminderNudge()) ...<Widget>[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F2FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.notifications_active_rounded,
                          color: Color(0xFF7A78F2),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            controller.reminderSubtitle(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!keyboardVisible && !AiConfig.isConfigured)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.info_outline_rounded, color: Color(0xFFAF7A00)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('API 还没配置好，现在先使用本地兜底陪伴回复。'),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: Column(
            children: <Widget>[
              if (!keyboardVisible && session.messages.length <= 1)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '如果不知道怎么开口，可以直接点一句',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (_quickPrompts[session.mode] ?? const <String>[])
                            .map(
                              (String prompt) => ActionChip(
                                label: Text(prompt),
                                onPressed: controller.isSending
                                    ? null
                                    : () => _sendQuickPrompt(prompt),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(20, keyboardVisible ? 4 : 12, 20, 20),
                  itemBuilder: (BuildContext context, int index) {
                    final ChatMessage message = session.messages[index];
                    final bool isUser = message.sender == Sender.user;
                    final Color bubbleColor = isUser
                        ? Theme.of(context).colorScheme.primary
                        : (message.isSafety ? const Color(0xFFFFF0F1) : Colors.white);
                    final Color textColor = isUser ? Colors.white : const Color(0xFF24283B);

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 312),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(color: textColor, height: 1.45),
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: session.messages.length,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _inputController,
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: '把想说的话留在这里',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 54,
                height: 54,
                child: FilledButton(
                  onPressed: controller.isSending ? null : _handleSend,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: controller.isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.arrow_upward_rounded),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRescuePage(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF1F2545), Color(0xFF3A4F8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        '情绪急救包',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '不用等到特别严重再来用，这里放的是几种能立刻帮你稳一点的小工具。',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.86),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ..._rescueTools.map(
                  (_RescueToolData tool) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _RescueToolCard(
                      tool: tool,
                      onTap: () => _showRescueTool(tool),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _SectionCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const _SectionHeader(
                        title: '如果你需要真人支持',
                        subtitle: '这不是失败，是在照顾自己。',
                      ),
                      const SizedBox(height: 12),
                      ...controller.hotlineLines().map(
                        (String item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Icon(Icons.circle, size: 8, color: Color(0xFF6A7393)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(item)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryPage(BuildContext context) {
    final List<ChatSession> sessions = controller.sessions;

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SectionCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const _SectionHeader(
                        title: '更像真人的记忆面板',
                        subtitle: '这里放的是最近反复出现的线索，你也可以手动删掉。',
                      ),
                      const SizedBox(height: 16),
                      if (controller.memoryHighlights.isEmpty)
                        const _EmptyHint(
                          text: '现在还没有记忆线索，多聊几次后这里会慢慢长出来。',
                          icon: Icons.auto_stories_rounded,
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: controller.memoryHighlights.map((String item) {
                            final String raw = _rawMemoryValue(item);
                            return InputChip(
                              label: Text(item),
                              onDeleted: () => controller.removeMemoryItem(raw),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _SectionHeader(
                        title: '提醒机制',
                        subtitle: controller.reminderHeadline(),
                        trailing: TextButton(
                          onPressed: _showReminderSheet,
                          child: const Text('设置'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _MetricCard(
                              title: '状态',
                              value: controller.reminderSettings.enabled ? '已开启' : '已关闭',
                              color: controller.reminderSettings.enabled
                                  ? const Color(0xFF7A78F2)
                                  : const Color(0xFF969CB1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              title: '时间',
                              value: controller.reminderSettings.formattedTime,
                              color: const Color(0xFF4FAE98),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          controller.reminderSubtitle(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF5F6783),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '本地历史记录',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: sessions.isEmpty ? null : () => _confirmClearAll(context),
                            icon: const Icon(Icons.delete_sweep_rounded),
                            label: const Text('清空全部'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '聊天、打卡和记忆都只保存在当前设备的本地加密存储里。',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF67708A),
                            ),
                      ),
                      const SizedBox(height: 16),
                      if (sessions.isEmpty)
                        const _EmptyHint(
                          text: '还没有聊天记录，先去首页开始一次吧。',
                          icon: Icons.history_rounded,
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (BuildContext context, int index) {
                            final ChatSession session = sessions[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                title: Text(
                                  session.mode.label,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        _sessionMeta(session),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        session.preview,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: IconButton(
                                  onPressed: () => controller.deleteSession(session.id),
                                  icon: const Icon(Icons.delete_outline_rounded),
                                  tooltip: '删除',
                                ),
                                onTap: () => controller.openSession(session.id),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemCount: sessions.length,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF746FF6), Color(0xFF9CB0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF746FF6).withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '愈心 AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '懂你的情绪，陪你慢慢说，也陪你慢慢缓下来。',
                      style: TextStyle(
                        color: Color(0xFFF4F1FF),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const BreathingAvatar(size: 72),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _GlassPill(label: controller.reminderSettings.enabled ? '提醒已开启' : '提醒已关闭'),
            ],
          ),
          const SizedBox(height: 18),
          if (controller.shouldShowReminderNudge())
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.notifications_active_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      controller.reminderSubtitle(),
                      style: const TextStyle(color: Colors.white, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => controller.switchTab(2),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5B58D6),
                  ),
                  icon: const Icon(Icons.health_and_safety_rounded),
                  label: const Text('打开急救包'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => controller.startNewSession(controller.selectedMode),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E325E),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('开始聊天'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleSend() {
    final String content = _inputController.text.trim();
    if (content.isEmpty) {
      return;
    }
    _inputController.clear();
    controller.sendMessage(content);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _handleMoodSave() async {
    await controller.saveMoodEntry(_moodController.text);
    _moodController.clear();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已记录今天的「${controller.selectedMood.label}」'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _sendQuickPrompt(String prompt) {
    _inputController.clear();
    controller.sendMessage(prompt);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 120,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('清空全部记录'),
          content: const Text('这会删除本地聊天、情绪打卡和记忆，而且无法恢复。'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认清空'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await controller.clearHistory();
    }
  }

  Future<void> _showSafetySheet() async {
    if (!mounted || controller.latestSafetyAlert == null) {
      return;
    }

    final String latest = controller.latestSafetyAlert!;
    controller.latestSafetyAlert = null;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '请优先联系真实支持',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(latest),
              const SizedBox(height: 14),
              ...controller.hotlineLines().map(
                (String item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(item),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPreferenceSheet() async {
    ResponsePreference draft = controller.responsePreference;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Widget buildSwitchTile({
              required String title,
              required String subtitle,
              required bool value,
              required ValueChanged<bool> onChanged,
            }) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  value: value,
                  onChanged: onChanged,
                  contentPadding: EdgeInsets.zero,
                  title: Text(title),
                  subtitle: Text(subtitle),
                ),
              );
            }

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      '回复偏好',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text('你可以直接决定它怎么回应你。'),
                    const SizedBox(height: 16),
                    buildSwitchTile(
                      title: '先接住情绪',
                      subtitle: '先听懂你，而不是立刻分析你。',
                      value: draft.quietCompanionship,
                      onChanged: (bool value) {
                        setModalState(() {
                          draft = draft.copyWith(quietCompanionship: value);
                        });
                      },
                    ),
                    buildSwitchTile(
                      title: '给一点建议',
                      subtitle: '当我明确求助时，再给轻量建议。',
                      value: draft.actionableAdvice,
                      onChanged: (bool value) {
                        setModalState(() {
                          draft = draft.copyWith(actionableAdvice: value);
                        });
                      },
                    ),
                    buildSwitchTile(
                      title: '回答短一点',
                      subtitle: '适合不想看太长文字的时候。',
                      value: draft.conciseReplies,
                      onChanged: (bool value) {
                        setModalState(() {
                          draft = draft.copyWith(conciseReplies: value);
                        });
                      },
                    ),
                    buildSwitchTile(
                      title: '别太说教',
                      subtitle: '更柔和一点，少一点“你应该”。',
                      value: draft.gentleTone,
                      onChanged: (bool value) {
                        setModalState(() {
                          draft = draft.copyWith(gentleTone: value);
                        });
                      },
                    ),
                    buildSwitchTile(
                      title: '深夜更轻一点',
                      subtitle: '在深夜模式里更安静、更慢一点。',
                      value: draft.nightSoftness,
                      onChanged: (bool value) {
                        setModalState(() {
                          draft = draft.copyWith(nightSoftness: value);
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          await controller.updateResponsePreference(draft);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('保存偏好'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showReminderSheet() async {
    ReminderSettings draft = controller.reminderSettings;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> pickTime() async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: draft.hour, minute: draft.minute),
              );
              if (picked == null) {
                return;
              }
              setModalState(() {
                draft = draft.copyWith(hour: picked.hour, minute: picked.minute);
              });
            }

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      '提醒机制',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text('这版先做成应用内提醒，在你设定的时间附近打开应用时，会主动提醒你来打卡。'),
                    const SizedBox(height: 18),
                    SwitchListTile(
                      value: draft.enabled,
                      onChanged: (bool value) {
                        setModalState(() {
                          draft = draft.copyWith(enabled: value);
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text('开启每日提醒'),
                      subtitle: const Text('在你设定的时间附近提示你做一次情绪打卡。'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('提醒时间'),
                      subtitle: Text(draft.formattedTime),
                      trailing: OutlinedButton(
                        onPressed: pickTime,
                        child: const Text('修改'),
                      ),
                    ),
                    SwitchListTile(
                      value: draft.weekdayOnly,
                      onChanged: (bool value) {
                        setModalState(() {
                          draft = draft.copyWith(weekdayOnly: value);
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text('仅工作日提醒'),
                      subtitle: const Text('周末先不催你。'),
                    ),
                    SwitchListTile(
                      value: draft.gentleNudge,
                      onChanged: (bool value) {
                        setModalState(() {
                          draft = draft.copyWith(gentleNudge: value);
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text('使用温柔文案'),
                      subtitle: const Text('提醒时更像轻轻拍一下肩膀。'),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          await controller.updateReminderSettings(draft);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('保存提醒设置'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showRescueTool(_RescueToolData tool) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: tool.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(tool.icon, color: tool.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            tool.title,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(tool.subtitle),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ...tool.steps.asMap().entries.map(
                  (MapEntry<int, String> entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: tool.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              color: tool.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(entry.value)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      controller.switchTab(1);
                      _inputController.text = '我刚刚用了「${tool.title}」，现在想继续说说。';
                    },
                    icon: const Icon(Icons.chat_rounded),
                    label: const Text('带着这个状态去聊天'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _sessionMeta(ChatSession session) {
    final DateTime time = session.updatedAt;
    final String date =
        '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final int rounds = ((session.messages.length - 1) / 2).ceil().clamp(0, 999);
    return '$date · $rounds 轮对话';
  }

  String _rawMemoryValue(String label) {
    const List<String> prefixes = <String>['压力点：', '缓和线索：', '偏好：'];
    for (final String prefix in prefixes) {
      if (label.startsWith(prefix)) {
        return label.substring(prefix.length);
      }
    }
    return label;
  }

  static Color _modeColor(CompanionMode mode) {
    switch (mode) {
      case CompanionMode.general:
        return const Color(0xFF7A78F2);
      case CompanionMode.teen:
        return const Color(0xFFE98F54);
      case CompanionMode.workplace:
        return const Color(0xFF4AA797);
      case CompanionMode.night:
        return const Color(0xFF5A6BD6);
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6E9F6)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF67708A),
                    ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  final MoodType mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? mood.color.withValues(alpha: 0.16) : const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? mood.color : const Color(0xFFE7EAF4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(mood.icon, color: mood.color, size: 18),
            const Spacer(),
            Text(
              mood.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              mood.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF66708A),
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodHistoryTile extends StatelessWidget {
  const _MoodHistoryTile({required this.entry});

  final MoodEntry entry;

  @override
  Widget build(BuildContext context) {
    final DateTime time = entry.createdAt;
    final String label = '${time.month}/${time.day}';

    return Container(
      width: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: entry.mood.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(entry.mood.icon, color: entry.mood.color),
          const Spacer(),
          Text(
            entry.mood.label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF66708A),
                ),
          ),
          if (entry.note.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              entry.note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeLaunchCard extends StatelessWidget {
  const _ModeLaunchCard({
    required this.mode,
    required this.onTap,
  });

  final CompanionMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    switch (mode) {
      case CompanionMode.general:
        icon = Icons.favorite_rounded;
      case CompanionMode.teen:
        icon = Icons.auto_awesome_rounded;
      case CompanionMode.workplace:
        icon = Icons.work_history_rounded;
      case CompanionMode.night:
        icon = Icons.dark_mode_rounded;
    }

    final Color accent = _ShellPageState._modeColor(mode);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              mode.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                mode.shortDescription,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF5F6783),
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RescueToolData {
  const _RescueToolData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.steps,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> steps;
}

class _RescueToolCard extends StatelessWidget {
  const _RescueToolCard({
    required this.tool,
    required this.onTap,
  });

  final _RescueToolData tool;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE6E9F6)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: tool.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(tool.icon, color: tool.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    tool.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tool.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF5F6783),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF67708A),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: const Color(0xFF7D86A3)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF67708A),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
