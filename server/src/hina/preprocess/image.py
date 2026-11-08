"""Tiền xử lý ảnh trước OCR/Detection/VLM."""

import io

from PIL import Image

from hina.geometry import Box


class CropError(ValueError):
    """Không cắt được vùng ảnh (ảnh hỏng hoặc box suy biến)."""


def crop(image: bytes, box: Box, *, min_side_px: int = 8) -> bytes:
    """Cắt vùng chuẩn hoá 0..1 khỏi ảnh, trả JPEG. Box tràn biên được clamp."""
    try:
        im = Image.open(io.BytesIO(image))
        im.load()
    except Exception as e:
        raise CropError("invalid image") from e
    im = im.convert("RGB")
    w, h = im.size
    x1 = max(0, min(w, round(box[0] * w)))
    y1 = max(0, min(h, round(box[1] * h)))
    x2 = max(0, min(w, round(box[2] * w)))
    y2 = max(0, min(h, round(box[3] * h)))
    if x2 - x1 < min_side_px or y2 - y1 < min_side_px:
        raise CropError("degenerate box")
    out = io.BytesIO()
    im.crop((x1, y1, x2, y2)).save(out, format="JPEG", quality=90)
    return out.getvalue()


def prepare_image(image: bytes, max_side: int = 1280) -> bytes:
    # TODO: kiểm tra kích thước, resize về max_side, sửa orientation (EXIF).
    return image
