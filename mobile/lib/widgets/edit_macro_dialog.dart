import 'package:flutter/material.dart';
import '../models/deck_profile.dart';
import '../models/icon_helper.dart';

class EditMacroDialog extends StatefulWidget {
  final MacroButton? initialButton;
  final ValueChanged<MacroButton> onSave;
  final VoidCallback? onDelete;

  const EditMacroDialog({
    super.key,
    this.initialButton,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<EditMacroDialog> createState() => _EditMacroDialogState();
}

class _EditMacroDialogState extends State<EditMacroDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _payloadController;
  late String _selectedIcon;
  late int _selectedColor;
  late ActionType _selectedActionType;

  static const List<int> _palette = [
    0xFF36E1BD, // DevPad Emerald Accent
    0xFF38BDF8, // Sky Blue
    0xFF818CF8, // Indigo
    0xFFA78BFA, // Violet
    0xFFF472B6, // Pink
    0xFFF87171, // Red
    0xFFFB923C, // Orange
    0xFFFBBF24, // Amber
    0xFF34D399, // Green
    0xFF94A3B8, // Slate
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.initialButton;
    _labelController = TextEditingController(text: b?.label ?? 'New Macro');
    _payloadController = TextEditingController(text: b?.payload ?? '');
    _selectedIcon = b?.iconName ?? 'bolt';
    _selectedColor = b?.colorValue ?? 0xFF36E1BD;
    _selectedActionType = b?.actionType ?? ActionType.keyboardShortcut;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _payloadController.dispose();
    super.dispose();
  }

  void _save() {
    final label = _labelController.text.trim();
    final payload = _payloadController.text.trim();

    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Macro label is required.')),
      );
      return;
    }

    final id = widget.initialButton?.id ??
        'btn_${DateTime.now().millisecondsSinceEpoch}';

    final result = MacroButton(
      id: id,
      label: label,
      iconName: _selectedIcon,
      colorValue: _selectedColor,
      actionType: _selectedActionType,
      payload: payload,
    );

    widget.onSave(result);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF19212D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Color(_selectedColor).withValues(alpha: 0.3)),
      ),
      title: Row(
        children: [
          Icon(IconHelper.getIcon(_selectedIcon), color: Color(_selectedColor)),
          const SizedBox(width: 10),
          Text(
            widget.initialButton == null ? 'Add Macro Button' : 'Edit Macro Button',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Spacer(),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                widget.onDelete!();
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: 'Button Label',
                filled: true,
                fillColor: const Color(0xFF0B1017),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ActionType>(
              initialValue: _selectedActionType,
              dropdownColor: const Color(0xFF19212D),
              decoration: InputDecoration(
                labelText: 'Action Type',
                filled: true,
                fillColor: const Color(0xFF0B1017),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: ActionType.keyboardShortcut, child: Text('Keyboard Shortcut (e.g. ctrl+k)')),
                DropdownMenuItem(value: ActionType.textMacro, child: Text('Text Macro / Prompt')),
                DropdownMenuItem(value: ActionType.desktopAction, child: Text('Approved Desktop Action')),
                DropdownMenuItem(value: ActionType.openApp, child: Text('Open Application')),
                DropdownMenuItem(value: ActionType.folderNavigation, child: Text('Folder / Subpage Navigation')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedActionType = val);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _payloadController,
              maxLines: _selectedActionType == ActionType.textMacro ? 3 : 1,
              decoration: InputDecoration(
                labelText: _getPayloadLabel(),
                hintText: _getPayloadHint(),
                filled: true,
                fillColor: const Color(0xFF0B1017),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Color Accent', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _palette.map((c) {
                final isSelected = _selectedColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Choose Icon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: GridView.count(
                crossAxisCount: 6,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: IconHelper.icons.entries.map((e) {
                  final isSelected = _selectedIcon == e.key;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = e.key),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(_selectedColor).withValues(alpha: 0.25)
                            : const Color(0xFF0B1017),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Color(_selectedColor)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Icon(e.value, size: 20, color: isSelected ? Color(_selectedColor) : Colors.white70),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF36E1BD),
            foregroundColor: const Color(0xFF0B1017),
          ),
          child: const Text('Save Macro', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  String _getPayloadLabel() {
    switch (_selectedActionType) {
      case ActionType.keyboardShortcut:
        return 'Shortcut Keys (e.g. ctrl+shift+f, f5)';
      case ActionType.textMacro:
        return 'Text / Prompt Content';
      case ActionType.desktopAction:
        return 'Action Identifier (e.g. ping, insert_text)';
      case ActionType.openApp:
        return 'Application Name / Executable';
      case ActionType.folderNavigation:
        return 'Page / Subdeck Index (e.g. page_1)';
    }
  }

  String _getPayloadHint() {
    switch (_selectedActionType) {
      case ActionType.keyboardShortcut:
        return 'ctrl+k';
      case ActionType.textMacro:
        return 'Enter prompt or boilerplate code';
      case ActionType.desktopAction:
        return 'insert_text';
      case ActionType.openApp:
        return 'cursor.exe';
      case ActionType.folderNavigation:
        return 'page_1';
    }
  }
}
