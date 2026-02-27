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
      // Helper para converter String ou num para double
      double parseDouble(dynamic value) {
        if (value == null) return 0.0;
        if (value is num) return value.toDouble();
        if (value is String) return double.parse(value);
        throw TypeError();
      }

      return Produto(
        id: json['id'] as int,
        nome: json['nome'] as String,
        unidade: json['unidade'] as String,
        preco: parseDouble(json['preco_venda']),
        quantidade: parseDouble(json['estoque_atual']),
        custoMedio: json['custo_medio'] != null ? parseDouble(json['custo_medio']) : null,
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
