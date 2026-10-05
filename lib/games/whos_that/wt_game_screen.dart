import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/feedback/fx.dart';
import '../../core/localization/app_language.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/chunky_button.dart';
import 'wt_questions.dart';
import 'wt_session.dart';
import 'wt_translations.dart';
import 'wt_widgets.dart';

/// The live game, one route for the whole match — the screen follows the
/// room's phase (driven by the host, same as the web game):
///   lobby    → Figma "Whosthat Lobby" / "Lobby - Active"
///   question → "Whosthat Question" / "Question - Status States"
///   reveal   → "Whosthat Bullseye" / "Majority Pick" / "Tie"
///   end      → "Whosthat Win" / "Good Game"
class WtGameScreen extends StatefulWidget {
  final WtSession session;
  const WtGameScreen({super.key, required this.session});

  @override
  State<WtGameScreen> createState() => _WtGameScreenState();
}

class _WtGameScreenState extends State<WtGameScreen> {
  WtSession get s => widget.session;

  final _confetti = GlobalKey<_WtConfettiState>();
  bool _exiting = false;
  String _lastPhase = '';
  int _lastQ = -1;
  int _lastPlayers = 0;
  String? _pendingPick;

  @override
  void initState() {
    super.initState();
    s.addListener(_onSession);
  }

  @override
  void dispose() {
    s.removeListener(_onSession);
    s.dispose();
    super.dispose();
  }

  WtText get _t => WtText(AppLanguage.instance.value);

