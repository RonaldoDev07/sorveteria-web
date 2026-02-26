import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/financeiro/venda_prazo_model.dart';
import '../../models/financeiro/compra_prazo_model.dart';
import '../auth_service.dart';
import '../../config/api_config.dart';

class RelatorioService {
  final AuthService _authService;

  RelatorioService(this._authService);

  String get _baseUrl => '${ApiConfig.baseUrl}/api/v1/financeiro/relatorios';

  Map<String, String> get _headers {
    final token = _authService.token;
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> contasReceber({
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (dataInicio != null) {
        queryParams['data_inicio'] = dataInicio.toIso8601String().split('T')[0];
      }
      if (dataFim != null) {
        queryParams['data_fim'] = dataFim.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse('$_baseUrl/contas-receber').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return {
          'vendas': (data['vendas'] as List).map((v) => VendaPrazo.fromJson(v)).toList(),
          'total_a_receber': (data['total_a_receber'] ?? 0).toDouble(),
          'total_recebido': (data['total_recebido'] ?? 0).toDouble(),
          'total_em_aberto': (data['total_em_aberto'] ?? 0).toDouble(),
          'contas_atrasadas': data['contas_atrasadas'] ?? 0,
        };
      } else {
        throw Exception('Erro ao buscar contas a receber');
      }
    } catch (e) {
      throw Exception('Erro: $e');
    }
  }

  Future<Map<String, dynamic>> contasPagar({
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (dataInicio != null) {
        queryParams['data_inicio'] = dataInicio.toIso8601String().split('T')[0];
      }
      if (dataFim != null) {
        queryParams['data_fim'] = dataFim.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse('$_baseUrl/contas-pagar').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return {
          'compras': (data['compras'] as List).map((c) => CompraPrazo.fromJson(c)).toList(),
          'total_a_pagar': (data['total_a_pagar'] ?? 0).toDouble(),
          'total_pago': (data['total_pago'] ?? 0).toDouble(),
          'total_em_aberto': (data['total_em_aberto'] ?? 0).toDouble(),
          'contas_atrasadas': data['contas_atrasadas'] ?? 0,
        };
      } else {
        throw Exception('Erro ao buscar contas a pagar');
      }
    } catch (e) {
      throw Exception('Erro: $e');
    }
  }
}
