from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.repositories.order_repo import OrderRepository
from app.schemas.order import OrderCreate, OrderUpdate
from app.services.order_service import OrderService

router = APIRouter()


@router.get("/orders")
def list_orders(
    status: Optional[str] = Query(default=None),
    db: Session = Depends(get_db),
):
    service = OrderService(OrderRepository())
    return service.list_orders(db, status)


@router.post("/orders")
def create_order(payload: OrderCreate, db: Session = Depends(get_db)):
    service = OrderService(OrderRepository())
    return service.create_order(db, payload)


@router.patch("/orders/{order_id}")
def update_order(
    order_id: str,
    payload: OrderUpdate,
    db: Session = Depends(get_db),
):
    service = OrderService(OrderRepository())
    updated = service.update_order(db, order_id, payload)
    if not updated:
        raise HTTPException(status_code=404, detail="order_not_found")
    return updated


@router.delete("/orders/{order_id}")
def delete_order(order_id: str, db: Session = Depends(get_db)):
    service = OrderService(OrderRepository())
    ok = service.delete_order(db, order_id)
    if not ok:
        raise HTTPException(status_code=404, detail="order_not_found")
    return {"ok": True}
