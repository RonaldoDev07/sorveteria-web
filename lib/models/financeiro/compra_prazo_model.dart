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
  });

  factory CompraPrazo.fromJson(Map<String, dynamic> json) {
    return CompraPrazo(
      id: json['id'],
      fornecedorId: json['fornecedor_id'],
      fornecedor: json['fornecedor'] != null ? Fornecedor.fromJson(json['fornecedor']) : null,
      usuarioId: json['usuario_id'].toString(),  // Converter int para String
      dataCompra: DateTime.parse(json['data_compra']),
      valorTotal: (json['valor_total'] ?? 0).toDouble(),
      saldoDevedor: (json['saldo_devedor'] ?? 0).toDouble(),
      status: json['status'],
      observacoes: json['observacoes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get estaQuitada => status == 'quitada';
  bool get estaAtrasada => status == 'atrasada';
  bool get estaCancelada => status == 'cancelada';
  double get valorPago => valorTotal - saldoDevedor;
}
