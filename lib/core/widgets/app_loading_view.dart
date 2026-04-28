import 'package:flutter/material.dart';

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({
    super.key,
    this.message = 'Memuat data...',
    this.child,
  });

  final String message;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (child != null) return child!;

    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
