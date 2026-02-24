import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/cliente.dart';
import '../models/conta_receber.dart';
import '../models/pagamento.dart';

class ClientesApiService {
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

  // ========== CLIENTES ==========

  static Future<List<Cliente>> getClientes(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/clientes'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = _decodeResponse(response);
      return data.map((json) => Cliente.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar clientes');
    }
  }

  static Future<Cliente> getCliente(String token, int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/clientes/$id'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return Cliente.fromJson(_decodeResponse(response));
    } else {
      throw Exception('Erro ao buscar cliente');
    }
  }

  static Future<Cliente> criarCliente(String token, Cliente cliente) async {
    final response = await http.post(
      Uri.parse('$baseUrl/clientes'),
      headers: _getHeaders(token),
      body: _encodeBody(cliente.toJson()),
    );

    if (response.statusCode == 200) {
      return Cliente.fromJson(_decodeResponse(response));
    } else {
      final error = _decodeResponse(response);
      throw Exception(error['detail'] ?? 'Erro ao criar cliente');
    }
  }

  static Future<Cliente> atualizarCliente(
    String token,
    int id,
    Cliente cliente,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/clientes/$id'),
      headers: _getHeaders(token),
      body: _encodeBody(cliente.toJson()),
    );

    if (response.statusCode == 200) {
      return Cliente.fromJson(_decodeResponse(response));
    } else {
      final error = _decodeResponse(response);
      throw Exception(error['detail'] ?? 'Erro ao atualizar cliente');
    }
  }

  static Future<void> deletarCliente(String token, int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/clientes/$id'),
      headers: _getHeaders(token),
    );

    if (response.statusCode != 200) {
      final error = _decodeResponse(response);
      throw Exception(error['detail'] ?? 'Erro ao deletar cliente');
    }
  }

  // ========== CONTAS A RECEBER ==========

  static Future<List<ContaReceber>> getContasReceber(
    String token, {
    String? status,
    int? clienteId,
  }) async {
    var url = '$baseUrl/contas-receber';
    final params = <String>[];

    if (status != null) params.add('status=$status');
    if (clienteId != null) params.add('cliente_id=$clienteId');

    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = _decodeResponse(response);
      return data.map((json) => ContaReceber.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar contas a receber');
    }
  }

  static Future<ContaReceber> getContaReceber(String token, int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/contas-receber/$id'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return ContaReceber.fromJson(_decodeResponse(response));
    } else {
      throw Exception('Erro ao buscar conta');
    }
  }

  static Future<List<ContaReceber>> getContasVencidas(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/contas-receber/vencidas/list'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = _decodeResponse(response);
      return data.map((json) => ContaReceber.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar contas vencidas');
    }
  }

  static Future<int> getAlertasCount(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/contas-receber/alertas/count'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = _decodeResponse(response);
      return data['count'];
    } else {
      throw Exception('Erro ao buscar alertas');
    }
  }

  static Future<List<ContaReceber>> criarVendaPrazo(
    String token, {
    required int clienteId,
    required double valorTotal,
    required String descricao,
    required int numeroParcelas,
    required DateTime dataPrimeiraParcela,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/contas-receber/venda-prazo'),
      headers: _getHeaders(token),
      body: _encodeBody({
        'cliente_id': clienteId,
        'valor_total': valorTotal,
        'descricao': descricao,
        'numero_parcelas': numeroParcelas,
        'data_primeira_parcela': dataPrimeiraParcela.toIso8601String().split('T')[0],
      }),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = _decodeResponse(response);
      return data.map((json) => ContaReceber.fromJson(json)).toList();
    } else {
      final error = _decodeResponse(response);
      throw Exception(error['detail'] ?? 'Erro ao criar venda a prazo');
    }
  }

  static Future<Map<String, dynamic>> getTotalReceber(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/contas-receber/relatorios/total-receber'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw Exception('Erro ao buscar total a receber');
    }
  }

  // ========== RECEBIMENTOS ==========

  static Future<List<Pagamento>> getRecebimentos(
    String token, {
    int? contaId,
  }) async {
    var url = '$baseUrl/recebimentos';
    if (contaId != null) {
      url = '$baseUrl/recebimentos/conta/$contaId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = _decodeResponse(response);
      return data.map((json) => Pagamento.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar recebimentos');
    }
  }

  static Future<Pagamento> registrarRecebimento(
    String token,
    Pagamento pagamento,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recebimentos'),
      headers: _getHeaders(token),
      body: _encodeBody(pagamento.toJson('receber')),
    );

    if (response.statusCode == 200) {
      return Pagamento.fromJson(_decodeResponse(response));
    } else {
      final error = _decodeResponse(response);
      throw Exception(error['detail'] ?? 'Erro ao registrar recebimento');
    }
  }
}
