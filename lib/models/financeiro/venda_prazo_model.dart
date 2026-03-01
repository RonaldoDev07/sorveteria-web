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
      
      // Parse com tratamento de erro individual para cada campo
      final id = json['id'];
      print('✅ id: $id');
      
      final clienteId = json['clienteId'] ?? json['cliente_id'];
      print('✅ clienteId: $clienteId');
      
      final cliente = json['cliente'] != null ? Cliente.fromJson(json['cliente']) : null;
      print('✅ cliente: ${cliente?.nome}');
      
      final usuarioId = (json['usuarioId'] ?? json['usuario_id'])?.toString() ?? '0';
      print('✅ usuarioId: $usuarioId');
      
      final dataVendaStr = json['dataVenda'] ?? json['data_venda'];
      print('🔍 dataVenda string: $dataVendaStr');
      final dataVenda = DateTime.parse(dataVendaStr);
      print('✅ dataVenda parsed: $dataVenda');
      
      final valorTotal = _toDouble(json['valorTotal'] ?? json['valor_total']);
      final valorPago = _toDouble(json['valorPago'] ?? json['valor_pago']);
      final saldoDevedor = _toDouble(json['saldoDevedor'] ?? json['saldo_devedor']);
      final status = json['status'] ?? 'em_dia';
      final observacoes = json['observacoes'];
      
      final createdAtStr = json['createdAt'] ?? json['created_at'];
      print('🔍 createdAt string: $createdAtStr');
      final createdAt = DateTime.parse(createdAtStr);
      print('✅ createdAt parsed: $createdAt');
      
      final updatedAtStr = json['updatedAt'] ?? json['updated_at'];
      print('🔍 updatedAt string: $updatedAtStr');
      final updatedAt = updatedAtStr != null ? DateTime.parse(updatedAtStr) : null;
      print('✅ updatedAt parsed: $updatedAt');
      
      final produtos = json['produtos'] as List<dynamic>?;
      
      return VendaPrazo(
        id: id,
        clienteId: clienteId,
        cliente: cliente,
        usuarioId: usuarioId,
        dataVenda: dataVenda,
        valorTotal: valorTotal,
        valorPago: valorPago,
        saldoDevedor: saldoDevedor,
        status: status,
        observacoes: observacoes,
        createdAt: createdAt,
        updatedAt: updatedAt,
        produtos: produtos,
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
