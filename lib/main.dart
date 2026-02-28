import 'package:flutter/material.dart';

void main() {
  runApp(const NoteFlowApp());
}

class NoteFlowApp extends StatelessWidget {
  const NoteFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NoteFlow',
      home: Scaffold(
        body: Center(
          child: Text('NoteFlow'),
        ),
      ),
    );
  }
}
