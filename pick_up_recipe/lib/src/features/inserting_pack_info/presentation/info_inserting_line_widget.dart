import 'dart:math';
import 'package:flutter/material.dart';

class TextInputWithHints extends StatefulWidget {
  final List<String> hintsArray;
  final String labelText;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const TextInputWithHints({
    super.key,
    required this.hintsArray,
    required this.labelText,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<TextInputWithHints> createState() => _TextInputWithHintsState();
}

class _TextInputWithHintsState extends State<TextInputWithHints>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late FocusNode _focusNode;

  List<String> _filteredHints = [];
  bool _isDropdownVisible = false;
  bool _hintSelected = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _hideDropdown();
      }
    });

    widget.controller.addListener(() {
      if (!_hintSelected) {
        _filterHints(widget.controller.text);
      } else {
        _hintSelected = false;
      }
    });
  }

  void _filterHints(String input) {
    if (!mounted) {
      return;
    }

    if (input.isEmpty) {
      setState(() {
        _filteredHints = [];
        _hideDropdown();
      });
      return;
    }

    setState(() {
      _filteredHints = widget.hintsArray
          .where((hint) =>
              (hint.toLowerCase().contains(input.toLowerCase())) &&
              hint != widget.controller.text)
          .toList();
      if (_filteredHints.isNotEmpty) {
        _showDropdown();
      } else {
        _hideDropdown();
      }
    });
  }

  void _showDropdown() {
    if (!_isDropdownVisible) {
      setState(() {
        _isDropdownVisible = true;
        _animationController.forward();
      });
    }
  }

  void _hideDropdown() {
    if (_isDropdownVisible) {
      setState(() {
        _animationController.reverse();
        _isDropdownVisible = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final InputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(12),
        bottom: _isDropdownVisible
            ? const Radius.circular(0)
            : const Radius.circular(12.0),
      ),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.surface,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                focusNode: _focusNode,
                controller: widget.controller,
                onChanged: (String query) {
                  widget.onChanged(query);
                  _filterHints(query);
                },
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  enabledBorder: inputBorder,
                  border: inputBorder,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                ),
              ),
              SizeTransition(
                sizeFactor: _fadeAnimation,
                child: _buildDropdown(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return AnimatedContainer(
      height: min(_filteredHints.length, 3) * 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 0.7,
        ),
      ),
      duration: const Duration(milliseconds: 100),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: min(_filteredHints.length, 3),
        itemBuilder: (context, index) {
          return SizedBox(
            height: 40,
            child: ListTile(
              title: SizedBox(
                height: 40,
                child: Text(_filteredHints[index]),
              ),
              onTap: () {
                setState(() {
                  _hintSelected = true;
                  widget.controller.text = _filteredHints[index];
                  widget.controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: widget.controller.text.length),
                  );
                  _hideDropdown();
                });
              },
            ),
          );
        },
      ),
    );
  }
}
