import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/app_language.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/game_header.dart';
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
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      final next = _countdownTick - 1;
      if (next <= 0) {
        timer.cancel();
        if (!mounted) return;
        setState(() => _showCountdown = false);
        onDone();
      } else {
        if (!mounted) return;
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
      setState(() {
        _found.add(i);
        _statusA = _found.length;
      });
      if (_found.length == _target.length) {
        _soloRoundWon();
      }
    } else {
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
    setState(() {
      _current = 1 - _current;
      _phase = _Phase.play;
      _activePlayer = _current;
      _statusKind = _StatusKind.turn;
    });
  }

  void _duelHint() {
    if (_phase != _Phase.play) return;
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final t = MgText(lang);
        return Scaffold(
          backgroundColor: MgData.screenBg,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    GameHeader(title: '', onBack: _quitToHome, onHelp: () => _openHow(t)),
                    _buildStatusBar(t),
                    Expanded(
                      child: _showCountdown ? _buildCountdown(t) : _buildPlayArea(t),
                    ),
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
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: Row(
          children: [
            Expanded(child: _pscore(t.p1, _duelScores[0], _activePlayer == 0, MgData.dotLit)),
            const SizedBox(width: 10),
            Expanded(child: _pscore(t.p2, _duelScores[1], _activePlayer == 1, MgData.gold)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statCard(children: [
            Text('$_streak', style: AppFonts.baloo(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Text(t.streak, style: AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white60)),
          ]),
          _statCard(children: [
            for (int i = 0; i < MgData.maxLives; i++)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Opacity(
                  opacity: i < _lives ? 1 : 0.25,
                  child: Text('❤️', style: TextStyle(fontSize: i < _lives ? 18 : 15)),
                ),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _statCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _pscore(String name, int value, bool active, Color activeColor) {
    return AnimatedOpacity(
      opacity: active ? 1 : 0.55,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? activeColor : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Text(name, style: AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w700)),
            Text('$value', style: AppFonts.baloo(fontSize: 20, fontWeight: FontWeight.w800)),
          ],
        ),
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
            child: Text('$_countdownTick', style: AppFonts.baloo(fontSize: 104, fontWeight: FontWeight.w800, color: MgData.accent2)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayArea(MgText t) {
    return Column(
      children: [
        if (!_isDuel) ...[
          const SizedBox(height: 4),
          Text(
            t.mode(widget.level!),
            style: AppFonts.baloo(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white38, letterSpacing: 1.5),
          ),
        ],
        const SizedBox(height: 10),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.count(
                  crossAxisCount: _gridSize,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: List.generate(_gridSize * _gridSize, (i) => _buildDot(i)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _statusText(t),
          textAlign: TextAlign.center,
          style: AppFonts.baloo(fontSize: 22, fontWeight: FontWeight.w800, color: _statusColor()),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _buildHintButton(t),
        ),
      ],
    );
  }

  Widget _buildDot(int i) {
    final isFound = _found.contains(i);
    final isWrong = _wrongIndex == i;
    final isLitFromReveal = (_phase == _Phase.showing && _target.contains(i)) || _hintRevealed.contains(i);

    Color color = MgData.dotIdle;
    Widget? overlay;
    if (isWrong) {
      color = MgData.red;
    } else if (isFound) {
      color = MgData.green;
      overlay = Text(
        '${_found.indexOf(i) + 1}',
        style: AppFonts.baloo(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF052E16)),
      );
    } else if (isLitFromReveal) {
      color = MgData.dotLit;
    }

    final locked = _phase != _Phase.play;

    return GestureDetector(
      onTap: locked ? null : () => _isDuel ? _duelTap(i) : _soloTap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: (isLitFromReveal || isFound)
              ? [BoxShadow(color: MgData.dotLit.withOpacity(0.5), blurRadius: 14)]
              : (isWrong ? [BoxShadow(color: MgData.red.withOpacity(0.6), blurRadius: 14)] : null),
        ),
        alignment: Alignment.center,
        child: overlay,
      ),
    );
  }

  Widget _buildHintButton(MgText t) {
    final showCount = !_isDuel;
    final enabled = _isDuel ? _phase == _Phase.play : (_hints > 0 && _phase == _Phase.play);
    return GestureDetector(
      onTap: enabled ? (_isDuel ? _duelHint : _soloHint) : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: MgData.gold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: MgData.gold.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(t.hint, style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w700, color: MgData.gold)),
              if (showCount) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: MgData.gold, borderRadius: BorderRadius.circular(50)),
                  child: Text('$_hints', style: AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF3B2503))),
                ),
              ],
            ],
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
        return MgData.accent2;
      case _StatusKind.turn:
        return _current == 0 ? MgData.dotLit : MgData.gold;
      default:
        return Colors.white.withOpacity(0.9);
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
            child: Text(
              _flashText ?? '',
              style: AppFonts.baloo(fontSize: 44, fontWeight: FontWeight.w800).copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2
                  ..color = const Color(0xFF0A3D20),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver(MgText t) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xF21A0B2E),
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
                GestureDetector(
                  onTap: _playAgain,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 340),
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFE08A), Color(0xFFC97F00)],
                      ),
                      boxShadow: const [BoxShadow(color: Color(0xFF7A4B00), offset: Offset(0, 4))],
                    ),
                    child: Text(t.playAgain, style: AppFonts.baloo(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1B2340))),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _quitToHome,
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
