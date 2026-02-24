import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/clientes_api_service.dart';
import '../models/conta_receber.dart';
import 'conta_receber_detalhes_screen.dart';

class ContasReceberScreen extends StatefulWidget {
  const ContasReceberScreen({super.key});

  @override
  State<ContasReceberScreen> createState() => _ContasReceberScreenState();
}

class _ContasReceberScreenState extends State<ContasReceberScreen> {
  List<ContaReceber> _contas = [];
  bool _isLoading = true;
  String _filtroStatus = 'todas';

  @override
  void initState() {
    super.initState();
    _carregarContas();
  }

  Future<void> _carregarContas() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final contas = await ClientesApiService.getContasReceber(
        auth.token!,
        status: _filtroStatus == 'todas' ? null : _filtroStatus,
      );
      setState(() {
        _contas = contas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contas a Receber'),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'todas', label: Text('Todas')),
                ButtonSegment(value: 'pendente', label: Text('Pendentes')),
                ButtonSegment(value: 'vencida', label: Text('Vencidas')),
                ButtonSegment(value: 'paga', label: Text('Pagas')),
              ],
              selected: {_filtroStatus},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _filtroStatus = newSelection.first);
                _carregarContas();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _contas.isEmpty
                    ? const Center(child: Text('Nenhuma conta encontrada'))
                    : RefreshIndicator(
                        onRefresh: _carregarContas,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _contas.length,
                          itemBuilder: (context, index) {
                            final conta = _contas[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Icon(
                                  conta.isPaga
                                      ? Icons.check_circle
                                      : conta.isVencida
                                          ? Icons.error
                                          : Icons.schedule,
                                  color: conta.isPaga
                                      ? Colors.green
                                      : conta.isVencida
                                          ? Colors.red
                                          : Colors.orange,
                                ),
                                title: Text(conta.clienteNome ?? 'Cliente'),
                                subtitle: Text(
                                  '${conta.descricao ?? 'Sem descrição'}\n'
                                  'Venc: ${DateFormat('dd/MM/yyyy').format(conta.dataVencimento)}',
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      formatter.format(conta.saldoDevedor),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'de ${formatter.format(conta.valorTotal)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ContaReceberDetalhesScreen(conta: conta),
                                    ),
                                  );
                                  _carregarContas();
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
