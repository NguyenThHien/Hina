import secrets
import time
from dataclasses import dataclass, field
from typing import Protocol


@dataclass(frozen=True)
class Session:
    id: str
    created_at: float = field(default_factory=time.time)


class SessionStore(Protocol):
    def create(self) -> Session: ...
    def get(self, session_id: str) -> Session | None: ...
    def delete(self, session_id: str) -> None: ...


class InMemoryStore:
    # ponytail: mất khi restart và không chia sẻ giữa instance; thêm RedisStore khi chạy nhiều instance.
    def __init__(self) -> None:
        self._sessions: dict[str, Session] = {}

    def create(self) -> Session:
        s = Session(id=secrets.token_urlsafe(16))
        self._sessions[s.id] = s
        return s

    def get(self, session_id: str) -> Session | None:
        return self._sessions.get(session_id)

    def delete(self, session_id: str) -> None:
        self._sessions.pop(session_id, None)
