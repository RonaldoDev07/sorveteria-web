class Produto {
  final int id;
  final String nome;
  final String unidade;
  final double preco;
  final double quantidade;
  final double? custoMedio;
  final String? dataValidade;
  final String? codigoBarras;

  Produto({
    required this.id,
    required this.nome,
    required this.unidade,
    required this.preco,
    required this.quantidade,
    this.custoMedio,
    this.dataValidade,
    this.codigoBarras,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'],
      nome: json['nome'],
      unidade: json['unidade'],
      preco: (json['preco_venda'] ?? 0).toDouble(),
      quantidade: (json['estoque_atual'] ?? 0).toDouble(),
      custoMedio: json['custo_medio']?.toDouble(),
      dataValidade: json['data_validade'],
      codigoBarras: json['codigo_barras'],
    );
  }
}
