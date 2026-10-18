import 'dart:convert';

enum ActionType {
  keyboardShortcut,
  textMacro,
  desktopAction,
  openApp,
  folderNavigation,
}

class MacroButton {
  final String id;
  final String label;
  final String iconName;
  final int colorValue;
  final ActionType actionType;
  final String payload; // e.g., "ctrl+s", "git status", "cursor.exe", or folder id

  const MacroButton({
    required this.id,
    required this.label,
    required this.iconName,
    required this.colorValue,
    required this.actionType,
    required this.payload,
  });

  MacroButton copyWith({
    String? id,
    String? label,
    String? iconName,
    int? colorValue,
    ActionType? actionType,
    String? payload,
  }) {
    return MacroButton(
      id: id ?? this.id,
      label: label ?? this.label,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      actionType: actionType ?? this.actionType,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'iconName': iconName,
      'colorValue': colorValue,
      'actionType': actionType.index,
      'payload': payload,
    };
  }

  factory MacroButton.fromMap(Map<String, dynamic> map) {
    return MacroButton(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? 'Button',
      iconName: map['iconName'] as String? ?? 'bolt',
      colorValue: map['colorValue'] as int? ?? 0xFF36E1BD,
      actionType: ActionType.values[
          (map['actionType'] as int? ?? 0).clamp(0, ActionType.values.length - 1)],
      payload: map['payload'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory MacroButton.fromJson(String source) =>
      MacroButton.fromMap(json.decode(source) as Map<String, dynamic>);
}

class DeckProfile {
  final String id;
  final String name;
  final String iconName;
  final int accentColor;
  final List<List<MacroButton>> pages; // Multiple pages of buttons

  const DeckProfile({
    required this.id,
    required this.name,
    required this.iconName,
    required this.accentColor,
    required this.pages,
  });

  DeckProfile copyWith({
    String? id,
    String? name,
    String? iconName,
    int? accentColor,
    List<List<MacroButton>>? pages,
  }) {
    return DeckProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      accentColor: accentColor ?? this.accentColor,
      pages: pages ?? this.pages,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'accentColor': accentColor,
      'pages': pages.map((page) => page.map((b) => b.toMap()).toList()).toList(),
    };
  }

  factory DeckProfile.fromMap(Map<String, dynamic> map) {
    final rawPages = map['pages'] as List<dynamic>? ?? [];
    final parsedPages = rawPages.map((page) {
      final list = page as List<dynamic>? ?? [];
      return list
          .map((b) => MacroButton.fromMap(b as Map<String, dynamic>))
          .toList();
    }).toList();

    return DeckProfile(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Profile',
      iconName: map['iconName'] as String? ?? 'apps',
      accentColor: map['accentColor'] as int? ?? 0xFF36E1BD,
      pages: parsedPages.isEmpty ? [[]] : parsedPages,
    );
  }

  String toJson() => json.encode(toMap());

  factory DeckProfile.fromJson(String source) =>
      DeckProfile.fromMap(json.decode(source) as Map<String, dynamic>);
}
