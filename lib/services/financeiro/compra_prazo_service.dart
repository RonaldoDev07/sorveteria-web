import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/financeiro/compra_prazo_model.dart';
import '../auth_service.dart';
import '../../config/api_config.dart';

class CompraPrazoService {
  final AuthService _authService;

  CompraPrazoService(this._authService);

  String get _baseUrl => '${ApiConfig.baseUrl}/api/v1/financeiro/compras-prazo';

  Map<String, String> get _headers {
    final token = _authService.token;
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<CompraPrazo>> listarCompras({
    String? fornecedorId,
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
      
      if (fornecedorId != null) queryParams['fornecedorId'] = fornecedorId;
      if (status != null) queryParams['status'] = status;
      if (dataInicio != null) {
        queryParams['dataInicio'] = dataInicio.toIso8601String().split('T')[0];
      }
      if (dataFim != null) {
        queryParams['dataFim'] = dataFim.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => CompraPrazo.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao listar compras: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com a API: $e');
    }
  }

  Future<CompraPrazo> criarCompra({
    required String fornecedorId,
    required List<Map<String, dynamic>> produtos,
    required List<Map<String, dynamic>> parcelas,
    String? observacoes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode({
          'fornecedorId': fornecedorId,
          'produtos': produtos,
          'parcelas': parcelas,
          'observacoes': observacoes,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CompraPrazo.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erro ao criar compra');
      }
    } catch (e) {
      throw Exception('Erro ao criar compra: $e');
    }
  }

  Future<void> cancelarCompra(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erro ao cancelar compra');
      }
    } catch (e) {
      throw Exception('Erro ao cancelar compra: $e');
    }
  }
}
