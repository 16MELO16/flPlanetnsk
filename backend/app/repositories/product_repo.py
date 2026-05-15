from typing import List, Optional

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.product import Product
from app.schemas.product import ProductCreate, ProductUpdate


class ProductRepository:
    def list(self, db: Session, section: Optional[str] = None) -> List[Product]:
        stmt = select(Product).order_by(Product.section, Product.sort_order, Product.created_at)
        if section:
            stmt = stmt.where(Product.section == section)
        return db.execute(stmt).scalars().all()

    def get(self, db: Session, product_id: str) -> Product | None:
        return db.get(Product, product_id)

    def next_sort_order(self, db: Session, section: str) -> int:
        stmt = select(func.coalesce(func.max(Product.sort_order), 0)).where(Product.section == section)
        return int(db.execute(stmt).scalar_one()) + 1

    def create(self, db: Session, payload: ProductCreate) -> Product:
        data = payload.model_dump()
        if not data.get("sort_order"):
            data["sort_order"] = self.next_sort_order(db, data["section"])
        product = Product(**data)
        db.add(product)
        return product

    def update(self, product: Product, payload: ProductUpdate) -> Product:
        for key, value in payload.model_dump(exclude_unset=True).items():
            setattr(product, key, value)
        return product

    def delete(self, db: Session, product: Product) -> None:
        db.delete(product)
