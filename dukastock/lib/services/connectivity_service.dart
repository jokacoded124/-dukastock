import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps connectivity_plus to expose a simple online/offline stream.
/// Used to show an offline banner and to guard network-dependent actions.
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  /// Stream of booleans: true = online, false = offline.
  /// Combines all connectivity result types into a single yes/no signal.
  static Stream<bool> get onStatusChange {
    return _connectivity.onConnectivityChanged.map((results) {
      return !results.contains(ConnectivityResult.none);
    });
  }

  /// One-off check, useful before firing a Firestore write (Add Product, etc).
  static Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }
}
