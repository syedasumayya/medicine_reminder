import 'dart:convert';
import 'package:flutter/material.dart';
import 'logo_data.dart';

/// The "My Medicine" logo. It has dark purple letters, so it should always
/// sit on a light background.
class AppLogo extends StatelessWidget {
  final double width;

  const AppLogo({super.key, this.width = 240});

  // The picture is stored as text in logo_data.dart.
  static final MemoryImage _image = MemoryImage(base64Decode(kLogoBase64));

  @override
  Widget build(BuildContext context) {
    return Image(
      image: _image,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => Text(
        'My Medicine',
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
