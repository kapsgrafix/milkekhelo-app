/// Chess rules for Mil ke Khelo — pure Dart, no Flutter imports, so the
/// computer opponent can run it in a background isolate.
///
/// Board: 64 squares, index = row * 8 + col. Row 0 is rank 8 (Black's back
/// rank, top of the screen for White), row 7 is rank 1. Pieces are ints:
/// positive = White, negative = Black, 0 = empty (see [ChessPiece]).
///
/// Move generation was verified square-for-square against the standard
/// "perft" counts (start position to depth 4, Kiwipete and three other
/// tricky positions — castling, en passant, promotion, pins and checks).
///
/// The app plays CASUAL (over-the-board, "friendly") rules — see
/// [ChessGame]: every piece may make any move its pattern allows, even into
/// check or out of a pin, and whoever captures the enemy king wins. The
/// strict legal-move generator is still used to spot checkmate (game ends
/// at once) and by the bot.
library;

class ChessPiece {
  ChessPiece._();
  static const int pawn = 1, knight = 2, bishop = 3, rook = 4, queen = 5, king = 6;

  /// Material value in pawns (for the captured-pieces "+3" lead).
  static const List<int> value = [0, 1, 3, 3, 5, 9, 0];
}

class ChessMove {
  final int from;
  final int to;

  /// Promotion piece type (2–5) or 0.
  final int promo;

  /// The piece taken (signed), or 0.
  final int captured;
  final bool enPassant;
  final bool castle;

  const ChessMove(this.from, this.to, {this.promo = 0, this.captured = 0, this.enPassant = false, this.castle = false});

  bool get isCapture => captured != 0;

  /// Square of the captured piece (differs from [to] for en passant).
  int get captureSquare => enPassant ? (to ~/ 8 == 2 ? to + 8 : to - 8) : to;

  @override
  bool operator ==(Object other) =>
      other is ChessMove && other.from == from && other.to == to && other.promo == promo;

  @override
  int get hashCode => from * 4096 + to * 8 + promo;

  /// Compact form for passing to / from an isolate.
  List<int> encode() => [from, to, promo, captured, enPassant ? 1 : 0, castle ? 1 : 0];
  static ChessMove decode(List<int> e) =>
      ChessMove(e[0], e[1], promo: e[2], captured: e[3], enPassant: e[4] == 1, castle: e[5] == 1);
}

enum ChessResult { none, whiteWins, blackWins, stalemate, insufficient, fiftyMove, repetition }

const _kn = [[-2, -1], [-2, 1], [-1, -2], [-1, 2], [1, -2], [1, 2], [2, -1], [2, 1]];
const _kg = [[-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1]];
const _diag = [[-1, -1], [-1, 1], [1, -1], [1, 1]];
const _orth = [[-1, 0], [1, 0], [0, -1], [0, 1]];
const _all = [..._diag, ..._orth];

class ChessPosition {
  final List<int> board;
  bool whiteToMove;

  /// White king-side, White queen-side, Black king-side, Black queen-side.
  final List<bool> castling;
  int epSquare;
  int halfmoves;

  ChessPosition._(this.board, this.whiteToMove, this.castling, this.epSquare, this.halfmoves);

  factory ChessPosition.initial() {
    const back = [ChessPiece.rook, ChessPiece.knight, ChessPiece.bishop, ChessPiece.queen, ChessPiece.king, ChessPiece.bishop, ChessPiece.knight, ChessPiece.rook];
    final b = List<int>.filled(64, 0);
    for (var c = 0; c < 8; c++) {
      b[c] = -back[c];
      b[8 + c] = -ChessPiece.pawn;
      b[48 + c] = ChessPiece.pawn;
      b[56 + c] = back[c];
    }
    return ChessPosition._(b, true, [true, true, true, true], -1, 0);
  }

  ChessPosition copy() => ChessPosition._(List<int>.of(board), whiteToMove, List<bool>.of(castling), epSquare, halfmoves);

  // ───────── isolate transport ─────────

  List<int> encode() => [
        ...board,
        whiteToMove ? 1 : 0,
        for (final c in castling) c ? 1 : 0,
        epSquare,
        halfmoves,
      ];

  static ChessPosition decode(List<int> e) =>
      ChessPosition._(e.sublist(0, 64), e[64] == 1, [e[65] == 1, e[66] == 1, e[67] == 1, e[68] == 1], e[69], e[70]);

  /// Key for repetition detection (board, side, castling, en passant).
  String get key => '${board.join(',')}|$whiteToMove|$castling|$epSquare';

  // ───────── queries ─────────

  int kingSquare(bool white) => board.indexOf(white ? ChessPiece.king : -ChessPiece.king);

