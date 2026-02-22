import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';

class MovimentacoesScreen extends StatefulWidget {
  const MovimentacoesScreen({super.key});

  @override
  State<MovimentacoesScreen> createState() => _MovimentacoesScreenState();
}

class _MovimentacoesScreenState extends State<MovimentacoesScreen> {
  List<dynamic> _movimentacoes = [];
  bool _isLoading = true;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadMovimentacoes();
  }

  String _formatarNumero(dynamic valor) {
    if (valor == null) return '0';
    final numero = double.parse(valor.toString());
    // Se for número inteiro, não mostrar casas decimais
    if (numero == numero.toInt()) {
      return numero.toInt().toString();
    }
    // Senão, mostrar com até 3 casas decimais, removendo zeros à direita
    return numero.toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), '');
  }

  Future<void> _loadMovimentacoes() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final movimentacoes = await ApiService.getMovimentacoes(auth.token!);
      setState(() {
        _movimentacoes = movimentacoes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar movimentações: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, Map<String, double>> _calcularResumoVendedores() {
    final resumo = <String, Map<String, double>>{};
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    
    for (var mov in _movimentacoes) {
      if (mov['tipo'] != 'SAIDA') continue; // Apenas vendas
      
      try {
        // Tentar diferentes formatos de data
        DateTime dataMovimentacao;
        if (mov['data_movimentacao'] != null) {
          dataMovimentacao = DateTime.parse(mov['data_movimentacao']);
        } else if (mov['data_hora'] != null) {
          dataMovimentacao = DateTime.parse(mov['data_hora']);
        } else {
          continue; // Pular se não tiver data
        }
        
        if (dataMovimentacao.isBefore(inicioDia)) continue; // Apenas hoje
        
        final vendedor = mov['usuario_nome'] ?? 'Desconhecido';
        
        // Calcular valor total: quantidade * valor_unitario
        final quantidade = (mov['quantidade'] is num) 
          ? (mov['quantidade'] as num).toDouble()
          : double.tryParse(mov['quantidade'].toString().replaceAll('.', '').replaceAll(',', '.')) ?? 0;
        final valorUnitario = (mov['valor_unitario'] is num) 
          ? (mov['valor_unitario'] as num).toDouble()
          : double.tryParse(mov['valor_unitario'].toString().replaceAll('.', '').replaceAll(',', '.')) ?? 0;
        final valorTotal = quantidade * valorUnitario;
        
        final lucro = (mov['lucro_total'] is num)
          ? (mov['lucro_total'] as num).toDouble()
          : double.tryParse(mov['lucro_total'].toString().replaceAll('.', '').replaceAll(',', '.')) ?? 0;
        
        if (!resumo.containsKey(vendedor)) {
          resumo[vendedor] = {'total': 0, 'lucro': 0, 'quantidade': 0};
        }
        
        resumo[vendedor]!['total'] = (resumo[vendedor]!['total'] ?? 0) + valorTotal;
        resumo[vendedor]!['lucro'] = (resumo[vendedor]!['lucro'] ?? 0) + lucro;
        resumo[vendedor]!['quantidade'] = (resumo[vendedor]!['quantidade'] ?? 0) + 1;
      } catch (e) {
        // Ignorar movimentações com erro de data
        continue;
      }
    }
    
    return resumo;
  }

  Future<void> _cancelarMovimentacao(int movimentacaoId, String tipo, String produtoNome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Cancelamento'),
        content: Text(
          'Deseja realmente cancelar esta ${tipo == "SAIDA" ? "venda" : "compra"} do produto "$produtoNome"?\n\n'
          'O estoque será revertido automaticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final result = await ApiService.cancelarMovimentacao(auth.token!, movimentacaoId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        _loadMovimentacoes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Movimentações'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMovimentacoes,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _movimentacoes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma movimentação encontrada',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Card de resumo por vendedor
                      if (_calcularResumoVendedores().isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.leaderboard_rounded, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Vendas de Hoje',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ..._calcularResumoVendedores().entries.map((entry) {
                                final vendedor = entry.key;
                                final dados = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.person_rounded, color: Colors.white.withOpacity(0.9), size: 18),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              vendedor,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${dados['quantidade']?.toInt() ?? 0} ${(dados['quantidade']?.toInt() ?? 0) == 1 ? 'venda' : 'vendas'}',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.95),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Total Vendido',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.8),
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                BrazilianFormatters.formatCurrency(dados['total'] ?? 0),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Lucro',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.8),
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                BrazilianFormatters.formatCurrency(dados['lucro'] ?? 0),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ],
                      // Lista de movimentações
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _movimentacoes.length,
                    itemBuilder: (context, index) {
                      final mov = _movimentacoes[index];
                      final isEntrada = mov['tipo'] == 'ENTRADA';
                      final cor = isEntrada ? Colors.teal : Colors.green;
                      final icone = isEntrada ? Icons.arrow_downward : Icons.arrow_upward;
                      final titulo = isEntrada ? 'COMPRA' : 'VENDA';

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [cor.shade100, cor.shade50],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: cor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      icone,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          titulo,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: cor.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          mov['produto_nome'] ?? 'Produto',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (auth.isAdmin)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: Colors.red,
                                      onPressed: () => _cancelarMovimentacao(
                                        mov['id'],
                                        mov['tipo'],
                                        mov['produto_nome'] ?? 'Produto',
                                      ),
                                      tooltip: 'Cancelar',
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                    'Quantidade',
                                    '${_formatarNumero(mov['quantidade'])} ${mov['unidade'] ?? 'UN'}',
                                    Icons.inventory,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    'Valor Unitário',
                                    BrazilianFormatters.formatCurrency(mov['valor_unitario']),
                                    Icons.payments_rounded,
                                  ),
                                  if (!isEntrada && mov['lucro_total'] != null) ...[
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      'Lucro Total',
                                      BrazilianFormatters.formatCurrency(mov['lucro_total']),
                                      Icons.monetization_on,
                                      valueColor: Colors.green,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    'Vendedor',
                                    mov['usuario_nome'] ?? 'Desconhecido',
                                    Icons.person,
                                    valueColor: Colors.indigo,
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _dateFormat.format(DateTime.parse(mov['data_hora'])),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                        ),
                      ],
                    ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
