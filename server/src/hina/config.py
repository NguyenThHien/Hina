from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="HINA_", env_file=".env", extra="ignore")

    # Bắt buộc, không có default: thiếu hoặc quá ngắn thì server không khởi động.
    jwt_secret: str = Field(min_length=32)
    jwt_ttl_s: int = 900
    gpu_queue_size: int = 16

    # Tên impl cho từng khối AI (xem ai/registry.py). Đổi sang model thật sau benchmark.
    asr: str = "stub"
    nlu: str = "stub"
    ocr: str = "stub"
    detector: str = "stub"
    depth: str = "stub"
    vlm: str = "stub"
    tts: str = "stub"
