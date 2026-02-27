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
