import 'package:flutter/material.dart';

void main() {
    runApp(const MyApp());
}

class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'DukaStock',
        theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        ),
        home: const MyHomePage(title: 'DukaStock'),
        );
    }
}

class _MyHomePageState extends State<MyHomePage> {
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
        children: [
        const Text(
                'Welcome to DukaStock!',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        ],
        ),
        ),
        );
    }
