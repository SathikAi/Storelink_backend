import asyncio
import json
from datetime import datetime, timezone
from typing import Dict, Set
from fastapi import WebSocket
from app.utils.logger import logger


class WebSocketManager:
    def __init__(self):
        # business_id -> set of active WebSocket connections
        self._connections: Dict[int, Set[WebSocket]] = {}
        self._lock = asyncio.Lock()

    async def connect(self, websocket: WebSocket, business_id: int) -> None:
        await websocket.accept()
        async with self._lock:
            if business_id not in self._connections:
                self._connections[business_id] = set()
            self._connections[business_id].add(websocket)
        logger.info(
            f"WS connected: business_id={business_id}, "
            f"total={len(self._connections[business_id])}"
        )

    async def disconnect(self, websocket: WebSocket, business_id: int) -> None:
        async with self._lock:
            if business_id in self._connections:
                self._connections[business_id].discard(websocket)
                if not self._connections[business_id]:
                    del self._connections[business_id]
        logger.info(f"WS disconnected: business_id={business_id}")

    async def broadcast(self, business_id: int, event: str, data: dict) -> None:
        payload = json.dumps({
            "event": event,
            "business_id": business_id,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "data": data,
        })
        async with self._lock:
            sockets = set(self._connections.get(business_id, set()))

        dead = []
        for ws in sockets:
            try:
                await ws.send_text(payload)
            except Exception:
                dead.append(ws)

        if dead:
            async with self._lock:
                for ws in dead:
                    self._connections.get(business_id, set()).discard(ws)


# Module-level singleton imported by routers and services
manager = WebSocketManager()
