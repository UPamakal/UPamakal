import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// --------------------------------------------------------------------------
/// YearPickerField
/// --------------------------------------------------------------------------
/// A field for selecting a year with text input and suggestions.
/// Allows typing any year or selecting from recent years.
/// --------------------------------------------------------------------------
class YearPickerField extends StatefulWidget {
  final int? value;
  final String label;
  final String hint;
  final void Function(int?) onChanged;
  final bool isRequired;
  final String? errorText;

  const YearPickerField({
    super.key,
    required this.value,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.isRequired = false,
    this.errorText,
  });

  @override
  State<YearPickerField> createState() => _YearPickerFieldState();
}

class _YearPickerFieldState extends State<YearPickerField> {
  final TextEditingController _controller = TextEditingController();
  bool _showSuggestions = false;
  
  // Generate last 10 years + next 2 years
  List<int> get _suggestedYears {
    final currentYear = DateTime.now().year;
    final years = <int>[];
    for (int i = currentYear - 10; i <= currentYear + 2; i++) {
      years.add(i);
    }
    return years;
  }

  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      _controller.text = widget.value!.toString();
    }
  }

  @override
  void didUpdateWidget(YearPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != null) {
      _controller.text = widget.value!.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTextChange(String text) {
    final parsed = int.tryParse(text);
    widget.onChanged(parsed);
    setState(() {
      _showSuggestions = text.isNotEmpty;
    });
  }

  void _selectYear(int year) {
    _controller.text = year.toString();
    widget.onChanged(year);
    setState(() {
      _showSuggestions = false;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          onChanged: _handleTextChange,
          onTap: () => setState(() => _showSuggestions = true),
          onEditingComplete: () => setState(() => _showSuggestions = false),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            suffixIcon: widget.value != null
                ? IconButton(
                    icon: Icon(Icons.clear, size: 18, color: Colors.grey.shade400),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged(null);
                    },
                  )
                : null,
            errorText: widget.errorText,
            errorStyle: TextStyle(fontSize: 12, color: Colors.red.shade700),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        if (_showSuggestions && _controller.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12), // ← FIX: Moved padding here
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Suggestions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  // ← REMOVED: padding parameter (Wrap doesn't accept it)
                  children: _suggestedYears.map((year) {
                    return GestureDetector(
                      onTap: () => _selectYear(year),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: widget.value == year
                              ? AppColors.primaryLight
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.value == year
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          year.toString(),
                          style: TextStyle(
                            fontWeight: widget.value == year
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: widget.value == year
                                ? AppColors.primary
                                : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}