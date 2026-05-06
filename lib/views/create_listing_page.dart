import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../utils/constants.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/create_listing_view_model.dart';
import '../services/listing_service.dart';

/// --------------------------------------------------------------------------
/// CreateListingPage
/// --------------------------------------------------------------------------
/// A fully functional page for creating new marketplace listings.
/// Features:
///   - Image picking (up to 5 images)
///   - Form validation
///   - Submit to Firestore
///   - Save drafts
/// --------------------------------------------------------------------------
class CreateListingPage extends StatelessWidget {
  const CreateListingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Create the ViewModel at the route level
    return ChangeNotifierProvider(
      create: (context) => CreateListingViewModel(
        listingService: ListingService(),
      ),
      child: const _CreateListingPageContent(),
    );
  }
}

class _CreateListingPageContent extends StatefulWidget {
  const _CreateListingPageContent();

  @override
  State<_CreateListingPageContent> createState() => _CreateListingPageContentState();
}

class _CreateListingPageContentState extends State<_CreateListingPageContent> {
  Future<void> _submitListing(CreateListingViewModel viewModel) async {
    final authVM = context.read<AuthViewModel>();
    final user = authVM.user;

    if (user == null) {
      _showError('You must be logged in to post a listing');
      return;
    }

    final listing = await viewModel.submitListing(user);

    if (mounted && listing != null) {
      _showSuccess('Listing posted successfully! 🎉');
      Navigator.of(context).pop(true);
    } else if (mounted && viewModel.errorMessage != null) {
      _showError(viewModel.errorMessage!);
    }
  }

  Future<void> _saveDraft(CreateListingViewModel viewModel) async {
    final authVM = context.read<AuthViewModel>();
    final user = authVM.user;

    if (user == null) {
      _showError('You must be logged in to save a draft');
      return;
    }

    final success = await viewModel.saveDraft(user);

    if (mounted && success) {
      _showSuccess('Draft saved successfully!');
    } else if (mounted && viewModel.errorMessage != null) {
      _showError(viewModel.errorMessage!);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: Consumer<CreateListingViewModel>(
        builder: (context, viewModel, child) {
          return Form(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotoSection(viewModel),
                  const SizedBox(height: 24),

                  if (viewModel.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
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
                                viewModel.errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => viewModel.clearError(),
                              child: Icon(Icons.close, color: Colors.red.shade700),
                            ),
                          ],
                        ),
                      ),
                    ),

                  _buildSectionLabel('Item Name'),
                  const SizedBox(height: 8),
                  _buildItemNameField(viewModel),
                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('Price'),
                            const SizedBox(height: 8),
                            _buildPriceField(viewModel),
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
                            _buildCategoryDropdown(viewModel),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildSectionLabel('Condition'),
                  const SizedBox(height: 10),
                  _buildConditionSelector(viewModel),
                  const SizedBox(height: 20),

                  _buildSectionLabel('Description'),
                  const SizedBox(height: 8),
                  _buildDescriptionField(viewModel),
                  const SizedBox(height: 32),

                  _buildSubmitButton(viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, size: 28, color: Colors.black87),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Post New Item',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
      centerTitle: true,
      actions: [
        Consumer<CreateListingViewModel>(
          builder: (context, viewModel, child) {
            return IconButton(
              icon: viewModel.isSavingDraft
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.article_outlined, color: Colors.black54),
              tooltip: 'Save as draft',
              onPressed: viewModel.isSavingDraft ? null : () => _saveDraft(viewModel),
            );
          },
        ),
      ],
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  Widget _buildPhotoSection(CreateListingViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Photos'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => viewModel.pickImages(),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: viewModel.hasImages ? 120 : 160,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
            child: viewModel.hasImages
                ? _buildPhotoGridView(viewModel)
                : _buildEmptyPhotoPlaceholder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to add up to 5 photos',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildEmptyPhotoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 12),
        const Text(
          'Add Photos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Up to 5 images',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildPhotoGridView(CreateListingViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: viewModel.selectedImages.length < 5
            ? viewModel.selectedImages.length + 1
            : viewModel.selectedImages.length,
        itemBuilder: (context, index) {
          if (index == viewModel.selectedImages.length) {
            return GestureDetector(
              onTap: () => viewModel.pickImages(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(Icons.add, color: Colors.grey),
              ),
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(viewModel.selectedImages[index].path),
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => viewModel.removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemNameField(CreateListingViewModel viewModel) {
    return TextFormField(
      controller: viewModel.titleController,
      textCapitalization: TextCapitalization.words,
      decoration: _inputDecoration(
        hint: 'e.g. Calculus Textbook, Vintage Jacket',
      ),
    );
  }

  Widget _buildPriceField(CreateListingViewModel viewModel) {
    return TextFormField(
      controller: viewModel.priceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: _inputDecoration(hint: '0.00').copyWith(
        prefixText: '₱ ',
        prefixStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(CreateListingViewModel viewModel) {
    return DropdownButtonFormField<String>(
      initialValue: viewModel.selectedCategory,
      hint: const Text(
        'Select...',
        style: TextStyle(color: Colors.grey, fontSize: 14),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
      onChanged: (val) => viewModel.setSelectedCategory(val!),
      decoration: _inputDecoration(hint: '').copyWith(hintText: null),
      items: CreateListingViewModel.categories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _buildConditionSelector(CreateListingViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: CreateListingViewModel.conditions.map((condition) {
          final isSelected = viewModel.selectedCondition == condition;
          return Expanded(
            child: GestureDetector(
              onTap: () => viewModel.setSelectedCondition(condition),
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

  Widget _buildDescriptionField(CreateListingViewModel viewModel) {
    return TextFormField(
      controller: viewModel.descriptionController,
      maxLines: 5,
      minLines: 4,
      textCapitalization: TextCapitalization.sentences,
      decoration: _inputDecoration(
        hint: 'Describe your item, any flaws, reason for selling...',
      ),
    );
  }

  Widget _buildSubmitButton(CreateListingViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: viewModel.isSubmitting ? null : () => _submitListing(viewModel),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
        ),
        child: viewModel.isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Post Item',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
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

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
    );
  }
}