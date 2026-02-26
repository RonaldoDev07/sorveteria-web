import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        // Se está autenticado, mostra a home
        if (auth.isAuthenticated) {
          return const HomeScreen();
        }
        
        // Se não está autenticado, mostra splash (que vai para login)
        return const SplashScreen();
      },
    );
  }
}