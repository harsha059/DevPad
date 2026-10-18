import 'package:flutter/material.dart';
import '../models/prompt_item.dart';

class PromptCard extends StatelessWidget {
  final PromptItem prompt;
  final VoidCallback onTap;
  final VoidCallback onSend;
  final VoidCallback? onDelete;

  const PromptCard({
    super.key,
    required this.prompt,
    required this.onTap,
    required this.onSend,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      color: const Color(0xFF131816),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: prompt.isCustom
                          ? Colors.purple.withValues(alpha: 0.15)
                          : theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: prompt.isCustom
                            ? Colors.purpleAccent.withValues(alpha: 0.3)
                            : theme.colorScheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      prompt.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: prompt.isCustom
                            ? Colors.purpleAccent
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (prompt.isCustom && onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onDelete,
                    ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onSend,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: const Color(0xFF041E15),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 14),
                    label: const Text(
                      'Insert',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                prompt.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                prompt.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.65),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
