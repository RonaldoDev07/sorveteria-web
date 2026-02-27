import 'cliente_model.dart';

class VendaPrazo {
  final String id;
  final String clienteId;
  final Cliente? cliente;
  final String usuarioId;
  final DateTime dataVenda;
  final double valorTotal;
  final double saldoDevedor;
  final String status;
  final String? observacoes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<dynamic>? produtos;  // Lista de produtos (opcional)

  VendaPrazo({
    required this.id,
    required this.clienteId,
    this.cliente,
    required this.usuarioId,
    required this.dataVenda,
    required this.valorTotal,
    required this.saldoDevedor,
    required this.status,
    this.observacoes,
    required this.createdAt,
    this.updatedAt,
    this.produtos,
  });

  factory VendaPrazo.fromJson(Map<String, dynamic> json) {
    try {
      return VendaPrazo(
        id: json['id'],
        clienteId: json['cliente_id'],
        cliente: json['cliente'] != null ? Cliente.fromJson(json['cliente']) : null,
        usuarioId: json['usuario_id']?.toString() ?? '0',  // Null-safe com fallback
        dataVenda: DateTime.parse(json['data_venda']),
        valorTotal: (json['valor_total'] ?? 0).toDouble(),
        saldoDevedor: (json['saldo_devedor'] ?? 0).toDouble(),
        status: json['status'] ?? 'em_dia',
        observacoes: json['observacoes'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
        produtos: json['produtos'] as List<dynamic>?,  // Aceita lista de produtos
      );
    } catch (e) {
      print('❌ Erro em VendaPrazo.fromJson: $e');
      print('   JSON recebido: $json');
      rethrow;
    }
  }

  bool get estaQuitada => status == 'quitada';
  bool get estaAtrasada => status == 'atrasada';
  bool get estaCancelada => status == 'cancelada';
  double get valorPago => valorTotal - saldoDevedor;
}
