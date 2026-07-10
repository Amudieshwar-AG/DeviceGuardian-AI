import os
import pandas as pd
import numpy as np
import xgboost as xgb
import shap
from sqlalchemy.orm import Session

import pickle

MODEL_PATH = "xgb_model.json"
ANOMALY_MODEL_PATH = "anomaly_model.pkl"
model = None
explainer = None
iso_forest = None

def synthesize_nasa_calce_dataset():
    """
    Synthesize a comprehensive dataset mimicking device degradation across Battery, CPU, and Storage.
    """
    print("Synthesizing comprehensive device degradation dataset...")
    np.random.seed(42)
    n_samples = 10000
    
    # 1. Feature Generation
    # Battery: Estimated charge cycles (0 = new, 1000 = heavily aged)
    charge_cycles = np.random.randint(0, 1000, n_samples)
    
    # Thermal: Average operating temperature in Celsius
    avg_temperature = np.random.normal(34, 8, n_samples)
    avg_temperature = np.clip(avg_temperature, 20, 60)
    
    # CPU: Average CPU load intensity (0-100%)
    avg_cpu_load = np.random.normal(35, 20, n_samples)
    avg_cpu_load = np.clip(avg_cpu_load, 0, 100)
    
    # Storage: SSD Terabytes Written (TBW) proxy (0-100% of warranty)
    ssd_tbw = np.random.randint(0, 100, n_samples)
    
    # RAM/Storage: RAM Swap Stress (0-100%) - frequent paging wears out SSD
    ram_swap_stress = np.random.normal(30, 25, n_samples)
    ram_swap_stress = np.clip(ram_swap_stress, 0, 100)
    
    # 2. Target Degradation Calculations
    
    # Battery Degradation (more realistic)
    base_battery_deg = charge_cycles * 0.015  # 1000 cycles = 15% degradation
    excess_heat = np.maximum(0, avg_temperature - 40)
    thermal_stress = excess_heat ** 1.3 * 0.15
    cpu_thermal = avg_cpu_load * 0.01
    battery_health = 100 - base_battery_deg - thermal_stress - cpu_thermal
    battery_health = np.clip(battery_health, 10, 100)
    
    # CPU Degradation
    cpu_health = 100 - (excess_heat ** 1.5 * 0.1) - (avg_cpu_load * 0.02)
    cpu_health = np.clip(cpu_health, 10, 100)
    
    # Storage Degradation (eMMC/SSD wears slower)
    storage_health = 100 - (ssd_tbw * 0.15) - (ram_swap_stress * 0.05)
    storage_health = np.clip(storage_health, 10, 100)
    
    # Overall System Health
    overall_health = np.minimum(battery_health, np.minimum(cpu_health, storage_health))
    
    df = pd.DataFrame({
        "charge_cycles": charge_cycles,
        "avg_temperature": avg_temperature,
        "avg_cpu_load": avg_cpu_load,
        "ssd_tbw": ssd_tbw,
        "ram_swap_stress": ram_swap_stress,
        "overall_health": overall_health
    })
    return df

def train_or_load_model():
    global model, explainer, iso_forest
    if model is not None and iso_forest is not None:
        return
        
    model = xgb.XGBRegressor(
        n_estimators=200,
        max_depth=5,
        learning_rate=0.05,
        subsample=0.8,
        colsample_bytree=0.8,
        base_score=0.5,
        random_state=42
    )
    
    if os.path.exists(MODEL_PATH):
        print(f"Loading trained model from {MODEL_PATH}...")
        model.load_model(MODEL_PATH)
    else:
        dataset_path = "device_health_dataset.csv"
        if os.path.exists(dataset_path):
            print(f"Loading dataset from {dataset_path}...")
            df = pd.read_csv(dataset_path)
        else:
            df = synthesize_nasa_calce_dataset()
            df.to_csv(dataset_path, index=False)
            print(f"Saved generated dataset to {dataset_path}")
            
        X = df[["charge_cycles", "avg_temperature", "avg_cpu_load", "ssd_tbw", "ram_swap_stress"]]
        y = df["overall_health"]
        
        print("Training XGBoost model on comprehensive system dataset...")
        from sklearn.model_selection import train_test_split
        from sklearn.metrics import r2_score, mean_absolute_error
        import json
        
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        model.fit(X_train, y_train)
        
        y_pred = model.predict(X_test)
        r2 = r2_score(y_test, y_pred)
        mae = mean_absolute_error(y_test, y_pred)
        
        errors = np.abs(y_pred - y_test)
        acc_2 = float(np.mean(errors <= 2.0))
        acc_3 = float(np.mean(errors <= 3.0))
        
        proof = {
            "r2_score": float(r2),
            "mae_percent": float(mae),
            "accuracy_within_2_percent": acc_2,
            "accuracy_within_3_percent": acc_3,
            "total_samples": len(df),
            "validation_samples": len(X_test),
            "features_used": list(X.columns)
        }
        
        with open("accuracy_proof.json", "w") as f:
            json.dump(proof, f, indent=4)
            
        print(f"Model validation completed. R2: {r2:.4f}, MAE: {mae:.4f}, Acc(2%): {acc_2:.4f}")
        model.save_model(MODEL_PATH)
        print(f"Saved trained model to {MODEL_PATH}")
        
    if os.path.exists(ANOMALY_MODEL_PATH):
        print(f"Loading anomaly model from {ANOMALY_MODEL_PATH}...")
        with open(ANOMALY_MODEL_PATH, "rb") as f:
            iso_forest = pickle.load(f)
    else:
        dataset_path = "device_health_dataset.csv"
        if os.path.exists(dataset_path):
            df = pd.read_csv(dataset_path)
        else:
            df = synthesize_nasa_calce_dataset()
            df.to_csv(dataset_path, index=False)
            
        X = df[["charge_cycles", "avg_temperature", "avg_cpu_load", "ssd_tbw", "ram_swap_stress"]]
        print("Training Isolation Forest anomaly detection...")
        from sklearn.ensemble import IsolationForest
        iso_forest = IsolationForest(contamination=0.03, random_state=42)
        iso_forest.fit(X)
        with open(ANOMALY_MODEL_PATH, "wb") as f:
            pickle.dump(iso_forest, f)
        print(f"Saved anomaly model to {ANOMALY_MODEL_PATH}")
    
    print("Building SHAP TreeExplainer...")
    explainer = shap.TreeExplainer(model)
    print("Model ready.")

