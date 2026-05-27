import 'package:flutter/material.dart';

import '../tokens/nova_colors.dart';

/// A [Scaffold] with the signature soft gradient background. The gradient
/// adapts to the active light/dark theme.
class SoftGradientScaffold extends StatelessWidget {
  const SoftGradientScaffold({
    required this.child,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    super.key,
  });

  final PreferredSizeWidget? appBar;
  final Widget child;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: context.colors.scaffoldGradient),
        child: SafeArea(child: child),
      ),
    );
  }
}
