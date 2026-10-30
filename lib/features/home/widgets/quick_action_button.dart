/// Quick Action Button Widget
///
/// Compact button for quick access to key features
library;

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final lightOverlay = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.95);
    final unifiedColor = AppColors.primary;

    final activeColor = color == AppColors.primary ? unifiedColor : color;

    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                activeColor.withValues(alpha: 0.2),
                activeColor.withValues(alpha: 0.12),
                lightOverlay,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(
              color: activeColor.withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: activeColor.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              splashColor: activeColor.withValues(alpha: 0.18),
              highlightColor: activeColor.withValues(alpha: 0.09),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.paddingMD,
                  horizontal: AppDimensions.paddingSM,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            activeColor.withValues(alpha: 0.98),
                            activeColor.withValues(alpha: 0.78),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.32),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: AppColors.textLight, size: 21),
                    ),
                    const SizedBox(width: AppDimensions.paddingSM),
                    Flexible(
                      child: Text(
                        label,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: textColor ?? AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
