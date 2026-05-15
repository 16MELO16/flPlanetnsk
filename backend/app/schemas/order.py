from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel


class OrderCreate(BaseModel):
    customer_name: str
    customer_phone: str
    customer_email: str = ""
    customer_comment: str = ""
    items: List[dict]
    total_amount: int
    has_approx_price: bool = False


class OrderUpdate(BaseModel):
    status: Optional[str] = None
    admin_notes: Optional[str] = None


class OrderOut(BaseModel):
    id: UUID
    created_at: datetime
    customer_name: str
    customer_phone: str
    customer_email: str
    customer_comment: str
    items: List[dict]
    total_amount: int
    has_approx_price: bool
    status: str
    admin_notes: str

    model_config = {"from_attributes": True}
