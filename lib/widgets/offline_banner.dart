import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService.onStatusChange,
      initialData: true,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        if (isOnline) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          color: Colors.red.shade600,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'No internet connection',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }
}