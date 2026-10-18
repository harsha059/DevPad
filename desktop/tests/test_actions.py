import pytest
import json
import asyncio
from pathlib import Path
from config import ServerConfig, ProfileConfig
from actions import ActionHandler
from automation import AutomationController

class MockAutomation(AutomationController):
    def __init__(self, target_title="Cursor - DevPad", target_exe="cursor.exe"):
        self.available = True
        self.title = target_title
        self.exe = target_exe
        self.last_inserted = None

    def get_foreground_window_info(self):
        return (self.title, self.exe)

    def insert_text(self, text: str) -> bool:
        self.last_inserted = text
        return True

@pytest.fixture
def config():
    return ServerConfig(
        auth_token="test-secret-token",
        enforce_window_target=True,
        profiles={
            "cursor": ProfileConfig("Cursor", ["Cursor", "cursor.exe"], {"codebase": "@Codebase"}),
            "terminal": ProfileConfig("Terminal", ["Terminal", "powershell.exe"], {})
        }
    )

def test_config_load_utf8_sig_and_malformed(tmp_path):
    bom_file = tmp_path / "config_bom.json"
    data = {"host": "127.0.0.1", "port": 9999, "auth_token": "secret123"}
    # Write with utf-8-sig encoding (BOM prefix)
    bom_file.write_text(json.dumps(data), encoding="utf-8-sig")

    loaded = ServerConfig.load(bom_file)
    assert loaded.host == "127.0.0.1"
    assert loaded.port == 9999
    assert loaded.auth_token == "secret123"

    # Test malformed JSON handling
    bad_file = tmp_path / "config_bad.json"
    bad_file.write_text("{not_valid_json: true", encoding="utf-8-sig")
    with pytest.raises(ValueError, match="Failed to parse config file"):
        ServerConfig.load(bad_file)

@pytest.mark.asyncio
async def test_ping_action(config):
    handler = ActionHandler(config, MockAutomation())
    res = await handler.execute({"id": "1", "action": "ping"})
    assert res["status"] == "ok"
    assert res["message"] == "pong"
    assert res["id"] == "1"

@pytest.mark.asyncio
async def test_disallowed_action(config):
    handler = ActionHandler(config, MockAutomation())
    res = await handler.execute({"id": "2", "action": "run_command", "cmd": "dir"})
    assert res["status"] == "error"
    assert "Unknown or disallowed action" in res["error"]

@pytest.mark.asyncio
async def test_insert_text_matching_target(config):
    mock_auto = MockAutomation(target_title="Cursor - DevPad", target_exe="cursor.exe")
    handler = ActionHandler(config, mock_auto)
    res = await handler.execute({
        "id": "3",
        "action": "insert_text",
        "profile": "cursor",
        "text": "@Codebase Refactor this function"
    })
    assert res["status"] == "ok"
    assert res["inserted_length"] == len("@Codebase Refactor this function")
    assert mock_auto.last_inserted == "@Codebase Refactor this function"

@pytest.mark.asyncio
async def test_insert_text_mismatch_warning(config):
    mock_auto = MockAutomation(target_title="Notepad", target_exe="notepad.exe")
    handler = ActionHandler(config, mock_auto)
    res = await handler.execute({
        "id": "4",
        "action": "insert_text",
        "profile": "cursor",
        "text": "Hello world"
    })
    assert res["status"] == "warning"
    assert res["warning_code"] == "WINDOW_MISMATCH"
    assert mock_auto.last_inserted is None

@pytest.mark.asyncio
async def test_insert_text_force_override(config):
    mock_auto = MockAutomation(target_title="Notepad", target_exe="notepad.exe")
    handler = ActionHandler(config, mock_auto)
    res = await handler.execute({
        "id": "5",
        "action": "insert_text",
        "profile": "cursor",
        "text": "Forced insert",
        "force": True
    })
    assert res["status"] == "ok"
    assert mock_auto.last_inserted == "Forced insert"
