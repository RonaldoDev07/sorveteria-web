import 'package:flutter/services.dart';

/// Formatador para CPF (XXX.XXX.XXX-XX)
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    if (text.length > 11) {
      return oldValue;
    }
    
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) {
        buffer.write('.');
      } else if (i == 9) {
        buffer.write('-');
      }
      buffer.write(text[i]);
    }
    
    final formatted = buffer.toString();
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatador para CNPJ (XX.XXX.XXX/XXXX-XX)
class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    if (text.length > 14) {
      return oldValue;
    }
    
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 5) {
        buffer.write('.');
      } else if (i == 8) {
        buffer.write('/');
      } else if (i == 12) {
        buffer.write('-');
      }
      buffer.write(text[i]);
    }
    
    final formatted = buffer.toString();
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatador inteligente para CPF ou CNPJ
/// Detecta automaticamente se é CPF (11 dígitos) ou CNPJ (14 dígitos)
class CpfCnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    if (text.length > 14) {
      return oldValue;
    }
    
    final buffer = StringBuffer();
    
    // Se tem até 11 dígitos, formata como CPF
    if (text.length <= 11) {
      for (int i = 0; i < text.length; i++) {
        if (i == 3 || i == 6) {
          buffer.write('.');
        } else if (i == 9) {
          buffer.write('-');
        }
        buffer.write(text[i]);
      }
    } else {
      // Se tem mais de 11 dígitos, formata como CNPJ
      for (int i = 0; i < text.length; i++) {
        if (i == 2 || i == 5) {
          buffer.write('.');
        } else if (i == 8) {
          buffer.write('/');
        } else if (i == 12) {
          buffer.write('-');
        }
        buffer.write(text[i]);
      }
    }
    
    final formatted = buffer.toString();
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatador para telefone (XX) XXXXX-XXXX ou (XX) XXXX-XXXX
class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    if (text.length > 11) {
      return oldValue;
    }
    
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i == 0) {
        buffer.write('(');
      } else if (i == 2) {
        buffer.write(') ');
      } else if ((text.length == 11 && i == 7) || (text.length == 10 && i == 6)) {
        buffer.write('-');
      }
      buffer.write(text[i]);
    }
    
    final formatted = buffer.toString();
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
