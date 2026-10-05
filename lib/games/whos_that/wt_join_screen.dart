import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/feedback/fx.dart';
import '../../core/localization/app_language.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/chunky_button.dart';
import 'wt_game_screen.dart';
import 'wt_session.dart';
import 'wt_translations.dart';
import 'wt_widgets.dart';

/// Figma "Whosthat Join" (334:417): heading · 20 · form card (4-letter game
/// code in ExtraBold 30 with 9px tracking, your name) · 20 · Join button.
class WtJoinScreen extends StatefulWidget {
  const WtJoinScreen({super.key});

  @override
  State<WtJoinScreen> createState() => _WtJoinScreenState();
}

class _WtJoinScreenState extends State<WtJoinScreen> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  bool _busy = false;

  /// Set while waiting for the host to let us into a running game.
  WtJoinRequest? _request;

  @override
  void dispose() {
    _request?.cancel();
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _ask(WtText t, String code, String name) async {
    final WtJoinRequest req;
    try {
      req = await WtJoinRequest.send(code: code, name: name);
    } on WtException {
      if (mounted) showWtToast(context, t.networkError);
      return;
    }
    if (!mounted) {
      req.cancel();
      return;
    }
    setState(() => _request = req);
    final answer = await req.answer;
    if (!mounted || _request != req) return;
    setState(() => _request = null);
    final lt = WtText(AppLanguage.instance.value);
    switch (answer) {
      case WtJoinAnswer.accepted:
        Fx.roundWin();
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => WtGameScreen(session: req.toSession())));
      case WtJoinAnswer.declined:
        showWtToast(context, lt.declined);
      case WtJoinAnswer.full:
        showWtToast(context, lt.gameFull);
      case WtJoinAnswer.ended:
        showWtToast(context, lt.noGame);
      case WtJoinAnswer.cancelled:
        break;
    }
  }

  void _cancelAsk() {
    final r = _request;
    if (r == null) return;
    setState(() => _request = null);
    r.cancel();
  }

  Future<void> _join(WtText t) async {
    final code = _code.text.trim().toUpperCase();
    final name = _name.text.trim();
    if (code.length != 4) {
      showWtToast(context, t.enterCode);
      return;
    }
    if (name.isEmpty) {
      showWtToast(context, t.enterName);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final session = await WtSession.join(code: code, name: name);
      if (!mounted) {
        session.leave();
        session.dispose();
        return;
      }
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => WtGameScreen(session: session)));
    } on WtException catch (e) {
      if (!mounted) return;
      if (e.reason == WtFailure.started) {
        await _ask(t, code, name);
        return;
      }
      showWtToast(context, switch (e.reason) {
        WtFailure.notFound => t.noGame,
        WtFailure.started => t.alreadyStarted,
        WtFailure.full => t.gameFull,
        WtFailure.network => t.networkError,
      });
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
          onBack: () {
            if (_request != null) {
              _cancelAsk();
            } else {
              Navigator.of(context).pop();
            }
          },
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
                        if (_request != null) ..._waiting(t) else ...[
                        WtHeading(title: t.joinGame, sub: t.joinHeadingSub),
                        const SizedBox(height: 20),
                        WtFormCard(children: [
                          WtField(
                            label: t.lCode,
                            child: WtTextInput(
                              controller: _code,
                              placeholder: 'ABCD',
                              maxLength: 4,
                              textAlign: TextAlign.center,
                              capitalization: TextCapitalization.characters,
                              action: TextInputAction.next,
                              style: AppFonts.baloo(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 9),
                              formatters: [_UpperAlnum()],
                            ),
                          ),
                          WtField(
                            label: t.lName,
                            child: WtTextInput(
                              controller: _name,
                              placeholder: t.phName,
                              onSubmitted: (_) => _join(t),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 20),
                        ChunkyButton(
                          label: _busy ? t.joining : t.joinGame,
                          width: double.infinity,
                          onTap: _busy ? null : () => _join(t),
                        ),
                        ],
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

extension on _WtJoinScreenState {
  /// Waiting for the host (game already running): heading, a card with a
  /// spinner and the code, and Cancel.
  List<Widget> _waiting(WtText t) => [
        WtHeading(title: t.askingTitle, sub: t.askingSub),
        const SizedBox(height: 20),
        WtFormCard(children: [
          Column(
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3, color: WtColors.pink),
              ),
              const SizedBox(height: 14),
              Text(_request!.code,
                  style: AppFonts.baloo(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 9, color: AppColors.brandYellow)),
              const SizedBox(height: 4),
              Text(t.waitingApproval,
                  textAlign: TextAlign.center,
                  style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
            ],
          ),
        ]),
        const SizedBox(height: 20),
        WtGhostButton(label: t.cancel, onTap: _cancelAsk),
      ];
}

/// Upper-cases the code and drops anything that isn't A–Z / 0–9.
class _UpperAlnum extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
