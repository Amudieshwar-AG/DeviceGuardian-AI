from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from datetime import datetime

import models
from database import engine, SessionLocal
from ai_pipeline import run_ai_pipeline

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="DeviceGuardian AI Backend")

# Enable CORS for Flutter web / mobile access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/")
def read_root():
    return {"message": "DeviceGuardian AI Backend is running"}

@app.post("/devices")
def register_device(telemetry: models.TelemetryCreate, db: Session = Depends(get_db)):
    # 1. Update or create the Device in the database
    device = db.query(models.DeviceRecord).filter(models.DeviceRecord.id == telemetry.deviceId).first()
    if not device:
        device = models.DeviceRecord(
            id=telemetry.deviceId,
            name=telemetry.name,
            deviceType=telemetry.deviceType,
            status=telemetry.status
        )
        db.add(device)
    else:
        device.status = telemetry.status
        device.lastUpdated = datetime.utcnow()

    # 2. Add telemetry data point
    new_telemetry = models.TelemetryRecord(
        deviceId=telemetry.deviceId,
        cpu=telemetry.cpu,
        ram=telemetry.ram,
        battery=telemetry.battery,
        temperature=telemetry.temperature,
        ssd=telemetry.ssd
    )
    db.add(new_telemetry)
    db.commit()
    
    return {"message": "Telemetry received successfully"}

@app.get("/devices")
def get_devices(db: Session = Depends(get_db)):
    devices = db.query(models.DeviceRecord).all()
    result = []
    for d in devices:
        # Get all telemetry history (oldest first for cycle estimation)
        all_telemetry = db.query(models.TelemetryRecord)\
            .filter(models.TelemetryRecord.deviceId == d.id)\
            .order_by(models.TelemetryRecord.timestamp.asc())\
            .all()
        
        # Latest reading is the last element
        latest_telemetry = all_telemetry[-1] if all_telemetry else None
            
        battery = latest_telemetry.battery if latest_telemetry else 100
        temp = latest_telemetry.temperature if latest_telemetry else 35
        
        # Run AI pipeline with full telemetry history for proper cycle estimation
        if latest_telemetry:
            telemetry_dict = {
                "deviceId": latest_telemetry.deviceId,
                "cpu": latest_telemetry.cpu,
                "ram": latest_telemetry.ram,
                "battery": latest_telemetry.battery,
                "temperature": latest_telemetry.temperature,
                "ssd": latest_telemetry.ssd
            }
            prediction = run_ai_pipeline(telemetry_dict, all_telemetry)
            health = prediction["healthScore"]
        else:
            health = 100
            
        result.append({
            "id": d.id,
            "name": d.name,
            "type": d.deviceType,
            "status": d.status,
            "lastUpdated": d.lastUpdated.isoformat(),
            "battery": battery,
            "temperature": temp,
            "healthScore": health
        })
    return result

@app.get("/devices/{device_id}")
def get_device(device_id: str, db: Session = Depends(get_db)):
    device = db.query(models.DeviceRecord).filter(models.DeviceRecord.id == device_id).first()
    if not device:
        raise HTTPException(status_code=404, detail="Device not found")
        
    latest_telemetry = db.query(models.TelemetryRecord)\
        .filter(models.TelemetryRecord.deviceId == device_id)\
        .order_by(models.TelemetryRecord.timestamp.desc())\
        .first()
        
    battery = latest_telemetry.battery if latest_telemetry else 100
    temp = latest_telemetry.temperature if latest_telemetry else 35
    ssd = latest_telemetry.ssd if latest_telemetry else 50
    cpu = latest_telemetry.cpu if latest_telemetry else 0
    ram = latest_telemetry.ram if latest_telemetry else 0
    
    return {
        "id": device.id,
        "name": device.name,
        "type": device.deviceType,
        "status": device.status,
        "lastUpdated": device.lastUpdated.isoformat(),
        "battery": battery,
        "temperature": temp,
        "ssd": ssd,
        "cpu": cpu,
        "ram": ram
    }

@app.get("/predictions/{device_id}", response_model=models.PredictionResponse)
def get_prediction(device_id: str, db: Session = Depends(get_db)):
    # 1. Get the latest telemetry for this device
    latest_telemetry = db.query(models.TelemetryRecord)\
        .filter(models.TelemetryRecord.deviceId == device_id)\
        .order_by(models.TelemetryRecord.timestamp.desc())\
        .first()
        
    if not latest_telemetry:
        # Return a default safe prediction if no telemetry exists yet
        return {
            "deviceId": device_id,
            "healthScore": 100,
            "riskLevel": "Low Risk",
            "recommendations": ["Waiting for first telemetry reading..."],
            "shapValues": {}
        }
        
    # 2. Get full telemetry history for cycle estimation
    all_telemetry = db.query(models.TelemetryRecord)\
        .filter(models.TelemetryRecord.deviceId == device_id)\
        .order_by(models.TelemetryRecord.timestamp.asc())\
        .all()
    
    # 3. Run the AI pipeline with history
    telemetry_dict = {
        "deviceId": latest_telemetry.deviceId,
        "cpu": latest_telemetry.cpu,
        "ram": latest_telemetry.ram,
        "battery": latest_telemetry.battery,
        "temperature": latest_telemetry.temperature,
        "ssd": latest_telemetry.ssd
    }
    
    prediction_result = run_ai_pipeline(telemetry_dict, all_telemetry)
    return prediction_result