# Initialize on startup
train_or_load_model()

def estimate_charge_cycles_from_history(telemetry_records: list) -> int:
    if not telemetry_records or len(telemetry_records) < 2:
        return 300
    
    levels = [r.battery for r in telemetry_records]
    cycles = 0
    for i in range(1, len(levels)):
        drop = levels[i-1] - levels[i]
        if drop > 20: 
            cycles += drop / 100.0
    return max(100, int(cycles * 10))

def estimate_ssd_tbw_from_history(telemetry_records: list) -> float:
    """Estimate SSD wear based on high storage utilization over time."""
    if not telemetry_records:
        return 20.0
    # A simple proxy: if SSD is consistently full, TBW accumulates faster.
    avg_ssd = sum(r.ssd for r in telemetry_records) / len(telemetry_records)
    # Base wear (e.g. 15%) + extra wear if SSD is very full
    wear = 15.0 + (max(0, avg_ssd - 70) * 1.5)
    return min(100.0, wear)

def estimate_ram_stress_from_history(telemetry_records: list) -> float:
    """Estimate RAM swap stress from high memory usage."""
    if not telemetry_records:
        return 30.0
    avg_ram = sum(r.ram for r in telemetry_records) / len(telemetry_records)
    # Swap stress increases exponentially past 80% RAM usage
    stress = (max(0, avg_ram - 60) ** 1.3) * 0.8
    return min(100.0, stress)

