import 'package:flutter/material.dart';

class IconHelper {
  static const Map<String, IconData> icons = {
    'bolt': Icons.bolt_rounded,
    'code': Icons.code_rounded,
    'terminal': Icons.terminal_rounded,
    'smart_toy': Icons.smart_toy_rounded,
    'play_arrow': Icons.play_arrow_rounded,
    'stop': Icons.stop_rounded,
    'refresh': Icons.refresh_rounded,
    'bug_report': Icons.bug_report_rounded,
    'folder': Icons.folder_rounded,
    'save': Icons.save_rounded,
    'commit': Icons.commit_rounded,
    'call_split': Icons.call_split_rounded,
    'cloud_upload': Icons.cloud_upload_rounded,
    'cloud_download': Icons.cloud_download_rounded,
    'language': Icons.language_rounded,
    'open_in_browser': Icons.open_in_browser_rounded,
    'bar_chart': Icons.bar_chart_rounded,
    'pie_chart': Icons.pie_chart_rounded,
    'table_chart': Icons.table_chart_rounded,
    'groups': Icons.groups_rounded,
    'mic': Icons.mic_rounded,
    'mic_off': Icons.mic_off_rounded,
    'videocam': Icons.videocam_rounded,
    'videocam_off': Icons.videocam_off_rounded,
    'screen_share': Icons.screen_share_rounded,
    'apps': Icons.apps_rounded,
    'edit': Icons.edit_rounded,
    'content_copy': Icons.content_copy_rounded,
    'content_paste': Icons.content_paste_rounded,
    'search': Icons.search_rounded,
    'format_paint': Icons.format_paint_rounded,
    'auto_fix_high': Icons.auto_fix_high_rounded,
    'keyboard': Icons.keyboard_rounded,
  };

  static IconData getIcon(String name) {
    return icons[name] ?? Icons.widgets_rounded;
  }
}
