import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/financeiro/fornecedor_model.dart';
import '../auth_service.dart';
import '../../config/api_config.dart';

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

  Future<List<Fornecedor>> listarFornecedores({int skip = 0, int limit = 100}) async {
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

  Future<Fornecedor> criarFornecedor(Fornecedor fornecedor) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode(fornecedor.toJson()),
      ).timeout(const Duration(minutes: 5));

      if (response.statusCode == 307 || response.statusCode == 308) {
        final location = response.headers['location'];
        if (location != null) {
          final redirectResponse = await http.post(
            Uri.parse(location),
            headers: _headers,
            body: json.encode(fornecedor.toJson()),
          ).timeout(const Duration(minutes: 5));
          if (redirectResponse.statusCode == 200 || redirectResponse.statusCode == 201) {
            return Fornecedor.fromJson(json.decode(utf8.decode(redirectResponse.bodyBytes)));
          }
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Fornecedor.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? error['message'] ?? 'Erro ao criar fornecedor');
      }
    } catch (e) {
      throw Exception('Erro ao criar fornecedor: $e');
    }
  }

  Future<Fornecedor> atualizarFornecedor(String id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$id'),
        headers: _headers,
        body: json.encode(dados),
      ).timeout(const Duration(minutes: 5));

      if (response.statusCode == 307 || response.statusCode == 308) {
        final location = response.headers['location'];
        if (location != null) {
          final redirectResponse = await http.put(
            Uri.parse(location),
            headers: _headers,
            body: json.encode(dados),
          ).timeout(const Duration(minutes: 5));
          if (redirectResponse.statusCode == 200) {
            return Fornecedor.fromJson(json.decode(utf8.decode(redirectResponse.bodyBytes)));
          }
        }
      }

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
