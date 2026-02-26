#!/usr/bin/env python3
"""
Script para gerar favicon.ico a partir do favicon.png
Requer: pip install Pillow
"""

from PIL import Image
import os

def gerar_favicon():
    """Gera favicon.ico a partir do favicon.png"""
    
    # Caminhos
    png_path = "web/favicon.png"
    ico_path = "web/favicon.ico"
    
    # Verificar se o PNG existe
    if not os.path.exists(png_path):
        print(f"❌ Arquivo {png_path} não encontrado!")
        print("   Usando ícone padrão...")
        
        # Criar um ícone simples com sorvete emoji
        img = Image.new('RGBA', (32, 32), (156, 39, 176, 255))  # Cor lilás
        
        # Salvar como ICO
        img.save(ico_path, format='ICO', sizes=[(16, 16), (32, 32), (48, 48)])
        print(f"✅ Favicon padrão criado: {ico_path}")
        return
    
    try:
        # Abrir o PNG
        img = Image.open(png_path)
        
        # Converter para RGBA se necessário
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Salvar como ICO com múltiplos tamanhos
        img.save(ico_path, format='ICO', sizes=[(16, 16), (32, 32), (48, 48)])
        
        print(f"✅ Favicon gerado com sucesso: {ico_path}")
        print(f"   Tamanhos: 16x16, 32x32, 48x48")
        
    except Exception as e:
        print(f"❌ Erro ao gerar favicon: {e}")
        print("   Criando favicon padrão...")
        
        # Criar um ícone simples como fallback
        img = Image.new('RGBA', (32, 32), (156, 39, 176, 255))
        img.save(ico_path, format='ICO', sizes=[(16, 16), (32, 32)])
        print(f"✅ Favicon padrão criado: {ico_path}")

if __name__ == "__main__":
    print("🎨 Gerando favicon.ico...")
    gerar_favicon()
