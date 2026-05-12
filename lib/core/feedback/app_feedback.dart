import 'package:flutter/material.dart';

import '../error/app_error_mapper.dart';
import '../error/failure.dart';

class AppFeedback {
  const AppFeedback._();

  static void showError(
    BuildContext context,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    final message = AppErrorMapper.toMessage(error, stackTrace);
    _showSnack(
      context,
      message: message,
      backgroundColor: Theme.of(context).colorScheme.error,
      foregroundColor: Theme.of(context).colorScheme.onError,
    );
  }

  static Future<void> showErrorDialog(
    BuildContext context,
    Object error, [
    StackTrace? stackTrace,
  ]) async {
    final failure = FailureMapper.fromException(AppErrorMapper.map(
      error,
      stackTrace,
    ));
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terjadi Kendala'),
        content: Text(failure.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  static void showInfo(
    BuildContext context,
    String message,
  ) {
    _showSnack(
      context,
      message: message,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
    );
  }

  static void _showSnack(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: foregroundColor)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
