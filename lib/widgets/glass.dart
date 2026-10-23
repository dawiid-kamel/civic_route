/// Frosted-glass card widget.
///
/// `GlassContainer` blurs whatever is behind it and adds a translucent tint.
/// It is used on the gradient Home screen (category cards, location pill,
/// empty-search message) so the content stays readable over the backdrop.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

/// A rounded card that blurs what is behind it and adds a see-through tint,
/// giving the frosted-glass look on top of the gradient backdrop.
class GlassContainer extends StatelessWidget {
  /// Content shown on top of the glass.
  final Widget child;
  /// Space between the glass edge and [child].
  final EdgeInsetsGeometry padding;
  /// Corner radius of the card, also used to clip the blur.
  final double radius;
  /// How strong the tint is, from 0 (clear) to 1 (solid).
  final double opacity;
  /// Base color of the glass; white by default.
  final Color tint;
  /// Optional custom border; when null a faint white outline is drawn.
  final BoxBorder? border;

  /// Creates a frosted-glass card around [child].
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.opacity = 0.2,
    this.tint = Colors.white,
    this.border,
  });

  /// Clips to rounded corners, blurs the backdrop, then paints the tinted box.
  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: opacity),
            borderRadius: borderRadius,
            border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: child,
        ),
      ),
    );
  }
}