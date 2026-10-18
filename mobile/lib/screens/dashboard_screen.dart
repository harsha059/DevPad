import 'package:flutter/material.dart';
import '../models/prompt_item.dart';
import '../models/connection_state.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../widgets/context_injectors_bar.dart';
import '../widgets/prompt_card.dart';
import '../widgets/prompt_edit_sheet.dart';
import '../widgets/settings_dialog.dart';
import 'qr_scanner_screen.dart';

class DashboardScreen extends StatefulWidget {
  final StorageService storageService;
  final WebSocketService wsService;

  const DashboardScreen({
    super.key,
    required this.storageService,
    required this.wsService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _scratchController = TextEditingController();

  List<PromptItem> _allPrompts = [];
  List<PromptItem> _filteredPrompts = [];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadPrompts();
    _searchController.addListener(_filterPrompts);
    widget.wsService.addListener(_onWsStateChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scratchController.dispose();
    widget.wsService.removeListener(_onWsStateChange);
    super.dispose();
  }

  void _onWsStateChange() {
    if (mounted) setState(() {});
  }

  void _loadPrompts() {
    final custom = widget.storageService.getCustomPrompts();
    setState(() {
      _allPrompts = [...StorageService.defaultPrompts, ...custom];
      _filterPrompts();
    });
  }

  void _filterPrompts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPrompts = _allPrompts.where((p) {
        final matchesCat = _selectedCategory == 'All' || p.category == _selectedCategory;
        final matchesQuery = p.title.toLowerCase().contains(query) ||
            p.content.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query);
        return matchesCat && matchesQuery;
      }).toList();
    });
  }

  List<String> get _categories {
    final set = {'All'};
    for (final p in _allPrompts) {
      set.add(p.category);
    }
    return set.toList();
  }

  Future<void> _toggleConnection() async {
    if (widget.wsService.isConnected) {
      widget.wsService.disconnect();
    } else {
      await widget.wsService.connect(
        host: widget.storageService.laptopIp,
        port: widget.storageService.laptopPort,
        token: widget.storageService.authToken,
      );
    }
  }

  void _injectContext(String tag) {
    final text = _scratchController.text;
    final selection = _scratchController.selection;
    if (selection.isValid && selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, '$tag ');
      _scratchController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + tag.length + 1),
      );
    } else {
      _scratchController.text = text.isEmpty ? '$tag ' : '$text $tag ';
    }
  }

  Future<void> _sendTextToDesktop(String text, {bool force = false}) async {
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send empty text.')),
      );
      return;
    }

    if (!widget.wsService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to desktop companion. Connect first.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final response = await widget.wsService.insertText(
      text: text,
      profile: widget.storageService.activeProfile,
      force: force,
    );

    if (!mounted) return;

    if (response.isOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pasted text into ${response.activeWindow ?? "target application"}!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else if (response.isWarning && response.warningCode == 'WINDOW_MISMATCH') {
      _showWindowMismatchDialog(text, response);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action failed: ${response.error ?? "Unknown error"}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showWindowMismatchDialog(String text, ActionResponse response) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text('Target Mismatch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '${response.message}\n\nDo you want to paste anyway into the active window?',
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _sendTextToDesktop(text, force: true);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.amber[700]),
            child: const Text('Paste Anyway', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openEditSheet([PromptItem? prompt]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111614),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => PromptEditSheet(
        initialPrompt: prompt,
        onSave: (savedPrompt) async {
          final customList = widget.storageService.getCustomPrompts();
          final index = customList.indexWhere((p) => p.id == savedPrompt.id);
          if (index >= 0) {
            customList[index] = savedPrompt;
          } else {
            customList.add(savedPrompt);
          }
          await widget.storageService.saveCustomPrompts(customList);
          _loadPrompts();
        },
      ),
    );
  }

  void _deleteCustomPrompt(PromptItem prompt) async {
    final customList = widget.storageService.getCustomPrompts();
    customList.removeWhere((p) => p.id == prompt.id);
    await widget.storageService.saveCustomPrompts(customList);
    _loadPrompts();
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

  void _openSettings() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => SettingsDialog(
        storageService: widget.storageService,
        wsService: widget.wsService,
        onScanQr: _openQrScanner,
      ),
    );
    if (updated == true && mounted) {
      setState(() {});
    }
  }

  Widget _buildConnectionBadge() {
    final status = widget.wsService.status;
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case ConnectionStatus.authenticated:
        color = const Color(0xFF10B981); // Emerald
        label = 'Connected';
        icon = Icons.check_circle;
        break;
      case ConnectionStatus.connecting:
        color = Colors.amber;
        label = 'Connecting...';
        icon = Icons.sync;
        break;
      case ConnectionStatus.connected:
        color = Colors.cyan;
        label = 'Authenticating';
        icon = Icons.lock_open;
        break;
      case ConnectionStatus.error:
        color = Colors.redAccent;
        label = 'Connection Error';
        icon = Icons.error_outline;
        break;
      case ConnectionStatus.disconnected:
        color = Colors.white38;
        label = 'Offline';
        icon = Icons.cloud_off;
        break;
    }

    return InkWell(
      onTap: _toggleConnection,
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.terminal_rounded, size: 20, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DevPad',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                Text(
                  'Profile: ${widget.storageService.activeProfile.toUpperCase()}',
                  style: TextStyle(fontSize: 10, color: theme.colorScheme.primary.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          _buildConnectionBadge(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Connection Settings',
            onPressed: _openSettings,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              // Context Injectors Bar
              ContextInjectorsBar(onInject: _injectContext),
              const SizedBox(height: 12),

              // Interactive Scratchpad / Custom Prompt Formatter
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF131816),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _scratchController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Type or click a prompt below to prepare text for Cursor...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.35)),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (_scratchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 16, color: Colors.white38),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _scratchController.clear(),
                          ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () => _sendTextToDesktop(_scratchController.text),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: const Color(0xFF041E15),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 14),
                          label: const Text(
                            'Send to PC',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Search & Filter Header
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white38),
                        hintText: 'Search prompt library...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: const Color(0xFF131816),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _openEditSheet(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF161E1A),
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _categories.map((cat) {
                    final selected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: FilterChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            _selectedCategory = cat;
                            _filterPrompts();
                          });
                        },
                        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                        checkmarkColor: theme.colorScheme.primary,
                        backgroundColor: const Color(0xFF131816),
                        side: BorderSide(
                          color: selected
                              ? theme.colorScheme.primary
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : Colors.white60,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 8),

              // Prompts List
              Expanded(
                child: _filteredPrompts.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 40, color: Colors.white24),
                            SizedBox(height: 8),
                            Text(
                              'No prompts found.',
                              style: TextStyle(color: Colors.white38),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filteredPrompts.length,
                        itemBuilder: (ctx, index) {
                          final prompt = _filteredPrompts[index];
                          return PromptCard(
                            prompt: prompt,
                            onTap: () {
                              _scratchController.text = prompt.content;
                            },
                            onSend: () {
                              _sendTextToDesktop(prompt.content);
                            },
                            onDelete: prompt.isCustom
                                ? () => _deleteCustomPrompt(prompt)
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

