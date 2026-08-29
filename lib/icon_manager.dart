import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IconManager {
  static final IconManager _instance = IconManager._internal();
  factory IconManager() => _instance;
  IconManager._internal();

  final Map<String, String> _iconSvgMap = {};

  Future<void> loadIcons(String path) async {
    final jsonString = await rootBundle.loadString(path);
    final List<dynamic> data = jsonDecode(jsonString)['icons'];

    for (final iconEntry in data) {
      final name = iconEntry["properties"]["name"] as String;
      final paths = iconEntry["icon"]["paths"] as List<dynamic>;
      final svgPaths = paths.map((p) => '<path d="$p"/>').join('\n');
      final width = (iconEntry["icon"]["width"] ?? 1024).toDouble();
      final height = (iconEntry["icon"]["height"] ?? 1024).toDouble();

      final svgString = '''
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $width $height">
        $svgPaths
        </svg>
      ''';

      _iconSvgMap[name] = svgString;
    }
  }

  Widget getIcon(String name, {double size = 24, Color? color}) {
    final svgString = _iconSvgMap[name];

    if (svgString == null) {
      return const SizedBox.shrink(); // fallback
    }

    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
    );
  }
}
