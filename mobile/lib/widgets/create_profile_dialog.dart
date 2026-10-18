import 'package:flutter/material.dart';
import '../models/deck_profile.dart';

class CreateProfileDialog extends StatefulWidget {
  final ValueChanged<DeckProfile> onSave;

  const CreateProfileDialog({super.key, required this.onSave});

  @override
  State<CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends State<CreateProfileDialog> {
  final TextEditingController _nameController = TextEditingController();
  final String _selectedIcon = 'apps';
  int _selectedColor = 0xFF36E1BD;

  static const List<int> _palette = [
    0xFF36E1BD,
    0xFF38BDF8,
    0xFF818CF8,
    0xFFA78BFA,
    0xFFF472B6,
    0xFFF87171,
    0xFFFB923C,
    0xFFFBBF24,
    0xFF34D399,
    0xFF94A3B8,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final id = 'prof_${name.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
    final profile = DeckProfile(
      id: id,
      name: name,
      iconName: _selectedIcon,
      accentColor: _selectedColor,
      pages: [
        [
          MacroButton(
            id: '${id}_1',
            label: 'Action 1',
            iconName: _selectedIcon,
            colorValue: _selectedColor,
            actionType: ActionType.textMacro,
            payload: 'Sample text',
          )
        ]
      ],
    );

    widget.onSave(profile);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF19212D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Create New Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Profile Name',
                hintText: 'e.g. Figma, Obsidian, Blender',
                filled: true,
                fillColor: const Color(0xFF0B1017),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Accent Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
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
                      border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2.5),
                    ),
                  ),
                );
              }).toList(),
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
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF36E1BD),
            foregroundColor: const Color(0xFF0B1017),
          ),
          child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
