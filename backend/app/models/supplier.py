from datetime import datetime, timezone
from enum import Enum

from sqlmodel import Field, SQLModel


class SupplierStatus(str, Enum):
    preferred = "preferred"
    active = "active"
    inactive = "inactive"
    high_risk = "high_risk"


class Supplier(SQLModel, table=True):
    """Supplier master data.

    Kept intentionally small for the MVP — performance history (delays,
    quality rejects, price volatility) lives in `supplier_performance`
    and feeds the risk-scoring engine, not this table.
    """

    id: int | None = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    location: str | None = None
    category: str | None = Field(default=None, index=True)
    lead_time_days: int | None = None
    quality_score: float | None = None  # 0-100, updated by risk engine
    status: SupplierStatus = Field(default=SupplierStatus.active)
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
