import 'package:flutter/cupertino.dart' as cupertino;
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
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

enum DialogType {
  material,
  cupertino,
  adaptive,
  customMaterial,
  customCupertino
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  Future<int> myFuture(int value) async {
    await Future.delayed(const Duration(seconds: 1));
    if (value >= 5) {
      throw 'Something went wrong';
    }
    return value + 1;
  }

  Future<void> _showError({
    required BuildContext context,
    required String error,
  }) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(
            error,
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _counter = 0;
                });
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  Future<void> _onIncrementCounter({
    required BuildContext context,
    required DialogType dialogType,
  }) async {
    final future = switch (dialogType) {
      DialogType.cupertino => showCupertinoProgressDialog(
          context: context,
          future: () => myFuture(_counter),
        ),
      DialogType.material => showProgressDialog(
          context: context,
          future: () => myFuture(_counter),
        ),
      DialogType.adaptive => showAdaptiveProgressDialog(
          context: context,
          future: () => myFuture(_counter),
        ),
      DialogType.customMaterial => showProgressDialog(
          context: context,
          builder: (context) => const Dialog(
            child: cupertino.Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Loading...'),
            ),
          ),
          future: () => myFuture(_counter),
        ),
      DialogType.customCupertino => showCupertinoProgressDialog(
          context: context,
          builder: (context) => const cupertino.CupertinoAlertDialog(
            content: cupertino.Text('Loading...'),
          ),
          future: () => myFuture(_counter),
        ),
    };
    final result = await future;
    if (!context.mounted) {
      return;
    }
    switch (result) {
      case Success<int>(value: final value):
        setState(() {
          _counter = value;
        });
        break;
      case Failure(error: final error):
        _showError(context: context, error: error.toString()).ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Your Future will return result here',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'counter: $_counter',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 4,
              children: [
                TextButton(
                  onPressed: () => _onIncrementCounter(
                    context: context,
                    dialogType: DialogType.material,
                  ),
                  child: const Text('Material'),
                ),
                TextButton(
                  onPressed: () => _onIncrementCounter(
                    context: context,
                    dialogType: DialogType.cupertino,
                  ),
                  child: const Text('Cupertino'),
                ),
                TextButton(
                  onPressed: () => _onIncrementCounter(
                    context: context,
                    dialogType: DialogType.adaptive,
                  ),
                  child: const Text('Adaptive'),
                ),
                TextButton(
                  onPressed: () => _onIncrementCounter(
                    context: context,
                    dialogType: DialogType.customMaterial,
                  ),
                  child: const Text('Custom Material'),
                ),
                TextButton(
                  onPressed: () => _onIncrementCounter(
                    context: context,
                    dialogType: DialogType.customCupertino,
                  ),
                  child: const Text('Custom cupertino'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
