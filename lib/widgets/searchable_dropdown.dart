import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// --------------------------------------------------------------------------
/// SearchableDropdown
/// --------------------------------------------------------------------------
/// A dropdown that allows searching/filtering of options.
/// Useful for long lists like courses (20+ items).
/// --------------------------------------------------------------------------
class SearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? value;
  final String hint;
  final String label;
  final String Function(T) displayValue;
  final void Function(T?) onChanged;
  final bool isRequired;
  final String? errorText;

  const SearchableDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.hint,
    required this.label,
    required this.displayValue,
    required this.onChanged,
    this.isRequired = false,
    this.errorText,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showDropdown = false;

  List<T> get _filteredItems {
    if (_searchQuery.isEmpty) return widget.items;
    return widget.items.where((item) {
      final display = widget.displayValue(item).toLowerCase();
      return display.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String get _displayText {
    if (widget.value != null) return widget.displayValue(widget.value!);
    return widget.hint;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        GestureDetector(
          onTap: () {
            setState(() => _showDropdown = !_showDropdown);
            if (!_showDropdown) {
              _searchController.clear();
              _searchQuery = '';
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.errorText != null
                    ? Colors.red.shade300
                    : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _displayText,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.value != null
                          ? Colors.black87
                          : Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  _showDropdown
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              widget.errorText!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ),
        if (_showDropdown)
          Container(
            margin: const EdgeInsets.only(top: 8),
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
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                const Divider(height: 0),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = widget.value == item;
                      return ListTile(
                        dense: true,
                        title: Text(
                          widget.displayValue(item),
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? AppColors.primary : Colors.black87,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check, color: AppColors.primary, size: 18)
                            : null,
                        onTap: () {
                          widget.onChanged(item);
                          setState(() {
                            _showDropdown = false;
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}