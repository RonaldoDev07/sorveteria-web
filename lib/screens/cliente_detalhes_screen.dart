import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/clientes_api_service.dart';
import '../models/cliente.dart';
import '../models/conta_receber.dart';
import 'cliente_form_screen.dart';
import 'venda_prazo_screen.dart';
import 'conta_receber_detalhes_screen.dart';

class ClienteDetalhesScreen extends StatefulWidget {
  final Cliente cliente;

  const ClienteDetalhesScreen({super.key, required this.cliente});

  @override
  State<ClienteDetalhesScreen> createState() => _ClienteDetalhesScreenState();
}

class _ClienteDetalhesScreenState extends State<ClienteDetalhesScreen> {
  List<ContaReceber> _contas = [];
  bool _isLoading = true;

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
        clienteId: widget.cliente.id,
      );
      setState(() {
        _contas = contas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double get _totalDevedor {
    return _contas.fold(0.0, (sum, c) => sum + c.saldoDevedor);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Cliente'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
            ),
          ),
        ),
        actions: [
          if (auth.isAdmin || auth.isVendedor)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClienteFormScreen(cliente: widget.cliente),
                  ),
                );
                if (mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    widget.cliente.nome.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      color: Color(0xFF9C27B0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.cliente.nome,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.cliente.cpfCnpj,
                  style: const TextStyle(color: Colors.white70),
                ),
                if (_totalDevedor > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Saldo Devedor: ${formatter.format(_totalDevedor)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VendaPrazoScreen(
                            cliente: widget.cliente,
                          ),
                        ),
                      );
                      _carregarContas();
                    },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Nova Venda'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Contas a Receber',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_contas.length} conta(s)',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _contas.isEmpty
                    ? const Center(child: Text('Nenhuma conta encontrada'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _contas.length,
                        itemBuilder: (context, index) {
                          final conta = _contas[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
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
                              title: Text(conta.descricao ?? 'Sem descrição'),
                              subtitle: Text(
                                'Venc: ${DateFormat('dd/MM/yyyy').format(conta.dataVencimento)}\n'
                                'Saldo: ${formatter.format(conta.saldoDevedor)}',
                              ),
                              trailing: Text(
                                formatter.format(conta.valorTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
        ],
      ),
    );
  }
}
