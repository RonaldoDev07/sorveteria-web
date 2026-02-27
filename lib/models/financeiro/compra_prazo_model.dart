import 'fornecedor_model.dart';

// Função helper para parsing defensivo de números
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

class CompraPrazo {
  final String id;
  final String fornecedorId;
  final Fornecedor? fornecedor;
  final String usuarioId;
  final DateTime dataCompra;
  final double valorTotal;
  final double valorPago;
  final double saldoDevedor;
  final String status;
  final String? observacoes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<dynamic>? produtos;  // Lista de produtos (opcional)

  CompraPrazo({
    required this.id,
    required this.fornecedorId,
    this.fornecedor,
    required this.usuarioId,
    required this.dataCompra,
    required this.valorTotal,
    required this.valorPago,
    required this.saldoDevedor,
    required this.status,
    this.observacoes,
    required this.createdAt,
    this.updatedAt,
    this.produtos,
  });

  factory CompraPrazo.fromJson(Map<String, dynamic> json) {
    try {
      return CompraPrazo(
        id: json['id'],
        fornecedorId: json['fornecedor_id'],
        fornecedor: json['fornecedor'] != null ? Fornecedor.fromJson(json['fornecedor']) : null,
        usuarioId: json['usuario_id']?.toString() ?? '0',
        dataCompra: DateTime.parse(json['data_compra']),
        valorTotal: _toDouble(json['valor_total']),
        valorPago: _toDouble(json['valor_pago']),
        saldoDevedor: _toDouble(json['saldo_devedor']),
        status: json['status'] ?? 'em_dia',
        observacoes: json['observacoes'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
        produtos: json['produtos'] as List<dynamic>?,
      );
    } catch (e) {
      print('❌ Erro em CompraPrazo.fromJson: $e');
      print('   JSON recebido: $json');
      rethrow;
    }
  }

  bool get estaQuitada => status == 'quitada';
  bool get estaAtrasada => status == 'atrasada';
  bool get estaCancelada => status == 'cancelada';
  double get valorPago => valorTotal - saldoDevedor;
}
