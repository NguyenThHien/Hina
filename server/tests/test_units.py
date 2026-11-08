import asyncio
import io

import pytest
from PIL import Image

from hina.aggregator.compose import NO_IMAGE, Result, compose
from hina.ai.base import Detection, Intent
from hina.ai.nlu.stub import StubNLU
from hina.ai.scheduler import SAFETY, USER, Busy, GpuScheduler
from hina.gateway.auth import AuthError, issue, verify
from hina.gateway.protocol import Kind, ProtocolError, decode_frame, encode_frame
from hina.preprocess.image import CropError, crop
from hina.safety.risk import assess

SECRET = "x" * 32


def png(w=100, h=200):
    buf = io.BytesIO()
    Image.new("RGB", (w, h), (10, 20, 30)).save(buf, format="PNG")
    return buf.getvalue()


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


def test_intent_is_numeric_1_to_5():
    assert [i.value for i in Intent] == [1, 2, 3, 4, 5]
    assert Intent(4) is Intent.END_SESSION
    assert not hasattr(Intent, "DETECT_OBJECT") and not hasattr(Intent, "VISUAL_QUESTION")


def test_compose_messages_per_intent():
    assert compose(Result(NO_IMAGE)) == "Chưa nhận được hình ảnh, bạn thử lại nhé."
    assert compose(Result(Intent.UNKNOWN)) == "Mình chưa hiểu yêu cầu, bạn nói lại giúp mình."
    assert "Tạm biệt" in compose(Result(Intent.END_SESSION))
    assert compose(Result(Intent.READ_TEXT, "abc")) == "abc"
    assert compose(Result(Intent.READ_TEXT, "  ")) == "Không đọc được chữ trong ảnh."


def test_stub_nlu_maps_vietnamese_phrases():
    async def parse(text):
        return (await StubNLU().parse(text)).intent

    assert asyncio.run(parse("đọc nội dung hóa đơn")) is Intent.READ_TEXT
    assert asyncio.run(parse("tả cảnh xung quanh")) is Intent.DESCRIBE_SCENE
    assert asyncio.run(parse("cái này màu gì")) is Intent.ANSWER_VISUAL_QUESTION
    assert asyncio.run(parse("kết thúc phiên đi")) is Intent.END_SESSION
    assert asyncio.run(parse("asdfgh qwerty")) is Intent.UNKNOWN


def test_crop_returns_jpeg_with_box_pixels():
    out = crop(png(100, 200), (0.1, 0.2, 0.5, 0.6))
    assert out[:2] == b"\xff\xd8"
    assert Image.open(io.BytesIO(out)).size == (40, 80)


def test_crop_clamps_box_to_image_bounds():
    out = crop(png(100, 100), (-0.1, -0.1, 1.2, 1.2))
    assert Image.open(io.BytesIO(out)).size == (100, 100)


def test_crop_rejects_degenerate_box_and_bad_image():
    with pytest.raises(CropError):
        crop(png(100, 100), (0.5, 0.5, 0.5, 0.5))
    with pytest.raises(CropError):
        crop(b"not-an-image", (0.0, 0.0, 1.0, 1.0))
