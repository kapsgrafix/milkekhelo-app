import 'package:flutter/material.dart';

import '../../core/localization/app_language.dart';
import '../../core/widgets/chunky_button.dart';
import 'wt_game_screen.dart';
import 'wt_session.dart';
import 'wt_translations.dart';
import 'wt_widgets.dart';

/// Figma "Whosthat Create" (325:357): heading · 20 · form card (questions
/// select, target stepper, your name) · 20 · Create button, all centred in
/// the space between the header and the bottom bar.
class WtCreateScreen extends StatefulWidget {
  const WtCreateScreen({super.key});

  @override
  State<WtCreateScreen> createState() => _WtCreateScreenState();
}

class _WtCreateScreenState extends State<WtCreateScreen> {
  static const _questionOptions = [5, 10, 15, 20];

  final _name = TextEditingController();
  int _qCount = 10;
  int _target = 5;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickCount(WtText t) async {
    final v = await showWtPicker<int>(context, values: _questionOptions, selected: _qCount, label: t.qOption);
    if (v == null || !mounted) return;
    setState(() {
      _qCount = v;
      if (_target > v) _target = v;
    });
  }

  Future<void> _create(WtText t) async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showWtToast(context, t.enterName);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final session = await WtSession.create(hostName: name, qCount: _qCount, target: _target);
      if (!mounted) {
        session.leave();
        session.dispose();
        return;
      }
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => WtGameScreen(session: session)));
    } on WtException {
      if (mounted) showWtToast(context, t.networkError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final t = WtText(lang);
        return WtScaffold(
          t: t,
          onBack: () => Navigator.of(context).pop(),
          body: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 312),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        WtHeading(title: t.createGame, sub: t.createHeadingSub),
                        const SizedBox(height: 20),
                        WtFormCard(children: [
                          WtField(
                            label: t.lQuestions,
                            child: WtSelectRow(value: t.qOption(_qCount), onTap: () => _pickCount(t)),
                          ),
                          WtField(
                            label: t.lTarget,
                            hint: t.targetHint(_qCount),
                            child: WtStepper(
                              value: _target,
                              min: 1,
                              max: _qCount,
                              onChanged: (v) => setState(() => _target = v),
                            ),
                          ),
                          WtField(
                            label: t.lName,
                            child: WtTextInput(
                              controller: _name,
                              placeholder: t.phName,
                              onSubmitted: (_) => _create(t),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 20),
                        ChunkyButton(
                          label: _busy ? t.creating : t.create,
                          width: double.infinity,
                          onTap: _busy ? null : () => _create(t),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
