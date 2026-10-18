import logging
from typing import Dict, Any, Callable, Awaitable, Optional
from config import ServerConfig
from automation import AutomationController

logger = logging.getLogger("DevPad.Actions")

class ActionHandler:
    def __init__(self, config: ServerConfig, automation: Optional[AutomationController] = None):
        self.config = config
        self.automation = automation or AutomationController()
        self.registry: Dict[str, Callable[[Dict[str, Any]], Awaitable[Dict[str, Any]]]] = {
            "ping": self._handle_ping,
            "insert_text": self._handle_insert_text,
            "desktop_macro": self._handle_desktop_macro,
            "activate_window": self._handle_activate_window,
            "get_window_info": self._handle_get_window_info,
            "get_profiles": self._handle_get_profiles,
        }

    async def execute(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        req_id = payload.get("id")
        action = payload.get("action")

        if not action or not isinstance(action, str):
            return {
                "id": req_id,
                "status": "error",
                "error": "Missing or invalid 'action' field."
            }

        handler = self.registry.get(action)
        if not handler:
            return {
                "id": req_id,
                "status": "error",
                "error": f"Unknown or disallowed action: {action}"
            }

        try:
            result = await handler(payload)
            result["id"] = req_id
            return result
        except Exception as e:
            logger.error(f"Error handling action '{action}': {e}", exc_info=True)
            return {
                "id": req_id,
                "status": "error",
                "error": f"Internal execution error: {str(e)}"
            }

    async def _handle_ping(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "status": "ok",
            "message": "pong",
            "version": "1.0.0"
        }

    async def _handle_activate_window(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        profile = payload.get("profile", "")
        success = self.automation.activate_app_window(profile)
        return {
            "status": "ok" if success else "error",
            "activated": success,
            "profile": profile
        }

    async def _handle_get_profiles(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        profiles_data = {
            k: {
                "name": v.name,
                "window_patterns": v.window_patterns,
                "context_prefix_map": v.context_prefix_map
            }
            for k, v in self.config.profiles.items()
        }
        return {
            "status": "ok",
            "profiles": profiles_data
        }

    async def _handle_get_window_info(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        title, exe = self.automation.get_foreground_window_info()
        return {
            "status": "ok",
            "window_title": title,
            "process_name": exe
        }

    async def _handle_insert_text(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        text = payload.get("text")
        if text is None or not isinstance(text, str):
            return {
                "status": "error",
                "error": "'text' field must be a valid string."
            }

        profile_key = payload.get("profile", "cursor")
        if profile_key:
            self.automation.activate_app_window(profile_key)

        success = self.automation.insert_text(text)
        if not success:
            return {
                "status": "error",
                "error": "Failed to paste text into target application."
            }

        return {
            "status": "ok",
            "inserted_length": len(text),
        }

    async def _handle_desktop_macro(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        macro_type = payload.get("type", "keyboardShortcut")
        macro_payload = payload.get("payload", "")
        profile_key = payload.get("profile", "")

        # Always focus/activate the target application window first
        if profile_key:
            self.automation.activate_app_window(profile_key)

        if macro_type == "keyboardShortcut":
            success = self.automation.send_shortcut(macro_payload)
            if success:
                logger.info(f"Executed shortcut '{macro_payload}' on profile '{profile_key}'")
                return {"status": "ok", "message": f"Simulated shortcut: {macro_payload}"}
            else:
                return {"status": "error", "error": f"Failed to simulate shortcut: {macro_payload}"}

        elif macro_type == "textMacro":
            success = self.automation.insert_text(macro_payload)
            return {"status": "ok" if success else "error"}

        return {
            "status": "ok",
            "message": f"Received macro {macro_type}: {macro_payload}"
        }
