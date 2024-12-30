import 'package:flutter/material.dart';

class PrimaryButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget centerWidget;
  final bool? isActive;

  const PrimaryButton({
    super.key,
    required this.onTap,
    required this.centerWidget,
    this.isActive,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.9,
      upperBound: 1.0,
    );
    _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isActive ?? true) {
      _controller.reverse();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isActive ?? true) {
      _controller.forward();
      widget.onTap();
    }
  }

  void _handleTapCancel() {
    if (widget.isActive ?? true) {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _controller,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: widget.isActive ?? true
                ? Theme.of(context).colorScheme.secondaryContainer
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
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
