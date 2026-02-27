// Função helper para parsing defensivo de números
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

class Pagamento {
  final String id;
  final String tipo; // 'venda' ou 'compra'
  final String referenciaId;
  final double valorPago;
  final String formaPagamento;
  final DateTime dataPagamento;
  final int usuarioId;
  final DateTime createdAt;

  Pagamento({
    required this.id,
    required this.tipo,
    required this.referenciaId,
    required this.valorPago,
    required this.formaPagamento,
    required this.dataPagamento,
    required this.usuarioId,
    required this.createdAt,
  });

  factory Pagamento.fromJson(Map<String, dynamic> json) {
    return Pagamento(
      id: json['id'],
      tipo: json['tipo'],
      referenciaId: json['referencia_id'],
      valorPago: _toDouble(json['valor_pago']),
      formaPagamento: json['forma_pagamento'],
      dataPagamento: DateTime.parse(json['data_pagamento']),
      usuarioId: json['usuario_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'referencia_id': referenciaId,
      'valor_pago': valorPago,
      'forma_pagamento': formaPagamento,
      'data_pagamento': dataPagamento.toIso8601String(),
      'usuario_id': usuarioId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
