import 'package:flutter/material.dart';

class BreathingAvatar extends StatefulWidget {
  const BreathingAvatar({
    super.key,
    this.size = 72,
  });

  final double size;

  @override
  State<BreathingAvatar> createState() => _BreathingAvatarState();
}

class _BreathingAvatarState extends State<BreathingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.92, end: 1.10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.20, end: 0.42).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF7A78F2), Color(0xFF9EB9FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF7A78F2).withValues(alpha: _glow.value),
                  blurRadius: 34,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Transform.scale(
                scale: 0.96 + (_controller.value * 0.12),
                child: Container(
                  width: widget.size * 0.52,
                  height: widget.size * 0.52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    size: widget.size * 0.30,
                    color: const Color(0xFF7A78F2),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
