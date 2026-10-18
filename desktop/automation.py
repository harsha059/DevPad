import logging
import ctypes
from typing import Optional, Tuple, List

logger = logging.getLogger("DevPad.Automation")

try:
    import win32gui
    import win32process
    import win32con
    import win32clipboard
    import win32api
    import win32service
    PYWIN32_AVAILABLE = True
except ImportError:
    PYWIN32_AVAILABLE = False
    logger.warning("pywin32 not available, automation will run in mock mode.")

VK_MAP = {
    "ctrl": 0x11,
    "control": 0x11,
    "shift": 0x10,
    "alt": 0x12,
    "enter": 0x0D,
    "return": 0x0D,
    "esc": 0x1B,
    "escape": 0x1B,
    "tab": 0x09,
    "backspace": 0x08,
    "space": 0x20,
    "f1": 0x70,
    "f2": 0x71,
    "f3": 0x72,
    "f4": 0x73,
    "f5": 0x74,
    "f6": 0x75,
    "f7": 0x76,
    "f8": 0x77,
    "f9": 0x78,
    "f10": 0x79,
    "f11": 0x7A,
    "f12": 0x7B,
}

APP_CLASS_OR_TITLE_PATTERNS = {
    "chrome": ["Chrome_WidgetWin_1", "Google Chrome", "Chrome"],
    "cursor": ["Cursor", "Cursor.exe"],
    "vscode": ["Code", "Visual Studio Code"],
    "terminal": ["CASCADIA_HOSTING_WINDOW_CLASS", "WindowsTerminal", "PowerShell", "cmd"],
    "teams": ["Teams"],
    "powerbi": ["Power BI", "PBIDesktop"],
}

class AutomationController:
    def __init__(self):
        self.available = PYWIN32_AVAILABLE
        self._desktop_switched = False
        self._ensure_interactive_desktop()

    def _ensure_interactive_desktop(self) -> bool:
        if not self.available or self._desktop_switched:
            return True
        try:
            hdesk = win32service.OpenDesktop("Default", 0, False, win32con.GENERIC_ALL)
            hdesk.SetThreadDesktop()
            self._desktop_switched = True
            return True
        except Exception as e:
            logger.debug(f"Could not attach to Default desktop: {e}")
            return False

    def activate_app_window(self, profile_name: str) -> bool:
        """Brings the target application window to the foreground without throwing Error 170."""
        if not self.available:
            return True

        self._ensure_interactive_desktop()
        patterns = APP_CLASS_OR_TITLE_PATTERNS.get(profile_name.lower(), [profile_name.lower()])
        target_hwnd = None

        # 1. First try FindWindow with known window classes
        for pattern in patterns:
            hwnd = ctypes.windll.user32.FindWindowW(pattern, None)
            if hwnd and ctypes.windll.user32.IsWindowVisible(hwnd):
                target_hwnd = hwnd
                break

        # 2. If not found, safely enumerate top-level windows using EnumDesktopWindows
        if not target_hwnd:
            try:
                def enum_cb(hwnd, _):
                    nonlocal target_hwnd
                    if ctypes.windll.user32.IsWindowVisible(hwnd):
                        length = ctypes.windll.user32.GetWindowTextLengthW(hwnd)
                        if length > 0:
                            buff = ctypes.create_unicode_buffer(length + 1)
                            ctypes.windll.user32.GetWindowTextW(hwnd, buff, length + 1)
                            title = buff.value.lower()
                            for p in patterns:
                                if p.lower() in title:
                                    target_hwnd = hwnd
                                    return False  # Stop enumeration
                    return True

                WNDENUMPROC = ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_void_p, ctypes.c_void_p)
                cb = WNDENUMPROC(enum_cb)
                ctypes.windll.user32.EnumDesktopWindows(None, cb, 0)
            except Exception as e:
                logger.debug(f"Window search notice: {e}")

        if not target_hwnd:
            return False

        try:
            cur_tid = win32api.GetCurrentThreadId()
            fg_hwnd = ctypes.windll.user32.GetForegroundWindow()
            fg_tid, _ = win32process.GetWindowThreadProcessId(fg_hwnd) if fg_hwnd else (0, 0)
            target_tid, _ = win32process.GetWindowThreadProcessId(target_hwnd)

            if fg_tid and cur_tid != fg_tid:
                ctypes.windll.user32.AttachThreadInput(cur_tid, fg_tid, True)
            if target_tid and cur_tid != target_tid:
                ctypes.windll.user32.AttachThreadInput(cur_tid, target_tid, True)

            ctypes.windll.user32.ShowWindow(target_hwnd, win32con.SW_RESTORE)
            ctypes.windll.user32.SetForegroundWindow(target_hwnd)
            ctypes.windll.user32.BringWindowToTop(target_hwnd)

            if fg_tid and cur_tid != fg_tid:
                ctypes.windll.user32.AttachThreadInput(cur_tid, fg_tid, False)
            if target_tid and cur_tid != target_tid:
                ctypes.windll.user32.AttachThreadInput(cur_tid, target_tid, False)

            return True
        except Exception as e:
            logger.error(f"Failed to focus window: {e}")
            return False

    def get_foreground_window_info(self) -> Tuple[str, str]:
        if not self.available:
            return ("MockWindow", "mock.exe")

        hwnd = ctypes.windll.user32.GetForegroundWindow()
        if not hwnd:
            return ("", "")

        length = ctypes.windll.user32.GetWindowTextLengthW(hwnd)
        buff = ctypes.create_unicode_buffer(length + 1)
        ctypes.windll.user32.GetWindowTextW(hwnd, buff, length + 1)
        title = buff.value
        return (title, "")

    def is_target_window(self, patterns: list[str]) -> Tuple[bool, str, str]:
        title, exe = self.get_foreground_window_info()
        return (True, title, exe)

    def insert_text(self, text: str) -> bool:
        if not self.available:
            return True
        try:
            win32clipboard.OpenClipboard()
            win32clipboard.EmptyClipboard()
            win32clipboard.SetClipboardData(win32con.CF_UNICODETEXT, text)
            win32clipboard.CloseClipboard()

            VK_CONTROL = 0x11
            VK_V = 0x56
            KEYEVENTF_KEYUP = 0x0002

            win32api.keybd_event(VK_CONTROL, 0, 0, 0)
            win32api.keybd_event(VK_V, 0, 0, 0)
            win32api.keybd_event(VK_V, 0, KEYEVENTF_KEYUP, 0)
            win32api.keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0)
            return True
        except Exception as e:
            logger.error(f"Failed to insert text: {e}")
            return False

    def send_shortcut(self, shortcut_str: str) -> bool:
        if not self.available:
            return True
        try:
            parts = [p.strip().lower() for p in shortcut_str.split("+") if p.strip()]
            vk_codes: List[int] = []

            for part in parts:
                if part in VK_MAP:
                    vk_codes.append(VK_MAP[part])
                elif len(part) == 1:
                    char = part.upper()
                    vk_codes.append(ord(char))
                elif part.startswith("f") and part[1:].isdigit():
                    num = int(part[1:])
                    vk_codes.append(0x6F + num)

            if not vk_codes:
                return False

            KEYEVENTF_KEYUP = 0x0002
            for vk in vk_codes:
                win32api.keybd_event(vk, 0, 0, 0)
            for vk in reversed(vk_codes):
                win32api.keybd_event(vk, 0, KEYEVENTF_KEYUP, 0)

            return True
        except Exception as e:
            logger.error(f"Failed to simulate shortcut '{shortcut_str}': {e}")
            return False
