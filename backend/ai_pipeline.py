import os
import pandas as pd
import numpy as np
import xgboost as xgb
import shap
from sqlalchemy.orm import Session

MODEL_PATH = "xgb_model.json"
model = None
explainer = None

def synthesize_nasa_calce_dataset():
    """
    Synthesize a dataset mimicking NASA/CALCE battery degradation.
    
    KEY INSIGHT: In NASA/CALCE datasets, battery HEALTH/CAPACITY is degraded by:
      1. Number of charge cycles (age of the battery)
      2. Operating temperature (heat accelerates chemical degradation)
      3. CPU/thermal stress (sustained high load = heat = faster aging)
    
    Current battery charge level (SoC) is NOT a health indicator.
    A phone at 26% charge is perfectly healthy. Only degradation matters.
    """
    print("Synthesizing NASA CALCE battery degradation dataset...")
    np.random.seed(42)
    n_samples = 2000
    
    # Feature 1: Estimated charge cycles (0 = new, 1000 = heavily aged)
    charge_cycles = np.random.randint(0, 1000, n_samples)
    
    # Feature 2: Average operating temperature in Celsius
    # Normal phone: 28-40°C. Hot environment / heavy gaming: 40-55°C+
    avg_temperature = np.random.normal(34, 8, n_samples)
    avg_temperature = np.clip(avg_temperature, 20, 60)
    
    # Feature 3: Average CPU load intensity (0-100%)
    avg_cpu_load = np.random.normal(35, 20, n_samples)
    avg_cpu_load = np.clip(avg_cpu_load, 0, 100)
    
    # Target: Battery capacity retention (health score 0-100)
    # Formula inspired by Arrhenius degradation model from NASA CALCE research:
    # - Each cycle causes linear capacity loss (~0.03% per cycle)
    # - Temperature above 40°C accelerates degradation exponentially (Arrhenius)
    # - CPU stress adds thermal cycles
    
    base_degradation = charge_cycles * 0.05  # 0.05% loss per cycle
    
    excess_heat = np.maximum(0, avg_temperature - 40)  # Only positive values
    thermal_stress = excess_heat ** 1.5 * 0.3  # Exponential above 40°C
    
    cpu_thermal = avg_cpu_load * 0.02  # CPU-induced thermal cycling
    
    capacity = 100 - base_degradation - thermal_stress - cpu_thermal
    capacity = np.clip(capacity, 10, 100)  # Battery never goes below 10% retention
    
    df = pd.DataFrame({
        "charge_cycles": charge_cycles,
        "avg_temperature": avg_temperature,
        "avg_cpu_load": avg_cpu_load,
        "capacity_retention": capacity
    })
    return df

def train_or_load_model():
    global model, explainer
    if model is not None:
        return
        
    model = xgb.XGBRegressor(
        n_estimators=200,
        max_depth=5,
        learning_rate=0.05,
        subsample=0.8,
        colsample_bytree=0.8,
        random_state=42
    )
        
    df = synthesize_nasa_calce_dataset()
    X = df[["charge_cycles", "avg_temperature", "avg_cpu_load"]]
    y = df["capacity_retention"]
    
    print("Training XGBoost model on NASA CALCE synthetic data...")
    model.fit(X, y)
    
    print("Building SHAP TreeExplainer...")
    explainer = shap.TreeExplainer(model, X.sample(100, random_state=42))
    print("Model ready.")

# Initialize on startup
train_or_load_model()

def estimate_charge_cycles_from_history(telemetry_records: list) -> int:
    """
    Estimate total charge cycles from telemetry history.
    A cycle = draining from ~100% to ~0% and recharging.
    We approximate by counting large battery drops between readings.
    """
    if not telemetry_records or len(telemetry_records) < 2:
        # Default estimate: assume a 1-year-old phone with ~300 cycles
        return 300
    
    levels = [r.battery for r in telemetry_records]
    cycles = 0
    for i in range(1, len(levels)):
        drop = levels[i-1] - levels[i]
        if drop > 20:  # Significant drop = partial cycle
            cycles += drop / 100.0
    
    return max(100, int(cycles * 10))  # Scale up and ensure minimum

def run_ai_pipeline(telemetry_data: dict, telemetry_history: list = None) -> dict:
    """
    Run XGBoost prediction with SHAP explanations.
    
    IMPORTANT: Battery current level (SoC) is a raw metric shown in UI.
    It does NOT drive the health score. Health is about battery capacity DEGRADATION.
    """
    global model, explainer
    
    temp = float(telemetry_data.get("temperature", 34.0))
    cpu = float(telemetry_data.get("cpu", 35.0))
    battery = float(telemetry_data.get("battery", 80.0))
    
    # Estimate charge cycles from history if available
    charge_cycles = estimate_charge_cycles_from_history(telemetry_history)
    
    input_df = pd.DataFrame([{
        "charge_cycles": charge_cycles,
        "avg_temperature": temp,
        "avg_cpu_load": cpu,
    }])
    
    # 1. Predict Health Score (battery capacity retention %)
    pred_capacity = model.predict(input_df)[0]
    health_score = int(np.clip(pred_capacity, 0, 100))
    
    # 2. Calculate real SHAP values
    shap_values_matrix = explainer.shap_values(input_df)
    shap_vals = shap_values_matrix[0]  # array for 3 features
    
    abs_shap = np.abs(shap_vals)
    total_abs_shap = np.sum(abs_shap)
    
    if total_abs_shap < 1e-9:
        shap_dict = {"Battery Age (Cycles)": 0.34, "Thermal Stress": 0.33, "CPU Load": 0.33}
    else:
        shap_dict = {
            "Battery Age (Cycles)": float(abs_shap[0] / total_abs_shap),
            "Thermal Stress": float(abs_shap[1] / total_abs_shap),
            "CPU Load": float(abs_shap[2] / total_abs_shap)
        }
        
    # 3. Risk classification and recommendations
    if health_score >= 80:
        risk_level = "Low Risk"
        recommendations = [
            "Battery health is excellent. Keep up the good habits!",
            "Maintain temperatures below 40°C to extend battery life.",
        ]
    elif health_score >= 60:
        risk_level = "Medium Risk"
        recommendations = [
            "Battery showing moderate wear. Avoid overnight charging.",
            "Keep the device cool — heat is the main cause of battery degradation.",
            "Avoid letting battery drop below 15% frequently.",
        ]
    else:
        risk_level = "High Risk"
        recommendations = [
            "Battery capacity significantly degraded. Consider a replacement.",
            "Reduce charging to 80% max to slow further degradation.",
            "Avoid heavy gaming or apps that cause sustained high temperatures.",
        ]
        
    return {
        "deviceId": telemetry_data.get("deviceId"),
        "healthScore": health_score,
        "riskLevel": risk_level,
        "recommendations": recommendations,
        "shapValues": shap_dict
    }
