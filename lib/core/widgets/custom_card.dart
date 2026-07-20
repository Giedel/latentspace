import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Border? border;
  final double elevation;

  const CustomCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.border,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(20);

    Widget cardChild = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: effectiveRadius,
        border: border ?? Border.all(color: Colors.grey.withValues(alpha: 0.12)),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04 * elevation),
                  blurRadius: 10 * elevation,
                  offset: Offset(0, 4 * elevation),
                )
              ]
            : null,
      ),
      child: child,
    );

    if (margin != null) {
      cardChild = Padding(padding: margin!, child: cardChild);
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: effectiveRadius,
          onTap: onTap,
          child: cardChild,
        ),
      );
    }

    return cardChild;
  }
}
