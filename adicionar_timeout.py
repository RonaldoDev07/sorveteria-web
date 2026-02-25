#!/usr/bin/env python3
"""
Script para adicionar timeout em todas as requisições HTTP do api_service.dart
"""

import re

# Ler o arquivo
with open('lib/services/api_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Padrão para encontrar requisições HTTP sem timeout
# Procura por: await http.METHOD(...); que não tenha .timeout antes do ;
pattern = r'(await http\.(get|post|put|delete|patch)\([^;]+\))(\s*;)'

# Função para substituir
def add_timeout(match):
    request = match.group(1)
    semicolon = match.group(3)
    
    # Verificar se já tem timeout
    if '.timeout(' in request:
        return match.group(0)  # Não modificar
    
    return f'{request}.timeout(ApiConfig.timeout){semicolon}'

# Aplicar substituição
new_content = re.sub(pattern, add_timeout, content)

# Salvar o arquivo
with open('lib/services/api_service.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)

print("✅ Timeout adicionado em todas as requisições HTTP!")
print("📝 Arquivo atualizado: lib/services/api_service.dart")
