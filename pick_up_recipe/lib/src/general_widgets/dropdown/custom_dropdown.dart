import 'package:flutter/material.dart';

class CustomDropdown extends StatefulWidget {
  final List<String> items;
  final String placeholder;
  final void Function(String selectedItem) onSelect;

  const CustomDropdown({
    Key? key,
    required this.placeholder,
    required this.items,
    required this.onSelect,
  }) : super(key: key);

  @override
  _CustomDropdownState createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late String _selectedItem;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.placeholder;
    _items = widget.items;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void _toggleDropdown() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _selectItem(String item) {
    setState(() {
      _selectedItem = item;
      _isOpen = false;
      _animationController.reverse();
    });

    widget.onSelect(item);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggleDropdown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedItem, style: const TextStyle(fontSize: 16),),
                Icon(_isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        ClipRect(
          child: AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Align(
                heightFactor: _expandAnimation.value,
                child: child,
              );
            },
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.secondaryContainer),
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isOpen ? 1.0 : 0.0,
                    curve: Interval(
                      index / widget.items.length,
                      1.0,
                      curve: Curves.easeInOut,
                    ),
                    child: GestureDetector(
                      onTap: () => _selectItem(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: index < widget.items.length - 1
                              ? Border(
                                  bottom: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    width: 1,
                                  ),
                                )
                              : null,
                        ),
                        child: Text(item),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
