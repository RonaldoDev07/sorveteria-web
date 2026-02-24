class Pagamento {
  final int id;
  final int contaId;
  final double valorPago;
  final DateTime dataPagamento;
  final String formaPagamento;
  final String? observacoes;

  Pagamento({
    required this.id,
    required this.contaId,
    required this.valorPago,
    required this.dataPagamento,
    required this.formaPagamento,
    this.observacoes,
  });

  factory Pagamento.fromJson(Map<String, dynamic> json) {
    return Pagamento(
      id: json['id'],
      contaId: json['conta_receber_id'] ?? json['conta_pagar_id'],
      valorPago: json['valor_pago'].toDouble(),
      dataPagamento: DateTime.parse(json['data_pagamento']),
      formaPagamento: json['forma_pagamento'],
      observacoes: json['observacoes'],
    );
  }

  Map<String, dynamic> toJson(String tipo) {
    return {
      tipo == 'receber' ? 'conta_receber_id' : 'conta_pagar_id': contaId,
      'valor_pago': valorPago,
      'data_pagamento': dataPagamento.toIso8601String().split('T')[0],
      'forma_pagamento': formaPagamento,
      'observacoes': observacoes,
    };
  }
}
