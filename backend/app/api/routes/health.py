from datetime import datetime, timezone

from fastapi import APIRouter

router = APIRouter(tags=["health"])


@router.get("/health")
def health_check() -> dict:
    """Basic liveness check. Also acts as a cheap observability signal
    (uptime monitors / demo reviewers hit this first)."""
    return {
        "status": "ok",
        "service": "ascip-backend",
        "time": datetime.now(timezone.utc).isoformat(),
    }
