import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final BorderRadius borderRadius;
  final Gradient? gradient;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 50,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return SizedBox(
        width: width,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
            side: const BorderSide(color: AppColors.primaryColor, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
                  ),
                )
              : Text(
                  label,
                  style: AppTypography.buttonText.copyWith(
                    color: textColor ?? AppColors.primaryColor,
                  ),
                ),
        ),
      );
    }

    final effectiveGradient = gradient ?? AppColors.primaryGradient;
    final bool useGradient = gradient != null || backgroundColor == null;

    if (useGradient) {
      return SizedBox(
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            gradient: isLoading ? null : effectiveGradient,
            color: isLoading ? AppColors.surfaceVariant : null,
            borderRadius: borderRadius,
            boxShadow: isLoading
                ? null
                : [
                    BoxShadow(
                      color: AppColors.glowTeal,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: borderRadius,
              splashColor: AppColors.whiteOverlay,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.textPrimary),
                        ),
                      )
                    : Text(
                        label,
                        style: AppTypography.buttonText.copyWith(
                          color: textColor ?? AppColors.textDark,
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor ?? AppColors.textDark,
          disabledBackgroundColor: AppColors.surfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation(AppColors.textPrimary),
                ),
              )
            : Text(
                label,
                style: AppTypography.buttonText.copyWith(
                  color: textColor ?? AppColors.textDark,
                ),
              ),
      ),
    );
  }
}
