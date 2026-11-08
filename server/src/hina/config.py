from pydantic import Field, SecretStr
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
    vlm: str = "stub"  # model VLM tự fine-tune sẽ đăng ký ở đây
    tts: str = "stub"  # "fpt"

    # NLU qua API ngoài (HINA_NLU=http).
    nlu_url: str = "https://nlu.frshdrp.vn"
    nlu_timeout_s: float = 5

    # TTS qua FPT.AI (HINA_TTS=fpt).
    fpt_api_key: SecretStr | None = None
    fpt_voice: str = "banmai"
    fpt_speed: int = 0
    tts_timeout_s: float = 20
