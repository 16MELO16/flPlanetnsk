from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class ProductBase(BaseModel):
    section: str = Field(pattern="^(cut|pot|cuttings)$")
    emoji: str = ""
    bg: str = ""
    badge: Optional[str] = Field(default=None, pattern="^(hit|rare|new)$")
    name1: str
    name2: str = ""
    latin: str = ""
    description: str = ""
    comp: str = ""
    price: str = ""
    unit: str = ""
    sort_order: int = 0
    photo_url: Optional[str] = None


class ProductCreate(ProductBase):
    id: str


class ProductUpdate(BaseModel):
    section: Optional[str] = Field(default=None, pattern="^(cut|pot|cuttings)$")
    emoji: Optional[str] = None
    bg: Optional[str] = None
    badge: Optional[str] = Field(default=None, pattern="^(hit|rare|new)$")
    name1: Optional[str] = None
    name2: Optional[str] = None
    latin: Optional[str] = None
    description: Optional[str] = None
    comp: Optional[str] = None
    price: Optional[str] = None
    unit: Optional[str] = None
    sort_order: Optional[int] = None
    photo_url: Optional[str] = None


class ProductPhotoUpdate(BaseModel):
    photo_url: Optional[str] = None


class ProductOut(ProductBase):
    id: str
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}
