import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/financeiro/venda_prazo_model.dart';
import '../auth_service.dart';
import '../../config/api_config.dart';

class VendaPrazoService {
  final AuthService _authService;

  VendaPrazoService(this._authService);

  String get _baseUrl => '${ApiConfig.baseUrl}/api/v1/financeiro/vendas-prazo';

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
      
      if (clienteId != null) queryParams['clienteId'] = clienteId;
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
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('🔍 buscarVenda resposta: historicoDetalhado=${data['historicoDetalhado']?.length ?? 'null'}');
        return VendaPrazo.fromJson(data);
      } else {
        print('❌ buscarVenda erro ${response.statusCode}: ${response.body}');
        throw Exception('Venda não encontrada');
      }
    } catch (e) {
      print('❌ buscarVenda exception: $e');
      throw Exception('Erro ao buscar venda: $e');
    }
  }

  Future<VendaPrazo> criarVenda({
    required String clienteId,
    required List<Map<String, dynamic>> produtos,
    required List<Map<String, dynamic>> parcelas,
    String? observacoes,
    String? formaPagamento,
  }) async {
    try {
      final body = {
        'clienteId': clienteId,
        'produtos': produtos,
        'parcelas': parcelas,
        'observacoes': observacoes,
      };
      
      if (formaPagamento != null) {
        body['formaPagamento'] = formaPagamento;
      }
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode(body),
      ).timeout(const Duration(minutes: 5));

      print('📥 Resposta criar venda a prazo - Status: ${response.statusCode}');
      print('   Headers: ${response.headers}');

      // Status 307 = Temporary Redirect - seguir o redirect manualmente
      if (response.statusCode == 307 || response.statusCode == 308) {
        final location = response.headers['location'];
        if (location != null) {
          print('🔄 Redirect detectado para: $location');
          final redirectResponse = await http.post(
            Uri.parse(location),
            headers: _headers,
            body: json.encode(body),
          ).timeout(const Duration(minutes: 5));
          
          if (redirectResponse.statusCode == 200 || redirectResponse.statusCode == 201) {
            return VendaPrazo.fromJson(json.decode(utf8.decode(redirectResponse.bodyBytes)));
          }
        }
      }

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

  // ========== CONTA MENSAL ==========

  Future<Map<String, dynamic>?> buscarContaAberta(String clienteId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/conta-mensal/conta-aberta/$clienteId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        // Se retornar null, não há conta aberta
        if (data == null) return null;
        return data as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        return null; // Não há conta aberta
      } else {
        throw Exception('Erro ao buscar conta aberta: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar conta aberta: $e');
    }
  }

  Future<Map<String, dynamic>> adicionarProdutosConta({
    required String clienteId,
    required List<Map<String, dynamic>> produtos,
    String? observacoes,
  }) async {
    try {
      final body = {
        'clienteId': clienteId,
        'produtos': produtos,
        'observacoes': observacoes,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/conta-mensal/adicionar-produtos'),
        headers: _headers,
        body: json.encode(body),
      ).timeout(const Duration(minutes: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erro ao adicionar produtos');
      }
    } catch (e) {
      throw Exception('Erro ao adicionar produtos: $e');
    }
  }

  Future<Map<String, dynamic>> fecharContaGerarParcelas({
    required String contaId,
    required List<Map<String, dynamic>> parcelas,
  }) async {
    try {
      final body = {
        'parcelas': parcelas,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/conta-mensal/fechar-conta/$contaId'),
        headers: _headers,
        body: json.encode(body),
      ).timeout(const Duration(minutes: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erro ao fechar conta');
      }
    } catch (e) {
      throw Exception('Erro ao fechar conta: $e');
    }
  }

  Future<List<Map<String, dynamic>>> listarContasAbertas({String? clienteId}) async {
    try {
      final queryParams = <String, String>{};
      if (clienteId != null) queryParams['cliente_id'] = clienteId;

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/conta-mensal/contas-abertas')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erro ao listar contas abertas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao listar contas abertas: $e');
    }
  }
}
