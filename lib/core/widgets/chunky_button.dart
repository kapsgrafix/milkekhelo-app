import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum ChunkyButtonStyle { primary, secondary }

/// Figma "Button" (Primary / Secondary): 48px tall (size/tap-min), radius 16
/// (radius/lg), top→bottom gradient, 4px solid bevel shadow (action/*-shadow).
///  * Pressed: shadow removed, face drops 4px, flattens to a solid tone.
///  * Disabled (onTap == null): 40% opacity.
///
/// Pass a [label] for a text button (Bold 20, text/on-light for primary,
/// white for secondary) or a [child] (e.g. a 16px icon) for square buttons.
class ChunkyButton extends StatefulWidget {
  final ChunkyButtonStyle style;
  final String? label;
  final Widget? child;
  final VoidCallback? onTap;
  final double? width;
  final String? semanticLabel;

  const ChunkyButton({
    super.key,
    this.style = ChunkyButtonStyle.primary,
    this.label,
    this.child,
    this.onTap,
    this.width,
    this.semanticLabel,
  })  : _icon = null,
        assert(label != null || child != null);

  /// 48×48 square Secondary CTA holding a 16px icon (e.g. Back / Refresh).
  const ChunkyButton.icon({
    super.key,
    required IconData icon,
    this.onTap,
    this.semanticLabel,
    this.style = ChunkyButtonStyle.secondary,
  })  : label = null,
        width = 48,
        child = null,
        _icon = icon;

  final IconData? _icon;

  static const double height = 48;
  static const double bevel = 4;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _pressed = false;

  void _set(bool v) {
    if (widget.onTap == null || _pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.style == ChunkyButtonStyle.primary;
    final gradient = primary ? AppColors.primaryGradient : AppColors.secondaryGradient;
    final shadow = primary ? AppColors.primaryShadow : AppColors.secondaryShadow;
    final fg = primary ? AppColors.textOnLight : AppColors.textPrimary;

    Widget content;
    if (widget.label != null) {
      content = FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(widget.label!, maxLines: 1, softWrap: false, style: AppText.button(color: fg)),
      );
    } else if (widget._icon != null) {
      content = Icon(widget._icon, size: 16, color: fg);
    } else {
      content = widget.child!;
    }

    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.semanticLabel ?? widget.label,
      child: Opacity(
        opacity: widget.onTap == null ? 0.4 : 1,
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => _set(true),
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: widget.width,
            height: ChunkyButton.height + ChunkyButton.bevel,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              curve: Curves.easeOut,
              margin: EdgeInsets.only(
                top: _pressed ? ChunkyButton.bevel : 0,
                bottom: _pressed ? 0 : ChunkyButton.bevel,
              ),
              padding: EdgeInsets.symmetric(horizontal: widget.label != null ? 24 : 0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _pressed ? Color.lerp(gradient.first, gradient.last, 0.55) : null,
                gradient: _pressed
                    ? null
                    : LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: gradient),
                boxShadow: _pressed ? const [] : [BoxShadow(color: shadow, offset: const Offset(0, ChunkyButton.bevel))],
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
