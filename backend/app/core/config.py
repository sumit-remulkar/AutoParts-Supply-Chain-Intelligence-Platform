from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Central app configuration, loaded from environment variables / .env."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "ASCIP API"
    environment: str = "development"

    database_url: str = "postgresql://ascip:ascip@localhost:5432/ascip"

    jwt_secret: str = "change-me"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60

    anthropic_api_key: str | None = None

    cors_origins: list[str] = ["http://localhost:3000"]


settings = Settings()
