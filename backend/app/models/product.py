from sqlalchemy import Column, DateTime, Integer, Text
from sqlalchemy.sql import func

from app.models.base import Base


class Product(Base):
    __tablename__ = "products"

    id = Column(Text, primary_key=True)
    section = Column(Text, nullable=False)
    emoji = Column(Text, default="")
    bg = Column(Text, default="")
    badge = Column(Text, nullable=True)
    name1 = Column(Text, nullable=False)
    name2 = Column(Text, default="")
    latin = Column(Text, default="")
    description = Column(Text, default="")
    comp = Column(Text, default="")
    price = Column(Text, default="")
    unit = Column(Text, default="")
    sort_order = Column(Integer, default=0)
    photo_url = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
