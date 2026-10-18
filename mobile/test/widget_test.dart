import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devpad_mobile/models/deck_profile.dart';
import 'package:devpad_mobile/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DevPad Stream Deck Models & Storage Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initializes with default Stream Deck profiles', () async {
      final storage = await StorageService.init();
      final profiles = storage.getDeckProfiles();

      expect(profiles, isNotEmpty);
      expect(profiles.any((p) => p.id == 'cursor'), isTrue);
      expect(profiles.any((p) => p.id == 'vscode'), isTrue);
      expect(profiles.any((p) => p.id == 'git'), isTrue);
      expect(profiles.any((p) => p.id == 'chrome'), isTrue);
      expect(profiles.any((p) => p.id == 'terminal'), isTrue);
      expect(profiles.any((p) => p.id == 'teams'), isTrue);
    });

    test('Persists customized profiles with custom buttons and pages', () async {
      final storage = await StorageService.init();
      final testProfile = DeckProfile(
        id: 'test_deck',
        name: 'Test Stream Deck',
        iconName: 'bolt',
        accentColor: 0xFF36E1BD,
        pages: [
          [
            const MacroButton(
              id: 'm1',
              label: 'Quick Commit',
              iconName: 'commit',
              colorValue: 0xFFF97316,
              actionType: ActionType.textMacro,
              payload: 'git commit -m "update"',
            ),
            const MacroButton(
              id: 'm2',
              label: 'Build APK',
              iconName: 'play_arrow',
              colorValue: 0xFF38BDF8,
              actionType: ActionType.desktopAction,
              payload: 'flutter_build',
            ),
          ]
        ],
      );

      await storage.saveDeckProfiles([testProfile]);
      final loaded = storage.getDeckProfiles();

      expect(loaded.length, 1);
      expect(loaded.first.id, 'test_deck');
      expect(loaded.first.pages.first.length, 2);
      expect(loaded.first.pages.first.first.label, 'Quick Commit');
      expect(loaded.first.pages.first.first.actionType, ActionType.textMacro);
    });

    test('MacroButton serialization and deserialization round-trip', () {
      const button = MacroButton(
        id: 'btn_123',
        label: 'Format Code',
        iconName: 'format_paint',
        colorValue: 0xFFFBBF24,
        actionType: ActionType.keyboardShortcut,
        payload: 'shift+alt+f',
      );

      final jsonStr = button.toJson();
      final parsed = MacroButton.fromJson(jsonStr);

      expect(parsed.id, button.id);
      expect(parsed.label, button.label);
      expect(parsed.iconName, button.iconName);
      expect(parsed.colorValue, button.colorValue);
      expect(parsed.actionType, ActionType.keyboardShortcut);
      expect(parsed.payload, 'shift+alt+f');
    });

    test('Preserves backward compatibility with Prompt Items and Connection settings', () async {
      final storage = await StorageService.init();
      await storage.setLaptopIp('192.168.1.50');
      await storage.setLaptopPort(8765);
      await storage.setPairedDeviceName('My-Laptop');

      expect(storage.laptopIp, '192.168.1.50');
      expect(storage.laptopPort, 8765);
      expect(storage.pairedDeviceName, 'My-Laptop');
      expect(StorageService.defaultPrompts.length, 5);
    });
  });
}
