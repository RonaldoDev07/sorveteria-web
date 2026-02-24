import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/clientes_api_service.dart';
import '../models/conta_receber.dart';
import '../models/pagamento.dart';

class ContaReceberDetalhesScreen extends StatefulWidget {
  final ContaReceber conta;

  const ContaReceberDetalhesScreen({super.key, required this.conta});

  @override
  State<ContaReceberDetalhesScreen> createState() =>
      _ContaReceberDetalhesScreenState();
}

class _ContaReceberDetalhesScreenState
    extends State<ContaReceberDetalhesScreen> {
  List<Pagamento> _pagamentos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarPagamentos();
  }

  Future<void> _carregarPagamentos() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final pagamentos = await ClientesApiService.getRecebimentos(
        auth.token!,
        contaId: widget.conta.id,
      );
      setState(() {
        _pagamentos = pagamentos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registrarRecebimento() async {
    final valorController = TextEditingController();
    String formaPagamento = 'PIX';
    DateTime dataPagamento = DateTime.now();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar Recebimento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: valorController,
                decoration: InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                  hintText: NumberFormat.currency(
                    locale: 'pt_BR',
                    symbol: '',
                  ).format(widget.conta.saldoDevedor),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: formaPagamento,
                decoration: const InputDecoration(labelText: 'Forma de Pagamento'),
                items: const [
                  DropdownMenuItem(value: 'DINHEIRO', child: Text('Dinheiro')),
                  DropdownMenuItem(value: 'PIX', child: Text('PIX')),
                  DropdownMenuItem(value: 'CARTAO_CREDITO', child: Text('Cartão de Crédito')),
                  DropdownMenuItem(value: 'CARTAO_DEBITO', child: Text('Cartão de Débito')),
                  DropdownMenuItem(value: 'TRANSFERENCIA', child: Text('Transferência')),
                ],
                onChanged: (v) => setDialogState(() => formaPagamento = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (valorController.text.isEmpty) return;
                try {
                  final auth = Provider.of<AuthService>(context, listen: false);
                  final pagamento = Pagamento(
                    id: 0,
                    contaId: widget.conta.id,
                    valorPago: double.parse(valorController.text),
                    dataPagamento: dataPagamento,
                    formaPagamento: formaPagamento,
                    observacoes: null,
                  );
                  await ClientesApiService.registrarRecebimento(
                    auth.token!,
                    pagamento,
                  );
                  if (context.mounted) Navigator.pop(context, true);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro: $e')),
                    );
                  }
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );

    if (resultado == true) {
      _carregarPagamentos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recebimento registrado com sucesso')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Conta'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.conta.isPaga
                  ? Colors.green
                  : widget.conta.isVencida
                      ? Colors.red
                      : Colors.orange,
            ),
            child: Column(
              children: [
                Text(
                  widget.conta.isPaga
                      ? 'PAGA'
                      : widget.conta.isVencida
                          ? 'VENCIDA'
                          : 'PENDENTE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatter.format(widget.conta.saldoDevedor),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Saldo Devedor',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoRow('Cliente', widget.conta.clienteNome ?? 'N/A'),
                _InfoRow('Descrição', widget.conta.descricao ?? 'N/A'),
                _InfoRow(
                  'Vencimento',
                  DateFormat('dd/MM/yyyy').format(widget.conta.dataVencimento),
                ),
                _InfoRow('Valor Total', formatter.format(widget.conta.valorTotal)),
                _InfoRow('Valor Pago', formatter.format(widget.conta.valorPago)),
              ],
            ),
          ),
          if (!widget.conta.isPaga)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: _registrarRecebimento,
                icon: const Icon(Icons.payment),
                label: const Text('Registrar Recebimento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Histórico de Recebimentos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pagamentos.isEmpty
                    ? const Center(child: Text('Nenhum recebimento registrado'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _pagamentos.length,
                        itemBuilder: (context, index) {
                          final pag = _pagamentos[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.check_circle, color: Colors.green),
                              title: Text(formatter.format(pag.valorPago)),
                              subtitle: Text(
                                '${DateFormat('dd/MM/yyyy').format(pag.dataPagamento)} - ${pag.formaPagamento}',
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
