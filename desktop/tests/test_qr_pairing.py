import pytest
import time
from qr_pairing import QRPairingManager

def test_qr_payload_generation():
    mgr = QRPairingManager("192.168.1.15", 8765, device_name="TestLaptop", ttl_seconds=60)
    payload = mgr.generate_payload()

    assert payload["type"] == "devpad_pairing"
    assert payload["version"] == 1
    assert payload["host"] == "192.168.1.15"
    assert payload["port"] == 8765
    assert payload["device_name"] == "TestLaptop"
    assert len(payload["pairing_id"]) > 0
    assert len(payload["token"]) > 0
    assert payload["expires_at"] > time.time()

def test_qr_validation_success():
    mgr = QRPairingManager("192.168.1.15", 8765)
    payload = mgr.generate_payload()
    valid = mgr.validate_pairing(payload["pairing_id"], payload["token"])
    assert valid is True

def test_qr_validation_invalid_token():
    mgr = QRPairingManager("192.168.1.15", 8765)
    payload = mgr.generate_payload()
    valid = mgr.validate_pairing(payload["pairing_id"], "wrong-token")
    assert valid is False

def test_qr_validation_expired():
    mgr = QRPairingManager("192.168.1.15", 8765, ttl_seconds=-5)
    payload = mgr.generate_payload()
    valid = mgr.validate_pairing(payload["pairing_id"], payload["token"])
    assert valid is False
