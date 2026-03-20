from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "sqlite+aiosqlite:///./data/goriva.db"
    fetch_interval_hours: int = 1
    goriva_base_url: str = "https://goriva.si"

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()
