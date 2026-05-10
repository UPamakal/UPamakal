import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/listing_model.dart';
import '../models/user_model.dart';
import '../services/listing_service.dart';
import '../utils/constants.dart';
import '../view_models/auth_view_model.dart';

/// --------------------------------------------------------------------------
/// EditListingPage
/// --------------------------------------------------------------------------
/// Allows sellers to edit their existing listings.
/// Features:
///   - Edit title, description, price, category, condition
///   - Update location
///   - Save changes to Firestore
/// --------------------------------------------------------------------------
class EditListingPage extends StatefulWidget {
  final ListingModel listing;

  const EditListingPage({super.key, required this.listing});

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  final ListingService _listingService = ListingService();
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _selectedCategory = '';
  String _selectedCondition = '';
  bool _isSubmitting = false;
  String? _errorMessage;

  static const List<String> categories = [
    'Books',
    'Electronics',
    'Clothing',
    'Food',
    'Sports',
    'furniture',
    'Services',
    'Other',
  ];

  static const List<String> conditions = ['New', 'Like New', 'Used', 'Fair'];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing listing data
    _titleController.text = widget.listing.title;
    _descriptionController.text = widget.listing.description;
    _priceController.text = widget.listing.price.toStringAsFixed(0);
    _locationController.text = widget.listing.location;
    _selectedCategory = widget.listing.category;
    _selectedCondition = widget.listing.condition;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text);
    if (price == null || price < 0) {
      setState(() => _errorMessage = 'Please enter a valid price');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _listingService.updateListing(
        listingId: widget.listing.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        location: _locationController.text.trim(),
        category: _selectedCategory,
        condition: _selectedCondition,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to update listing: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Listing',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _saveChanges,
            child: Text(
              'Save',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _isSubmitting ? Colors.grey : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _errorMessage = null),
                        child: Icon(Icons.close, color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ),

              // Title
              _buildSectionLabel('Item Name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _titleController,
                hint: 'e.g. Calculus Textbook',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an item name';
                  }
                  if (value.trim().length < 3) {
                    return 'Item name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Price and Category row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('Price'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _priceController,
                          hint: '0',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          prefixText: '₱ ',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a price';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price < 0) {
                              return 'Invalid price';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('Category'),
                        const SizedBox(height: 8),
                        _buildCategoryDropdown(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Condition
              _buildSectionLabel('Condition'),
              const SizedBox(height: 8),
              _buildConditionSelector(),
              const SizedBox(height: 20),

              // Location
              _buildSectionLabel('Location'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _locationController,
                hint: 'e.g. UP Diliman, Katipunan',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description
              _buildSectionLabel('Description'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hint: 'Describe your item, condition, reason for selling...',
                maxLines: 5,
                minLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.trim().length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Photo notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'To change photos, please delete and create a new listing.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    int maxLines = 1,
    int minLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        hint: const Text(
          'Select...',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
        onChanged: (val) => setState(() => _selectedCategory = val!),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildConditionSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: conditions.map((condition) {
          final isSelected = _selectedCondition == condition;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCondition = condition),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  condition,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}