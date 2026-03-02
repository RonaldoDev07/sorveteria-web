import 'package:flutter/material.dart';

/// Estilos padronizados para o módulo financeiro
class FinanceiroStyles {
  // Cores do módulo
  static const Color corVenda = Color(0xFF10B981); // Verde
  static const Color corCompra = Color(0xFF8B5CF6); // Roxo
  static const Color corParcela = Color(0xFF3B82F6); // Azul
  static const Color corCliente = Color(0xFF06B6D4); // Ciano
  static const Color corFornecedor = Color(0xFFF59E0B); // Laranja
  
  // Estilo para botões primários
  static ButtonStyle botaoPrimario(Color cor) {
    return ElevatedButton.styleFrom(
      backgroundColor: cor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
  
  // Estilo para botões com ícone
  static ButtonStyle botaoComIcone(Color cor) {
    return ElevatedButton.styleFrom(
      backgroundColor: cor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
  
  // Estilo para AppBar
  static AppBar appBar(String titulo, Color cor, {List<Widget>? actions}) {
    return AppBar(
      title: Text(titulo),
      backgroundColor: cor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: actions,
    );
  }
  
  // Ícones do módulo
  static const IconData iconeVenda = Icons.shopping_cart;
  static const IconData iconeCompra = Icons.shopping_bag;
  static const IconData iconeCliente = Icons.person;
  static const IconData iconeFornecedor = Icons.business;
  static const IconData iconeParcela = Icons.calendar_today;
  static const IconData iconeAdicionar = Icons.add_circle;
  static const IconData iconeSalvar = Icons.check_circle;
  static const IconData iconeCancelar = Icons.cancel;
}
