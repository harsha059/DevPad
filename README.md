# DevPad — Developer Command Center (Sprint 1)

DevPad turns an Android phone into a customizable, dark Material 3 command center with emerald accents for controlling your Windows development workstation, specifically tailored for LLM coding workflows in Cursor, Windows Terminal, and Chrome.

---

## Architecture Overview

- **Flutter Mobile App (`C:\Projects\mobile`)**:
  - Material 3 Dark theme with Emerald accent (`#10B981`) and high-contrast surfaces.
  - Configurable Windows host IP, port, profile selector, and private pairing token.
  - Searchable prompt library with categories and custom prompt creation/editing/deletion.
  - Quick-injection context tags: `@Codebase`, `@Web`, `@Docs`, `@Git`, `@Terminal`.
  - Local state persistence using `SharedPreferences`.
  - Visual status badge and confirmation modals for active window mismatches.

- **Python Desktop Companion (`C:\Projects\desktop`)**:
  - Asynchronous WebSocket server (`websockets`) on `ws://0.0.0.0:8765`.
  - Strict authentication handshake with private token verification (`secrets.compare_digest`).
  - Action registry with allowlist enforcement (`ping`, `insert_text`, `get_window_info`, `get_profiles`).
  - Safe Windows text paste via `CF_UNICODETEXT` clipboard buffer and synthesized `Ctrl+V` key events.
  - Active foreground window detection (`pywin32`) preventing accidental text injection into untargeted windows.
  - Privacy-preserving logging (excludes prompt contents and auth tokens).
  - Graceful shutdown handling.

- **Shared Configuration (`C:\Projects\config\default_config.json`)**:
  - Port, host, payload limits, profiles (Cursor, Terminal, Chrome), and window match rules.

---

## Desktop Companion Setup

### 1. Requirements
Ensure Python 3.11+ is installed. Dependencies are listed in `desktop/requirements.txt`:
```bash
pip install -r C:\Projects\desktop\requirements.txt
```

### 2. Start Companion Server
```powershell
python C:\Projects\desktop\server.py
```
*(Your current LAN IP on Wi-Fi is detected as `192.168.1.15`)*

### 3. Run Companion Tests
```powershell
cd C:\Projects\desktop
pytest -v
```

---

## Mobile App Setup & Running on Physical Android Device

### Prerequisites:
1. Enable **Developer Options** and **USB Debugging** on your Android phone.
2. Connect your phone via USB cable to this Windows laptop.
3. Verify ADB detects your phone:
   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
   ```
   *(If prompted on your phone, tap "Allow USB debugging" / "Always allow from this computer")*

### Run on Device:
```powershell
cd C:\Projects\mobile
flutter run
```

### Pairing phone with Windows laptop:
1. Ensure both your phone and Windows laptop are on the same Wi-Fi network.
2. In the DevPad mobile app, tap the **Settings** (gear) icon in the top right.
3. Configure:
   - **Laptop IP**: `192.168.1.15` (or whatever LAN IP is assigned to your PC)
   - **Companion Port**: `8765`
   - **Pairing Token**: `devpad-secret-token-change-me`
   - **Active Profile**: `Cursor`
4. Tap **Save & Apply**, then tap **Offline / Connected** pill badge to establish connection.

---

## Security Model & Transport Limitations

- **Current Prototype (Sprint 1)**:
  - Restricted to local network communication (`192.168.1.x`).
  - Uses private shared secret pairing token to authenticate WebSocket connections.
  - Enforces payload size limits (64 KB) to reject buffer exhaustion attacks.
  - Uses strict action registry; **no arbitrary shell commands or code execution**.
  - Logs omit tokens and prompt text to prevent credential/data leakage.
  - Injects text only through standard clipboard paste without automated submission (no Enter key sent).

- **Production Recommendations**:
  - **mTLS / TLS (WSS)**: Wrap WebSocket connections in TLS (self-signed certificates or local CA) to prevent LAN eavesdropping/sniffing.
  - **Dynamic Pairing via QR Code / ECDH**: Generate single-use pairing codes or ephemeral cryptographic key exchange via QR code scanning.
  - **Device Pinning**: Bind the paired Android device hardware identifier / certificate after the first handshake.
