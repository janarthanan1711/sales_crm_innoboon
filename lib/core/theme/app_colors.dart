import 'package:flutter/material.dart';
import 'app_palette.dart';

/// SalesHub Design System — Color Tokens
/// Extracted from Figma "Sales Prospecting & CRM Platform"
///
/// These were `static const` until dark mode landed. They're now getters over
/// the active [AppPalette], which is what lets ~900 existing call sites pick up
/// dark mode without being touched. The trade-off is that they can no longer
/// appear inside `const` expressions — a widget that used to be
/// `const BoxDecoration(color: AppColors.border)` simply drops its `const`.
///
/// [applyBrightness] is called from the app root on every build, so the palette
/// is always in step with the `MaterialApp` theme that's about to be painted.
class AppColors {
  AppColors._();

  static AppPalette _palette = AppPalette.light;

  /// Swaps the token set. Call this *before* building the widget tree for a
  /// given brightness — the app root does it inline for exactly that reason.
  static void applyBrightness(Brightness brightness) {
    _palette = brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
  }

  /// For the handful of places that genuinely need to branch — chart tooltips,
  /// image overlays, anything painting its own contrast.
  static bool get isDark => _palette.isDark;

  static AppPalette get palette => _palette;

  // ─── Primary ───────────────────────────────────────────
  static Color get primary => _palette.primary;
  static Color get primaryLight => _palette.primaryLight;
  static Color get primaryDark => _palette.primaryDark;
  static Color get primaryHover => _palette.primaryHover;

  // ─── Surface & Background ─────────────────────────────
  static Color get surface => _palette.surface;
  static Color get background => _palette.background;
  static Color get scaffoldBackground => _palette.scaffoldBackground;
  static Color get cardBackground => _palette.cardBackground;
  static Color get sidebarBackground => _palette.sidebarBackground;

  // ─── Text ──────────────────────────────────────────────
  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;
  static Color get textMuted => _palette.textMuted;
  static Color get textOnPrimary => _palette.textOnPrimary;
  static Color get textLink => _palette.textLink;

  /// Three one-off shades that several pages hard-coded instead of using the
  /// tokens above (a near-black hero heading, a slate-600 body, a slate-700
  /// field label), plus the deeper blue those pages used on their primary
  /// button. Promoted to tokens so they can go dark — their light values are
  /// exactly what those pages had, so nothing shifts in light mode.
  static Color get textStrong => _palette.textStrong;
  static Color get textBody => _palette.textBody;
  static Color get fieldLabel => _palette.fieldLabel;
  static Color get primaryButton => _palette.primaryButton;

  // ─── Borders & Dividers ────────────────────────────────
  static Color get border => _palette.border;
  static Color get borderLight => _palette.borderLight;
  static Color get divider => _palette.divider;

  // ─── Semantic ──────────────────────────────────────────
  static Color get success => _palette.success;
  static Color get successLight => _palette.successLight;
  static Color get warning => _palette.warning;
  static Color get warningLight => _palette.warningLight;
  static Color get error => _palette.error;
  static Color get errorLight => _palette.errorLight;
  static Color get info => _palette.info;
  static Color get infoLight => _palette.infoLight;

  // ─── Tier Badge Colors ─────────────────────────────────
  static Color get tierStrategicBg => _palette.tierStrategicBg;
  static Color get tierStrategicText => _palette.tierStrategicText;
  static Color get tierDiamondBg => _palette.tierDiamondBg;
  static Color get tierDiamondText => _palette.tierDiamondText;
  static Color get tierGoldBg => _palette.tierGoldBg;
  static Color get tierGoldText => _palette.tierGoldText;
  static Color get tierSilverBg => _palette.tierSilverBg;
  static Color get tierSilverText => _palette.tierSilverText;
  static Color get tierBronzeBg => _palette.tierBronzeBg;
  static Color get tierBronzeText => _palette.tierBronzeText;

  // ─── Stage Colors ──────────────────────────────────────
  static Color get stageReceived => _palette.stageReceived;
  static Color get stageQualified => _palette.stageQualified;
  static Color get stageEvaluation => _palette.stageEvaluation;
  static Color get stageProposal => _palette.stageProposal;
  static Color get stageContract => _palette.stageContract;
  static Color get stageWon => _palette.stageWon;
  static Color get stageLost => _palette.stageLost;
  static Color get stageCold => _palette.stageCold;

  // ─── Deal Stage Badge Colors ───────────────────────────
  static Color get discoveryBg => _palette.discoveryBg;
  static Color get discoveryText => _palette.discoveryText;
  static Color get proposalBg => _palette.proposalBg;
  static Color get proposalText => _palette.proposalText;
  static Color get negotiationBg => _palette.negotiationBg;
  static Color get negotiationText => _palette.negotiationText;

  // ─── Navigation ────────────────────────────────────────
  static Color get navActive => _palette.navActive;
  static Color get navActiveBg => _palette.navActiveBg;
  static Color get navInactive => _palette.navInactive;
  static Color get navHover => _palette.navHover;

  // ─── Misc ──────────────────────────────────────────────
  static Color get shadow => _palette.shadow;
  static Color get overlay => _palette.overlay;
  static Color get avatarBg => _palette.avatarBg;

  /// White in both modes — for text/icons sitting on a filled brand-coloured
  /// surface, where the background doesn't change with the theme.
  static const Color onAccent = Color(0xFFFFFFFF);
}
