import 'fornecedor_model.dart';

class CompraPrazo {
  final String id;
  final String fornecedorId;
  final Fornecedor? fornecedor;
  final String usuarioId;
  final DateTime dataCompra;
  final double valorTotal;
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
        usuarioId: json['usuario_id']?.toString() ?? '0',  // Null-safe com fallback
        dataCompra: DateTime.parse(json['data_compra']),
        valorTotal: (json['valor_total'] ?? 0).toDouble(),
        saldoDevedor: (json['saldo_devedor'] ?? 0).toDouble(),
        status: json['status'] ?? 'em_dia',
        observacoes: json['observacoes'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
        produtos: json['produtos'] as List<dynamic>?,  // Aceita lista de produtos
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
