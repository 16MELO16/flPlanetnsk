from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.repositories.product_repo import ProductRepository
from app.schemas.product import ProductPhotoUpdate
from app.services.product_service import ProductService

router = APIRouter()


@router.patch("/photos/products/{product_id}")
def update_product_photo(product_id: str, payload: ProductPhotoUpdate, db: Session = Depends(get_db)):
    service = ProductService(ProductRepository())
    updated = service.update_photo(db, product_id, payload)
    if not updated:
        raise HTTPException(status_code=404, detail="product_not_found")
    return updated