def run_ai_pipeline(telemetry_data: dict, telemetry_history: list = None) -> dict:
    global model, explainer
    
    temp = float(telemetry_data.get("temperature", 34.0))
    cpu = float(telemetry_data.get("cpu", 35.0))
    
    # Feature extraction from history
    charge_cycles = estimate_charge_cycles_from_history(telemetry_history)
    ssd_tbw = estimate_ssd_tbw_from_history(telemetry_history)
    ram_swap_stress = estimate_ram_stress_from_history(telemetry_history)
    
    input_df = pd.DataFrame([{
        "charge_cycles": charge_cycles,
        "avg_temperature": temp,
        "avg_cpu_load": cpu,
        "ssd_tbw": ssd_tbw,
        "ram_swap_stress": ram_swap_stress
    }])
    
    # 1. Predict Overall System Health Score
    pred_health = model.predict(input_df)[0]
    health_score = int(np.clip(pred_health, 0, 100))
    
    # Predict Anomaly using Isolation Forest
    is_anomaly = False
    anomaly_score = 0.0
    if iso_forest is not None:
        anomaly_pred = iso_forest.predict(input_df)[0]
        is_anomaly = bool(anomaly_pred == -1)
        anomaly_score = float(iso_forest.decision_function(input_df)[0])
        
    # 2. Calculate SHAP values
    shap_values_matrix = explainer.shap_values(input_df)
    shap_vals = shap_values_matrix[0]  # array for 5 features
    
    abs_shap = np.abs(shap_vals)
    total_abs_shap = np.sum(abs_shap)
    
    if total_abs_shap < 1e-9:
        shap_dict = {
            "Battery Age (Cycles)": 0.20,
            "Thermal Stress": 0.20,
            "CPU Load": 0.20,
            "SSD Wear (TBW)": 0.20,
            "RAM Swap Stress": 0.20
        }
    else:
        shap_dict = {
            "Battery Age (Cycles)": float(abs_shap[0] / total_abs_shap),
            "Thermal Stress": float(abs_shap[1] / total_abs_shap),
            "CPU Load": float(abs_shap[2] / total_abs_shap),
            "SSD Wear (TBW)": float(abs_shap[3] / total_abs_shap),
            "RAM Swap Stress": float(abs_shap[4] / total_abs_shap)
        }
        
    # 3. Dynamic Recommendations based on SHAP impacts
    # Find the feature with the highest negative impact (largest magnitude)
    # SHAP values can be negative if they lower the health score.
    # To identify the worst offender, we look for the most negative shap value.
    worst_idx = np.argmin(shap_vals)
    worst_feature_impact = shap_vals[worst_idx]
    
    # Determine risk level first based on XGBoost health score
    if health_score >= 85:
        risk_level = "Low Risk"
    elif health_score >= 65:
        risk_level = "Medium Risk"
    else:
        risk_level = "High Risk"
        
    recommendations = []
    
    # Identify the worst contributing factor
    worst_idx = np.argmin(shap_vals)
    worst_feature_impact = shap_vals[worst_idx]
    
    # 1. High Risk Specific Recommendations
    if risk_level == "High Risk":
        if worst_idx == 0:
            recommendations.append({
                "title": "CRITICAL: Replace Battery",
                "description": "Lithium cells are heavily degraded. High swelling risk. Replace immediately.",
                "improvement": "+25%",
                "icon": "battery-warning",
                "color": "critical"
            })
        elif worst_idx == 1:
            recommendations.append({
                "title": "CRITICAL: Cool Down Device",
                "description": "Device is undergoing severe thermal stress. Clean CPU vents and check cooling.",
                "improvement": "+15%",
                "icon": "fan",
                "color": "critical"
            })
        elif worst_idx == 2:
            recommendations.append({
                "title": "CRITICAL: Reduce CPU Load",
                "description": "Sustained peak CPU stress is causing silicon wear. Close intensive processes.",
                "improvement": "+10%",
                "icon": "cpu",
                "color": "critical"
            })
        elif worst_idx == 3:
            recommendations.append({
                "title": "CRITICAL: Backup SSD Data",
                "description": "SSD blocks are heavily worn. Electromigration risk high. Backup data immediately.",
                "improvement": "+0%",
                "icon": "hard-drive",
                "color": "critical"
            })
        elif worst_idx == 4:
            recommendations.append({
                "title": "CRITICAL: Close Swap Apps",
                "description": "Excessive memory paging is thrashing the flash memory. Close background apps.",
                "improvement": "+12%",
                "icon": "memory",
                "color": "critical"
            })
            
    # 2. Medium Risk Specific Recommendations
    elif risk_level == "Medium Risk":
        if worst_idx == 0 or charge_cycles > 400:
            recommendations.append({
                "title": "Warning: Optimize Battery",
                "description": "Moderate battery wear. Avoid overnight charging and keep level between 20%-80%.",
                "improvement": "+8%",
                "icon": "battery-warning",
                "color": "warning"
            })
        if worst_idx == 1 or temp > 38.0:
            recommendations.append({
                "title": "Warning: Thermal Management",
                "description": "Device is running warm. Use a laptop stand/cooler and avoid direct sunlight.",
                "improvement": "+5%",
                "icon": "fan",
                "color": "warning"
            })
        if worst_idx == 3 or ssd_tbw > 40:
            recommendations.append({
                "title": "Warning: Clear Storage Space",
                "description": "Clear cached files and junk data to enable optimal flash wear leveling.",
                "improvement": "+4%",
                "icon": "trash",
                "color": "warning"
            })
        if not recommendations:
            recommendations.append({
                "title": "Warning: Moderate Wear",
                "description": "System shows moderate wear. Limit heavy gaming or complex calculations.",
                "improvement": "+5%",
                "icon": "warning-circle",
                "color": "warning"
            })
            
    # 3. Low Risk (Healthy) Recommendations
    else:
        recommendations.append({
            "title": "All Systems Optimal",
            "description": "Battery, CPU, and Storage components are running at peak physical conditions.",
            "improvement": "+0%",
            "icon": "check-circle",
            "color": "success"
        })
            
    if is_anomaly:
        recommendations.insert(0, {
            "title": "ANOMALY FLAGGED: Unusual Hardware Behavior",
            "description": f"Isolation Forest detected abnormal hardware metrics (Score: {anomaly_score:.3f}). Keep temperatures low.",
            "improvement": "N/A",
            "icon": "warning-octagon",
            "color": "critical"
        })
            
    # Calculate dynamic confidence level based on health stability and anomaly metrics
    base_conf = 98.5
    if is_anomaly:
        anomaly_penalty = min(25.0, abs(anomaly_score) * 50.0)
        base_conf -= anomaly_penalty
    else:
        if temp > 40.0:
            base_conf -= min(5.0, (temp - 40.0) * 0.5)
            
    confidence_level = float(np.clip(base_conf, 65.0, 99.8))
            
    return {
        "deviceId": telemetry_data.get("deviceId"),
        "healthScore": health_score,
        "riskLevel": risk_level,
        "recommendations": recommendations,
        "shapValues": shap_dict,
        "isAnomaly": is_anomaly,
        "anomalyScore": anomaly_score,
        "confidenceLevel": confidence_level
    }
