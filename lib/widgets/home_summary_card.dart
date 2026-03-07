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

  @override
  void initState() {
    super.initState();
    _carregarResumo();
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
      
      final relatorio = await ApiService.getRelatorioLucro(token, dataInicio, dataInicio);
      return (relatorio['receita_total'] ?? 0.0).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _buscarVendasSemana(String token) async {
    try {
      final hoje = DateTime.now();
      final seteDiasAtras = hoje.subtract(const Duration(days: 7));
      final dataInicio = '${seteDiasAtras.year}-${seteDiasAtras.month.toString().padLeft(2, '0')}-${seteDiasAtras.day.toString().padLeft(2, '0')}';
      final dataFim = '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
      
      final relatorio = await ApiService.getRelatorioLucro(token, dataInicio, dataFim);
      return (relatorio['receita_total'] ?? 0.0).toDouble();
    } catch (e) {
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
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Vendas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withOpacity(0.1),
                  const Color(0xFF059669).withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.attach_money_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vendas de Hoje',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatarMoeda(_vendasHoje),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Semana: ${formatarMoeda(_vendasSemana)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Alertas
          if (_produtosEstoqueBaixo > 0 || _parcelasVencidas > 0)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_produtosEstoqueBaixo > 0)
                    _buildAlerta(
                      icon: Icons.inventory_2_outlined,
                      color: Colors.orange,
                      titulo: 'Estoque Baixo',
                      descricao: '$_produtosEstoqueBaixo ${_produtosEstoqueBaixo == 1 ? 'produto' : 'produtos'} com estoque baixo',
                    ),
                  if (_produtosEstoqueBaixo > 0 && _parcelasVencidas > 0)
                    const SizedBox(height: 12),
                  if (_parcelasVencidas > 0)
                    _buildAlerta(
                      icon: Icons.warning_amber_rounded,
                      color: Colors.red,
                      titulo: 'Parcelas Vencidas',
                      descricao: '$_parcelasVencidas ${_parcelasVencidas == 1 ? 'parcela vencida' : 'parcelas vencidas'}',
                    ),
                ],
              ),
            ),
          
          // Mensagem quando está tudo ok
          if (_produtosEstoqueBaixo == 0 && _parcelasVencidas == 0)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tudo certo! Sem alertas no momento.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
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
