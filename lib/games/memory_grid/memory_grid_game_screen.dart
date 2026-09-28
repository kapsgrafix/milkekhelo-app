import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/feedback/fx.dart';
import '../../core/localization/app_language.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/game_header.dart';
import '../../core/widgets/player_score_chip.dart';
import '../../core/widgets/screen_bottom_bar.dart';
import 'memory_grid_home_screen.dart' show MgHowToPlaySheet;
import 'mg_confetti.dart';
import 'mg_data.dart';
import 'mg_translations.dart';

enum _Phase { showing, play, resolving, over, idle }

enum _StatusKind { memorise, tapProgress, outLives, lifeLeft, livesLeft, turn, hereThey }

/// Memory Grid gameplay: handles BOTH solo (pass a [level]) and duel (leave
/// [level] null) since the two modes share almost all of their mechanics
/// (grid, reveal, tap handling, hint, confetti) — splitting them into two
/// screens would have meant duplicating that shared logic. Still entirely
/// self-contained within games/memory_grid/.
class MemoryGridGameScreen extends StatefulWidget {
  /// 'easy' | 'medium' | 'hard' for solo, or null for a 2-player duel.
  final String? level;
  const MemoryGridGameScreen({super.key, this.level});

  @override
  State<MemoryGridGameScreen> createState() => _MemoryGridGameScreenState();
}

class _MemoryGridGameScreenState extends State<MemoryGridGameScreen> {
  final _rng = Random();
  final _confettiKey = GlobalKey<MgConfettiState>();

  bool get _isDuel => widget.level == null;

  late int _gridSize;
  late int _dotCount;

  List<int> _target = [];
  final List<int> _found = [];
  int? _wrongIndex;
  final Set<int> _hintRevealed = {};

  _Phase _phase = _Phase.idle;
  _StatusKind _statusKind = _StatusKind.memorise;
  int _statusA = 0;
  int _statusB = 0;

  // Solo state.
  int _streak = 0;
  int _lives = MgData.maxLives;
  int _hints = MgData.maxHints;
  bool _firstEasyRound = false;
  int _best = 0;

  // Duel state.
  final List<int> _duelScores = [0, 0];
  int _current = 0;
  int _activePlayer = -1;

  bool _showCountdown = true;
  int _countdownTick = 3;
  Timer? _countdownTimer;

