# Estoque Mobile

App Flutter para gerenciamento de estoque integrado com a API FastAPI.

## Funcionalidades

- Login com autenticação JWT
- Lista de produtos com estoque atual
- Baixa de estoque (OPERADOR e ADMIN)
- Entrada de estoque (apenas ADMIN)
- Cadastro de produtos (apenas ADMIN)

## Instalação

```bash
# Instalar dependências
flutter pub get

# Executar
flutter run
```

## Configuração

Editar `lib/services/api_service.dart` e alterar a URL da API:

```dart
static const String baseUrl = 'https://sua-api.onrender.com';
```

## Segurança Implementada

- Token JWT em todas requisições
- Validação de perfil no frontend E backend
- Nunca atualiza estoque diretamente
- Sempre registra movimentação via API
- Backend valida todas operações com transações

## Estrutura

```
lib/
├── main.dart
├── services/
│   ├── auth_service.dart
│   └── api_service.dart
└── screens/
    ├── login_screen.dart
    ├── home_screen.dart
    ├── produtos_screen.dart
    ├── cadastro_produto_screen.dart
    ├── baixa_estoque_screen.dart
    └── entrada_estoque_screen.dart
```
