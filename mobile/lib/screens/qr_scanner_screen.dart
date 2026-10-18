import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';

class QrScannerScreen extends StatefulWidget {
  final StorageService storageService;
  final WebSocketService wsService;

  const QrScannerScreen({
    super.key,
    required this.storageService,
    required this.wsService,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  late final MobileScannerController _scannerController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        _processScannedData(barcode.rawValue!);
        break;
      }
    }
  }

  void _processScannedData(String rawData) {
    setState(() => _isProcessing = true);

    try {
      final jsonMap = json.decode(rawData) as Map<String, dynamic>;

      // 1. Validate payload structure & type
      if (jsonMap['type'] != 'devpad_pairing') {
        _showErrorDialog('Invalid QR Code', 'This QR code is not a DevPad pairing code.');
        return;
      }

      final version = jsonMap['version'] as int? ?? 1;
      if (version > 1) {
        _showErrorDialog('Unsupported Version', 'This QR code version is not supported by this client build.');
        return;
      }

      final host = jsonMap['host'] as String?;
      final port = jsonMap['port'] as int?;
      final pairingId = jsonMap['pairing_id'] as String?;
      final token = jsonMap['token'] as String?;
      final deviceName = jsonMap['device_name'] as String? ?? 'DevPad Workstation';
      final expiresAt = jsonMap['expires_at'] as int?;

      if (host == null || host.isEmpty || port == null || port <= 0 || pairingId == null || token == null) {
        _showErrorDialog('Malformed Payload', 'QR code contains incomplete connection parameters.');
        return;
      }

      // Check expiration
      if (expiresAt != null) {
        final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (nowSeconds > expiresAt) {
          _showErrorDialog('QR Code Expired', 'This pairing QR code has expired. Please generate a new one on your PC.');
          return;
        }
      }

      // Show confirmation dialog before saving or connecting
      _showPairingConfirmationDialog(
        deviceName: deviceName,
        host: host,
        port: port,
        token: token,
      );
    } catch (e) {
      _showErrorDialog('Parse Error', 'Failed to read QR code: malformed JSON format.');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF19212D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _isProcessing = false);
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF36E1BD)),
            child: const Text('Scan Again', style: TextStyle(color: Color(0xFF0B1017), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPairingConfirmationDialog({
    required String deviceName,
    required String host,
    required int port,
    required String token,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF19212D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF36E1BD), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.laptop_chromebook_rounded, color: Color(0xFF36E1BD)),
            SizedBox(width: 8),
            Text('Pair Workstation', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discovered Workstation: "$deviceName"',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Text('IP Address: $host', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text('Port: $port', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1017),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pairing status: Pending verification. Will store configuration.',
                      style: TextStyle(fontSize: 12, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _isProcessing = false);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () async {
              final rootNav = Navigator.of(context);
              final dialogNav = Navigator.of(ctx);

              await widget.storageService.setLaptopIp(host);
              await widget.storageService.setLaptopPort(port);
              await widget.storageService.setAuthToken(token);
              await widget.storageService.setPairedDeviceName(deviceName);

              dialogNav.pop();
              rootNav.pop(true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF36E1BD),
              foregroundColor: const Color(0xFF0B1017),
            ),
            child: const Text('Confirm & Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1017),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1017),
        elevation: 0,
        title: const Text('Scan Workstation QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, size: 20),
            onPressed: () => _scannerController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          // Subtle scanner overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF36E1BD), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF36E1BD).withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF19212D).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Text(
                'Scan the pairing_qr.png image on your computer screen (not terminal ASCII text)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
