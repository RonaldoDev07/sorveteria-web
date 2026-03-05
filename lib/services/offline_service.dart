import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineService extends ChangeNotifier {
  bool _isOnline = true;
  List<Map<String, dynamic>> _operacoesPendentes = [];
  final Connectivity _connectivity = Connectivity();

  bool get isOnline => _isOnline;
  int get operacoesPendentesCount => _operacoesPendentes.length;

  OfflineService() {
    _initConnectivity();
    _carregarOperacoesPendentes();
  }

  Future<void> _initConnectivity() async {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
      
      // Se voltou online, sincronizar
      if (wasOffline && _isOnline) {
        sincronizar();
      }
    });

    // Verificar status inicial
    final results = await _connectivity.checkConnectivity();
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    _isOnline = result != ConnectivityResult.none;
    notifyListeners();
  }

  Future<void> _carregarOperacoesPendentes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? operacoesJson = prefs.getString('operacoes_pendentes');
      if (operacoesJson != null) {
        final List<dynamic> operacoes = jsonDecode(operacoesJson);
        _operacoesPendentes = operacoes.cast<Map<String, dynamic>>();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar operações pendentes: $e');
      }
    }
  }

  Future<void> _salvarOperacoesPendentes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String operacoesJson = jsonEncode(_operacoesPendentes);
      await prefs.setString('operacoes_pendentes', operacoesJson);
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar operações pendentes: $e');
      }
    }
  }

  Future<void> adicionarOperacaoPendente(Map<String, dynamic> operacao) async {
    _operacoesPendentes.add({
      ...operacao,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _salvarOperacoesPendentes();
    notifyListeners();
  }

  Future<void> sincronizar() async {
    if (!_isOnline || _operacoesPendentes.isEmpty) return;

    // Aqui você implementaria a lógica de sincronização com o backend
    // Por enquanto, vamos apenas limpar as operações pendentes
    // Em produção, você enviaria cada operação para o servidor
    
    if (kDebugMode) {
      print('Sincronizando ${_operacoesPendentes.length} operações...');
    }

    // TODO: Implementar sincronização real com o backend
    // for (var operacao in _operacoesPendentes) {
    //   await enviarParaServidor(operacao);
    // }

    _operacoesPendentes.clear();
    await _salvarOperacoesPendentes();
    notifyListeners();
  }

  Future<void> limparOperacoesPendentes() async {
    _operacoesPendentes.clear();
    await _salvarOperacoesPendentes();
    notifyListeners();
  }
}
