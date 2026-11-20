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
    tts: str = "stub"  # "fpt" | "mms"
    text_detector: str = "stub"  # "ppocr"

    # Model tự host (xem D:/<model>-api): URL + X-API-Key. Cùng mạng docker thì dùng http://<container>:8000.
    phowhisper_url: str = "https://stt.frshdrp.vn"
    phowhisper_api_key: SecretStr | None = None
    asr_timeout_s: float = 30
    ppocr_url: str = "https://ocr-det.frshdrp.vn"
    ppocr_api_key: SecretStr | None = None
    vietocr_url: str = "https://ocr.frshdrp.vn"
    vietocr_api_key: SecretStr | None = None
    ocr_timeout_s: float = 10  # dùng cho cả ppocr và vietocr
    yolo_url: str = "https://yolo.frshdrp.vn"
    yolo_api_key: SecretStr | None = None
    yolo_conf: float = 0.35
    detector_timeout_s: float = 5
    smolvlm_url: str = "https://vlm.frshdrp.vn"
    smolvlm_api_key: SecretStr | None = None
    smolvlm_max_tokens: int = 48  # ~1 s/token trên CPU
    mms_url: str = "https://tts.frshdrp.vn"
    mms_api_key: SecretStr | None = None

    # NLU qua API ngoài (HINA_NLU=http).
    nlu_url: str = "https://nlu.frshdrp.vn"
    nlu_timeout_s: float = 5

    # TTS qua FPT.AI (HINA_TTS=fpt).
    fpt_api_key: SecretStr | None = None
    fpt_voice: str = "banmai"
    fpt_speed: int = 0
    tts_timeout_s: float = 20

    # VLM qua Google Gemini (HINA_VLM=gemini). gemini-3.5-flash ~5 s; cần nhanh hơn: gemini-flash-lite-latest.
    gemini_api_key: SecretStr | None = None
    gemini_base_url: str | None = None  # đặt trong .env (HINA_GEMINI_BASE_URL)
    gemini_model: str = "gemini-3.5-flash"
    vlm_timeout_s: float = 15

    # Trang /debug xem luồng request (chứa ảnh/câu nói của người dùng): CHỈ bật khi dev.
    debug: bool = False
