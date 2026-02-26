import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/financeiro/parcela_model.dart';
import '../auth_service.dart';
import '../../config/api_config.dart';

class ParcelaService {
  final AuthService _authService;

  ParcelaService(this._authService);

  String get _baseUrl => '${ApiConfig.baseUrl}/financeiro/parcelas';

  Map<String, String> get _headers {
    final token = _authService.token;
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Parcela>> listarParcelas({
    String? tipo,
    String? status,
    String? referenciaId,
    DateTime? vencimentoAte,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };
      
      if (tipo != null) queryParams['tipo'] = tipo;
      if (status != null) queryParams['status'] = status;
      if (referenciaId != null) queryParams['referencia_id'] = referenciaId;
      if (vencimentoAte != null) {
        queryParams['vencimento_ate'] = vencimentoAte.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Parcela.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao listar parcelas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com a API: $e');
    }
  }

  Future<Parcela> buscarParcela(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return Parcela.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Parcela não encontrada');
      }
    } catch (e) {
      throw Exception('Erro ao buscar parcela: $e');
    }
  }

  Future<void> darBaixaParcela(String id, double valorPago, String formaPagamento) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$id/baixa'),
        headers: _headers,
        body: json.encode({
          'valor_pago': valorPago,
          'forma_pagamento': formaPagamento,
        }),
      );

      if (response.statusCode != 200) {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erro ao dar baixa na parcela');
      }
    } catch (e) {
      throw Exception('Erro ao dar baixa: $e');
    }
  }
}
