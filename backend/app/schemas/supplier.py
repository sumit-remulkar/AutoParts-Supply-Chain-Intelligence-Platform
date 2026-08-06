from pydantic import BaseModel

from app.models.supplier import SupplierStatus


class SupplierCreate(BaseModel):
    name: str
    location: str | None = None
    category: str | None = None
    lead_time_days: int | None = None


class SupplierRead(BaseModel):
    id: int
    name: str
    location: str | None
    category: str | None
    lead_time_days: int | None
    quality_score: float | None
    status: SupplierStatus
