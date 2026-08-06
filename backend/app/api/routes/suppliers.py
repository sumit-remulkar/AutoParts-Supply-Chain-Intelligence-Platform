from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.core.database import get_session
from app.models.supplier import Supplier
from app.schemas.supplier import SupplierCreate, SupplierRead

router = APIRouter(prefix="/suppliers", tags=["suppliers"])


@router.get("", response_model=list[SupplierRead])
def list_suppliers(session: Session = Depends(get_session)) -> list[Supplier]:
    return session.exec(select(Supplier)).all()


@router.post("", response_model=SupplierRead, status_code=201)
def create_supplier(
    payload: SupplierCreate, session: Session = Depends(get_session)
) -> Supplier:
    supplier = Supplier(**payload.model_dump())
    session.add(supplier)
    session.commit()
    session.refresh(supplier)
    return supplier


@router.get("/{supplier_id}", response_model=SupplierRead)
def get_supplier(supplier_id: int, session: Session = Depends(get_session)) -> Supplier:
    supplier = session.get(Supplier, supplier_id)
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    return supplier


# TODO (next steps in the build):
# - PATCH /{supplier_id}  (update)
# - DELETE /{supplier_id}
# - GET /{supplier_id}/risk-score  -> wired up once the risk-scoring engine (ai/) lands
# - GET /{supplier_id}/performance -> reads from supplier_performance table
