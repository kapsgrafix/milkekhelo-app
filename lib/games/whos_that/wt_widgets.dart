import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/feedback/fx.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/game_header.dart';
import '../../core/widgets/screen_bottom_bar.dart';
import 'wt_translations.dart';

/// Who's That design tokens (Figma "Whosthat *" frames). Fill opacities that
/// the Figma export drops were measured from the frame renders.
class WtColors {
  WtColors._();

  static const Color screenBg = Color(0xFF3D0F1E); // background/screen-pink
  static const Color pink = Color(0xFFFF5D8F); // module/pink
  static const Color green = Color(0xFF33C481); // module/green
  static const Color red = Color(0xFFE03D3D); // module/red
  static const Color slotEmpty = Color(0x59000000); // background/slot-empty (35% black)

  /// Foot sheet: 22% black over the screen colour, 1px pink top edge.
  static final Color footSheet = Color.alphaBlend(const Color(0x38000000), screenBg);

  /// Question option / check ring (measured: 7% / 30% white).
  static const Color optionFill = Color(0x12FFFFFF);
  static const Color checkRing = Color(0x4DFFFFFF);

  static Color tint(Color c, double a) => c.withAlpha((a * 255).round());

  /// Same palette and hashing as the web game, so a player keeps their
  /// colour on every device.
  static const List<Color> avatars = [
    Color(0xFF2563EB), Color(0xFF22D3EE), Color(0xFFFBBF24), Color(0xFF4ADE80), Color(0xFFEC4899),
    Color(0xFFF87171), Color(0xFF818CF8), Color(0xFFFB923C), Color(0xFF2DD4BF), Color(0xFF60A5FA),
  ];

  static Color avatarFor(String id) {
    var sum = 0;
    for (final c in id.codeUnits) {
      sum += c;
    }
    return avatars[sum % avatars.length];
  }
}

/// Screen shell shared by every Who's That frame: pink-screen background,
/// "Game Empty" header (back · how-to · language), optional 50px bottom bar.
class WtScaffold extends StatelessWidget {
  final WtText t;
  final VoidCallback onBack;
  final Widget body;
  final bool bottomBar;

  const WtScaffold({super.key, required this.t, required this.onBack, required this.body, this.bottomBar = true});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: bottomBar ? Color.alphaBlend(AppColors.surface, WtColors.screenBg) : WtColors.footSheet,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: WtColors.screenBg,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: GameHeader(title: '', onBack: onBack, onHelp: () => showWtHowToPlay(context, t)),
            ),
            Expanded(child: body),
            if (bottomBar) const ScreenBottomBar(),
          ],
        ),
      ),
    );
  }
}

/// Small floating message at the bottom of the screen.
void showWtToast(BuildContext context, String message) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xF21B0A12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.borderDefault)),
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 70),
      duration: const Duration(milliseconds: 2200),
      content: Text(message, textAlign: TextAlign.center, style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w700)),
    ),
  );
}

// ───────────────────────────── Text styles ─────────────────────────────

class WtStyle {
  WtStyle._();
  static TextStyle h1() => AppFonts.baloo(fontSize: 28, fontWeight: FontWeight.w800, height: 1.15);
  static TextStyle headingSub() => AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textMuted);
  static TextStyle fieldLabel() =>
      AppFonts.baloo(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.66);
  static TextStyle statValue() => AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w800, height: 17 / 15);
  static TextStyle statLabel() =>
      AppFonts.baloo(fontSize: 11, fontWeight: FontWeight.w600, height: 12 / 11, color: AppColors.textMuted, letterSpacing: 0.66);
}

/// Figma "Heading": h1 title over a Medium 14 muted line.
class WtHeading extends StatelessWidget {
  final String title;
  final String sub;
  const WtHeading({super.key, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, textAlign: TextAlign.center, style: WtStyle.h1()),
        Text(sub, textAlign: TextAlign.center, style: WtStyle.headingSub()),
      ],
    );
  }
}

// ───────────────────────────── Form pieces ─────────────────────────────

