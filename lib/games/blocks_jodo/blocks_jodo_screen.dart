import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/save_progress/save_progress_nudge.dart';
import '../../core/saves/game_saves.dart';
import '../../core/feedback/fx.dart';
import '../../core/localization/app_language.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/lives_hearts.dart';
import '../../core/widgets/new_best_banner.dart';
import '../../core/widgets/game_header.dart';
import '../../core/widgets/screen_bottom_bar.dart';
import 'bj_data.dart';
import 'bj_engine.dart';
import 'bj_painters.dart';
import 'bj_translations.dart';

/// Blocks Jodo — a Block Blast-style puzzle. Figma "Blocks Jodo L2"
/// (252:1195, 360×720):
///   0    Header (Game Empty)                                        56
///   56   Score Section — Score · Lives (8/12 padding, 12 gap)       67
///   147  Board 340×340: slot-empty fill, 2px white-40% border, r5,
///        3px padding, 8×8 slots (39.5, gap 2, r4, white-8%)
///        Tray: three pieces at 20px cells / 1px gap, centred in thirds
///   670  Bottom bar                                                 50
///
/// Play: drag a piece from the tray onto the board. Rows (and columns)
/// that the drop would complete glow; on release they blast away with a
/// flash, shards, a beam and a score pop. Back-to-back clears build a
/// combo. When no piece fits you lose a life and the board is rescued;
/// lose all three and it's game over.
class BlocksJodoScreen extends StatefulWidget {
  const BlocksJodoScreen({super.key});

  @override
  State<BlocksJodoScreen> createState() => _BlocksJodoScreenState();
}

class _BlocksJodoScreenState extends State<BlocksJodoScreen> with TickerProviderStateMixin {
  // ---- Game state -----------------------------------------------------------
  final BjBoard _board = BjBoard();
  final BjDealer _dealer = BjDealer();
  final Random _rng = Random();
  List<BjPiece?> _tray = [null, null, null];
  int _score = 0;
  int _best = 0;
  int _lives = BjData.maxLives;
  int _combo = 0;
  int _movesSinceClear = 0;
  bool _bestAnnounced = false;
  bool _showNewBest = false; // glossy "New Best Score!" over the board
  int _newBestKey = 0;
  bool _newBest = false;
  bool _busy = false; // a life is being lost / board rescued
  bool _gameOver = false;
  bool _showGameOver = false;
  final List<Timer> _timers = [];

  // ---- Effects --------------------------------------------------------------
  final Stopwatch _clock = Stopwatch()..start();
  double _now() => _clock.elapsedMicroseconds / 1e6;
  late final BjBoardScene _scene = BjBoardScene(_board, _now);
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;
  double? _shakeStart;
  double _shakeAmp = 0;
  final List<BjParticle> _confetti = [];

  String? _banner;
  String? _bannerSub;
  Color _bannerEdge = const Color(0xFF7A3A00);
  int _bannerKey = 0;

