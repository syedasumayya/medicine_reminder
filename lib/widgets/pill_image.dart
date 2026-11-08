import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/medicine.dart';
import 'pill_data.dart';

/// Shows one of the nine pill pictures (index 0 to 8).
class PillImage extends StatelessWidget {
  final int index;
  final double size;

  const PillImage({super.key, required this.index, this.size = 48});

  // The pictures are stored as text in pill_data.dart.
  // We turn them into images once, and reuse them everywhere.
  static final List<MemoryImage> _images = kPillImagesBase64
      .map((text) => MemoryImage(base64Decode(text)))
      .toList();

  /// How many pill pictures there are (9).
  static int get count => _images.length;

  /// Picks a picture automatically from the medicine's name and dose.
  /// [seed] makes the choice stable (the same medicine always gets the
  /// same picture) while different medicines get different pictures.
  static int suggest({
    required String name,
    required String dose,
    required int seed,
  }) {
    final n = name.toLowerCase();
    final d = dose.toLowerCase();
    if (n.contains('vitamin') || n.contains('omega') || n.contains('fish oil')) {
      return 7; // amber softgel
    }
    if (d.contains('capsule')) {
      return const [0, 2, 4][seed % 3]; // capsules
    }
    if (d.contains('tablet')) {
      return const [1, 3, 5, 6][seed % 4]; // tablets
    }
    return seed % count;
  }

  /// The picture to show for a medicine: the one the user chose,
  /// or an automatic one.
  static int forMedicine(Medicine medicine) {
    return medicine.iconIndex ??
        suggest(name: medicine.name, dose: medicine.dose, seed: medicine.id);
  }

  @override
  Widget build(BuildContext context) {
    return Image(
      image: _images[index % count],
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.medication,
        size: size * 0.6,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// A pill picture on a soft lavender background (round or rounded square).
class PillBadge extends StatelessWidget {
  final int index;
  final double size;
  final bool circle;

  const PillBadge({
    super.key,
    required this.index,
    this.size = 56,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size * 0.3),
      ),
      child: PillImage(index: index, size: size * 0.76),
    );
  }
}
