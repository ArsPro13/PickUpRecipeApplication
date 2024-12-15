import 'package:flutter/material.dart';

class NumberInput extends StatefulWidget {
  const NumberInput({
    super.key,
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  _NumberInputState createState() => _NumberInputState();
}

class _NumberInputState extends State<NumberInput> {
  double _fillPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateFillPercentage);
    _updateFillPercentage(); // Убедимся, что начальное значение обработано
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateFillPercentage);
    super.dispose();
  }

  void _updateFillPercentage() {
    final value = widget.controller.text;
    int? number = int.tryParse(value);
    if (number != null && number >= 1 && number <= 100) {
      setState(() {
        _fillPercentage = number / 100;
      });
    } else {
      setState(() {
        _fillPercentage = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            height: 45,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).colorScheme.secondaryContainer,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                )),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: _fillPercentage),
            duration: const Duration(milliseconds: 200),
            builder: (context, value, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    ),
                  ),
                ),
              );
            },
          ),
          TextField(
            controller: widget.controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              hintText: widget.hintText,
            ),
          ),
        ],
      ),
    );
  }
}
