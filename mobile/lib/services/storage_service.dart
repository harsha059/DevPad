import 'package:shared_preferences/shared_preferences.dart';
import '../models/prompt_item.dart';
import '../models/deck_profile.dart';

class StorageService {
  static const String _keyIp = 'devpad_laptop_ip';
  static const String _keyPort = 'devpad_laptop_port';
  static const String _keyToken = 'devpad_auth_token';
  static const String _keyProfile = 'devpad_active_profile';
  static const String _keyCustomPrompts = 'devpad_custom_prompts';
  static const String _keyDeckProfiles = 'devpad_deck_profiles_v2';
  static const String _keyPairedDevice = 'devpad_paired_device_name';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Connection Settings
  String get laptopIp => _prefs.getString(_keyIp) ?? '192.168.1.15';
  Future<bool> setLaptopIp(String ip) => _prefs.setString(_keyIp, ip);

  int get laptopPort => _prefs.getInt(_keyPort) ?? 8765;
  Future<bool> setLaptopPort(int port) => _prefs.setInt(_keyPort, port);

  String get authToken => _prefs.getString(_keyToken) ?? 'devpad-secret-token-change-me';
  Future<bool> setAuthToken(String token) => _prefs.setString(_keyToken, token);

  String get activeProfile => _prefs.getString(_keyProfile) ?? 'cursor';
  Future<bool> setActiveProfile(String profile) => _prefs.setString(_keyProfile, profile);

  String? get pairedDeviceName => _prefs.getString(_keyPairedDevice);
  Future<bool> setPairedDeviceName(String name) => _prefs.setString(_keyPairedDevice, name);

  // Backward compatibility: Prompts List
  static final List<PromptItem> defaultPrompts = [
    const PromptItem(
      id: 'default_1',
      title: 'Pandas to PyArrow/Parquet',
      content: 'Convert this Pandas script to PyArrow/Parquet for optimized vectorized operations and streaming memory efficiency.',
      category: 'Data & Python',
      isCustom: false,
    ),
    const PromptItem(
      id: 'default_2',
      title: 'Add Strict TypeScript Types',
      content: 'Add strict TypeScript types, avoiding any, creating explicit interfaces, union types, and runtime validation guards where appropriate.',
      category: 'Frontend & TS',
      isCustom: false,
    ),
    const PromptItem(
      id: 'default_3',
      title: 'Pytest Edge Cases',
      content: 'Write pytest unit tests covering edge cases, invalid inputs, boundary values, and mock external network/database calls.',
      category: 'Testing',
      isCustom: false,
    ),
    const PromptItem(
      id: 'default_4',
      title: 'Explain & Audit Code',
      content: 'Explain this code step-by-step, evaluate time and space complexity, and identify potential bugs, concurrency race conditions, or security issues.',
      category: 'Review',
      isCustom: false,
    ),
    const PromptItem(
      id: 'default_5',
      title: 'Refactor for Performance',
      content: 'Refactor this function for readability and performance while keeping existing behavior and contracts intact.',
      category: 'Refactoring',
      isCustom: false,
    ),
  ];

  List<PromptItem> getCustomPrompts() {
    final list = _prefs.getStringList(_keyCustomPrompts);
    if (list == null) return [];
    return list.map((s) => PromptItem.fromJson(s)).toList();
  }

  Future<bool> saveCustomPrompts(List<PromptItem> prompts) {
    final list = prompts.map((p) => p.toJson()).toList();
    return _prefs.setStringList(_keyCustomPrompts, list);
  }

  // ===================== STREAM DECK PROFILES =====================

