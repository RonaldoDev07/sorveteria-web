import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/fornecedor.dart';
import '../models/conta_pagar.dart';
import '../models/pagamento.dart';

class FornecedoresApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  static Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $token',
    };
  }

  static dynamic _decodeResponse(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static List<int> _encodeBody(Map<String, dynamic> body) {
    return utf8.encode(jsonEncode(body));
  }

  // ========== FORNECEDORES ==========

  static Future<List<Fornecedor>> getFornecedores(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fornecedores'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = _decodeResponse(response);
      return data.map((json) => Fornecedor.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar fornecedores');
    }
  }

  static Future<Fornecedor> getFornecedor(String token, int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fornecedores/$id'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return Fornecedor.fromJson(_decodeResponse(response));
    } else {
      throw Exception('Erro ao buscar fornecedor');
    }
  }

  static Future<Fornecedor> criarFornecedor(
    String token,
    Fornecedor fornecedor,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fornecedores'),
      headers: _getHeaders(token),
      body: _encodeBody(fornecedor.toJson()),
    );

    if (response.statusCode == 200) {
      return Fornecedor.fromJson(_decodeResponse(response));
    } else {
      final error = _decodeResponse(response);
      throw Exception(error['detail'] ?? 'Erro ao criar fornecedor');
    }
  }

  static Future<Fornecedor> atualizarFornecedor(
    String token,
    int id,
    Fornecedor fornecedor,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/fornecedores/$id'),
      headers: _getHeaders(token),
      body: _encodeBody(fornecedor.toJson()),
    );

    if (response.statusCode == 200) {
      return Fornecedor.fromJson(_decodeResponse(response));
    } else {
      final error = _decodeResponse(response);
      throw Exception(error['detail'] ?? 'Erro ao atualizar fornecedor');
    }
  }

  static Future<void> deletarFornecedor(String token, int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/fornecedores/$id'),
      headers: _getHeaders(token),
    );

    if (response.statusCode != 200) {
      final error = _decodeResponse(response);
      throw Exception(error['detail'] ?? 'Erro ao deletar fornecedor');
    }
  }

  // ========== CONTAS A PAGAR ==========

  static Future<List<ContaPagar>> getContasPagar(
    String token, {
    String? status,
    int? fornecedorId,
  }) async {
    var url = '$baseUrl/contas-pagar';
    final params = <String>[];

    if (status != null) params.add('status=$status');
    if (fornecedorId != null) params.add('fornecedor_id=$fornecedorId');

    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = _decodeResponse(response);
      return data.map((json) => ContaPagar.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar contas a pagar');
    }
  }

  static Future<ContaPagar> getContaPagar(String token, int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/contas-pagar/$id'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return ContaPagar.fromJson(_decodeResponse(response));
    } else {
      throw Exception('Erro ao buscar conta');
    }
  }

  static Future<List<ContaPagar>> getContasVencidas(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/contas-pagar/vencidas/list'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = _decodeResponse(response);
      return data.map((json) => ContaPagar.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar contas vencidas');
    }
  }

  static Future<int> getAlertasCount(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/contas-pagar/alertas/count'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = _decodeResponse(response);
      return data['count'];
    } else {
      throw Exception('Erro ao buscar alertas');
    }
  }

  static Future<List<ContaPagar>> criarCompraPrazo(
    String token, {
    required int fornecedorId,
    required double valorTotal,
    required String descricao,
    required int numeroParcelas,
    required DateTime dataPrimeiraParcela,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/contas-pagar/compra-prazo'),
      headers: _getHeaders(token),
      body: _encodeBody({
        'fornecedor_id': fornecedorId,
        'valor_total': valorTotal,
        'descricao': descricao,
        'numero_parcelas': numeroParcelas,
        'data_primeira_parcela': dataPrimeiraParcela.toIso8601String().split('T')[0],
      }),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = _decodeResponse(response);
      return data.map((json) => ContaPagar.fromJson(json)).toList();
    } else {
      final error = _decodeResponse(response);
      throw Exception(error['detail'] ?? 'Erro ao criar compra a prazo');
    }
  }

  static Future<Map<String, dynamic>> getTotalPagar(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/contas-pagar/relatorios/total-pagar'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw Exception('Erro ao buscar total a pagar');
    }
  }

  // ========== PAGAMENTOS ==========

  static Future<List<Pagamento>> getPagamentos(
    String token, {
    int? contaId,
  }) async {
    var url = '$baseUrl/pagamentos-fornecedor';
    if (contaId != null) {
      url = '$baseUrl/pagamentos-fornecedor/conta/$contaId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = _decodeResponse(response);
      return data.map((json) => Pagamento.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar pagamentos');
    }
  }

  static Future<Pagamento> registrarPagamento(
    String token,
    Pagamento pagamento,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pagamentos-fornecedor'),
      headers: _getHeaders(token),
      body: _encodeBody(pagamento.toJson('pagar')),
    );

    if (response.statusCode == 200) {
      return Pagamento.fromJson(_decodeResponse(response));
    } else {
      final error = _decodeResponse(response);
      throw Exception(error['detail'] ?? 'Erro ao registrar pagamento');
    }
  }
}
