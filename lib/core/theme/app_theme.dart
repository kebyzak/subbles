import 'package:flutter/material.dart';
import 'package:subbles/core/theme/colors.dart';
import 'package:subbles/core/widgets/bubble_surface.dart';

final appTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'PlusJakartaSans',
  scaffoldBackgroundColor: bubbleCanvas,
  colorScheme: ColorScheme.fromSeed(
    seedColor: accent,
    primary: ink,
    secondary: accent,
    surface: paper,
  ),
  textTheme: ThemeData.light().textTheme.apply(
    fontFamily: 'PlusJakartaSans',
    bodyColor: ink,
    displayColor: ink,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style:
        FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ).copyWith(
          backgroundBuilder: (context, states, child) => DecoratedBox(
            decoration: bubbleSurfaceDecoration(
              radius: 20,
              color: states.contains(WidgetState.disabled)
                  ? muted.withValues(alpha: .16)
                  : ink,
            ),
            child: child,
          ),
        ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      foregroundColor: ink,
      backgroundColor: Colors.white.withValues(alpha: .55),
      side: BorderSide(color: Colors.white.withValues(alpha: .9)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: ink,
      backgroundColor: Colors.white.withValues(alpha: .4),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: ink,
      backgroundColor: Colors.white.withValues(alpha: .45),
      side: BorderSide(color: Colors.white.withValues(alpha: .7)),
      shape: const CircleBorder(),
    ),
  ),
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: ButtonStyle(
      foregroundColor: const WidgetStatePropertyAll(ink),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? mint.withValues(alpha: .9)
            : Colors.white.withValues(alpha: .6),
      ),
      side: WidgetStatePropertyAll(
        BorderSide(color: Colors.white.withValues(alpha: .9)),
      ),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled) ? paper : Colors.white,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? mint
          : muted.withValues(alpha: .18),
    ),
    trackOutlineColor: WidgetStatePropertyAll(
      Colors.white.withValues(alpha: .8),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white.withValues(alpha: .95),
    surfaceTintColor: Colors.transparent,
    shadowColor: ink.withValues(alpha: .14),
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
      side: BorderSide(color: Colors.white.withValues(alpha: .9)),
    ),
  ),
  datePickerTheme: DatePickerThemeData(
    backgroundColor: const Color(0xF5F3F6F0),
    surfaceTintColor: Colors.transparent,
    headerBackgroundColor: mint.withValues(alpha: .6),
    headerForegroundColor: ink,
    dividerColor: Colors.white.withValues(alpha: .8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
      side: BorderSide(color: Colors.white.withValues(alpha: .9)),
    ),
    dayForegroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? muted.withValues(alpha: .45)
          : ink,
    ),
    dayBackgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected) ? mint : null,
    ),
    todayForegroundColor: const WidgetStatePropertyAll(accent),
    todayBorder: const BorderSide(color: accent),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: ink.withValues(alpha: .95),
    contentTextStyle: const TextStyle(color: Colors.white),
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: Colors.white.withValues(alpha: .2)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white.withValues(alpha: .8),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: .9)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: accent.withValues(alpha: .6)),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.transparent,
    indicatorColor: mint,
    indicatorShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(100),
    ),
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        size: 20,
        color: states.contains(WidgetState.selected) ? ink : muted,
      ),
    ),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ink),
    ),
  ),
);
