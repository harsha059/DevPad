import json
import socket
import time
import secrets
from pathlib import Path
from typing import Dict, Any, Optional

try:
    import qrcode
    QRCODE_AVAILABLE = True
except ImportError:
    QRCODE_AVAILABLE = False

PAIRINGS_FILE = Path("C:/Projects/config/pending_pairings.json")

class QRPairingManager:
    """
    Generates and validates versioned DevPad pairing QR payloads.
    Uses ephemeral one-time pairing credentials rather than exposing
    the permanent auth token.
    Persists pending pairings to disk so different processes
    (generate_qr.py / show_qr.py / server.py) can validate them.
    """
    def __init__(self, host: str, port: int, device_name: Optional[str] = None, ttl_seconds: int = 86400):
        self.host = host
        self.port = port
        self.device_name = device_name or socket.gethostname()
        self.ttl_seconds = ttl_seconds

    def _load_pairings(self) -> Dict[str, Dict[str, Any]]:
        if not PAIRINGS_FILE.exists():
            return {}
        try:
            with open(PAIRINGS_FILE, "r", encoding="utf-8-sig") as f:
                return json.load(f)
        except Exception:
            return {}

    def _save_pairings(self, data: Dict[str, Dict[str, Any]]) -> None:
        try:
            PAIRINGS_FILE.parent.mkdir(parents=True, exist_ok=True)
            with open(PAIRINGS_FILE, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
        except Exception:
            pass

    def get_detectable_lan_ip(self) -> str:
        """Best effort to get current non-loopback LAN IP."""
        if self.host != "0.0.0.0":
            return self.host
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except Exception:
            return "127.0.0.1"

    def generate_payload(self) -> Dict[str, Any]:
        pairing_id = secrets.token_hex(8)
        one_time_token = secrets.token_urlsafe(16)
        expires_at = int(time.time()) + self.ttl_seconds

        pairings = self._load_pairings()
        pairings[pairing_id] = {
            "token": one_time_token,
            "expires_at": expires_at,
            "status": "pending",
        }
        self._save_pairings(pairings)

        ip = self.get_detectable_lan_ip()

        payload = {
            "type": "devpad_pairing",
            "version": 1,
            "host": ip,
            "port": self.port,
            "pairing_id": pairing_id,
            "token": one_time_token,
            "device_name": self.device_name,
            "expires_at": expires_at
        }
        return payload

    def save_qr_image(self, output_path: str = "pairing_qr.png") -> Optional[str]:
        """Saves a high-resolution PNG image of the QR code."""
        if not QRCODE_AVAILABLE:
            return None
        payload = self.generate_payload()
        qr_str = json.dumps(payload)
        img = qrcode.make(qr_str)
        img.save(output_path)
        return output_path

    def generate_qr_ascii(self) -> str:
        """Generates an ASCII text QR code using standard console characters."""
        if not QRCODE_AVAILABLE:
            return "[qrcode library not installed]"
        payload = self.generate_payload()
        qr_str = json.dumps(payload)
        qr = qrcode.QRCode()
        qr.add_data(qr_str)
        qr.make()
        
        output = []
        for row in qr.modules:
            line = "".join("##" if cell else "  " for cell in row)
            output.append(line)
        return "\n".join(output)

    def validate_pairing(self, pairing_id: str, token: str) -> bool:
        """Validates a one-time pairing credential."""
        pairings = self._load_pairings()
        record = pairings.get(pairing_id)
        if not record:
            return False
        if time.time() > record["expires_at"]:
            del pairings[pairing_id]
            self._save_pairings(pairings)
            return False
        if secrets.compare_digest(record["token"], token):
            record["status"] = "paired"
            self._save_pairings(pairings)
            return True
        return False

    def is_valid_any_ephemeral(self, token: str) -> bool:
        """Allows connecting if token matches any active unexpired ephemeral QR token."""
        now = time.time()
        pairings = self._load_pairings()
        changed = False
        valid = False
        for pid, record in list(pairings.items()):
            if now > record["expires_at"]:
                del pairings[pid]
                changed = True
                continue
            if secrets.compare_digest(record["token"], token):
                valid = True
                break
        if changed:
            self._save_pairings(pairings)
        return valid
