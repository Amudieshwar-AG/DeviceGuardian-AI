import json
import os

proof_path = os.path.join(os.path.dirname(__file__), 'accuracy_proof.json')

try:
    with open(proof_path, 'r') as f:
        data = json.load(f)
        print(f"=========================================")
        print(f"      DEVICE GUARDIAN MODEL ACCURACY     ")
        print(f"=========================================")
        print(f" XGBoost R2 Score     : {data['r2_score'] * 100:.3f}%")
        print(f" Mean Absolute Error  : {data['mae_percent']:.3f}%")
        print(f" Accuracy (error<=±2%): {data['accuracy_within_2_percent'] * 100:.2f}%")
        print(f" Accuracy (error<=±3%): {data['accuracy_within_3_percent'] * 100:.2f}%")
        print(f" Dataset Size         : {data['total_samples']} devices")
        print(f" Features Evaluated   : {', '.join(data['features_used'])}")
        print(f"=========================================")
except Exception as e:
    print(f"Error reading accuracy metrics: {e}")
