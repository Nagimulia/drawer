import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<Map<dynamic, dynamic>> _drawingBox;

  @override
  void initState() {
    _initializeHive();
    super.initState();
  }

  Future<void> _initializeHive() async {
    _drawingBox = Hive.box<Map<dynamic, dynamic>>('drawings');

    setState(() {});
  }

  void _deleteDrawing(String name) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Delete Drawing'),
              content: Text('Are you sure you want to delete $name'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Delete')),
              ],
            ));

    if (confirm == true) {
      _drawingBox.delete(name);
      setState(() {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Drawing $name delete')));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawingNames = _drawingBox.keys.cast<String>().toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('My Drawing'),
      ),
      body: drawingNames.isEmpty
          ? Center(
              child: Text('No drawing saved yet'),
            )
          : GridView.builder(
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: drawingNames.length,
              itemBuilder: (context, index) {
                final name = drawingNames[index];
                final data = _drawingBox.get(name) as Map;
                final thumbnail = data['thumbnail'] as Uint8List;

                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/draw', arguments: name);
                      },
                      child: Card(
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Image.memory(
                                thumbnail,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(5),
                              child: Text(
                                name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                            onPressed: () => _deleteDrawing(name),
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red,
                            )))
                  ],
                );
              }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/draw');
          setState(() {});
        },
        child: Icon(Icons.draw),
      ),
    );
  }
}
