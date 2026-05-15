from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.repositories.product_repo import ProductRepository
from app.schemas.product import ProductCreate, ProductPhotoUpdate, ProductUpdate
from app.services.product_service import ProductService

router = APIRouter()


def get_service() -> ProductService:
    return ProductService(ProductRepository())


@router.get("/products")
def list_products(
    section: Optional[str] = Query(default=None),
    db: Session = Depends(get_db),
    service: ProductService = Depends(get_service),
):
    return service.list_products(db, section)


@router.post("/products")
def create_product(
    payload: ProductCreate,
    db: Session = Depends(get_db),
    service: ProductService = Depends(get_service),
):
    return service.create_product(db, payload)


@router.patch("/products/{product_id}")
def update_product(
    product_id: str,
    payload: ProductUpdate,
    db: Session = Depends(get_db),
    service: ProductService = Depends(get_service),
):
    updated = service.update_product(db, product_id, payload)
    if not updated:
        raise HTTPException(status_code=404, detail="product_not_found")
    return updated


@router.patch("/products/{product_id}/photo")
def update_product_photo(
    product_id: str,
    payload: ProductPhotoUpdate,
    db: Session = Depends(get_db),
    service: ProductService = Depends(get_service),
):
    updated = service.update_photo(db, product_id, payload)
    if not updated:
        raise HTTPException(status_code=404, detail="product_not_found")
    return updated


@router.delete("/products/{product_id}")
def delete_product(
    product_id: str,
    db: Session = Depends(get_db),
    service: ProductService = Depends(get_service),
):
    ok = service.delete_product(db, product_id)
    if not ok:
        raise HTTPException(status_code=404, detail="product_not_found")
    return {"ok": True}
