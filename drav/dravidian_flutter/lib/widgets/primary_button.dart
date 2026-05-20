import 'package:flutter/material.dart';
import '../theme.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const PrimaryButton({super.key, required this.onPressed, required this.child, this.style});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: style ?? AppTheme.primaryButton,
      child: child,
    );
  }
}
