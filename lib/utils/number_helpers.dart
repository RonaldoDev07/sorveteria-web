/// Funções auxiliares para conversão e formatação de números
/// Centraliza a lógica de conversão para evitar duplicação de código

/// Converte qualquer valor para double de forma segura
/// Trata números, strings e valores nulos
double toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  
  // Tentar converter string
  final str = value.toString().replaceAll(',', '.');
  return double.tryParse(str) ?? 0.0;
}

/// Converte qualquer valor para int de forma segura
int toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  
  // Tentar converter string
  final str = value.toString().replaceAll(',', '.');
  final doubleValue = double.tryParse(str);
  return doubleValue?.toInt() ?? 0;
}

/// Verifica se um valor numérico é válido (não nulo e maior que zero)
bool isValidNumber(dynamic value) {
  final num = toDouble(value);
  return num > 0;
}

/// Formata um número removendo zeros desnecessários
/// Exemplo: 3.000 -> 3, 3.500 -> 3.5, 3.865 -> 3.865
String formatNumber(dynamic value) {
  if (value == null) return '0';
  
  final numero = toDouble(value);
  
  // Se for inteiro, retornar sem casas decimais
  if (numero == numero.toInt()) {
    return numero.toInt().toString();
  }
  
  // Remover zeros à direita
  return numero.toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), '');
}
