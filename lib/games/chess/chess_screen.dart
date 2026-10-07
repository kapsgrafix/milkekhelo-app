import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/feedback/fx.dart';
import '../../core/localization/app_language.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/game_header.dart';
import '../../core/widgets/screen_bottom_bar.dart';
import 'chess_ai.dart';
import 'chess_engine.dart';
import 'chess_pieces.dart';
import 'chess_translations.dart';

/// Chess game table — Figma "Chess Solo - Game Table" (382:733): the wood
/// board (assets/chess/board.webp) edge to edge, 360 wide, on the coral
/// screen colour, with a player bar above and below. Bars + board form one
/// unit, centred vertically between the header and the bottom bar.
///
/// Solo: you play White (bottom) against [chessBotMove] (top).
/// 2 Players: one phone between two people — Black's bar and Black's pieces
/// are drawn upside down so the player sitting at the top reads them.
///
/// Tap a piece → its legal squares get dots (rings for captures); tap a dot
/// to move. A king in check gets a pulsing red square and a "Check!" pop;
/// captures burst and the taken piece joins the captor's tray (with the
/// material lead, like chess.com); checkmate topples the king and confetti
/// flies for the winner.
class ChessScreen extends StatefulWidget {
  final bool vsBot;
  const ChessScreen({super.key, required this.vsBot});

  static void showHowToPlay(BuildContext context, ChessText t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _HowToSheet(t: t),
    );
  }

  @override
  State<ChessScreen> createState() => _ChessScreenState();
}

