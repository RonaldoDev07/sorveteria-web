class ContaReceber {
  final int id;
  final int clienteId;
  final String? clienteNome;
  final double valorTotal;
  final double valorPago;
  final DateTime dataVencimento;
  final String? descricao;
  final String status;
  final DateTime dataCriacao;

  ContaReceber({
    required this.id,
    required this.clienteId,
    this.clienteNome,
    required this.valorTotal,
    required this.valorPago,
    required this.dataVencimento,
    this.descricao,
    required this.status,
    required this.dataCriacao,
  });

  double get saldoDevedor => valorTotal - valorPago;
  
  bool get isPaga => status == 'paga';
  bool get isVencida => status == 'vencida';
  bool get isPendente => status == 'pendente';

  factory ContaReceber.fromJson(Map<String, dynamic> json) {
    return ContaReceber(
      id: json['id'],
      clienteId: json['cliente_id'],
      clienteNome: json['cliente_nome'],
      valorTotal: json['valor_total'].toDouble(),
      valorPago: json['valor_pago'].toDouble(),
      dataVencimento: DateTime.parse(json['data_vencimento']),
      descricao: json['descricao'],
      status: json['status'],
      dataCriacao: DateTime.parse(json['data_criacao']),
    );
  }
}
