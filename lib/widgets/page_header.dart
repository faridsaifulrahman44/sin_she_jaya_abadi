import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: ctextPrimary(context),
        letterSpacing: -0.3,
      ),
    );
  }
}
