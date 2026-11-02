"""Khung binary WSS: [1 byte kind][4 byte request_id big-endian][payload]. Xem docs/protocol.md."""

import struct
from enum import IntEnum

_HEADER = struct.Struct(">BI")
MAX_FRAME_BYTES = 5 * 1024 * 1024


class Kind(IntEnum):
    AUDIO = 1  # client -> server: 1 lượt nói hoàn chỉnh (VAD cắt ở mobile)
    IMAGE = 2  # client -> server: 1 frame JPEG
    TTS = 3  # server -> client: audio phản hồi


class ProtocolError(ValueError):
    pass


def decode_frame(data: bytes) -> tuple[Kind, int, bytes]:
    if not _HEADER.size <= len(data) <= MAX_FRAME_BYTES:
        raise ProtocolError("bad frame size")
    kind, request_id = _HEADER.unpack_from(data)
    try:
        return Kind(kind), request_id, data[_HEADER.size :]
    except ValueError:
        raise ProtocolError(f"unknown kind {kind}") from None


def encode_frame(kind: Kind, request_id: int, payload: bytes) -> bytes:
    return _HEADER.pack(kind, request_id) + payload
