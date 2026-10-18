import 'package:flutter/material.dart';
import '../models/prompt_item.dart';

class ContextInjectorsBar extends StatelessWidget {
  final ValueChanged<String> onInject;

  const ContextInjectorsBar({
    super.key,
    required this.onInject,
  });

  static const List<ContextTag> tags = [
    ContextTag(
      label: 'Codebase',
      tag: '@Codebase',
      description: 'Reference full project repository context',
    ),
    ContextTag(
      label: 'Web',
      tag: '@Web',
      description: 'Search public web and live docs',
    ),
    ContextTag(
      label: 'Docs',
      tag: '@Docs',
      description: 'Query indexed library documentation',
    ),
    ContextTag(
      label: 'Git',
      tag: '@Git',
      description: 'Include current diffs, branch, and commits',
    ),
    ContextTag(
      label: 'Terminal',
      tag: '@Terminal',
      description: 'Include recent terminal buffer output',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.grain, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'CONTEXT INJECTORS (CURSOR / LLM)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: theme.colorScheme.primary.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: tags.map((t) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  avatar: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                    radius: 12,
                    child: Text(
                      '@',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  label: Text(t.label),
                  tooltip: '${t.tag} - ${t.description}',
                  backgroundColor: const Color(0xFF161E1A),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD1FAE5),
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onPressed: () => onInject(t.tag),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
