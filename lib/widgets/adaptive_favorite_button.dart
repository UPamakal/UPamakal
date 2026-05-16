import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/image_service.dart';
import 'favorite_button.dart';

/// Adaptive favorite button that adjusts its background based on listing image.
/// Uses a glassmorphism-style backdrop with smooth animations.
class AdaptiveFavoriteButton extends StatefulWidget {
  final String listingId;
  final String userId;
  final String? imageBase64;
  final double size;
  final bool showBackground;

  const AdaptiveFavoriteButton({
    super.key,
    required this.listingId,
    required this.userId,
    this.imageBase64,
    this.size = 20,
    this.showBackground = true,
  });

  @override
  State<AdaptiveFavoriteButton> createState() => _AdaptiveFavoriteButtonState();
}

class _AdaptiveFavoriteButtonState extends State<AdaptiveFavoriteButton>
    with SingleTickerProviderStateMixin {
  Color? _adaptiveBackgroundColor;
  bool _isLoadingBackground = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadAdaptiveBackground();
  }

  @override
  void didUpdateWidget(AdaptiveFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBase64 != widget.imageBase64) {
      _loadAdaptiveBackground();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadAdaptiveBackground() async {
    if (!widget.showBackground || widget.imageBase64 == null) {
      if (mounted) {
        setState(() => _isLoadingBackground = false);
        _fadeController.forward();
      }
      return;
    }

    try {
      final bgColor =
          await ImageService.getAdaptiveButtonBackground(widget.imageBase64!);
      if (mounted) {
        setState(() {
          _adaptiveBackgroundColor = bgColor;
          _isLoadingBackground = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _adaptiveBackgroundColor = Colors.black.withValues(alpha: 0.45);
          _isLoadingBackground = false;
        });
        _fadeController.forward();
      }
    }
  }

  // Effective container size: icon size + padding
  double get _containerSize => widget.size + 20;

  @override
  Widget build(BuildContext context) {
    if (_isLoadingBackground) {
      return _buildSkeleton();
    }

    final button = FavoriteButton(
      listingId: widget.listingId,
      userId: widget.userId,
      size: widget.size,
    );

    if (!widget.showBackground) {
      return FadeTransition(opacity: _fadeAnimation, child: button);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _GlassButton(
        size: _containerSize,
        backgroundColor:
            _adaptiveBackgroundColor ?? Colors.black.withValues(alpha: 0.45),
        child: Center(child: button),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Container(
      width: _containerSize,
      height: _containerSize,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Adaptive icon button (share / other actions) with glassmorphism styling.
class AdaptiveIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? imageBase64;
  final double size;
  final double iconSize;

  const AdaptiveIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.imageBase64,
    this.size = 40,
    this.iconSize = 20,
  });

  @override
  State<AdaptiveIconButton> createState() => _AdaptiveIconButtonState();
}

class _AdaptiveIconButtonState extends State<AdaptiveIconButton>
    with SingleTickerProviderStateMixin {
  Color? _adaptiveBackgroundColor;
  bool _isLoadingBackground = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadAdaptiveBackground();
  }

  @override
  void didUpdateWidget(AdaptiveIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBase64 != widget.imageBase64) {
      _loadAdaptiveBackground();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadAdaptiveBackground() async {
    if (widget.imageBase64 == null) {
      if (mounted) {
        setState(() {
          _adaptiveBackgroundColor = Colors.black.withValues(alpha: 0.45);
          _isLoadingBackground = false;
        });
        _fadeController.forward();
      }
      return;
    }

    try {
      final bgColor =
          await ImageService.getAdaptiveButtonBackground(widget.imageBase64!);
      if (mounted) {
        setState(() {
          _adaptiveBackgroundColor = bgColor;
          _isLoadingBackground = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _adaptiveBackgroundColor = Colors.black.withValues(alpha: 0.45);
          _isLoadingBackground = false;
        });
        _fadeController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingBackground) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _GlassButton(
        size: widget.size,
        backgroundColor:
            _adaptiveBackgroundColor ?? Colors.black.withValues(alpha: 0.45),
        child: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onPressed();
          },
          icon: Icon(widget.icon, color: Colors.white, size: widget.iconSize),
          padding: EdgeInsets.zero,
          splashRadius: widget.size / 2,
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}

/// Internal glassmorphism-style circular button container.
/// Applies a frosted-glass look with a subtle inner highlight ring
/// and a soft drop shadow — readable over any image brightness.
class _GlassButton extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Widget child;

  const _GlassButton({
    required this.size,
    required this.backgroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Main frosted fill
        color: backgroundColor,
        // Thin top-highlight ring simulating glass refraction
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.30),
          width: 1.2,
        ),
        boxShadow: [
          // Soft ambient shadow for lift
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
          // Tight crisp shadow for definition
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 3,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      // Inner highlight arc at the top of the circle
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(0, -0.6),
          radius: 0.8,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.transparent,
          ],
        ),
      ),
      child: child,
    );
  }
}