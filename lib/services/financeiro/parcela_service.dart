import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/financeiro/parcela_model.dart';
import '../auth_service.dart';
import '../../config/api_config.dart';

class ParcelaService {
  final AuthService _authService;

  ParcelaService(this._authService);

  String get _baseUrl => '${ApiConfig.baseUrl}/api/v1/financeiro/parcelas';

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
      print('🔄 Listando parcelas...');
      print('📋 Parâmetros: tipo=$tipo, status=$status, referenciaId=$referenciaId');
      
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };
      
      if (tipo != null) queryParams['tipo'] = tipo;
      if (status != null) queryParams['status'] = status;
      if (referenciaId != null) queryParams['referencia_id'] = referenciaId;
      if (vencimentoAte != null) {
        queryParams['vencimentoAte'] = vencimentoAte.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      print('🌐 URL: $uri');
      
      final response = await http.get(uri, headers: _headers);
      print('📡 Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ Parcelas recebidas: ${data.length}');
        
        return data.map((json) {
          try {
            return Parcela.fromJson(json);
          } catch (e) {
            print('❌ Erro ao processar parcela: $e');
            print('📄 Dados da parcela: $json');
            rethrow;
          }
        }).toList();
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        print('❌ Erro na API: ${response.statusCode} - $errorBody');
        throw Exception('Erro ${response.statusCode}: Falha ao listar parcelas');
      }
    } catch (e) {
      print('❌ Erro em listarParcelas: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Erro de conexão. Verifique sua internet.');
      }
      throw Exception('Erro ao listar parcelas: $e');
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
      final body = {
        'valorPago': valorPago,
        'formaPagamento': formaPagamento,
      };

      final response = await http.put(
        Uri.parse('$_baseUrl/$id/baixa'),
        headers: _headers,
        body: json.encode(body),
      ).timeout(const Duration(minutes: 5));

      print('📥 Resposta baixa parcela - Status: ${response.statusCode}');
      print('   Headers: ${response.headers}');

      // Status 307 = Temporary Redirect - seguir o redirect manualmente
      if (response.statusCode == 307 || response.statusCode == 308) {
        final location = response.headers['location'];
        if (location != null) {
          print('🔄 Redirect detectado para: $location');
          final redirectResponse = await http.put(
            Uri.parse(location),
            headers: _headers,
            body: json.encode(body),
          ).timeout(const Duration(minutes: 5));
          
          if (redirectResponse.statusCode == 200) {
            return;
          }
        }
      }

      if (response.statusCode != 200) {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erro ao dar baixa na parcela');
      }
    } catch (e) {
      throw Exception('Erro ao dar baixa: $e');
    }
  }

  Future<void> cancelarParcela(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erro ao cancelar parcela');
      }
    } catch (e) {
      throw Exception('Erro ao cancelar parcela: $e');
    }
  }
}
