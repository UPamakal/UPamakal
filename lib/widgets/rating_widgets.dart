import 'package:flutter/material.dart';
import '../models/rating_model.dart';

/// --------------------------------------------------------------------------
/// Rating Display Widget
/// --------------------------------------------------------------------------
/// Displays the star rating with optional label
/// --------------------------------------------------------------------------
class StarRating extends StatelessWidget {
  final double rating;
  final int size;
  final Color activeColor;
  final Color inactiveColor;
  final bool showLabel;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 16,
    this.activeColor = const Color(0xFFFFB800),
    this.inactiveColor = const Color(0xFFE5E5E5),
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(
          5,
          (index) {
            final fillPercentage = (rating - index).clamp(0.0, 1.0);
            return Stack(
              children: [
                Icon(Icons.star, size: size.toDouble(), color: inactiveColor),
                ClipRect(
                  clipper: _PartialClipper(fillPercentage),
                  child: Icon(Icons.star,
                      size: size.toDouble(), color: activeColor),
                ),
              ],
            );
          },
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ],
    );
  }
}

/// Helper class for partial star filling
class _PartialClipper extends CustomClipper<Rect> {
  final double fillPercentage;

  _PartialClipper(this.fillPercentage);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * fillPercentage, size.height);
  }

  @override
  bool shouldReclip(_PartialClipper oldClipper) {
    return oldClipper.fillPercentage != fillPercentage;
  }
}

/// --------------------------------------------------------------------------
/// Rating Input Widget
/// --------------------------------------------------------------------------
/// Allows users to select a rating (interactive stars)
/// --------------------------------------------------------------------------
class RatingInput extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;
  final int size;

  const RatingInput({
    super.key,
    this.initialRating = 5,
    required this.onRatingChanged,
    this.size = 32,
  });

  @override
  State<RatingInput> createState() => _RatingInputState();
}

class _RatingInputState extends State<RatingInput> {
  late double _hoverRating;

  @override
  void initState() {
    super.initState();
    _hoverRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starRating = index + 1.0;
        return GestureDetector(
          onTap: () {
            widget.onRatingChanged(starRating);
            setState(() => _hoverRating = starRating);
          },
          child: MouseRegion(
            onEnter: (_) {
              setState(() => _hoverRating = starRating);
            },
            onExit: (_) {
              setState(() => _hoverRating = widget.initialRating);
            },
            child: Icon(
              Icons.star,
              size: widget.size.toDouble(),
              color: _hoverRating >= starRating
                  ? const Color(0xFFFFB800)
                  : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }
}

/// --------------------------------------------------------------------------
/// Review Card Widget
/// --------------------------------------------------------------------------
/// Displays a single review with rating, text, and metadata
/// --------------------------------------------------------------------------
class ReviewCard extends StatelessWidget {
  final RatingModel rating;
  final VoidCallback? onDelete;
  final bool showDeleteButton;

  const ReviewCard({
    super.key,
    required this.rating,
    this.onDelete,
    this.showDeleteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating.reviewerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    StarRating(rating: rating.rating, size: 14),
                  ],
                ),
              ),
              if (showDeleteButton)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Colors.red,
                ),
            ],
          ),
          if (rating.review != null && rating.review!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rating.review!,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          Text(
            rating.timeAgo,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

/// --------------------------------------------------------------------------
/// Rating Summary Widget
/// --------------------------------------------------------------------------
/// Displays overall rating with count and breakdown
/// --------------------------------------------------------------------------
class RatingSummary extends StatelessWidget {
  final double averageRating;
  final int ratingCount;
  final Map<int, int>? breakdown;

  const RatingSummary({
    super.key,
    required this.averageRating,
    required this.ratingCount,
    this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StarRating(rating: averageRating, size: 20, showLabel: true),
                  const SizedBox(height: 6),
                  Text(
                    '$ratingCount ${ratingCount == 1 ? 'review' : 'reviews'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (breakdown != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(5, (index) {
                    final stars = 5 - index;
                    final count = breakdown![stars] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$stars★',
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: ratingCount > 0
                                  ? count / ratingCount
                                  : 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB800),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 24,
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// --------------------------------------------------------------------------
/// Rating Dialog Widget
/// --------------------------------------------------------------------------
/// Modal dialog for submitting a rating
/// --------------------------------------------------------------------------
class RatingDialog extends StatefulWidget {
  final String listingTitle;
  final String sellerName;
  final VoidCallback onSubmit;
  final Function(double rating, String? review) onRatingSelected;

  const RatingDialog({
    super.key,
    required this.listingTitle,
    required this.sellerName,
    required this.onSubmit,
    required this.onRatingSelected,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 5;
  final _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate This Seller',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'How would you rate your experience with ${widget.sellerName}?',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            Center(
              child: RatingInput(
                initialRating: _rating,
                onRatingChanged: (rating) {
                  setState(() => _rating = rating);
                },
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Add a comment (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onRatingSelected(
                        _rating,
                        _reviewController.text.isNotEmpty
                            ? _reviewController.text
                            : null,
                      );
                      widget.onSubmit();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
