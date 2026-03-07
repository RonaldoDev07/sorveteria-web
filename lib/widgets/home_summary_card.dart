import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/text_formatters.dart';

class HomeSummaryCard extends StatefulWidget {
  const HomeSummaryCard({super.key});

  @override
  State<HomeSummaryCard> createState() => _HomeSummaryCardState();
}

class _HomeSummaryCardState extends State<HomeSummaryCard> {
  bool _isLoading = true;
  double _vendasHoje = 0.0;
  double _vendasSemana = 0.0;
  int _produtosEstoqueBaixo = 0;
  int _parcelasVencidas = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _carregarResumo();
    // Atualizar a cada 1 minuto
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        _carregarResumo();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _carregarResumo() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      
      // Buscar dados em paralelo
      final results = await Future.wait([
        _buscarVendasHoje(auth.token!),
        _buscarVendasSemana(auth.token!),
        _buscarProdutosEstoqueBaixo(auth.token!),
        _buscarParcelasVencidas(auth.token!),
      ]);

      if (mounted) {
        setState(() {
          _vendasHoje = results[0] as double;
          _vendasSemana = results[1] as double;
          _produtosEstoqueBaixo = results[2] as int;
          _parcelasVencidas = results[3] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar resumo: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<double> _buscarVendasHoje(String token) async {
    try {
      final hoje = DateTime.now();
      final dataInicio = '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
      
      // Buscar movimentações do dia
      final movimentacoes = await ApiService.getMovimentacoes(token);
      
      // Filtrar apenas vendas (SAIDA) de hoje
      double totalVendas = 0.0;
      for (var mov in movimentacoes) {
        if (mov['tipo'] == 'SAIDA') {
          // Verificar se é de hoje
          final dataMov = mov['data_movimentacao'] ?? '';
          if (dataMov.startsWith(dataInicio)) {
            final valorTotal = mov['valor_total'];
            if (valorTotal != null) {
              totalVendas += (valorTotal is num ? valorTotal.toDouble() : double.tryParse(valorTotal.toString()) ?? 0.0);
            }
          }
        }
      }
      
      return totalVendas;
    } catch (e) {
      print('Erro ao buscar vendas de hoje: $e');
      return 0.0;
    }
  }

  Future<double> _buscarVendasSemana(String token) async {
    try {
      final hoje = DateTime.now();
      final seteDiasAtras = hoje.subtract(const Duration(days: 7));
      
      // Buscar movimentações
      final movimentacoes = await ApiService.getMovimentacoes(token);
      
      // Filtrar apenas vendas (SAIDA) dos últimos 7 dias
      double totalVendas = 0.0;
      for (var mov in movimentacoes) {
        if (mov['tipo'] == 'SAIDA') {
          final dataMov = mov['data_movimentacao'] ?? '';
          if (dataMov.isNotEmpty) {
            try {
              final dataParsed = DateTime.parse(dataMov);
              if (dataParsed.isAfter(seteDiasAtras) && dataParsed.isBefore(hoje.add(const Duration(days: 1)))) {
                final valorTotal = mov['valor_total'];
                if (valorTotal != null) {
                  totalVendas += (valorTotal is num ? valorTotal.toDouble() : double.tryParse(valorTotal.toString()) ?? 0.0);
                }
              }
            } catch (e) {
              // Ignorar erro de parse de data
            }
          }
        }
      }
      
      return totalVendas;
    } catch (e) {
      print('Erro ao buscar vendas da semana: $e');
      return 0.0;
    }
  }

  Future<int> _buscarProdutosEstoqueBaixo(String token) async {
    try {
      final produtos = await ApiService.getProdutos(token);
      return produtos.where((p) {
        final estoque = p['estoque_atual'];
        final estoqueNum = estoque is num ? estoque : (double.tryParse(estoque.toString()) ?? 0);
        return estoqueNum < 5; // Estoque baixo = menos de 5 unidades
      }).length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _buscarParcelasVencidas(String token) async {
    try {
      // Buscar parcelas vencidas (status PENDENTE e data_vencimento < hoje)
      final hoje = DateTime.now();
      // Por enquanto, retornar 0 - implementar quando tiver endpoint específico
      return 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Skeleton para vendas
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 30,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 60,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Skeleton para alertas
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 50,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            )
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Vendas de Hoje - compacto
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'R\$',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hoje',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    formatarMoeda(_vendasHoje),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Alertas - compacto
          if (_produtosEstoqueBaixo > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.orange,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Estoque',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$_produtosEstoqueBaixo baixo${_produtosEstoqueBaixo > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Tudo OK',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAlerta({
    required IconData icon,
    required Color color,
    required String titulo,
    required String descricao,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descricao,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
