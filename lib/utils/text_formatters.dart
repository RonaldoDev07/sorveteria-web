/// Funções utilitárias para formatação de dados

import 'package:intl/intl.dart';

/// Formata CPF no padrão XXX.XXX.XXX-XX
String formatarCpf(String cpf) {
  final numeros = cpf.replaceAll(RegExp(r'[^0-9]'), '');
  
  if (numeros.length != 11) {
    return cpf; // Retorna original se não tiver 11 dígitos
  }
  
  return '${numeros.substring(0, 3)}.${numeros.substring(3, 6)}.${numeros.substring(6, 9)}-${numeros.substring(9, 11)}';
}

/// Formata CNPJ no padrão XX.XXX.XXX/XXXX-XX
String formatarCnpj(String cnpj) {
  final numeros = cnpj.replaceAll(RegExp(r'[^0-9]'), '');
  
  if (numeros.length != 14) {
    return cnpj; // Retorna original se não tiver 14 dígitos
  }
  
  return '${numeros.substring(0, 2)}.${numeros.substring(2, 5)}.${numeros.substring(5, 8)}/${numeros.substring(8, 12)}-${numeros.substring(12, 14)}';
}

/// Formata CPF ou CNPJ automaticamente
String formatarCpfCnpj(String documento) {
  final numeros = documento.replaceAll(RegExp(r'[^0-9]'), '');
  
  if (numeros.length == 11) {
    return formatarCpf(documento);
  } else if (numeros.length == 14) {
    return formatarCnpj(documento);
  }
  
  return documento; // Retorna original se não for CPF nem CNPJ
}

/// Formata telefone no padrão (XX) XXXXX-XXXX ou (XX) XXXX-XXXX
String formatarTelefone(String telefone) {
  final numeros = telefone.replaceAll(RegExp(r'[^0-9]'), '');
  
  if (numeros.length == 11) {
    // Celular: (XX) XXXXX-XXXX
    return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 7)}-${numeros.substring(7, 11)}';
  } else if (numeros.length == 10) {
    // Fixo: (XX) XXXX-XXXX
    return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 6)}-${numeros.substring(6, 10)}';
  }
  
  return telefone; // Retorna original se não tiver 10 ou 11 dígitos
}

/// Formata data no padrão brasileiro: dd/MM/yyyy
String formatarData(DateTime data) {
  return DateFormat('dd/MM/yyyy', 'pt_BR').format(data);
}

/// Formata data e hora no padrão brasileiro: dd/MM/yyyy HH:mm
String formatarDataHora(DateTime dataHora) {
  return DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(dataHora);
}

/// Formata data e hora completa: dd/MM/yyyy HH:mm:ss
String formatarDataHoraCompleta(DateTime dataHora) {
  return DateFormat('dd/MM/yyyy HH:mm:ss', 'pt_BR').format(dataHora);
}

/// Formata apenas a hora: HH:mm
String formatarHora(DateTime dataHora) {
  return DateFormat('HH:mm', 'pt_BR').format(dataHora);
}

/// Formata moeda brasileira: R$ 1.234,56
String formatarMoeda(dynamic valor) {
  final valorDouble = valor is String ? double.tryParse(valor) ?? 0.0 : (valor as num).toDouble();
  return NumberFormat.currency(locale: 'pt_BR', symbol: r'R$').format(valorDouble);
}
