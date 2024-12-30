import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateInputField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;

  const DateInputField(
      {super.key, required this.hintText, required this.controller});

  @override
  State<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<DateInputField>
    with SingleTickerProviderStateMixin {
  DateTime? selectedDate;
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  late AnimationController _controller;
  late Animation<double> _iconRotation;
  bool isPickerVisible = false;
  late Color _containerColor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _iconRotation = Tween<double>(begin: 0.0, end: .5)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    widget.controller.text = widget.hintText;
  }

  void _togglePicker() {
    setState(() {
      isPickerVisible = !isPickerVisible;
      if (isPickerVisible) {
        _controller.forward();
        _containerColor = Theme.of(context).colorScheme.secondaryContainer;
      } else {
        _controller.reverse();
        _containerColor = Theme.of(context).colorScheme.secondaryContainer;
      }
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      selectedDate = date;
      widget.controller.text = _dateFormat.format(selectedDate!);
      isPickerVisible = false;
      _controller.reverse();
      _containerColor = Theme.of(context).colorScheme.secondaryContainer;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _containerColor = Theme.of(context).colorScheme.secondaryContainer;
    return GestureDetector(
      onTap: _togglePicker,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: _containerColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  RotationTransition(
                    turns: _iconRotation,
                    child: Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 35,
                      child: TextField(
                        controller: widget.controller,
                        onTap: _togglePicker,
                        readOnly: true,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.only(top: 4),
                          hintText: widget.hintText,
                          hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.secondary),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizeTransition(
              sizeFactor: CurvedAnimation(
                parent: _controller,
                curve: Curves.easeInOut,
              ),
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                child: CalendarDatePicker(
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2010),
                  lastDate: DateTime.now(),
                  onDateChanged: _onDateSelected,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
