/// Model para Dashboard Financeiro
class DashboardFinanceiro {
  final double totalAReceber;
  final double totalAPagar;
  final int contasAtrasadasReceber;
  final int contasAtrasadasPagar;
  final int contasVencendoHoje;
  final int contasVencendoSemana;

  DashboardFinanceiro({
    required this.totalAReceber,
    required this.totalAPagar,
    required this.contasAtrasadasReceber,
    required this.contasAtrasadasPagar,
    required this.contasVencendoHoje,
    required this.contasVencendoSemana,
  });

  factory DashboardFinanceiro.fromJson(Map<String, dynamic> json) {
    return DashboardFinanceiro(
      totalAReceber: (json['total_a_receber'] ?? 0).toDouble(),
      totalAPagar: (json['total_a_pagar'] ?? 0).toDouble(),
      contasAtrasadasReceber: json['contas_atrasadas_receber'] ?? 0,
      contasAtrasadasPagar: json['contas_atrasadas_pagar'] ?? 0,
      contasVencendoHoje: json['contas_vencendo_hoje'] ?? 0,
      contasVencendoSemana: json['contas_vencendo_semana'] ?? 0,
    );
  }

  double get saldoLiquido => totalAReceber - totalAPagar;
  int get totalContasAtrasadas => contasAtrasadasReceber + contasAtrasadasPagar;
}
