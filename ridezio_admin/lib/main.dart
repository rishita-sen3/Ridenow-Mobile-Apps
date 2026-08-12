import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/providers.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authCheck = ref.watch(authCheckProvider);
    final isAuthenticated = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Ridezio Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authCheck.when(
        data: (_) => isAuthenticated ? const MainLayout() : const LoginScreen(),
        loading: () => const SplashScreen(),
        error: (_, _) => const LoginScreen(),
      ),
    );
  }
}