class _ChessScreenState extends State<ChessScreen> with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF0F3D28); // background/screen-green

  late ChessGame _game = ChessGame();
  int? _selected;
  List<ChessMove> _targets = const [];
  List<ChessMove>? _promoChoices;
  bool _thinking = false;
  bool _showEnd = false;
  int _generation = 0;

  // Move slide.
  late final AnimationController _moveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  ChessMove? _animMove;
  int _animPiece = 0;

  // Capture burst.
  late final AnimationController _captureCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
  int _capPiece = 0;
  int _capSquare = -1;
  List<_Shard> _shards = const [];

  // Check: pulsing red square + "Check!" pop.
  late final AnimationController _checkPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  late final AnimationController _bannerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  String _banner = '';
  bool _bannerFlip = false;

  // 2 Players: every piece turns to face whoever is to move
  // (0 = White's view, 1 = Black's view — pieces rotated 180°).
  late final AnimationController _viewCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  // Game over: king topples, then the result card.
  late final AnimationController _endCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  final _confetti = GlobalKey<_ConfettiState>();
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    ChessPieceArt.load();
  }

  @override
  void dispose() {
    _generation++;
    _moveCtrl.dispose();
    _captureCtrl.dispose();
    _checkPulse.dispose();
    _bannerCtrl.dispose();
    _endCtrl.dispose();
    _viewCtrl.dispose();
    super.dispose();
  }

  bool get _twoPlayer => !widget.vsBot;
  bool get _busy => _moveCtrl.isAnimating || _thinking || _game.over || _promoChoices != null;

  // ───────────────────────── Input ─────────────────────────

  void _onTapSquare(int sq) {
    if (_busy) return;
    if (widget.vsBot && !_game.whiteToMove) return;
    final piece = _game.position.board[sq];
    final own = piece != 0 && (piece > 0) == _game.whiteToMove;

    if (_selected != null) {
      final moves = [for (final m in _targets) if (m.to == sq) m];
      if (moves.isNotEmpty) {
        if (moves.length > 1) {
          Fx.tap();
          setState(() => _promoChoices = moves);
        } else {
          _play(moves.first);
        }
        return;
      }
    }
    if (own && _selected != sq) {
      Fx.tap();
      setState(() {
        _selected = sq;
        _targets = _game.movesFrom(sq);
      });
    } else {
      setState(() {
        _selected = null;
        _targets = const [];
      });
    }
  }

  Future<void> _play(ChessMove m) async {
    final gen = _generation;
    final mover = _game.position.board[m.from];
    setState(() {
      _promoChoices = null;
      _selected = null;
      _targets = const [];
      _animMove = m;
      _animPiece = mover;
      _bannerCtrl.value = 0;
      _checkPulse.stop();
      _checkPulse.value = 0;
    });
    _game.apply(m);
    if (m.isCapture) {
      Fx.chessCapture();
    } else {
      Fx.chessMove();
    }
    await _moveCtrl.forward(from: 0);
    if (!mounted || gen != _generation) return;
    if (m.isCapture) _burst(m);
    setState(() => _animMove = null);
    // 2 Players: turn the pieces to face the player whose turn it is now.
    if (_twoPlayer && !_game.over) {
      _viewCtrl.value = _game.whiteToMove ? 0 : 1; // instant, no spin
    }

    if (_game.over) {
      _gameOver();
      return;
    }
    if (_game.inCheck) {
      Fx.chessCheck();
      _checkPulse.repeat(reverse: true);
      _banner = ChessText(AppLanguage.instance.value).check;
      _bannerFlip = _twoPlayer && !_game.whiteToMove;
      _bannerCtrl.forward(from: 0);
    }
    if (widget.vsBot && !_game.whiteToMove) _botTurn();
  }

  void _burst(ChessMove m) {
    _capPiece = m.captured;
    _capSquare = m.captureSquare;
    _shards = List.generate(12, (i) {
      final a = (i / 12) * pi * 2 + _rng.nextDouble() * 0.4;
      final speed = 0.9 + _rng.nextDouble() * 0.9;
      return _Shard(cos(a) * speed, sin(a) * speed - 0.6, 0.08 + _rng.nextDouble() * 0.07, _rng.nextDouble() * 6 - 3);
    });
    _captureCtrl.forward(from: 0);
  }

  Future<void> _botTurn() async {
    final gen = _generation;
    setState(() => _thinking = true);
    final encoded = _game.position.encode();
    List<int> reply;
    try {
      final r = await Future.wait<Object>([
        compute(chessBotMove, encoded),
        Future<Object>.delayed(const Duration(milliseconds: 650), () => 0),
      ]);
      reply = r[0] as List<int>;
    } catch (_) {
      reply = chessBotMove(encoded); // isolate unavailable — think here
    }
    if (!mounted || gen != _generation) return;
    final wanted = ChessMove.decode(reply);
    final legal = _game.playableMoves;
    final m = legal.firstWhere((x) => x == wanted, orElse: () => legal.first);
    setState(() => _thinking = false);
    await _play(m);
  }

  void _gameOver() {
    final r = _game.result;
    _checkPulse.stop();
    final mate = r == ChessResult.whiteWins || r == ChessResult.blackWins;
    if (mate) {
      _checkPulse.value = 1;
      final tt = ChessText(AppLanguage.instance.value);
      _banner = _game.kingCaptured ? tt.kingCaptured : tt.checkmate;
      _bannerFlip = _twoPlayer && r == ChessResult.whiteWins; // loser (Black) reads it
      _bannerCtrl.forward(from: 0);
      if (!_game.kingCaptured) _endCtrl.forward(from: 0); // a taken king is gone already
    }
    final humanLost = widget.vsBot && r == ChessResult.blackWins;
    Future.delayed(Duration(milliseconds: mate ? 900 : 300), () {
      if (!mounted) return;
      if (mate && !humanLost) {
        Fx.win();
        _confetti.currentState?.fire();
      } else if (humanLost) {
        Fx.lose();
      } else {
        Fx.roundWin();
      }
    });
    Future.delayed(Duration(milliseconds: mate ? 1600 : 900), () {
      if (mounted) setState(() => _showEnd = true);
    });
  }

  void _restart() {
    setState(() {
      _generation++;
      _game = ChessGame();
      _selected = null;
      _targets = const [];
      _promoChoices = null;
      _thinking = false;
      _showEnd = false;
      _animMove = null;
      _capSquare = -1;
      _moveCtrl.value = 0;
      _captureCtrl.value = 0;
      _checkPulse.stop();
      _checkPulse.value = 0;
      _bannerCtrl.value = 0;
      _endCtrl.value = 0;
      _viewCtrl.value = 0;
    });
  }

  // ───────────────────────── Derived ─────────────────────────

  /// Pieces each side has taken, in capture order (signed piece codes).
  /// The move still sliding in isn't counted until it lands.
  List<int> _captured({required bool byWhite}) {
    final moves = _game.moves;
    final n = moves.length - (_animMove != null ? 1 : 0);
    return [
      for (var i = 0; i < n; i++)
        if ((i % 2 == 0) == byWhite && moves[i].captured != 0) moves[i].captured,
    ];
  }

  /// Board material difference (White − Black), in pawns.
  int get _materialLead {
    var s = 0;
    for (final v in _game.position.board) {
      s += (v > 0 ? 1 : -1) * ChessPiece.value[v.abs()];
    }
    return s;
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final t = ChessText(lang);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: Color.alphaBlend(AppColors.surface, _bg),
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: _bg,
            body: Stack(
              children: [
                Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: GameHeader(
                        title: '',
                        onBack: () => Navigator.of(context).pop(),
                        onHelp: () => ChessScreen.showHowToPlay(context, t),
                      ),
                    ),
                    Expanded(child: _table(t)),
                    const ScreenBottomBar(),
                  ],
                ),
                Positioned.fill(child: IgnorePointer(child: _Confetti(key: _confetti))),
                if (_showEnd) Positioned.fill(child: _endOverlay(t)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _table(ChessText t) {
    return LayoutBuilder(
      builder: (context, c) {
        const barH = 58.0, gap = 24.0;
        final size = min(c.maxWidth, c.maxHeight - 2 * barH - 2 * gap - 16).clamp(200.0, 720.0).toDouble();
        final top = _playerBar(t, white: false);
        return Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: barH, child: _twoPlayer ? RotatedBox(quarterTurns: 2, child: top) : top),
                const SizedBox(height: gap),
                SizedBox.square(dimension: size, child: _board(t, size)),
                const SizedBox(height: gap),
                SizedBox(height: barH, child: _playerBar(t, white: true)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────── Player bars ─────────────────────────

  Widget _playerBar(ChessText t, {required bool white}) {
    final name = widget.vsBot ? (white ? t.you : t.bot) : (white ? t.player1 : t.player2);
    final avatar = widget.vsBot ? (white ? '🦁' : '🤖') : (white ? '🦁' : '🐯');
    final avatarBg = white ? const Color(0xFFFFC53D) : const Color(0xFF5B8CFF);
    final active = !_game.over && _game.whiteToMove == white;
    final inCheck = active && _game.inCheck;
    final taken = _captured(byWhite: white);
    final lead = _materialLead * (white ? 1 : -1);

    String? status;
    if (active) {
      if (inCheck) {
        status = t.check;
      } else if (!white && widget.vsBot) {
        status = _thinking ? t.thinking : null;
      } else {
        status = widget.vsBot ? t.yourTurn : t.turn;
      }
    }

    final ring = active ? (inCheck ? const Color(0xFFFF5A5A) : AppColors.brandYellow) : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Avatar; a coloured ring marks whose turn it is.
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(color: ring, width: 2),
            ),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(color: avatarBg),
              child: Text(avatar, style: const TextStyle(fontSize: 21, height: 1.1)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.baloo(fontSize: 15, fontWeight: FontWeight.w800, height: 1.15)),
                    ),
                    const SizedBox(width: 6),
                    // Which colour this player has.
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: white ? ChessPieceArt.whiteTop : ChessPieceArt.blackTop,
                        border: Border.all(color: ChessPieceArt.blackEdge, width: 1),
                      ),
                    ),
                    if (status != null) ...[
                      const SizedBox(width: 8),
                      _statusChip(status, inCheck, thinking: !white && widget.vsBot && _thinking),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                SizedBox(height: 18, child: _capturedRow(taken, lead)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// chess.com-style tray: taken pieces grouped by type (pawns first),
  /// overlapping within a group, then "+N" when this side is ahead.
  Widget _capturedRow(List<int> taken, int lead) {
    final sorted = [...taken]..sort((a, b) => ChessPiece.value[a.abs()].compareTo(ChessPiece.value[b.abs()]) == 0
        ? a.abs().compareTo(b.abs())
        : ChessPiece.value[a.abs()].compareTo(ChessPiece.value[b.abs()]));
    final children = <Widget>[];
    var x = 0.0;
    int? lastType;
    for (var i = 0; i < sorted.length; i++) {
      final type = sorted[i].abs();
      if (lastType != null) x += type == lastType ? 9 : 17;
      lastType = type;
      children.add(Positioned(
        left: x,
        top: 0,
        child: TweenAnimationBuilder<double>(
          key: ValueKey('cap$i-${sorted[i]}'),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          builder: (context, v, child) => Transform.scale(scale: v, child: child),
          child: ChessPieceIcon(piece: sorted[i], size: 18),
        ),
      ));
    }
    final width = sorted.isEmpty ? 0.0 : x + 18;
    return Row(
      children: [
        SizedBox(width: width, height: 18, child: Stack(clipBehavior: Clip.none, children: children)),
        if (lead > 0) ...[
          const SizedBox(width: 6),
          Text('+$lead', style: AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
        ],
      ],
    );
  }

  Widget _statusChip(String text, bool danger, {bool thinking = false}) {
    final color = danger ? const Color(0xFFFF5A5A) : AppColors.brandYellow;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(color: color.withAlpha(40), borderRadius: BorderRadius.circular(999)),
      child: thinking
          ? _ThinkingText(text: text, color: color)
          : Text(text, style: AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
    );
  }

  // ───────────────────────── Board ─────────────────────────

  /// Width of the board art's frame, as a fraction of the board size.
  static const double _frame = 14 / 720;

  Widget _board(ChessText t, double size) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The supplied board art has a dark top-left corner; mirrored so
        // a8 (top-left) and h1 (bottom-right) are light squares, as in chess.
        Positioned.fill(
          child: Transform.flip(
            flipX: true,
            child: Image.asset('assets/chess/board.webp', fit: BoxFit.fill, filterQuality: FilterQuality.medium),
          ),
        ),
        // The board art has a wooden frame: the 8 × 8 grid sits 14/720 of
        // the width in from each edge, so pieces, highlights and taps use
        // that inner square.
        Positioned.fill(
          left: size * _frame,
          top: size * _frame,
          right: size * _frame,
          bottom: size * _frame,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              final cell = size * (1 - 2 * _frame) / 8;
              final col = (d.localPosition.dx / cell).floor().clamp(0, 7);
              final row = (d.localPosition.dy / cell).floor().clamp(0, 7);
              _onTapSquare(row * 8 + col);
            },
            child: CustomPaint(
              painter: _BoardPainter(this, Listenable.merge([_moveCtrl, _captureCtrl, _checkPulse, _endCtrl, _viewCtrl, ChessPieceArt.ready])),
            ),
          ),
        ),
        Positioned.fill(child: IgnorePointer(child: _checkBanner())),
        if (_promoChoices != null) Positioned.fill(child: _promotionPicker(t)),
      ],
    );
  }

  Widget _checkBanner() {
    return AnimatedBuilder(
      animation: _bannerCtrl,
      builder: (context, _) {
        final v = _bannerCtrl.value;
        if (v == 0 || v == 1) return const SizedBox.shrink();
        final scale = v < 0.25 ? Curves.elasticOut.transform(v / 0.25) : 1.0;
        final opacity = v > 0.75 ? (1 - v) / 0.25 : 1.0;
        final pill = Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFF6B6B), Color(0xFFC62828)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Color(0x99E53935), blurRadius: 24, spreadRadius: 2)],
              ),
              child: Text(_banner, style: AppFonts.baloo(fontSize: 30, fontWeight: FontWeight.w800, height: 1.1)),
            ),
          ),
        );
        return Center(child: _bannerFlip ? RotatedBox(quarterTurns: 2, child: pill) : pill);
      },
    );
  }

  Widget _promotionPicker(ChessText t) {
    final white = _game.whiteToMove;
    final card = Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xF20A2A1B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandYellow, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.promoteTo, style: AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final m in _promoChoices!) ...[
                GestureDetector(
                  onTap: () => _play(m),
                  child: Container(
                    width: 56,
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: ChessPieceIcon(piece: white ? m.promo : -m.promo, size: 46, shadow: true),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
    return GestureDetector(
      onTap: () => setState(() => _promoChoices = null), // tap outside = cancel
      child: Container(
        color: const Color(0x80000000),
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {},
          child: _twoPlayer && !white ? RotatedBox(quarterTurns: 2, child: card) : card,
        ),
      ),
    );
  }

  // ───────────────────────── Game over ─────────────────────────

  Widget _endOverlay(ChessText t) {
    final r = _game.result;
    final mate = r == ChessResult.whiteWins || r == ChessResult.blackWins;
    String emoji, title, sub;
    if (mate) {
      final whiteWon = r == ChessResult.whiteWins;
      title = _game.kingCaptured ? t.kingCaptured : t.checkmate;
      if (widget.vsBot) {
        emoji = whiteWon ? '🏆' : '🤖';
        sub = whiteWon ? t.youWin : t.botWins;
      } else {
        emoji = '🏆';
        sub = t.wins('${whiteWon ? t.player1 : t.player2} (${whiteWon ? t.white : t.black})');
      }
    } else {
      emoji = '🤝';
      title = t.draw;
      sub = switch (r) {
        ChessResult.stalemate => t.stalemate,
        ChessResult.insufficient => t.insufficient,
        ChessResult.fiftyMove => t.fiftyMove,
        _ => t.repetition,
      };
    }
    Widget message() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 4),
            Text(title,
                textAlign: TextAlign.center,
                style: AppFonts.baloo(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.brandYellow)),
            Text(sub,
                textAlign: TextAlign.center,
                style: AppFonts.baloo(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        );
    final buttons = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChunkyButton(label: t.playAgain, width: double.infinity, onTap: _restart),
        const SizedBox(height: 14),
        ChunkyButton(
          label: t.backHome,
          width: double.infinity,
          style: ChunkyButtonStyle.secondary,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      builder: (context, v, child) => Opacity(opacity: v, child: child),
      child: Container(
        color: const Color(0xD9061A10),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_twoPlayer) ...[
                RotatedBox(quarterTurns: 2, child: message()),
                const SizedBox(height: 28),
                buttons,
                const SizedBox(height: 28),
                message(),
              ] else ...[
                message(),
                const SizedBox(height: 32),
                buttons,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Board painter ─────────────────────────

class _Shard {
  final double vx, vy, size, spin;
  const _Shard(this.vx, this.vy, this.size, this.spin);
}

class _BoardPainter extends CustomPainter {
  final _ChessScreenState s;
  _BoardPainter(this.s, Listenable repaint) : super(repaint: repaint);

  static const Color _lastMove = Color(0x66F7D354);
  static const Color _selectedSq = Color(0x99F7D354);
  static const Color _hint = Color(0x52000000);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 8;
    Rect rect(int sq) => Rect.fromLTWH((sq % 8) * cell, (sq ~/ 8) * cell, cell, cell);
    final game = s._game;
    final board = game.position.board;
    final anim = s._animMove;
    final t = Curves.easeInOutCubic.transform(s._moveCtrl.value);

    // 1. Last move + selection.
    final last = game.lastMove;
    if (last != null) {
      canvas.drawRect(rect(last.from), Paint()..color = _lastMove);
      canvas.drawRect(rect(last.to), Paint()..color = _lastMove);
    }
    if (s._selected != null) canvas.drawRect(rect(s._selected!), Paint()..color = _selectedSq);

    // 2. King in check: pulsing red square with a glow.
    final mated = game.result == ChessResult.whiteWins || game.result == ChessResult.blackWins;
    if ((game.inCheck && anim == null) || mated) {
      final k = game.position.kingSquare(game.whiteToMove);
      if (k >= 0) {
        final r = rect(k);
        final p = mated ? 1.0 : s._checkPulse.value;
        canvas.drawRect(
          r,
          Paint()
            ..shader = RadialGradient(colors: [
              Color.fromARGB((235 * (0.7 + 0.3 * p)).round(), 255, 59, 48),
              Color.fromARGB((170 * (0.6 + 0.4 * p)).round(), 200, 20, 20),
            ]).createShader(r),
        );
        canvas.drawRect(
          r.inflate(2 + 4 * p),
          Paint()
            ..color = Color.fromARGB((120 * p).round(), 255, 70, 60)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
    }

    // 3. Pieces.
    final hidden = <int>{};
    int? rookFrom, rookTo;
    if (anim != null) {
      hidden.add(anim.to);
      if (anim.castle) {
        rookFrom = anim.to > anim.from ? anim.from + 3 : anim.from - 4;
        rookTo = anim.to > anim.from ? anim.from + 1 : anim.from - 1;
        hidden.add(rookTo);
      }
    }
    final loserKing = mated ? game.position.kingSquare(game.whiteToMove) : -1;
    for (var sq = 0; sq < 64; sq++) {
      final v = board[sq];
      if (v == 0 || hidden.contains(sq)) continue;
      if (sq == loserKing) {
        _topple(canvas, rect(sq), v, s._endCtrl.value);
        continue;
      }
      _piece(canvas, rect(sq), v);
    }
    // The captured piece waits on its square until the attacker lands.
    if (anim != null && anim.isCapture) _piece(canvas, rect(anim.captureSquare), anim.captured);

    // 4. Capture burst.
    final ct = s._captureCtrl.value;
    if (s._capSquare >= 0 && ct > 0 && ct < 1) _captureBurst(canvas, rect(s._capSquare), s._capPiece, ct, cell);

    // 5. Moving piece(s), lifted slightly mid-flight.
    if (anim != null) {
      final lift = 1 + 0.12 * sin(pi * t);
      final from = rect(anim.from), to = rect(anim.to);
      _piece(canvas, _scaleRect(Rect.lerp(from, to, t)!, lift), s._animPiece);
      if (rookFrom != null && rookTo != null) {
        _piece(canvas, Rect.lerp(rect(rookFrom), rect(rookTo), t)!, board[rookTo]);
      }
    }

    // 6. Move hints.
    if (s._selected != null) {
      for (final m in s._targets) {
        final r = rect(m.to);
        if (m.isCapture) {
          canvas.drawCircle(
            r.center,
            cell * 0.44,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = cell * 0.08
              ..color = _hint,
          );
        } else {
          canvas.drawCircle(r.center, cell * 0.16, Paint()..color = _hint);
        }
      }
    }
  }

  Rect _scaleRect(Rect r, double k) => Rect.fromCenter(center: r.center, width: r.width * k, height: r.height * k);

  /// 2 Players: all pieces face the player to move (switches instantly).
  double get _viewAngle => s._twoPlayer ? pi * s._viewCtrl.value : 0;

  void _piece(Canvas canvas, Rect square, int piece, {double opacity = 1}) {
    final r = square.deflate(square.width * 0.03);
    final angle = _viewAngle;
    if (angle != 0) {
      canvas.save();
      canvas.translate(r.center.dx, r.center.dy);
      canvas.rotate(angle);
      canvas.translate(-r.center.dx, -r.center.dy);
    }
    ChessPieceArt.paint(canvas, r, piece, opacity: opacity);
    if (angle != 0) canvas.restore();
  }

  /// Checkmated king tips over onto its side.
  void _topple(Canvas canvas, Rect square, int piece, double v) {
    final e = Curves.bounceOut.transform(v);
    final r = square.deflate(square.width * 0.03);
    canvas.save();
    canvas.translate(r.center.dx, r.center.dy);
    canvas.rotate(_viewAngle);
    canvas.translate(0, r.height * 0.35);
    canvas.rotate(-pi / 2 * 0.92 * e);
    canvas.translate(0, -r.height * 0.35);
    canvas.translate(-r.center.dx, -r.center.dy);
    ChessPieceArt.paint(canvas, r, piece);
    canvas.restore();
  }

  void _captureBurst(Canvas canvas, Rect square, int piece, double t, double cell) {
    final c = square.center;
    // Flash ring.
    canvas.drawCircle(
      c,
      cell * (0.25 + 0.55 * Curves.easeOut.transform(t)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.08 * (1 - t)
        ..color = Color.fromARGB((230 * (1 - t)).round(), 255, 240, 200),
    );
    // The taken piece spins and shrinks away.
    final k = 1 - Curves.easeIn.transform(t);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(t * 1.4);
    canvas.translate(-c.dx, -c.dy);
    ChessPieceArt.paint(canvas, _scaleRect(square.deflate(square.width * 0.03), k), piece, shadow: false, opacity: k);
    canvas.restore();
    // Shards in the taken piece's colours.
    final white = piece > 0;
    for (var i = 0; i < s._shards.length; i++) {
      final sh = s._shards[i];
      final p = Offset(c.dx + sh.vx * cell * t * 1.2, c.dy + (sh.vy * t + 1.6 * t * t) * cell);
      final paint = Paint()
        ..color = (i.isEven
                ? (white ? ChessPieceArt.whiteTop : ChessPieceArt.blackTop)
                : const Color(0xFFFFC53D))
            .withAlpha((255 * (1 - t)).round());
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(sh.spin * t);
      final w = sh.size * cell;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: w), Radius.circular(w * 0.25)), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => true;
}

// ───────────────────────── Small widgets ─────────────────────────

/// "Thinking" with three dots that fill in turn.
class _ThinkingText extends StatefulWidget {
  final String text;
  final Color color;
  const _ThinkingText({required this.text, required this.color});

  @override
  State<_ThinkingText> createState() => _ThinkingTextState();
}

class _ThinkingTextState extends State<_ThinkingText> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = AppFonts.baloo(fontSize: 12, fontWeight: FontWeight.w800, color: widget.color);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final n = (_c.value * 4).floor();
        return Text('${widget.text}${'.' * n}${' ' * (3 - min(n, 3))}', style: style);
      },
    );
  }
}

/// Confetti burst for a checkmate win.
class _Confetti extends StatefulWidget {
  const _Confetti({super.key});

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
  final _rng = Random();
  List<_Bit> _bits = const [];

  static const _colors = [
    Color(0xFF60A5FA), Color(0xFFFBBF24), Color(0xFF4ADE80), Color(0xFFF87171),
    Color(0xFFEC4899), Color(0xFF22D3EE), Colors.white,
  ];

  void fire() {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    _bits = List.generate(
      130,
      (_) => _Bit(
        _rng.nextDouble(),
        -_rng.nextDouble() * 0.6,
        6 + _rng.nextDouble() * 7,
        9 + _rng.nextDouble() * 9,
        _colors[_rng.nextInt(_colors.length)],
        0.5 + _rng.nextDouble() * 0.6,
        -0.08 + _rng.nextDouble() * 0.16,
        _rng.nextDouble() * pi * 2,
        -6 + _rng.nextDouble() * 12,
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
        return CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_bits, _c.value * 2.8));
      },
    );
  }
}

class _Bit {
  final double x, y, w, h;
  final Color color;
  final double vy, vx, rot, vr;
  const _Bit(this.x, this.y, this.w, this.h, this.color, this.vy, this.vx, this.rot, this.vr);
}

class _ConfettiPainter extends CustomPainter {
  final List<_Bit> bits;
  final double t;
  _ConfettiPainter(this.bits, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final fade = t > 2.3 ? max(0.0, (2.8 - t) / 0.5) : 1.0;
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

class _HowToSheet extends StatelessWidget {
  final ChessText t;
  const _HowToSheet({required this.t});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + MediaQuery.viewPaddingOf(context).bottom),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF12442B), Color(0xFF0A2418)],
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
              Text(t.howTitle, style: AppFonts.baloo(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.brandYellow)),
              const SizedBox(height: 20),
              for (var i = 0; i < t.steps.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF33C481)),
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
                  color: const Color(0x1A33C481),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x4033C481)),
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
