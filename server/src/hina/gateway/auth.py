import time

import jwt

ALGORITHM = "HS256"


class AuthError(Exception):
    pass


def issue(session_id: str, secret: str, ttl_s: int) -> str:
    return jwt.encode({"sid": session_id, "exp": int(time.time()) + ttl_s}, secret, ALGORITHM)


def verify(token: str, secret: str) -> str:
    """Trả về session_id; ném AuthError nếu token sai/hết hạn."""
    try:
        claims = jwt.decode(token, secret, algorithms=[ALGORITHM], options={"require": ["exp", "sid"]})
    except jwt.PyJWTError as e:
        raise AuthError(str(e)) from e
    return claims["sid"]


def bearer(header: str | None) -> str:
    scheme, _, token = (header or "").partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise AuthError("missing bearer token")
    return token
