import 'package:flutter/widgets.dart';

/// Ensures tab content state is kept alive when switching tabs.
class KeepAliveTab extends StatefulWidget {
  const KeepAliveTab({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<KeepAliveTab>
    with AutomaticKeepAliveClientMixin<KeepAliveTab> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
