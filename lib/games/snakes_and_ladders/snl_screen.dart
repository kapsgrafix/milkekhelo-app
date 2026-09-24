import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_language.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/game_header.dart';
import '../../core/widgets/screen_bottom_bar.dart';
import 'snl_board.dart';
import 'snl_data.dart';
import 'snl_translations.dart';

enum _MsgKind { turn, rolled, snakeBite, ladderUp, reached100 }

/// Snakes & Ladders — full game screen. Everything this game needs (board,
/// dice, timer, turns, win/draw logic, how-to-play) lives in this one
/// module folder; nothing outside `games/snakes_and_ladders/` references
/// its internals.
class SnlScreen extends StatefulWidget {
  const SnlScreen({super.key});

  @override
  State<SnlScreen> createState() => _SnlScreenState();
}

class _SnlScreenState extends State<SnlScreen> with TickerProviderStateMixin {
  final _rng = Random();

  final Map<String, int> _pos = {'yellow': 0, 'red': 0};
  String _turn = 'yellow';
  bool _rolling = false;
  bool _busy = false;
  bool _gameOver = false;
  int _timeLeft = 120;
  Timer? _matchTimer;

  bool _showCountdown = true;
  int _countdownTick = 3;
  Timer? _countdownTimer;

  int? _diceValue; // null = not rolled yet (shows 🎲)
  Timer? _diceShuffleTimer;

  _MsgKind _msgKind = _MsgKind.turn;
  int _msgValue = 0;

  bool _showEndScreen = false;
  String? _winner; // 'yellow' | 'red' | null (draw)

