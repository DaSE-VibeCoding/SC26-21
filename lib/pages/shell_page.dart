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
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  AppController get controller => widget.controller;

  @override
  void dispose() {
    _inputController.dispose();
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
    if (controller.isBootstrapping) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> pages = <Widget>[
      _buildHomePage(context),
      _buildChatPage(context),
      _buildHistoryPage(context),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: controller.currentTabIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: controller.currentTabIndex,
        onDestinationSelected: controller.switchTab,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_rounded), label: '首页'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_rounded), label: '聊天'),
          NavigationDestination(icon: Icon(Icons.history_rounded), label: '记录'),
        ],
      ),
    );
  }

  Widget _buildHomePage(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '愈芯 AI',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  '懂你的情绪，陪你释怀，予你温柔疏导。',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF5E627A),
                      ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFFECE8FF), Color(0xFFFDF7FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      const BreathingAvatar(size: 74),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '匿名开启，打开就能说。',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '无登录、无广告、无社区。所有记录仅本地加密保存，不上传云端。',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    _InfoPill(label: '7x24 陪伴'),
                    const SizedBox(width: 10),
                    _InfoPill(label: '本地加密'),
                    const SizedBox(width: 10),
                    _InfoPill(label: '轻量疏导'),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          sliver: SliverList.separated(
            itemBuilder: (BuildContext context, int index) {
              final CompanionMode mode = CompanionMode.values[index];
              return _ModeCard(
                mode: mode,
                selected: controller.selectedMode == mode,
                onTap: () => controller.selectMode(mode),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemCount: CompanionMode.values.length,
          ),
        ),
      ],
    );
  }

  Widget _buildChatPage(BuildContext context) {
    final ChatSession session = controller.activeSession;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Row(
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
                    Row(
                      children: <Widget>[
                        Text(
                          session.mode.label,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(session.mode.personaTitle),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!AiConfig.isConfigured)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
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
                  child: Text(
                    '大模型 API 地址和 Key 还没填写，当前先用本地陪伴回复逻辑。后续你补上配置就能接真实接口。',
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: textColor,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: session.messages.length,
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
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
                width: 52,
                height: 52,
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

  Widget _buildHistoryPage(BuildContext context) {
    final List<ChatSession> sessions = controller.sessions;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '本地历史记录',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
            '仅保存在当前设备的加密存储中，不上传、不备份、删除后不可恢复。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF676C82),
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: sessions.isEmpty
                ? Center(
                    child: Text(
                      '还没有聊天记录，去首页选一个模式开始吧。',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.separated(
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
                            child: Text(
                              session.preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: IconButton(
                            onPressed: () => controller.deleteSession(session.id),
                            icon: const Icon(Icons.delete_outline_rounded),
                            tooltip: '删除',
                          ),
                          onTap: () {
                            controller.selectMode(session.mode);
                          },
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: sessions.length,
                  ),
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
          content: const Text('这会彻底删除本地历史和长期记忆，且无法恢复。'),
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
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final CompanionMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final List<IconData> icons = <IconData>[
      Icons.favorite_rounded,
      Icons.auto_awesome_rounded,
      Icons.work_history_rounded,
      Icons.dark_mode_rounded,
    ];
    final List<String> detail = <String>[
      '日常情绪宣泄、心态调节、轻度疏导',
      '学业压力、考试焦虑、校园关系、亲子矛盾',
      '加班内耗、人际拉扯、工作焦虑、生活压力',
      '失眠低落、孤独迷茫、夜间闲聊、松弛陪伴',
    ];
    final int index = CompanionMode.values.indexOf(mode);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: selected ? const Color(0xFFECEBFF) : Colors.white.withValues(alpha: 0.92),
          border: Border.all(
            color: selected ? const Color(0xFF8883FF) : Colors.white,
            width: 1.2,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icons[index], color: const Color(0xFF7873F1)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    mode.label,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detail[index],
                    style: const TextStyle(height: 1.4, color: Color(0xFF5F657A)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
