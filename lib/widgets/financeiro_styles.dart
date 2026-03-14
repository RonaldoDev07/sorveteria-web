import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Estilos padronizados para o módulo financeiro
class FinanceiroStyles {
  // Cores do módulo
  static const Color corVenda = Color(0xFF059669);
  static const Color corCompra = Color(0xFF7C3AED);
  static const Color corParcela = Color(0xFF2563EB);
  static const Color corCliente = Color(0xFF0891B2);
  static const Color corFornecedor = Color(0xFFD97706);

  // Gradientes
  static const LinearGradient gradientVenda = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientCompra = LinearGradient(
    colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientCliente = LinearGradient(
    colors: [Color(0xFF0369A1), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientFornecedor = LinearGradient(
    colors: [Color(0xFFB45309), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Estilo para botões primários
  static ButtonStyle botaoPrimario(Color cor) {
    return ElevatedButton.styleFrom(
      backgroundColor: cor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
      elevation: 0,
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }

  // Estilo para botões com ícone
  static ButtonStyle botaoComIcone(Color cor) {
    return ElevatedButton.styleFrom(
      backgroundColor: cor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
      elevation: 0,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  // AppBar com gradiente
  static PreferredSizeWidget appBar(
    String titulo,
    List<Color> cores, {
    List<Widget>? actions,
    bool showBack = true,
  }) {
    return GradientAppBar(
      title: titulo,
      colors: cores,
      actions: actions,
      showBackButton: showBack,
    );
  }

  // Ícones do módulo
  static const IconData iconeVenda = Icons.point_of_sale_rounded;
  static const IconData iconeCompra = Icons.local_shipping_rounded;
  static const IconData iconeCliente = Icons.person_rounded;
  static const IconData iconeFornecedor = Icons.business_rounded;
  static const IconData iconeParcela = Icons.calendar_month_rounded;
  static const IconData iconeAdicionar = Icons.add_circle_rounded;
  static const IconData iconeSalvar = Icons.check_circle_rounded;
  static const IconData iconeCancelar = Icons.cancel_rounded;
}
