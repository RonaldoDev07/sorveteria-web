import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/financeiro/venda_prazo_model.dart';
import '../../models/financeiro/compra_prazo_model.dart';
import '../auth_service.dart';
import '../../config/api_config.dart';

// Função helper para parsing defensivo de números
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

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
        queryParams['dataInicio'] = dataInicio.toIso8601String().split('T')[0];
      }
      if (dataFim != null) {
        queryParams['dataFim'] = dataFim.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse('$_baseUrl/contas-receber').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return {
          'vendas': (data['vendas'] as List).map((v) => VendaPrazo.fromJson(v)).toList(),
          'total_a_receber': _toDouble(data['total_a_receber']),
          'total_recebido': _toDouble(data['total_recebido']),
          'total_em_aberto': _toDouble(data['total_em_aberto']),
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
        queryParams['dataInicio'] = dataInicio.toIso8601String().split('T')[0];
      }
      if (dataFim != null) {
        queryParams['dataFim'] = dataFim.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse('$_baseUrl/contas-pagar').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return {
          'compras': (data['compras'] as List).map((c) => CompraPrazo.fromJson(c)).toList(),
          'total_a_pagar': _toDouble(data['total_a_pagar']),
          'total_pago': _toDouble(data['total_pago']),
          'total_em_aberto': _toDouble(data['total_em_aberto']),
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
