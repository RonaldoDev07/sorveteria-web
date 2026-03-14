import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/offline_service.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineService>(
      builder: (context, offlineService, child) {
        if (offlineService.isOnline && offlineService.operacoesPendentesCount == 0) {
          return const SizedBox.shrink();
        }

        return Material(
          elevation: 4,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: offlineService.isOnline
                    ? [const Color(0xFF2563EB), const Color(0xFF60A5FA)]
                    : [Colors.orange.shade400, Colors.orange.shade600],
              ),
            ),
            child: Row(
              children: [
                Icon(
                  offlineService.isOnline
                      ? Icons.cloud_upload_outlined
                      : Icons.cloud_off_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    offlineService.isOnline
                        ? 'Sincronizando ${offlineService.operacoesPendentesCount} operação(ões)...'
                        : 'Modo offline - ${offlineService.operacoesPendentesCount} operação(ões) pendente(s)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (offlineService.isOnline && offlineService.operacoesPendentesCount > 0)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
