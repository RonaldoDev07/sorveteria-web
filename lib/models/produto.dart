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
    try {
      return Produto(
        id: json['id'] as int,
        nome: json['nome'] as String,
        unidade: json['unidade'] as String,
        preco: (json['preco_venda'] as num).toDouble(),
        quantidade: (json['estoque_atual'] as num).toDouble(),
        custoMedio: json['custo_medio'] != null ? (json['custo_medio'] as num).toDouble() : null,
        dataValidade: json['data_validade'] as String?,
        codigoBarras: json['codigo_barras'] as String?,
      );
    } catch (e) {
      print('❌ Erro em Produto.fromJson: $e');
      print('   JSON recebido: $json');
      rethrow;
    }
  }
}
