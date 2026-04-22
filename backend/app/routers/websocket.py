from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, status
from app.core.security import decode_token
from app.core.websocket_manager import manager
from app.utils.logger import logger

router = APIRouter(tags=["WebSocket"])


@router.websocket("/v1/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: str = Query(...),
):
    payload = decode_token(token)
    if not payload:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    business_id: int | None = payload.get("business_id")
    if not business_id:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    await manager.connect(websocket, business_id)
    try:
        while True:
            # Keep connection alive; server only sends, client messages are ignored
            await websocket.receive_text()
    except WebSocketDisconnect:
        pass
    except Exception as e:
        logger.warning(f"WS error for business_id={business_id}: {e}")
    finally:
        await manager.disconnect(websocket, business_id)
