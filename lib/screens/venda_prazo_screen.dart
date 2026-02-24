import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/clientes_api_service.dart';
import '../models/cliente.dart';

class VendaPrazoScreen extends StatefulWidget {
  final Cliente cliente;

  const VendaPrazoScreen({super.key, required this.cliente});

  @override
  State<VendaPrazoScreen> createState() => _VendaPrazoScreenState();
}

class _VendaPrazoScreenState extends State<VendaPrazoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();
  int _numeroParcelas = 1;
  DateTime _dataPrimeiraParcela = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  Future<void> _criar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      await ClientesApiService.criarVendaPrazo(
        auth.token!,
        clienteId: widget.cliente.id,
        valorTotal: double.parse(_valorController.text),
        descricao: _descricaoController.text,
        numeroParcelas: _numeroParcelas,
        dataPrimeiraParcela: _dataPrimeiraParcela,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venda a prazo criada com sucesso')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final valorParcela = _valorController.text.isEmpty
        ? 0.0
        : double.parse(_valorController.text) / _numeroParcelas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Venda a Prazo'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cliente',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      widget.cliente.nome,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valorController,
              decoration: const InputDecoration(
                labelText: 'Valor Total *',
                border: OutlineInputBorder(),
                prefixText: 'R\$ ',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Campo obrigatório';
                if (double.tryParse(v!) == null) return 'Valor inválido';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _numeroParcelas,
              decoration: const InputDecoration(
                labelText: 'Número de Parcelas',
                border: OutlineInputBorder(),
              ),
              items: List.generate(12, (i) => i + 1)
                  .map((n) => DropdownMenuItem(
                        value: n,
                        child: Text('$n parcela${n > 1 ? 's' : ''}'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _numeroParcelas = v!),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Data da 1ª Parcela'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_dataPrimeiraParcela)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final data = await showDatePicker(
                  context: context,
                  initialDate: _dataPrimeiraParcela,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (data != null) {
                  setState(() => _dataPrimeiraParcela = data);
                }
              },
            ),
            const SizedBox(height: 16),
            if (_valorController.text.isNotEmpty)
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_numeroParcelas parcela${_numeroParcelas > 1 ? 's' : ''} de ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valorParcela)}',
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _criar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Criar Venda a Prazo',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
