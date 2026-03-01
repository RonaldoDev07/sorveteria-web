import 'cliente_model.dart';

// Função helper para parsing defensivo de números
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

class VendaPrazo {
  final String id;
  final String clienteId;
  final Cliente? cliente;
  final String usuarioId;
  final DateTime dataVenda;
  final double valorTotal;
  final double valorPago;
  final double saldoDevedor;
  final String status;
  final String? observacoes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<dynamic>? produtos;  // Lista de produtos (opcional)

  VendaPrazo({
    required this.id,
    required this.clienteId,
    this.cliente,
    required this.usuarioId,
    required this.dataVenda,
    required this.valorTotal,
    required this.valorPago,
    required this.saldoDevedor,
    required this.status,
    this.observacoes,
    required this.createdAt,
    this.updatedAt,
    this.produtos,
  });

  factory VendaPrazo.fromJson(Map<String, dynamic> json) {
    try {
      // Debug: imprimir produtos
      if (json['produtos'] != null) {
        print('🔍 Produtos recebidos: ${json['produtos']}');
        print('🔍 Tipo de produtos: ${json['produtos'].runtimeType}');
      }
      
      return VendaPrazo(
        id: json['id'],
        clienteId: json['clienteId'] ?? json['cliente_id'],
        cliente: json['cliente'] != null ? Cliente.fromJson(json['cliente']) : null,
        usuarioId: (json['usuarioId'] ?? json['usuario_id'])?.toString() ?? '0',
        dataVenda: DateTime.parse(json['dataVenda'] ?? json['data_venda']),
        valorTotal: _toDouble(json['valorTotal'] ?? json['valor_total']),
        valorPago: _toDouble(json['valorPago'] ?? json['valor_pago']),
        saldoDevedor: _toDouble(json['saldoDevedor'] ?? json['saldo_devedor']),
        status: json['status'] ?? 'em_dia',
        observacoes: json['observacoes'],
        createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
        updatedAt: (json['updatedAt'] ?? json['updated_at']) != null 
            ? DateTime.parse(json['updatedAt'] ?? json['updated_at']) 
            : null,
        produtos: json['produtos'] as List<dynamic>?,
      );
    } catch (e, stackTrace) {
      print('❌ Erro em VendaPrazo.fromJson: $e');
      print('   JSON recebido: $json');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  bool get estaQuitada => status == 'quitada';
  bool get estaAtrasada => status == 'atrasada';
  bool get estaCancelada => status == 'cancelada';
}
