import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/financeiro/venda_prazo_model.dart';

class VendaDetalhesScreen extends StatelessWidget {
  final VendaPrazo venda;

  const VendaDetalhesScreen({super.key, required this.venda});

  @override
  Widget build(BuildContext context) {
    final formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final formatoData = DateFormat('dd/MM/yyyy');
    final formatoHora = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Venda'),
        backgroundColor: Colors.green,
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
                        const Icon(Icons.person, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            venda.cliente?.nome ?? 'Cliente',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow('Data', formatoData.format(venda.dataVenda)),
                    _buildInfoRow('Horário', formatoHora.format(venda.dataVenda)),
                    _buildInfoRow('Status', _getStatusLabel(venda.status)),
                    const Divider(height: 24),
                    _buildInfoRow('Valor Total', formatoMoeda.format(venda.valorTotal)),
                    _buildInfoRow('Saldo Devedor', formatoMoeda.format(venda.saldoDevedor)),
                    if (venda.observacoes != null && venda.observacoes!.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Text(
                        'Observações:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(venda.observacoes!),
                    ],
                  ],
                ),
              ),
            ),

            // Card de Produtos
            if (venda.produtos != null && venda.produtos!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Produtos (${venda.produtos!.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...venda.produtos!.map((produto) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.shopping_bag, color: Colors.white, size: 20),
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
