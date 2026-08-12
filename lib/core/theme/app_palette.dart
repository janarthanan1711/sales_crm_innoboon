import 'package:flutter/material.dart';

/// The full set of design tokens for one brightness.
///
/// [AppColors] reads whichever palette is currently active, so every existing
/// `AppColors.textPrimary`-style reference keeps working and simply resolves
/// differently in dark mode. The light values here are copied verbatim from the
/// original token list — light mode renders exactly as it did before.
///
/// The dark set follows the same slate/blue family, flipped: surfaces step
/// *down* to slate-900/800 while text and accents step *up* to the 100–400
/// range, so contrast is preserved without changing any layout.
@immutable
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.primaryHover,
    required this.surface,
    required this.background,
    required this.scaffoldBackground,
    required this.cardBackground,
    required this.sidebarBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnPrimary,
    required this.textLink,
    required this.textStrong,
    required this.textBody,
    required this.fieldLabel,
    required this.primaryButton,
    required this.border,
    required this.borderLight,
    required this.divider,
    required this.success,
    required this.successLight,
    required this.warning,
    required this.warningLight,
    required this.error,
    required this.errorLight,
    required this.info,
    required this.infoLight,
    required this.tierStrategicBg,
    required this.tierStrategicText,
    required this.tierDiamondBg,
    required this.tierDiamondText,
    required this.tierGoldBg,
    required this.tierGoldText,
    required this.tierSilverBg,
    required this.tierSilverText,
    required this.tierBronzeBg,
    required this.tierBronzeText,
    required this.stageReceived,
    required this.stageQualified,
    required this.stageEvaluation,
    required this.stageProposal,
    required this.stageContract,
    required this.stageWon,
    required this.stageLost,
    required this.stageCold,
    required this.discoveryBg,
    required this.discoveryText,
    required this.proposalBg,
    required this.proposalText,
    required this.negotiationBg,
    required this.negotiationText,
    required this.navActive,
    required this.navActiveBg,
    required this.navInactive,
    required this.navHover,
    required this.shadow,
    required this.overlay,
    required this.avatarBg,
  });

  final Brightness brightness;

  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color primaryHover;

  final Color surface;
  final Color background;
  final Color scaffoldBackground;
  final Color cardBackground;
  final Color sidebarBackground;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnPrimary;
  final Color textLink;
  final Color textStrong;
  final Color textBody;
  final Color fieldLabel;
  final Color primaryButton;

  final Color border;
  final Color borderLight;
  final Color divider;

  final Color success;
  final Color successLight;
  final Color warning;
  final Color warningLight;
  final Color error;
  final Color errorLight;
  final Color info;
  final Color infoLight;

  final Color tierStrategicBg;
  final Color tierStrategicText;
  final Color tierDiamondBg;
  final Color tierDiamondText;
  final Color tierGoldBg;
  final Color tierGoldText;
  final Color tierSilverBg;
  final Color tierSilverText;
  final Color tierBronzeBg;
  final Color tierBronzeText;

  final Color stageReceived;
  final Color stageQualified;
  final Color stageEvaluation;
  final Color stageProposal;
  final Color stageContract;
  final Color stageWon;
  final Color stageLost;
  final Color stageCold;

  final Color discoveryBg;
  final Color discoveryText;
  final Color proposalBg;
  final Color proposalText;
  final Color negotiationBg;
  final Color negotiationText;

  final Color navActive;
  final Color navActiveBg;
  final Color navInactive;
  final Color navHover;

  final Color shadow;
  final Color overlay;
  final Color avatarBg;

  bool get isDark => brightness == Brightness.dark;

  /// Original Figma tokens, unchanged.
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF2563EB),
    primaryLight: Color(0xFFEFF6FF),
    primaryDark: Color(0xFF1D4ED8),
    primaryHover: Color(0xFF3B82F6),
    surface: Color(0xFFFFFFFF),
    background: Color(0xFFF8FAFC),
    scaffoldBackground: Color(0xFFF8FAFC),
    cardBackground: Color(0xFFFFFFFF),
    sidebarBackground: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF64748B),
    textMuted: Color(0xFF94A3B8),
    textOnPrimary: Color(0xFFFFFFFF),
    textLink: Color(0xFF2563EB),
    // Kept verbatim from the pages that hand-rolled them, so light mode is
    // pixel-identical to before dark mode existed.
    textStrong: Color(0xFF0F172A),
    textBody: Color(0xFF475569),
    fieldLabel: Color(0xFF334155),
    primaryButton: Color(0xFF0F47C6),
    border: Color(0xFFE2E8F0),
    borderLight: Color(0xFFF1F5F9),
    divider: Color(0xFFE2E8F0),
    success: Color(0xFF16A34A),
    successLight: Color(0xFFF0FDF4),
    warning: Color(0xFFEA580C),
    warningLight: Color(0xFFFFF7ED),
    error: Color(0xFFDC2626),
    errorLight: Color(0xFFFEF2F2),
    info: Color(0xFF0EA5E9),
    infoLight: Color(0xFFF0F9FF),
    tierStrategicBg: Color(0xFFEFF6FF),
    tierStrategicText: Color(0xFF2563EB),
    tierDiamondBg: Color(0xFFF5F3FF),
    tierDiamondText: Color(0xFF7C3AED),
    tierGoldBg: Color(0xFFFFFBEB),
    tierGoldText: Color(0xFFD97706),
    tierSilverBg: Color(0xFFF3F4F6),
    tierSilverText: Color(0xFF6B7280),
    tierBronzeBg: Color(0xFFFEF3C7),
    tierBronzeText: Color(0xFF92400E),
    stageReceived: Color(0xFF64748B),
    stageQualified: Color(0xFF2563EB),
    stageEvaluation: Color(0xFF7C3AED),
    stageProposal: Color(0xFF2563EB),
    stageContract: Color(0xFF0EA5E9),
    stageWon: Color(0xFF16A34A),
    stageLost: Color(0xFFDC2626),
    stageCold: Color(0xFF94A3B8),
    discoveryBg: Color(0xFFEFF6FF),
    discoveryText: Color(0xFF2563EB),
    proposalBg: Color(0xFFEFF6FF),
    proposalText: Color(0xFF2563EB),
    negotiationBg: Color(0xFFFFF7ED),
    negotiationText: Color(0xFFEA580C),
    navActive: Color(0xFF2563EB),
    navActiveBg: Color(0xFFEFF6FF),
    navInactive: Color(0xFF64748B),
    navHover: Color(0xFFF8FAFC),
    shadow: Color(0x0A000000),
    overlay: Color(0x33000000),
    avatarBg: Color(0xFFE2E8F0),
  );

  /// Dark counterpart.
  ///
  /// Two rules kept it coherent: surfaces are slate-900 (page) over slate-800
  /// (cards) so cards still read as raised without a shadow doing the work; and
  /// every "…Light" tint that was a 50-level wash becomes the matching 950-level
  /// shade of the same hue, so badges stay recognisable by colour rather than
  /// flattening into grey.
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    // Lifted from blue-600 to blue-500: the darker brand blue doesn't carry
    // enough contrast against a slate-900 page.
    primary: Color(0xFF3B82F6),
    primaryLight: Color(0xFF172554),
    primaryDark: Color(0xFF60A5FA),
    primaryHover: Color(0xFF60A5FA),
    surface: Color(0xFF1E293B),
    background: Color(0xFF0F172A),
    scaffoldBackground: Color(0xFF0F172A),
    cardBackground: Color(0xFF1E293B),
    sidebarBackground: Color(0xFF1E293B),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    // Still white — it sits on the filled primary button in both modes.
    textOnPrimary: Color(0xFFFFFFFF),
    textLink: Color(0xFF60A5FA),
    textStrong: Color(0xFFF8FAFC),
    textBody: Color(0xFFCBD5E1),
    fieldLabel: Color(0xFFCBD5E1),
    primaryButton: Color(0xFF3B82F6),
    border: Color(0xFF334155),
    borderLight: Color(0xFF293548),
    divider: Color(0xFF334155),
    success: Color(0xFF4ADE80),
    successLight: Color(0xFF052E16),
    warning: Color(0xFFFB923C),
    warningLight: Color(0xFF431407),
    error: Color(0xFFF87171),
    errorLight: Color(0xFF450A0A),
    info: Color(0xFF38BDF8),
    infoLight: Color(0xFF082F49),
    tierStrategicBg: Color(0xFF172554),
    tierStrategicText: Color(0xFF60A5FA),
    tierDiamondBg: Color(0xFF2E1065),
    tierDiamondText: Color(0xFFA78BFA),
    tierGoldBg: Color(0xFF451A03),
    tierGoldText: Color(0xFFFBBF24),
    tierSilverBg: Color(0xFF334155),
    tierSilverText: Color(0xFFCBD5E1),
    tierBronzeBg: Color(0xFF431407),
    tierBronzeText: Color(0xFFFDBA74),
    stageReceived: Color(0xFF94A3B8),
    stageQualified: Color(0xFF60A5FA),
    stageEvaluation: Color(0xFFA78BFA),
    stageProposal: Color(0xFF60A5FA),
    stageContract: Color(0xFF38BDF8),
    stageWon: Color(0xFF4ADE80),
    stageLost: Color(0xFFF87171),
    stageCold: Color(0xFF94A3B8),
    discoveryBg: Color(0xFF172554),
    discoveryText: Color(0xFF60A5FA),
    proposalBg: Color(0xFF172554),
    proposalText: Color(0xFF60A5FA),
    negotiationBg: Color(0xFF431407),
    negotiationText: Color(0xFFFB923C),
    navActive: Color(0xFF60A5FA),
    navActiveBg: Color(0xFF172554),
    navInactive: Color(0xFF94A3B8),
    navHover: Color(0xFF334155),
    // Shadows have to be heavier to register against dark surfaces at all.
    shadow: Color(0x33000000),
    overlay: Color(0x99000000),
    avatarBg: Color(0xFF334155),
  );
}
