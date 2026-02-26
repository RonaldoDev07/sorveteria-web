import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/financeiro/fornecedor_model.dart';
import '../auth_service.dart';
import '../../config/api_config.dart';

/// Service para gerenciar fornecedores via API
class FornecedorService {
  final AuthService _authService;

  FornecedorService(this._authService);

  String get _baseUrl => '${ApiConfig.baseUrl}/api/v1/financeiro/fornecedores';

  Map<String, String> get _headers {
    final token = _authService.token;
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  /// Lista todos os fornecedores
  Future<List<Fornecedor>> listarFornecedores({
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
        return data.map((json) => Fornecedor.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao listar fornecedores: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com a API: $e');
    }
  }

  /// Busca um fornecedor por ID
  Future<Fornecedor> buscarFornecedor(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return Fornecedor.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Fornecedor não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar fornecedor: $e');
    }
  }

  /// Cria um novo fornecedor
  Future<Fornecedor> criarFornecedor(Fornecedor fornecedor) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode(fornecedor.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Fornecedor.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erro ao criar fornecedor');
      }
    } catch (e) {
      throw Exception('Erro ao criar fornecedor: $e');
    }
  }

  /// Atualiza um fornecedor existente
  Future<Fornecedor> atualizarFornecedor(String id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$id'),
        headers: _headers,
        body: json.encode(dados),
      );

      if (response.statusCode == 200) {
        return Fornecedor.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erro ao atualizar fornecedor');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar fornecedor: $e');
    }
  }

  /// Deleta um fornecedor (soft delete)
  Future<void> deletarFornecedor(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erro ao deletar fornecedor');
      }
    } catch (e) {
      throw Exception('Erro ao deletar fornecedor: $e');
    }
  }
}
