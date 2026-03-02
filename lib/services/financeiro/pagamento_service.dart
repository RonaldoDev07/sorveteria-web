import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/financeiro/pagamento_model.dart';
import '../auth_service.dart';
import '../../config/api_config.dart';

class PagamentoService {
  final AuthService _authService;

  PagamentoService(this._authService);

  String get _baseUrl => '${ApiConfig.baseUrl}/api/v1/financeiro';

  Map<String, String> get _headers {
    final token = _authService.token;
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  /// Registra um pagamento para uma venda
  Future<Pagamento> registrarPagamentoVenda({
    required String vendaId,
    required double valorPago,
    required String formaPagamento,
    DateTime? dataPagamento,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/vendas/$vendaId/pagamentos'),
        headers: _headers,
        body: json.encode({
          'valorPago': valorPago,
          'formaPagamento': formaPagamento,
          'dataPagamento': (dataPagamento ?? DateTime.now()).toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Pagamento.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erro ao registrar pagamento');
      }
    } catch (e) {
      throw Exception('Erro ao registrar pagamento: $e');
    }
  }

  /// Lista pagamentos de uma venda
  Future<List<Pagamento>> listarPagamentosVenda(String vendaId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/vendas/$vendaId/pagamentos'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Pagamento.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao listar pagamentos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao listar pagamentos: $e');
    }
  }

  /// Registra um pagamento para uma compra
  Future<Pagamento> registrarPagamentoCompra({
    required String compraId,
    required double valorPago,
    required String formaPagamento,
    DateTime? dataPagamento,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/compras/$compraId/pagamentos'),
        headers: _headers,
        body: json.encode({
          'valorPago': valorPago,
          'formaPagamento': formaPagamento,
          'dataPagamento': (dataPagamento ?? DateTime.now()).toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Pagamento.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erro ao registrar pagamento');
      }
    } catch (e) {
      throw Exception('Erro ao registrar pagamento: $e');
    }
  }

  /// Lista pagamentos de uma compra
  Future<List<Pagamento>> listarPagamentosCompra(String compraId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/compras/$compraId/pagamentos'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Pagamento.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao listar pagamentos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao listar pagamentos: $e');
    }
  }

  /// Cancela um pagamento
  Future<void> cancelarPagamento(String pagamentoId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/pagamentos/$pagamentoId'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erro ao cancelar pagamento');
      }
    } catch (e) {
      throw Exception('Erro ao cancelar pagamento: $e');
    }
  }
}
