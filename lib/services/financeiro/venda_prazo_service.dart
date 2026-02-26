import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/financeiro/venda_prazo_model.dart';
import '../auth_service.dart';
import '../../config/api_config.dart';

class VendaPrazoService {
  final AuthService _authService;

  VendaPrazoService(this._authService);

  String get _baseUrl => '${ApiConfig.baseUrl}/financeiro/vendas-prazo';

  Map<String, String> get _headers {
    final token = _authService.token;
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<VendaPrazo>> listarVendas({
    String? clienteId,
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };
      
      if (clienteId != null) queryParams['cliente_id'] = clienteId;
      if (status != null) queryParams['status'] = status;
      if (dataInicio != null) {
        queryParams['data_inicio'] = dataInicio.toIso8601String().split('T')[0];
      }
      if (dataFim != null) {
        queryParams['data_fim'] = dataFim.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => VendaPrazo.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao listar vendas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com a API: $e');
    }
  }

  Future<VendaPrazo> buscarVenda(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return VendaPrazo.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Venda não encontrada');
      }
    } catch (e) {
      throw Exception('Erro ao buscar venda: $e');
    }
  }

  Future<VendaPrazo> criarVenda({
    required String clienteId,
    required List<Map<String, dynamic>> produtos,
    required List<Map<String, dynamic>> parcelas,
    String? observacoes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode({
          'cliente_id': clienteId,
          'produtos': produtos,
          'parcelas': parcelas,
          'observacoes': observacoes,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return VendaPrazo.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erro ao criar venda');
      }
    } catch (e) {
      throw Exception('Erro ao criar venda: $e');
    }
  }

  Future<void> cancelarVenda(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erro ao cancelar venda');
      }
    } catch (e) {
      throw Exception('Erro ao cancelar venda: $e');
    }
  }
}
