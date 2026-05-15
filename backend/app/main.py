from fastapi import FastAPI

from app.api.routes.orders import router as orders_router
from app.api.routes.photos import router as photos_router
from app.api.routes.products import router as products_router

app = FastAPI(title="Flower Planet API")


@app.get("/api/health")
def health_check():
    return {"ok": True}


app.include_router(orders_router, prefix="/api")
app.include_router(products_router, prefix="/api")
app.include_router(photos_router, prefix="/api")
