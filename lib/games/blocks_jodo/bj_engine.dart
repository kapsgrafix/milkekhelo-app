import 'dart:math';
import 'dart:ui';

import 'bj_data.dart';

/// Rows and columns that are (or would be) complete.
class BjLines {
  final List<int> rows;
  final List<int> cols;
  const BjLines(this.rows, this.cols);

  static const empty = BjLines([], []);

  int get count => rows.length + cols.length;
  bool get isEmpty => count == 0;

  /// Every board index covered by these lines.
  Set<int> get indices {
    const n = BjData.size;
    return {
      for (final r in rows)
        for (var c = 0; c < n; c++) r * n + c,
      for (final c in cols)
        for (var r = 0; r < n; r++) r * n + c,
    };
  }
}

/// Pure game logic — no Flutter widgets, so it stays easy to reason about.
class BjBoard {
  static const int n = BjData.size;

  /// Colour of the block in each cell, or null when empty. Index = r * n + c.
  final List<Color?> cells = List<Color?>.filled(n * n, null);

  bool get isEmpty => cells.every((c) => c == null);

  void reset() => cells.fillRange(0, cells.length, null);

  bool canPlace(BjPiece p, int row, int col) {
    if (row < 0 || col < 0 || row + p.rows > n || col + p.cols > n) return false;
    for (final cell in p.cells) {
      if (cells[(row + cell.r) * n + col + cell.c] != null) return false;
    }
    return true;
  }

  List<int> indicesFor(BjPiece p, int row, int col) =>
      [for (final cell in p.cells) (row + cell.r) * n + col + cell.c];

  bool fitsAnywhere(BjPiece p) {
    for (var r = 0; r <= n - p.rows; r++) {
      for (var c = 0; c <= n - p.cols; c++) {
        if (canPlace(p, r, c)) return true;
      }
    }
    return false;
  }

  /// Lines that would be complete if [extra] cells were also filled.
  BjLines linesWith(Iterable<int> extra) {
    final filled = Set<int>.from(extra);
    bool on(int i) => cells[i] != null || filled.contains(i);
    final rows = <int>[];
    final cols = <int>[];
    for (var r = 0; r < n; r++) {
      var full = true;
      for (var c = 0; c < n && full; c++) {
        full = on(r * n + c);
      }
      if (full) rows.add(r);
    }
    if (BjData.clearColumns) {
      for (var c = 0; c < n; c++) {
        var full = true;
        for (var r = 0; r < n && full; r++) {
          full = on(r * n + c);
        }
        if (full) cols.add(c);
      }
    }
    return BjLines(rows, cols);
  }

  /// Places the piece and returns the indices it filled.
  List<int> place(BjPiece p, int row, int col) {
    final idx = indicesFor(p, row, col);
    for (final i in idx) {
      cells[i] = p.color;
    }
    return idx;
  }

  /// Empties the given cells; returns each removed cell's colour.
  Map<int, Color> clear(Iterable<int> idx) {
    final out = <int, Color>{};
    for (final i in idx) {
      final c = cells[i];
      if (c != null) out[i] = c;
      cells[i] = null;
    }
    return out;
  }

  /// The [count] fullest rows/columns (for the "rescue" when a life is lost).
  BjLines fullestLines(int count) {
    final scored = <({bool row, int i, int filled})>[];
    for (var k = 0; k < n; k++) {
      var rf = 0, cf = 0;
      for (var j = 0; j < n; j++) {
        if (cells[k * n + j] != null) rf++;
        if (cells[j * n + k] != null) cf++;
      }
      scored.add((row: true, i: k, filled: rf));
      if (BjData.clearColumns) scored.add((row: false, i: k, filled: cf));
    }
    scored.sort((a, b) => b.filled.compareTo(a.filled));
    final pick = scored.where((s) => s.filled > 0).take(count);
    return BjLines(
      [for (final s in pick) if (s.row) s.i],
      [for (final s in pick) if (!s.row) s.i],
    );
  }
}

/// Deals pieces the way Block Blast does: random but fair — every new set
/// of three always contains at least one piece that fits.
class BjDealer {
  final Random _rng = Random();
  late final double _total = bjShapes.fold(0.0, (s, e) => s + e.weight);

  BjShape _randomShape() {
    var x = _rng.nextDouble() * _total;
    for (final s in bjShapes) {
      x -= s.weight;
      if (x <= 0) return s;
    }
    return bjShapes.last;
  }

  Color _randomColor(Set<Color> avoid) {
    final options = BjData.blockColors.where((c) => !avoid.contains(c)).toList();
    final pool = options.isEmpty ? BjData.blockColors : options;
    return pool[_rng.nextInt(pool.length)];
  }

  List<BjPiece> deal(BjBoard board) {
    for (var attempt = 0; attempt < 40; attempt++) {
      final shapes = <BjShape>[];
      while (shapes.length < 3) {
        final s = _randomShape();
        if (!shapes.contains(s)) shapes.add(s);
      }
      final used = <Color>{};
      final pieces = [
        for (final s in shapes)
          () {
            final c = _randomColor(used);
            used.add(c);
            return BjPiece(s, c);
          }(),
      ];
      if (pieces.any(board.fitsAnywhere)) return pieces;
    }
    return rescueSet(board);
  }

  /// Small pieces that are guaranteed to fit (a single block always fits
  /// because a completely full board would already have been cleared).
  List<BjPiece> rescueSet(BjBoard board) {
    final small = bjShapes.where((s) => s.cells.length <= 3).toList()..shuffle(_rng);
    final fitting = small.where((s) => board.fitsAnywhere(BjPiece(s, BjData.blockColors[0]))).toList();
    final picks = <BjShape>[...fitting.take(3)];
    while (picks.length < 3) {
      picks.add(bjShapes.first);
    }
    final used = <Color>{};
    return [
      for (final s in picks)
        () {
          final c = _randomColor(used);
          used.add(c);
          return BjPiece(s, c);
        }(),
    ];
  }
}
