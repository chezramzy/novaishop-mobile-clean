import 'package:flutter/material.dart';

import '../../design/motion/page_transitions.dart';

/// The animated transition styles available to routes.
enum RouteTransitionStyle { fade, sharedAxis, slideUp }

/// Builds an animated [PageRoute] for [page] using the design-system page
/// transitions. Feature route maps use this so every navigation animates
/// consistently.
PageRoute<T> buildRoute<T>(
  Widget page, {
  RouteSettings? settings,
  RouteTransitionStyle style = RouteTransitionStyle.sharedAxis,
}) {
  switch (style) {
    case RouteTransitionStyle.fade:
      return AppPageRoute.fade<T>(page, settings: settings);
    case RouteTransitionStyle.sharedAxis:
      return AppPageRoute.sharedAxis<T>(page, settings: settings);
    case RouteTransitionStyle.slideUp:
      return AppPageRoute.slideUp<T>(page, settings: settings);
  }
}