  static bool _on(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

  bool attacked(int sq, bool byWhite) {
    final r = sq ~/ 8, c = sq % 8, sg = byWhite ? 1 : -1;
    final pr = byWhite ? r + 1 : r - 1;
    if (pr >= 0 && pr < 8) {
      for (final dc in const [-1, 1]) {
        final cc = c + dc;
        if (cc >= 0 && cc < 8 && board[pr * 8 + cc] == sg * ChessPiece.pawn) return true;
      }
    }
    for (final d in _kn) {
      final rr = r + d[0], cc = c + d[1];
      if (_on(rr, cc) && board[rr * 8 + cc] == sg * ChessPiece.knight) return true;
    }
    for (final d in _kg) {
      final rr = r + d[0], cc = c + d[1];
      if (_on(rr, cc) && board[rr * 8 + cc] == sg * ChessPiece.king) return true;
    }
    if (_slides(r, c, _diag, sg * ChessPiece.bishop, sg * ChessPiece.queen)) return true;
    if (_slides(r, c, _orth, sg * ChessPiece.rook, sg * ChessPiece.queen)) return true;
    return false;
  }

  bool _slides(int r, int c, List<List<int>> dirs, int a, int b) {
    for (final d in dirs) {
      var rr = r + d[0], cc = c + d[1];
      while (_on(rr, cc)) {
        final v = board[rr * 8 + cc];
        if (v != 0) {
          if (v == a || v == b) return true;
          break;
        }
        rr += d[0];
        cc += d[1];
      }
    }
    return false;
  }

  bool inCheck([bool? white]) {
    final w = white ?? whiteToMove;
    final k = kingSquare(w);
    return k >= 0 && attacked(k, !w);
  }

  // ───────── move generation ─────────

  /// Every move each piece's pattern allows (ignores check). With
  /// [relaxedCastling], castling only needs the rights and an empty path —
  /// it may start from, pass through or land in check (casual rules).
  List<ChessMove> pseudoMoves({bool relaxedCastling = false}) {
    final out = <ChessMove>[];
    final w = whiteToMove, sg = w ? 1 : -1;
    for (var sq = 0; sq < 64; sq++) {
      final v = board[sq];
      if (v == 0 || (v > 0) != w) continue;
      final t = v.abs(), r = sq ~/ 8, c = sq % 8;
      if (t == ChessPiece.pawn) {
        final d = w ? -1 : 1, start = w ? 6 : 1, last = w ? 0 : 7;
        final rr = r + d;
        if (rr >= 0 && rr < 8 && board[rr * 8 + c] == 0) {
          _addPawn(out, sq, rr * 8 + c, 0, rr == last);
          if (r == start && board[(r + 2 * d) * 8 + c] == 0) out.add(ChessMove(sq, (r + 2 * d) * 8 + c));
        }
        for (final dc in const [-1, 1]) {
          final cc = c + dc;
          if (rr >= 0 && rr < 8 && cc >= 0 && cc < 8) {
            final to = rr * 8 + cc, tv = board[to];
            if (tv != 0 && (tv > 0) != w) {
              _addPawn(out, sq, to, tv, rr == last);
            } else if (to == epSquare) {
              out.add(ChessMove(sq, to, captured: -sg * ChessPiece.pawn, enPassant: true));
            }
          }
        }
      } else if (t == ChessPiece.knight || t == ChessPiece.king) {
        for (final d in t == ChessPiece.knight ? _kn : _kg) {
          final rr = r + d[0], cc = c + d[1];
          if (!_on(rr, cc)) continue;
          final tv = board[rr * 8 + cc];
          if (tv == 0 || (tv > 0) != w) out.add(ChessMove(sq, rr * 8 + cc, captured: tv));
        }
        if (t == ChessPiece.king) _castles(out, sq, relaxed: relaxedCastling);
      } else {
        final dirs = t == ChessPiece.bishop ? _diag : (t == ChessPiece.rook ? _orth : _all);
        for (final d in dirs) {
          var rr = r + d[0], cc = c + d[1];
          while (_on(rr, cc)) {
            final tv = board[rr * 8 + cc];
            if (tv == 0) {
              out.add(ChessMove(sq, rr * 8 + cc));
            } else {
              if ((tv > 0) != w) out.add(ChessMove(sq, rr * 8 + cc, captured: tv));
              break;
            }
            rr += d[0];
            cc += d[1];
          }
        }
      }
    }
    return out;
  }

  void _addPawn(List<ChessMove> out, int from, int to, int cap, bool promo) {
    if (promo) {
      for (final p in const [ChessPiece.queen, ChessPiece.rook, ChessPiece.bishop, ChessPiece.knight]) {
        out.add(ChessMove(from, to, promo: p, captured: cap));
      }
    } else {
      out.add(ChessMove(from, to, captured: cap));
    }
  }

  void _castles(List<ChessMove> out, int sq, {bool relaxed = false}) {
    final w = whiteToMove, home = w ? 60 : 4;
    if (sq != home) return;
    final ki = w ? 0 : 2, qi = w ? 1 : 3, rook = w ? ChessPiece.rook : -ChessPiece.rook;
    if (!relaxed && inCheck(w)) return;
    bool safe(int s) => relaxed || !attacked(s, !w);
    if (castling[ki] &&
        board[home + 1] == 0 &&
        board[home + 2] == 0 &&
        board[home + 3] == rook &&
        safe(home + 1) &&
        safe(home + 2)) {
      out.add(ChessMove(home, home + 2, castle: true));
    }
    if (castling[qi] &&
        board[home - 1] == 0 &&
        board[home - 2] == 0 &&
        board[home - 3] == 0 &&
        board[home - 4] == rook &&
        safe(home - 1) &&
        safe(home - 2)) {
      out.add(ChessMove(home, home - 2, castle: true));
    }
  }

  /// The position after [m] (this one is untouched).
  ChessPosition play(ChessMove m) {
    final p = copy();
    final b = p.board, v = b[m.from], w = whiteToMove;
    b[m.to] = v;
    b[m.from] = 0;
    if (m.enPassant) b[m.to + (w ? 8 : -8)] = 0;
    if (m.promo != 0) b[m.to] = w ? m.promo : -m.promo;
    if (m.castle) {
      if (m.to > m.from) {
        b[m.from + 1] = b[m.from + 3];
        b[m.from + 3] = 0;
      } else {
        b[m.from - 1] = b[m.from - 4];
        b[m.from - 4] = 0;
      }
    }
    p.epSquare = (v.abs() == ChessPiece.pawn && (m.to - m.from).abs() == 16) ? (m.to + m.from) ~/ 2 : -1;
    if (v.abs() == ChessPiece.king) {
      if (w) {
        p.castling[0] = p.castling[1] = false;
      } else {
        p.castling[2] = p.castling[3] = false;
      }
    }
    const corners = [63, 56, 7, 0];
    for (var i = 0; i < 4; i++) {
      if (m.from == corners[i] || m.to == corners[i]) p.castling[i] = false;
    }
    p.halfmoves = (v.abs() == ChessPiece.pawn || m.captured != 0) ? 0 : halfmoves + 1;
    p.whiteToMove = !w;
    return p;
  }

  List<ChessMove> legalMoves() {
    final out = <ChessMove>[];
    for (final m in pseudoMoves()) {
      if (!play(m).inCheck(whiteToMove)) out.add(m);
    }
    return out;
  }

  /// Only bare kings, or king + one minor piece vs king, or king + bishop
  /// vs king + bishop on the same colour — nobody can force mate.
  bool get insufficientMaterial {
    final minors = <int>[];
    for (var sq = 0; sq < 64; sq++) {
      final t = board[sq].abs();
      if (t == 0 || t == ChessPiece.king) continue;
      if (t == ChessPiece.pawn || t == ChessPiece.rook || t == ChessPiece.queen) return false;
      minors.add(sq);
    }
    if (minors.length <= 1) return true;
    if (minors.length == 2 &&
        board[minors[0]].abs() == ChessPiece.bishop &&
        board[minors[1]].abs() == ChessPiece.bishop &&
        (board[minors[0]] > 0) != (board[minors[1]] > 0)) {
      int colour(int sq) => (sq ~/ 8 + sq % 8) % 2;
      return colour(minors[0]) == colour(minors[1]);
    }
    return false;
  }
}

/// A whole game under CASUAL rules: position + history + result.
///
///   • Moves: any pattern move ([ChessPosition.pseudoMoves], relaxed
///     castling) — you may move into check or leave your king exposed.
///   • Capturing the enemy king wins on the spot ([kingCaptured]).
///   • Checkmate (no move can save the king) also ends the game at once.
///   • Draws: stalemate, bare kings / not enough material, 50 moves without
///     a capture or pawn move, or the same position three times.
class ChessGame {
  ChessPosition position = ChessPosition.initial();
  final List<ChessMove> moves = [];
  final Map<String, int> _seen = {};
  ChessResult result = ChessResult.none;
  List<ChessMove> _playable = const [];

