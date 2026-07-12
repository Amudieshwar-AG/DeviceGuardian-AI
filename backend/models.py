from sqlalchemy import Column, Integer, String, Float, DateTime
from database import Base
from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

# SQLAlchemy Models (Database)
class DeviceRecord(Base):
    __tablename__ = "devices"

    id = Column(String, primary_key=True, index=True)
    name = Column(String, index=True)
    deviceType = Column(String)
    status = Column(String)
    lastUpdated = Column(DateTime, default=datetime.utcnow)
    remainingUsefulLife = Column(Float, default=36.0)

class TelemetryRecord(Base):
    __tablename__ = "telemetry"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    deviceId = Column(String, index=True)
    cpu = Column(Float)
    ram = Column(Float)
    battery = Column(Float)
    temperature = Column(Float)
    ssd = Column(Float)
    timestamp = Column(DateTime, default=datetime.utcnow)

class AIPrediction(Base):
    __tablename__ = "ai_predictions"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    deviceId = Column(String, index=True)
    healthScore = Column(Integer)
    riskLevel = Column(String)
    isAnomaly = Column(Integer)  # 0 or 1
    anomalyScore = Column(Float)
    confidenceLevel = Column(Float)
    timestamp = Column(DateTime, default=datetime.utcnow)

# Pydantic Models (API Validation)
class TelemetryCreate(BaseModel):
    deviceId: str
    name: str
    deviceType: str
    cpu: float
    ram: float
    battery: float
    temperature: float
    ssd: float
    status: str
    timestamp: str

class DeviceResponse(BaseModel):
    id: str
    name: str
    type: str
    status: str
    lastUpdated: str

class ActionableRecommendation(BaseModel):
    title: str
    description: str
    improvement: str
    icon: str
    color: str

class PredictionResponse(BaseModel):
    deviceId: str
    healthScore: int
    riskLevel: str
    recommendations: List[ActionableRecommendation]
    shapValues: dict[str, float]
    isAnomaly: bool
    anomalyScore: float
    confidenceLevel: float
    remainingUsefulLife: float = 36.0

class SupportTicketRequest(BaseModel):
    deviceId: str
    healthScore: int
    riskLevel: str
    cpu: float
    ram: float
    battery: float
    temperature: float
    ssd: float

class SupportTicketResponse(BaseModel):
    status: str
    ticketId: str
    message: str
