from typing import List, Optional
from uuid import UUID

from sqlalchemy.orm import Session

from app.models.order import Order
from app.repositories.order_repo import OrderRepository
from app.schemas.order import OrderCreate, OrderOut, OrderUpdate


class OrderService:
    def __init__(self, repo: OrderRepository) -> None:
        self.repo = repo

    def list_orders(self, db: Session, status: Optional[str]) -> List[OrderOut]:
        orders = self.repo.list(db, status)
        return [OrderOut.model_validate(o) for o in orders]

    def create_order(self, db: Session, payload: OrderCreate) -> OrderOut:
        order = self.repo.create(db, payload)
        db.commit()
        db.refresh(order)
        return OrderOut.model_validate(order)

    def update_order(self, db: Session, order_id: str, payload: OrderUpdate) -> OrderOut | None:
        order = self._get_order(db, order_id)
        if not order:
            return None
        updated = self.repo.update(db, order, payload)
        db.commit()
        db.refresh(updated)
        return OrderOut.model_validate(updated)

    def delete_order(self, db: Session, order_id: str) -> bool:
        order = self._get_order(db, order_id)
        if not order:
            return False
        self.repo.delete(db, order)
        db.commit()
        return True

    @staticmethod
    def _get_order(db: Session, order_id: str) -> Order | None:
        try:
            return db.get(Order, UUID(order_id))
        except ValueError:
            return None
