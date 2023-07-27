import 'package:flutter/material.dart';
import 'package:progress_dialog/flutter_progress_dialog.dart';

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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _yourFutureResult = '';

  Future<void> myFuture() async {
    await Future<void>.delayed(const Duration(seconds: 2), () => _counter++);
    if (_counter < 3) {
      setState(() {
        _counter;
        _yourFutureResult = 'Result $_counter';
      });
    } else {
      throw 'Error: Something went wrong';
    }
  }

  Future _onIncrementCounter(BuildContext context) async {
    final result = await showProgressDialog(
      context: context,
      future: () => myFuture(),
    );
    if (!mounted) {
      return;
    }
    if (result.isError) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              content: Text(
                '${result.requireError}',
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _counter = 0;
                      _yourFutureResult = '';
                    });
                  },
                  child: const Text(
                    'OK',
                  ),
                )
              ]);
        },
      );
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
              _yourFutureResult,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _onIncrementCounter(context);
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
