from sqlalchemy import Boolean, Column, DateTime, Integer, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func, text
from sqlalchemy.types import UUID

from app.models.base import Base


class Order(Base):
    __tablename__ = "orders"

    id = Column(UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    customer_name = Column(Text, nullable=False)
    customer_phone = Column(Text, nullable=False)
    customer_email = Column(Text, default="")
    customer_comment = Column(Text, default="")
    items = Column(JSONB, nullable=False)
    total_amount = Column(Integer, nullable=False, default=0)
    has_approx_price = Column(Boolean, nullable=False, default=False)
    status = Column(Text, nullable=False, default="new")
    admin_notes = Column(Text, default="")
