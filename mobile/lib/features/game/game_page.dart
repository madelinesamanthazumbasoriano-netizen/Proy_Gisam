import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/gisam_economy.dart';

enum _MiniGame { tetris, puzzle }

class GamePage extends StatefulWidget {
  final GisamEconomy economy;

  const GamePage({super.key, required this.economy});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  static const _roundLength = 45;
  static const _progressPerBar = 10;
  static const _rows = 18;
  static const _columns = 10;
  static const _pieceShapes = [
    [math.Point<int>(0, 0), math.Point<int>(1, 0), math.Point<int>(0, 1), math.Point<int>(1, 1)],
    [math.Point<int>(0, 0), math.Point<int>(1, 0), math.Point<int>(2, 0), math.Point<int>(3, 0)],
    [math.Point<int>(1, 0), math.Point<int>(0, 1), math.Point<int>(1, 1), math.Point<int>(2, 1)],
    [math.Point<int>(1, 0), math.Point<int>(2, 0), math.Point<int>(0, 1), math.Point<int>(1, 1)],
    [math.Point<int>(0, 0), math.Point<int>(1, 0), math.Point<int>(1, 1), math.Point<int>(2, 1)],
    [math.Point<int>(0, 0), math.Point<int>(0, 1), math.Point<int>(1, 1), math.Point<int>(2, 1)],
    [math.Point<int>(2, 0), math.Point<int>(0, 1), math.Point<int>(1, 1), math.Point<int>(2, 1)],
  ];
  static const _pieceColors = [
    Colors.transparent,
    Color(0xFF69C8D0),
    Color(0xFFF1D36B),
    Color(0xFF9B85D6),
    Color(0xFF75B985),
    Color(0xFFE57C96),
    Color(0xFF668DD1),
    Color(0xFFE79B61),
  ];

  Timer? _roundTimer;
  Timer? _fallTimer;
  _MiniGame _selectedGame = _MiniGame.tetris;
  List<List<int>> _board = [];
  List<int> _puzzle = [];
  List<math.Point<int>> _piece = _pieceShapes.first;
  int _pieceX = 3;
  int _pieceY = 0;
  int _pieceColor = 1;
  int _puzzleSize = 3;
  int _puzzleLevel = 1;
  int _secondsRemaining = _roundLength;
  int _score = 0;
  bool _playing = false;
  bool _starting = false;
  bool _savingReward = false;
  bool _gameOver = false;
  int? _lastReward;
  String? _roundId;

  int get _filledBars => _score ~/ _progressPerBar;
  int get _barProgress => _score % _progressPerBar;

  @override
  void initState() {
    super.initState();
    _prepareRound();
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _fallTimer?.cancel();
    super.dispose();
  }

  void _prepareRound() {
    _score = 0;
    _secondsRemaining = _roundLength;
    _gameOver = false;
    _board = List.generate(
      _rows,
      (_) => List<int>.filled(_columns, 0),
    );
    _puzzleLevel = 1;
    _puzzle = _createPuzzle(_puzzleLevel);
    _spawnPiece();
  }

