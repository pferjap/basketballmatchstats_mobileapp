import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';

/// Top banner of the login screen: a dark, court-inspired gradient with the
/// BASKETSTATS wordmark and tagline centered over it, fading into the page
/// background (design: `docs/images/login_screen.png`).
///
/// The reference art is a photographic arena; here it is approximated with a
/// gradient + basketball glyph so no large raster asset needs to ship.
class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF3A2A12),
              Color(0xFF1A1712),
              AppColors.background,
            ],
            stops: <double>[0.0, 0.6, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sports_basketball,
                size: 72,
                color: AppColors.primary,
              ),
              const SizedBox(height: kSpacingS),
              Text.rich(
                TextSpan(
                  children: const [
                    TextSpan(
                      text: 'BASKET',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    TextSpan(
                      text: 'STATS',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: kSpacingXS),
              Text(
                'ANOTA · SINCRONIZA · COMPITE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
