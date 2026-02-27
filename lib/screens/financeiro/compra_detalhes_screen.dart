import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/financeiro/compra_prazo_model.dart';

class CompraDetalhesScreen extends StatelessWidget {
  final CompraPrazo compra;

  const CompraDetalhesScreen({super.key, required this.compra});

  @override
  Widget build(BuildContext context) {
    final formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final formatoData = DateFormat('dd/MM/yyyy');
    final formatoHora = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Compra'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Informações Gerais
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.business, color: Colors.purple),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            compra.fornecedor?.nome ?? 'Fornecedor',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow('Data', formatoData.format(compra.dataCompra)),
                    _buildInfoRow('Horário', formatoHora.format(compra.dataCompra)),
                    _buildInfoRow('Status', _getStatusLabel(compra.status)),
                    const Divider(height: 24),
                    _buildInfoRow('Valor Total', formatoMoeda.format(compra.valorTotal)),
                    _buildInfoRow('Saldo Devedor', formatoMoeda.format(compra.saldoDevedor)),
                    if (compra.observacoes != null && compra.observacoes!.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Text(
                        'Observações:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(compra.observacoes!),
                    ],
                  ],
                ),
              ),
            ),

            // Card de Produtos
            if (compra.produtos != null && compra.produtos!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Produtos (${compra.produtos!.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...compra.produtos!.map((produto) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.purple,
                    child: Icon(Icons.inventory, color: Colors.white, size: 20),
                  ),
                  title: Text('Produto ID: ${produto.produtoId}'),
                  subtitle: Text('${produto.quantidade}x ${formatoMoeda.format(produto.valorUnitario)}'),
                  trailing: Text(
                    formatoMoeda.format(produto.subtotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              )),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'quitada':
        return 'Quitada';
      case 'atrasada':
        return 'Atrasada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return 'Em Dia';
    }
  }
}
