import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';

class SettingsDialog extends StatefulWidget {
  final StorageService storageService;
  final WebSocketService wsService;
  final VoidCallback onScanQr;

  const SettingsDialog({
    super.key,
    required this.storageService,
    required this.wsService,
    required this.onScanQr,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late final TextEditingController _ipController;
  late final TextEditingController _portController;
  late final TextEditingController _tokenController;
  late String _selectedProfile;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.storageService.laptopIp);
    _portController = TextEditingController(text: widget.storageService.laptopPort.toString());
    _tokenController = TextEditingController(text: widget.storageService.authToken);
    _selectedProfile = widget.storageService.activeProfile;
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8765;
    final token = _tokenController.text.trim();

    await widget.storageService.setLaptopIp(ip);
    await widget.storageService.setLaptopPort(port);
    await widget.storageService.setAuthToken(token);
    await widget.storageService.setActiveProfile(_selectedProfile);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _testPing() async {
    setState(() => _testing = true);
    final response = await widget.wsService.ping();
    if (mounted) {
      setState(() => _testing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.isOk
                ? 'Ping successful! Server responded with pong.'
                : 'Ping failed: ${response.error ?? "No response"}',
          ),
          backgroundColor: response.isOk ? const Color(0xFF36E1BD) : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF19212D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      title: Row(
        children: [
          const Icon(Icons.tune_rounded, color: Color(0xFF36E1BD)),
          const SizedBox(width: 10),
          const Text('DevPad Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onScanQr();
              },
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('Scan Workstation QR Code'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF36E1BD),
                side: const BorderSide(color: Color(0xFF36E1BD)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('MANUAL CONFIG', style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 1.1)),
                ),
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'Windows Laptop IP',
                hintText: 'e.g. 192.168.1.15',
                filled: true,
                fillColor: const Color(0xFF0B1017),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Companion Port',
                hintText: '8765',
                filled: true,
                fillColor: const Color(0xFF0B1017),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Pairing Token',
                hintText: 'Private pairing token',
                filled: true,
                fillColor: const Color(0xFF0B1017),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.wsService.isConnected)
              OutlinedButton.icon(
                onPressed: _testing ? null : _testPing,
                icon: const Icon(Icons.bolt, size: 16),
                label: Text(_testing ? 'Pinging...' : 'Test Ping Desktop'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF36E1BD),
                  side: BorderSide(color: const Color(0xFF36E1BD).withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF36E1BD),
            foregroundColor: const Color(0xFF0B1017),
          ),
          child: const Text('Save & Apply', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
