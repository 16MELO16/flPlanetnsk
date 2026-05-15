from typing import List, Optional

from sqlalchemy.orm import Session

from app.repositories.product_repo import ProductRepository
from app.schemas.product import ProductCreate, ProductOut, ProductPhotoUpdate, ProductUpdate


class ProductService:
    def __init__(self, repo: ProductRepository) -> None:
        self.repo = repo

    def list_products(self, db: Session, section: Optional[str] = None) -> List[ProductOut]:
        return [ProductOut.model_validate(p) for p in self.repo.list(db, section)]

    def create_product(self, db: Session, payload: ProductCreate) -> ProductOut:
        product = self.repo.create(db, payload)
        db.commit()
        db.refresh(product)
        return ProductOut.model_validate(product)

    def update_product(self, db: Session, product_id: str, payload: ProductUpdate) -> ProductOut | None:
        product = self.repo.get(db, product_id)
        if not product:
            return None
        updated = self.repo.update(product, payload)
        db.commit()
        db.refresh(updated)
        return ProductOut.model_validate(updated)

    def update_photo(self, db: Session, product_id: str, payload: ProductPhotoUpdate) -> ProductOut | None:
        return self.update_product(db, product_id, ProductUpdate(photo_url=payload.photo_url))

    def delete_product(self, db: Session, product_id: str) -> bool:
        product = self.repo.get(db, product_id)
        if not product:
            return False
        self.repo.delete(db, product)
        db.commit()
        return True