/// Figma "Form Card": 35% black, radius 22, 18 × 20 padding, 16 gap.
class WtFormCard extends StatelessWidget {
  final List<Widget> children;
  const WtFormCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(color: WtColors.slotEmpty, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Label (ExtraBold 11 muted, +0.66) · 7 · field.
class WtField extends StatelessWidget {
  final String label;
  final Widget child;
  final String? hint;
  const WtField({super.key, required this.label, required this.child, this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: WtStyle.fieldLabel()),
        const SizedBox(height: 7),
        child,
        if (hint != null) ...[
          const SizedBox(height: 7),
          Text(hint!, style: AppFonts.baloo(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        ],
      ],
    );
  }
}

BoxDecoration _rowDecoration() => BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderDefault, width: 1.5),
    );

/// Figma "Select Field" row: value Bold 16 white, arrow-down on the right.
class WtSelectRow extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  const WtSelectRow({super.key, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Fx.tap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: _rowDecoration(),
        child: Row(
          children: [
            Expanded(child: Text(value, style: AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w700))),
            const Icon(Icons.arrow_downward_rounded, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Figma "Stepper": 48px pink – / + squares (radius 12), 9px gaps, value box.
class WtStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const WtStepper({super.key, required this.value, required this.min, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget btn(String glyph, bool enabled, int delta) => Opacity(
          opacity: enabled ? 1 : 0.4,
          child: GestureDetector(
            onTap: enabled
                ? () {
                    Fx.tap();
                    onChanged(value + delta);
                  }
                : null,
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: WtColors.pink, borderRadius: BorderRadius.circular(12)),
              child: Text(glyph, style: AppFonts.baloo(fontSize: 22, fontWeight: FontWeight.w800, height: 1)),
            ),
          ),
        );
    return Row(
      children: [
        btn('–', value > min, -1),
        const SizedBox(width: 9),
        Expanded(
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: _rowDecoration(),
            child: Text('$value', style: AppFonts.baloo(fontSize: 22, fontWeight: FontWeight.w800, height: 1)),
          ),
        ),
        const SizedBox(width: 9),
        btn('+', value < max, 1),
      ],
    );
  }
}

/// Figma "Text Input Field" row: Medium 16, muted placeholder.
class WtTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final int maxLength;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextCapitalization capitalization;
  final List<TextInputFormatter>? formatters;
  final TextInputAction action;
  final ValueChanged<String>? onSubmitted;
  final EdgeInsets padding;

  const WtTextInput({
    super.key,
    required this.controller,
    required this.placeholder,
    this.maxLength = 16,
    this.style,
    this.textAlign = TextAlign.start,
    this.capitalization = TextCapitalization.words,
    this.formatters,
    this.action = TextInputAction.done,
    this.onSubmitted,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    final s = style ?? AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w500);
    return Container(
      padding: padding,
      decoration: _rowDecoration(),
      child: TextField(
        controller: controller,
        style: s,
        textAlign: textAlign,
        cursorColor: AppColors.brandYellow,
        textCapitalization: capitalization,
        textInputAction: action,
        onSubmitted: onSubmitted,
        autocorrect: false,
        enableSuggestions: false,
        inputFormatters: [LengthLimitingTextInputFormatter(maxLength), ...?formatters],
        decoration: InputDecoration.collapsed(
          hintText: placeholder,
          hintStyle: s.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

/// Bottom-sheet list used by the "Number of questions" select.
Future<T?> showWtPicker<T>(BuildContext context, {required List<T> values, required T selected, required String Function(T) label}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.viewPaddingOf(context).bottom),
      decoration: BoxDecoration(
        color: WtColors.footSheet,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: WtColors.tint(WtColors.pink, 0.5))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          for (final v in values) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Fx.tap();
                Navigator.of(context).pop(v);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: v == selected ? WtColors.tint(WtColors.pink, 0.16) : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: v == selected ? WtColors.pink : AppColors.borderDefault, width: 1.5),
                ),
                child: Text(label(v), style: AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    ),
  );
}

// ───────────────────────────── Game pieces ─────────────────────────────

/// Round player avatar with the initial (colour hashed from the player id).
class WtAvatar extends StatelessWidget {
  final String id;
  final String initial;
  final double size;
  final double fontSize;
  const WtAvatar({super.key, required this.id, required this.initial, this.size = 34, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: WtColors.avatarFor(id), shape: BoxShape.circle),
      child: Text(initial, style: AppFonts.baloo(fontSize: fontSize, fontWeight: FontWeight.w800, height: 1.2)),
    );
  }
}