  void _onSession() {
    if (!mounted || _exiting) return;
    if (s.ended || s.removed) {
      _exiting = true;
      showWtToast(context, s.removed ? _t.youWereRemoved : _t.gameEnded);
      Navigator.of(context).pop();
      return;
    }
    if (!s.ready) return;

    // Moments: sounds, haptics, confetti.
    final phase = s.phase;
    final q = s.qIndex;
    if (phase != _lastPhase || q != _lastQ) {
      if (phase == 'question') {
        _pendingPick = null;
        if (_lastPhase.isNotEmpty) Fx.cardFlip();
      } else if (phase == 'reveal') {
        final r = s.roundResult;
        if (r?.outcome == WtOutcome.bullseye) {
          Fx.correct();
        } else {
          Fx.turn();
        }
      } else if (phase == 'end' && _lastPhase.isNotEmpty) {
        if (s.won) {
          Fx.win();
          WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.currentState?.fire());
        } else {
          Fx.lose();
        }
      }
      _lastPhase = phase;
      _lastQ = q;
    }
    final count = s.players.length;
    if (phase == 'lobby' && count > _lastPlayers && _lastPlayers > 0) Fx.toggle();
    _lastPlayers = count;
  }

  // ───────────────────────── Leaving ─────────────────────────

  Future<void> _confirmLeave() async {
    if (_exiting) return;
    final t = _t;
    if (s.phase == 'end') {
      await _leave();
      return;
    }
    final ok = await _confirm(
      title: t.leaveTitle,
      body: s.isHost ? t.leaveHostBody : t.leaveBody,
      confirm: t.leave,
      cancel: t.stay,
    );
    if (ok == true) await _leave();
  }

  Future<void> _leave() async {
    if (_exiting) return;
    _exiting = true;
    await s.leave();
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool?> _confirm({required String title, required String body, required String confirm, required String cancel}) {
    return showDialog<bool>(
      context: context,
      barrierColor: const Color(0xB3000000),
      builder: (context) => Dialog(
        backgroundColor: WtColors.footSheet,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: WtColors.tint(WtColors.pink, 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, textAlign: TextAlign.center, style: AppFonts.baloo(fontSize: 22, fontWeight: FontWeight.w800)),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(body,
                    textAlign: TextAlign.center,
                    style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              ],
              const SizedBox(height: 20),
              ChunkyButton(label: confirm, width: double.infinity, onTap: () => Navigator.of(context).pop(true)),
              const SizedBox(height: 12),
              WtGhostButton(label: cancel, onTap: () => Navigator.of(context).pop(false)),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Actions ─────────────────────────

  Future<void> _pick(String id) async {
    if (s.myAnswer != null || _pendingPick != null) return;
    Fx.tap();
    setState(() => _pendingPick = id);
    final ok = await s.answer(id);
    if (!ok && mounted) {
      setState(() => _pendingPick = null);
      showWtToast(context, _t.sendFailed);
    }
  }

  Future<void> _remove(WtPlayer p) async {
    final t = _t;
    final ok = await _confirm(title: t.removeConfirm(p.name), body: '', confirm: t.remove, cancel: t.stay);
    if (ok == true && !await s.removePlayer(p.id) && mounted) showWtToast(context, t.sendFailed);
  }

  Future<void> _hostAction(Future<bool> Function() action) async {
    if (!await action() && mounted) showWtToast(context, _t.sendFailed);
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: ValueListenableBuilder<AppLang>(
        valueListenable: AppLanguage.instance,
        builder: (context, lang, _) {
          final t = WtText(lang);
          return ListenableBuilder(
            listenable: s,
            builder: (context, _) {
              final phase = s.ready ? s.phase : 'loading';
              final withSheet = phase == 'lobby' || (phase == 'reveal' && _revealHasSheet);
              return Stack(
                children: [
                  WtScaffold(
                    t: t,
                    onBack: _confirmLeave,
                    bottomBar: !withSheet,
                    body: Column(
                      children: [
                        if (!s.connected)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(t.reconnecting,
                                style: AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                          ),
                        Expanded(child: _body(t, phase)),
                      ],
                    ),
                  ),
                  Positioned.fill(child: IgnorePointer(child: _WtConfetti(key: _confetti))),
                ],
              );
            },
          );
        },
      ),
    );
  }

  bool get _revealHasSheet => s.ready && s.phase == 'reveal' && s.score < s.target;

  Widget _body(WtText t, String phase) {
    switch (phase) {
      case 'lobby':
        return _lobby(t);
      case 'question':
        return _question(t);
      case 'reveal':
        return _reveal(t);
      case 'end':
        return _end(t);
      default:
        return const Center(
          child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: WtColors.pink)),
        );
    }
  }

  // ───────────────────────── Lobby ─────────────────────────

  Widget _lobby(WtText t) {
    final players = s.players;
    final enough = players.length >= 2;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _codeBox(t),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(t.playersLabel,
                          style: AppFonts.baloo(
                              fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.96)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
                      decoration: BoxDecoration(
                        color: WtColors.tint(WtColors.pink, 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('${players.length} / ${WtSession.maxPlayers}',
                          style: AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w800, color: WtColors.pink)),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                for (var i = 0; i < WtSession.maxPlayers; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  if (i < players.length) _playerChip(t, players[i]) else _emptyChip(t, i + 1),
                ],
              ],
            ),
          ),
        ),
        WtFootSheet(children: [
          if (!s.isHost)
            WtFootNote(t.waitingHostStart)
          else ...[
            if (!enough) WtFootNote(t.waitingPlayers),
            ChunkyButton(
              label: t.startGame,
              width: double.infinity,
              onTap: enough ? () => _hostAction(s.startGame) : null,
            ),
          ],
        ]),
      ],
    );
  }

  /// Figma "Code Box": pink 13% fill, 2px dashed pink edge, radius 24.
  Widget _codeBox(WtText t) {
    return WtDashedBorder(
      color: WtColors.tint(WtColors.pink, 0.5),
      width: 2,
      radius: 24,
      dash: 7,
      gap: 5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(color: WtColors.tint(WtColors.pink, 0.13), borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            Text(t.gameCode,
                style: AppFonts.baloo(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.88)),
            const SizedBox(height: 8),
            Text(s.code, style: AppFonts.baloo(fontSize: 40, fontWeight: FontWeight.w800, height: 1.1, color: AppColors.brandYellow)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Fx.tap();
                Clipboard.setData(ClipboardData(text: s.code));
                showWtToast(context, t.codeCopied);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Text(t.copyCode, style: AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Figma "Player Chip": surface, 1px border, radius 15, 14 × 11 padding.
  Widget _playerChip(WtText t, WtPlayer p) {
    final offline = s.isOffline(p.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          WtAvatar(id: p.id, initial: p.initial),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.id == s.myId ? '${p.name} ${t.you}' : p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                if (offline) _status(t.offline, WtColors.red),
              ],
            ),
          ),
          if (p.isHost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: WtColors.tint(AppColors.brandYellow, 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(t.hostTag,
                  style: AppFonts.baloo(
                      fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.brandYellow, letterSpacing: 0.4)),
            )
          else if (s.isHost && offline)
            _removeButton(p),
        ],
      ),
    );
  }

  /// Figma "Player Chip - Empty": dashed 1.5px border, numbered avatar.
  Widget _emptyChip(WtText t, int n) {
    return WtDashedBorder(
      color: AppColors.borderDefault,
      width: 1.5,
      radius: 15,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
              child: Text('$n', style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(t.waitingSlot,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _status(String text, Color color) => Text(
        text,
        style: AppFonts.baloo(fontSize: 10, fontWeight: FontWeight.w600, height: 12 / 10, color: color, letterSpacing: 0.2),
      );

  /// Figma "Remove": 22px red circle (12% fill) with a 12px red ✕.
  Widget _removeButton(WtPlayer p) {
    return Semantics(
      button: true,
      label: 'Remove ${p.name}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Fx.tap();
          _remove(p);
        },
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: WtColors.tint(WtColors.red, 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded, size: 12, color: WtColors.red),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Question ─────────────────────────

  Widget _question(WtText t) {
    final players = s.players;
    final answers = s.answers;
    final mine = s.myAnswer ?? _pendingPick;
    return Column(
      children: [
        WtScoreSection(t: t, score: s.score, target: s.target, remaining: max(0, s.qCount - s.qIndex)),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _questionCard(t),
                const SizedBox(height: 20),
                for (var i = 0; i < players.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _option(t, players[i], selected: mine == players[i].id, locked: mine != null, answered: answers[players[i].id] != null),
                ],
                if (mine != null) ...[
                  const SizedBox(height: 16),
                  Text(t.locked,
                      textAlign: TextAlign.center,
                      style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Figma "Q Card": pink 15% fill, 1px pink edge, radius 24, 22 × 24 padding.
  Widget _questionCard(WtText t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        color: WtColors.tint(WtColors.pink, 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: WtColors.tint(WtColors.pink, 0.5)),
      ),
      child: Column(
        children: [
          Text(t.questionNo(s.qIndex + 1),
              style: AppFonts.baloo(fontSize: 11, fontWeight: FontWeight.w800, color: WtColors.pink, letterSpacing: 1.76)),
          const SizedBox(height: 9),
          Text(
            WtQuestions.text(s.questionIndex, t.hi),
            textAlign: TextAlign.center,
            style: AppFonts.baloo(fontSize: 23, fontWeight: FontWeight.w700, height: 1.3),
          ),
        ],
      ),
    );
  }

  /// Figma "Opt": 66px, 7% white fill, 2px border, radius 17, 16px padding,
  /// 13px gaps — check ring · avatar · name (+ Answered / Offline) · remove.
  Widget _option(WtText t, WtPlayer p, {required bool selected, required bool locked, required bool answered}) {
    final offline = s.isOffline(p.id);
    final status = offline ? _status(t.offline, WtColors.red) : (answered ? _status(t.answered, WtColors.green) : null);
    return Semantics(
      button: !locked,
      selected: selected,
      label: p.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: locked ? null : () => _pick(p.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? WtColors.tint(AppColors.brandYellow, 0.14) : WtColors.optionFill,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: selected ? AppColors.brandYellow : AppColors.borderDefault, width: 2),
          ),
          child: Row(
            children: [
              _check(selected),
              const SizedBox(width: 13),
              WtAvatar(id: p.id, initial: p.initial, fontSize: 14),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.id == s.myId ? '${p.name} ${t.youLower}' : p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.baloo(fontSize: 17, fontWeight: FontWeight.w800, height: status == null ? null : 18 / 17),
                    ),
                    if (status != null) ...[const SizedBox(height: 2), status],
                  ],
                ),
              ),
              if (s.isHost && p.id != s.myId) _removeButton(p),
            ],
          ),
        ),
      ),
    );
  }

  /// 24px check: 2px 30%-white ring; selected = brand yellow with a ✓.
  Widget _check(bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.brandYellow : Colors.transparent,
        border: Border.all(color: selected ? AppColors.brandYellow : WtColors.checkRing, width: 2),
      ),
      child: selected ? const Icon(Icons.check_rounded, size: 16, color: AppColors.textOnLight) : null,
    );
  }

  // ───────────────────────── Reveal ─────────────────────────

  Widget _reveal(WtText t) {
    final result = s.roundResult;
    final players = s.players;
    final answers = s.answers;
    String nameOf(String id) => s.player(id)?.name ?? '—';

    final isLast = s.qIndex + 1 >= s.qCount;
    return Column(
      children: [
        WtScoreSection(t: t, score: s.score, target: s.target, remaining: max(0, s.qCount - s.qIndex - 1)),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (result != null) _banner(t, result, nameOf),
                const SizedBox(height: 20),
                for (var i = 0; i < players.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _voteRow(t, players[i], answers[players[i].id], nameOf),
                ],
              ],
            ),
          ),
        ),
        if (_revealHasSheet)
          WtFootSheet(children: [
            if (s.isHost)
              ChunkyButton(
                label: isLast ? t.seeResults : t.nextQuestion,
                width: double.infinity,
                onTap: () => _hostAction(s.nextQuestion),
              )
            else
              WtFootNote(t.waitHost),
          ]),
      ],
    );
  }

  /// Result banner: outcome colour at 16% fill, 2px edge at 55%, radius 22,
  /// 22px padding — emoji · title (ExtraBold 24) · line (Bold 14 muted).
  Widget _banner(WtText t, WtRoundResult r, String Function(String) nameOf) {
    final muted = AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMuted);
    late final Color color;
    late final String emoji;
    late final String title;
    late final Widget line;
    double emojiSize = 44;
    switch (r.outcome) {
      case WtOutcome.bullseye:
        color = WtColors.green;
        emoji = '🎯';
        emojiSize = 52;
        title = t.bullseye;
        line = Text.rich(
          TextSpan(children: [
            TextSpan(text: t.everyonePicked(nameOf(r.picked.first))),
            TextSpan(text: t.plusOne, style: muted.copyWith(color: WtColors.green)),
          ]),
          textAlign: TextAlign.center,
          style: muted,
        );
      case WtOutcome.crowdPick:
        color = WtColors.pink;
        emoji = '👑';
        title = t.crowdsPick;
        line = Text(t.crowdSub(nameOf(r.picked.first)), textAlign: TextAlign.center, style: muted);
      case WtOutcome.tie:
        color = AppColors.brandYellow;
        emoji = '🤝';
        title = t.tie;
        line = Text(t.tieSub(r.picked.map(nameOf).toList()), textAlign: TextAlign.center, style: muted);
    }
    final banner = Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: WtColors.tint(color, 0.16),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: WtColors.tint(color, 0.55), width: 2),
      ),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: emojiSize)),
          const SizedBox(height: 6),
          Text(title, textAlign: TextAlign.center, style: AppFonts.baloo(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          line,
        ],
      ),
    );
    if (r.outcome != WtOutcome.bullseye) return banner;
    // Figma "Confetti": five small rotated squares along the banner's top edge.
    Widget dot(double left, double top, double size, double deg, Color c) => Positioned(
          left: left,
          top: top,
          child: Transform.rotate(
            angle: deg * pi / 180,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(size / 4)),
            ),
          ),
        );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        banner,
        dot(10, -8, 8, -20, const Color(0xFFFBBF24)),
        dot(40, 4, 6, -45, const Color(0xFFEC4899)),
        dot(150, -11, 6, -10, const Color(0xFFFB923C)),
        dot(255, 14, 9, 30, const Color(0xFF4ADE80)),
        dot(281, -2, 7, 15, const Color(0xFF22D3EE)),
      ],
    );
  }

  /// Figma "Vote Row": surface, radius 14, 14 × 11 padding, 11px gaps.
  Widget _voteRow(WtText t, WtPlayer p, String? toId, String Function(String) nameOf) {
    final to = toId == null ? '—' : (toId == p.id ? '${nameOf(toId)} ${t.self}' : nameOf(toId));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          WtAvatar(id: p.id, initial: p.initial, size: 28, fontSize: 13),
          const SizedBox(width: 11),
          Flexible(
            child: Text(p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
          ),
          const SizedBox(width: 11),
          Text('→', style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
          const SizedBox(width: 11),
          Expanded(
            flex: 2,
            child: Text(to,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.brandYellow)),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── End ─────────────────────────

  Widget _end(WtText t) {
    final won = s.won;
    return LayoutBuilder(
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
                  Text(won ? '🎉' : '🙌', style: const TextStyle(fontSize: 76)),
                  const SizedBox(height: 8),
                  Text(
                    won ? t.winTitle : t.loseTitle,
                    textAlign: TextAlign.center,
                    style: AppFonts.baloo(
                        fontSize: 32, fontWeight: FontWeight.w800, color: won ? WtColors.green : AppColors.brandYellow),
                  ),
                  const SizedBox(height: 8),
                  Text(won ? t.winSub : t.loseSub,
                      textAlign: TextAlign.center,
                      style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                  const SizedBox(height: 36),
                  ChunkyButton(
                    label: t.playAgain,
                    width: double.infinity,
                    onTap: () {
                      if (s.isHost) {
                        _hostAction(s.playAgain);
                      } else {
                        showWtToast(context, t.onlyHostRestarts);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  WtGhostButton(label: t.backHome, onTap: _leave),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Confetti ─────────────────────────

/// Full-screen confetti burst for "Your Team Wins!" (same palette as web).
class _WtConfetti extends StatefulWidget {
  const _WtConfetti({super.key});

  @override
  State<_WtConfetti> createState() => _WtConfettiState();
}

class _WtConfettiState extends State<_WtConfetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  final _rng = Random();
  List<_Bit> _bits = const [];

  static const _colors = [
    Color(0xFF60A5FA), Color(0xFFFBBF24), Color(0xFF4ADE80), Color(0xFFF87171),
    Color(0xFFEC4899), Color(0xFF22D3EE), Colors.white,
  ];

  void fire() {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    _bits = List.generate(
      120,
      (_) => _Bit(
        x: _rng.nextDouble(),
        y: -_rng.nextDouble() * 0.6,
        w: 6 + _rng.nextDouble() * 7,
        h: 9 + _rng.nextDouble() * 9,
        color: _colors[_rng.nextInt(_colors.length)],
        vy: 0.55 + _rng.nextDouble() * 0.6,
        vx: -0.08 + _rng.nextDouble() * 0.16,
        rot: _rng.nextDouble() * pi * 2,
        vr: -6 + _rng.nextDouble() * 12,
      ),
    );
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        if (!_c.isAnimating) return const SizedBox.shrink();
        return CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_bits, _c.value * 2.6));
      },
    );
  }
}

class _Bit {
  final double x, y, w, h, vy, vx, rot, vr;
  final Color color;
  const _Bit({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.color,
    required this.vy,
    required this.vx,
    required this.rot,
    required this.vr,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Bit> bits;
  final double t; // seconds
  _ConfettiPainter(this.bits, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final fade = t > 2.1 ? max(0.0, (2.6 - t) / 0.5) : 1.0;
    final paint = Paint();
    for (final b in bits) {
      final x = (b.x + b.vx * t) * size.width;
      final y = (b.y + b.vy * t) * size.height;
      if (y < -20 || y > size.height + 20) continue;
      paint.color = b.color.withAlpha((fade * 255).round());
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(b.rot + b.vr * t);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: b.w, height: b.h), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => true;
}
