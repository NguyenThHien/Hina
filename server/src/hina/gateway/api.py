from fastapi import APIRouter, Header, HTTPException, Request, Response
from pydantic import BaseModel

from hina.gateway.auth import AuthError, bearer, issue, verify

router = APIRouter()


class SessionOut(BaseModel):
    session_id: str
    token: str
    expires_in: int


@router.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


# ponytail: chưa xác thực client và chưa rate-limit; thêm API key + slowapi trước khi mở ra internet.
@router.post("/sessions", status_code=201)
async def create_session(request: Request) -> SessionOut:
    c = request.app.state.container
    session = c.store.create()
    token = issue(session.id, c.settings.jwt_secret, c.settings.jwt_ttl_s)
    return SessionOut(session_id=session.id, token=token, expires_in=c.settings.jwt_ttl_s)


@router.delete("/sessions/{session_id}", status_code=204)
async def delete_session(
    session_id: str, request: Request, authorization: str | None = Header(default=None)
) -> Response:
    c = request.app.state.container
    try:
        sid = verify(bearer(authorization), c.settings.jwt_secret)
    except AuthError:
        raise HTTPException(401, "invalid token") from None
    if sid != session_id:
        raise HTTPException(403, "token does not match session")
    c.store.delete(session_id)
    return Response(status_code=204)
