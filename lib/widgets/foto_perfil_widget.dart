import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import '../services/auth_service.dart';
import '../services/api_service.dart';

class FotoPerfilWidget extends StatelessWidget {
  final AuthService auth;

  const FotoPerfilWidget({super.key, required this.auth});

  void _selecionarFotoWeb(BuildContext context) {
    print('🔵 Abrindo página de upload');
    
    // Abrir página de upload em nova aba
    html.window.open('/upload.html', 'Upload Foto', 'width=600,height=600');
    
    // Fechar modal
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  void _removerFoto(BuildContext context) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
          ),
        ),
      );

      await ApiService.removerFoto(auth.token!);
      await auth.removerFoto();

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto removida com sucesso!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao remover foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarOpcoes(BuildContext context) {
    if (kIsWeb) {
      // Na web, mostrar modal com opções
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Foto de Perfil',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFFE91E63)),
                ),
                title: const Text('Escolher da galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _selecionarFotoWeb(context);
                },
              ),
              if (auth.fotoUrl != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_rounded, color: Colors.red),
                  ),
                  title: const Text('Remover foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _removerFoto(context);
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🟢 FotoPerfilWidget build - fotoUrl: ${auth.fotoUrl}');
    return GestureDetector(
      onTap: () {
        print('🟢 Avatar clicado!');
        _mostrarOpcoes(context);
      },
      child: Stack(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFE91E63).withOpacity(0.1),
            backgroundImage: auth.fotoUrl != null ? NetworkImage(auth.fotoUrl!) : null,
            child: auth.fotoUrl == null
                ? Text(
                    auth.username?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE91E63),
                    ),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
