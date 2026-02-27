/// Configuração da API
/// 
/// IMPORTANTE: Atualizar baseUrl após fazer deploy da API no Render

class ApiConfig {
  // DESENVOLVIMENTO (localhost)
  static const String devUrl = 'http://127.0.0.1:8000';
  
  // PRODUÇÃO (Render Oregon) - SEMPRE USAR HTTPS
  static const String prodUrl = 'https://sorveteria-camila-api.onrender.com';
  
  // URL atual - TROCAR ENTRE devUrl E prodUrl CONFORME NECESSÁRIO
  static const String baseUrl = prodUrl;  // ← USANDO PRODUÇÃO
  
  // Timeout das requisições (aumentado para cold start do Render)
  // Render free tier pode demorar até 180s para acordar
  static const Duration timeout = Duration(seconds: 180);
}
