import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/text_formatters.dart';

class HomeSummaryCard extends StatefulWidget {
  const HomeSummaryCard({super.key});

  @override
  State<HomeSummaryCard> createState() => _HomeSummaryCardState();
}

class _HomeSummaryCardState extends State<HomeSummaryCard> {
  bool _isLoading = true;
  double _vendasHoje = 0.0;
  int _produtosEstoqueBaixo = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _carregarResumo();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _carregarResumo();
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
      final results = await Future.wait([
        _buscarVendasHoje(auth.token!),
        _buscarProdutosEstoqueBaixo(auth.token!),
      ]);
      if (mounted) {
        setState(() {
          _vendasHoje = results[0] as double;
          _produtosEstoqueBaixo = results[1] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<double> _buscarVendasHoje(String token) async {
    try {
      final hoje = DateTime.now();
      final dataInicio =
          '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
      final movimentacoes = await ApiService.getMovimentacoes(token);
      double total = 0.0;
      for (var mov in movimentacoes) {
        if (mov['tipo'] == 'SAIDA') {
          final dataHora = mov['data_hora'] ?? '';
          if (dataHora.isNotEmpty) {
            try {
              final d = DateTime.parse(dataHora);
              final ds =
                  '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
              if (ds == dataInicio) {
                final v = mov['valor_unitario'];
                final q = mov['quantidade'];
                if (v != null && q != null) {
                  total += (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0) *
                      (q is num ? q.toDouble() : double.tryParse(q.toString()) ?? 0.0);
                }
              }
            } catch (_) {}
          }
        }
      }
      return total;
    } catch (_) {
      return 0.0;
    }
  }

  Future<int> _buscarProdutosEstoqueBaixo(String token) async {
    try {
      final produtos = await ApiService.getProdutos(token);
      return produtos.where((p) {
        final e = p['estoque_atual'];
        return (e is num ? e : double.tryParse(e.toString()) ?? 0) < 5;
      }).length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: AppTheme.radiusLg,
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: _isLoading ? _buildSkeleton() : _buildContent(),
    );
  }

  Widget _buildSkeleton() {
    return Row(
      children: [
        _SkeletonBox(width: 120, height: 48),
        const SizedBox(width: 12),
        Container(width: 1, height: 40, color: AppTheme.border),
        const SizedBox(width: 12),
        _SkeletonBox(width: 100, height: 48),
        const Spacer(),
        _SkeletonBox(width: 60, height: 28, radius: 20),
      ],
    );
  }

  Widget _buildContent() {
    return Row(
      children: [
        // Vendas hoje
        Expanded(
          child: _StatItem(
            icon: Icons.trending_up_rounded,
            iconColor: AppTheme.success,
            label: 'Vendas hoje',
            value: formatarMoeda(_vendasHoje),
            valueColor: AppTheme.success,
          ),
        ),
        Container(width: 1, height: 44, color: AppTheme.border),
        Expanded(
          child: _produtosEstoqueBaixo > 0
              ? _StatItem(
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppTheme.warning,
                  label: 'Estoque baixo',
                  value: '$_produtosEstoqueBaixo produto${_produtosEstoqueBaixo > 1 ? 's' : ''}',
                  valueColor: AppTheme.warning,
                )
              : _StatItem(
                  icon: Icons.check_circle_rounded,
                  iconColor: AppTheme.success,
                  label: 'Estoque',
                  value: 'Tudo OK',
                  valueColor: AppTheme.success,
                ),
        ),
        // Botão refresh
        GestureDetector(
          onTap: () {
            setState(() => _isLoading = true);
            _carregarResumo();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: AppTheme.radiusSm,
            ),
            child: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.primary),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: AppTheme.radiusSm,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
