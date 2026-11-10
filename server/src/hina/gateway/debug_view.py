"""Trang /debug: xem luồng mobile <-> server theo thời gian thực. Chỉ dùng khi dev.

Không có xác thực và hiển thị ảnh/câu nói của người dùng: HINA_DEBUG=false (mặc định) thì
mọi route trả 404. Không bật trên server public.
"""

from pathlib import Path

from fastapi import APIRouter, HTTPException, Request, Response
from fastapi.responses import HTMLResponse

from hina.debug import DebugLog

router = APIRouter(prefix="/debug", include_in_schema=False)
_PAGE = (Path(__file__).parent / "debug.html").read_text(encoding="utf-8")


def _log(request: Request) -> DebugLog:
    log: DebugLog = request.app.state.container.debug
    if not log.enabled:
        raise HTTPException(404)
    return log


@router.get("")
async def page(request: Request) -> HTMLResponse:
    _log(request)
    return HTMLResponse(_PAGE)


@router.get("/events")
async def events(request: Request, after: int = 0) -> dict:
    log = _log(request)
    return {"events": log.events(after), "sessions": log.sessions()}


@router.get("/frame/{sid}")
async def frame(sid: str, request: Request) -> Response:
    jpeg = _log(request).latest_frame(sid)
    if jpeg is None:
        raise HTTPException(404)
    return Response(jpeg, media_type="image/jpeg", headers={"Cache-Control": "no-store"})
