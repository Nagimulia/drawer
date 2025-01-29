import 'dart:typed_data';
import 'package:drawer/features/draw/models/stroke.dart';
import 'package:drawer/features/utils/thumbnail_helper.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  List<Stroke> _strokes = [];
  List<Stroke> _redoStokes = [];
  List<Offset> _currentPoints = [];
  Color _selectedColor = Colors.black;
  double _brushSize = 4.0;
  late Box<Map<dynamic, dynamic>> _drawingBox;

  String? _drawingName;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHive();
    });
    super.initState();
  }

  Future<void> _initializeHive() async {
    _drawingBox = Hive.box<Map<dynamic, dynamic>>('drawings');

    final name = ModalRoute.of(context)?.settings.arguments as String?;
    if (name != null) {
      final rawData = _drawingBox.get(name);
      setState(() {
        _drawingName = name;
        _strokes =
            (rawData?['strokes'] as List<dynamic>?)?.cast<Stroke>() ?? [];
      });
    }
  }

  Future<void> _saveDrawing(String name) async {
    // generate thumbnail
    final Uint8List thumbnail = await generateThumbnail(_strokes, 200, 200);
    await _drawingBox.put(name, {'strokes': _strokes, 'thumbnail': thumbnail});
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Drawing $name saved')));
  }

  void _showSaveDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Save Drawing'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: 'Enter drawing name'),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel')),
              TextButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isNotEmpty) {
                      setState(() {
                        _drawingName = name;
                      });
                      _saveDrawing(name);
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('Save')),
            ],
          );
        });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_drawingName ?? 'Draw Your Dream'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _currentPoints.add(details.localPosition);
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _currentPoints.add(details.localPosition);
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _strokes.add(
                    Stroke.fromOffsets(
                      color: _selectedColor,
                      brushSize: _brushSize,
                      points: List.from(_currentPoints),
                    ),
                  );
                  _currentPoints = [];
                  _redoStokes = [];
                });
              },
              child: CustomPaint(
                painter: DrawPainter(
                  strokes: _strokes,
                  currentPoints: _currentPoints,
                  currentColor: _selectedColor,
                  currentBrushSize: _brushSize,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          _buildToolBar(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSaveDialog,
        child: Icon(Icons.save),
      ),
    );
  }

  Widget _buildToolBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _strokes.isNotEmpty
                ? () {
                    setState(() {
                      _redoStokes.add(_strokes.removeLast());
                    });
                  }
                : null,
            icon: Icon(Icons.undo),
          ),
          IconButton(
            onPressed: _redoStokes.isNotEmpty
                ? () {
                    setState(() {
                      _strokes.add(_redoStokes.removeLast());
                    });
                  }
                : null,
            icon: Icon(Icons.redo),
          ),

          // выбрать размер кисти
          DropdownButton(
              value: _brushSize,
              items: [
                DropdownMenuItem(
                  value: 2.0,
                  child: Text('Small'),
                ),
                DropdownMenuItem(
                  value: 4.0,
                  child: Text('Medium'),
                ),
                DropdownMenuItem(
                  value: 6.0,
                  child: Text('Big'),
                ),
                DropdownMenuItem(
                  value: 8.0,
                  child: Text('Large'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _brushSize = value!;
                });
              }),
          // палитра цветов
          Row(
            children: [
              _buildColorButton(Colors.black),
              _buildColorButton(Colors.brown),
              _buildColorButton(Colors.red),
              _buildColorButton(Colors.pinkAccent),
              _buildColorButton(Colors.purple),
              _buildColorButton(Colors.deepOrange),
              _buildColorButton(Colors.white),
              _buildColorButton(Colors.green),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: _selectedColor == color
                  ? Colors.blueGrey
                  : Colors.transparent,
            )),
      ),
    );
  }
}

class DrawPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentBrushSize;

  DrawPainter(
      {super.repaint,
      required this.strokes,
      required this.currentPoints,
      required this.currentColor,
      required this.currentBrushSize});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.strokeColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke.brushSize;

      final points = stroke.offsetPoints;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
          canvas.drawLine(points[i], points[i + 1], paint);
        }
      }
    }
    final paint = Paint()
      ..color = currentColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = currentBrushSize;
    for (int i = 0; i < currentPoints.length - 1; i++) {
      if (currentPoints[i] != Offset.zero &&
          currentPoints[i + 1] != Offset.zero) {
        canvas.drawLine(currentPoints[i], currentPoints[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
