# 📱 Como Instalar o Flutter no Windows

## Passo 1: Baixar o Flutter

1. Acesse: https://docs.flutter.dev/get-started/install/windows
2. Clique em "Download Flutter SDK"
3. Ou baixe direto: https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.0-stable.zip

## Passo 2: Extrair o arquivo

1. Extraia o arquivo ZIP baixado
2. Coloque a pasta `flutter` em `C:\`
3. O caminho final deve ser: `C:\flutter`

## Passo 3: Adicionar ao PATH

1. Pressione `Windows + R`
2. Digite: `sysdm.cpl` e pressione Enter
3. Vá na aba "Avançado"
4. Clique em "Variáveis de Ambiente"
5. Em "Variáveis do sistema", encontre "Path" e clique em "Editar"
6. Clique em "Novo"
7. Adicione: `C:\flutter\bin`
8. Clique em "OK" em todas as janelas

## Passo 4: Verificar instalação

Abra um NOVO terminal (PowerShell ou CMD) e execute:

```bash
flutter --version
```

Se aparecer a versão do Flutter, está instalado! ✅

## Passo 5: Fazer o build do projeto

```bash
cd "C:\Users\RonaldoDev\3D Objects\Aplicativo para controle de estoque 3 celulares\sorveteria-web-deploy"
flutter build web --release
```

Aguarde uns 2-3 minutos. Quando terminar, execute:

```bash
git add build/web
git commit -m "build: atualizar aplicação"
git push origin main
```

## Passo 6: Verificar no site

Aguarde 1-2 minutos e acesse: https://sorveteria-web-one.vercel.app

Pronto! 🎉

---

## Problemas comuns

### "flutter não é reconhecido"
- Feche TODOS os terminais e abra um novo
- Reinicie o computador se necessário

### Build demora muito
- É normal na primeira vez (pode levar 5-10 minutos)
- Próximos builds serão mais rápidos

### Erro de permissão
- Execute o terminal como Administrador