  // ---- Drag -----------------------------------------------------------------
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _boardKey = GlobalKey();
  final List<GlobalKey> _slotKeys = List.generate(3, (_) => GlobalKey());
  int? _dragSlot;
  int? _pointer;
  Offset _finger = Offset.zero; // in stack coordinates
  bool _returning = false;
  Offset _retFrom = Offset.zero;
  Offset _retTo = Offset.zero;
  int? _hoverRow;
  int? _hoverCol;
  late final AnimationController _lift =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 130));
  late final AnimationController _ret =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
  late final AnimationController _refill =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 750));

  // Geometry, refreshed every layout.
  double _cell = 39.5;
  double _trayCell = 20;
  double _trayGap = 1;
  static const double _liftGap = 52; // how far above the finger the piece floats

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      final busy = _scene.prune() | _confettiAlive() | _shaking();
      if (busy) _frame.value++;
    })
      ..start();
    _loadBest();
    // Signed in with an unfinished game? Carry on from there.
    if (!_resume()) _newGame();
  }

  // ---- Saved game (signed-in players) ---------------------------------------

  static const String _saveId = 'blocks_jodo';

  Map<String, dynamic> _snapshot() => {
        'cells': [for (final c in _board.cells) c?.value ?? 0],
        'tray': [
          for (final p in _tray) p == null ? -1 : bjShapes.indexOf(p.shape),
        ],
        'trayColors': [for (final p in _tray) p?.color.value ?? 0],
        'score': _score,
        'lives': _lives,
        'combo': _combo,
        'msc': _movesSinceClear,
        'ba': _bestAnnounced,
      };

  /// Saves the board, tray, score and lives (skipped once the game is over
  /// or before anything has happened).
  void _saveProgress({bool now = false}) {
    if (_gameOver) return;
    if (_score == 0 && _board.isEmpty) return;
    GameSaves.instance.put(_saveId, _snapshot(), now: now);
  }

  bool _resume() {
    final s = GameSaves.instance.peek(_saveId);
    if (s == null) return false;
    try {
      final cells = (s['cells'] as List).map((e) => (e as num).toInt()).toList();
      final tray = (s['tray'] as List).map((e) => (e as num).toInt()).toList();
      final trayColors = (s['trayColors'] as List).map((e) => (e as num).toInt()).toList();
      if (cells.length != _board.cells.length || tray.length != 3 || trayColors.length != 3) return false;
      for (var i = 0; i < cells.length; i++) {
        _board.cells[i] = cells[i] == 0 ? null : Color(cells[i]);
      }
      _tray = [
        for (var i = 0; i < 3; i++)
          tray[i] < 0 || tray[i] >= bjShapes.length ? null : BjPiece(bjShapes[tray[i]], Color(trayColors[i])),
      ];
      _score = (s['score'] as num).toInt();
      _lives = (s['lives'] as num).toInt().clamp(1, BjData.maxLives);
      _combo = (s['combo'] as num?)?.toInt() ?? 0;
      _movesSinceClear = (s['msc'] as num?)?.toInt() ?? 0;
      _bestAnnounced = s['ba'] == true;
    } catch (_) {
      _board.reset();
      return false;
    }
    _scene.introStart = _now();
    if (_tray.every((p) => p == null)) {
      _after(350, _deal);
    } else {
      // The tray slides in with the refill animation — without it the
      // restored pieces stay invisible.
      _refill.forward(from: 0);
      _after(500, _checkMoves);
    }
    return true;
  }

  @override
  void dispose() {
    // Leaving mid-game: signed-in players get the game saved to continue
    // later; everyone keeps a new high score.
    _saveProgress(now: true);
    if (_score > _best) {
      _best = _score;
      _saveBest();
    }
    for (final t in _timers) {
      t.cancel();
    }
    _ticker.dispose();
    _lift.dispose();
    _ret.dispose();
    _refill.dispose();
    _frame.dispose();
    super.dispose();
  }

  Future<void> _loadBest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) setState(() => _best = prefs.getInt(BjData.bestKey) ?? 0);
    } catch (_) {}
  }

  Future<void> _saveBest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(BjData.bestKey, _best);
      GameSaves.instance.bestChanged(BjData.bestKey, _best);
    } catch (_) {}
  }

  void _after(int ms, VoidCallback f) {
    late final Timer t;
    t = Timer(Duration(milliseconds: ms), () {
      _timers.remove(t);
      if (mounted) f();
    });
    _timers.add(t);
  }

  bool _confettiAlive() {
    final t = _now();
    _confetti.removeWhere((p) => t - p.start > p.life);
    return _confetti.isNotEmpty;
  }

  bool _shaking() => _shakeStart != null && _now() - _shakeStart! < 0.35;

  Offset get _shakeOffset {
    if (!_shaking()) return Offset.zero;
    final p = (_now() - _shakeStart!) / 0.35;
    final d = _shakeAmp * (1 - p);
    return Offset(sin(p * pi * 9) * d, cos(p * pi * 7) * d * 0.5);
  }

  // ---- Game flow ------------------------------------------------------------

  void _newGame() {
    GameSaves.instance.clear(_saveId);
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _board.reset();
    _scene
      ..bursts.clear()
      ..beams.clear()
      ..particles.clear()
      ..floats.clear()
      ..pops.clear()
      ..preview = {}
      ..previewColor = null
      ..glow = BjLines.empty
      ..gameOverStart = null
      ..introStart = _now();
    _confetti.clear();
    _score = 0;
    _lives = BjData.maxLives;
    _combo = 0;
    _movesSinceClear = 0;
    _bestAnnounced = false;
    _showNewBest = false;
    _newBest = false;
    _busy = false;
    _gameOver = false;
    _showGameOver = false;
    _banner = null;
    _clearDrag();
    _tray = [null, null, null];
    _after(350, _deal);
  }

  void _deal() {
    setState(() => _tray = List<BjPiece?>.of(_dealer.deal(_board)));
    _refill.forward(from: 0);
    Fx.refill();
    _saveProgress();
    _after(500, _checkMoves);
  }

  void _checkMoves() {
    if (_gameOver || _busy || _dragSlot != null) return;
    final left = _tray.whereType<BjPiece>().toList();
    if (left.isEmpty) return;
    if (left.any(_board.fitsAnywhere)) return;
    _onNoMoves();
  }

  /// No piece fits: lose a life, then rescue the board (or end the game).
  void _onNoMoves() {
    _busy = true;
    setState(() {});
    _after(300, () {
      Fx.noMoves();
      setState(() {
        _lives = _lives > 0 ? _lives - 1 : 0;
        _showBanner(BjText(AppLanguage.instance.value).noSpace, edge: const Color(0xFF8A1030));
      });
      if (_lives > 0) {
        _after(1100, _rescue);
      } else {
        _after(900, _startGameOver);
      }
    });
  }

  void _rescue() {
    final lines = _board.fullestLines(3);
    final cleared = _board.clear(lines.indices);
    final center = _boardInnerSize / 2;
    _spawnClear(cleared, lines, Offset(center, center), null);
    Fx.lineClear(3);
    _startShake(5);
    setState(() => _showBanner(BjText(AppLanguage.instance.value).rescue, edge: const Color(0xFF1E4FA0), small: true));
    _after(550, () {
      _busy = false;
      _deal();
    });
  }

  void _startGameOver() {
    GameSaves.instance.clear(_saveId);
    setState(() {
      _gameOver = true;
      _scene.gameOverStart = _now();
    });
    Fx.lose();
    _after(1250, () {
      if (_score > _best) {
        _newBest = _best > 0 || _score > 0;
        _best = _score;
        _saveBest();
      }
      setState(() => _showGameOver = true);
      if (_newBest) {
        Fx.win();
        _spawnConfetti();
      }
    });
  }

  // ---- Placement ------------------------------------------------------------

  void _place(int slot, int row, int col) {
    final piece = _tray[slot]!;
    final placed = _board.place(piece, row, col);
    final t = _now();
    for (final i in placed) {
      _scene.pops[i] = t;
    }
    _tray[slot] = null;
    _clearDrag();
    Fx.blockPlace();

    var gained = placed.length;
    final lines = _board.linesWith(const []);
    final pitch = _cell + BjBoardPainter.gap;
    final origin = placed
            .map((i) => Offset((i % BjData.size) * pitch + _cell / 2, (i ~/ BjData.size) * pitch + _cell / 2))
            .reduce((a, b) => a + b) /
        placed.length.toDouble();
    final text = BjText(AppLanguage.instance.value);

    if (!lines.isEmpty) {
      final cleared = _board.clear(lines.indices);
      _spawnClear(cleared, lines, origin, piece.color);
      _combo += 1;
      _movesSinceClear = 0;
      int pts = BjData.linePoints(lines.count) * (_combo < 1 ? 1 : _combo);
      final allClear = _board.isEmpty;
      if (allClear) pts += BjData.allClearBonus;
      gained += pts;
      _scene.floats.add(BjFloat('+$pts', origin, t));
      _after(50, () => Fx.lineClear(lines.count));
      if (_combo >= 2) _after(280, Fx.combo);
      if (lines.count >= 2) _startShake(2.0 + lines.count * 1.5);
      _showBanner(
        allClear ? text.allClear : text.praise(lines.count),
        sub: _combo >= 2 ? text.combo(_combo) : null,
        edge: _combo >= 2 ? const Color(0xFF8A1A4A) : const Color(0xFF7A3A00),
      );
    } else {
      _movesSinceClear += 1;
      if (_movesSinceClear >= BjData.comboGrace) _combo = 0;
    }

    _score += gained;
    if (!_bestAnnounced && _best > 0 && _score > _best) {
      _bestAnnounced = true;
      // New best score: confetti, the win sound and a glossy 3D title.
      _after(lines.isEmpty ? 150 : 900, () {
        Fx.win();
        _spawnConfetti();
        setState(() {
          _newBestKey++;
          _showNewBest = true;
        });
        _after(NewBestBanner.duration.inMilliseconds, () => setState(() => _showNewBest = false));
      });
    }

    if (_tray.every((p) => p == null)) {
      _after(260, _deal);
    } else {
      _after(lines.isEmpty ? 250 : 600, _checkMoves);
    }
    setState(() {});
    _saveProgress();
  }

  void _spawnClear(Map<int, Color> cleared, BjLines lines, Offset origin, Color? tint) {
    final t = _now();
    final pitch = _cell + BjBoardPainter.gap;
    for (final e in cleared.entries) {
      final c = Offset((e.key % BjData.size) * pitch + _cell / 2, (e.key ~/ BjData.size) * pitch + _cell / 2);
      final delay = (c - origin).distance / pitch * 0.028;
      final color = tint ?? e.value;
      _scene.bursts.add(BjBurst(e.key, color, t + delay));
      // No flying sparks on each clear (too distracting) — the cell burst
      // and the line beam are enough.
    }
    final beam = tint ?? Colors.white;
    for (final r in lines.rows) {
      _scene.beams.add(BjBeam(true, r, beam, t));
    }
    for (final c in lines.cols) {
      _scene.beams.add(BjBeam(false, c, beam, t));
    }
  }

  void _startShake(double amp) {
    _shakeStart = _now();
    _shakeAmp = amp;
  }

  void _spawnConfetti() {
    final size = MediaQuery.sizeOf(context);
    final t = _now();
    for (var i = 0; i < 110; i++) {
      _confetti.add(BjParticle(
        Offset(_rng.nextDouble() * size.width, -20 - _rng.nextDouble() * 120),
        Offset((_rng.nextDouble() - 0.5) * 80, 60 + _rng.nextDouble() * 140),
        BjData.blockColors[_rng.nextInt(BjData.blockColors.length)],
        t + _rng.nextDouble() * 0.6,
        2.4 + _rng.nextDouble() * 1.2,
        7 + _rng.nextDouble() * 6,
        (_rng.nextDouble() - 0.5) * 10,
      ));
    }
  }

  void _showBanner(String text, {String? sub, Color edge = const Color(0xFF7A3A00), bool small = false}) {
    _banner = text;
    _bannerSub = sub;
    _bannerEdge = edge;
    _bannerSmall = small;
    _bannerKey++;
  }

  bool _bannerSmall = false;

  // ---- Drag handling --------------------------------------------------------

  Offset _toStack(Offset global) {
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    return box == null ? global : box.globalToLocal(global);
  }

  /// Top-left of the board's 8×8 grid area, in stack coordinates.
  Offset get _boardOrigin {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    // Ignore the post-clear shake so the snap target stays steady.
    return _toStack(box.localToGlobal(Offset.zero)) - _shakeOffset;
  }

  double get _boardInnerSize => _cell * BjData.size + BjBoardPainter.gap * (BjData.size - 1);

  Offset _slotCenter(int i) {
    final box = _slotKeys[i].currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    return _toStack(box.localToGlobal(box.size.center(Offset.zero)));
  }

  /// Size of the floating piece as it grows from tray size to board size.
  ({double cell, double gap}) _dragMetrics(double k) =>
      (cell: lerpDouble(_trayCell, _cell, k)!, gap: lerpDouble(_trayGap, BjBoardPainter.gap, k)!);

  Offset _dragCenter(BjPiece p) {
    final k = Curves.easeOut.transform(_lift.value);
    final m = _dragMetrics(k);
    final h = p.rows * m.cell + (p.rows - 1) * m.gap;
    return _finger - Offset(0, k * (h / 2 + _liftGap));
  }

  void _onDown(int slot, PointerDownEvent e) {
    if (_dragSlot != null || _returning || _busy || _gameOver || _tray[slot] == null) return;
    _dragSlot = slot;
    _pointer = e.pointer;
    _finger = _toStack(e.position);
    _lift.forward(from: 0);
    Fx.blockPick();
    setState(() {});
  }

  void _onMove(PointerMoveEvent e) {
    if (e.pointer != _pointer || _dragSlot == null || _returning) return;
    _finger = _toStack(e.position);
    _updateHover();
    setState(() {});
  }

  void _onUp(PointerEvent e) {
    if (e.pointer != _pointer || _dragSlot == null || _returning) return;
    _finger = _toStack(e.position);
    _updateHover();
    final slot = _dragSlot!;
    if (_hoverRow != null && _hoverCol != null) {
      _place(slot, _hoverRow!, _hoverCol!);
    } else {
      _returnPiece();
    }
  }

  void _onCancel(PointerCancelEvent e) {
    if (e.pointer != _pointer || _dragSlot == null || _returning) return;
    _returnPiece();
  }

  void _updateHover() {
    final p = _tray[_dragSlot!]!;
    final pitch = _cell + BjBoardPainter.gap;
    final w = p.cols * pitch - BjBoardPainter.gap;
    final h = p.rows * pitch - BjBoardPainter.gap;
    final topLeft = _dragCenter(p) - Offset(w / 2, h / 2) - _boardOrigin;
    final col = (topLeft.dx / pitch).round();
    final row = (topLeft.dy / pitch).round();
    final hadGlow = !_scene.glow.isEmpty;
    if (_board.canPlace(p, row, col)) {
      if (row == _hoverRow && col == _hoverCol) return;
      _hoverRow = row;
      _hoverCol = col;
      final idx = _board.indicesFor(p, row, col);
      _scene
        ..preview = idx.toSet()
        ..previewColor = p.color
        ..glow = _board.linesWith(idx);
      if (!hadGlow && !_scene.glow.isEmpty) Fx.lineReady();
    } else {
      _hoverRow = null;
      _hoverCol = null;
      _scene
        ..preview = {}
        ..previewColor = null
        ..glow = BjLines.empty;
    }
  }

  void _returnPiece() {
    final slot = _dragSlot!;
    _retFrom = _dragCenter(_tray[slot]!);
    _retTo = _slotCenter(slot);
    _returning = true;
    _hoverRow = null;
    _hoverCol = null;
    _scene
      ..preview = {}
      ..previewColor = null
      ..glow = BjLines.empty;
    Fx.blockInvalid();
    _ret.forward(from: 0).whenCompleteOrCancel(() {
      if (!mounted) return;
      setState(_clearDrag);
      _after(80, _checkMoves);
    });
    setState(() {});
  }

  void _clearDrag() {
    _dragSlot = null;
    _pointer = null;
    _returning = false;
    _hoverRow = null;
    _hoverCol = null;
    _scene
      ..preview = {}
      ..previewColor = null
      ..glow = BjLines.empty;
  }

  void _openHow(BjText t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _BjHowToPlaySheet(t: t),
    );
  }

  // ---- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SaveProgressGate(
      // Save Progress overlay on leaving a game in progress (not on the
      // result screen), once the score is 150+.
      progressed: () => !_gameOver && !_showGameOver && _score >= 150,
      saveId: _saveId,
      background: BjData.screenBg,
      child: ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final t = BjText(lang);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: AppColors.adStripOn(BjData.screenBg),
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: BjData.screenBg,
            body: Stack(
              key: _stackKey,
              children: [
                Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: GameHeader(title: '', onBack: () => Navigator.of(context).maybePop(), onHelp: () => _openHow(t)),
                    ),
                    _buildScoreSection(t),
                    Expanded(child: _buildPlayArea()),
                    // Footer: lives bottom-left (same line position as Memory Grid).
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SizedBox(
                        height: 36,
                        child: Row(children: [LivesHearts(lives: _lives, max: BjData.maxLives)]),
                      ),
                    ),
                    const ScreenBottomBar(),
                  ],
                ),
                if (_dragSlot != null) _buildDragged(),
                if (_banner != null) _buildBanner(),
                if (_showNewBest)
                  Positioned.fill(
                    child: NewBestBanner(key: ValueKey(_newBestKey), title: t.newBestScore, value: max(_best, _score)),
                  ),
                if (_showGameOver) _buildGameOver(t),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: BjConfettiPainter(_confetti, _now, _frame)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
    );
  }

  // Score Section: Best Score | Score (lives are in the footer, bottom left,
  // same as Memory Grid). Best shows the live best while you beat it.
  Widget _buildScoreSection(BjText t) {
    final number = AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w800, height: 17 / 15);
    Widget counter(int value) => TweenAnimationBuilder<double>(
          tween: Tween(end: value.toDouble()),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          builder: (context, v, _) => Text('${v.round()}', style: number),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _statBox(value: counter(max(_best, _score)), label: t.bestScore)),
          const SizedBox(width: 12),
          Expanded(child: _statBox(value: counter(_score), label: t.score)),
        ],
      ),
    );
  }

  /// Figma Score Section box: surface fill, 2px border/default, radius 16,
  /// 16/10 padding; number ExtraBold 15/17 over label SemiBold 11/12, muted,
  /// +0.66 tracking.
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

  Widget _buildPlayArea() {
    return LayoutBuilder(
      builder: (context, c) {
        // Board + tray are one group, centred vertically between the score
        // boxes and the bottom bar. Board is 340 at 360 wide (10px margins);
        // the tray is tall enough for the tallest piece (5 cells) plus 12px
        // above and below. On short screens the whole group scales down.
        const gap = 24.0; // board → tray
        const margin = 16.0; // minimum space above and below the group
        // trayHeight = 5 × 20k + 4 + 24, with k = boardSize / 340.
        final byHeight = (c.maxHeight - 2 * margin - gap - 28) / (1 + 100 / 340);
        final boardSize = min(min(340.0, c.maxWidth - 20), byHeight).clamp(200.0, 340.0).toDouble();
        final inner = boardSize - 10; // 2px border + 3px padding each side
        _cell = (inner - BjBoardPainter.gap * (BjData.size - 1)) / BjData.size;
        final k = boardSize / 340;
        _trayCell = 20 * k;
        _trayGap = 1;
        final trayHeight = 5 * _trayCell + 4 * _trayGap + 24;
        return Column(
          children: [
            const Spacer(),
            ValueListenableBuilder<int>(
              valueListenable: _frame,
              builder: (context, _, child) => Transform.translate(offset: _shakeOffset, child: child),
              child: Container(
                width: boardSize,
                height: boardSize,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: BjData.boardFill,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: BjData.boardBorder, width: 2),
                ),
                child: CustomPaint(
                  key: _boardKey,
                  size: Size.square(inner),
                  painter: BjBoardPainter(_scene, _frame),
                ),
              ),
            ),
            const SizedBox(height: gap),
            SizedBox(height: trayHeight, child: _buildTray()),
            const Spacer(),
          ],
        );
      },
    );
  }

  Widget _buildTray() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) => _onDown(i, e),
                onPointerMove: _onMove,
                onPointerUp: _onUp,
                onPointerCancel: _onCancel,
                child: SizedBox.expand(
                  key: _slotKeys[i],
                  child: Center(child: _trayPiece(i)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _trayPiece(int i) {
    final p = _tray[i];
    if (p == null || _dragSlot == i) return const SizedBox.shrink();
    final fits = _board.fitsAnywhere(p);
    final size = BjPiecePainter.sizeFor(p, _trayCell, _trayGap);
    return AnimatedBuilder(
      animation: _refill,
      builder: (context, child) {
        final start = i * 0.12;
        final raw = ((_refill.value - start) / 0.62).clamp(0.0, 1.0);
        final v = Curves.easeOutBack.transform(raw);
        return Opacity(
          opacity: raw.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(70 * (1 - v), 0),
            child: Transform.scale(scale: 0.4 + 0.6 * v, child: child),
          ),
        );
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: fits && !_gameOver ? 1 : 0.35,
        child: CustomPaint(
          size: size,
          painter: BjPiecePainter(
            piece: p,
            cell: _trayCell,
            gap: _trayGap,
            overrideColor: _gameOver ? BjData.deadBlock : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDragged() {
    final p = _tray[_dragSlot!]!;
    return AnimatedBuilder(
      animation: Listenable.merge([_lift, _ret]),
      builder: (context, _) {
        Offset center;
        ({double cell, double gap}) m;
        if (_returning) {
          final v = Curves.easeOutBack.transform(_ret.value);
          center = Offset.lerp(_retFrom, _retTo, v)!;
          m = _dragMetrics(1 - Curves.easeOut.transform(_ret.value));
        } else {
          center = _dragCenter(p);
          m = _dragMetrics(Curves.easeOut.transform(_lift.value));
        }
        final size = BjPiecePainter.sizeFor(p, m.cell, m.gap);
        return Positioned(
          left: center.dx - size.width / 2,
          top: center.dy - size.height / 2,
          child: IgnorePointer(
            child: CustomPaint(
              size: size,
              painter: BjPiecePainter(piece: p, cell: m.cell, gap: m.gap, shadow: !_returning),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBanner() {
    final big = _bannerSmall ? 26.0 : 42.0;
    Widget outlined(String s, double size, Color edge) => Stack(
          alignment: Alignment.center,
          children: [
            Text(
              s,
              textAlign: TextAlign.center,
              style: AppFonts.baloo(fontSize: size, fontWeight: FontWeight.w800, height: 1.1).copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = size / 6
                  ..strokeJoin = StrokeJoin.round
                  ..color = edge,
                shadows: const [Shadow(color: Color(0x99000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
            ),
            Text(s, textAlign: TextAlign.center, style: AppFonts.baloo(fontSize: size, fontWeight: FontWeight.w800, height: 1.1)),
          ],
        );
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: const Alignment(0, -0.28),
          child: TweenAnimationBuilder<double>(
            key: ValueKey(_bannerKey),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1150),
            builder: (context, v, child) {
              final s = v < 0.22 ? Curves.elasticOut.transform(v / 0.22) : 1.0;
              final o = v > 0.72 ? (1 - (v - 0.72) / 0.28) : 1.0;
              return Opacity(
                opacity: o.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, -18 * v),
                  child: Transform.scale(scale: 0.4 + 0.6 * s, child: child),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  outlined(_banner!, big, _bannerEdge),
                  if (_bannerSub != null) ...[
                    const SizedBox(height: 2),
                    outlined(_bannerSub!, 26, const Color(0xFF8A1A4A)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver(BjText t) {
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
        builder: (context, v, child) => Opacity(
          opacity: v,
          child: Transform.scale(scale: 0.92 + 0.08 * v, child: child),
        ),
        child: Container(
          color: const Color(0xF2240812),
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_newBest ? '🏆' : '🧱', style: const TextStyle(fontSize: 70)),
                  const SizedBox(height: 12),
                  Text(_newBest ? t.newBest : t.gameOver, style: AppFonts.baloo(fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    _newBest ? t.newBestSub : t.tryAgainSub,
                    textAlign: TextAlign.center,
                    style: AppFonts.baloo(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _newBest ? BjData.gold : Colors.transparent, width: 2),
                    ),
                    child: Column(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: _score.toDouble()),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, _) => Text(
                            '${v.round()}',
                            style: AppFonts.baloo(fontSize: 54, fontWeight: FontWeight.w800, color: BjData.gold),
                          ),
                        ),
                        Text(t.finalScore.toUpperCase(),
                            style: AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white70)),
                        const SizedBox(height: 6),
                        Text(t.best(_best), style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: ChunkyButton(label: t.playAgain, onTap: () => setState(_newGame)),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Fx.tap();
                      Navigator.of(context).maybePop();
                    },
                    child: Text(t.backHome, style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── How to play ───────────────────────────

class _BjHowToPlaySheet extends StatelessWidget {
  final BjText t;
  const _BjHowToPlaySheet({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Clear the phone's gesture / navigation bar.
      padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + MediaQuery.viewPaddingOf(context).bottom),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A1024), Color(0xFF1E0B2E)],
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
            Text(t.howTitle, style: AppFonts.baloo(fontSize: 22, fontWeight: FontWeight.w800, color: BjData.gold)),
            const SizedBox(height: 20),
            for (var i = 0; i < t.steps.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: BjData.blockColors[i % BjData.blockColors.length],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${i + 1}', style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textOnLight)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.steps[i][0], style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(t.steps[i][1], style: AppFonts.baloo(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
              if (i != t.steps.length - 1) const SizedBox(height: 16),
            ],
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x1AFFC53D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x40FFC53D)),
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
