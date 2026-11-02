"""Một GPU dùng chung: hàng đợi ưu tiên, Safety vượt mặt request người dùng."""

import asyncio
import itertools
from collections.abc import Awaitable, Callable

SAFETY, USER = 0, 1  # số nhỏ = ưu tiên cao


class Busy(Exception):
    """Hàng đợi đầy."""


class GpuScheduler:
    # ponytail: 1 queue + 1 worker tuần tự, đủ cho 1 GPU. Queue đầy thì cả Safety cũng bị Busy;
    # nếu nhiều user, dành slot riêng cho Safety.
    def __init__(self, max_queue: int) -> None:
        self._q: asyncio.PriorityQueue = asyncio.PriorityQueue(max_queue)
        self._seq = itertools.count()
        self._task: asyncio.Task | None = None

    def start(self) -> None:
        self._task = asyncio.create_task(self._worker())

    async def stop(self) -> None:
        if self._task:
            self._task.cancel()
            await asyncio.gather(self._task, return_exceptions=True)

    async def run[T](self, priority: int, fn: Callable[[], Awaitable[T]]) -> T:
        fut: asyncio.Future[T] = asyncio.get_running_loop().create_future()
        try:
            self._q.put_nowait((priority, next(self._seq), fn, fut))
        except asyncio.QueueFull:
            raise Busy from None
        return await fut

    async def _worker(self) -> None:
        while True:
            _, _, fn, fut = await self._q.get()
            if fut.cancelled():
                continue
            try:
                result = await fn()
            except Exception as e:
                if not fut.cancelled():
                    fut.set_exception(e)
            else:
                if not fut.cancelled():
                    fut.set_result(result)