  static List<DeckProfile> get defaultDeckProfiles => [
    DeckProfile(
      id: 'cursor',
      name: 'Cursor',
      iconName: 'smart_toy',
      accentColor: 0xFF36E1BD,
      pages: [
        [
          const MacroButton(id: 'c1', label: 'AI Chat', iconName: 'smart_toy', colorValue: 0xFF36E1BD, actionType: ActionType.keyboardShortcut, payload: 'ctrl+l'),
          const MacroButton(id: 'c2', label: 'Edit Inline', iconName: 'edit', colorValue: 0xFF60A5FA, actionType: ActionType.keyboardShortcut, payload: 'ctrl+k'),
          const MacroButton(id: 'c3', label: '@Codebase', iconName: 'folder', colorValue: 0xFFA78BFA, actionType: ActionType.textMacro, payload: '@Codebase '),
          const MacroButton(id: 'c4', label: 'Accept Diff', iconName: 'save', colorValue: 0xFF34D399, actionType: ActionType.keyboardShortcut, payload: 'ctrl+enter'),
          const MacroButton(id: 'c5', label: 'Format Code', iconName: 'format_paint', colorValue: 0xFFFBBF24, actionType: ActionType.keyboardShortcut, payload: 'shift+alt+f'),
          const MacroButton(id: 'c6', label: 'Explain Bugs', iconName: 'bug_report', colorValue: 0xFFF87171, actionType: ActionType.textMacro, payload: 'Explain this code and identify potential bugs or performance bottlenecks.'),
          const MacroButton(id: 'c7', label: 'Refactor', iconName: 'auto_fix_high', colorValue: 0xFF38BDF8, actionType: ActionType.textMacro, payload: 'Refactor this function for readability and maintainability.'),
          const MacroButton(id: 'c8', label: 'Next Page', iconName: 'apps', colorValue: 0xFF94A3B8, actionType: ActionType.folderNavigation, payload: 'page_1'),
        ],
        [
          const MacroButton(id: 'c9', label: '@Web', iconName: 'language', colorValue: 0xFF38BDF8, actionType: ActionType.textMacro, payload: '@Web '),
          const MacroButton(id: 'c10', label: '@Docs', iconName: 'code', colorValue: 0xFF818CF8, actionType: ActionType.textMacro, payload: '@Docs '),
          const MacroButton(id: 'c11', label: '@Git', iconName: 'commit', colorValue: 0xFFFB923C, actionType: ActionType.textMacro, payload: '@Git '),
          const MacroButton(id: 'c12', label: 'Toggle Term', iconName: 'terminal', colorValue: 0xFFF472B6, actionType: ActionType.keyboardShortcut, payload: 'ctrl+`'),
        ]
      ],
    ),
    DeckProfile(
      id: 'vscode',
      name: 'VS Code',
      iconName: 'code',
      accentColor: 0xFF38BDF8,
      pages: [
        [
          const MacroButton(id: 'v1', label: 'Quick Open', iconName: 'search', colorValue: 0xFF38BDF8, actionType: ActionType.keyboardShortcut, payload: 'ctrl+p'),
          const MacroButton(id: 'v2', label: 'Command Pal', iconName: 'terminal', colorValue: 0xFF818CF8, actionType: ActionType.keyboardShortcut, payload: 'ctrl+shift+p'),
          const MacroButton(id: 'v3', label: 'Split Editor', iconName: 'call_split', colorValue: 0xFF34D399, actionType: ActionType.keyboardShortcut, payload: 'ctrl+\\'),
          const MacroButton(id: 'v4', label: 'Toggle Sidebar', iconName: 'apps', colorValue: 0xFF94A3B8, actionType: ActionType.keyboardShortcut, payload: 'ctrl+b'),
          const MacroButton(id: 'v5', label: 'Find In Files', iconName: 'search', colorValue: 0xFFFBBF24, actionType: ActionType.keyboardShortcut, payload: 'ctrl+shift+f'),
          const MacroButton(id: 'v6', label: 'Format Document', iconName: 'format_paint', colorValue: 0xFFF472B6, actionType: ActionType.keyboardShortcut, payload: 'shift+alt+f'),
          const MacroButton(id: 'v7', label: 'Debug Start', iconName: 'play_arrow', colorValue: 0xFF34D399, actionType: ActionType.keyboardShortcut, payload: 'f5'),
          const MacroButton(id: 'v8', label: 'Stop Debug', iconName: 'stop', colorValue: 0xFFF87171, actionType: ActionType.keyboardShortcut, payload: 'shift+f5'),
        ]
      ],
    ),
    DeckProfile(
      id: 'git',
      name: 'Git',
      iconName: 'commit',
      accentColor: 0xFFF97316,
      pages: [
        [
          const MacroButton(id: 'g1', label: 'git status', iconName: 'terminal', colorValue: 0xFFF97316, actionType: ActionType.textMacro, payload: 'git status\n'),
          const MacroButton(id: 'g2', label: 'git diff', iconName: 'call_split', colorValue: 0xFFFBBF24, actionType: ActionType.textMacro, payload: 'git diff\n'),
          const MacroButton(id: 'g3', label: 'git commit -m', iconName: 'commit', colorValue: 0xFF34D399, actionType: ActionType.textMacro, payload: 'git commit -m "'),
          const MacroButton(id: 'g4', label: 'git pull', iconName: 'cloud_download', colorValue: 0xFF38BDF8, actionType: ActionType.textMacro, payload: 'git pull\n'),
          const MacroButton(id: 'g5', label: 'git push', iconName: 'cloud_upload', colorValue: 0xFFA78BFA, actionType: ActionType.textMacro, payload: 'git push\n'),
          const MacroButton(id: 'g6', label: 'git log -5', iconName: 'table_chart', colorValue: 0xFF94A3B8, actionType: ActionType.textMacro, payload: 'git log --oneline -5\n'),
          const MacroButton(id: 'g7', label: 'git checkout -b', iconName: 'call_split', colorValue: 0xFFF472B6, actionType: ActionType.textMacro, payload: 'git checkout -b '),
          const MacroButton(id: 'g8', label: 'git stash', iconName: 'folder', colorValue: 0xFFE2E8F0, actionType: ActionType.textMacro, payload: 'git stash\n'),
        ]
      ],
    ),
    DeckProfile(
      id: 'chrome',
      name: 'Chrome',
      iconName: 'language',
      accentColor: 0xFFFBBF24,
      pages: [
        [
          const MacroButton(id: 'ch1', label: 'DevTools', iconName: 'bug_report', colorValue: 0xFFFBBF24, actionType: ActionType.keyboardShortcut, payload: 'f12'),
          const MacroButton(id: 'ch2', label: 'Hard Reload', iconName: 'refresh', colorValue: 0xFF38BDF8, actionType: ActionType.keyboardShortcut, payload: 'ctrl+shift+r'),
          const MacroButton(id: 'ch3', label: 'New Tab', iconName: 'open_in_browser', colorValue: 0xFF34D399, actionType: ActionType.keyboardShortcut, payload: 'ctrl+t'),
          const MacroButton(id: 'ch4', label: 'Close Tab', iconName: 'stop', colorValue: 0xFFF87171, actionType: ActionType.keyboardShortcut, payload: 'ctrl+w'),
          const MacroButton(id: 'ch5', label: 'Reopen Tab', iconName: 'refresh', colorValue: 0xFFA78BFA, actionType: ActionType.keyboardShortcut, payload: 'ctrl+shift+t'),
          const MacroButton(id: 'ch6', label: 'Inspect Element', iconName: 'search', colorValue: 0xFFF472B6, actionType: ActionType.keyboardShortcut, payload: 'ctrl+shift+c'),
          const MacroButton(id: 'ch7', label: 'Console Tab', iconName: 'terminal', colorValue: 0xFFE2E8F0, actionType: ActionType.keyboardShortcut, payload: 'ctrl+shift+j'),
          const MacroButton(id: 'ch8', label: 'Bookmark Page', iconName: 'save', colorValue: 0xFFFBBF24, actionType: ActionType.keyboardShortcut, payload: 'ctrl+d'),
        ]
      ],
    ),
    DeckProfile(
      id: 'powerbi',
      name: 'Power BI',
      iconName: 'bar_chart',
      accentColor: 0xFFFACC15,
      pages: [
        [
          const MacroButton(id: 'pb1', label: 'DAX Formatter', iconName: 'format_paint', colorValue: 0xFFFACC15, actionType: ActionType.textMacro, payload: '// Formatted DAX Measure\n'),
          const MacroButton(id: 'pb2', label: 'Refresh Data', iconName: 'refresh', colorValue: 0xFF34D399, actionType: ActionType.keyboardShortcut, payload: 'ctrl+r'),
          const MacroButton(id: 'pb3', label: 'Data View', iconName: 'table_chart', colorValue: 0xFF38BDF8, actionType: ActionType.desktopAction, payload: 'view_data'),
          const MacroButton(id: 'pb4', label: 'Model View', iconName: 'call_split', colorValue: 0xFFA78BFA, actionType: ActionType.desktopAction, payload: 'view_model'),
          const MacroButton(id: 'pb5', label: 'New Measure', iconName: 'bolt', colorValue: 0xFFF472B6, actionType: ActionType.textMacro, payload: 'NewMeasure = \nCALCULATE(\n    \n)\n'),
          const MacroButton(id: 'pb6', label: 'Transform Data', iconName: 'auto_fix_high', colorValue: 0xFFFB923C, actionType: ActionType.desktopAction, payload: 'open_power_query'),
        ]
      ],
    ),
    DeckProfile(
      id: 'terminal',
      name: 'Terminal',
      iconName: 'terminal',
      accentColor: 0xFF4ADE80,
      pages: [
        [
          const MacroButton(id: 't1', label: 'Clear (cls)', iconName: 'refresh', colorValue: 0xFF4ADE80, actionType: ActionType.textMacro, payload: 'cls\n'),
          const MacroButton(id: 't2', label: 'npm run dev', iconName: 'play_arrow', colorValue: 0xFF38BDF8, actionType: ActionType.textMacro, payload: 'npm run dev\n'),
          const MacroButton(id: 't3', label: 'pytest -v', iconName: 'bug_report', colorValue: 0xFFFBBF24, actionType: ActionType.textMacro, payload: 'pytest -v\n'),
          const MacroButton(id: 't4', label: 'docker ps', iconName: 'table_chart', colorValue: 0xFF60A5FA, actionType: ActionType.textMacro, payload: 'docker ps\n'),
          const MacroButton(id: 't5', label: 'Ctrl+C (Kill)', iconName: 'stop', colorValue: 0xFFF87171, actionType: ActionType.keyboardShortcut, payload: 'ctrl+c'),
          const MacroButton(id: 't6', label: 'Exit', iconName: 'stop', colorValue: 0xFF94A3B8, actionType: ActionType.textMacro, payload: 'exit\n'),
        ]
      ],
    ),
    DeckProfile(
      id: 'teams',
      name: 'Teams',
      iconName: 'groups',
      accentColor: 0xFF818CF8,
      pages: [
        [
          const MacroButton(id: 'tm1', label: 'Mute Mic', iconName: 'mic_off', colorValue: 0xFFF87171, actionType: ActionType.keyboardShortcut, payload: 'ctrl+shift+m'),
          const MacroButton(id: 'tm2', label: 'Camera Toggle', iconName: 'videocam_off', colorValue: 0xFFFB923C, actionType: ActionType.keyboardShortcut, payload: 'ctrl+shift+o'),
          const MacroButton(id: 'tm3', label: 'Share Screen', iconName: 'screen_share', colorValue: 0xFF34D399, actionType: ActionType.keyboardShortcut, payload: 'ctrl+shift+e'),
          const MacroButton(id: 'tm4', label: 'Raise Hand', iconName: 'bolt', colorValue: 0xFFFBBF24, actionType: ActionType.keyboardShortcut, payload: 'ctrl+shift+k'),
        ]
      ],
    ),
    DeckProfile(
      id: 'custom',
      name: 'Custom',
      iconName: 'apps',
      accentColor: 0xFFE2E8F0,
      pages: [
        [
          const MacroButton(id: 'cust1', label: 'Open DevPad', iconName: 'open_in_browser', colorValue: 0xFF36E1BD, actionType: ActionType.openApp, payload: 'devpad'),
          const MacroButton(id: 'cust2', label: 'Paste Clipboard', iconName: 'content_paste', colorValue: 0xFF60A5FA, actionType: ActionType.keyboardShortcut, payload: 'ctrl+v'),
        ]
      ],
    ),
  ];

  List<DeckProfile> getDeckProfiles() {
    final list = _prefs.getStringList(_keyDeckProfiles);
    if (list == null || list.isEmpty) {
      return defaultDeckProfiles;
    }
    try {
      return list.map((s) => DeckProfile.fromJson(s)).toList();
    } catch (_) {
      return defaultDeckProfiles;
    }
  }

  Future<bool> saveDeckProfiles(List<DeckProfile> profiles) {
    final list = profiles.map((p) => p.toJson()).toList();
    return _prefs.setStringList(_keyDeckProfiles, list);
  }
}
