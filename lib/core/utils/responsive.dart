import 'package:flutter/material.dart';

/// Screen size categories for responsive layout
enum ScreenSize { mobile, tablet, web }

/// Responsive breakpoint utilities
class Responsive {
  Responsive._();

  // ─── Breakpoints ───────────────────────────────────────
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  /// Get current screen size from [BoxConstraints] or [BuildContext]
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileBreakpoint) return ScreenSize.mobile;
    if (width < tabletBreakpoint) return ScreenSize.tablet;
    return ScreenSize.web;
  }

  /// Get screen size from width value
  static ScreenSize getScreenSizeFromWidth(double width) {
    if (width < mobileBreakpoint) return ScreenSize.mobile;
    if (width < tabletBreakpoint) return ScreenSize.tablet;
    return ScreenSize.web;
  }

  static bool isMobile(BuildContext context) =>
      getScreenSize(context) == ScreenSize.mobile;

  static bool isTablet(BuildContext context) =>
      getScreenSize(context) == ScreenSize.tablet;

  static bool isWeb(BuildContext context) =>
      getScreenSize(context) == ScreenSize.web;

  static bool isDesktopOrTablet(BuildContext context) =>
      !isMobile(context);

  /// Page padding based on screen size
  static double pagePadding(BuildContext context) {
    switch (getScreenSize(context)) {
      case ScreenSize.mobile:
        return 16;
      case ScreenSize.tablet:
        return 24;
      case ScreenSize.web:
        return 32;
    }
  }
}

/// Responsive layout builder that renders different widgets per breakpoint
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.web,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? web;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Responsive.getScreenSize(context);
        switch (screenSize) {
          case ScreenSize.web:
            return web ?? tablet ?? mobile;
          case ScreenSize.tablet:
            return tablet ?? mobile;
          case ScreenSize.mobile:
            return mobile;
        }
      },
    );
  }
}

/// Extension on BuildContext for quick responsive checks
extension ResponsiveExtension on BuildContext {
  ScreenSize get screenSize => Responsive.getScreenSize(this);
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isWeb => Responsive.isWeb(this);
  double get pagePadding => Responsive.pagePadding(this);
}
