# 🚀 Como Executar o App Flutter

## Opção 1: Usando o Script (MAIS FÁCIL)

1. Vá na pasta `estoque_mobile`
2. Dê duplo clique no arquivo **executar_app.bat**
3. Aguarde o Chrome abrir
4. Faça login:
   - Login: `admin`
   - Senha: `Sorv@2026#Camila!`

---

## Opção 2: Linha de Comando

Abra o CMD ou PowerShell na pasta `estoque_mobile` e execute:

```cmd
C:\flutter\bin\flutter.bat run -d chrome
```

---

## Opção 3: Adicionar Flutter ao PATH (Permanente)

Para poder usar `flutter` de qualquer lugar:

1. Pressione **Windows + R**
2. Digite: `sysdm.cpl` e pressione Enter
3. Vá na aba **Avançado**
4. Clique em **Variáveis de Ambiente**
5. Em **Variáveis do sistema**, encontre **Path**
6. Clique em **Editar**
7. Clique em **Novo**
8. Adicione: `C:\flutter\bin`
9. Clique em **OK** em todas as janelas
10. Feche e abra o CMD novamente

Depois disso, você pode usar:
```cmd
flutter run -d chrome
```

---

## 📱 Executar no Android

Se tiver um celular Android conectado ou emulador:

```cmd
C:\flutter\bin\flutter.bat run
```

---

## 🔨 Build para Produção

**Android APK:**
```cmd
C:\flutter\bin\flutter.bat build apk --release
```

O APK estará em:
```
build/app/outputs/flutter-apk/app-release.apk
```

Você pode copiar esse APK para o celular e instalar!

---

## 🌐 Testar no Navegador (Sem Instalar)

Se não quiser instalar no celular, pode usar direto no Chrome:

1. Execute o app no Chrome (opção 1 ou 2)
2. O Chrome vai abrir automaticamente
3. Use normalmente como se fosse um app

---

## 🔑 Credenciais

**Administrador:**
- Login: `admin`
- Senha: `Sorv@2026#Camila!`

**API em Produção:**
- URL: `https://sorveteria-camila-api.onrender.com`

---

## ⚠️ Problemas Comuns

### "Flutter não encontrado"
- Use o caminho completo: `C:\flutter\bin\flutter.bat`
- Ou adicione ao PATH (opção 3)

### "Chrome não abre"
- Verifique se o Chrome está instalado
- Tente: `C:\flutter\bin\flutter.bat devices` para ver dispositivos disponíveis

### "Erro de conexão com API"
- Verifique se a API está no ar: https://sorveteria-camila-api.onrender.com/docs
- Verifique sua conexão com internet

---

## 🎯 Próximos Passos

Após testar no navegador:
1. Fazer build do APK
2. Instalar no celular
3. Cadastrar produtos da sorveteria
4. Testar fluxo completo de vendas
