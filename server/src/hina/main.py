from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from hina.ai.registry import build_services
from hina.ai.scheduler import GpuScheduler
from hina.config import Settings
from hina.container import Container
from hina.gateway import api, ws
from hina.orchestrator.router import Orchestrator
from hina.session.store import InMemoryStore


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = Settings()  # thiếu HINA_JWT_SECRET thì dừng ngay tại đây
    ai = build_services(settings)
    scheduler = GpuScheduler(settings.gpu_queue_size)
    app.state.container = Container(
        settings, InMemoryStore(), ai, scheduler, Orchestrator(ai, scheduler)
    )
    scheduler.start()
    try:
        yield
    finally:
        await scheduler.stop()


def create_app() -> FastAPI:
    app = FastAPI(title="Hina", lifespan=lifespan)
    app.include_router(api.router)
    app.include_router(ws.router)
    return app


app = create_app()
