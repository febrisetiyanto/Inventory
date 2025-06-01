import 'package:flutter/material.dart';
import 'package:inventory/pages/spalshscreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lqoppcixzcidychqklal.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxxb3BwY2l4emNpZHljaHFrbGFsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxODM4MDgsImV4cCI6MjA2Mzc1OTgwOH0.mzNZbBwOH0QKNNDra5cqRwgIw3IKlX7ZeVJoqiq7TkE',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen()
    );
  }
}
