import 'package:flutter/material.dart';

import 'controllers/app_controller.dart';
import 'pages/shell_page.dart';
import 'services/companion_service.dart';
import 'services/local_store_service.dart';
import 'ui/theme.dart';

class YuXinApp extends StatefulWidget {
  const YuXinApp({super.key});

  @override
  State<YuXinApp> createState() => _YuXinAppState();
}

class _YuXinAppState extends State<YuXinApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController(
      store: LocalStoreService(),
      companionService: CompanionService(),
    )..bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return MaterialApp(
          title: '愈心 AI',
          debugShowCheckedModeBanner: false,
          theme: buildYuXinTheme(),
          home: ShellPage(controller: _controller),
        );
      },
    );
  }
}
