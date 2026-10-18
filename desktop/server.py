import asyncio
import json
import logging
import signal
import sys
import secrets
from pathlib import Path
from typing import Set

import websockets
from websockets.server import WebSocketServerProtocol

from config import ServerConfig
from actions import ActionHandler
from qr_pairing import QRPairingManager

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] [%(name)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)
logger = logging.getLogger("DevPad.Server")

class DevPadServer:
    def __init__(self, config: ServerConfig, qr_manager: QRPairingManager = None):
        self.config = config
        self.handler = ActionHandler(config)
        self.qr_manager = qr_manager or QRPairingManager(config.host, config.port)
        self.connected_clients: Set[WebSocketServerProtocol] = set()
        self.authenticated_clients: Set[WebSocketServerProtocol] = set()
        self._server = None
        self._shutdown_event = asyncio.Event()

    async def handle_connection(self, websocket: WebSocketServerProtocol):
        client_ip = websocket.remote_address[0]
        logger.info(f"New client connected from {client_ip}")
        self.connected_clients.add(websocket)

        try:
            async for raw_message in websocket:
                if len(raw_message) > self.config.max_payload_bytes:
                    logger.warning(f"Payload rejected: size {len(raw_message)} exceeds limit {self.config.max_payload_bytes}")
                    await websocket.send(json.dumps({
                        "status": "error",
                        "error": "PAYLOAD_TOO_LARGE",
                        "message": f"Message size exceeds limit of {self.config.max_payload_bytes} bytes."
                    }))
                    continue

                try:
                    payload = json.loads(raw_message)
                except Exception as e:
                    await websocket.send(json.dumps({
                        "status": "error",
                        "error": "INVALID_JSON",
                        "message": f"Malformed JSON: {str(e)}"
                    }))
                    continue

                if not isinstance(payload, dict):
                    await websocket.send(json.dumps({
                        "status": "error",
                        "error": "INVALID_PAYLOAD",
                        "message": "Root payload must be a JSON object."
                    }))
                    continue

                req_id = payload.get("id")
                action = payload.get("action")

                # Handle Authentication handshake
                if websocket not in self.authenticated_clients:
                    if action == "auth":
                        token = payload.get("token", "")
                        pairing_id = payload.get("pairing_id")

                        # 1. Check permanent auth token
                        is_valid = secrets.compare_digest(token, self.config.auth_token)
                        
                        # 2. Or validate ephemeral QR pairing token
                        if not is_valid and pairing_id:
                            is_valid = self.qr_manager.validate_pairing(pairing_id, token)
                        elif not is_valid and self.qr_manager.is_valid_any_ephemeral(token):
                            is_valid = True

                        if is_valid:
                            self.authenticated_clients.add(websocket)
                            logger.info(f"Client {client_ip} successfully authenticated.")
                            await websocket.send(json.dumps({
                                "id": req_id,
                                "status": "ok",
                                "message": "AUTHENTICATED"
                            }))
                        else:
                            logger.warning(f"Failed authentication attempt from {client_ip}.")
                            await websocket.send(json.dumps({
                                "id": req_id,
                                "status": "error",
                                "error": "AUTH_FAILED",
                                "message": "Invalid pairing token."
                            }))
                        continue
                    else:
                        await websocket.send(json.dumps({
                            "id": req_id,
                            "status": "error",
                            "error": "UNAUTHENTICATED",
                            "message": "Must send 'auth' action with valid token first."
                        }))
                        continue

                # Process validated action
                response = await self.handler.execute(payload)
                await websocket.send(json.dumps(response))

        except websockets.exceptions.ConnectionClosed:
            logger.info(f"Client {client_ip} disconnected.")
        except Exception as e:
            logger.error(f"Unexpected error in client session {client_ip}: {e}", exc_info=True)
        finally:
            self.connected_clients.discard(websocket)
            self.authenticated_clients.discard(websocket)

    async def start(self):
        logger.info(f"Starting DevPad companion server on ws://{self.config.host}:{self.config.port}")
        logger.info(f"Authentication required. Pairing token configured.")
        logger.info(f"Max payload: {self.config.max_payload_bytes} bytes. Window enforcement: {self.config.enforce_window_target}")

        self._server = await websockets.serve(
            self.handle_connection,
            self.config.host,
            self.config.port,
            max_size=self.config.max_payload_bytes + 4096
        )

        await self._shutdown_event.wait()
        logger.info("Graceful shutdown initiated...")
        self._server.close()
        await self._server.wait_closed()
        logger.info("DevPad server stopped cleanly.")

    def stop(self):
        self._shutdown_event.set()

def main():
    config = ServerConfig.load()
    server = DevPadServer(config)

    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)

    def _sig_handler():
        logger.info("Received termination signal.")
        server.stop()

    if sys.platform != "win32":
        for s in (signal.SIGINT, signal.SIGTERM):
            loop.add_signal_handler(s, _sig_handler)

    try:
        loop.run_until_complete(server.start())
    except KeyboardInterrupt:
        logger.info("KeyboardInterrupt received.")
        server.stop()
        loop.run_until_complete(asyncio.sleep(0.5))
    finally:
        loop.close()

if __name__ == "__main__":
    main()
