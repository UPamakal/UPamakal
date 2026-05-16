import 'package:flutter/material.dart'; 
import 'package:image_picker/image_picker.dart';
import '../models/listing_model.dart';
import '../models/user_model.dart';
import '../services/listing_service.dart';

class CreateListingViewModel extends ChangeNotifier {
  final ListingService _listingService;

  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  
  // Optional offer price controllers
  final minePriceController = TextEditingController();
  final stealPriceController = TextEditingController();
  final grabPriceController = TextEditingController();

  String? _selectedCategory;
  String _selectedCondition = 'New';
  List<XFile> _selectedImages = [];
  bool _isSubmitting = false;
  bool _isSavingDraft = false;
  String? _errorMessage;

  CreateListingViewModel({required ListingService listingService})
      : _listingService = listingService;

  String? get selectedCategory => _selectedCategory;
  String get selectedCondition => _selectedCondition;
  List<XFile> get selectedImages => _selectedImages;
  bool get isSubmitting => _isSubmitting;
  bool get isSavingDraft => _isSavingDraft;
  String? get errorMessage => _errorMessage;
  bool get hasImages => _selectedImages.isNotEmpty;

  static const List<String> categories = [
    'Books',
    'Electronics',
    'Clothing',
    'Food',
    'Furniture',
    'Sports',
    'Services',
    'Other',
  ];

  static const List<String> conditions = ['New', 'Like New', 'Used', 'Fair'];

  void setSelectedCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedCondition(String condition) {
    if (_selectedCondition == condition) return;
    _selectedCondition = condition;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> pickImages() async {
    try {
      final images = await _listingService.pickImages(maxCount: 3);
      _selectedImages = images;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to pick images: $e';
      notifyListeners();
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  bool validateForm() {
    if (titleController.text.trim().isEmpty) {
      _errorMessage = 'Please enter an item name';
      notifyListeners();
      return false;
    }
    if (titleController.text.trim().length < 3) {
      _errorMessage = 'Item name must be at least 3 characters';
      notifyListeners();
      return false;
    }
    if (priceController.text.trim().isEmpty) {
      _errorMessage = 'Please enter a price';
      notifyListeners();
      return false;
    }
    final price = double.tryParse(priceController.text);
    if (price == null || price < 0) {
      _errorMessage = 'Please enter a valid price';
      notifyListeners();
      return false;
    }
    if (_selectedCategory == null) {
      _errorMessage = 'Please select a category';
      notifyListeners();
      return false;
    }
    if (descriptionController.text.trim().isEmpty) {
      _errorMessage = 'Please add a description';
      notifyListeners();
      return false;
    }
    if (descriptionController.text.trim().length < 10) {
      _errorMessage = 'Description must be at least 10 characters';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<ListingModel?> submitListing(UserModel seller) async {
    if (!validateForm()) return null;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final mine = double.tryParse(minePriceController.text);
      final steal = double.tryParse(stealPriceController.text);
      final grab = double.tryParse(grabPriceController.text);

      final listing = await _listingService.createListing(
        title: titleController.text,
        description: descriptionController.text,
        price: double.parse(priceController.text),
        location: 'Campus Area',
        category: _selectedCategory!,
        condition: _selectedCondition,
        seller: seller,
        images: _selectedImages,
        minePrice: mine,
        stealPrice: steal,
        grabPrice: grab,
      );

      _isSubmitting = false;
      notifyListeners();
      return listing;
    } catch (e) {
      _errorMessage = 'Failed to create listing: $e';
      _isSubmitting = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> saveDraft(UserModel seller) async {
    if (titleController.text.isEmpty && descriptionController.text.isEmpty) {
      _errorMessage = 'Please add at least a title or description to save draft';
      notifyListeners();
      return false;
    }

    _isSavingDraft = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final price = double.tryParse(priceController.text) ?? 0;
      final mine = double.tryParse(minePriceController.text);
      final steal = double.tryParse(stealPriceController.text);
      final grab = double.tryParse(grabPriceController.text);
      
      await _listingService.saveDraft(
        title: titleController.text.isEmpty ? 'Untitled Draft' : titleController.text,
        description: descriptionController.text.isEmpty ? 'No description provided' : descriptionController.text,
        price: price,
        location: 'Campus Area',
        category: _selectedCategory ?? categories.first,
        condition: _selectedCondition,
        seller: seller,
        images: _selectedImages,
        minePrice: mine,
        stealPrice: steal,
        grabPrice: grab,
      );

      _isSavingDraft = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save draft: $e';
      _isSavingDraft = false;
      notifyListeners();
      return false;
    }
  }

  void resetForm() {
    titleController.clear();
    priceController.clear();
    descriptionController.clear();
    minePriceController.clear();
    stealPriceController.clear();
    grabPriceController.clear();
    _selectedCategory = null;
    _selectedCondition = 'New';
    _selectedImages = [];
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    minePriceController.dispose();
    stealPriceController.dispose();
    grabPriceController.dispose();
    super.dispose();
  }
}