/// Figma "Score Section": two 16-radius stat boxes (surface, 2px border),
/// 12px padding, 12px gap — "score / target · SCORE" and "n · REMAINING".
class WtScoreSection extends StatelessWidget {
  final WtText t;
  final int score;
  final int target;
  final int remaining;
  const WtScoreSection({super.key, required this.t, required this.score, required this.target, required this.remaining});

  @override
  Widget build(BuildContext context) {
    Widget box(String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDefault, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: WtStyle.statValue()),
                const SizedBox(height: 2),
                Text(label, style: WtStyle.statLabel()),
              ],
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          box('$score / $target', t.score),
          const SizedBox(width: 12),
          box('$remaining', t.remaining),
        ],
      ),
    );
  }
}

/// Figma "Foot Sheet": 22% black over the screen, 1px pink top edge, 22px
/// top corners, 16 / 20 / 28 padding (plus the phone's navigation inset).
class WtFootSheet extends StatelessWidget {
  final List<Widget> children;
  const WtFootSheet({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 16, 20, 28 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: WtColors.footSheet,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: WtColors.tint(WtColors.pink, 0.5))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Foot sheet status line (Bold 14 muted).
class WtFootNote extends StatelessWidget {
  final String text;
  const WtFootNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMuted),
      );
}

/// Figma "Button / Style=Ghost": 48px, radius 16, 2px border/default,
/// white Bold 20 label, no fill.
class WtGhostButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const WtGhostButton({super.key, required this.label, required this.onTap});

  @override
  State<WtGhostButton> createState() => _WtGhostButtonState();
}

class _WtGhostButtonState extends State<WtGhostButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: () {
          Fx.tap();
          widget.onTap();
        },
        child: Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: _down ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDefault, width: 2),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(widget.label, maxLines: 1, style: AppText.button(color: AppColors.textPrimary)),
          ),
        ),
      ),
    );
  }
}

/// Rounded-rect dashed border (Figma dashed strokes: code box, empty slots).
class WtDashedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double width;
  final double radius;
  final double dash;
  final double gap;
  const WtDashedBorder({
    super.key,
    required this.child,
    required this.color,
    this.width = 1.5,
    this.radius = 15,
    this.dash = 6,
    this.gap = 4,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashPainter(color, width, radius, dash, gap),
      child: child,
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  final double width;
  final double radius;
  final double dash;
  final double gap;
  _DashPainter(this.color, this.width, this.radius, this.dash, this.gap);

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius((Offset.zero & size).deflate(width / 2), Radius.circular(radius));
    final path = Path()..addRRect(r);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (final ui.PathMetric m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, min(d + dash, m.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter old) => old.color != color || old.width != width;
}

// ───────────────────────────── How to play ─────────────────────────────

void showWtHowToPlay(BuildContext context, WtText t) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _WtHowToSheet(t: t),
  );
}

class _WtHowToSheet extends StatelessWidget {
  final WtText t;
  const _WtHowToSheet({required this.t});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      child: Container(
        // Clear the phone's gesture / navigation bar.
        padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + MediaQuery.viewPaddingOf(context).bottom),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A1226), Color(0xFF2A0A16)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(t.howTitle, style: AppFonts.baloo(fontSize: 22, fontWeight: FontWeight.w800, color: WtColors.pink)),
              const SizedBox(height: 20),
              for (var i = 0; i < t.steps.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: WtColors.pink),
                      child: Text('${i + 1}', style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.steps[i][0], style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(t.steps[i][1],
                              style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white60)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (i != t.steps.length - 1) const SizedBox(height: 16),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: WtColors.tint(WtColors.pink, 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: WtColors.tint(WtColors.pink, 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.goalTitle, style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(t.goalText, style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