  bool _showGameOver = false;
  String? _flashText;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _loadBest();
    if (_isDuel) {
      _gridSize = MgData.duelSize;
      _dotCount = MgData.duelDots;
    } else {
      final lv = MgData.levels[widget.level]!;
      _gridSize = lv.size;
      _dotCount = lv.dots;
      _firstEasyRound = widget.level == 'easy';
    }
    _runCountdown(() {
      if (_isDuel) {
        _duelStartRound();
      } else {
        _soloNewRound();
      }
    });
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt('mg-best') ?? 0;
    if (mounted) setState(() => _best = v);
  }

  Future<void> _saveBest(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('mg-best', v);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  // ---- Countdown -----------------------------------------------------------

  void _runCountdown(VoidCallback onDone) {
    _showCountdown = true;
    _countdownTick = 3;
    Fx.countdown();
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      final next = _countdownTick - 1;
      if (next <= 0) {
        timer.cancel();
        if (!mounted) return;
        Fx.goSignal();
        setState(() => _showCountdown = false);
        onDone();
      } else {
        if (!mounted) return;
        Fx.countdown();
        setState(() => _countdownTick = next);
      }
    });
  }

  List<int> _pickTarget() {
    final total = _gridSize * _gridSize;
    final all = List<int>.generate(total, (i) => i)..shuffle(_rng);
    final picked = all.take(_dotCount).toList()..sort();
    return picked;
  }

  // ---- Solo ------------------------------------------------------------------

  void _soloNewRound() {
    setState(() {
      _found.clear();
      _hintRevealed.clear();
      _wrongIndex = null;
      _target = _pickTarget();
      _phase = _Phase.showing;
      _statusKind = _StatusKind.memorise;
    });
    final baseMs = MgData.revealMs[widget.level]!;
    final revealMs = _firstEasyRound ? baseMs * 2 : baseMs;
    _firstEasyRound = false;
    Future.delayed(Duration(milliseconds: revealMs), () {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.play;
        _statusKind = _StatusKind.tapProgress;
        _statusA = 0;
        _statusB = _target.length;
      });
    });
  }

  void _soloTap(int i) {
    if (_phase != _Phase.play || _found.contains(i)) return;
    if (_target.contains(i)) {
      Fx.correct();
      setState(() {
        _found.add(i);
        _statusA = _found.length;
      });
      if (_found.length == _target.length) {
        _soloRoundWon();
      }
    } else {
      Fx.wrong();
      setState(() => _wrongIndex = i);
      _soloLoseLife();
    }
  }

  void _soloRoundWon() {
    setState(() {
      _phase = _Phase.idle;
      _streak++;
    });
    if (_streak > _best) {
      setState(() => _best = _streak);
      _saveBest(_streak);
    }
    _confettiKey.currentState?.fire();
    Fx.roundWin();
    _flash(MgText(AppLanguage.instance.value).praise[_rng.nextInt(6)]);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _soloNewRound();
    });
  }

  void _soloLoseLife() {
    setState(() => _lives--);
    if (_lives <= 0) {
      setState(() {
        _phase = _Phase.over;
        _hintRevealed.addAll(_target.where((i) => !_found.contains(i)));
        _statusKind = _StatusKind.outLives;
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        Fx.lose();
        setState(() => _showGameOver = true);
      });
    } else {
      setState(() {
        _statusKind = _lives == 1 ? _StatusKind.lifeLeft : _StatusKind.livesLeft;
        _statusA = _lives;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _wrongIndex = null;
          _statusKind = _StatusKind.tapProgress;
          _statusA = _found.length;
          _statusB = _target.length;
        });
      });
    }
  }

  void _soloHint() {
    if (_hints <= 0 || _phase != _Phase.play) return;
    Fx.hint();
    setState(() {
      _hints--;
      _hintRevealed.addAll(_target.where((i) => !_found.contains(i)));
    });
    Future.delayed(Duration(milliseconds: MgData.duelHintMs), () {
      if (!mounted) return;
      setState(() => _hintRevealed.clear());
    });
  }

  // ---- Duel ------------------------------------------------------------------

  void _duelStartRound() {
    setState(() {
      _found.clear();
      _hintRevealed.clear();
      _wrongIndex = null;
      _target = _pickTarget();
      _phase = _Phase.showing;
      _activePlayer = -1;
      _statusKind = _StatusKind.memorise;
    });
    Future.delayed(Duration(milliseconds: MgData.duelShowMs), () {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.play;
        _current = 0;
        _activePlayer = 0;
        _statusKind = _StatusKind.turn;
      });
    });
  }

  void _duelTap(int i) {
    if (_phase != _Phase.play || _found.contains(i)) return;
    setState(() => _phase = _Phase.resolving);
    if (_target.contains(i)) {
      Fx.correct();
      setState(() {
        _found.add(i);
        _duelScores[_current]++;
      });
      if (_found.length == _target.length) {
        Future.delayed(const Duration(milliseconds: 700), _duelEnd);
      } else {
        Future.delayed(const Duration(milliseconds: 650), _switchTurn);
      }
    } else {
      Fx.wrong();
      setState(() => _wrongIndex = i);
      Future.delayed(const Duration(milliseconds: 650), () {
        if (!mounted) return;
        setState(() => _wrongIndex = null);
        _switchTurn();
      });
    }
  }

  void _switchTurn() {
    if (!mounted) return;
    Fx.turn();
    setState(() {
      _current = 1 - _current;
      _phase = _Phase.play;
      _activePlayer = _current;
      _statusKind = _StatusKind.turn;
    });
  }

  void _duelHint() {
    if (_phase != _Phase.play) return;
    Fx.hint();
    final savedCurrent = _current;
    setState(() {
      _hintRevealed.addAll(_target.where((i) => !_found.contains(i)));
      _statusKind = _StatusKind.hereThey;
      _phase = _Phase.resolving; // block taps while hint is showing
    });
    Future.delayed(Duration(milliseconds: MgData.duelHintMs), () {
      if (!mounted) return;
      setState(() {
        _hintRevealed.clear();
        _current = savedCurrent;
        _activePlayer = savedCurrent;
        _phase = _Phase.play;
        _statusKind = _StatusKind.turn;
      });
    });
  }

  void _duelEnd() {
    if (!mounted) return;
    setState(() => _phase = _Phase.over);
    _confettiKey.currentState?.fire();
    Fx.win();
    setState(() => _showGameOver = true);
  }

  void _flash(String text) {
    _flashTimer?.cancel();
    setState(() => _flashText = text);
    _flashTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _flashText = null);
    });
  }

  void _playAgain() {
    setState(() {
      _showGameOver = false;
      _streak = 0;
      _lives = MgData.maxLives;
      _hints = MgData.maxHints;
      _duelScores[0] = 0;
      _duelScores[1] = 0;
      _found.clear();
      _hintRevealed.clear();
      _wrongIndex = null;
      if (!_isDuel) _firstEasyRound = widget.level == 'easy';
    });
    _runCountdown(() {
      if (_isDuel) {
        _duelStartRound();
      } else {
        _soloNewRound();
      }
    });
  }

  void _quitToHome() => Navigator.of(context).pop();

  void _openHow(MgText t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MgHowToPlaySheet(t: t, isDuel: _isDuel),
    );
  }

  // ---- Build -------------------------------------------------------------
  //
  // Figma "Memory Grid L2" (solo, 8:268) / "Memory Grid L3" (duel, 12:900):
  //   0    Header (Game Empty)                                          56
  //   56   Score Section — solo: Streak · Lives / duel: Yellow · Red    67–71
  //        Grid: 340 wide (10px margins), 8px gaps, radius-12 tiles,
  //        centred in the space above the status line
  //   584  Status line (label/card 16) — muted in solo, player colour in duel
  //        Hint pill (kept by request; not in the frames)
  //   670  Bottom bar                                                   50

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final t = MgText(lang);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: Color.alphaBlend(AppColors.surface, MgData.screenBg),
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: MgData.screenBg,
            body: Stack(
              children: [
                Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: GameHeader(title: '', onBack: _quitToHome, onHelp: () => _openHow(t)),
                    ),
                    _buildStatusBar(t),
                    Expanded(
                      child: _showCountdown ? _buildCountdown(t) : _buildPlayArea(t),
                    ),
                    const ScreenBottomBar(),
                  ],
                ),
                Positioned.fill(child: MgConfetti(key: _confettiKey, duration: const Duration(milliseconds: 1600))),
                if (_flashText != null) _buildFlash(),
                if (_showGameOver) _buildGameOver(t),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBar(MgText t) {
    if (_isDuel) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: PlayerScoreChip(
                name: t.p1,
                score: _duelScores[0],
                unit: t.pts,
                swatch: PlayerColors.yellowSwatch,
                border: PlayerColors.yellowBorder,
                active: _activePlayer != 1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PlayerScoreChip(
                name: t.p2,
                score: _duelScores[1],
                unit: t.pts,
                swatch: PlayerColors.redSwatch,
                border: PlayerColors.redBorder,
                active: _activePlayer == 1,
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _statBox(value: Text('$_streak', style: _statNumber), label: t.streak)),
          const SizedBox(width: 12),
          Expanded(
            child: _statBox(
              value: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('$_lives', style: _statNumber),
                ],
              ),
              label: t.lives,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _statNumber => AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w800, height: 17 / 15);

  /// Figma solo Score Section box: surface fill, 2px border/default, radius
  /// 16, 16/10 padding; number ExtraBold 15/17 over label SemiBold 11/12,
  /// muted, +0.66 tracking, uppercase.
  Widget _statBox({required Widget value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          value,
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: AppFonts.baloo(fontSize: 11, fontWeight: FontWeight.w600, height: 12 / 11, letterSpacing: 0.66, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown(MgText t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.memorizeIn, style: AppFonts.baloo(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white54)),
          const SizedBox(height: 2),
          TweenAnimationBuilder<double>(
            key: ValueKey(_countdownTick),
            tween: Tween(begin: 0.6, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: Text('$_countdownTick',
                style: AppFonts.baloo(fontSize: 104, fontWeight: FontWeight.w800, height: 1.0, color: MgData.titleAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayArea(MgText t) {
    return LayoutBuilder(
      builder: (context, c) {
        // Status (16 × 1.25) + 12 + hint pill (36) + bottom breathing room.
        const below = 20.0 + 12 + 36 + 20;
        final gridSide = (c.maxWidth - 20).clamp(160.0, (c.maxHeight - below - 36).clamp(160.0, 2000.0)).toDouble();
        const gap = 8.0;
        final tile = (gridSide - gap * (_gridSize - 1)) / _gridSize;
        return Column(
          children: [
            const Spacer(),
            SizedBox.square(
              dimension: gridSide,
              child: Column(
                children: [
                  for (int r = 0; r < _gridSize; r++) ...[
                    if (r > 0) const SizedBox(height: gap),
                    Row(
                      children: [
                        for (int col = 0; col < _gridSize; col++) ...[
                          if (col > 0) const SizedBox(width: gap),
                          SizedBox.square(dimension: tile, child: _buildTile(r * _gridSize + col, tile)),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              height: 20,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _statusText(t),
                  textAlign: TextAlign.center,
                  style: AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w800, height: 1.25, color: _statusColor()),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildHintButton(t),
            const Spacer(),
          ],
        );
      },
    );
  }

  /// Figma tile: radius 12. Empty = slot-empty (35% black); lit / found =
  /// module/green; wrong tap = module/coral. Found tiles show their order
  /// (stat/number, text/on-light), scaled to the tile size.
  Widget _buildTile(int i, double size) {
    final isFound = _found.contains(i);
    final isWrong = _wrongIndex == i;
    final isHint = _hintRevealed.contains(i) && !isFound;
    final isLit = _phase == _Phase.showing && _target.contains(i);

    Color color = MgData.tileEmpty;
    Widget? label;
    if (isWrong) {
      color = MgData.tileWrong;
    } else if (isFound) {
      color = MgData.tileLit;
      label = FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${_found.indexOf(i) + 1}',
          style: AppFonts.baloo(fontSize: 32 * size / 108, fontWeight: FontWeight.w800, height: 1.05, color: MgData.tileNumber),
        ),
      );
    } else if (isLit) {
      color = MgData.tileLit;
    } else if (isHint) {
      color = MgData.tileLit.withAlpha(150);
    }

    final locked = _phase != _Phase.play;
    return GestureDetector(
      onTap: locked ? null : () => _isDuel ? _duelTap(i) : _soloTap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12 * (size / 108).clamp(0.6, 1.0))),
        child: label,
      ),
    );
  }

  /// Hint pill (kept from the original game; styled with the design-system
  /// surface/border tokens). Solo shows remaining hints; duel is unlimited.
  Widget _buildHintButton(MgText t) {
    final showCount = !_isDuel;
    final enabled = _isDuel ? _phase == _Phase.play : (_hints > 0 && _phase == _Phase.play);
    return Semantics(
      button: true,
      enabled: enabled,
      label: t.hint,
      child: GestureDetector(
        onTap: enabled ? (_isDuel ? _duelHint : _soloHint) : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.4,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lightbulb_rounded, size: 16, color: AppColors.brandYellow),
                const SizedBox(width: 6),
                Text(t.hint, style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w700)),
                if (showCount) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.brandYellow, borderRadius: BorderRadius.circular(999)),
                    child: Text('$_hints', style: AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textOnLight)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusText(MgText t) {
    switch (_statusKind) {
      case _StatusKind.memorise:
        return t.memorise;
      case _StatusKind.tapProgress:
        return t.tap(_statusA, _statusB);
      case _StatusKind.outLives:
        return t.outLives;
      case _StatusKind.lifeLeft:
        return t.lifeLeft;
      case _StatusKind.livesLeft:
        return t.livesLeft(_statusA);
      case _StatusKind.turn:
        return _current == 0 ? t.p1turn : t.p2turn;
      case _StatusKind.hereThey:
        return t.hereThey;
    }
  }

  Color _statusColor() {
    switch (_statusKind) {
      case _StatusKind.memorise:
      case _StatusKind.hereThey:
        return MgData.titleAccent;
      case _StatusKind.turn:
        return _current == 0 ? PlayerColors.yellowBorder : PlayerColors.redBorder;
      case _StatusKind.outLives:
      case _StatusKind.lifeLeft:
        return MgData.tileWrong;
      default:
        return AppColors.textMuted;
    }
  }

  Widget _buildFlash() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            key: ValueKey(_flashText),
            tween: Tween(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 350),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            // White fill on top of a thick dark-green outline (a Text with a
            // stroke `foreground` paints ONLY the outline, so the two are
            // stacked), plus a soft drop shadow so it reads over the grid.
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  _flashText ?? '',
                  textAlign: TextAlign.center,
                  style: AppFonts.baloo(fontSize: 44, fontWeight: FontWeight.w800).copyWith(
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 7
                      ..strokeJoin = StrokeJoin.round
                      ..color = const Color(0xFF0A3D20),
                    shadows: const [Shadow(color: Color(0x99000000), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                ),
                Text(
                  _flashText ?? '',
                  textAlign: TextAlign.center,
                  style: AppFonts.baloo(fontSize: 44, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver(MgText t) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xF20A2A1B),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_isDuel ? (_duelScores[0] == _duelScores[1] ? '🤝' : '🏆') : '🧠', style: const TextStyle(fontSize: 70)),
                const SizedBox(height: 12),
                Text(
                  _isDuel
                      ? (_duelScores[0] == _duelScores[1] ? t.tie : t.wins(_duelScores[0] > _duelScores[1] ? 1 : 2))
                      : t.gameOver,
                  style: AppFonts.baloo(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  _isDuel
                      ? (_duelScores[0] == _duelScores[1] ? t.tieSub : t.winSub)
                      : (_streak == 0 ? t.betterLuck : t.reachedStreak(_streak)),
                  style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFBABABA)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (_isDuel)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _finalScoreBox(t.p1, _duelScores[0], _duelScores[0] >= _duelScores[1] && _duelScores[0] != _duelScores[1]),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('vs', style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white38)),
                      ),
                      _finalScoreBox(t.p2, _duelScores[1], _duelScores[1] > _duelScores[0]),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        Text('$_streak', style: AppFonts.baloo(fontSize: 54, fontWeight: FontWeight.w800, color: MgData.gold)),
                        Text(t.finalStreak.toUpperCase(), style: AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white70)),
                        if (_best > 0) ...[
                          const SizedBox(height: 6),
                          Text(t.bestStreak(_best), style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white54)),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 26),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: ChunkyButton(label: t.playAgain, onTap: _playAgain),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Fx.tap();
                    _quitToHome();
                  },
                  child: Text(t.backHome, style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _finalScoreBox(String name, int value, bool winner) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: winner ? MgData.gold.withOpacity(0.15) : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: winner ? MgData.gold : Colors.transparent, width: 2),
      ),
      child: Column(
        children: [
          Text(name, style: AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
          const SizedBox(height: 4),
          Text('$value', style: AppFonts.baloo(fontSize: 26, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
