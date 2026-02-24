class ContaPagar {
  final int id;
  final int fornecedorId;
  final String? fornecedorNome;
  final double valorTotal;
  final double valorPago;
  final DateTime dataVencimento;
  final String? descricao;
  final String status;
  final DateTime dataCriacao;

  ContaPagar({
    required this.id,
    required this.fornecedorId,
    this.fornecedorNome,
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

  factory ContaPagar.fromJson(Map<String, dynamic> json) {
    return ContaPagar(
      id: json['id'],
      fornecedorId: json['fornecedor_id'],
      fornecedorNome: json['fornecedor_nome'],
      valorTotal: json['valor_total'].toDouble(),
      valorPago: json['valor_pago'].toDouble(),
      dataVencimento: DateTime.parse(json['data_vencimento']),
      descricao: json['descricao'],
      status: json['status'],
      dataCriacao: DateTime.parse(json['data_criacao']),
    );
  }
}