  /// The game ended because a king was taken (not by checkmate).
  bool kingCaptured = false;

  ChessGame() {
    _seen[position.key] = 1;
    _playable = position.pseudoMoves(relaxedCastling: true);
  }

  bool get over => result != ChessResult.none;
  bool get whiteToMove => position.whiteToMove;
  List<ChessMove> get playableMoves => _playable;
  ChessMove? get lastMove => moves.isEmpty ? null : moves.last;
  bool get inCheck => position.inCheck();

  List<ChessMove> movesFrom(int sq) => [for (final m in _playable) if (m.from == sq) m];

  void apply(ChessMove m) {
    final moverWhite = position.whiteToMove;
    position = position.play(m);
    moves.add(m);
    if (m.captured.abs() == ChessPiece.king) {
      kingCaptured = true;
      result = moverWhite ? ChessResult.whiteWins : ChessResult.blackWins;
      _playable = const [];
      return;
    }
    final k = position.key;
    _seen[k] = (_seen[k] ?? 0) + 1;
    _playable = position.pseudoMoves(relaxedCastling: true);
    final safe = position.legalMoves();
    if (safe.isEmpty) {
      result = position.inCheck()
          ? (position.whiteToMove ? ChessResult.blackWins : ChessResult.whiteWins)
          : ChessResult.stalemate;
    } else if (position.insufficientMaterial) {
      result = ChessResult.insufficient;
    } else if (position.halfmoves >= 100) {
      result = ChessResult.fiftyMove;
    } else if (_seen[k]! >= 3) {
      result = ChessResult.repetition;
    }
  }
}

