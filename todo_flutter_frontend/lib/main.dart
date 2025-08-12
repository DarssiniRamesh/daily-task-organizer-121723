import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/todo_provider.dart';
import 'ui/todo_page.dart';

void main() {
  runApp(const MyApp());
}

/// PUBLIC_INTERFACE
class MyApp extends StatelessWidget {
  /// Root of the Todo Flutter app. Sets up theming and providers.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const figmaPrimary = Color(0xFF9395D3);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TodoProvider()),
      ],
      child: MaterialApp(
        title: 'TODO APP',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: figmaPrimary, brightness: Brightness.light),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFD6D7EF),
          appBarTheme: const AppBarTheme(
            backgroundColor: figmaPrimary,
            foregroundColor: Colors.white,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: figmaPrimary,
            foregroundColor: Colors.white,
          ),
        ),
        home: const TodoPage(),
      ),
    );
  }
}
