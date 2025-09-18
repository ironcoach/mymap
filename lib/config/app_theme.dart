import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

// Theme config for FlexColorScheme version 7.3.x. Make sure you use
// same or higher package version, but still same major version. If you
// use a lower package version, some properties may not be supported.
// In that case remove them after copying this theme to your app.

  static final lightTheme = FlexThemeData.light(
    scheme: FlexScheme.verdunHemlock,


    surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
    blendLevel: 1,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 8,
      blendOnColors: false,
      useMaterial3Typography: true,
      useM2StyleDividerInM3: true,
      defaultRadius: 12.0,
      elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
      elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
      outlinedButtonOutlineSchemeColor: SchemeColor.primary,
      toggleButtonsBorderSchemeColor: SchemeColor.primary,
      segmentedButtonSchemeColor: SchemeColor.primary,
      segmentedButtonBorderSchemeColor: SchemeColor.primary,
      unselectedToggleIsColored: true,
      sliderValueTinted: true,
      inputDecoratorSchemeColor: SchemeColor.primary,
      inputDecoratorBackgroundAlpha: 31,
      inputDecoratorUnfocusedHasBorder: false,
      inputDecoratorFocusedBorderWidth: 1.0,
      inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
      fabUseShape: true,
      fabAlwaysCircular: true,
      fabSchemeColor: SchemeColor.tertiary,
      popupMenuRadius: 8.0,
      popupMenuElevation: 3.0,
      alignedDropdown: true,
      useInputDecoratorThemeInDialogs: true,
      // Completely disable drawer indicators
      drawerIndicatorRadius: 0.0,
      drawerIndicatorSchemeColor: SchemeColor.surface,
      drawerIndicatorOpacity: 0.0,
      bottomNavigationBarMutedUnselectedLabel: false,
      bottomNavigationBarMutedUnselectedIcon: false,
      menuRadius: 8.0,
      menuElevation: 3.0,
      menuBarRadius: 0.0,
      menuBarElevation: 2.0,
      menuBarShadowColor: Color(0x00000000),
      navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
      navigationBarMutedUnselectedLabel: false,
      navigationBarSelectedIconSchemeColor: SchemeColor.onPrimary,
      navigationBarMutedUnselectedIcon: false,
      navigationBarIndicatorSchemeColor: SchemeColor.primary,
      navigationBarIndicatorOpacity: 1.00,
      navigationBarIndicatorRadius: 12.0,
      navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
      navigationRailMutedUnselectedLabel: false,
      navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
      navigationRailMutedUnselectedIcon: false,
      navigationRailIndicatorSchemeColor: SchemeColor.primary,
      navigationRailIndicatorOpacity: 1.00,
      navigationRailIndicatorRadius: 12.0,
      navigationRailBackgroundSchemeColor: SchemeColor.surface,
    ),
    keyColors: const FlexKeyColors(
      useSecondary: true,
      useTertiary: true,
      keepPrimary: true,
    ),
    tones: FlexTones.jolly(Brightness.light),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    // To use the Playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  ).copyWith(
    // Override drawer theme to eliminate all indicators
    drawerTheme: const DrawerThemeData(
      backgroundColor: null, // Use theme default
      scrimColor: null,
      elevation: 16,
    ),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: null,
      elevation: 16,
      indicatorColor: Colors.transparent,
      indicatorShape: const RoundedRectangleBorder(),
    ),
    listTileTheme: const ListTileThemeData(
      selectedTileColor: Colors.transparent,
      selectedColor: null,
      tileColor: Colors.transparent,
    ),
  );

  static final darkTheme = FlexThemeData.dark(
    scheme: FlexScheme.blueM3,
    surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
    blendLevel: 2,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      useMaterial3Typography: true,
      useM2StyleDividerInM3: true,
      defaultRadius: 12.0,
      elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
      elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
      outlinedButtonOutlineSchemeColor: SchemeColor.primary,
      toggleButtonsBorderSchemeColor: SchemeColor.primary,
      segmentedButtonSchemeColor: SchemeColor.primary,
      segmentedButtonBorderSchemeColor: SchemeColor.primary,
      unselectedToggleIsColored: true,
      sliderValueTinted: true,
      inputDecoratorSchemeColor: SchemeColor.primary,
      inputDecoratorBackgroundAlpha: 43,
      inputDecoratorUnfocusedHasBorder: false,
      inputDecoratorFocusedBorderWidth: 1.0,
      inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
      fabUseShape: true,
      fabAlwaysCircular: true,
      fabSchemeColor: SchemeColor.tertiary,
      popupMenuRadius: 8.0,
      popupMenuElevation: 3.0,
      alignedDropdown: true,
      useInputDecoratorThemeInDialogs: true,
      // Completely disable drawer indicators
      drawerIndicatorRadius: 0.0,
      drawerIndicatorSchemeColor: SchemeColor.surface,
      drawerIndicatorOpacity: 0.0,
      bottomNavigationBarMutedUnselectedLabel: false,
      bottomNavigationBarMutedUnselectedIcon: false,
      menuRadius: 8.0,
      menuElevation: 3.0,
      menuBarRadius: 0.0,
      menuBarElevation: 2.0,
      menuBarShadowColor: Color(0x00000000),
      navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
      navigationBarMutedUnselectedLabel: false,
      navigationBarSelectedIconSchemeColor: SchemeColor.onPrimary,
      navigationBarMutedUnselectedIcon: false,
      navigationBarIndicatorSchemeColor: SchemeColor.primary,
      navigationBarIndicatorOpacity: 1.00,
      navigationBarIndicatorRadius: 12.0,
      navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
      navigationRailMutedUnselectedLabel: false,
      navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
      navigationRailMutedUnselectedIcon: false,
      navigationRailIndicatorSchemeColor: SchemeColor.primary,
      navigationRailIndicatorOpacity: 1.00,
      navigationRailIndicatorRadius: 12.0,
      navigationRailBackgroundSchemeColor: SchemeColor.surface,
    ),
    keyColors: const FlexKeyColors(
      useSecondary: true,
      useTertiary: true,
    ),
    tones: FlexTones.jolly(Brightness.dark),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    // To use the Playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  ).copyWith(
    // Override drawer theme to eliminate all indicators
    drawerTheme: const DrawerThemeData(
      backgroundColor: null, // Use theme default
      scrimColor: null,
      elevation: 16,
    ),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: null,
      elevation: 16,
      indicatorColor: Colors.transparent,
      indicatorShape: const RoundedRectangleBorder(),
    ),
    listTileTheme: const ListTileThemeData(
      selectedTileColor: Colors.transparent,
      selectedColor: null,
      tileColor: Colors.transparent,
    ),
  );
}
