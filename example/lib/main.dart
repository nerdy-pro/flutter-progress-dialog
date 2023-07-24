import 'package:flutter/material.dart';
import 'package:progress_dialog/progress_dialog.dart';

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

  Future<void> myFuture() async {
    await Future<void>.delayed(const Duration(seconds: 2), () => _counter++);
    if (_counter < 3) {
      setState(() {
        _counter;
      });
    } else {
      throw 'error';
    }
  }

  Future<Result<T>?> showProgressDialog<T>({
    required BuildContext context,
    required Future<T> Function() future,
    bool cancelOnTapOutside = true,
    bool useRootNavigator = true,
  }) async {
    final result = await showDialog<Result<T>>(
      barrierDismissible: cancelOnTapOutside,
      useRootNavigator: useRootNavigator,
      context: context,
      builder: (context) => ProgressBarDialog<T>(future: future),
    );
    return result;
  }

  Future _onIncrementCounter(BuildContext context) async {
    final result = await showProgressDialog(
      context: context,
      future: () => myFuture(),
    );
    if (!mounted || result == null) {
      return;
    }
    if (result.isError) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              content: Text(
                '${result.requireError}',
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
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
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
