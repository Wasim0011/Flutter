import 'package:flutter/material.dart';

void main() {
  runApp(const SamvaadApp());
}

class SamvaadApp extends StatelessWidget {
  const SamvaadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Samvaad',
      debugShowCheckedModeBanner: false,
      home: _FoundationPlaceholder(),
    );
  }
}

class _FoundationPlaceholder extends StatelessWidget {
  const _FoundationPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Samvaad — foundation build'),
      ),
    );
  }
}