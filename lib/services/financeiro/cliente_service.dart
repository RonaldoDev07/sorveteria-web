import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/financeiro/cliente_model.dart';
import '../auth_service.dart';
import '../../config/api_config.dart';

/// Service para gerenciar clientes via API
class ClienteService {
  final AuthService _authService;

  ClienteService(this._authService);

  String get _baseUrl => '${ApiConfig.baseUrl}/api/v1/financeiro/clientes';

  Map<String, String> get _headers {
    final token = _authService.token;
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  /// Lista todos os clientes
  Future<List<Cliente>> listarClientes({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?skip=$skip&limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Cliente.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao listar clientes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com a API: $e');
    }
  }

  /// Busca um cliente por ID
  Future<Cliente> buscarCliente(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return Cliente.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Cliente não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar cliente: $e');
    }
  }

  /// Cria um novo cliente
  Future<Cliente> criarCliente(Cliente cliente) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode(cliente.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Cliente.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erro ao criar cliente');
      }
    } catch (e) {
      throw Exception('Erro ao criar cliente: $e');
    }
  }

  /// Atualiza um cliente existente
  Future<Cliente> atualizarCliente(String id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$id'),
        headers: _headers,
        body: json.encode(dados),
      );

      if (response.statusCode == 200) {
        return Cliente.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erro ao atualizar cliente');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar cliente: $e');
    }
  }

  /// Deleta um cliente (soft delete)
  Future<void> deletarCliente(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erro ao deletar cliente');
      }
    } catch (e) {
      throw Exception('Erro ao deletar cliente: $e');
    }
  }
}
