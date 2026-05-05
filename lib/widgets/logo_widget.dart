import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// --------------------------------------------------------------------------
/// LogoWidget
/// --------------------------------------------------------------------------
/// Displays the UPamakal brand logo.  Attempts to load the PNG asset at
/// [AppConstants.logoAssetPath].  If the asset file is not found (i.e.
/// the developer has not yet placed UPamakal.png in the assets folder),
/// a Maroon placeholder tile with the text "UP" is shown instead.
///
/// This graceful degradation means the app compiles and runs even before
/// the final logo artwork is added.
/// --------------------------------------------------------------------------
class LogoWidget extends StatelessWidget {
  /// The width and height of the logo square, in logical pixels.
  final double size;
  const LogoWidget({super.key, this.size = 100});
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppConstants.logoAssetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // ---- Fallback when image asset is missing ---------------------------
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'UP',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ),
        );
      },
    );
  }
}
