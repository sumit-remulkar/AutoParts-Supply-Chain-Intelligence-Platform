from collections.abc import Generator

from sqlmodel import Session, SQLModel, create_engine

from app.core.config import settings

engine = create_engine(settings.database_url, echo=False)


def init_db() -> None:
    """Create tables from SQLModel metadata.

    In this project the canonical schema lives in database/schema.sql
    (run automatically by docker-compose on first Postgres start).
    This is kept for local dev convenience / tests using SQLite or a
    throwaway Postgres instance without the init script.
    """
    SQLModel.metadata.create_all(engine)


def get_session() -> Generator[Session, None, None]:
    with Session(engine) as session:
        yield session
