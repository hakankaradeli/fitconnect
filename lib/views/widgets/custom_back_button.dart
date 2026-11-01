import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final Color? color;
  final Color? backgroundColor;
  final VoidCallback? onPressed;

  const CustomBackButton({
    super.key,
    this.color,
    this.backgroundColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ??
        Theme.of(context).appBarTheme.foregroundColor ??
        IconTheme.of(context).color ??
        const Color(0xFF1E293B);

    final effectiveBg = backgroundColor ?? effectiveColor.withValues(alpha: 0.16);

    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      icon: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: effectiveBg,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: effectiveColor,
          size: 18,
        ),
      ),
      onPressed: onPressed ?? () => Navigator.maybePop(context),
    );
  }
}
