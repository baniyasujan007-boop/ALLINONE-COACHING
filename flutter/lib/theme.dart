import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color purple = Color(0xFF6C63FF);
  static const Color blue = Color(0xFF4DA6FF);
  static const Color pink = Color(0xFFFF6EC7);

  static const Color orange = Color(0xFFFF9F43);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color green = Color(0xFF8DDC5A);

  static const List<Color> primaryGradient = <Color>[purple, blue, pink];
}

class AppTheme {
  static const PageTransitionsTheme _transitions = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
    },
  );

  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.purple,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF4F6FB),
      textTheme: GoogleFonts.poppinsTextTheme(),
      pageTransitionsTheme: _transitions,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.purple,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF121225),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      pageTransitionsTheme: _transitions,
      cardTheme: CardThemeData(
        color: const Color(0xFF1D1C39),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1D1C39),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class AppDecorations {
  static BoxDecoration gradientBg({bool dark = false}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? const <Color>[
                Color(0xFF11112A),
                Color(0xFF1E1A3F),
                Color(0xFF281B45),
              ]
            : const <Color>[
                Color(0xFFF6F7FF),
                Color(0xFFF9F3FF),
                Color(0xFFFFF4FB),
              ],
      ),
    );
  }

  static BoxDecoration glassCard(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: dark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.62),
      border: Border.all(
        color: dark ? Colors.white12 : Colors.white.withValues(alpha: 0.8),
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.28 : 0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration softNeu(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color base = dark ? const Color(0xFF212041) : const Color(0xFFF0F3FB);
    return BoxDecoration(
      color: base,
      borderRadius: BorderRadius.circular(20),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: dark ? Colors.black.withValues(alpha: 0.35) : Colors.white,
          offset: const Offset(-4, -4),
          blurRadius: 12,
        ),
        BoxShadow(
          color: dark ? Colors.white10 : Colors.black.withValues(alpha: 0.09),
          offset: const Offset(6, 6),
          blurRadius: 12,
        ),
      ],
    );
  }
}
