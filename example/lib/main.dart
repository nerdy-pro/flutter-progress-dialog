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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  Future<int> myFuture() async {
    await Future.delayed(const Duration(seconds: 2));
    if (_counter >= 3) {
      throw 'Something went wrong';
    }
    return _counter + 1;
  }

  Future<void> _onIncrementCounter(BuildContext context) async {
    final result = await showProgressDialog(
      context: context,
      future: () => myFuture(),
    );
    if (!mounted) {
      return;
    }
    switch (result) {
      case ResultOk<int>(value: final value):
        setState(() {
          _counter = value;
        });
        break;
      case ResultError(error: final error):
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(
                '$error',
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
                  child: const Text(
                    'OK',
                  ),
                )
              ],
            );
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
              '_counter: $_counter',
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
