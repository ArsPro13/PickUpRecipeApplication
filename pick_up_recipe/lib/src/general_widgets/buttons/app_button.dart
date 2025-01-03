import 'package:flutter/material.dart';

enum AppButtonStyle {
  primary,
  secondary,
}

class AppButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget centerWidget;
  final bool? isActive;
  final AppButtonStyle buttonStyle;

  const AppButton({
    super.key,
    required this.onTap,
    required this.centerWidget,
    this.isActive,
    required this.buttonStyle,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.85,
      upperBound: 1.0,
    );
    _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTapDown(TapDownDetails details) async {
    if (widget.isActive ?? true) {
      await _controller.animateTo(
        0.85,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleTapUp(TapUpDetails details) async {
    if (widget.isActive ?? true) {
      await _controller.animateTo(
        1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
      widget.onTap();
    }
  }

  void _handleTapCancel() async {
    if (widget.isActive ?? true) {
      await _controller.animateTo(
        0.9,
        duration: const Duration(milliseconds: 50),
        curve: Curves.easeOut,
      );
      await _controller.animateTo(
        1,
        duration: const Duration(milliseconds: 50),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = switch (widget.buttonStyle) {
      AppButtonStyle.primary => Theme.of(context).colorScheme.primary,
      AppButtonStyle.secondary =>
        Theme.of(context).colorScheme.secondaryContainer,
    };

    if (!(widget.isActive ?? true)) {
      bgColor = bgColor.withOpacity(0.5);
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _controller,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: widget.centerWidget,
          ),
        ),
      ),
    );
  }
}
