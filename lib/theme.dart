import 'package:arkham_decks/factions.dart';
import 'package:flutter/material.dart';

class FactionColors {
  final Color light, dark;

  const FactionColors({required this.light, required this.dark});
}

abstract class AppColors {
  static const _nord0 = Color(0xFF2E3440);
  static const _nordPoint5 = Color(0xFF353B49);
  static const _nord1 = Color(0xFF3B4252);
  static const _nord2 = Color(0xFF434C5E);
  static const _nord3 = Color(0xFF4C566A);
  static const _nord4 = Color(0xFFD8DEE9);
  static const _nord5 = Color(0xFFE5E9F0);
  static const _nord6 = Color(0xFFECEFF4);

  // semantic
  static const _guardian = FactionColors(
    light: Color(0xFF5CB4FD),
    dark: Color(0xFF1072C2),
  );
  static const _seeker = FactionColors(
    light: Color(0xFFEFA345),
    dark: Color(0xFFDB7C07),
  );
  static const _rogue = FactionColors(
    light: Color(0xFF48B14F),
    dark: Color(0xFF219428),
  );
  static const _mystic = FactionColors(
    light: Color(0xFFBA81F2),
    dark: Color(0xFF7554AB),
  );
  static const _survivor = FactionColors(
    light: Color(0xFFEE4A53),
    dark: Color(0xFFCC3038),
  );
  static const _neutral = FactionColors(
    light: Color(0xFFF5F0E1),
    dark: Color(0xFF475259),
  );
  static const _multi = FactionColors(
    light: Color(0xFFE9D06C),
    dark: Color(0xFFcfb13a),
  );

  static const _willpower = Color(0xFF2C7FC0);
  static const _intellect = Color(0xFF7C3C85);
  static const _combat = Color(0xFFAE4236);
  static const _agility = Color(0xFF14854D);
  static const _wild = Color(0xFF8A7D5A);

  static const health = Color(0xFF8D181E);
  static const sanity = Color(0xFF165385);

  static const taboo = Color(0xFF9869F5);

  // TODO: maybe define operator [] directly for AppColors
  // instead of having to AppColors.factions[] ?
  static const Map<Faction, FactionColors> factions = {
    Faction.guardian: _guardian,
    Faction.seeker: _seeker,
    Faction.rogue: _rogue,
    Faction.mystic: _mystic,
    Faction.survivor: _survivor,
    Faction.neutral: _neutral,
    Faction.multi: _multi,
  };

  static const List<Color> stats = [
    _willpower,
    _intellect,
    _combat,
    _agility,
    _wild,
  ];
}

class AppTheme {
  static ThemeData theme() {
    final base = ThemeData.dark(useMaterial3: true);

    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors._nord5,
      onPrimary: Color(0xFF232C61),
      primaryContainer: AppColors._nord3,
      onPrimaryContainer: AppColors._nord6,
      primaryFixed: Color(0xFFDFE0FF),
      primaryFixedDim: Color(0xFFBBC3FF),
      onPrimaryFixed: Color(0xFF0C154B),
      onPrimaryFixedVariant: Color(0xFF3A4279),
      secondary: Color(0xFFC4C5DD),
      onSecondary: Color(0xFF2D2F42),
      secondaryContainer: AppColors._nord2,
      onSecondaryContainer: AppColors._nord6,
      secondaryFixed: Color(0xFFE0E1F9),
      secondaryFixedDim: Color(0xFFC4C5DD),
      onSecondaryFixed: Color(0xFF181A2C),
      onSecondaryFixedVariant: Color(0xFF434559),
      tertiary: Color(0xFFE6BAD7),
      onTertiary: Color(0xFF45263D),
      tertiaryContainer: Color(0xFF5D3C54),
      onTertiaryContainer: Color(0xFFFFD7F0),
      tertiaryFixed: Color(0xFFFFD7F0),
      tertiaryFixedDim: Color(0xFFE6BAD7),
      onTertiaryFixed: Color(0xFF2D1227),
      onTertiaryFixedVariant: Color(0xFF5D3C54),
      error: Color(0xFFFF0000),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF39313D),
      onErrorContainer: AppColors._nord6,
      surface: AppColors._nord0,
      onSurface: AppColors._nord4,
      surfaceDim: AppColors._nord2,
      surfaceBright: Color(0xFF39393F),
      surfaceContainerLowest: Color(0xFF0D0E13),
      surfaceContainerLow: AppColors._nord1,
      surfaceContainer: AppColors._nordPoint5,
      surfaceContainerHigh: Color(0xFF29292F),
      surfaceContainerHighest: Color(0xFF34343A),
      onSurfaceVariant: AppColors._nord5,
      outline: AppColors._nord3,
      outlineVariant: Color(0xFF46464F),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE4E1E9),
      onInverseSurface: Color(0xFF303036),
      inversePrimary: Color(0xFF525A92),
      surfaceTint: Color(0xFFBBC3FF),
    );

    final textTheme = TextTheme(
      headlineMedium: const TextStyle(fontFamily: 'Arkhamic', fontSize: 24.0),
      bodyMedium: const TextStyle(
        fontFamily: 'Alegreya',
        fontSize: 16.0,
        wordSpacing: -0.7,
      ),
      bodySmall: const TextStyle(
        fontFamily: 'Alegreya',
        fontStyle: FontStyle.italic,
        fontSize: 15.0,
        fontVariations: [FontVariation('wght', 450)],
        letterSpacing: -0.1,
      ),
    );

    final appBarTheme = AppBarTheme(
      titleTextStyle: textTheme.headlineMedium!.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      backgroundColor: colorScheme.surfaceContainer,
      elevation: 0.0,
      scrolledUnderElevation: 0.0,
      actionsIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
    );
    final listTileTheme = ListTileThemeData(
      titleTextStyle: textTheme.headlineMedium!.copyWith(
        fontSize: 22.0,
        color: colorScheme.onSurface,
      ),
      subtitleTextStyle: textTheme.bodySmall!.copyWith(
        fontSize: 14.0,
        color: colorScheme.onSurface,
      ),
      minVerticalPadding: 0.0,
      visualDensity: VisualDensity(horizontal: 0.0, vertical: -4.0),
    );

    final navigationBarTheme = NavigationBarThemeData(
      labelTextStyle: WidgetStateProperty<TextStyle?>.fromMap({
        WidgetState.any: textTheme.bodyMedium!.copyWith(
          fontVariations: [FontVariation('wght', 500)],
          height: 1,
        ),
      }),
    );

    final filledButtonTheme = FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: Size(130.0, 40.0),
        elevation: 1.0,
        textStyle: textTheme.bodyMedium!.copyWith(fontSize: 18.0),
      ),
    );

    final textButtonTheme = TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: textTheme.bodyMedium),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: appBarTheme,
      listTileTheme: listTileTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      navigationBarTheme: navigationBarTheme,
      filledButtonTheme: filledButtonTheme,
      textButtonTheme: textButtonTheme,
    );
  }
}

// TODO: put this in a widgets.dart
class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function clear;
  final Function onChanged;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.clear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.0,
      child: TextField(
        controller: controller,
        autocorrect: false,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.search),
          suffixIcon: IconButton(
            onPressed: () => clear(),
            icon: Icon(Icons.clear),
          ),
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        onChanged: (searchText) => onChanged(searchText),
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
      ),
    );
  }
}
