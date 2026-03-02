import 'package:flutter/material.dart';

/// Centralized application color tokens for cohesive, modern obsidian dark design.
class AppColors {
  AppColors._();

  // Background & Surfaces
  static const Color background = Color(0xFF090D12); // Deep obsidian canvas
  static const Color surfaceSidebar = Color(
    0xFF0D1117,
  ); // Left/Right sidebar surfaces
  static const Color surfaceCard = Color(
    0xFF161B22,
  ); // Cards, toolbars, top bars
  static const Color surfaceNavbar = Color(
    0xFF171B21,
  ); // Navigation bars, app bars
  static const Color surfaceElevated = Color(0xFF1C2128); // Dropdowns, modals
  static const Color surfaceHover = Color(0xFF1F242C); // Hover state
  static const Color surfaceActive = Color(0xFF262C36); // Selected state

  // Borders & Dividers
  static const Color borderSubtle = Color(0xFF21262D); // Subtle dividers
  static const Color borderDefault = Color(0xFF30363D); // Card/Input borders
  static const Color borderHover = Color(0xFF484F58); // Hover borders
  static const Color borderActive = Color(0xFF58A6FF); // Focused borders

  // Primary & Accents
  static const Color primary = Color(0xFF58A6FF); // Electric Blue accent
  static const Color primaryHover = Color(0xFF79B8FF); // Brighter electric blue
  static const Color primaryContainer = Color(0xFF1F6FEB); // Primary container
  static const Color secondary = Color(
    0xFF7EE787,
  ); // Mint / Emerald green (diagrams)
  static const Color accent = Color(0xFFA371F7); // Lavender purple

  // Semantic Marks & Tags
  static const Color markImportant = Color(
    0xFFF0883E,
  ); // Vibrant Amber/Orange (@@imp)
  static const Color markInfo = Color(0xFF58A6FF); // Crisp Blue (@@info)
  static const Color markTag = Color(0xFFBC8CFF); // Soft Violet (@@tag)
  static const Color markDiagram = Color(
    0xFF7EE787,
  ); // Mint Emerald (@@drawing)
  static const Color markSuccess = Color(0xFF3FB950); // Success Green
  static const Color markDanger = Color(0xFFF85149); // Error Red

  // Text
  static const Color textPrimary = Color(
    0xFFF0F6FC,
  ); // Crisp high-contrast white
  static const Color textSecondary = Color(0xFFC9D1D9); // Readable secondary
  static const Color textMuted = Color(
    0xFF8B949E,
  ); // Muted descriptions & metadata
  static const Color textTertiary = Color(0xFF6E7681); // Subtle hints & keycaps
  static const Color textDivider = Color(0xFF424754);

  // Window Chrome Colors
  static const Color chromeBackground = Color(0xFF171B21);
  static const Color chromeBottomBorder = Color(0xFF242830);

  // Control Containers (Toggle pill & Search box)
  static const Color controlBackground = Color(0xFF0A0E14);
  static const Color controlBorder = Color(0xFF1F242D);
  static const Color controlHover = Color(0xFF151922);

  // Active Segment (e.g. Reading button in toggle)
  static const Color activeSegment = Color(0xFF262A31);
  static const Color activeSegmentBorder = Color(0xFF374151);

  // Search Badge (⌘K)
  static const Color badgeBackground = Color(0xFF1C2026);
  static const Color badgeBorder = Color(0xFF2A303A);
  static const Color badgeText = Color(0xFF858997);

  // Right-side window & layout action icons
  static const Color actionIcon = Color(0xFFC2C6D6);
  static const Color actionIconActive = Color(0xFFFFFFFF);
  static const Color actionIconHoverBg = Color(0xFF262B35);

  // App Icon Badge
  static const Color appIconBadgeBg = Color(0xFF1E293B);
  static const Color appIconBadgeBorder = Color(0xFF2E384D);
  static const Color appIconCyan = Color(0xFF38BDF8);
  static const Color appIconOrange = Color(0xFFF59E0B);
  static const Color appIconDocumentOutline = Color(0xFF64748B);

  // Workspace / Document Canvas Colors
  static const Color workspaceBackground = Color(0xFF0E1116);
  static const Color sidebarBackground = Color(0xFF13171E);
  static const Color sidebarBorder = Color(0xFF1E232B);
  static const Color cardBackground = Color(0xFF181C24);
  static const Color cardBorder = Color(0xFF242A35);
  static const Color codeBackground = Color(0xFF080B0F);
  static const Color selectionHighlight = Color(0x3338BDF8);
  static const Color accentCyan = Color(0xFF38BDF8);
  static const Color accentOrange = Color(0xFFF59E0B);
}

/// Cohesive Dark Theme for noteflow notebook application.
class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.background,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.surfaceSidebar,
      surfaceContainer: AppColors.surfaceCard,
      surfaceContainerHigh: AppColors.surfaceElevated,
      surfaceContainerHighest: AppColors.surfaceActive,
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: Color(0xFFFFFFFF),
      secondary: AppColors.secondary,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderDefault,
      outlineVariant: AppColors.borderSubtle,
      error: AppColors.markDanger,
      onError: Color(0xFFFFFFFF),
    ),
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13.5,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        color: AppColors.textMuted,
        fontSize: 11.5,
        height: 1.4,
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      titleSmall: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      headlineLarge: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 32,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 24,
        letterSpacing: -0.3,
      ),
      headlineSmall: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 20,
        letterSpacing: -0.2,
      ),
      labelLarge: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      labelMedium: TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 11.5,
      ),
      labelSmall: TextStyle(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
        fontSize: 10,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceSidebar,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    dividerTheme: const DividerThemeData(
      space: 1,
      thickness: 1,
      color: AppColors.borderSubtle,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceSidebar,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      waitDuration: const Duration(milliseconds: 400),
      showDuration: const Duration(milliseconds: 2000),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceElevated,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderDefault),
      ),
      textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceCard,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.borderDefault, width: 1.5),
      ),
      titleTextStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.borderDefault),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.dragged)) {
          return AppColors.textTertiary;
        }
        return AppColors.borderSubtle;
      }),
      radius: const Radius.circular(4),
      thickness: WidgetStateProperty.all(6),
    ),
  );

  static ThemeData get light => dark; // Pure obsidian dark theme everywhere
}
