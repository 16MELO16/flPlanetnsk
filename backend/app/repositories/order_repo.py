from typing import List, Optional

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.order import Order
from app.schemas.order import OrderCreate, OrderUpdate


class OrderRepository:
    def list(self, db: Session, status: Optional[str] = None) -> List[Order]:
        stmt = select(Order).order_by(Order.created_at.desc())
        if status:
            stmt = stmt.where(Order.status == status)
        return db.execute(stmt).scalars().all()

    def create(self, db: Session, payload: OrderCreate) -> Order:
        order = Order(**payload.model_dump())
        db.add(order)
        return order

    def update(self, db: Session, order: Order, payload: OrderUpdate) -> Order:
        data = payload.model_dump(exclude_unset=True)
        for key, value in data.items():
            setattr(order, key, value)
        return order

    def delete(self, db: Session, order: Order) -> None:
        db.delete(order)
