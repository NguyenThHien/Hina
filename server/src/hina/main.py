from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI

from hina.ai.registry import build_services
from hina.ai.scheduler import GpuScheduler
from hina.config import Settings
from hina.container import Container
from hina.debug import DebugLog
from hina.gateway import api, debug_view, ws
from hina.orchestrator.router import Orchestrator
from hina.session.store import InMemoryStore

# Trần cho từng request HTTP ra ngoài; thời gian tổng cho TTS do Orchestrator giới hạn.
HTTP_TIMEOUT_S = 30.0


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = Settings()  # thiếu HINA_JWT_SECRET thì dừng ngay tại đây
    async with httpx.AsyncClient(timeout=HTTP_TIMEOUT_S) as http:
        ai = build_services(settings, http)  # bật fpt mà thiếu key thì dừng tại đây
        scheduler = GpuScheduler(settings.gpu_queue_size)
        orchestrator = Orchestrator(
            ai, scheduler, tts_timeout_s=settings.tts_timeout_s, vlm_timeout_s=settings.vlm_timeout_s
        )
        debug = DebugLog(settings.debug)
        app.state.container = Container(settings, InMemoryStore(), ai, scheduler, orchestrator, debug)
        scheduler.start()
        try:
            yield
        finally:
            await scheduler.stop()


def create_app() -> FastAPI:
    app = FastAPI(title="Hina", lifespan=lifespan)
    app.include_router(api.router)
    app.include_router(ws.router)
    app.include_router(debug_view.router)  # 404 nếu HINA_DEBUG không bật
    return app


app = create_app()
