import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  const LoadingIndicator({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: size,
        width: size,
        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
}
