import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'widgets/auth_wrapper.dart';

void main() {
  // Capturar erros do Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('Flutter Error: ${details.exception}');
      print('Stack trace: ${details.stack}');
    }
  };

  // Capturar erros assíncronos não tratados
  runZonedGuarded(
    () {
      runApp(
        ChangeNotifierProvider(
          create: (_) => AuthService(),
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      if (kDebugMode) {
        print('Uncaught error: $error');
        print('Stack trace: $stack');
      }
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sorveteria Camila',
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      // Tratamento de erros de navegação
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Ops! Algo deu errado',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (kDebugMode)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        errorDetails.exception.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Recarregar a página
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const AuthWrapper()),
                      );
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        };
        return widget!;
      },
    );
  }
}