  Future<void> _start() async {
    _roundTimer?.cancel();
    _fallTimer?.cancel();
    setState(() => _starting = true);
    try {
      final roundId = await widget.economy.startMiniGame();
      if (!mounted) return;
      setState(() {
        _roundId = roundId;
        _lastReward = null;
        _prepareRound();
        _playing = true;
        _starting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _starting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo iniciar la partida: $error')),
      );
      return;
    }

    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        unawaited(_finishRound());
      } else if (mounted) {
        setState(() => _secondsRemaining--);
      }
    });
    _fallTimer = Timer.periodic(const Duration(milliseconds: 550), (_) {
      if (_selectedGame == _MiniGame.tetris) _fallPiece();
    });
  }

  Future<void> _finishRound() async {
    if (!mounted) return;
    final roundId = _roundId;
    if (roundId == null) return;
    _fallTimer?.cancel();
    setState(() {
      _secondsRemaining = 0;
      _playing = false;
      _savingReward = true;
    });
    try {
      final reward = await widget.economy.completeMiniGame(
        score: _score,
        roundId: roundId,
      );
      if (!mounted) return;
      setState(() {
        _lastReward = reward;
        _savingReward = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reward > 0
                ? '¡Buen trabajo! Ganaste $reward monedas.'
                : 'Completa al menos media barra para ganar monedas.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _savingReward = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se guardó la recompensa: $error')),
      );
    }
  }

  List<int> _createPuzzle(int level) {
    final size = level < 4 ? 3 : level < 7 ? 4 : 5;
    _puzzleSize = size;
    final tiles = List<int>.generate(size * size, (index) {
      return index == size * size - 1 ? 0 : index + 1;
    });
    var emptyIndex = tiles.length - 1;
    var previousIndex = -1;
    final random = math.Random();
    final shuffleSteps = math.min(size * size, 8 + level * 2);

    for (var step = 0; step < shuffleSteps; step++) {
      final choices = _neighbors(emptyIndex, size)
          .where((index) => index != previousIndex)
          .toList();
      final nextIndex = choices[random.nextInt(choices.length)];
      tiles[emptyIndex] = tiles[nextIndex];
      tiles[nextIndex] = 0;
      previousIndex = emptyIndex;
      emptyIndex = nextIndex;
    }
    return tiles;
  }

  List<int> _neighbors(int index, int size) {
    final row = index ~/ size;
    final column = index % size;
    return [
      if (row > 0) index - size,
      if (row < size - 1) index + size,
      if (column > 0) index - 1,
      if (column < size - 1) index + 1,
    ];
  }

  void _movePuzzleTile(int index) {
    if (!_playing) return;
    final emptyIndex = _puzzle.indexOf(0);
    final sameRow = index ~/ _puzzleSize == emptyIndex ~/ _puzzleSize &&
        (index - emptyIndex).abs() == 1;
    final sameColumn = index % _puzzleSize == emptyIndex % _puzzleSize &&
        (index - emptyIndex).abs() == _puzzleSize;
    if (!sameRow && !sameColumn) return;

    setState(() {
      _puzzle[emptyIndex] = _puzzle[index];
      _puzzle[index] = 0;
      if (_isPuzzleSolved()) {
        _score = (_score + _progressPerBar).clamp(0, 300).toInt();
        _puzzleLevel++;
        _puzzle = _createPuzzle(_puzzleLevel);
      }
    });
  }

  bool _isPuzzleSolved() {
    for (var index = 0; index < _puzzle.length - 1; index++) {
      if (_puzzle[index] != index + 1) return false;
    }
    return _puzzle.last == 0;
  }

  void _spawnPiece() {
    final random = math.Random();
    _piece = _pieceShapes[random.nextInt(_pieceShapes.length)];
    _pieceColor = 1 + random.nextInt(_pieceColors.length - 1);
    _pieceX = _columns ~/ 2 - 1;
    _pieceY = 0;
  }

  bool _canPlace(int x, int y, List<math.Point<int>> shape) {
    for (final cell in shape) {
      final column = x + cell.x;
      final row = y + cell.y;
      if (column < 0 || column >= _columns || row < 0 || row >= _rows) {
        return false;
      }
      if (_board[row][column] != 0) return false;
    }
    return true;
  }

  void _fallPiece() {
    if (!_playing || _gameOver) return;
    if (_canPlace(_pieceX, _pieceY + 1, _piece)) {
      setState(() => _pieceY++);
    } else {
      setState(_lockPiece);
    }
  }

  void _movePiece(int dx, int dy) {
    if (!_playing || _gameOver) return;
    final nextX = _pieceX + dx;
    final nextY = _pieceY + dy;
    if (_canPlace(nextX, nextY, _piece)) {
      setState(() {
        _pieceX = nextX;
        _pieceY = nextY;
      });
    } else if (dy > 0) {
      setState(_lockPiece);
    }
  }

  void _rotatePiece() {
    if (!_playing || _gameOver) return;
    final rotated = _piece
        .map((cell) => math.Point<int>(-cell.y, cell.x))
        .toList();
    final minX = rotated.map((cell) => cell.x).reduce(math.min);
    final minY = rotated.map((cell) => cell.y).reduce(math.min);
    final normalized = rotated
        .map((cell) => math.Point<int>(cell.x - minX, cell.y - minY))
        .toList();
    if (_canPlace(_pieceX, _pieceY, normalized)) {
      setState(() => _piece = normalized);
    }
  }

  void _lockPiece() {
    final nextBoard = _board.map((row) => List<int>.of(row)).toList();
    for (final cell in _piece) {
      final column = _pieceX + cell.x;
      final row = _pieceY + cell.y;
      if (row >= 0 && row < _rows && column >= 0 && column < _columns) {
        nextBoard[row][column] = _pieceColor;
      }
    }

    final remainingRows =
        nextBoard.where((row) => row.any((cell) => cell == 0)).toList();
    final clearedRows = _rows - remainingRows.length;
    _board = [
      ...List.generate(_rows - remainingRows.length, (_) => List<int>.filled(_columns, 0)),
      ...remainingRows,
    ];
    if (clearedRows > 0) {
      _score = (_score + clearedRows * _progressPerBar).clamp(0, 300).toInt();
    }
    _spawnPiece();
    if (!_canPlace(_pieceX, _pieceY, _piece)) _gameOver = true;
  }

  Color _cellColor(int row, int column) {
    final fixedColor = _board[row][column];
    if (fixedColor != 0) return _pieceColors[fixedColor];
    if (_piece.any(
      (cell) => _pieceX + cell.x == column && _pieceY + cell.y == row,
    )) {
      return _pieceColors[_pieceColor];
    }
    return const Color(0xFFF2EAF2);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.economy,
        builder: (context, _) {
          final colors = Theme.of(context).colorScheme;
          return Scaffold(
            appBar: AppBar(title: const Text('Minijuegos')),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Juega y gana monedas',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Elige un juego. Cada barra completa suma monedas a tu '
                  'recompensa al terminar la partida.',
                ),
                const SizedBox(height: 16),
                SegmentedButton<_MiniGame>(
                  segments: const [
                    ButtonSegment(
                      value: _MiniGame.tetris,
                      icon: Icon(Icons.grid_view_rounded),
                      label: Text('Tetris'),
                    ),
                    ButtonSegment(
                      value: _MiniGame.puzzle,
                      icon: Icon(Icons.extension_rounded),
                      label: Text('Puzzle'),
                    ),
                  ],
                  selected: {_selectedGame},
                  onSelectionChanged:
                      _playing || _starting || _savingReward
                          ? null
                          : (selection) =>
                              setState(() => _selectedGame = selection.first),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${widget.economy.coins} 🪙',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$_secondsRemaining s',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Puntos: $_score'),
                            Text('Barras llenas: $_filledBars'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _barProgress / _progressPerBar,
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _barProgress == 0
                              ? 'Barra lista · cada barra adicional suma 5 monedas'
                              : '$_barProgress de $_progressPerBar puntos para llenar la barra',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (_selectedGame == _MiniGame.tetris)
                          _buildTetris(colors)
                        else
                          _buildPuzzle(colors),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _playing || _starting || _savingReward
                              ? null
                              : _start,
                          icon: Icon(
                            _playing ? Icons.hourglass_top : Icons.play_arrow,
                          ),
                          label: Text(
                            _playing
                                ? '¡Sigue jugando!'
                                : _starting
                                    ? 'Preparando partida...'
                                    : _lastReward == null
                                        ? 'Empezar partida'
                                        : 'Jugar otra vez',
                          ),
                        ),
                        if (_lastReward != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Recompensa de esta partida: $_lastReward monedas',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.tips_and_updates_outlined),
                    title: Text('Cómo ganar'),
                    subtitle: Text(
                      'En Tetris, cada línea completa llena una barra. En el '
                      'puzzle, completa niveles. 5–9 puntos dan 8 monedas; '
                      'una barra da 15 y cada barra extra suma 5. '
                      'La recompensa se entrega al terminar.',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildTetris(ColorScheme colors) {
    if (!_playing) {
      return Container(
        width: 230,
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_view_rounded, size: 54),
            SizedBox(height: 8),
            Text('Completa líneas para llenar la barra'),
          ],
        ),
      );
    }

    final boardWidth = math.min(
      280.0,
      MediaQuery.sizeOf(context).width - 88,
    ).toDouble();
    return Column(
      children: [
        Center(
          child: SizedBox(
            width: boardWidth,
            child: AspectRatio(
              aspectRatio: _columns / _rows,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _rows * _columns,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _columns,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final row = index ~/ _columns;
                  final column = index % _columns;
                  return Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: _cellColor(row, column),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: const Color(0x1F60445D),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (_gameOver)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('¡Tablero lleno! Tu partida sigue contando.'),
          ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            IconButton.filledTonal(
              tooltip: 'Mover izquierda',
              onPressed: _playing && !_gameOver ? () => _movePiece(-1, 0) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton.filledTonal(
              tooltip: 'Bajar pieza',
              onPressed: _playing && !_gameOver ? () => _movePiece(0, 1) : null,
              icon: const Icon(Icons.keyboard_double_arrow_down),
            ),
            IconButton.filledTonal(
              tooltip: 'Mover derecha',
              onPressed: _playing && !_gameOver ? () => _movePiece(1, 0) : null,
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton.filledTonal(
              tooltip: 'Girar pieza',
              onPressed: _playing && !_gameOver ? _rotatePiece : null,
              icon: const Icon(Icons.rotate_right),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPuzzle(ColorScheme colors) {
    if (!_playing) {
      return Container(
        width: 230,
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.extension_rounded, size: 54),
            SizedBox(height: 8),
            Text('Ordena las piezas y avanza de nivel'),
          ],
        ),
      );
    }

    final boardWidth = math.min(
      310.0,
      MediaQuery.sizeOf(context).width - 64,
    ).toDouble();
    return Column(
      children: [
        Text(
          'Nivel $_puzzleLevel · ${_puzzleSize}×$_puzzleSize',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Center(
          child: SizedBox(
            width: boardWidth,
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _puzzle.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _puzzleSize,
                ),
                itemBuilder: (context, index) {
                  final tile = _puzzle[index];
                  return Padding(
                    padding: const EdgeInsets.all(3),
                    child: tile == 0
                        ? const SizedBox.expand()
                        : Material(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: () => _movePuzzleTile(index),
                              borderRadius: BorderRadius.circular(10),
                              child: Center(
                                child: Text(
                                  '$tile',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colors.onPrimaryContainer,
                                      ),
                                ),
                              ),
                            ),
                          ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
