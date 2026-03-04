import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/financeiro/venda_prazo_model.dart';
import '../../models/financeiro/compra_prazo_model.dart';
import '../auth_service.dart';
import '../../config/api_config.dart';

// Função helper para parsing defensivo de números
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

class RelatorioService {
  final AuthService _authService;

  RelatorioService(this._authService);

  String get _baseUrl => '${ApiConfig.baseUrl}/api/v1/financeiro/relatorios';

  Map<String, String> get _headers {
    final token = _authService.token;
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> contasReceber({
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      print('🔄 Buscando contas a receber...');
      print('📋 Parâmetros: status=$status, dataInicio=$dataInicio, dataFim=$dataFim');
      
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (dataInicio != null) {
        queryParams['dataInicio'] = dataInicio.toIso8601String().split('T')[0];
      }
      if (dataFim != null) {
        queryParams['dataFim'] = dataFim.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse('$_baseUrl/contas-receber').replace(queryParameters: queryParams);
      print('🌐 URL: $uri');
      
      final response = await http.get(uri, headers: _headers);
      print('📡 Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ Dados recebidos com sucesso');
        print('📊 Estrutura: ${data.keys}');
        
        final vendas = (data['vendas'] as List? ?? []).map((v) {
          try {
            return VendaPrazo.fromJson(v);
          } catch (e) {
            print('❌ Erro ao processar venda: $e');
            print('📄 Dados da venda: $v');
            rethrow;
          }
        }).toList();
        
        return {
          'vendas': vendas,
          'total_a_receber': _toDouble(data['total_a_receber']),
          'total_recebido': _toDouble(data['total_recebido']),
          'total_em_aberto': _toDouble(data['total_em_aberto']),
          'contas_atrasadas': data['contas_atrasadas'] ?? 0,
        };
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        print('❌ Erro na API: ${response.statusCode} - $errorBody');
        throw Exception('Erro ${response.statusCode}: Falha ao buscar contas a receber');
      }
    } catch (e) {
      print('❌ Erro em contasReceber: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Erro de conexão. Verifique sua internet.');
      }
      throw Exception('Erro ao buscar contas a receber: $e');
    }
  }

  Future<Map<String, dynamic>> contasPagar({
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      print('🔄 Buscando contas a pagar...');
      print('📋 Parâmetros: status=$status, dataInicio=$dataInicio, dataFim=$dataFim');
      
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (dataInicio != null) {
        queryParams['dataInicio'] = dataInicio.toIso8601String().split('T')[0];
      }
      if (dataFim != null) {
        queryParams['dataFim'] = dataFim.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse('$_baseUrl/contas-pagar').replace(queryParameters: queryParams);
      print('🌐 URL: $uri');
      
      final response = await http.get(uri, headers: _headers);
      print('📡 Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ Dados recebidos com sucesso');
        print('📊 Estrutura: ${data.keys}');
        
        final compras = (data['compras'] as List? ?? []).map((c) {
          try {
            return CompraPrazo.fromJson(c);
          } catch (e) {
            print('❌ Erro ao processar compra: $e');
            print('📄 Dados da compra: $c');
            rethrow;
          }
        }).toList();
        
        return {
          'compras': compras,
          'total_a_pagar': _toDouble(data['total_a_pagar']),
          'total_pago': _toDouble(data['total_pago']),
          'total_em_aberto': _toDouble(data['total_em_aberto']),
          'contas_atrasadas': data['contas_atrasadas'] ?? 0,
        };
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        print('❌ Erro na API: ${response.statusCode} - $errorBody');
        throw Exception('Erro ${response.statusCode}: Falha ao buscar contas a pagar');
      }
    } catch (e) {
      print('❌ Erro em contasPagar: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Erro de conexão. Verifique sua internet.');
      }
      throw Exception('Erro ao buscar contas a pagar: $e');
    }
  }
}
