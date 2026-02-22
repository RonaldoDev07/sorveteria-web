import 'package:intl/intl.dart';

class BrazilianFormatters {
  static final currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  static final numberFormatter = NumberFormat.decimalPattern('pt_BR');

  static String formatCurrency(dynamic value) {
    if (value == null) return 'R\$ 0,00';
    
    double doubleValue;
    if (value is String) {
      doubleValue = double.tryParse(value) ?? 0.0;
    } else if (value is num) {
      doubleValue = value.toDouble();
    } else {
      return 'R\$ 0,00';
    }
    
    return currencyFormatter.format(doubleValue);
  }

  static String formatNumber(dynamic value) {
    if (value == null) return '0';
    
    double doubleValue;
    if (value is String) {
      doubleValue = double.tryParse(value) ?? 0.0;
    } else if (value is num) {
      doubleValue = value.toDouble();
    } else {
      return '0';
    }
    
    // Se for número inteiro, não mostrar casas decimais
    if (doubleValue == doubleValue.toInt()) {
      return doubleValue.toInt().toString();
    }
    
    // Senão, formatar com padrão brasileiro e remover zeros à direita
    String formatted = numberFormatter.format(doubleValue);
    // Remove zeros à direita após a vírgula
    formatted = formatted.replaceAll(RegExp(r',0+$'), '');
    return formatted;
  }
}
