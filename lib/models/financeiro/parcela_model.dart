// Função helper para parsing defensivo de números
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

/// Model para Parcela
class Parcela {
  final String id;
  final String tipo; // 'venda' ou 'compra'
  final String referenciaId;
  final int numeroParcela;
  final double valorParcela;
  final double valorPago;
  final DateTime dataVencimento;
  final String status; // 'pendente', 'parcialmente_paga', 'paga', 'atrasada'
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Informações adicionais
  final String? clienteNome;
  final String? fornecedorNome;

  Parcela({
    required this.id,
    required this.tipo,
    required this.referenciaId,
    required this.numeroParcela,
    required this.valorParcela,
    required this.valorPago,
    required this.dataVencimento,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.clienteNome,
    this.fornecedorNome,
  });

  factory Parcela.fromJson(Map<String, dynamic> json) {
    try {
      // Debug: imprimir dados recebidos
      print('🔍 Parcela JSON recebido: $json');
      
      return Parcela(
        id: json['id'],
        tipo: json['tipo'],
        referenciaId: json['referenciaId'] ?? json['referencia_id'],
        numeroParcela: json['numeroParcela'] ?? json['numero_parcela'],
        valorParcela: _toDouble(json['valorParcela'] ?? json['valor_parcela']),
        valorPago: _toDouble(json['valorPago'] ?? json['valor_pago']),
        dataVencimento: DateTime.parse(json['dataVencimento'] ?? json['data_vencimento']),
        status: json['status'],
        createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
        updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at']),
        clienteNome: json['clienteNome'] ?? 
                    json['cliente_nome'] ?? 
                    (json['cliente'] != null ? json['cliente']['nome'] : null) ??
                    (json['venda'] != null && json['venda']['cliente'] != null ? json['venda']['cliente']['nome'] : null),
        fornecedorNome: json['fornecedorNome'] ?? 
                       json['fornecedor_nome'] ?? 
                       (json['fornecedor'] != null ? json['fornecedor']['nome'] : null) ??
                       (json['compra'] != null && json['compra']['fornecedor'] != null ? json['compra']['fornecedor']['nome'] : null),
      );
    } catch (e) {
      print('❌ Erro ao processar parcela: $e');
      print('📄 JSON da parcela: $json');
      rethrow;
    }
  }

  double get saldoRestante => valorParcela - valorPago;
  bool get estaPaga => status == 'paga';
  bool get estaAtrasada => status == 'atrasada';
  bool get estaPendente => status == 'pendente';
  
  String get nomeRelacionado {
    // Tentar várias formas de obter o nome
    String? nome;
    
    if (tipo == 'venda' || tipo == 'VENDA') {
      nome = clienteNome;
      if (nome == null || nome.isEmpty || nome == 'null') {
        print('⚠️ Nome do cliente não encontrado para parcela $id');
        return 'Cliente não identificado';
      }
    } else if (tipo == 'compra' || tipo == 'COMPRA') {
      nome = fornecedorNome;
      if (nome == null || nome.isEmpty || nome == 'null') {
        print('⚠️ Nome do fornecedor não encontrado para parcela $id');
        return 'Fornecedor não identificado';
      }
    }
    
    print('✅ Nome encontrado para parcela $id: $nome');
    return nome ?? 'N/A';
  }
}
