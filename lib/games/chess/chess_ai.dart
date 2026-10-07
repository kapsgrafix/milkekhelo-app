import 'dart:math';

import 'chess_engine.dart';

/// The Solo-mode computer opponent: a small alpha-beta search (iterative
/// deepening up to [maxDepth] plies within a time budget, plus a capture
/// "quiescence" search so it doesn't blunder into obvious recaptures) with a
/// material + piece-square evaluation. Strong enough to punish loose pieces
/// and find short mates, gentle enough for casual players. To keep games
/// varied it picks at random among moves within 15 centipawns of its best.
///
/// Casual rules: if the player leaves their king exposed, the bot takes it.
///
/// [chessBotMove] is a top-level function so it can run in a background
/// isolate via `compute` — the board keeps animating while the bot thinks.
List<int> chessBotMove(List<int> encodedPosition) {
  final p = ChessPosition.decode(encodedPosition);
  // Casual rules: if the opponent left their king open, take it and win.
  for (final m in p.pseudoMoves()) {
    if (m.captured.abs() == ChessPiece.king) return m.encode();
  }
  final m = _Bot(Random()).best(p);
  return m.encode();
}

const int maxDepth = 4;
const int _timeBudgetMs = 1400;
const int _mate = 100000;
const _val = [0, 100, 320, 330, 500, 900, 0];

// Piece-square tables from White's point of view, row 0 = rank 8.
const _pst = <List<int>>[
  [],
  [0, 0, 0, 0, 0, 0, 0, 0, 50, 50, 50, 50, 50, 50, 50, 50, 10, 10, 20, 30, 30, 20, 10, 10, 5, 5, 10, 25, 25, 10, 5, 5, 0, 0, 0, 20, 20, 0, 0, 0, 5, -5, -10, 0, 0, -10, -5, 5, 5, 10, 10, -20, -20, 10, 10, 5, 0, 0, 0, 0, 0, 0, 0, 0],
  [-50, -40, -30, -30, -30, -30, -40, -50, -40, -20, 0, 0, 0, 0, -20, -40, -30, 0, 10, 15, 15, 10, 0, -30, -30, 5, 15, 20, 20, 15, 5, -30, -30, 0, 15, 20, 20, 15, 0, -30, -30, 5, 10, 15, 15, 10, 5, -30, -40, -20, 0, 5, 5, 0, -20, -40, -50, -40, -30, -30, -30, -30, -40, -50],
  [-20, -10, -10, -10, -10, -10, -10, -20, -10, 0, 0, 0, 0, 0, 0, -10, -10, 0, 5, 10, 10, 5, 0, -10, -10, 5, 5, 10, 10, 5, 5, -10, -10, 0, 10, 10, 10, 10, 0, -10, -10, 10, 10, 10, 10, 10, 10, -10, -10, 5, 0, 0, 0, 0, 5, -10, -20, -10, -10, -10, -10, -10, -10, -20],
  [0, 0, 0, 0, 0, 0, 0, 0, 5, 10, 10, 10, 10, 10, 10, 5, -5, 0, 0, 0, 0, 0, 0, -5, -5, 0, 0, 0, 0, 0, 0, -5, -5, 0, 0, 0, 0, 0, 0, -5, -5, 0, 0, 0, 0, 0, 0, -5, -5, 0, 0, 0, 0, 0, 0, -5, 0, 0, 0, 5, 5, 0, 0, 0],
  [-20, -10, -10, -5, -5, -10, -10, -20, -10, 0, 0, 0, 0, 0, 0, -10, -10, 0, 5, 5, 5, 5, 0, -10, -5, 0, 5, 5, 5, 5, 0, -5, 0, 0, 5, 5, 5, 5, 0, -5, -10, 5, 5, 5, 5, 5, 0, -10, -10, 0, 5, 0, 0, 0, 0, -10, -20, -10, -10, -5, -5, -10, -10, -20],
  [-30, -40, -40, -50, -50, -40, -40, -30, -30, -40, -40, -50, -50, -40, -40, -30, -30, -40, -40, -50, -50, -40, -40, -30, -30, -40, -40, -50, -50, -40, -40, -30, -20, -30, -30, -40, -40, -30, -30, -20, -10, -20, -20, -20, -20, -20, -20, -10, 20, 20, 0, 0, 0, 0, 20, 20, 20, 30, 10, 0, 0, 10, 30, 20],
];

