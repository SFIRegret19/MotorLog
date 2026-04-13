from fastapi import FastAPI, Depends
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, String, Integer
from sqlalchemy.orm import sessionmaker, declarative_base, Session

# 1. НАСТРОЙКА БАЗЫ ДАННЫХ (Инфраструктура)
# Для простоты старта используем локальный файл SQLite, имитирующий облако. 
# Позже заменим эту строку на URL от PostgreSQL.
SQLALCHEMY_DATABASE_URL = "sqlite:///./motorlog_cloud.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# 2. МОДЕЛИ БАЗЫ ДАННЫХ (Domain)
class VehicleDB(Base):
    __tablename__ = "vehicles"
    id = Column(String, primary_key=True, index=True)
    brand = Column(String)
    model = Column(String)
    year = Column(Integer)
    vin = Column(String)
    currentMileage = Column(Integer)

# Создаем таблицы
Base.metadata.create_all(bind=engine)

# 3. СХЕМЫ ДАННЫХ (Для валидации входящего JSON от телефона)
class VehicleSchema(BaseModel):
    id: str
    brand: str
    model: str
    year: int
    vin: str
    currentMileage: int

    class Config:
        from_attributes = True

# Функция для получения сессии БД
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 4. НАШЕ ПРИЛОЖЕНИЕ (API Controllers)
app = FastAPI(title="MotorLog Cloud API")

@app.get("/")
def read_root():
    return {"status": "online", "message": "MotorLog Cloud Server is running!"}

# --- ЭНДПОИНТ ДЛЯ СИНХРОНИЗАЦИИ ---
# Сюда телефон будет присылать данные, когда появится интернет
@app.post("/api/sync/vehicle", response_model=VehicleSchema)
def sync_vehicle(vehicle: VehicleSchema, db: Session = Depends(get_db)):
    # Ищем, есть ли уже такая машина в "облаке"
    db_vehicle = db.query(VehicleDB).filter(VehicleDB.id == vehicle.id).first()
    
    if db_vehicle:
        # Если есть - обновляем данные (например, изменился пробег)
        db_vehicle.brand = vehicle.brand
        db_vehicle.model = vehicle.model
        db_vehicle.year = vehicle.year
        db_vehicle.vin = vehicle.vin
        db_vehicle.currentMileage = vehicle.currentMileage
    else:
        # Если нет - создаем новую запись
        db_vehicle = VehicleDB(
            id=vehicle.id,
            brand=vehicle.brand,
            model=vehicle.model,
            year=vehicle.year,
            vin=vehicle.vin,
            currentMileage=vehicle.currentMileage
        )
        db.add(db_vehicle)
        
    db.commit()
    db.refresh(db_vehicle)
    return db_vehicle

# Эндпоинт, чтобы посмотреть все машины в "облаке"
@app.get("/api/vehicles", response_model=list[VehicleSchema])
def get_all_vehicles(db: Session = Depends(get_db)):
    return db.query(VehicleDB).all()