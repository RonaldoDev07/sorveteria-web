import 'dart:async';
import 'package:flutter/material.dart';

/// Mixin para adicionar refresh automático em telas
/// Atualiza os dados a cada 30 segundos automaticamente
mixin AutoRefreshMixin<T extends StatefulWidget> on State<T> {
  Timer? _refreshTimer;
  
  /// Duração entre cada refresh automático (padrão: 30 segundos)
  Duration get refreshInterval => const Duration(seconds: 30);
  
  /// Método que deve ser implementado para carregar os dados
  Future<void> loadData();
  
  /// Inicia o timer de refresh automático
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(refreshInterval, (_) {
      if (mounted) {
        loadData();
      }
    });
  }
  
  /// Para o timer de refresh automático
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
  
  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
