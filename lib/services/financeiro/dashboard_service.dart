import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/financeiro/dashboard_model.dart';
import '../auth_service.dart';
import '../../config/api_config.dart';

/// Service para buscar dados do dashboard financeiro
class DashboardService {
  final AuthService _authService;

  DashboardService(this._authService);

  String get _baseUrl => '${ApiConfig.baseUrl}/api/v1/financeiro/relatorios/dashboard';

  Map<String, String> get _headers {
    final token = _authService.token;
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  /// Busca dados do dashboard
  Future<DashboardFinanceiro> buscarDashboard() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return DashboardFinanceiro.fromJson(data);
      } else {
        throw Exception('Erro ao buscar dashboard: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com a API: $e');
    }
  }
}