class _Timeout implements Exception {}

class _Bot {
  final Random rng;
  _Bot(this.rng);

  late Stopwatch _clock;
  int _nodes = 0;

  int _evaluate(ChessPosition p) {
    var s = 0;
    final b = p.board;
    for (var sq = 0; sq < 64; sq++) {
      final v = b[sq];
      if (v == 0) continue;
      final t = v.abs();
      if (v > 0) {
        s += _val[t] + _pst[t][sq];
      } else {
        s -= _val[t] + _pst[t][(7 - sq ~/ 8) * 8 + sq % 8];
      }
    }
    return p.whiteToMove ? s : -s;
  }

  static int _orderScore(ChessMove m) =>
      (m.captured != 0 ? _val[m.captured.abs()] * 10 : 0) + (m.promo == ChessPiece.queen ? 8000 : 0);

  List<ChessMove> _ordered(List<ChessMove> ms) => ms..sort((a, b) => _orderScore(b) - _orderScore(a));

  void _tick() {
    if ((++_nodes & 1023) == 0 && _clock.elapsedMilliseconds > _timeBudgetMs) throw _Timeout();
  }

  int _quiesce(ChessPosition p, int alpha, int beta, int depth) {
    _tick();
    final standPat = _evaluate(p);
    if (standPat >= beta || depth == 0) return standPat;
    if (standPat > alpha) alpha = standPat;
    final moves = _ordered([for (final m in p.legalMoves()) if (m.captured != 0 || m.promo != 0) m]);
    for (final m in moves) {
      final s = -_quiesce(p.play(m), -beta, -alpha, depth - 1);
      if (s >= beta) return s;
      if (s > alpha) alpha = s;
    }
    return alpha;
  }

  int _search(ChessPosition p, int depth, int alpha, int beta, int ply) {
    _tick();
    final moves = p.legalMoves();
    if (moves.isEmpty) return p.inCheck() ? -_mate + ply : 0;
    if (depth == 0) return _quiesce(p, alpha, beta, 4);
    var best = -_mate * 2;
    for (final m in _ordered(moves)) {
      final s = -_search(p.play(m), depth - 1, -beta, -alpha, ply + 1);
      if (s > best) best = s;
      if (s > alpha) alpha = s;
      if (alpha >= beta) break;
    }
    return best;
  }

  ChessMove best(ChessPosition p) {
    _clock = Stopwatch()..start();
    final moves = _ordered(p.legalMoves());
    var choice = moves.first;
    for (var depth = 1; depth <= maxDepth; depth++) {
      try {
        final scored = <(int, ChessMove)>[];
        var alpha = -_mate * 2;
        for (final m in moves) {
          // Window keeps moves within 20cp of the best scored exactly enough
          // to pick among near-equals.
          final s = -_search(p.play(m), depth - 1, -_mate * 2, -(alpha - 20), 1);
          scored.add((s, m));
          if (s > alpha) alpha = s;
        }
        final top = scored.map((e) => e.$1).reduce(max);
        final near = top >= _mate - 1000
            ? [for (final e in scored) if (e.$1 == top) e.$2]
            : [for (final e in scored) if (e.$1 >= top - 15) e.$2];
        choice = near[rng.nextInt(near.length)];
        // Search the best moves first next iteration.
        moves.sort((a, b) {
          int sc(ChessMove m) => scored.firstWhere((e) => e.$2 == m).$1;
          return sc(b) - sc(a);
        });
        if (top >= _mate - 1000) break; // found a forced mate
      } on _Timeout {
        break;
      }
    }
    return choice;
  }
}
