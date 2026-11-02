"""Tiền xử lý ảnh trước OCR/Detection/VLM (placeholder, chưa nối vào orchestrator)."""


def prepare_image(image: bytes, max_side: int = 1280) -> bytes:
    # TODO: decode JPEG, kiểm tra kích thước, resize về max_side, sửa orientation (EXIF).
    return image