  late final AnimationController _blinkCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final AnimationController _diceShakeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  bool get _urgent => _timeLeft <= 20;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _matchTimer?.cancel();
    _countdownTimer?.cancel();
    _diceShuffleTimer?.cancel();
    _blinkCtrl.dispose();
    _diceShakeCtrl.dispose();
    super.dispose();
  }

  // ---- Game lifecycle ----------------------------------------------------

  void _startGame() {
    _matchTimer?.cancel();
    _countdownTimer?.cancel();
    _diceShuffleTimer?.cancel();
    _blinkCtrl
      ..stop()
      ..reset();
    setState(() {
      _pos['yellow'] = 0;
      _pos['red'] = 0;
      _turn = 'yellow';
      _rolling = false;
      _busy = false;
      _gameOver = false;
      _timeLeft = 120;
      _showCountdown = true;
      _countdownTick = 3;
      _diceValue = null;
      _msgKind = _MsgKind.turn;
      _msgValue = 0;
      _showEndScreen = false;
      _winner = null;
    });
    _runCountdown();
  }

  void _runCountdown() {
    _countdownTick = 3;
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      final next = _countdownTick - 1;
      if (next <= 0) {
        timer.cancel();
        if (!mounted) return;
        setState(() => _showCountdown = false);
        _startMatchTimer();
      } else {
        if (!mounted) return;
        setState(() => _countdownTick = next);
      }
    });
  }

  void _startMatchTimer() {
    _matchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 20 && !_blinkCtrl.isAnimating) {
        _blinkCtrl.repeat(reverse: true);
      }
      if (_timeLeft <= 0) {
        timer.cancel();
        _endGame();
      }
    });
  }

  // ---- Dice + movement ----------------------------------------------------

  void _rollDice() {
    if (_rolling || _busy || _gameOver) return;
    setState(() {
      _rolling = true;
      _busy = true;
    });
    _diceShakeCtrl.repeat(reverse: true);
    int ticks = 0;
    _diceShuffleTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      ticks++;
      if (ticks >= 8) {
        timer.cancel();
        _diceShakeCtrl
          ..stop()
          ..reset();
        final value = _rng.nextInt(6) + 1;
        if (!mounted) return;
        setState(() {
          _diceValue = value;
          _rolling = false;
          _msgKind = _MsgKind.rolled;
          _msgValue = value;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          _moveGoti(value);
        });
      } else {
        if (!mounted) return;
        setState(() => _diceValue = _rng.nextInt(6) + 1);
      }
    });
  }

  Future<void> _moveGoti(int steps) async {
    final color = _turn;
    final start = _pos[color]!;
    final target = start + steps;

    if (target > 100) {
      // Overshoot: piece doesn't move, turn is simply wasted.
      _finishTurn();
      return;
    }

    int current = start;
    while (current < target) {
      current++;
      if (!mounted) return;
      setState(() => _pos[color] = current);
      if (current < target) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
      }
    }

    if (SnlData.snakes.containsKey(current)) {
      setState(() => _msgKind = _MsgKind.snakeBite);
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _pos[color] = SnlData.snakes[current]!);
      _finishTurn();
    } else if (SnlData.ladders.containsKey(current)) {
      setState(() => _msgKind = _MsgKind.ladderUp);
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _pos[color] = SnlData.ladders[current]!);
      _finishTurn();
    } else if (current == 100) {
      setState(() => _msgKind = _MsgKind.reached100);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _endGame(winner: color);
    } else {
      _finishTurn();
    }
  }

  void _finishTurn() {
    if (_gameOver || !mounted) return;
    setState(() {
      _turn = _turn == 'yellow' ? 'red' : 'yellow';
      _busy = false;
      _msgKind = _MsgKind.turn;
    });
  }

  Future<void> _endGame({String? winner}) async {
    if (_gameOver) return;
    _matchTimer?.cancel();
    _blinkCtrl.stop();
    String? finalWinner = winner;
    if (finalWinner == null) {
      final yp = _pos['yellow']! * 2;
      final rp = _pos['red']! * 2;
      if (yp > rp) {
        finalWinner = 'yellow';
      } else if (rp > yp) {
        finalWinner = 'red';
      }
    }
    setState(() {
      _gameOver = true;
      _winner = finalWinner;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _showEndScreen = true);
  }

  void _exit() => Navigator.of(context).pop();

  void _openHow(SnlText t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _HowToPlaySheet(t: t),
    );
  }

  // ---- Build ---------------------------------------------------------------
  //
  // Layout follows Figma "SnL Timed Game Table" (14:1337, 360×720):
  //   0    Header (Game Empty — back + help, no title, language toggle)  56
  //   56   Score Section (two player chips)                             71
  //   162  Timer "02:00" (stat/number, action/primary)                  34
  //   208  Board 340×340 (10px side margins)
  //        Status line + dice (not in the frame — sits in the free
  //        space between the board and the bottom bar)
  //   670  Bottom bar                                                   50

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final t = SnlText(lang);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: Color.alphaBlend(AppColors.surface, SnlData.screenBg),
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: SnlData.screenBg,
            body: Stack(
              children: [
                Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: GameHeader(title: '', onBack: _exit, onHelp: () => _openHow(t)),
                    ),
                    _buildScores(t),
                    Expanded(
                      child: _showCountdown ? _buildCountdown(t) : _buildPlayArea(t),
                    ),
                    const ScreenBottomBar(),
                  ],
                ),
                if (_showEndScreen) _buildEndScreen(t),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Figma "Score Section / 2 Player": 12px sides, 8px top/bottom, 12px gap.
  Widget _buildScores(SnlText t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _PlayerChip(
              name: t.yellow,
              pts: _pos['yellow']! * 2,
              ptsLabel: t.pts,
              swatch: SnlData.yellowSwatch,
              border: SnlData.yellowActiveBorder,
              active: _turn == 'yellow',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PlayerChip(
              name: t.red,
              pts: _pos['red']! * 2,
              ptsLabel: t.pts,
              swatch: SnlData.redSwatch,
              border: SnlData.redActiveBorder,
              active: _turn == 'red',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown(SnlText t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.getReadyIn,
            style: AppFonts.baloo(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white54),
          ),
          const SizedBox(height: 2),
          TweenAnimationBuilder<double>(
            key: ValueKey(_countdownTick),
            tween: Tween(begin: 0.6, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: Text(
              '$_countdownTick',
              style: AppFonts.baloo(fontSize: 104, fontWeight: FontWeight.w800, height: 1.0, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayArea(SnlText t) {
    final minutes = _timeLeft ~/ 60;
    final seconds = _timeLeft % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return LayoutBuilder(
      builder: (context, constraints) {
        // Timer (32 × 1.05) + 12 gap + status (18) + 10 gap + dice (64 + 5).
        const fixed = 33.6 + 12 + 18 + 10 + 69;
        final maxByHeight = constraints.maxHeight - fixed - 24;
        final boardSize = (constraints.maxWidth - 20).clamp(160.0, maxByHeight < 160 ? 160.0 : maxByHeight).toDouble();
        return Column(
          children: [
            const Spacer(flex: 35),
            AnimatedBuilder(
              animation: _blinkCtrl,
              builder: (context, child) {
                final opacity = _urgent ? (1 - _blinkCtrl.value * 0.6) : 1.0;
                return Opacity(
                  opacity: opacity,
                  child: Text(
                    timeStr,
                    style: AppText.statNumber(color: _urgent ? const Color(0xFFF87171) : AppColors.actionPrimary),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox.square(
              dimension: boardSize,
              child: SnlBoard(yellowPos: _pos['yellow']!, redPos: _pos['red']!),
            ),
            const Spacer(flex: 12),
            SizedBox(
              height: 18,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _statusText(t),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.3, color: const Color(0xBFFFFFFF)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildDice(),
            const Spacer(flex: 13),
          ],
        );
      },
    );
  }

  String _statusText(SnlText t) {
    final name = _turn == 'yellow' ? t.yellow : t.red;
    switch (_msgKind) {
      case _MsgKind.turn:
        return t.turnMsg(name);
      case _MsgKind.rolled:
        return t.rolled(name, _msgValue);
      case _MsgKind.snakeBite:
        return t.snakeBite;
      case _MsgKind.ladderUp:
        return t.ladderUp;
      case _MsgKind.reached100:
        return t.reached100(name);
    }
  }

  Widget _buildDice() {
    final colors = _gameOver
        ? SnlData.diceIdle
        : (_turn == 'yellow' ? SnlData.diceYellow : SnlData.diceRed);
    final shadowColor = _gameOver
        ? const Color(0xFFA3A3A3)
        : (_turn == 'yellow' ? const Color(0xFFB45309) : const Color(0xFF991B1B));

    return AnimatedBuilder(
      animation: _diceShakeCtrl,
      builder: (context, child) {
        final angle = _rolling ? (sin(_diceShakeCtrl.value * pi * 2) * 0.2) : 0.0;
        final scale = _rolling ? 1 + _diceShakeCtrl.value * 0.06 : 1.0;
        return Transform.rotate(
          angle: angle,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Semantics(
        button: true,
        label: _diceValue == null ? 'Roll dice' : 'Dice shows $_diceValue',
        child: GestureDetector(
          onTap: _gameOver ? null : _rollDice,
          child: Opacity(
            opacity: _gameOver ? 0.5 : 1,
            child: Container(
              width: 64,
              height: 64,
              margin: const EdgeInsets.only(bottom: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                boxShadow: [BoxShadow(color: shadowColor, offset: const Offset(0, 5))],
              ),
              child: _diceValue == null
                  ? const Text('🎲', style: TextStyle(fontSize: 34))
                  : SnlDiceFace(value: _diceValue!, size: 44),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEndScreen(SnlText t) {
    final yp = _pos['yellow']! * 2;
    final rp = _pos['red']! * 2;
    final isDraw = _winner == null;
    final winnerName = _winner == 'yellow' ? t.yellow : (_winner == 'red' ? t.red : null);
    final titleColor = isDraw
        ? const Color(0xFFA3A3A3)
        : (_winner == 'yellow' ? SnlData.yellowSwatch : SnlData.redSwatch);

    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 400),
        builder: (context, v, child) => Opacity(
          opacity: v,
          child: Transform.scale(scale: 0.95 + 0.05 * v, child: child),
        ),
        child: Container(
          color: SnlData.endOverlayBg,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isDraw ? '🤝' : '🏆', style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 12),
              Text(
                isDraw ? t.draw : t.wins(winnerName!),
                style: AppFonts.baloo(fontSize: 30, fontWeight: FontWeight.w800, color: titleColor),
              ),
              const SizedBox(height: 8),
              Text(
                t.endSub(yp, rp),
                style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 220,
                child: ChunkyButton(label: t.playAgain, onTap: _startGame),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _exit,
                child: Text(
                  t.backToHome,
                  style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Figma "Score Section" player chip: background/surface fill, 2px border
/// in the player's colour, radius 16, 16/10 padding, 32px avatar, 12px gap.
/// Name Bold 12/13 · score Bold 18/20 + "pts" Medium 11/12 (text/muted).
/// The player whose turn it isn't is shown at 70% opacity.
class _PlayerChip extends StatelessWidget {
  final String name;
  final int pts;
  final String ptsLabel;
  final Color swatch;
  final Color border;
  final bool active;

  const _PlayerChip({
    required this.name,
    required this.pts,
    required this.ptsLabel,
    required this.swatch,
    required this.border,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1 : 0.7,
      duration: const Duration(milliseconds: 250),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: swatch,
                border: Border.all(color: const Color(0xD9FFFFFF), width: 3),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w700, height: 13 / 12)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('$pts', style: AppFonts.baloo(fontSize: 18, fontWeight: FontWeight.w700, height: 20 / 18)),
                      const SizedBox(width: 4),
                      Text(ptsLabel,
                          style: AppFonts.baloo(fontSize: 11, fontWeight: FontWeight.w500, height: 12 / 11, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowToPlaySheet extends StatelessWidget {
  final SnlText t;
  const _HowToPlaySheet({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1040), Color(0xFF0D2040)],
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
            Text(t.howTitle, style: AppFonts.baloo(fontSize: 22, fontWeight: FontWeight.w800, color: SnlData.howAccent)),
            const SizedBox(height: 20),
            for (int i = 0; i < t.steps.length; i++) ...[
              _Step(number: i + 1, title: t.steps[i][0], desc: t.steps[i][1]),
              if (i != t.steps.length - 1) const SizedBox(height: 16),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x1A3B82F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x403B82F6)),
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
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String title;
  final String desc;
  const _Step({required this.number, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1E4FA0)]),
          ),
          child: Text('$number', style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(desc, style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white60)),
            ],
          ),
        ),
      ],
    );
  }
}
