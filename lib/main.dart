import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/categories/presentation/categories_screen.dart';

void main() {
  runApp(
    // ProviderScope is Riverpod's root — wraps the entire widget tree.
    const ProviderScope(
      child: ParkApp(),
    ),
  );
}

class ParkApp extends StatelessWidget {
  const ParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seyil-Et!',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const CategoriesScreen(),
    );
  }
}
