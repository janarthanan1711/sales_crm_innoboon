import 'package:flutter/material.dart';
import '../../app/di/injector.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';

/// Sun/moon switch for flipping between light and dark.
///
/// Deliberately not Material's [Switch]: this reads as a *mode* picker rather
/// than an on/off setting, so both destinations are drawn on the track and the
/// thumb carries the one you're currently in. Styled flat with a 1px border to
/// match the rest of the chrome instead of the soft-shadow look.
///
/// It reads [AppColors.isDark] rather than the controller's [ThemeMode], so
/// under "system" it shows what's actually on screen. Changing the theme
/// rebuilds from the app root, which is what repaints this.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, this.compact = false});

  /// Narrower track for the mobile top bar, where the row is already tight.
  final bool compact;

  static const Duration _duration = Duration(milliseconds: 220);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final height = compact ? 26.0 : 30.0;
    final width = compact ? 48.0 : 56.0;
    const padding = 3.0;
    final thumb = height - padding * 2;
    final iconSize = compact ? 13.0 : 15.0;

    // Everything here is decoration, so it all collapses under reduce-motion.
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _duration;

    return Tooltip(
      message: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      child: Semantics(
        button: true,
        toggled: isDark,
        label: 'Dark mode',
        child: InkWell(
          onTap: () => sl<ThemeController>().toggle(
            // Resolved against the platform so that from "system" the switch
            // moves away from whatever is currently rendered.
            platformIsDark:
                MediaQuery.platformBrightnessOf(context) == Brightness.dark,
          ),
          borderRadius: BorderRadius.circular(height),
          child: AnimatedContainer(
            duration: duration,
            curve: _curve,
            width: width,
            height: height,
            padding: const EdgeInsets.all(padding),
            decoration: BoxDecoration(
              // Tinted in dark so the switch reads as "on" at a glance, the way
              // a filled track does, without needing a second accent colour.
              color: isDark ? AppColors.primaryLight : AppColors.background,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(height),
            ),
            child: Stack(
              children: [
                // The destination icon — the one the thumb *isn't* sitting on.
                // Fading rather than swapping keeps the track from flickering
                // as the thumb crosses it.
                Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _trackIcon(
                        Icons.light_mode_outlined,
                        show: isDark,
                        size: iconSize,
                        slot: thumb,
                        duration: duration,
                      ),
                      _trackIcon(
                        Icons.dark_mode_outlined,
                        show: !isDark,
                        size: iconSize,
                        slot: thumb,
                        duration: duration,
                      ),
                    ],
                  ),
                ),
                AnimatedAlign(
                  duration: duration,
                  curve: _curve,
                  alignment: isDark
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: thumb,
                    height: thumb,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    // Sun keeps its warm hue and moon the brand blue — the two
                    // states stay distinguishable without reading the icon.
                    child: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      size: iconSize,
                      color: isDark ? AppColors.primary : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _trackIcon(
    IconData icon, {
    required bool show,
    required double size,
    required double slot,
    required Duration duration,
  }) {
    return SizedBox(
      width: slot,
      child: AnimatedOpacity(
        duration: duration,
        opacity: show ? 1 : 0,
        child: Icon(icon, size: size, color: AppColors.textMuted),
      ),
    );
  }
}
