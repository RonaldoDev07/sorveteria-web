import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import '../services/auth_service.dart';
import '../services/api_service.dart';

class FotoPerfilWidget extends StatelessWidget {
  final AuthService auth;

  const FotoPerfilWidget({super.key, required this.auth});

  void _selecionarFotoWeb(BuildContext context) {
    html.window.open('/upload.html', 'Upload Foto', 'width=600,height=600');
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  void _removerFoto(BuildContext context) async {
    try {
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
            content: Text('Foto removida com sucesso'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarOpcoes(BuildContext context) {
    if (kIsWeb) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Foto de Perfil',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFFE91E63), size: 20),
                ),
                title: const Text('Escolher da galeria', style: TextStyle(fontSize: 13)),
                onTap: () {
                  Navigator.pop(context);
                  _selecionarFotoWeb(context);
                },
              ),
              if (auth.fotoUrl != null)
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                  ),
                  title: const Text('Remover foto', style: TextStyle(fontSize: 13)),
                  onTap: () {
                    Navigator.pop(context);
                    _removerFoto(context);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _mostrarOpcoes(context),
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
              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
