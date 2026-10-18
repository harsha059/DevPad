import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/deck_profile.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../widgets/macro_button_tile.dart';
import '../widgets/edit_macro_dialog.dart';

class ShortcutDeckScreen extends StatefulWidget {
  final DeckProfile profile;
  final StorageService storageService;
  final WebSocketService wsService;
  final VoidCallback onProfilesUpdated;

  const ShortcutDeckScreen({
    super.key,
    required this.profile,
    required this.storageService,
    required this.wsService,
    required this.onProfilesUpdated,
  });

  @override
  State<ShortcutDeckScreen> createState() => _ShortcutDeckScreenState();
}

class _ShortcutDeckScreenState extends State<ShortcutDeckScreen> {
  late DeckProfile _profile;
  late PageController _pageController;
  int _currentPageIndex = 0;
  bool _isImmersive = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    if (_isImmersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  void _toggleImmersive() {
    setState(() {
      _isImmersive = !_isImmersive;
      if (_isImmersive) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  Future<void> _handleButtonTap(MacroButton button) async {
    // 1. If folder/page navigation, switch page directly offline
    if (button.actionType == ActionType.folderNavigation) {
      final pageTarget = int.tryParse(button.payload.replaceAll('page_', '')) ??
          (_currentPageIndex + 1);
      if (pageTarget < _profile.pages.length) {
        _pageController.animateToPage(
          pageTarget,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Target page does not exist.')),
        );
      }
      return;
    }

    // 2. Offline check
    if (!widget.wsService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_off, size: 16, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Offline mode: Connect to PC to run "${button.label}"'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF19212D),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // 3. Online actions
    if (button.actionType == ActionType.textMacro) {
      final response = await widget.wsService.insertText(
        text: button.payload,
        profile: _profile.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.isOk
                ? 'Executed macro: "${button.label}"'
                : 'Failed: ${response.error ?? "Action error"}'),
            backgroundColor: response.isOk ? const Color(0xFF36E1BD) : Colors.redAccent,
          ),
        );
      }
    } else {
      // For shortcuts or app launch, send formatted desktop action
      final response = await widget.wsService.sendAction('desktop_macro', {
        'type': button.actionType.name,
        'payload': button.payload,
        'profile': _profile.id,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.isOk
                ? 'Sent command: ${button.label}'
                : 'Action: ${response.error ?? "Sent to desktop"}'),
            backgroundColor: const Color(0xFF36E1BD),
          ),
        );
      }
    }
  }

  void _openEditButton(int pageIndex, int buttonIndex) {
    final currentButton = _profile.pages[pageIndex][buttonIndex];
    showDialog(
      context: context,
      builder: (ctx) => EditMacroDialog(
        initialButton: currentButton,
        onSave: (updated) => _updateButton(pageIndex, buttonIndex, updated),
        onDelete: () => _deleteButton(pageIndex, buttonIndex),
      ),
    );
  }

  void _openAddButton(int pageIndex) {
    showDialog(
      context: context,
      builder: (ctx) => EditMacroDialog(
        onSave: (newBtn) => _addButton(pageIndex, newBtn),
      ),
    );
  }

  Future<void> _persistProfile() async {
    final allProfiles = widget.storageService.getDeckProfiles();
    final idx = allProfiles.indexWhere((p) => p.id == _profile.id);
    if (idx >= 0) {
      allProfiles[idx] = _profile;
    } else {
      allProfiles.add(_profile);
    }
    await widget.storageService.saveDeckProfiles(allProfiles);
    widget.onProfilesUpdated();
  }

  void _updateButton(int pageIndex, int buttonIndex, MacroButton updated) {
    setState(() {
      _profile.pages[pageIndex][buttonIndex] = updated;
    });
    _persistProfile();
  }

  void _deleteButton(int pageIndex, int buttonIndex) {
    setState(() {
      _profile.pages[pageIndex].removeAt(buttonIndex);
    });
    _persistProfile();
  }

  void _addButton(int pageIndex, MacroButton newBtn) {
    setState(() {
      _profile.pages[pageIndex].add(newBtn);
    });
    _persistProfile();
  }

  void _addNewPage() {
    setState(() {
      _profile.pages.add([]);
    });
    _persistProfile();
    _pageController.animateToPage(
      _profile.pages.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(_profile.accentColor);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1017),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                    tooltip: 'Back to Profiles',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.stream_rounded, size: 18, color: accentColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _profile.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  // Page Indicators
                  if (_profile.pages.length > 1)
                    Row(
                      children: List.generate(_profile.pages.length, (idx) {
                        final active = _currentPageIndex == idx;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active ? accentColor : Colors.white24,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.add_to_photos_rounded, color: Colors.white70, size: 20),
                    tooltip: 'Add Page',
                    onPressed: _addNewPage,
                  ),
                  IconButton(
                    icon: Icon(
                      _isImmersive ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                      color: Colors.white70,
                      size: 22,
                    ),
                    tooltip: _isImmersive ? 'Exit Fullscreen' : 'Fullscreen Stream Deck Mode',
                    onPressed: _toggleImmersive,
                  ),
                ],
              ),
            ),

            // Page View with Responsive Grid
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _profile.pages.length,
                onPageChanged: (idx) => setState(() => _currentPageIndex = idx),
                itemBuilder: (ctx, pageIndex) {
                  final buttons = _profile.pages[pageIndex];

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive columns: 4 columns landscape default
                      final isLandscape = constraints.maxWidth > constraints.maxHeight;
                      final colCount = isLandscape ? 4 : 3;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        child: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: colCount,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.15,
                          ),
                          itemCount: buttons.length + 1, // +1 for Add button
                          itemBuilder: (ctx, btnIndex) {
                            if (btnIndex == buttons.length) {
                              // Add button tile
                              return InkWell(
                                onTap: () => _openAddButton(pageIndex),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF19212D).withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_circle_outline_rounded,
                                          size: 28, color: accentColor.withValues(alpha: 0.7)),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Add Macro',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final button = buttons[btnIndex];
                            return MacroButtonTile(
                              button: button,
                              onTap: () => _handleButtonTap(button),
                              onLongPress: () => _openEditButton(pageIndex, btnIndex),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
