enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  authenticated,
  error,
}

class ActionResponse {
  final String? id;
  final String status;
  final String? message;
  final String? error;
  final String? warningCode;
  final String? activeWindow;
  final String? activeProcess;

  const ActionResponse({
    this.id,
    required this.status,
    this.message,
    this.error,
    this.warningCode,
    this.activeWindow,
    this.activeProcess,
  });

  bool get isOk => status == 'ok';
  bool get isWarning => status == 'warning';
  bool get isError => status == 'error';

  factory ActionResponse.fromMap(Map<String, dynamic> map) {
    return ActionResponse(
      id: map['id']?.toString(),
      status: map['status'] as String? ?? 'unknown',
      message: map['message'] as String?,
      error: map['error'] as String?,
      warningCode: map['warning_code'] as String?,
      activeWindow: map['active_window'] as String?,
      activeProcess: map['active_process'] as String?,
    );
  }
}
