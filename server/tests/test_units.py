import asyncio

import pytest

from hina.ai.base import Detection
from hina.ai.scheduler import SAFETY, USER, Busy, GpuScheduler
from hina.gateway.auth import AuthError, issue, verify
from hina.gateway.protocol import Kind, ProtocolError, decode_frame, encode_frame
from hina.safety.risk import assess

SECRET = "x" * 32


def det(label="person", box=(0.4, 0.2, 0.6, 0.8)):
    return Detection(label, box, 0.9)


def test_frame_roundtrip_and_errors():
    assert decode_frame(encode_frame(Kind.IMAGE, 5, b"ab")) == (Kind.IMAGE, 5, b"ab")
    for bad in (b"", b"\x01\x00", b"\x63\x00\x00\x00\x01"):
        with pytest.raises(ProtocolError):
            decode_frame(bad)


def test_jwt_roundtrip_expiry_and_wrong_secret():
    assert verify(issue("s1", SECRET, 60), SECRET) == "s1"
    with pytest.raises(AuthError):
        verify(issue("s1", SECRET, -1), SECRET)
    with pytest.raises(AuthError):
        verify(issue("s1", SECRET, 60), "y" * 32)


def test_risk_picks_nearest_and_skips_far_or_nonhazard():
    near, far = det(box=(0.0, 0, 0.2, 0.5)), det()
    alert = assess([(far, 1.8), (near, 0.8), (det("cat"), 0.3), (det(), 5.0)])
    assert (alert["level"], alert["direction"], alert["distance_m"]) == ("danger", "left", 0.8)
    assert assess([(det(), 3.0), (det("cat"), 0.5)]) is None


def test_risk_unknown_distance_needs_large_box():
    assert assess([(det(box=(0.4, 0.4, 0.5, 0.5)), None)]) is None
    alert = assess([(det(box=(0.2, 0.0, 0.8, 1.0)), None)])
    assert alert["level"] == "warning" and "distance_m" not in alert


def test_scheduler_safety_beats_user_and_queue_is_bounded():
    async def main():
        s = GpuScheduler(max_queue=2)
        s.start()
        order, gate = [], asyncio.Event()

        async def blocker():
            await gate.wait()

        async def job(name):
            order.append(name)

        first = asyncio.create_task(s.run(USER, blocker))
        await asyncio.sleep(0.01)  # worker đã nhận blocker
        user = asyncio.create_task(s.run(USER, lambda: job("user")))
        safety = asyncio.create_task(s.run(SAFETY, lambda: job("safety")))
        await asyncio.sleep(0.01)
        with pytest.raises(Busy):
            await s.run(USER, lambda: job("overflow"))
        gate.set()
        await asyncio.gather(first, user, safety)
        await s.stop()
        return order

    assert asyncio.run(main()) == ["safety", "user"]
