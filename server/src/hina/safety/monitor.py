import asyncio
import logging
from collections.abc import Awaitable, Callable
from functools import partial

from hina.ai.base import Depth, Detector
from hina.ai.scheduler import SAFETY, GpuScheduler
from hina.safety.risk import HAZARD_LABELS, assess

log = logging.getLogger(__name__)


class SafetyMonitor:
    """Chạy độc lập với luồng hỏi đáp: mỗi kết nối 1 task, luôn xử lý frame mới nhất."""

    def __init__(
        self,
        detector: Detector,
        depth: Depth,
        scheduler: GpuScheduler,
        emit: Callable[[dict], Awaitable[None]],
    ) -> None:
        self._detector = detector
        self._depth = depth
        self._scheduler = scheduler
        self._emit = emit
        self._latest: bytes | None = None
        self._wake = asyncio.Event()

    def submit(self, frame: bytes) -> None:
        self._latest = frame  # ghi đè = bỏ frame cũ chưa kịp xử lý
        self._wake.set()

    async def run(self) -> None:
        while True:
            await self._wake.wait()
            self._wake.clear()
            frame, self._latest = self._latest, None
            if frame is None:
                continue
            try:
                alert = await self._assess(frame)
            except Exception:
                log.exception("safety assess failed")
                continue
            if alert:
                await self._emit(alert)

    async def _assess(self, frame: bytes) -> dict | None:
        run = self._scheduler.run
        dets = await run(SAFETY, partial(self._detector.detect, frame))
        hazards = [d for d in dets if d.label in HAZARD_LABELS]
        dists = await asyncio.gather(
            *(run(SAFETY, partial(self._depth.distance_m, frame, d.box)) for d in hazards)
        )
        return assess(list(zip(hazards, dists, strict=True)))
