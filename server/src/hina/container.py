from dataclasses import dataclass

from hina.ai.base import AiServices
from hina.ai.scheduler import GpuScheduler
from hina.config import Settings
from hina.debug import DebugLog
from hina.orchestrator.router import Orchestrator
from hina.session.store import SessionStore


@dataclass(frozen=True)
class Container:
    settings: Settings
    store: SessionStore
    ai: AiServices
    scheduler: GpuScheduler
    orchestrator: Orchestrator
    debug: DebugLog
