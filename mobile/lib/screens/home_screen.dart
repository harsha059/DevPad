import 'package:flutter/material.dart';
import '../models/deck_profile.dart';
import '../models/icon_helper.dart';
import '../models/connection_state.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/create_profile_dialog.dart';
import 'shortcut_deck_screen.dart';
import 'qr_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;
  final WebSocketService wsService;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.wsService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DeckProfile> _profiles = [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    widget.wsService.addListener(_onWsChange);
  }

  @override
  void dispose() {
    widget.wsService.removeListener(_onWsChange);
    super.dispose();
  }

  void _onWsChange() {
    if (mounted) setState(() {});
  }

  void _loadProfiles() {
    setState(() {
      _profiles = widget.storageService.getDeckProfiles();
    });
  }

  void _openDeck(DeckProfile profile) {
    widget.storageService.setActiveProfile(profile.id);

    // If connected, automatically activate / bring the application window to front on PC
    if (widget.wsService.isConnected) {
      widget.wsService.sendAction('activate_window', {
        'profile': profile.id,
      });
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ShortcutDeckScreen(
          profile: profile,
          storageService: widget.storageService,
          wsService: widget.wsService,
          onProfilesUpdated: _loadProfiles,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.05, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );
  }


  void _openQrScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => QrScannerScreen(
          storageService: widget.storageService,
          wsService: widget.wsService,
        ),
      ),
    );
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (ctx) => SettingsDialog(
        storageService: widget.storageService,
        wsService: widget.wsService,
        onScanQr: _openQrScanner,
      ),
    );
  }

  void _openCreateProfile() {
    showDialog(
      context: context,
      builder: (ctx) => CreateProfileDialog(
        onSave: (newProfile) async {
          final list = widget.storageService.getDeckProfiles();
          list.add(newProfile);
          await widget.storageService.saveDeckProfiles(list);
          _loadProfiles();
        },
      ),
    );
  }

  Widget _buildConnectionBadge() {
    final status = widget.wsService.status;
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case ConnectionStatus.authenticated:
        color = const Color(0xFF36E1BD); // Emerald accent
        label = 'Connected';
        icon = Icons.check_circle_rounded;
        break;
      case ConnectionStatus.connecting:
        color = Colors.amber;
        label = 'Connecting...';
        icon = Icons.sync_rounded;
        break;
      case ConnectionStatus.connected:
        color = Colors.cyan;
        label = 'Authenticating';
        icon = Icons.lock_open_rounded;
        break;
      case ConnectionStatus.error:
        color = Colors.redAccent;
        label = 'Offline / Error';
        icon = Icons.error_outline_rounded;
        break;
      case ConnectionStatus.disconnected:
        color = Colors.white38;
        label = 'Offline Deck';
        icon = Icons.cloud_off_rounded;
        break;
    }

    return InkWell(
      onTap: () async {
        if (widget.wsService.isConnected) {
          widget.wsService.disconnect();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Disconnected from PC companion.'),
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          final targetIp = widget.storageService.laptopIp;
          final targetPort = widget.storageService.laptopPort;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connecting to $targetIp:$targetPort...'),
              duration: const Duration(seconds: 1),
            ),
          );

          await widget.wsService.connect(
            host: targetIp,
            port: targetPort,
            token: widget.storageService.authToken,
          );

          if (!mounted) return;

          if (widget.wsService.isConnected) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connected & Authenticated!'),
                backgroundColor: Color(0xFF36E1BD),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.wsService.lastError ?? 'Connection failed. Check Settings.',
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      },

      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF36E1BD).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.dialpad_rounded, size: 20, color: Color(0xFF36E1BD)),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DevPad',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'STREAM DECK CONTROLLER',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF36E1BD),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          _buildConnectionBadge(),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white70),
            tooltip: 'Pair via QR Code',
            onPressed: _openQrScanner,
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white70),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;
              final colCount = isLandscape ? 4 : 2;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Row(
                      children: [
                        const Text(
                          'SELECT PROFILE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.white54,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _openCreateProfile,
                          icon: const Icon(Icons.add, size: 16, color: Color(0xFF36E1BD)),
                          label: const Text(
                            'New Profile',
                            style: TextStyle(fontSize: 12, color: Color(0xFF36E1BD), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: colCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: isLandscape ? 1.6 : 1.3,
                      ),
                      itemCount: _profiles.length,
                      itemBuilder: (ctx, index) {
                        final prof = _profiles[index];
                        final accent = Color(prof.accentColor);
                        final totalButtons = prof.pages.fold<int>(0, (sum, page) => sum + page.length);

                        return InkWell(
                          onTap: () => _openDeck(prof),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF19212D),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        IconHelper.getIcon(prof.iconName),
                                        size: 24,
                                        color: accent,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$totalButtons keys',
                                        style: const TextStyle(fontSize: 11, color: Colors.white60),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prof.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${prof.pages.length} page(s)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: accent.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}


