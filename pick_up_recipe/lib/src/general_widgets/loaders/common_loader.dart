import 'package:flutter/material.dart';

class CommonLoader extends StatefulWidget {
  const CommonLoader({super.key});

  @override
  _CommonLoaderState createState() => _CommonLoaderState();
}

class _CommonLoaderState extends State<CommonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Transform.scale(
        scale: 2.0,
        child: Icon(
          Icons.coffee,
          size: 50.0,
          color: Colors.brown[900],
        ),
      ),
    );
  }
}
