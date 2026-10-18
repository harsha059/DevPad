import 'package:flutter/material.dart';
import '../models/prompt_item.dart';

class PromptEditSheet extends StatefulWidget {
  final PromptItem? initialPrompt;
  final ValueChanged<PromptItem> onSave;

  const PromptEditSheet({
    super.key,
    this.initialPrompt,
    required this.onSave,
  });

  @override
  State<PromptEditSheet> createState() => _PromptEditSheetState();
}

class _PromptEditSheetState extends State<PromptEditSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialPrompt?.title ?? '');
    _contentController = TextEditingController(text: widget.initialPrompt?.content ?? '');
    _categoryController = TextEditingController(text: widget.initialPrompt?.category ?? 'Custom');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final category = _categoryController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content are required')),
      );
      return;
    }

    final id = widget.initialPrompt?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final saved = PromptItem(
      id: id,
      title: title,
      content: content,
      category: category.isEmpty ? 'Custom' : category,
      isCustom: true,
    );

    widget.onSave(saved);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  widget.initialPrompt == null ? Icons.add_circle_outline : Icons.edit_note,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.initialPrompt == null ? 'Create Custom Prompt' : 'Edit Prompt',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Prompt Title',
                hintText: 'e.g. Generate Mock Data',
                filled: true,
                fillColor: const Color(0xFF161E1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: 'Category',
                hintText: 'e.g. Python, Testing, Frontend',
                filled: true,
                fillColor: const Color(0xFF161E1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Prompt Text / Template',
                hintText: 'Enter prompt instructions for your AI companion...',
                filled: true,
                fillColor: const Color(0xFF161E1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save to Library', style: TextStyle(fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: const Color(0xFF041E15),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
