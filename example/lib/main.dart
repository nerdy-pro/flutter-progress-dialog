import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_future_progress_dialog/flutter_future_progress_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Progress Dialog Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExamplePage(),
    );
  }
}

Future<String> _successTask() async {
  await Future.delayed(const Duration(seconds: 2));
  return 'Task completed';
}

Future<String> _failingTask() async {
  await Future.delayed(const Duration(seconds: 2));
  throw Exception('Something went wrong');
}

class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key});

  void _showResult(BuildContext context, ProgressDialogResult<String> result) {
    final message = switch (result) {
      Success(:final value) => value,
      Failure(:final error) => 'Error: $error',
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onMaterial(BuildContext context) async {
    final result = await showProgressDialog(
      context: context,
      future: () => _successTask(),
    );
    if (!context.mounted) return;
    _showResult(context, result);
  }

  Future<void> _onCupertino(BuildContext context) async {
    final result = await showCupertinoProgressDialog(
      context: context,
      future: () => _successTask(),
    );
    if (!context.mounted) return;
    _showResult(context, result);
  }

  Future<void> _onCustom(BuildContext context) async {
    final result = await showProgressDialog(
      context: context,
      future: () => _successTask(),
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoActivityIndicator(),
              SizedBox(width: 16),
              Text('Please wait...'),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    _showResult(context, result);
  }

  Future<void> _onFailure(BuildContext context) async {
    final result = await showProgressDialog(
      context: context,
      future: () => _failingTask(),
    );
    if (!context.mounted) return;
    _showResult(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Progress Dialog Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            FilledButton(
              onPressed: () => _onMaterial(context),
              child: const Text('Material'),
            ),
            FilledButton(
              onPressed: () => _onCupertino(context),
              child: const Text('Cupertino'),
            ),
            FilledButton(
              onPressed: () => _onCustom(context),
              child: const Text('Custom dialog'),
            ),
            FilledButton.tonal(
              onPressed: () => _onFailure(context),
              child: const Text('Failure'),
            ),
          ],
        ),
      ),
    );
  }
}
