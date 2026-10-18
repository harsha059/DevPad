import json
import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Any, List

logger = logging.getLogger("DevPad.Config")

DEFAULT_CONFIG_PATH = Path("C:/Projects/config/default_config.json")

@dataclass
class ProfileConfig:
    name: str
    window_patterns: List[str] = field(default_factory=list)
    context_prefix_map: Dict[str, str] = field(default_factory=dict)

@dataclass
class ServerConfig:
    host: str = "0.0.0.0"
    port: int = 8765
    auth_token: str = "devpad-secret-token-change-me"
    max_payload_bytes: int = 65536
    enforce_window_target: bool = True
    profiles: Dict[str, ProfileConfig] = field(default_factory=dict)

    @classmethod
    def load(cls, path: Path = DEFAULT_CONFIG_PATH) -> "ServerConfig":
        if not path.exists():
            logger.warning(f"Config path {path} not found. Creating default.")
            config = cls()
            config.save(path)
            return config

        try:
            with open(path, "r", encoding="utf-8-sig") as f:
                data = json.load(f)
        except json.JSONDecodeError as e:
            logger.error(f"Malformed configuration file at {path}: {e}")
            raise ValueError(f"Failed to parse config file at {path}: {e}") from e

        profiles = {}
        for key, pdata in data.get("profiles", {}).items():
            profiles[key] = ProfileConfig(
                name=pdata.get("name", key),
                window_patterns=pdata.get("window_patterns", []),
                context_prefix_map=pdata.get("context_prefix_map", {})
            )

        return cls(
            host=data.get("host", "0.0.0.0"),
            port=data.get("port", 8765),
            auth_token=data.get("auth_token", "devpad-secret-token-change-me"),
            max_payload_bytes=data.get("max_payload_bytes", 65536),
            enforce_window_target=data.get("enforce_window_target", True),
            profiles=profiles
        )

    def save(self, path: Path = DEFAULT_CONFIG_PATH) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        data = {
            "host": self.host,
            "port": self.port,
            "auth_token": self.auth_token,
            "max_payload_bytes": self.max_payload_bytes,
            "enforce_window_target": self.enforce_window_target,
            "profiles": {
                k: {
                    "name": v.name,
                    "window_patterns": v.window_patterns,
                    "context_prefix_map": v.context_prefix_map
                }
                for k, v in self.profiles.items()
            }
        }
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
