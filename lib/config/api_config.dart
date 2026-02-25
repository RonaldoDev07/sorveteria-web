/// Configuração da API
/// 
/// IMPORTANTE: Atualizar baseUrl após fazer deploy da API no Render

class ApiConfig {
  // DESENVOLVIMENTO (localhost)
  static const String devUrl = 'http://127.0.0.1:8000';
  
  // PRODUÇÃO (Render)
  static const String prodUrl = 'https://sorveteria-camila-api-v3.onrender.com';
  
  // URL atual - TROCAR ENTRE devUrl E prodUrl CONFORME NECESSÁRIO
  static const String baseUrl = prodUrl;  // ← USANDO PRODUÇÃO
  
  // Timeout das requisições
  static const Duration timeout = Duration(seconds: 30);
}
